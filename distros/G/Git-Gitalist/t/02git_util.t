use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use strict;
use warnings;
use Test::More;

use Data::Dumper;

BEGIN {
    use_ok 'Git::Gitalist::Util';
    use_ok 'Git::Gitalist::Repository';
}

use Path::Class;
my $gitdir = dir("$Bin/lib/repositories/repo1");

my $proj = Git::Gitalist::Repository->new($gitdir);
my $util = Git::Gitalist::Util->new(
    repository => $proj,
);
isa_ok($util, 'Git::Gitalist::Util');

like( $util->_git, qr#\bgit(\.\w+)*$#, 'git binary found');
isa_ok($util->gpp, 'Git::PurePerl', 'gpp instance created');

done_testing;
