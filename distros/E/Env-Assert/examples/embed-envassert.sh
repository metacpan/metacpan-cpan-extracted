#!/usr/bin/env sh

# Get error when using unset (environment) variables.
set -u

# Ensure we have the required environment setup.
envassert --stdin <<'EOF'
NUMERIC_VAR=^[[:digit:]]+$
TIME_VAR=^\d{2}:\d{2}:\d{2}$
EOF

echo "${NUMERIC_VAR}: ${TIME_VAR}"
exit

# Run this example without installing the distribution:
# PERL5LIB=lib PATH="bin:${PATH}" NUMERIC_VAR=123 TIME_VAR=02:04:06 examples/embed-envassert.sh
