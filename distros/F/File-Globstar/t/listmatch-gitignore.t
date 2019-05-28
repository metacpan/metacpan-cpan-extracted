# Copyright (C) 2016-2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use common::sense;

use Cwd;
use File::Spec;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

# We run all the tests from listmatch-xmode.t but with a
# custom version of the list matcher that creates a git
# repository with a .gitignore file on the fly and then
# checks what gitignore says.

my $libdir = Cwd::abs_path($0);
$libdir =~ s{/[^/]+$}{/gitlib};

unshift @INC, $libdir;

$ENV{FILE_GLOBSTAR_GIT_CHECK_IGNORE} = 1;

use lib q/./;
require "t/listmatch-xmode.t";
