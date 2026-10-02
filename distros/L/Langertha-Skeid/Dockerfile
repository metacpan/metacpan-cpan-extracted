# Build stage: compiler and libpq headers for the XS modules. Only what cpm installed and
# the checkout leave this stage.
FROM perl:5.38-slim AS build

ARG LANGERTHA_SRC=""

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/skeid

COPY . .
# requires,recommends: DBI, DBD::Pg and DBD::SQLite are what the cpanfile recommends, at the
# versions it names. chmod: the runtime user is not the owner, and a checkout made under a
# tight umask would otherwise be unreadable to it. Cpanel::JSON::XS is a recommends;
# the -M line fails the build should it be missing, whatever cpm did with it. Without it the stream
# relay decodes every SSE frame in pure Perl and loses 43 % throughput (ADR 0019).
RUN cpanm --notest App::cpm \
    && if [ -n "$LANGERTHA_SRC" ]; then cpanm --notest "$LANGERTHA_SRC"; fi \
    && if [ -f cpanfile.snapshot ]; then SNAP="--snapshot=./cpanfile.snapshot"; else SNAP=""; fi \
    && cpm install --cpanfile=./cpanfile $SNAP \
      --global \
      --top-level-relationship requires,recommends \
      --resolver metacpan \
      --workers=$(nproc) \
      --show-build-log-on-failure \
    && perl -MCpanel::JSON::XS -e 1 \
    && chmod -R a+rX /opt/skeid

# Runtime stage: the same perl, the shared libraries the XS modules link against (libssl
# comes with the base image), no compiler.
FROM perl:5.38-slim

# A numeric USER below, so an orchestrator can verify it is not root. The two directories
# are the ones the image offers for writing: jsonlog events and a sqlite database. A named
# volume mounted there takes this ownership.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    jq \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 skeid \
    && useradd --uid 10001 --gid 10001 --no-create-home --home-dir /opt/skeid \
      --shell /usr/sbin/nologin skeid \
    && mkdir -p /var/log/skeid/events /var/lib/skeid \
    && chown -R 10001:10001 /var/log/skeid /var/lib/skeid

COPY --from=build /usr/local/lib/perl5/site_perl /usr/local/lib/perl5/site_perl
COPY --from=build /opt/skeid /opt/skeid

WORKDIR /opt/skeid

# Fails the build when a shared library an XS module needs is missing from this stage.
RUN perl -MDBI -MDBD::Pg -MDBD::SQLite -MIO::Socket::SSL -MCpanel::JSON::XS -e 1

USER 10001:10001

EXPOSE 8090

# SIGQUIT is the graceful stop. Mojolicious's prefork manager answers SIGTERM by SIGKILLing its
# workers, which loses what a write-behind usage store (usage_store.flush_interval_ms, k78)
# still holds; on SIGQUIT the workers run END and flush. A single process handles it too
# (bin/skeid). docker stop sends this, then SIGKILL after its grace period (10 s by default):
# raise it (`--time`, compose stop_grace_period) when streams outlive that.
STOPSIGNAL SIGQUIT

ENTRYPOINT ["perl", "-Ilib", "bin/skeid"]
CMD ["serve", "--listen", "0.0.0.0:8090", "--config", "/etc/skeid/skeid.yaml"]
