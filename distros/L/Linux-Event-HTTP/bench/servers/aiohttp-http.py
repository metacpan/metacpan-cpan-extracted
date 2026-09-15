#!/usr/bin/env python3
import os
from aiohttp import web

port = int(os.environ["BENCH_PORT"])
response_bytes = int(os.environ.get("BENCH_RESPONSE_BYTES", "32"))
payload = b"x" * response_bytes

async def bench(request: web.Request) -> web.Response:
    if request.can_read_body:
        await request.read()
    return web.Response(
        body=payload,
        headers={
            "Content-Type": "application/octet-stream",
            "Content-Length": str(len(payload)),
        },
    )

app = web.Application()
app.router.add_route("*", "/bench", bench)

web.run_app(
    app,
    host="127.0.0.1",
    port=port,
    access_log=None,
    print=lambda *args, **kwargs: None,
)
