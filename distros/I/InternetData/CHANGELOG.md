# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff. Releases before 1.6.1 are described by their release commits.

## 1.11.0 - 2026-10-18

### Features

- Add oauth->register, for RFC 7591 dynamic client registration ([`8ed4586`](https://github.com/internetdata/sdk-perl/commit/8ed4586060b418faee13930f43d13fb528f67795))

## 1.10.1 - 2026-10-17

### Fixes

- Refuse a database answer whose member has the wrong type ([`c4d8144`](https://github.com/internetdata/sdk-perl/commit/c4d81447a5deea913497e32e2bb1967a94ae6325))

## 1.10.0 - 2026-10-17

### Features

- Integration: pass over a licensed file past the CI budget ([`296d85f`](https://github.com/internetdata/sdk-perl/commit/296d85fdebfa9b216630447e840e6e4e53a52ef8))
- Re-pin the spec to 2026.10.16: dynamic client registration ([`504d5e9`](https://github.com/internetdata/sdk-perl/commit/504d5e96bc85b2b6b9e39e2d43b212f89ce945f9))

## 1.9.5 - 2026-10-16

### Fixes

- Re-pin the spec to 2026.10.15: three descriptions in US spelling ([`597760d`](https://github.com/internetdata/sdk-perl/commit/597760d6628d5a00de9eddc21b148a9357d73276))

## 1.9.4 - 2026-10-15

### Fixes

- Retry an unreadable answer to OAuth discovery and device authorization ([`ef9459a`](https://github.com/internetdata/sdk-perl/commit/ef9459ad20e61330e7a713f6c0c91c2f4ac08fed))

## 1.9.3 - 2026-10-13

### Fixes

- Re-pin the spec to 2026.10.13: Open databases come with a license ([`b3a2373`](https://github.com/internetdata/sdk-perl/commit/b3a23737bad936588b9e2d03876ec76627fc0727))

## 1.9.2 - 2026-10-11

### Fixes

- Read Retry-After as digits or an RFC 9110 date in GMT, nothing else ([`d85cdbe`](https://github.com/internetdata/sdk-perl/commit/d85cdbed725ffa537dba13b02e1e5f99ecc240dd))
- Trim the key and refuse a control character in it; require metadata's id ([`82389e0`](https://github.com/internetdata/sdk-perl/commit/82389e0a975a342ae6e939f1bc3935968d0663f9))

## 1.9.1 - 2026-10-10

### Fixes

- Re-pin the spec to 2026.10.09: rotating a key needs apikeys.reveal ([`fc1e0f0`](https://github.com/internetdata/sdk-perl/commit/fc1e0f01c51a822279d5e13bee5f4ca518f27ff1))

## 1.9.0 - 2026-10-09

### Features

- Re-pin the spec to 2026.10.08, adding the Open databases' open flag ([`cb20799`](https://github.com/internetdata/sdk-perl/commit/cb20799d17e736d212f1544720dcd445288b2db8))

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
