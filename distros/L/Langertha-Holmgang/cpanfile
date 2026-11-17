requires 'perl', '5.020';

requires 'B';
requires 'Carp';
requires 'Compress::Zlib';
requires 'Digest::MD5';
requires 'Digest::SHA';
requires 'Encode';
requires 'Exporter';
requires 'File::ShareDir';
requires 'Future';
requires 'Future::AsyncAwait';
requires 'Getopt::Long';
requires 'IO::Compress::Gzip';
requires 'IO::Uncompress::Gunzip';
requires 'JSON::MaybeXS';
requires 'Langertha', '0.504';
requires 'Math::BigInt';
requires 'Math::BigRat';
requires 'MIME::Base64';
requires 'Module::Runtime';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Path::Tiny';
requires 'POSIX';
requires 'Scalar::Util';
requires 'Socket';
requires 'Text::Xslate';
requires 'Time::HiRes';
requires 'Time::Local';
requires 'Unicode::Normalize';
requires 'URI';
requires 'YAML::XS';

# a deadline and concurrent requests need the engine on an event loop, as
# Langertha's _f methods do; without them requests run one after another
recommends 'IO::Async';
recommends 'Net::Async::HTTP';

on test => sub {
  requires 'File::Find';
  requires 'File::Spec';
  requires 'FindBin';
  requires 'IPC::Open3';
  requires 'Storable';
  requires 'Test::Fatal';
  requires 'Test::More';
};
