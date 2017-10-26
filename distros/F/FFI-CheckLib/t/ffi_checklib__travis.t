use Test2::V0 -no_srand => 1;
use FFI::CheckLib qw( find_lib has_symbols );

skip_all 'only run under travis-ci'
  unless defined $ENV{TRAVIS}
  &&     $ENV{TRAVIS} eq 'true'
  &&     defined $ENV{TRAVIS_REPO_SLUG}
  &&     $ENV{TRAVIS_REPO_SLUG} =~ /\/FFI-CheckLib$/;

diag '';
diag '';
diag '';

diag "$_ = $ENV{$_}" for sort grep /TRAVIS/, keys %ENV;

diag '';
diag '';

diag "libssl=$_" for find_lib( lib => '*', verify => sub { $_[0] eq 'ssl' });

diag '';
diag '';

is(
  find_lib(
    lib    => 'crypto',
    symbol => 'PEM_read_bio_CMS',
  ),
  T(),
);

is(
  has_symbols('/lib/x86_64-linux-gnu/libssl.so.0.9.8', 'PEM_read_bio_CMS'),
  F(),
);

is(
  has_symbols('/lib/x86_64-linux-gnu/libssl.so.1.0.0', 'PEM_read_bio_CMS'),
  T(),
);

done_testing;
