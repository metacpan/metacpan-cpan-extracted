# Project Name - HTTP-API-Client #

A lightweight `LWP::UserAgent` wrapper for authenticated JSON/form REST
APIs: an event/callback system for computing signed-request headers from
the request's own data at build time, retry-with-backoff, and
`xTRUE`/`xCSV`-style data type markers for the values a plain Perl scalar
can't represent unambiguously. See `lib/HTTP/API/Client.pm`'s POD for the
full API and a worked signing example.

# SETUP #
--------------------------------------------------------------
## Prerequisites ##

Either a system Perl with the `cpanfile` dependencies installed, or Docker.

## Running the tests ##

Locally (needs a system Perl with the cpanfile deps installed):

 >> cd src
 >> cpanm --installdeps .
 >> PERL5LIB=lib prove -r t

In Docker (matches CI - the root Dockerfile runs the same suite):

 >> docker build -t http-api-client .
 >> docker run --rm http-api-client

-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-===-=

## Coverage ##

 >> cpanm --installdeps --with-develop .
 >> PERL5LIB="lib:$PERL5LIB" PERL5OPT=-MDevel::Cover prove -r t
 >> PERL5LIB="lib:$PERL5LIB" cover

Threshold: **75% statement coverage** on `lib/`, tracked per-module. Current baseline (2026-08-19): `HTTP/API/Client.pm` 100% statement / 96.2% branch / 91.6% condition, `HTTP/API/DataTypeMarker.pm` 100%. Branch/condition coverage is measured and reported but not gated yet - most of the remaining gap is branches that are structurally always-true (e.g. `pre_defined_data` is never falsy, so its `if` guard has no untaken side) rather than genuinely missing scenarios.

`cover_db/` is a generated artifact - never commit it.

-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-===-=

# Developers #

 * Michael Vu <email@michael.vu>

# License #

MIT
