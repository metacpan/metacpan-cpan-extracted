#!/usr/bin/env bash
# Simple script to rent a vast.ai GPU and start vLLM + Skeid on it.
set -euo pipefail

IMAGE="${SKEID_VAST_IMAGE:-raudssus/langertha-skeid:vasttest}"
MODEL="Qwen/Qwen2.5-0.5B-Instruct"
GPU_TYPE=""
NUM_GPUS=1
DISK_GB=80
MAX_DPH=""
RENT_LIMIT=20
LABEL="skeid-onebox"
HF_TOKEN_VALUE="${HF_TOKEN:-}"
MAX_CONNS=4
ACTION=""
INSTANCE_ID=""

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: skeid-vast-onebox.sh <action> [options]

Actions:
  start               Search cheapest datacenter offer, rent via SSH mode,
                      and auto-start vLLM + Skeid via onstart script
  list-offers         List available datacenter offers
  list-instances      List your running instances
  status ID           Show status of an instance
  destroy ID          Destroy an instance
  logs ID             Show vLLM + Skeid logs from instance
  ssh ID              SSH into an instance

Options:
  --model NAME        Model for vLLM (default: Qwen/Qwen2.5-0.5B-Instruct)
  --gpu-type NAME     GPU filter, e.g. A40, H100, "RTX 4090" (default: any)
  --num-gpus N        Required GPU count (default: 1)
  --disk-gb N         Disk size in GB (default: 80)
  --max-dph PRICE     Max $/hour price filter
  --image IMAGE       Docker image to use
  --hf-token TOKEN    Hugging Face token (or set HF_TOKEN env)
  --max-conns N       Skeid max concurrent backend connections (default: 4)
  --limit N           Offer search result limit (default: 20)
  --label NAME        Instance label (default: skeid-onebox)
  -h, --help          Show this help

Environment:
  VAST_API_KEY        Vast.ai API key (or use 'vastai set api-key')
  HF_TOKEN            Hugging Face token
  SKEID_VAST_IMAGE    Docker image override

Examples:
  ./skeid-vast-onebox.sh list-offers --gpu-type A40
  ./skeid-vast-onebox.sh start --model Qwen/Qwen2.5-7B-Instruct --gpu-type A40
  ./skeid-vast-onebox.sh status 12345678
  ./skeid-vast-onebox.sh destroy 12345678
USAGE
}

# --- Parse args ---

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

# First arg is the action (or --help)
case "$1" in
  start|list-offers|list-instances|status|destroy|logs|ssh)
    ACTION="$1"; shift ;;
  -h|--help)
    usage; exit 0 ;;
  *)
    die "Unknown action: $1 (try --help)" ;;
esac

# For actions that take an instance ID
if [[ "$ACTION" =~ ^(status|destroy|logs|ssh)$ ]]; then
  if [[ $# -ge 1 && "$1" != --* ]]; then
    INSTANCE_ID="$1"; shift
  fi
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)      MODEL="$2"; shift 2 ;;
    --gpu-type)   GPU_TYPE="$2"; shift 2 ;;
    --num-gpus)   NUM_GPUS="$2"; shift 2 ;;
    --disk-gb)    DISK_GB="$2"; shift 2 ;;
    --max-dph)    MAX_DPH="$2"; shift 2 ;;
    --image)      IMAGE="$2"; shift 2 ;;
    --hf-token)   HF_TOKEN_VALUE="$2"; shift 2 ;;
    --max-conns)  MAX_CONNS="$2"; shift 2 ;;
    --limit)      RENT_LIMIT="$2"; shift 2 ;;
    --label)      LABEL="$2"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *)            die "Unknown option: $1" ;;
  esac
done

# --- Helpers ---

require_vastai() {
  command -v vastai >/dev/null 2>&1 || die "vastai CLI not found (pip install vastai)"
  vastai show user >/dev/null 2>&1 || die "Vast auth failed. Run: vastai set api-key YOUR_KEY"
}

build_query() {
  local q="verified=true rentable=true datacenter=True num_gpus=${NUM_GPUS}"
  if [[ -n "$MAX_DPH" ]]; then
    q="${q} dph_total<=${MAX_DPH}"
  fi
  echo "$q"
}

