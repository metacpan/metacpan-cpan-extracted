
requires 'Compress::Raw::Bzip2';
requires 'Compress::Raw::Zlib';
requires 'File::ShareDir::ProjectDistDir';
requires 'Future';
requires 'Future::AsyncAwait', '>= 0.66';
requires 'Import::Into';
requires 'JSON::MaybeXS';
requires 'JSON::PP';
requires 'JSON::Schema::Modern', '>= 0.617';
requires 'LWP::Protocol::https';
requires 'IO::Socket::SSL';   # used directly by HTTP::UserAgent (connect_address TLS checks)
requires 'Net::SSLeay';       # ditto: get_verify_result on the pinned session
requires 'LWP::UserAgent';
requires 'HTTP::Message';
requires 'HTTP::Date';
requires 'MIME::Base64';
requires 'Log::Any';
requires 'Module::Runtime';
requires 'Module::Pluggable';
requires 'Moose';
requires 'MooseX::NonMoose';
requires 'OpenAPI::Modern', '>= 0.089';  # needs v0.089+ for updated evaluator handling
requires 'Path::Tiny';
requires 'Time::HiRes';
requires 'Time::Moment';
requires 'URI';
requires 'YAML::PP';
requires 'YAML::XS';

# The async _f transport is optional: without these Langertha falls back to a
# synchronous LWP client (Langertha::Role::AsyncHTTP -> Langertha::Request::SyncHTTP),
# so the _f methods keep working sequentially. Install them (or `cpanm
# --with-recommends`) for real async concurrency. See ADR 0027.
recommends 'IO::Async';
recommends 'IO::Async::SSL';
recommends 'Net::Async::HTTP';

on test => sub {
  requires 'Test2::Suite';
  requires 'Module::Runtime';
  requires 'Math::Vector::Similarity';
  requires 'Perl::Critic', '>= 1.156';
  requires 'Test::Perl::Critic';
  # t/45_sync_http_real_lwp.t runs a real LWP (and Net::Async::HTTP, when
  # installed) against a local forked daemon.
  requires 'HTTP::Daemon';

  # t/93_to_json.t compares every JSON::MaybeXS backend; JSON::XS is the one
  # that is not pulled in transitively, so it is wanted but not required.
  recommends 'JSON::XS';
};
