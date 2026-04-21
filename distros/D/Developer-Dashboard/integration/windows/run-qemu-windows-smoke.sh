#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WINDOWS_QEMU_MODE="${WINDOWS_QEMU_MODE:-prepared}"
WINDOWS_IMAGE="${WINDOWS_IMAGE:-}"
WINDOWS_SSH_USER="${WINDOWS_SSH_USER:-developer}"
WINDOWS_SSH_KEY="${WINDOWS_SSH_KEY:-$HOME/.ssh/id_ed25519}"
WINDOWS_SSH_PORT="${WINDOWS_SSH_PORT:-2222}"
WINDOWS_RAM_MB="${WINDOWS_RAM_MB:-8192}"
WINDOWS_CPU_COUNT="${WINDOWS_CPU_COUNT:-4}"
WINDOWS_DOCKUR_IMAGE="${WINDOWS_DOCKUR_IMAGE:-docker.io/dockurr/windows}"
WINDOWS_DOCKUR_VERSION="${WINDOWS_DOCKUR_VERSION:-11}"
WINDOWS_DOCKUR_NAME="${WINDOWS_DOCKUR_NAME:-dd-windows-smoke}"
WINDOWS_DOCKUR_WORKDIR="${WINDOWS_DOCKUR_WORKDIR:-$ROOT_DIR/.developer-dashboard/windows-dockur}"
WINDOWS_DOCKUR_TIMEOUT_SECS="${WINDOWS_DOCKUR_TIMEOUT_SECS:-7200}"
WINDOWS_DOCKUR_WEB_PORT="${WINDOWS_DOCKUR_WEB_PORT:-8006}"
WINDOWS_DOCKUR_RDP_PORT="${WINDOWS_DOCKUR_RDP_PORT:-3389}"
WINDOWS_SKIP_CPANM_TESTS="${WINDOWS_SKIP_CPANM_TESTS:-1}"
WINDOWS_STRAWBERRY_URL="${WINDOWS_STRAWBERRY_URL:-}"
WINDOWS_DOCKUR_USERNAME="${WINDOWS_DOCKUR_USERNAME:-developer}"
WINDOWS_DOCKUR_PASSWORD="${WINDOWS_DOCKUR_PASSWORD:-developer-pass-123}"
WINDOWS_DOCKUR_KEEP_RUNNING="${WINDOWS_DOCKUR_KEEP_RUNNING:-1}"
DD_WINDOWS_KVM_REEXEC="${DD_WINDOWS_KVM_REEXEC:-0}"
QEMU_PID=""
DOCKUR_STARTED=0
DOCKUR_LOG_PID=""

load_windows_env() {
  # Purpose: import reusable Windows smoke settings from an env file.
  # Input: optional WINDOWS_QEMU_ENV_FILE or default project/home env-file paths.
  # Output: exports the env-file variables into the current shell when a file exists.
  local candidate="${WINDOWS_QEMU_ENV_FILE:-}"

  if [[ -z "$candidate" && -f "$ROOT_DIR/.developer-dashboard/windows-qemu.env" ]]; then
    candidate="$ROOT_DIR/.developer-dashboard/windows-qemu.env"
  fi

  if [[ -z "$candidate" && -n "${HOME:-}" && -f "$HOME/.developer-dashboard/windows-qemu.env" ]]; then
    candidate="$HOME/.developer-dashboard/windows-qemu.env"
  fi

  if [[ -n "$candidate" ]]; then
    if [[ ! -f "$candidate" ]]; then
      echo "WINDOWS_QEMU_ENV_FILE does not exist: $candidate" >&2
      exit 1
    fi
    export WINDOWS_QEMU_ENV_FILE="$candidate"
    set -a
    # shellcheck disable=SC1090
    source "$candidate"
    set +a
  fi
}

