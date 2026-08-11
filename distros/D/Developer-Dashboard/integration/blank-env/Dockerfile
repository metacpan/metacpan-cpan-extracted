FROM perl:5.44-bookworm@sha256:3f99fa84d0a7f83faf8012d757b41a04b5522f1eb9fe089eba8712f858215264

ENV PERL_MM_USE_DEFAULT=1 \
    NONINTERACTIVE_TESTING=1 \
    PERL_CANARY_STABILITY_NOPROMPT=1

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
        libexpat1-dev \
        libssl-dev \
        pkg-config \
        procps \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest \
        Capture::Tiny \
        JSON::XS

WORKDIR /opt/integration

COPY integration/blank-env/run-integration.pl /opt/integration/run-integration.pl

CMD ["perl", "/opt/integration/run-integration.pl"]
