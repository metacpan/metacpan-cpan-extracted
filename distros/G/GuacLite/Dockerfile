FROM perl:latest

WORKDIR /opt/guaclite

COPY cpanfile .
RUN cpanm --installdeps .

COPY script script/
COPY share share/
COPY lib lib/

ENTRYPOINT ["perl", "script/guaclite", "daemon"]