ensure_kvm_available() {
  # Purpose: fail fast when the selected Windows VM path cannot use KVM.
  # Input: the current host /dev/kvm device state.
  # Output: exits non-zero with an explicit error when KVM access is unavailable.
  if [[ ! -e /dev/kvm ]]; then
    echo "/dev/kvm is not available on this host" >&2
    exit 1
  fi

  if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    if [[ "$DD_WINDOWS_KVM_REEXEC" -eq 0 ]] && command -v sg >/dev/null 2>&1 && groups "$(id -un)" | grep -qw kvm; then
      export DD_WINDOWS_KVM_REEXEC=1
      exec sg kvm -c "\"$0\""
    fi
    echo "/dev/kvm exists but is not readable and writable for the current user" >&2
    exit 1
  fi
}

resolve_strawberry_url() {
  # Purpose: resolve the latest 64-bit Strawberry Perl MSI URL from the official release feed.
  # Input: optional WINDOWS_STRAWBERRY_URL override or host Perl with LWP::UserAgent and JSON::XS.
  # Output: exports WINDOWS_STRAWBERRY_URL with a downloadable MSI URL or exits on failure.
  if [[ -n "$WINDOWS_STRAWBERRY_URL" ]]; then
    return
  fi

  if ! command -v perl >/dev/null 2>&1; then
    echo "WINDOWS_STRAWBERRY_URL is required when perl is unavailable on the host" >&2
    exit 1
  fi

  WINDOWS_STRAWBERRY_URL="$(
    perl -MJSON::XS=decode_json -MLWP::UserAgent -e '
      my $ua = LWP::UserAgent->new( timeout => 20 );
      my $res = $ua->get("https://strawberryperl.com/releases.json");
      die $res->status_line unless $res->is_success;
      my $data = decode_json( $res->decoded_content );
      for my $release ( @{$data} ) {
        next if ( $release->{archname} || "" ) ne "MSWin32-x64-multi-thread";
        my $url = $release->{edition}{msi}{url} || "";
        next if $url eq "";
        print $url;
        exit 0;
      }
      die "No 64-bit Strawberry Perl MSI URL found in releases.json\n";
    '
  )"

  if [[ -z "$WINDOWS_STRAWBERRY_URL" ]]; then
    echo "Unable to resolve a Strawberry Perl MSI URL from the official release feed" >&2
    exit 1
  fi
  if [[ "$WINDOWS_STRAWBERRY_URL" != https://* ]]; then
    echo "WINDOWS_STRAWBERRY_URL must use https: $WINDOWS_STRAWBERRY_URL" >&2
    exit 1
  fi
  export WINDOWS_STRAWBERRY_URL
}

prepare_strawberry_installer() {
  # Purpose: cache the Strawberry Perl MSI in the OEM folder so Windows setup
  # does not depend on a live in-guest HTTP download before the smoke starts.
  # Input: resolved WINDOWS_STRAWBERRY_URL plus the Dockur OEM workdir.
  # Output: writes strawberry-perl-installer.msi into the OEM folder when missing.
  local oem_dir="$WINDOWS_DOCKUR_WORKDIR/oem"
  local installer_path="$oem_dir/strawberry-perl-installer.msi"

  mkdir -p "$oem_dir"
  if [[ -s "$installer_path" ]]; then
    return
  fi

  perl -MLWP::UserAgent -e '
    use strict;
    use warnings;

    my ( $url, $target ) = @ARGV;
    die "missing Strawberry Perl URL\n" if !defined $url || $url eq q{};
    die "missing Strawberry Perl target path\n" if !defined $target || $target eq q{};

    my $ua = LWP::UserAgent->new( timeout => 120 );
    my $res = $ua->mirror( $url, $target );
    die $res->status_line . "\n" if !$res->is_success && $res->code != 304;
  ' "$WINDOWS_STRAWBERRY_URL" "$installer_path"
}

prepare_dockur_oem_bundle() {
  # Purpose: stage the Dockur OEM and shared-folder files used by the Windows smoke.
  # Input: the built tarball path plus optional Windows Strawberry installer URL.
  # Output: writes OEM bootstrap files and shared-folder markers into the Dockur workdir.
  local storage_dir="$WINDOWS_DOCKUR_WORKDIR/storage"
  local shared_dir="$WINDOWS_DOCKUR_WORKDIR/shared"
  local oem_dir="$WINDOWS_DOCKUR_WORKDIR/oem"
  local bootstrap_ps1="$oem_dir/bootstrap.ps1"
  local install_bat="$oem_dir/install.bat"

  resolve_strawberry_url
  prepare_strawberry_installer
  mkdir -p "$storage_dir" "$shared_dir" "$oem_dir"
  cp "$TARBALL" "$shared_dir/"
  cp "$ROOT_DIR/integration/windows/run-strawberry-smoke.ps1" "$oem_dir/"

  cat >"$install_bat" <<'EOF'
@echo off
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\OEM\bootstrap.ps1
exit /b %ERRORLEVEL%
EOF

  cat >"$bootstrap_ps1" <<EOF
\$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Status {
    param(
        [Parameter(Mandatory = \$true)][string]\$Name,
        [Parameter(Mandatory = \$true)][string]\$Value
    )
    Set-Content -Path "\\\\host.lan\\Data\\\$Name" -Value \$Value
}

try {
    Write-Status -Name "status.txt" -Value "starting"
    \$shared = "\\\\host.lan\\Data"
    Write-Status -Name "status.txt" -Value "locate-tarball"
    \$tarball = Get-ChildItem -Path \$shared -Filter "Developer-Dashboard-*.tar.gz" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not \$tarball) {
        throw "Unable to locate Developer Dashboard tarball in \$shared"
    }

    Write-Status -Name "status.txt" -Value "locate-strawberry-perl"
    \$perl = Get-Command perl -ErrorAction SilentlyContinue
    if (-not \$perl) {
        Write-Status -Name "status.txt" -Value "install-strawberry-perl"
        \$installer = "C:\\OEM\\strawberry-perl-installer.msi"
        if (-not (Test-Path \$installer)) {
            throw "Unable to find staged Strawberry Perl installer at \$installer"
        }
        Start-Process msiexec.exe -ArgumentList @('/i', \$installer, '/qn', '/norestart') -Wait
    }

    Write-Status -Name "status.txt" -Value "run-strawberry-smoke"
    \$smokeArgs = @(
        '-Tarball', \$tarball.FullName,
        '-StatusRoot', \$shared
    )
    if ("$WINDOWS_SKIP_CPANM_TESTS" -eq "1") {
        \$smokeArgs += '-SkipCpanmTests'
    }
    & "C:\\OEM\\run-strawberry-smoke.ps1" @smokeArgs
    Write-Status -Name "status.txt" -Value "success"
}
catch {
    \$message = (\$_ | Out-String)
    Set-Content -Path "\\\\host.lan\\Data\\status.txt" -Value "failure"
    Set-Content -Path "\\\\host.lan\\Data\\error.txt" -Value \$message
    throw
}
EOF
}

