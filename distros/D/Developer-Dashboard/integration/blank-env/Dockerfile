FROM perl:5.44-threaded-bookworm@sha256:4bc64abbc2d74e0354b6b8af8229456183a516eff033dc986ff3d3bf78326c79

ENV PERL_MM_USE_DEFAULT=1 \
    NONINTERACTIVE_TESTING=1 \
    PERL_CANARY_STABILITY_NOPROMPT=1

RUN perl -MConfig -e 'die "Perl interpreter must be built with ithreads\\n" if !$Config{useithreads}'

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
        libayatana-appindicator3-dev \
        libexpat1-dev \
        libgtk-3-dev \
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
