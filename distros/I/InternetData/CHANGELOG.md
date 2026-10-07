# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff. Releases before 1.6.1 are described by their release commits.

## 1.8.2 - 2026-10-07

### Fixes

- Raise a database answer missing what the call returns as server_error ([`8547698`](https://github.com/internetdata/sdk-perl/commit/854769899db6d73f7e4a1b52cf35d9057747eb13))

## 1.8.1 - 2026-10-04

### Fixes

- Re-pin the spec to 2026.10.03: metadata needs no license ([`f93c06e`](https://github.com/internetdata/sdk-perl/commit/f93c06ee940c6d77dd462ddfd39dbd9172fa4eb5))

## 1.8.0 - 2026-09-30

### Features

- Add the authorization code sign-in, with PKCE ([`0002d02`](https://github.com/internetdata/sdk-perl/commit/0002d028de057ab29d4bfed35022d6dd8578a376))

## 1.7.1 - 2026-09-29

### Fixes

- Read a timeout written as a string zero as no bound ([`2d5da60`](https://github.com/internetdata/sdk-perl/commit/2d5da600b6fb2a1afc885e3efe35c64cbff6d5bf))

## 1.7.0 - 2026-09-27

### Features

- Re-pin the spec to 2026.09.26, adding its evaluation-sample fields ([`1d53ef4`](https://github.com/internetdata/sdk-perl/commit/1d53ef46ab9f7ab91651bcd0b2e7cf4e23de7a0b))

## 1.6.1 - 2026-09-24

### Fixes

- Back off between retries, and end the poll's sleep at its deadline ([`94bfc22`](https://github.com/internetdata/sdk-perl/commit/94bfc2220222845a2bea46ea9c2d43fcedf8cbdf))