run_prepared_qemu_smoke() {
  # Purpose: boot a prepared Windows image and run the Strawberry smoke over SSH.
  # Input: a prepared qcow2 image, SSH credentials, and a built tarball.
  # Output: exits zero only when the in-guest Windows smoke passes.
  if [[ -z "$WINDOWS_IMAGE" ]]; then
    echo "WINDOWS_IMAGE is required and must point to a prepared Windows qcow2 image" >&2
    exit 1
  fi

  if [[ ! -f "$WINDOWS_IMAGE" ]]; then
    echo "Windows image does not exist: $WINDOWS_IMAGE" >&2
    exit 1
  fi

  echo "==> boot Windows QEMU guest"
  qemu-system-x86_64 \
    -enable-kvm \
    -m "$WINDOWS_RAM_MB" \
    -smp "$WINDOWS_CPU_COUNT" \
    -drive "file=$WINDOWS_IMAGE,if=virtio" \
    -netdev "user,id=net0,hostfwd=tcp::${WINDOWS_SSH_PORT}-:22,hostfwd=tcp::7890-:7890" \
    -device virtio-net-pci,netdev=net0 \
    -display none \
    -daemonize

  QEMU_PID="$(pgrep -n -f "qemu-system-x86_64.*${WINDOWS_IMAGE//\//\\/}" || true)"

  for _ in {1..60}; do
    if ssh -i "$WINDOWS_SSH_KEY" -p "$WINDOWS_SSH_PORT" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$WINDOWS_SSH_USER"@127.0.0.1 'echo ssh-ready' >/dev/null 2>&1; then
      break
    fi
    sleep 5
  done

  echo "==> copy tarball and Windows smoke script into guest"
  scp -i "$WINDOWS_SSH_KEY" -P "$WINDOWS_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$TARBALL" \
    "$ROOT_DIR/integration/windows/run-strawberry-smoke.ps1" \
    "$WINDOWS_SSH_USER"@127.0.0.1:/C:/Temp/

  local guest_tarball="C:/Temp/$(basename "$TARBALL")"

  echo "==> run Strawberry Perl smoke inside guest"
  ssh -i "$WINDOWS_SSH_KEY" -p "$WINDOWS_SSH_PORT" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$WINDOWS_SSH_USER"@127.0.0.1 \
    "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:/Temp/run-strawberry-smoke.ps1 -Tarball '$guest_tarball'"
}

run_dockur_smoke() {
  # Purpose: launch Dockur's KVM-backed Windows VM and wait for the OEM smoke marker.
  # Input: Dockur image settings, OEM/shared workdir, and a built tarball.
  # Output: exits zero only when the guest writes a success marker into the shared folder.
  local shared_dir="$WINDOWS_DOCKUR_WORKDIR/shared"
  local status_file="$shared_dir/status.txt"
  local error_file="$shared_dir/error.txt"
  local host_log_file="$shared_dir/dockur-host.log"
  local container_log_file="$shared_dir/dockur-container.log"

  prepare_dockur_oem_bundle
  rm -f "$status_file" "$error_file"

  local container_id=""
  if docker ps -a --format '{{.Names}}' | grep -Fxq "$WINDOWS_DOCKUR_NAME"; then
    echo "==> reusing existing Dockur Windows container"
    container_id="$(docker ps -a --filter "name=^${WINDOWS_DOCKUR_NAME}$" --format '{{.ID}}' | head -n1)"
    if ! docker ps --format '{{.Names}}' | grep -Fxq "$WINDOWS_DOCKUR_NAME"; then
      docker start "$WINDOWS_DOCKUR_NAME" >/dev/null
    fi
  else
    echo "==> start Dockur Windows container"
    container_id="$(docker run -d \
      --name "$WINDOWS_DOCKUR_NAME" \
      --device=/dev/kvm \
      --device=/dev/net/tun \
      --cap-add NET_ADMIN \
      -e "VERSION=$WINDOWS_DOCKUR_VERSION" \
      -e "RAM_SIZE=${WINDOWS_RAM_MB}M" \
      -e "CPU_CORES=$WINDOWS_CPU_COUNT" \
      -e "USERNAME=$WINDOWS_DOCKUR_USERNAME" \
      -e "PASSWORD=$WINDOWS_DOCKUR_PASSWORD" \
      -p "${WINDOWS_DOCKUR_WEB_PORT}:8006" \
      -p "${WINDOWS_DOCKUR_RDP_PORT}:3389/tcp" \
      -p "${WINDOWS_DOCKUR_RDP_PORT}:3389/udp" \
      -v "$WINDOWS_DOCKUR_WORKDIR/storage:/storage" \
      -v "$WINDOWS_DOCKUR_WORKDIR/shared:/shared" \
      -v "$WINDOWS_DOCKUR_WORKDIR/oem:/oem" \
      "$WINDOWS_DOCKUR_IMAGE")"
    DOCKUR_STARTED=1
  fi
  : >"$container_log_file"
  docker logs -f "$container_id" >"$container_log_file" 2>&1 &
  DOCKUR_LOG_PID="$!"

  echo "==> wait for Dockur Windows smoke marker"
  local deadline=$(( $(date +%s) + WINDOWS_DOCKUR_TIMEOUT_SECS ))
  while (( $(date +%s) < deadline )); do
    if [[ -f "$status_file" ]]; then
      local status
      status="$(tr -d '\r\n' <"$status_file")"
      if [[ "$status" == "success" ]]; then
        return 0
      fi
      if [[ "$status" == "failure" ]]; then
        if [[ -f "$error_file" ]]; then
          cat "$error_file" >&2
        fi
        echo "Dockur Windows smoke failed" >&2
        exit 1
      fi
    fi
    if ! docker ps -a --format '{{.Names}}' | grep -Fxq "$WINDOWS_DOCKUR_NAME"; then
      {
        echo "Dockur Windows container disappeared before reporting success"
        [[ -f "$status_file" ]] && {
          echo
          echo "last status:"
          cat "$status_file"
        }
      } >"$host_log_file"
      cat "$host_log_file" >&2
      exit 1
    fi
    sleep 10
  done

  echo "Timed out waiting for Dockur Windows smoke result after ${WINDOWS_DOCKUR_TIMEOUT_SECS}s" >&2
  exit 1
}

load_windows_env

if [[ -z "${TARBALL:-}" ]]; then
  TARBALL="$(ls -1t "$ROOT_DIR"/Developer-Dashboard-*.tar.gz 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$TARBALL" || ! -f "$TARBALL" ]]; then
  echo "TARBALL is required and must point to a built Developer-Dashboard tarball" >&2
  exit 1
