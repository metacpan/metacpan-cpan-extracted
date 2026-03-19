#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="raudssus/langertha-skeid:vasttest"

PUSH=0
for arg in "$@"; do
  case "$arg" in
    --push) PUSH=1 ;;
    --help|-h)
      echo "Usage: build-vast-image.sh [--push]"
      echo "  Builds the vast test image (vLLM + Skeid)"
      echo "  --push  Push to Docker Hub after building"
      exit 0
      ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

echo "Building ${IMAGE}..."
docker build -f "${ROOT_DIR}/examples/Dockerfile.vast" -t "$IMAGE" "$ROOT_DIR"

echo "Done: ${IMAGE}"
docker images "$IMAGE"

if [[ "$PUSH" -eq 1 ]]; then
  echo "Pushing ${IMAGE}..."
  docker push "$IMAGE"
  echo "Pushed."
fi
