# Update the VARIANT arg in devcontainer.json to pick a Perl version
ARG VARIANT=5
FROM perl:${VARIANT}

# [Option] Install zsh
ARG INSTALL_ZSH="false"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY ./.devcontainer/library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "false" "false"

# Install additional packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install libperl-languageserver-perl \
    '^libdist-zilla.*-perl$' \
    libffi-platypus-perl libffi-checklib-perl \
    libcapture-tiny-perl libtest-failwarnings-perl \
    '^libmoose.*-perl$' libperl-prereqscanner-perl \
    libyaml-tiny-perl libjson-maybexs-perl licenseutils \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm Perl::LanguageServer --notest --quiet --skip-satisfied

COPY dist.ini /tmp/
RUN dzil authordeps --root /tmp | cpanm --notest --quiet --skip-satisfied

# Cleanup
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts /tmp/dist.ini /tmp/2023-07-05.tar.gz /tmp/gs1-syntax-engine-2023-07-05