fi

cleanup() {
  if [[ -n "$QEMU_PID" ]] && kill -0 "$QEMU_PID" 2>/dev/null; then
    kill "$QEMU_PID"
    wait "$QEMU_PID" || true
  fi
  if [[ "$DOCKUR_STARTED" -eq 1 ]]; then
    if [[ -n "$DOCKUR_LOG_PID" ]] && kill -0 "$DOCKUR_LOG_PID" 2>/dev/null; then
      kill "$DOCKUR_LOG_PID" >/dev/null 2>&1 || true
      wait "$DOCKUR_LOG_PID" >/dev/null 2>&1 || true
    fi
    if [[ "$WINDOWS_DOCKUR_KEEP_RUNNING" != "1" ]]; then
      docker rm -f "$WINDOWS_DOCKUR_NAME" >/dev/null 2>&1 || true
    fi
  fi
}
trap cleanup EXIT

ensure_kvm_available

case "$WINDOWS_QEMU_MODE" in
  prepared)
    run_prepared_qemu_smoke
    ;;
  dockur)
    run_dockur_smoke
    ;;
  *)
    echo "Unsupported WINDOWS_QEMU_MODE: $WINDOWS_QEMU_MODE" >&2
    exit 1
    ;;
esac

echo "==> QEMU Windows smoke passed"

