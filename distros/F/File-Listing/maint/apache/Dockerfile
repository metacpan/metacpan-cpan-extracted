FROM httpd:2.4

RUN mkdir -p /usr/local/apache2/htdocs/File-Listing && \
    cd /usr/local/apache2/htdocs/                   && \
    ln -s File-Listing default                      && \
    ln -s File-Listing fancy-indexing               && \
    ln -s File-Listing html-table                   && \
    ln -s File-Listing old-date                     && \
    ln -s File-Listing xhtml                        && \
    ln -s File-Listing with-icons                   && \
    ln -s File-Listing html-table-with-icons
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY index.html /usr/local/apache2/htdocs/index.html
