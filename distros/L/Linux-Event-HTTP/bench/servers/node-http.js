'use strict';

const http = require('node:http');

const port = Number(process.env.BENCH_PORT);
const responseBytes = Number(process.env.BENCH_RESPONSE_BYTES || 32);
if (!Number.isInteger(port) || port <= 0) {
  throw new Error('BENCH_PORT is required');
}
const payload = Buffer.alloc(responseBytes, 0x78);

const server = http.createServer((req, res) => {
  req.on('data', () => {});
  req.on('end', () => {
    res.writeHead(200, {
      'Content-Type': 'application/octet-stream',
      'Content-Length': payload.length,
    });
    res.end(payload);
  });
});

server.listen(port, '127.0.0.1');
