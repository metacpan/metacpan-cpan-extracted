#!/bin/bash
# Soak / reliability benchmark: hammer Hyperman for a fixed duration (default
# 60s = one minute) and report how many requests FAILED. Where bench.sh cares
# about throughput, this answers "does it stay correct under sustained load?".
#
# A request is counted as failed when it is a wrk socket error (connect / read
# / write / timeout) or the response was Non-2xx/3xx. The server is also run
# with worker recycling (max-requests) so the soak exercises the recycle path
# under load, not just a static pool.
#
# Usage: bench/soak.sh [DURATION] [CONNS] [WORKERS] [THREADS] [MAXREQ]
#   e.g. bench/soak.sh 60s 400 4 4 20000
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/bench/app.psgi"
DUR="${1:-60s}"
CONNS="${2:-400}"
WORKERS="${3:-4}"
THREADS="${4:-4}"
MAXREQ="${5:-20000}"     # recycle each worker after this many requests (0 = off)
PORT=9701
HOST=127.0.0.1
URL="http://$HOST:$PORT/"
PLACKUP="$(command -v plackup)"

command -v wrk >/dev/null || { echo "wrk not found (brew install wrk)"; exit 1; }
[ -n "$PLACKUP" ] || { echo "plackup not found"; exit 1; }

drain() {
    local tries=0
    while netstat -an 2>/dev/null | grep -q "\.$PORT .*TIME_WAIT"; do
        sleep 1; tries=$((tries+1)); [ $tries -gt 40 ] && break
    done
}

start_server() {
    local extra=""
    [ "$MAXREQ" -gt 0 ] 2>/dev/null && extra="--max-requests-per-worker $MAXREQ"
    perl -Mblib="$ROOT/blib" "$PLACKUP" -s Hyperman -E deployment \
        --workers "$WORKERS" $extra --host "$HOST" --port "$PORT" "$APP" \
        >/dev/null 2>&1 &
    SRV_PID=$!
    for _ in $(seq 1 50); do
        curl -s -o /dev/null "$URL" 2>/dev/null && return 0
        sleep 0.2
    done
    return 1
}

stop_server() {
    kill -TERM "$SRV_PID" 2>/dev/null
    pkill -TERM -P "$SRV_PID" 2>/dev/null
    wait "$SRV_PID" 2>/dev/null
    pkill -9 -f "port $PORT" 2>/dev/null
    drain
}

field() {   # $1 = wrk output, $2 = key in the "Socket errors" line
    echo "$1" | sed -n "s/.*$2 \([0-9]*\).*/\1/p" | head -1
}

pkill -9 -f "port $PORT" 2>/dev/null; drain

echo "Hyperman soak / reliability"
echo "duration=$DUR  conns=$CONNS  workers=$WORKERS  threads=$THREADS  max-requests=$MAXREQ"
echo "app=plaintext 'Hello, World!'   client: wrk co-resident (shares cores)"
echo "==============================================================================="

if ! start_server; then
    echo "FAILED TO START"; stop_server; exit 1
fi

OUT="$(wrk -t"$THREADS" -c"$CONNS" -d"$DUR" --latency "$URL" 2>/dev/null)"
stop_server

TOTAL=$(echo "$OUT" | awk '/requests in/{print $1}'); TOTAL=${TOTAL:-0}
CN=$(field "$OUT" connect); CN=${CN:-0}
RD=$(field "$OUT" read);    RD=${RD:-0}
WR=$(field "$OUT" write);   WR=${WR:-0}
TO=$(field "$OUT" timeout); TO=${TO:-0}
NON2=$(echo "$OUT" | awk '/Non-2xx/{print $NF}'); NON2=${NON2:-0}
RPS=$(echo "$OUT" | awk '/Requests\/sec/{print $2}')

FAILED=$((CN + RD + WR + TO + NON2))
if [ "$TOTAL" -gt 0 ]; then
    RATE=$(awk "BEGIN{printf \"%.5f\", ($FAILED/$TOTAL)*100}")
else
    RATE="n/a"
fi

echo
echo "requests completed : $TOTAL"
echo "requests/sec       : ${RPS:-n/a}"
echo "socket errors      : connect=$CN read=$RD write=$WR timeout=$TO"
echo "non-2xx/3xx        : $NON2"
echo "-------------------------------------------------------------------------------"
echo "FAILED REQUESTS    : $FAILED   (${RATE}% of $TOTAL)"
echo
[ "$FAILED" -eq 0 ] && echo "PASS: no failed requests over $DUR" \
                    || echo "note: $FAILED failed request(s) - inspect above"
