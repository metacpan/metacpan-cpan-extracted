FROM perl:5.38-slim

ARG KNARR_ROOT="/opt/knarr"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cpan -T App::cpm

RUN mkdir /home/knarr && useradd -s /bin/bash -d /home/knarr -u 1000 knarr && chown knarr.knarr /home/knarr && rm -rf /tmp/*

RUN install -o knarr -d $KNARR_ROOT/install $KNARR_ROOT/src

USER knarr:knarr

WORKDIR "$KNARR_ROOT/src"

# Install cpan modules -------------------------------------------------------

ENV PATH="$KNARR_ROOT/install/perl5/bin:${PATH}"
ENV PERL5LIB="$KNARR_ROOT/install/perl5/lib/perl5"
ENV PERL_LOCAL_LIB_ROOT="$KNARR_ROOT/install/perl5"
ENV PERL_MB_OPT="--install_base $KNARR_ROOT/install/perl5"
ENV PERL_MM_OPT="INSTALL_BASE=$KNARR_ROOT/install/perl5"

COPY --chown=knarr:knarr ./cpanfile $KNARR_ROOT/src

RUN cpm install --cpanfile=./cpanfile \
  --resolver 02packages,https://cpan.metacpan.org \
  --workers=$(nproc) --local-lib-contained=$PERL_LOCAL_LIB_ROOT \
  && rm -rf ~/.perl-cpm/ /tmp/*

# Install project -------------------------------------------------------------

COPY --chown=knarr:knarr . $KNARR_ROOT/src

ENV PERL5LIB="$KNARR_ROOT/src/lib:$KNARR_ROOT/install/perl5/lib/perl5"

EXPOSE 8080 11434

# Set KNARR_DEBUG=1 to enable verbose logging to stderr
ENTRYPOINT ["perl", "bin/knarr"]
CMD ["start", "--from-env", "-p", "8080", "-p", "11434"]
