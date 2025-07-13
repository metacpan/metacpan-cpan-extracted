#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Filename::Type::Perl::Release qw(check_perl_release_filename);

is_deeply(check_perl_release_filename(filename=>"foo.txt"), 0);
is_deeply(check_perl_release_filename(filename=>"foo.tar.gz"), 0);
is_deeply(check_perl_release_filename(filename=>"foo-bar-v1.2.3.tar.gz"),
          {
              archive_suffix=>'.tar',
              distribution=>'foo-bar',
              module=>'foo::bar',
              version => '1.2.3',
          });

DONE_TESTING:
done_testing;
