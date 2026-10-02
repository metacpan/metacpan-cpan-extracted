#!/bin/sh
# One-shot setup for the example stack. Runs in the openbao image (see docker-compose.yml), so
# the only tool it needs is the bao CLI that image ships. POSIX sh: the image has no bash.
#
# Needs BAO_ADDR and BAO_TOKEN (the dev root token). Writes into OpenBao:
#   - the AppRole skeid-service and the policy skeid-keys (read secret/skeid/*)
#   - provider keys from SKEID_GROQ_KEY / SKEID_OPENAI_KEY / SKEID_ANTHROPIC_KEY, when set,
#     at secret/skeid/remote/<provider> -- where a node's api_key_ref points
# It creates no usage table (Skeid applies share/sql/usage_events.postgresql.sql itself on
# start) and stores no customer keys (Skeid never looks one up).
set -eu

ROLE_NAME=skeid-service
POLICY_NAME=skeid-keys

echo "=== Skeid init ==="

# depends_on already waits for a healthy openbao; this only bounds a slow start.
tries=0
until bao status > /dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "$tries" -ge 30 ]; then
    echo "OpenBao at ${BAO_ADDR} did not answer after 60s -- giving up" >&2
    exit 1
  fi
  sleep 2
done
echo "OpenBao at ${BAO_ADDR} is up"

echo "=== Policy and AppRole ==="

# KV v2: reads go to secret/data/..., listing to secret/metadata/...
bao policy write "$POLICY_NAME" - << 'POLICY'
path "secret/data/skeid/*" {
  capabilities = ["read"]
}
path "secret/metadata/skeid/*" {
  capabilities = ["list"]
}
POLICY

if bao auth list | grep -q '^approle/'; then
  echo "approle auth already enabled"
else
  bao auth enable approle
fi

# token_max_ttl: renewal stops there, Skeid exits and its restart logs in again with the same
# secret_id. The secret_id gets no use limit and no TTL -- a dev convenience; a production role
# limits both and hands every start a fresh one.
bao write "auth/approle/role/${ROLE_NAME}" \
  token_ttl=1h \
  token_max_ttl=24h \
  token_policies="$POLICY_NAME"

ROLE_ID=$(bao read -field=role_id "auth/approle/role/${ROLE_NAME}/role-id")
SECRET_ID=$(bao write -f -field=secret_id "auth/approle/role/${ROLE_NAME}/secret-id")

echo "=== Provider keys ==="

# The key goes in on stdin (api_key=-), so it is never in a process argument list.
store_key() {
  provider=$1
  key=$2
  if [ -n "$key" ]; then
    printf '%s' "$key" | bao kv put "secret/skeid/remote/${provider}" api_key=- > /dev/null
    echo "stored secret/skeid/remote/${provider}"
  else
    echo "skipped secret/skeid/remote/${provider} (no key given)"
  fi
}

store_key groq      "${SKEID_GROQ_KEY:-}"
store_key openai    "${SKEID_OPENAI_KEY:-}"
store_key anthropic "${SKEID_ANTHROPIC_KEY:-}"

echo ""
echo "=== Done ==="
echo ""
echo "Put these two lines into .env, then: docker compose up -d skeid"
echo ""
echo "OPENBAO_ROLE_ID=${ROLE_ID}"
echo "OPENBAO_SECRET_ID=${SECRET_ID}"
echo ""
echo "OpenBao runs in dev mode and keeps everything in memory: after any restart of the openbao"
echo "container, run this job again and replace both lines."
echo ""
echo "Customer keys are not stored anywhere. Skeid takes any bearer key and routes and bills it"
echo "under its key id; that id (never the key) is what skeid.yaml's names:/keys: hold:"
echo "  echo sk-alice-secret-key | docker run --rm -i raudssus/langertha-skeid keyid"
