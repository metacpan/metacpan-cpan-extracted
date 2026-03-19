#!/usr/bin/env bash
# On-start script for Vast.ai SSH mode.
# Starts vLLM + Skeid in background. SSH in to monitor.
set -euo pipefail

MODEL="${MODEL:-Qwen/Qwen2.5-0.5B-Instruct}"
VLLM_HOST="${VLLM_HOST:-0.0.0.0}"
VLLM_PORT="${VLLM_PORT:-8000}"
SKEID_LISTEN="${SKEID_LISTEN:-0.0.0.0:8090}"
SKEID_CONFIG="${SKEID_CONFIG:-}"
MAX_CONNS="${MAX_CONNS:-4}"

LOGDIR="/var/log/skeid"
mkdir -p "$LOGDIR" /root/skeid-usage

echo "[vast-start] model=${MODEL}"
echo "[vast-start] vllm=${VLLM_HOST}:${VLLM_PORT}"
echo "[vast-start] skeid=${SKEID_LISTEN}"
echo "[vast-start] logs in ${LOGDIR}/"

# Generate Skeid config if none provided
if [[ -z "$SKEID_CONFIG" ]]; then
  SKEID_CONFIG="/tmp/skeid.yaml"
  cat > "$SKEID_CONFIG" <<YAML
pricing:
  "*":
    input_per_million: 0.10
    output_per_million: 0.40

usage_store:
  backend: jsonlog
  path: /root/skeid-usage/

routing:
  wait_timeout_ms: 6000
  wait_poll_ms: 25

nodes:
  - id: local-vllm
    url: http://127.0.0.1:${VLLM_PORT}/v1
    model: ${MODEL}
    engine: vllm
    weight: 1
    max_conns: ${MAX_CONNS}
YAML
  echo "[vast-start] generated config: ${SKEID_CONFIG}"
fi

# Start vLLM in background
echo "[vast-start] starting vLLM..."
nohup vllm serve "$MODEL" --host "$VLLM_HOST" --port "$VLLM_PORT" \
  > "${LOGDIR}/vllm.log" 2>&1 &
VLLM_PID=$!
echo "$VLLM_PID" > "${LOGDIR}/vllm.pid"
echo "[vast-start] vLLM pid=${VLLM_PID}"

# Wait for vLLM to be ready
echo "[vast-start] waiting for vLLM..."
for i in $(seq 1 600); do
  if curl -fsS --max-time 2 "http://127.0.0.1:${VLLM_PORT}/v1/models" >/dev/null 2>&1; then
    echo "[vast-start] vLLM ready after ${i}s"
    break
  fi
  if ! kill -0 "$VLLM_PID" 2>/dev/null; then
    echo "[vast-start] ERROR: vLLM exited unexpectedly" >&2
    tail -n 50 "${LOGDIR}/vllm.log" >&2
    exit 1
  fi
  if (( i % 30 == 0 )); then
    echo "[vast-start] still waiting for vLLM... (${i}s)"
  fi
  sleep 1
done

if ! curl -fsS --max-time 2 "http://127.0.0.1:${VLLM_PORT}/v1/models" >/dev/null 2>&1; then
  echo "[vast-start] ERROR: vLLM not ready after 600s" >&2
  tail -n 50 "${LOGDIR}/vllm.log" >&2
  exit 1
fi

# Start Skeid in background
echo "[vast-start] starting Skeid proxy..."
nohup perl -I/opt/skeid/lib /opt/skeid/bin/skeid serve \
  --listen "$SKEID_LISTEN" \
  --config "$SKEID_CONFIG" \
  > "${LOGDIR}/skeid.log" 2>&1 &
SKEID_PID=$!
echo "$SKEID_PID" > "${LOGDIR}/skeid.pid"
echo "[vast-start] Skeid pid=${SKEID_PID}"

echo ""
echo "[vast-start] === READY ==="
echo "[vast-start] vLLM  : http://0.0.0.0:${VLLM_PORT}/v1"
echo "[vast-start] Skeid : http://0.0.0.0:${SKEID_LISTEN}/v1"
echo "[vast-start] Logs  : tail -f ${LOGDIR}/vllm.log ${LOGDIR}/skeid.log"
