FROM debian:buster

# build:
# docker pull debian:buster && docker build --tag "lgehlen/math_matrix_banded_base:$(TZ='UTC' date '+%Y%m%dT%H%M%SZ')" --tag "lgehlen/math_matrix_banded_base:latest" "docker"
# run (assuming the repo sits in /data/git/math-matrix-banded):
# docker run --volume "/data/git/math-matrix-banded:/usr/local/math-matrix-banded" --workdir "/usr/local/math-matrix-banded" lgehlen/math_matrix_banded_base perl -M5.014 -Ilib -MMath::Matrix::Banded -e 'say "Hello World"'

RUN apt-get update \
    && apt-get install --assume-yes \
       less \
       build-essential \
       perl \
       cpanminus

RUN cpanm Moo
RUN cpanm List::Util
RUN cpanm Try::Tiny
