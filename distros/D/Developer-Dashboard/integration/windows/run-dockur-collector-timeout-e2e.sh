#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HARNESS="$ROOT_DIR/integration/windows/run-collector-timeout-e2e.ps1"

DOCKUR_CONTAINER="${DOCKUR_CONTAINER:-dd-windows-smoke}"
GUEST_SHARE="${GUEST_SHARE:-\\\\host.lan\\Data}"
GUEST_PERL_PATH="${GUEST_PERL_PATH:-C:\\Strawberry\\perl\\bin;C:\\Strawberry\\perl\\site\\bin;C:\\Strawberry\\c\\bin}"
GUEST_TEMP="${GUEST_TEMP:-C:\\Temp}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-10}"
AGENT_ALIVE_WAIT="${AGENT_ALIVE_WAIT:-30}"
JOB_TIMEOUT="${JOB_TIMEOUT:-2400}"
JOB_ID="${JOB_ID:-dd-timeout-e2e-$(date +%s)}"

log() {
  # Purpose: emit one progress line for the host operator.
  # Input: message words.
  # Output: writes the message to stderr so stdout stays the guest transcript.
  echo "[dockur-timeout-e2e] $*" >&2
}

fail() {
  # Purpose: abort the driver with a diagnostic instead of a silent partial run.
  # Input: message words.
  # Output: exits non-zero after writing the message to stderr.
  echo "[dockur-timeout-e2e] FAIL: $*" >&2
  exit 1
}

