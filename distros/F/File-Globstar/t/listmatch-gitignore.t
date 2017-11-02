# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>, 
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use strict;

use Cwd;
use File::Spec;

BEGIN {
    my ($volume, $directory) = File::Spec->splitpath(Cwd::abs_path($0));
    my $here = File::Spec->catpath($volume, $directory);
    my $gitdir = File::Spec->catdir($here, File::Spec->updir, '.git');

    $ENV{AUTHOR_TESTING} = 1 if -d $gitdir;

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

require "t/listmatch-xmode.t";
