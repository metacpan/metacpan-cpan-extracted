#!/usr/bin/env bash
# Read-only summaries. Review/redact output before sharing.
set -euo pipefail
if ! command -v docker >/dev/null 2>&1; then
  echo 'docker CLI is not installed' >&2
  exit 127
fi
# DOCKER_CONTEXT is respected by the CLI; pass it deliberately before invoking.
printf '\n== Context ==\n'
docker context show
printf '\n== Client/server versions ==\n'
docker version
printf '\n== Compose / Buildx versions ==\n'
docker compose version || true
docker buildx version || true
printf '\n== Container summary (names may be sensitive) ==\n'
docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
printf '\n== Disk accounting ==\n'
docker system df
printf '\n== One-shot resource stats ==\n'
docker stats --no-stream
printf '\nNo full inspect, environment, logs, or rendered Compose config was collected.\n'
