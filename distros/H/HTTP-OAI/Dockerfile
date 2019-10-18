FROM perl:5.30

COPY . /usr/src/app
WORKDIR /usr/src/app
RUN cpanm --quiet . LWP::Protocol::https
#RUN cpanm --quiet --installdeps --notest --force --skip-satisfied .
#RUN cpanm --quiet --notest --skip-satisfied Devel::Cover
#RUN perl Build.PL && ./Build build && cover -test

# For compatibility with Debian suffix-less scripts
RUN ln -s /usr/local/bin/oai_browser.pl /usr/local/bin/oai_browser && \
    ln -s /usr/local/bin/oai_pmh.pl /usr/local/bin/oai_pmh

WORKDIR /tmp
CMD ["/usr/local/bin/oai_browser"]
