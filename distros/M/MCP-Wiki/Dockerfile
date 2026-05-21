# syntax=docker/dockerfile:1
ARG PERL_VERSION=5.40-slim

# Build stage
FROM perl:${PERL_VERSION} AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Install cpanm
RUN cpanm --notest App::cpanminus

COPY cpanfile .
RUN cpanm --installdeps --cpanfile cpanfile --notest

COPY . .

# Build with dzil and install the tarball
RUN cpanm --notest Dist::Zilla Dist::Zilla::PluginBundle::Author::GETTY && \
    dzil build && cpanm ./MCP-Wiki-*.tar.gz && rm -f ./MCP-Wiki-*.tar.gz

# Runtime stage
FROM perl:${PERL_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
    zlib1g-dev \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Create initial non-root user
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash appuser

WORKDIR /home/appuser

# Copy pre-installed modules from build
COPY --from=build /usr/local/lib/perl5/site_perl /usr/local/lib/perl5/site_perl
COPY --from=build /usr/local/bin/mcp-wiki /usr/local/bin/mcp-wiki

# Copy wiki root (empty, for data persistence) and entrypoint
COPY --from=build /build/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN mkdir -p /wiki && chown -R appuser:appgroup /wiki

ENV PERL5LIB=/usr/local/lib/perl5/site_perl/5.40.3:/usr/local/lib/perl5/site_perl/5.40.3/x86_64-linux-gnu
ENV MCP_WIKI_ROOT=/wiki

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["--wiki-root", "/wiki"]
