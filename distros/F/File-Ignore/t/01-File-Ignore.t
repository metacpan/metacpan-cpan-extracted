#!perl -wT

use strict;
no warnings qw/qw/;
use Test::More qw/no_plan/;
use Test::Lazy qw/template/;
use Test::Deep;

use File::Ignore;

my $seed = int rand $$ . time . int rand $$;
diag "Seed: $seed";
srand $seed;
my $template;

$template = template(\join "\n", map { "File::Ignore->ignore('$_')" } qw(
RCS/
SCCS/
CVS/
CVS.adm
RCSLOG
cvslog.apple
tags
TAGS
.make.state
.nse_depinfo
apple~
#apple
.#apple
,apple
_$apple
apple$
apple.old
apple.bak
apple.BAK
apple.orig
apple.rej
.del-apple
apple.a
apple.olb
apple.o
apple.obj
apple.so
apple.exe
apple.Z
apple.elc
apple.ln
core
.svn/
apple.swp
apple.swr
apple.swz
));
$template->test(ok => undef);

$template = template(\join "\n", map { "File::Ignore->ignore('$_')" } qw(RCS SCCS CVS .svn));
$template->test(ok => undef);

sub random_directory_path($) {
    my $file = shift;
    my @path;
    push @path, "", if 1 == int rand 4;
    push @path, "apple", if 1 == int rand 4;
    push @path, "banana-", if 1 == int rand 4;
    push @path, "cherry", if 1 == int rand 4;
    push @path, ".grape", if 1 == int rand 4;
    return join "/", @path, $file;
}

$template = template(\join "\n", map { "File::Ignore->ignore('@{[ random_directory_path $_ ]}')" } qw(
RCS/
SCCS/
CVS/
CVS.adm
RCSLOG
cvslog.apple
tags
TAGS
.make.state
.nse_depinfo
apple~
#apple
.#apple
,apple
_$apple
apple$
apple.old
apple.bak
apple.BAK
apple.orig
apple.rej
.del-apple
apple.a
apple.olb
apple.o
apple.obj
apple.so
apple.exe
apple.Z
apple.elc
apple.ln
core
.svn/
));
$template->test(ok => undef);

$template = template(\join "\n", map { "File::Ignore->ignore('@{[ random_directory_path $_ ]}')" } (0 .. 99));
$template->test(not_ok => undef);

cmp_deeply(File::Ignore->include(qw(src/RCS apple.Z doc/apple.txt tags .svn banana.html core)), [qw(doc/apple.txt banana.html)]);

cmp_deeply(File::Ignore->exclude(qw/RCS apple.Z apple.txt tags .svn banana.html core/), [qw/RCS apple.Z tags .svn core/]);
