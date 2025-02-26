# FU - Framework Ultimatum: A Lean and Efficient Zero-Dependency Web Framework

FU is a web development framework for Perl and a collection of handy utility
modules.

*Contributing:* Refer to my [contribution guidelines](https://dev.yorhel.nl/contributing).

## Project Status

**EXPERIMENTAL**; expect breaking changes.

## Build & Install

```sh
perl Makefile.PL
make
make install
```

## Project ideas

Things that may or may not happen:

- FU::JSON - JSON::{XS,PP,etc}-compatible wrapper around FU::Util's JSON functions? I prolly won't need this myself, but could be handy.
- FU::DBI - DBI wrapper with a FU::Pg-like API, for easier integration into FU.
- FU::Mailer - Simple sendmail wrapper

# License

MIT.
