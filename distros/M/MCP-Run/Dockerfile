# ------------------------------------------------------------------ builder
FROM perl:5.40-slim AS builder

ARG MCP_RUN_VERSION=dev
ARG MCP_RUN_SRC=/usr/local/src/MCP-Run-${MCP_RUN_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libssl-dev zlib1g-dev curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm \
        -o /usr/local/bin/cpm \
    && chmod +x /usr/local/bin/cpm

WORKDIR ${MCP_RUN_SRC}
COPY . .

# The Docker context is the Dist::Zilla-built distribution directory. Install
# declared prereqs from cpanfile, then install the dist itself.
RUN cpm install -g \
        --cpanfile cpanfile \
        --resolver metacpan \
        --without-test \
        --with-recommends \
    && perl Makefile.PL \
    && make install \
    && rm -rf ~/.perl-cpm ~/.cpanm

# ------------------------------------------------------------------ runtime
FROM perl:5.40-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        libssl3 zlib1g ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/perl5/site_perl/ /usr/local/lib/perl5/site_perl/
COPY --from=builder /usr/local/bin/                 /usr/local/bin/

# Marks this image as the "docker" install flavor. bin/mcp-run-compress reads
# MCP_RUN_COMPRESS_INSTALL_MODE to decide whether --install-claude should
# register a native (`mcp-run-compress --hook`) or Docker
# (`docker run … --hook`) hook command, and whether --hook should rewrite
# Bash commands to `--b64 …` (native) or to a host-side pipe-through-docker
# snippet (docker). Native Perl installs never have this var set.
ARG MCP_RUN_VERSION=dev
ENV MCP_RUN_COMPRESS_INSTALL_MODE=docker \
    MCP_RUN_COMPRESS_IMAGE=raudssus/mcp-run-compress:${MCP_RUN_VERSION}

ENTRYPOINT ["mcp-run-compress"]
