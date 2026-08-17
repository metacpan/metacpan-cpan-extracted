# Migration from HTTP::API::Client

`HTTP::API::Core` continues the pre-release `HTTP::API::Client` project under a
new CPAN namespace.

The rename was required because `HTTP::API::Client` was not available for
authorized CPAN indexing.

Replace:

```perl
use HTTP::API::Client;
```

with:

```perl
use HTTP::API::Core;
```

Supporting packages move likewise:

- `HTTP::API::Client::Auth` → `HTTP::API::Core::Auth`
- `HTTP::API::Client::Error` → `HTTP::API::Core::Error`
- `HTTP::API::Client::Pagination` → `HTTP::API::Core::Pagination`
- `HTTP::API::Client::RateLimit` → `HTTP::API::Core::RateLimit`
- `HTTP::API::Client::Response` → `HTTP::API::Core::Response`

`HTTP::API::Core` 0.01 carries forward the behavior developed through
`HTTP::API::Client` 0.12.
