FROM perl:5.24
RUN cpanm Carton
COPY cpanfile /src/cpanfile
WORKDIR /src
RUN carton install
COPY Makefile /src/Makefile
COPY . /src
