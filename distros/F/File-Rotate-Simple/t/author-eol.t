
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test::EOL;
all_perl_files_ok({ trailing_whitespace => 1 }, qw/ lib t / );
