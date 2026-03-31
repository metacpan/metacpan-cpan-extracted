FROM perl:5.38-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cpanminus \
        chromium \
        curl \
        fonts-liberation \
        git \
        iproute2 \
        procps \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest \
        Capture::Tiny \
        JSON::XS

WORKDIR /opt/integration

COPY integration/blank-env/run-integration.pl /opt/integration/run-integration.pl

CMD ["perl", "/opt/integration/run-integration.pl"]
