#!/bin/bash
# Benchmark Hyperman vs Gazelle vs Starman on an identical plaintext PSGI app.
#
# All three are prefork PSGI servers; each runs with the same worker count and
# is hit with wrk (keep-alive). wrk runs co-resident with the server on this
# box (they share cores), so numbers are RELATIVE — good for comparing the
# three here, not for absolute headline figures (those need a separate load
# box). Socket errors and non-2xx are reported so degraded runs are visible.
# Between runs we drain TIME_WAIT sockets so the port is reusable.
#
# Usage: bench/bench.sh [WORKERS] [DURATION] [CONNS...]
#   e.g. bench/bench.sh 4 10s 50 200 1000
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/bench/app.psgi"
WORKERS="${1:-4}"
DUR="${2:-10s}"
shift 2 2>/dev/null || true
CONNS_LIST="${*:-200}"
PORT=9700
HOST=127.0.0.1
URL="http://$HOST:$PORT/"
THREADS=4
PLACKUP="$(command -v plackup)"

command -v wrk >/dev/null || { echo "wrk not found (brew install wrk)"; exit 1; }

drain() {
    local tries=0
    while netstat -an 2>/dev/null | grep -q "\.$PORT .*TIME_WAIT"; do
        sleep 1; tries=$((tries+1)); [ $tries -gt 40 ] && break
    done
}

start_server() {   # $1 = name -> sets global SRV_PID, returns 0 if up
    local name="$1"
    case "$name" in
        Hyperman) perl -Mblib="$ROOT/blib" "$PLACKUP" -s Hyperman -E deployment \
                      --workers "$WORKERS" --host "$HOST" --port "$PORT" "$APP" \
                      >/dev/null 2>&1 & ;;
        Gazelle)  plackup -s Gazelle -E deployment \
                      --workers "$WORKERS" --host "$HOST" --port "$PORT" "$APP" \
                      >/dev/null 2>&1 & ;;
        Starman)  starman --workers "$WORKERS" -E deployment \
                      --host "$HOST" --port "$PORT" "$APP" >/dev/null 2>&1 & ;;
    esac
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

bench_one() {   # $1 name, $2 conns
    local name="$1" conns="$2"
    if ! start_server "$name"; then
        printf "  %-9s c=%-5s  FAILED TO START\n" "$name" "$conns"
        stop_server; return
    fi
    local out rps lat errs non2
    out="$(wrk -t"$THREADS" -c"$conns" -d"$DUR" "$URL" 2>/dev/null)"
    rps="$(echo "$out"  | awk '/Requests\/sec/{print $2}')"
    lat="$(echo "$out"  | awk '/^[[:space:]]*Latency/{print $2; exit}')"
    errs="$(echo "$out" | awk '/Socket errors/{print}' | sed 's/^ *Socket errors: //')"
    non2="$(echo "$out" | awk '/Non-2xx/{print $NF}')"
    printf "  %-9s c=%-5s %12s req/s  lat %-9s %s%s\n" \
        "$name" "$conns" "${rps:-n/a}" "${lat:-n/a}" \
        "${errs:+[errs: $errs] }" "${non2:+[non-2xx: $non2]}"
    stop_server
}

pkill -9 -f "port $PORT" 2>/dev/null; drain
echo "Hyperman vs Gazelle vs Starman"
echo "workers=$WORKERS  duration=$DUR  threads=$THREADS  app=plaintext 'Hello, World!'"
echo "client: wrk, co-resident (shares cores) -> numbers are RELATIVE"
echo "==============================================================================="
for c in $CONNS_LIST; do
    echo "concurrency = $c connections:"
    for s in Hyperman Gazelle Starman; do bench_one "$s" "$c"; done
    echo
done
echo "done."
