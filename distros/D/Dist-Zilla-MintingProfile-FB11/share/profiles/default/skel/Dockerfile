FROM quay.io/opusvl/fb11
MAINTAINER {{ $dist->authors->[0] }}

ARG version
RUN if [ -z "$version" ]; then echo "No version specified"; exit 1; fi

ARG gitrev
RUN if [ -z "$gitrev" ]; then echo "No gitrev provided"; exit 1; fi

RUN echo "$gitrev" > /opt/fb11/{{ $dist->name }}-gitrev
COPY {{ $dist->name }}-$version.tar.gz /opt/fb11
# FIXME - when FB11 tests work, remove -n
RUN cpanm -n /opt/fb11/{{ $dist->name }}*.tar.gz
# FIXME - I don't like FB11 putting the version file in root, but we have to use
# a consistent place for now.
RUN echo {{ $dist->name =~ s/-/::/gr }}@$version >> /version

{{ $confname = lc $dist->name =~ s/-/_/gr; '' }}

COPY {{ $confname }}.yml /srv/fb11/{{ $confname }}.yml
ENV CATALYST_CONFIG /srv/fb11/{{ $confname }}.yml
ENV PSGI /opt/perl5/bin/{{ $confname }}.psgi
