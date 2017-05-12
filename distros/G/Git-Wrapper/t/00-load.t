use Test::More tests => 6;

BEGIN {
  use_ok('Git::Wrapper::Status');
  use_ok('Git::Wrapper::Statuses');
  use_ok('Git::Wrapper::Exception');
  use_ok('Git::Wrapper::File::RawModification');
  use_ok('Git::Wrapper::Log');
  use_ok('Git::Wrapper');
}

diag( "Testing Git::Wrapper $Git::Wrapper::VERSION" );
