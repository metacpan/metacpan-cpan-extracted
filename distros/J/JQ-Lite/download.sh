#!/usr/bin/env bash

set -euo pipefail

DIST_NAME="JQ-Lite"
OUT_DIR="."
SPECIFIED_VERSION=""

usage() {
  cat <<USAGE
Usage: $0 [-v <version>] [-o <output-dir>]

Downloads the specified version of ${DIST_NAME} from MetaCPAN.
If no version is provided, the latest version will be downloaded.

Options:
  -v <version>  Version to download (e.g. 1.28)
  -o <dir>      Directory where the tarball should be saved (default: current)
  -h            Show this help message
USAGE
}

# --- Parse options ---
while getopts ":v:o:h" opt; do
  case "$opt" in
    v) SPECIFIED_VERSION="$OPTARG" ;;
    o) OUT_DIR="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    :)
      echo "[ERROR] Option -$OPTARG requires an argument." >&2
      usage >&2
      exit 1
      ;;
    ?)
      echo "[ERROR] Unknown option -$OPTARG" >&2
      usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

# --- Check required tools ---
for tool in curl perl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[ERROR] '$tool' is required but not installed." >&2
    exit 1
  fi
done

# --- Prepare output directory ---
if [[ ! -d "$OUT_DIR" ]]; then
  echo "[INFO] Creating output directory $OUT_DIR"
  mkdir -p "$OUT_DIR"
fi

# --- Fetch metadata ---
if [[ -n "$SPECIFIED_VERSION" ]]; then
  echo "[INFO] Fetching JQ-Lite version $SPECIFIED_VERSION from MetaCPAN..."
  META_URL="https://fastapi.metacpan.org/v1/release/_search"
  RELEASE_JSON=$(curl -sSfL -X POST "$META_URL" \
    -H 'Content-Type: application/json' \
    -d "{\"query\":{\"bool\":{\"must\":[{\"term\":{\"distribution\":\"${DIST_NAME}\"}},{\"term\":{\"version\":\"${SPECIFIED_VERSION}\"}}]}},\"size\":1}")
else
  echo "[INFO] Fetching latest JQ-Lite release from MetaCPAN..."
  META_URL="https://fastapi.metacpan.org/v1/release/${DIST_NAME}?fields=download_url,version"
  RELEASE_JSON=$(curl -sSfL "$META_URL")
fi

# --- Parse JSON (mac-compatible) ---
META_FIELDS=($(printf '%s' "$RELEASE_JSON" | perl -MJSON::PP -E '
  my $data = decode_json(join q{}, <STDIN>);
  my ($url, $version);

  # Case 1: _search API
  if (exists $data->{hits}) {
    my $hit = $data->{hits}->{hits}->[0] // {};
    if (exists $hit->{_source}) {
      $url = $hit->{_source}->{download_url} // q{};
      $version = $hit->{_source}->{version} // q{};
    } elsif (exists $hit->{fields}) {
      $url = $hit->{fields}->{download_url}->[0] // q{};
      $version = $hit->{fields}->{version}->[0] // q{};
    }
  }
  # Case 2: direct release API
  else {
    $url = $data->{download_url} // q{};
    $version = $data->{version} // q{};
  }

  say $url;
  say $version;
'))

DOWNLOAD_URL="${META_FIELDS[0]:-}"
VERSION="${META_FIELDS[1]:-}"

# --- Validate ---
if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "[ERROR] Failed to find download URL for version ${SPECIFIED_VERSION:-latest}." >&2
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  echo "[ERROR] Failed to determine version info." >&2
  exit 1
fi

# --- Prepare file path ---
TARBALL_NAME="${DIST_NAME}-${VERSION}.tar.gz"
TARGET_PATH="${OUT_DIR%/}/$TARBALL_NAME"

if [[ -f "$TARGET_PATH" ]]; then
  echo "[WARN] $TARGET_PATH already exists. Overwriting..."
  rm -f "$TARGET_PATH"
fi

# --- Download ---
echo "[INFO] Downloading $TARBALL_NAME..."
curl -sSfL "$DOWNLOAD_URL" -o "$TARGET_PATH"

echo
cat <<EOM
[INFO] Download complete.
Saved to: $TARGET_PATH

To install, copy the file to your target machine (if offline) and run:
  ./install.sh $TARBALL_NAME
EOM
