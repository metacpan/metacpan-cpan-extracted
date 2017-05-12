#!perl
#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More;
use File::RsyBak;

test_sources(
    name => 'all local = ok',
    sources => ['a', 'b/c'],
);
test_sources(
    name => 'all remote (: syntax), same machine = ok',
    sources => ['user@host:/a', 'user@host:b/c'],
);
test_sources(
    name => 'all remote (: syntax), different machines = error',
    sources => ['user@host:/a', 'user@host2:b/c'],
    error => 1,
);
test_sources(
    name => 'some remote, some local = error',
    sources => ['a/b', 'user@host:b/c'],
    error => 1,
);

done_testing();

sub test_sources {
    my %args = @_;
    my $name = $args{name};
    my $sources = $args{sources};

    my @sources = map { File::RsyBak::_parse_path($_) } @$sources;
    my $res = File::RsyBak::_check_sources(\@sources);
    if ($args{error}) {
        isnt($res->[0], 200, "$name (error)") or explain($res);
    } else {
        is  ($res->[0], 200, "$name (not error)") or explain($res);
    }

}

