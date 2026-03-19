#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKEND_URL="${BACKEND_URL:-http://5.9.97.19:32080/v1}"
ENGINE="${ENGINE:-vllm}"
MODEL="${MODEL:-Qwen/Qwen2.5-0.5B-Instruct}"
LISTEN="${LISTEN:-127.0.0.1:8090}"
REQUESTS="${REQUESTS:-10}"
CONCURRENCY="${CONCURRENCY:-10}"
MAX_CONNS="${MAX_CONNS:-4}"
MAX_TOKENS="${MAX_TOKENS:-32}"
PROMPT="${PROMPT:-Say hello in exactly three words.}"
TIMEOUT="${TIMEOUT:-120}"
KEEP_RUNNING="${KEEP_RUNNING:-0}"
WORK_DIR="${WORK_DIR:-}"

if [[ -z "${WORK_DIR}" ]]; then
  WORK_DIR="$(mktemp -d /tmp/skeid-onebox.XXXXXX)"
fi

CONFIG_FILE="${WORK_DIR}/skeid.onebox.yaml"
LOG_FILE="${WORK_DIR}/skeid.log"

LISTEN_HOST="${LISTEN%:*}"
LISTEN_PORT="${LISTEN##*:}"
HEALTH_HOST="${LISTEN_HOST}"
if [[ "${HEALTH_HOST}" == "0.0.0.0" ]]; then
  HEALTH_HOST="127.0.0.1"
fi

BASE_URL="http://${HEALTH_HOST}:${LISTEN_PORT}"

cat > "${CONFIG_FILE}" <<YAML
pricing:
  "*":
    input_per_million: 0.10
    output_per_million: 0.40

usage_store:
  backend: sqlite
  sqlite_path: ${WORK_DIR}/usage.sqlite

routing:
  wait_timeout_ms: 6000
  wait_poll_ms: 25

nodes:
  - id: onebox-primary
    url: ${BACKEND_URL}
    model: ${MODEL}
    engine: ${ENGINE}
    weight: 1
    max_conns: ${MAX_CONNS}
YAML

echo "[onebox] Config written: ${CONFIG_FILE}"
echo "[onebox] Backend: ${BACKEND_URL} (${ENGINE})"
echo "[onebox] Skeid listen: ${LISTEN}"

cleanup() {
  local ec=$?
  if [[ -n "${SKEID_PID:-}" ]] && kill -0 "${SKEID_PID}" 2>/dev/null; then
    if [[ "${KEEP_RUNNING}" == "1" ]]; then
      echo "[onebox] KEEP_RUNNING=1, leaving Skeid running (pid=${SKEID_PID})"
      echo "[onebox] log: ${LOG_FILE}"
    else
      echo "[onebox] Stopping Skeid (pid=${SKEID_PID})"
      kill "${SKEID_PID}" 2>/dev/null || true
      wait "${SKEID_PID}" 2>/dev/null || true
    fi
  fi
  exit "${ec}"
}
trap cleanup EXIT INT TERM

perl "${ROOT_DIR}/bin/skeid" serve --listen "${LISTEN}" --config "${CONFIG_FILE}" >"${LOG_FILE}" 2>&1 &
SKEID_PID=$!
echo "[onebox] Skeid pid=${SKEID_PID}, log=${LOG_FILE}"

for i in $(seq 1 120); do
  if curl -fsS --max-time 2 "${BASE_URL}/health" >/dev/null 2>&1; then
    echo "[onebox] Health OK: ${BASE_URL}/health"
    break
  fi
  sleep 0.25
  if [[ "${i}" -eq 120 ]]; then
    echo "[onebox] ERROR: Skeid health check failed" >&2
    tail -n 80 "${LOG_FILE}" >&2 || true
    exit 1
  fi
done

echo "[onebox] Running smoke: requests=${REQUESTS} concurrency=${CONCURRENCY}"
perl "${ROOT_DIR}/examples/skeid-parallel-smoke.pl" \
  --base-url "${BASE_URL}" \
  --model "${MODEL}" \
  --requests "${REQUESTS}" \
  --concurrency "${CONCURRENCY}" \
  --max-tokens "${MAX_TOKENS}" \
  --prompt "${PROMPT}" \
  --timeout "${TIMEOUT}" \
  --show-errors \
  --json

echo "[onebox] Done. Artifacts in ${WORK_DIR}"
