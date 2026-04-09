FROM test_by_michael-app:latest

RUN apt-get update; apt-get install -y libdbi-perl libdbd-sqlite3-perl libdbd-mysql-perl libdbd-pg-perl default-libmysqlclient-dev libpq-dev

RUN cpanm --notest DBI DBD::SQLite

COPY DD.tgz /tmp/DD.tgz

RUN cpanm /tmp/DD.tgz -v

RUN apt update && apt install -y vim
