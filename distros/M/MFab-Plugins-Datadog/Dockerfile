FROM alpine:3.20

# Install perl and required system dependencies
RUN apk add --no-cache \
    perl \
    perl-dev \
    perl-app-cpanminus \
    make \
    gcc \
    musl-dev \
    gmp-dev

# Set working directory
WORKDIR /app

# application files
COPY Makefile.PL .
COPY lib lib

# Install dependencies
RUN cpanm --install .

# Copy example application
COPY example example

# Default command
CMD ["/app/example/run.sh"]
EXPOSE 4301
