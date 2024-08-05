FROM perl:latest

ARG LANGERTHA_UID="1000"
ARG LANGERTHA_GID="1000"
ARG LANGERTHA_VERSION=""

ENV LANGERTHA_UID ${LANGERTHA_UID}
ENV LANGERTHA_GID ${LANGERTHA_GID}
ENV LANGERTHA_VERSION ${LANGERTHA_VERSION}

# Install Debian packages ----------------------------------------------------

ENV DEBIAN_FRONTEND  "noninteractive"

RUN echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" > /debconf-preseed.txt \
  && echo "locales locales/default_environment_locale select en_US.UTF-8" >> /debconf-preseed.txt \
  && debconf-set-selections /debconf-preseed.txt && apt-get update -y \
  && apt-get install -y lsb-release locales apt-utils \
  && debconf-set-selections /debconf-preseed.txt \
  && apt-get update -y \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/* /var/cache/*

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENV LANGERTHA_PROJECT_ROOT  "/opt/langertha"

RUN mkdir /home/langertha \
  && groupadd -g ${LANGERTHA_GID} langertha \
  && useradd -s /bin/bash -d /home/langertha -u ${LANGERTHA_UID} -g ${LANGERTHA_GID} langertha \
  && chown ${LANGERTHA_UID}:${LANGERTHA_GID} /home/langertha \
  && rm -rf /tmp/*

RUN install -o ${LANGERTHA_UID} -g ${LANGERTHA_GID} -d ${LANGERTHA_PROJECT_ROOT}/install

USER ${LANGERTHA_UID}:${LANGERTHA_GID}

WORKDIR ${LANGERTHA_PROJECT_ROOT}/src

# Install Perl Modules --------------------------------------------------------

ENV PATH                 "${LANGERTHA_PROJECT_ROOT}/install/perl5/bin:${PATH}"
ENV PERL5LIB             "${LANGERTHA_PROJECT_ROOT}/install/perl5/lib/perl5"
ENV PERL_LOCAL_LIB_ROOT  "${LANGERTHA_PROJECT_ROOT}/install/perl5"
ENV PERL_MB_OPT          "--install_base ${LANGERTHA_PROJECT_ROOT}/install/perl5"
ENV PERL_MM_OPT          "INSTALL_BASE=${LANGERTHA_PROJECT_ROOT}/install/perl5"
ENV PERL_CARTON_PATH     "${LANGERTHA_PROJECT_ROOT}/install/perl5"

COPY --chown=${LANGERTHA_UID}:${LANGERTHA_GID} ./cpanfile ${LANGERTHA_PROJECT_ROOT}/src

RUN cpm install --cpanfile=./cpanfile --workers=$(nproc) \
  --local-lib-contained=${PERL_LOCAL_LIB_ROOT} && rm -rf ~/.perl-cpm/ /tmp/*

COPY --chown=${LANGERTHA_UID}:${LANGERTHA_GID} . ${LANGERTHA_PROJECT_ROOT}/src

# Add project path ------------------------------------------------------------

ENV PATH "${LANGERTHA_PROJECT_ROOT}/src/bin:${PATH}"

ENTRYPOINT ["/docker-entrypoint.sh"]
