#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;
BEGIN { use_ok 'Dunce::Files' }


sub do_nothing { 1 }

eval { 
    local $SIG{__WARN__} = sub { die @_ };
    open(FILE, 'bogus'); 
};
like( $@, qr/^You didn't check/ );

eval { 
    local $SIG{__WARN__} = sub { die @_ };
    open(FILE, 't/Files.t') || die $!;
    1;
};
is( $@, '' );

my $Buh;
eval { 
    local $SIG{__WARN__} = sub { die @_ };
    chmod(0755, 'moo') || do_nothing();
    1;
};
like( $@, qr/^Don't make files/,                                  'chmod' );

#'#
my %hash = (foo => 'bar');
eval { 
    local $SIG{__WARN__} = sub { die @_ };
    dbmopen(%hash, "testingdb", 0644) || do_nothing;
    1;
};
like( $@, qr/^Hash given to dbmopen\(\) already contains data/,   'dbmopen' );

SKIP: {
    skip "chop() is not overridable in your version of Perl", 3
      unless defined prototype("CORE::chop");

    my @test = qw(something morestuff);
    my $test = 'morestuff';

    is( chop($test), 'f' );
    is( $test, 'morestuf');

    eval {
        local $SIG{__WARN__} = sub { die @_ };
        local $_ = "foo\n";
        chop($_);
        1;
    };
    like( $@, qr/Looks like you're using chop\(\) to strip newlines/i,
          'chop' );
}
