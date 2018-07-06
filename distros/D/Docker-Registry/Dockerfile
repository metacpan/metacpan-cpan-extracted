FROM perl:latest

ENV DEBIAN_FRONTEND=noninteractive

COPY cpanfile .
RUN cpanm --installdeps .

COPY . .

RUN prove -lv t/*
RUN cpanm .
