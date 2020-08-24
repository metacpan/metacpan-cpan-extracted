FROM perl:5.30.0
RUN cpanm Carton

COPY cpanfile .
RUN carton install

COPY . .
RUN perl Makefile.PL
CMD ["carton", "exec", "cover", "-t"]
