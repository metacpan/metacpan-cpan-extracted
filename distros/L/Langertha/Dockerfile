# ------------------------------------------------------------------ builder
FROM perl:5.40-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libssl-dev zlib1g-dev curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm \
        -o /usr/local/bin/cpm \
    && chmod +x /usr/local/bin/cpm

WORKDIR /usr/local/src/Langertha
COPY . .

# The Docker context is the Dist::Zilla-built distribution directory. Install
# prerequisites from the cpanfile through cpm -- the recommended async
# transport (IO::Async, Net::Async::HTTP) included --, then what Makefile.PL
# itself needs (the configure phase of the built META.json, which the cpanfile
# does not carry), then install the dist.
RUN cpm install -g \
        --cpanfile cpanfile \
        --resolver metacpan \
        --with-recommends \
        --without-test \
    && cpm install -g \
        --metafile META.json \
        --resolver metacpan \
        --top-level-phase configure \
    && perl Makefile.PL \
    && make install \
    && rm -rf ~/.perl-cpm ~/.cpanm

# ------------------------------------------------------------------ runtime
# Perl with Langertha installed: a base image for applications built on it,
# and a place to run the bundled langertha_* example scripts. No compiler.
FROM perl:5.40-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/perl5/site_perl/ /usr/local/lib/perl5/site_perl/
COPY --from=builder /usr/local/bin/                 /usr/local/bin/

# Fails the build when a shared library an XS module needs is missing here.
RUN perl -MLangertha -MIO::Socket::SSL -MNet::Async::HTTP -e 1

CMD ["perl", "-MLangertha", "-E", "say qq{Langertha $Langertha::VERSION}"]