: <<'__END__'

=pod

=head1 NAME

run-qemu-windows-smoke.sh - boot a prepared Windows guest and run the Strawberry Perl smoke

=head1 SYNOPSIS

  WINDOWS_QEMU_ENV_FILE=.developer-dashboard/windows-qemu.env \
  integration/windows/run-qemu-windows-smoke.sh

  WINDOWS_IMAGE=/var/lib/vm/windows-dev.qcow2 \
  WINDOWS_SSH_USER=developer \
  WINDOWS_SSH_KEY=~/.ssh/id_ed25519 \
  TARBALL=/path/to/Developer-Dashboard-*.tar.gz \
  integration/windows/run-qemu-windows-smoke.sh

=head1 DESCRIPTION

This host-side script loads optional settings from either
C<WINDOWS_QEMU_ENV_FILE>, F<./.developer-dashboard/windows-qemu.env>, or
F<~/.developer-dashboard/windows-qemu.env>. In C<prepared> mode it boots a
prepared Windows guest with C<qemu-system-x86_64 -enable-kvm>, forwards SSH and
the dashboard listener back to the host, copies the built tarball plus
F<integration/windows/run-strawberry-smoke.ps1> into the guest, and runs the
same Strawberry Perl smoke over SSH.

In C<dockur> mode it launches C<docker.io/dockurr/windows> with KVM, stages an
OEM bootstrap bundle plus a shared folder, and waits for the Windows guest to
report its smoke result through that shared folder. Unless
C<WINDOWS_STRAWBERRY_URL> is already set, the Dockur path resolves the latest
64-bit Strawberry Perl MSI URL from the official Strawberry Perl
C<releases.json> feed before it generates the OEM bootstrap. The Dockur path
is the repeatable host-side provisioning route; the supported runtime baseline
inside Windows remains PowerShell plus Strawberry Perl. Git Bash and Scoop are
optional setup helpers, not runtime requirements for Developer Dashboard.

=cut
__END__
