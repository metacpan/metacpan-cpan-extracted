# HTTP-Caching
A Perl class that one SHOULD use when building a cache for HTTP responses, it's
brains are wired according to RFC7234

## DEPRECATION WARNING !!!
This module is going to be completely redesigned!!!

As it was planned, these are the brains, but unfortunately, it has become an
implementation.

The future version will answer two questions:
- may_store
- may_reuse

Those are currently implemented as private methods.

Please contact the author if you rely on this module directly to prevent
breakage

Sorry for any inconvenience

## ADVICE
Please use `LPW::UserAgent::Caching` or `LWP::UserAgent::Caching::Simple`.
