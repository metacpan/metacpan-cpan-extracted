#!/usr/bin/env python3
"""Small dependency-free teaching server. Not for production traffic."""
from __future__ import annotations
import json
import os
import signal
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path not in ('/', '/health'):
            self.send_error(404)
            return
        payload = json.dumps({'status': 'ok', 'mode': os.environ.get('APP_MODE', 'lab')}).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def main() -> None:
    port = int(os.environ.get('PORT', '8080'))
    if not 1 <= port <= 65535:
        raise ValueError('PORT must be between 1 and 65535')
    state = Path(os.environ.get('STATE_DIR', '/tmp'))
    state.mkdir(parents=True, exist_ok=True)
    (state / 'last-start.txt').write_text('started\n', encoding='utf-8')
    with ThreadingHTTPServer((os.environ.get('HOST', '0.0.0.0'), port), Handler) as server:
        server.timeout = 0.25
        server.daemon_threads = True
        stopping = False

        def stop(signum: int, _frame: object) -> None:
            nonlocal stopping
            stopping = True

        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGINT, stop)
        print(f'Listening on {port}', flush=True)
        while not stopping:
            server.handle_request()
        print('Graceful stop', flush=True)


if __name__ == '__main__':
    main()
