FROM quay.io/opusvl/fb11
MAINTAINER {{ $dist->authors->[0] }}

ARG version
RUN if [ -z "$version" ]; then echo "No version specified"; exit 1; fi

ARG gitrev
RUN if [ -z "$gitrev" ]; then echo "No gitrev provided"; exit 1; fi

RUN echo "$gitrev" > /root/gitstatus.txt
COPY {{ $dist->name }}-$version.tar.gz /
# Currently the [redacted] tests don't even [redacted] work
RUN cpanm -n /{{ $dist->name }}*.tar.gz && rm /{{ $dist->name }}*.tar.gz
RUN echo {{ $dist->name =~ s/-/::/gr }}@$version >> /version

{{ $confname = lc $dist->name =~ s/-/_/gr; '' }}

COPY {{ $confname }}.conf /srv/fb11/{{ $confname }}.conf
ENV CATALYST_CONFIG /srv/fb11/{{ $confname }}.conf
ENV PSGI /opt/perl5/bin/{{ $confname }}.psgi
