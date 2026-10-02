# ------------------------------------------------------------------ builder
FROM perl:5.40-slim AS builder

ARG RAIDER_VERSION=dev
ARG RAIDER_SRC=/usr/local/src/Langertha-Raider-${RAIDER_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libssl-dev libreadline-dev libxml2-dev \
        zlib1g-dev git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm \
        -o /usr/local/bin/cpm \
    && chmod +x /usr/local/bin/cpm

WORKDIR ${RAIDER_SRC}
COPY . .

# The Docker context is the Dist::Zilla-built distribution directory. Install
# prerequisites from the cpanfile through cpm, then install the dist.
RUN cpm install -g \
        --cpanfile cpanfile \
        --resolver metacpan \
        --with-recommends \
        --without-test \
    && perl Makefile.PL \
    && make install \
    && rm -rf ~/.perl-cpm ~/.cpanm

# ------------------------------------------------------------------ runtime-base
FROM perl:5.40-slim AS runtime-base

RUN apt-get update && apt-get install -y --no-install-recommends \
        libreadline8 libssl3 libxml2 zlib1g git ca-certificates gosu passwd \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/perl5/site_perl/ /usr/local/lib/perl5/site_perl/
COPY --from=builder /usr/local/bin/                 /usr/local/bin/

RUN mkdir -p /home/raider /work
ENV HOME=/home/raider \
    TERM=xterm-256color
WORKDIR /work

# ------------------------------------------------------------------ runtime-root
# Runs as root. This is the Docker Hub default and works well for one-off
# sessions against a bind-mounted project tree.
FROM runtime-base AS runtime-root
ENTRYPOINT ["raider"]

# ------------------------------------------------------------------ runtime-user
# Runs as a non-root user. Build with --build-arg RAIDER_UID=$(id -u) and
# --build-arg RAIDER_GID=$(id -g) to match host ownership under /work.
FROM runtime-base AS runtime-user
ARG RAIDER_UID=1000
ARG RAIDER_GID=1000
RUN groupadd -g ${RAIDER_GID} raider \
    && useradd -m -d /home/raider -u ${RAIDER_UID} -g ${RAIDER_GID} -s /bin/sh raider \
    && chown -R ${RAIDER_UID}:${RAIDER_GID} /home/raider /work
USER raider
ENTRYPOINT ["raider"]
