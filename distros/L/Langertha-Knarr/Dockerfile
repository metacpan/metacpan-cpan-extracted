FROM perl:5.38-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest \
    Langertha \
    Mojolicious \
    Moo \
    MooX::Cmd \
    MooX::Options \
    YAML::PP \
    JSON::MaybeXS \
    Log::Any \
    Log::Any::Adapter::Stderr

WORKDIR /app
COPY lib/ lib/
COPY bin/ bin/
COPY share/ share/

ENV PERL5LIB=/app/lib
EXPOSE 8080 11434

# Default: container mode (auto-detect from ENV, listen on 0.0.0.0)
# With config: mount to /etc/knarr/config.yaml and use CMD ["start", "-c", "/etc/knarr/config.yaml"]
ENTRYPOINT ["perl", "bin/knarr"]
CMD ["container"]
