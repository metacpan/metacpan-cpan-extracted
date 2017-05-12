FROM perl:5.24.0
MAINTAINER  Markus Benning <ich@markusbenning.de>

COPY ./cpanfile /saftpresse/cpanfile
WORKDIR /saftpresse

RUN apt-get update \
  && apt-get install uuid-dev telnet \
  && apt-get clean \
  && cpanm --notest Carton \
  && carton install \
  && rm -rf ~/.cpanm

RUN addgroup --system saftpresse \
  && adduser --system --home /saftpresse --no-create-home \
    --disabled-password --ingroup saftpresse saftpresse

COPY . /saftpresse
COPY ./etc/docker.conf /etc/saftpresse/saftpresse.conf

EXPOSE 10514
EXPOSE 20514

CMD [ "carton",  "exec", "perl", "-Mlib=./lib", "bin/saftpresse", "-c", "/etc/saftpresse/saftpresse.conf" ]