resolve_share() {
  # Purpose: locate the Dockur guest's shared folder from any checkout, including a ticket worktree.
  # Input: optional DOCKUR_SHARE env var, this checkout, its main checkout, and the home runtime layer.
  # Output: exports DOCKUR_SHARE, or exits non-zero when no shared folder exists.
  if [[ -n "${DOCKUR_SHARE:-}" ]]; then
    [[ -d "$DOCKUR_SHARE" ]] || fail "DOCKUR_SHARE does not exist: $DOCKUR_SHARE"
    export DOCKUR_SHARE
    return
  fi

  local -a candidates=("$ROOT_DIR")
  # A ticket worktree has no runtime layer of its own; the guest share lives in
  # the main checkout, which git names through its common directory.
  local common_dir
  common_dir="$(cd "$ROOT_DIR" && git rev-parse --git-common-dir 2>/dev/null || true)"
  if [[ -n "$common_dir" ]]; then
    [[ "$common_dir" = /* ]] || common_dir="$ROOT_DIR/$common_dir"
    candidates+=("$(cd "$common_dir/.." && pwd)")
  fi
  [[ -n "${HOME:-}" ]] && candidates+=("$HOME")

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate/.developer-dashboard/windows-dockur/shared" ]]; then
      DOCKUR_SHARE="$candidate/.developer-dashboard/windows-dockur/shared"
      export DOCKUR_SHARE
      log "shared folder: $DOCKUR_SHARE"
      return
    fi
  done

  fail "no Dockur shared folder found under ${candidates[*]} (set DOCKUR_SHARE)"
}

require_guest() {
  # Purpose: confirm the Dockur QEMU Windows guest container is really running.
  # Input: DOCKUR_CONTAINER name and an available docker CLI.
  # Output: returns nothing, or exits non-zero when the guest is not up.
  command -v docker >/dev/null 2>&1 || fail "docker is required to reach the Dockur Windows guest"
  local running
  running="$(docker inspect -f '{{.State.Running}}' "$DOCKUR_CONTAINER" 2>/dev/null || true)"
  [[ "$running" == "true" ]] || fail "Dockur Windows guest container '$DOCKUR_CONTAINER' is not running"
  log "guest container $DOCKUR_CONTAINER is running"
}

require_agent_alive() {
  # Purpose: prove the in-guest job agent loop is still ticking before queueing work.
  # Input: the shared folder holding ddagent-alive.txt and AGENT_ALIVE_WAIT seconds.
  # Output: returns nothing, or exits non-zero when the tick does not advance.
  local alive="$DOCKUR_SHARE/ddagent-alive.txt"
  [[ -f "$alive" ]] || fail "in-guest job agent has never reported: $alive is missing (re-establish ddagent.ps1 in the guest)"
  local first second waited=0
  first="$(cat "$alive")"
  while (( waited < AGENT_ALIVE_WAIT )); do
    sleep 3
    waited=$(( waited + 3 ))
    second="$(cat "$alive")"
    if [[ "$second" != "$first" ]]; then
      log "in-guest job agent is alive: $second"
      return
    fi
  done
  fail "in-guest job agent tick did not advance within ${AGENT_ALIVE_WAIT}s (last: $first) — re-establish ddagent.ps1 in the guest"
}

resolve_tarball() {
  # Purpose: resolve the release tarball whose product the E2E must exercise.
  # Input: optional TARBALL env var, otherwise the newest tarball in the repo root.
  # Output: exports TARBALL as an absolute path.
  if [[ -z "${TARBALL:-}" ]]; then
    TARBALL="$(ls -1t "$ROOT_DIR"/Developer-Dashboard-*.tar.gz 2>/dev/null | head -n1 || true)"
    [[ -n "$TARBALL" ]] || fail "no Developer-Dashboard-*.tar.gz in $ROOT_DIR — run 'dzil build' first or pass TARBALL"
  fi
  [[ -f "$TARBALL" ]] || fail "TARBALL does not exist: $TARBALL"
  TARBALL="$(cd "$(dirname "$TARBALL")" && pwd)/$(basename "$TARBALL")"
  export TARBALL
}

write_job() {
  # Purpose: publish the tarball, the in-guest harness, and the job script the agent runs.
  # Input: resolved TARBALL, JOB_ID, and guest path settings.
  # Output: returns nothing; leaves ddjob-<JOB_ID>.ps1 in the shared folder.
  local tarball_name="$JOB_ID-$(basename "$TARBALL")"
  local harness_name="$JOB_ID-run-collector-timeout-e2e.ps1"
  local version
  version="$(basename "$TARBALL" | sed -e 's/^Developer-Dashboard-//' -e 's/\.tar\.gz$//')"
  local version_pattern="${version//./\\.}"

  cp "$TARBALL" "$DOCKUR_SHARE/$tarball_name"
  cp "$HARNESS" "$DOCKUR_SHARE/$harness_name"
  rm -f "$DOCKUR_SHARE/ddjob-$JOB_ID.status" "$DOCKUR_SHARE/ddjob-$JOB_ID.out"

  cat >"$DOCKUR_SHARE/.ddjob-$JOB_ID.ps1.partial" <<EOF
\$ErrorActionPreference = 'Continue'
\$env:Path = '$GUEST_PERL_PATH;' + \$env:Path
\$env:PERL_MM_USE_DEFAULT = '1'
# A non-interactive Windows session inherits neither a POSIX HOME nor a POSIX
# username, and the dashboard needs both before it can resolve runtime state.
\$env:HOME = \$env:USERPROFILE
\$env:DD_STATE_ROOT_USER = 'dd-timeout-e2e'
New-Item -ItemType Directory -Force -Path '$GUEST_TEMP' | Out-Null
Copy-Item -Path '$GUEST_SHARE\\$tarball_name' -Destination '$GUEST_TEMP\\$tarball_name' -Force
Copy-Item -Path '$GUEST_SHARE\\$harness_name' -Destination '$GUEST_TEMP\\$harness_name' -Force

Write-Output '==> clean slate: stop stray timeout-E2E and collector processes from earlier runs'
foreach (\$fragment in @('dd-timeout-e2e-', 'dashboard collector')) {
    \$escaped = [regex]::Escape(\$fragment)
    Get-CimInstance Win32_Process |
        Where-Object { (\$null -ne \$_.CommandLine) -and (\$_.CommandLine -match \$escaped) -and (\$_.ProcessId -ne \$PID) } |
        ForEach-Object {
            Write-Output ("clean-slate: stopping stray pid {0}: {1}" -f \$_.ProcessId, \$_.CommandLine)
            Stop-Process -Id \$_.ProcessId -Force -ErrorAction SilentlyContinue
        }
}

Write-Output '==> install the host-built tarball into the guest'
cpanm --notest --no-interactive --reinstall '$GUEST_TEMP\\$tarball_name' 2>&1 | Out-String
\$installExit = \$LASTEXITCODE
Write-Output "cpanm exit: \$installExit"
if (\$installExit -ne 0) { exit 10 }

\$installed = (dashboard version 2>&1 | Out-String).Trim()
Write-Output "installed dashboard version: \$installed"
if (\$installed -notmatch '$version_pattern') { Write-Output 'VERSION MISMATCH'; exit 11 }

Write-Output '==> assert the installed product really carries the Windows timeout implementation'
perl -MDeveloper::Dashboard::CollectorRunner -e "exit(Developer::Dashboard::CollectorRunner->can('_await_windows_command') ? 0 : 9)"
\$symbolExit = \$LASTEXITCODE
Write-Output "installed _await_windows_command probe exit: \$symbolExit"
if (\$symbolExit -ne 0) { Write-Output 'INSTALLED PRODUCT LACKS THE WINDOWS COMMAND TIMEOUT IMPLEMENTATION'; exit 12 }

Write-Output '==> run the in-guest collector timeout E2E'
& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File '$GUEST_TEMP\\$harness_name' -TimeoutSeconds $TIMEOUT_SECONDS 2>&1 | Out-String
\$e2eExit = \$LASTEXITCODE
Write-Output "E2E exit: \$e2eExit"
exit \$e2eExit
EOF

  mv "$DOCKUR_SHARE/.ddjob-$JOB_ID.ps1.partial" "$DOCKUR_SHARE/ddjob-$JOB_ID.ps1"
  log "submitted job ddjob-$JOB_ID.ps1 (tarball $tarball_name, timeout ${TIMEOUT_SECONDS}s)"
}

await_job() {
  # Purpose: wait for the guest agent to finish the submitted job and surface its transcript.
  # Input: JOB_ID and JOB_TIMEOUT seconds.
  # Output: prints the guest transcript on stdout and exits with the guest exit code.
  local status_file="$DOCKUR_SHARE/ddjob-$JOB_ID.status"
  local out_file="$DOCKUR_SHARE/ddjob-$JOB_ID.out"
  local waited=0 status=""
  while (( waited < JOB_TIMEOUT )); do
    if [[ -f "$status_file" ]]; then
      # The guest agent writes the status with Windows line endings, so strip
      # the carriage return before the exit code is read as a number.
      status="$(tr -d '\r\n' < "$status_file")"
      if [[ "$status" == exit:* ]]; then
        log "job finished with $status"
        [[ -f "$out_file" ]] && cat "$out_file"
        local code="${status#exit:}"
        [[ "$code" =~ ^[0-9]+$ ]] || fail "guest agent reported a non-numeric exit status: $status"
        exit "$code"
      fi
    fi
    sleep 5
    waited=$(( waited + 5 ))
    if (( waited % 60 == 0 )); then
      log "still waiting (${waited}s, status: ${status:-queued})"
    fi
  done
  [[ -f "$out_file" ]] && cat "$out_file"
  fail "job ddjob-$JOB_ID did not finish within ${JOB_TIMEOUT}s (status: ${status:-queued})"
}

[[ -f "$HARNESS" ]] || fail "in-guest harness is missing: $HARNESS"
# The job namespace and timeout are interpolated into the generated guest script,
# so keep them to shapes that cannot terminate a quoted PowerShell literal.
[[ "$JOB_ID" =~ ^[A-Za-z0-9._-]+$ ]] || fail "JOB_ID must be limited to letters, digits, dot, underscore, and dash: $JOB_ID"
[[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || fail "TIMEOUT_SECONDS must be a whole number of seconds: $TIMEOUT_SECONDS"

resolve_share
require_guest
require_agent_alive
resolve_tarball
log "tarball: $TARBALL"
write_job
await_job

: <<'__END__'

=pod

=head1 NAME

run-dockur-collector-timeout-e2e.sh - run the Windows collector timeout E2E in the Dockur QEMU guest

=head1 SYNOPSIS

  integration/windows/run-dockur-collector-timeout-e2e.sh

  TARBALL="$(ls -1t Developer-Dashboard-*.tar.gz | head -n1)" TIMEOUT_SECONDS=15 \
  integration/windows/run-dockur-collector-timeout-e2e.sh

=head1 DESCRIPTION

This host-side driver makes the Windows collector-timeout End-to-End gate
repeatable. It confirms the Dockur C<qemu-system> Windows guest container is
running and that the in-guest file-job agent loop is still ticking, finds the
guest's shared folder in this checkout, in the main checkout behind a ticket
worktree, or in the home runtime layer, resolves the
release tarball to test (the newest one in the repository root unless C<TARBALL>
is set), copies that tarball and F<run-collector-timeout-e2e.ps1> into the shared
folder under a unique per-run job namespace, and submits one atomic job through
the shared-folder job protocol so no concurrent session can install a different
build between the install and the E2E.

The submitted job gives the guest session the environment a non-interactive
Windows shell lacks (C<HOME> and the C<DD_STATE_ROOT_USER> state-root seam),
applies the persistent-guest clean-slate rule, installs the tarball with
C<cpanm>, asserts the installed version matches the tarball and that the
installed C<Developer::Dashboard::CollectorRunner> really carries the Windows
command-timeout implementation (so a stale install can never produce a green
run), and only then runs the in-guest harness.

The driver then polls the job status file the agent writes, prints the guest
transcript on standard output, and exits with the guest exit code.

=head1 ENVIRONMENT

C<DOCKUR_CONTAINER>, C<DOCKUR_SHARE>, C<GUEST_SHARE>, C<GUEST_PERL_PATH>,
C<GUEST_TEMP>, C<TARBALL>, C<TIMEOUT_SECONDS>, C<AGENT_ALIVE_WAIT>,
C<JOB_TIMEOUT>, and C<JOB_ID> override the defaults.

=cut
__END__
