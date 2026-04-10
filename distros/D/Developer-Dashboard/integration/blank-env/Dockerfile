FROM ubuntu:24.04@sha256:84e77dee7d1bc93fb029a45e3c6cb9d8aa4831ccfcc7103d36e876938d28895b

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
        procps \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm --notest \
        Capture::Tiny \
        JSON::XS

WORKDIR /opt/integration

COPY integration/blank-env/run-integration.pl /opt/integration/run-integration.pl

CMD ["perl", "/opt/integration/run-integration.pl"]
