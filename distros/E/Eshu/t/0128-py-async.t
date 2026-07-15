use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── async def ────────────────────────────────────────────────────

{
    my $src = "async def fetch(url):\n    return await get(url)\n";
    my $out = py($src);
    like($out, qr/^async def fetch\(url\):$/m, 'async def at depth 0');
    like($out, qr/^    return await get\(url\)$/m, 'body with await at depth 1');
}

# ── async def inside class ───────────────────────────────────────

{
    my $src = <<'SRC';
class Client:
    async def connect(self):
        self.sock = await open_connection()
    async def close(self):
        await self.sock.close()
SRC
    my $out = py($src);
    like($out, qr/^    async def connect\(self\):$/m, 'async def at depth 1');
    like($out, qr/^        self\.sock = await/m,      'body at depth 2');
    like($out, qr/^    async def close\(self\):$/m,   'second async def at depth 1');
    like($out, qr/^        await self\.sock/m,        'close body at depth 2');
}

# ── async for ────────────────────────────────────────────────────

{
    my $src = <<'SRC';
async def consume(stream):
    async for chunk in stream:
        process(chunk)
SRC
    my $out = py($src);
    like($out, qr/^    async for chunk in stream:$/m, 'async for at depth 1');
    like($out, qr/^        process\(chunk\)$/m,        'async for body at depth 2');
}

# ── async with ───────────────────────────────────────────────────

{
    my $src = <<'SRC';
async def read_file(path):
    async with aiofiles.open(path) as f:
        data = await f.read()
    return data
SRC
    my $out = py($src);
    like($out, qr/^    async with aiofiles/m,       'async with at depth 1');
    like($out, qr/^        data = await f\.read/m,  'async with body at depth 2');
    like($out, qr/^    return data$/m,               'return after async with at depth 1');
}

# ── await expression ─────────────────────────────────────────────

{
    my $src = <<'SRC';
async def main():
    result = await asyncio.gather(
        task1(),
        task2(),
    )
    return result
SRC
    my $out = py($src);
    like($out, qr/^    result = await asyncio\.gather\($/m, 'await gather at depth 1');
    like($out, qr/^        task1\(\),$/m,                    'arg at depth 2');
    like($out, qr/^    \)$/m,                                'closing paren at depth 1');
    like($out, qr/^    return result$/m,                     'return at depth 1');
}

# ── try/except inside async def ──────────────────────────────────

{
    my $src = <<'SRC';
async def safe_fetch(url):
    try:
        data = await fetch(url)
    except aiohttp.ClientError:
        data = None
    return data
SRC
    my $out = py($src);
    like($out, qr/^    try:$/m,                        'try at depth 1');
    like($out, qr/^        data = await fetch\(url\)$/m, 'await in try body at depth 2');
    like($out, qr/^    except aiohttp\.ClientError:$/m, 'except at depth 1');
    like($out, qr/^    return data$/m,                  'return at depth 1');
}

# ── nested async defs ────────────────────────────────────────────

{
    my $src = <<'SRC';
async def outer():
    async def inner():
        await do_thing()
    await inner()
SRC
    my $out = py($src);
    like($out, qr/^    async def inner\(\):$/m, 'nested async def at depth 1');
    like($out, qr/^        await do_thing\(\)$/m, 'inner body at depth 2');
    like($out, qr/^    await inner\(\)$/m,       'outer body resumes depth 1');
}

# ── async comprehension ──────────────────────────────────────────

{
    my $src = "async def f():\n    results = [x async for x in aiter]\n    return results\n";
    my $out = py($src);
    like($out, qr/^    results = \[x async for/m, 'async comprehension in list at depth 1');
    like($out, qr/^    return results$/m,           'return at depth 1');
}

done_testing;
