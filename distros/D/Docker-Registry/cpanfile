requires 'perl' => '5.014001';
requires 'Moo';
requires 'Types::Standard';
requires 'namespace::autoclean';
requires 'JSON::MaybeXS';
requires 'HTTP::Tiny';
requires 'HTTP::Headers';
requires 'Throwable::Error';
requires 'IO::Socket::SSL';
requires 'MIME::Base64';

feature 'gcr-registry', 'Support for GCR' => sub {
  requires 'Crypt::JWT';
  requires 'Path::Class';
  requires 'URI';
};

feature 'ecr-registry', 'support for ecr' => sub {
  #requires 'Paws';
};

feature 'gitlab-registry', 'support for gitlab' => sub {
};

on test => sub {
  requires 'Test::More';
  requires 'Test::Most';
  requires 'Test::Exception';
  requires 'Sub::Override';
  requires 'Import::Into' => '1.002003';
  requires 'Test::Deep';
  requires 'Test::Lib';
  requires 'Test::Spec';
  requires 'Test::Spec::Mocks';
};