# Search offers and optionally filter by GPU name pattern.
# Outputs JSON array to stdout.
search_offers() {
  local query
  query="$(build_query)"
  vastai search offers "$query" --order dph_total --limit "$RENT_LIMIT" --raw
}

# Filter + format offers as a table. Reads JSON from stdin.
format_offers() {
  local gpu_pattern="${1:-}"
  perl -MJSON::PP -e '
    my $pat = shift // "";
    my $raw = do { local $/; <STDIN> };
    my $rows = eval { decode_json($raw) } || [];
    ref($rows) eq "ARRAY" or die "expected array\n";

    printf "%-12s %-20s %8s %5s %10s %s\n",
      "OFFER_ID", "GPU", "VRAM_GB", "GPUs", "\$/hour", "LOCATION";
    printf "%s\n", "-" x 72;

    for my $r (@$rows) {
      my $gpu = $r->{gpu_name} // "";
      if (length $pat) {
        next unless $gpu =~ /$pat/i;
      }
      printf "%-12s %-20s %8.1f %5d %10.4f %s\n",
        $r->{id} // "",
        $gpu,
        ($r->{gpu_ram} // 0) / 1024.0,
        $r->{num_gpus} // 0,
        $r->{dph_total} // 0,
        $r->{geolocation} // "";
    }
  ' "$gpu_pattern"
}

# Pick cheapest offer matching GPU pattern. Reads JSON from stdin.
# Prints offer_id to stdout.
pick_cheapest() {
  local gpu_pattern="${1:-}"
  perl -MJSON::PP -e '
    my $pat = shift // "";
    my $raw = do { local $/; <STDIN> };
    my $rows = eval { decode_json($raw) } || [];
    ref($rows) eq "ARRAY" or exit 1;

    for my $r (sort { ($a->{dph_total}//9e9) <=> ($b->{dph_total}//9e9) } @$rows) {
      my $gpu = $r->{gpu_name} // "";
      if (length $pat) {
        next unless $gpu =~ /$pat/i;
      }
      my $id = $r->{id} // next;
      printf "%s\t%s\t%.1f\t%.4f\n",
        $id, $gpu, ($r->{gpu_ram}//0)/1024.0, $r->{dph_total}//0;
      exit 0;
    }
    exit 1;
  ' "$gpu_pattern"
}

# Build a regex pattern from a friendly GPU type name
gpu_pattern() {
  local t="${1:-}"
  [[ -z "$t" ]] && return
  # Already a regex? pass through
  if [[ "$t" == *'['* || "$t" == *'('* || "$t" == *'\b'* ]]; then
    echo "$t"
    return
  fi
  # Escape for regex and make case-insensitive match
  echo "$t"
}

# Parse instance JSON for connection info
instance_info() {
  local json="$1"
  printf '%s' "$json" | perl -MJSON::PP -e '
    my $d = eval { decode_json(do { local $/; <STDIN> }) } || {};
    my $st   = $d->{actual_status} // $d->{cur_state} // "unknown";
    my $gpu  = $d->{gpu_name} // "";
    my $host = $d->{ssh_host} // $d->{public_ipaddr} // "";
    my $port = $d->{ssh_port} // "";
    my $ports = $d->{ports} // {};
    my $label = $d->{label} // "";
    my $img  = $d->{image_uuid} // "";
    printf "status=%s gpu=%s host=%s ssh_port=%s label=%s image=%s\n",
      $st, $gpu, $host, $port, $label, $img;
  '
}

# --- Actions ---

case "$ACTION" in

  list-offers)
    require_vastai
    pat="$(gpu_pattern "$GPU_TYPE")"
    echo "Searching offers (num_gpus=${NUM_GPUS}, limit=${RENT_LIMIT})..."
    search_offers | format_offers "$pat"
    ;;

  list-instances)
    require_vastai
    echo "Your instances:"
    vastai show instances --raw | perl -MJSON::PP -e '
      my $raw = do { local $/; <STDIN> };
      my $rows = eval { decode_json($raw) } || [];
      ref($rows) eq "ARRAY" or die "unexpected format\n";

      printf "%-12s %-20s %8s %-10s %-20s %s\n",
        "ID", "GPU", "VRAM_GB", "STATUS", "HOST", "LABEL";
      printf "%s\n", "-" x 85;

      for my $r (@$rows) {
        printf "%-12s %-20s %8.1f %-10s %-20s %s\n",
          $r->{id} // "",
          $r->{gpu_name} // "",
          ($r->{gpu_ram} // $r->{gpu_totalram} // 0) / 1024.0,
          $r->{actual_status} // $r->{cur_state} // "",
          ($r->{ssh_host} // "") . ":" . ($r->{ssh_port} // ""),
          $r->{label} // "";
      }
    '
    ;;

  status)
    require_vastai
    [[ -n "$INSTANCE_ID" ]] || die "Usage: skeid-vast-onebox.sh status <instance-id>"
    json="$(vastai show instance "$INSTANCE_ID" --raw)"
    instance_info "$json"
    ;;

  destroy)
    require_vastai
    if [[ -n "$INSTANCE_ID" ]]; then
      echo "Destroying instance ${INSTANCE_ID}..."
      vastai destroy instance "$INSTANCE_ID"
      echo "Done."
    else
      # Destroy all instances running our image
      echo "Finding all instances with image ${IMAGE}..."
      IDS="$(vastai show instances --raw | perl -MJSON::PP -e '
        my $img = shift;
        my $rows = eval { decode_json(do { local $/; <STDIN> }) } || [];
        for my $r (@$rows) {
          next unless ref($r) eq "HASH";
          my $i = $r->{image_uuid} // "";
          print $r->{id}, "\n" if $i eq $img;
        }
      ' "$IMAGE")"
      if [[ -z "$IDS" ]]; then
        echo "No instances found with image ${IMAGE}."
      else
        for id in $IDS; do
          echo "Destroying instance ${id}..."
          vastai destroy instance "$id"
        done
        echo "Done."
      fi
    fi
    ;;

  logs)
    require_vastai
    [[ -n "$INSTANCE_ID" ]] || die "Usage: skeid-vast-onebox.sh logs <instance-id>"
    vastai logs "$INSTANCE_ID" 2>&1 | tail -n 200
    ;;

  ssh)
    require_vastai
    [[ -n "$INSTANCE_ID" ]] || die "Usage: skeid-vast-onebox.sh ssh <instance-id>"
    INST_JSON="$(vastai show instance "$INSTANCE_ID" --raw)"
    SSH_HOST="$(printf '%s' "$INST_JSON" | perl -MJSON::PP -e '
      my $d = eval { decode_json(do { local $/; <STDIN> }) } || {};
      print $d->{ssh_host} // $d->{public_ipaddr} // "";
    ')"
    SSH_PORT="$(printf '%s' "$INST_JSON" | perl -MJSON::PP -e '
      my $d = eval { decode_json(do { local $/; <STDIN> }) } || {};
      print $d->{ssh_port} // "22";
    ')"
    [[ -n "$SSH_HOST" ]] || die "Cannot determine SSH host for instance ${INSTANCE_ID}"
    echo "Connecting to ${SSH_HOST}:${SSH_PORT}..."
    exec ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "root@${SSH_HOST}"
    ;;

  start)
    require_vastai
    pat="$(gpu_pattern "$GPU_TYPE")"

    # Find cheapest offer
    echo "Searching for cheapest offer..."
    OFFER_JSON="$(search_offers)"
    CHEAPEST="$(echo "$OFFER_JSON" | pick_cheapest "$pat" || true)"

    if [[ -z "$CHEAPEST" ]]; then
      echo "No matching offers found. Available:"
      echo "$OFFER_JSON" | format_offers ""
      die "No offer matches gpu_type='${GPU_TYPE}'. Try --limit or different --gpu-type."
    fi

    IFS=$'\t' read -r OFFER_ID OFFER_GPU OFFER_VRAM OFFER_DPH <<< "$CHEAPEST"
    echo "Selected: offer=${OFFER_ID} gpu=${OFFER_GPU} vram=${OFFER_VRAM}GB \$${OFFER_DPH}/h"

    # Build env string: expose ports 8000 (vLLM) and 8090 (Skeid) + env vars
    ENV_PARTS="-e MODEL=${MODEL} -e MAX_CONNS=${MAX_CONNS} -p 8000:8000 -p 8090:8090"
    if [[ -n "$HF_TOKEN_VALUE" ]]; then
      ENV_PARTS="${ENV_PARTS} -e HF_TOKEN=${HF_TOKEN_VALUE}"
    fi

    # Create instance in SSH mode with onstart script
    echo "Creating instance with image ${IMAGE} (SSH mode)..."
    CREATE_OUT="$(vastai create instance "$OFFER_ID" \
      --image "$IMAGE" \
      --disk "$DISK_GB" \
      --label "$LABEL" \
      --env "$ENV_PARTS" \
      --ssh \
      --direct \
      --onstart-cmd 'bash /opt/skeid/vast-start.sh' \
      --raw)"

    CREATED_ID="$(printf '%s' "$CREATE_OUT" | perl -MJSON::PP -e '
      my $d = eval { decode_json(do { local $/; <STDIN> }) } || {};
      my $id = $d->{new_contract} // $d->{id} // $d->{instance_id} // "";
      print $id if $id;
    ' || true)"

    if [[ -z "$CREATED_ID" ]]; then
      # Fallback: extract any number from response
      CREATED_ID="$(echo "$CREATE_OUT" | grep -oP '\d{5,}' | head -1 || true)"
    fi

    [[ -n "$CREATED_ID" ]] || die "Could not parse instance ID from: ${CREATE_OUT}"
    echo "Instance created: id=${CREATED_ID}"

    # Wait for running
    echo "Waiting for instance to start..."
    READY=0
    for i in $(seq 1 300); do
      INST_JSON="$(vastai show instance "$CREATED_ID" --raw 2>/dev/null || true)"
      if [[ -n "$INST_JSON" ]]; then
        STATUS="$(printf '%s' "$INST_JSON" | perl -MJSON::PP -e '
          my $d = eval { decode_json(do { local $/; <STDIN> }) } || {};
          print $d->{actual_status} // $d->{cur_state} // "";
        ')"
        if [[ "${STATUS,,}" == "running" ]]; then
          READY=1
          break
        fi
        if (( i % 15 == 0 )); then
          echo "  status=${STATUS} (${i}s)..."
        fi
      fi
      sleep 1
    done

    if [[ "$READY" -ne 1 ]]; then
      die "Instance did not reach running state in 5 minutes. Check: vastai show instance ${CREATED_ID}"
    fi

    echo ""
    echo "=== Instance is running ==="
    instance_info "$INST_JSON"

    # Extract connection details
    eval "$(printf '%s' "$INST_JSON" | perl -MJSON::PP -e '
      my $d = eval { decode_json(do { local $/; <STDIN> }) } || {};
      my $host = $d->{ssh_host} // $d->{public_ipaddr} // "";
      my $port = $d->{ssh_port} // "";
      printf "INST_HOST=%s\nINST_SSH_PORT=%s\n", $host, $port;
      # Find mapped ports
      my $ports = $d->{ports} // {};
      for my $k (sort keys %$ports) {
        my $mappings = $ports->{$k};
        next unless ref($mappings) eq "ARRAY" && @$mappings;
        my $hp = $mappings->[0]{HostPort} // next;
        if ($k =~ /^8090/) {
          printf "INST_SKEID_PORT=%s\n", $hp;
        } elsif ($k =~ /^8000/) {
          printf "INST_VLLM_PORT=%s\n", $hp;
        }
      }
    ')"

    echo ""
    echo "=== Connection Info ==="
    echo "  Instance ID : ${CREATED_ID}"
    echo "  Model       : ${MODEL}"
    if [[ -n "${INST_SKEID_PORT:-}" ]]; then
      echo "  Skeid API   : http://${INST_HOST}:${INST_SKEID_PORT}/v1/chat/completions"
    fi
    if [[ -n "${INST_VLLM_PORT:-}" ]]; then
      echo "  vLLM direct : http://${INST_HOST}:${INST_VLLM_PORT}/v1/chat/completions"
    fi
    if [[ -n "${INST_SSH_PORT:-}" ]]; then
      echo "  SSH         : ssh -p ${INST_SSH_PORT} root@${INST_HOST}"
    fi
    echo ""
    echo "vLLM + Skeid are starting via onstart script."
    echo "SSH in to monitor:"
    echo "  $0 ssh ${CREATED_ID}"
    echo ""
    echo "Check logs inside the instance:"
    echo "  tail -f /var/log/skeid/vllm.log /var/log/skeid/skeid.log"
    echo ""
    echo "Destroy when done:"
    echo "  $0 destroy ${CREATED_ID}"
    ;;

esac
