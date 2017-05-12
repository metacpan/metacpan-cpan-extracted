#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Temp qw/tempdir/;
use File::Touch;

use Test::More;
use File::Find::Rule::Age;

my $test_dir = File::Temp->newdir( CLEANUP => 1 );
my $dir_name = $test_dir->dirname;

my $cmp_test_dir = File::Temp->newdir( CLEANUP => 1 );
my $cmp_dir_name = $cmp_test_dir->dirname;

my ( $now, $today, $yesterday, $lastday ) = ( DateTime->now(), DateTime->now(), DateTime->now(), DateTime->now() );
if ( $ENV{AUTOMATED_TESTING} )
{
    # just to have a difference - avoid $now is 0:00:00
    $today->subtract( hours => 1 );
    $lastday->subtract( hours => 2 );
    $yesterday->subtract( hours => 3 );
}
else
{
    $today->truncate( to => 'day' );
    $lastday->subtract( days => 1 );
    $yesterday->truncate( to => 'day' );
    $yesterday->subtract( days => 2 );
}

File::Touch->new( atime => $now->epoch )->touch( File::Spec->catfile( $dir_name,     'now' ) );
File::Touch->new( atime => $now->epoch )->touch( File::Spec->catfile( $cmp_dir_name, 'now' ) );
File::Touch->new( atime => $today->epoch )->touch( File::Spec->catfile( $dir_name,     'today' ) );
File::Touch->new( atime => $today->epoch )->touch( File::Spec->catfile( $cmp_dir_name, 'today' ) );
File::Touch->new( atime => $lastday->epoch )->touch( File::Spec->catfile( $dir_name,     'lastday' ) );
File::Touch->new( atime => $lastday->epoch )->touch( File::Spec->catfile( $cmp_dir_name, 'lastday' ) );
File::Touch->new( atime => $yesterday->epoch )->touch( File::Spec->catfile( $dir_name,     'yesterday' ) );
File::Touch->new( atime => $yesterday->epoch )->touch( File::Spec->catfile( $cmp_dir_name, 'yesterday' ) );

my @fl;

@fl = find(
    file     => accessed_since => File::Spec->catfile( $cmp_dir_name, 'now' ),
    relative => in             => $dir_name
);
is_deeply( \@fl, ['now'], "accessed_since now (File)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_since => $now->epoch,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['now'], "accessed_since now (Number)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_since => $now,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['now'], "accessed_since now (DateTime)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_since => $now - $now,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['now'], "accessed_since now (DateTime::Duration)" ) or diag( explain( \@fl ) );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file     => accessed_since => "Halli-Galli",
        relative => in             => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing 2nd operand" );
    like( $warns[0], qr/^Cannot parse reference/, "Missing 2nd operator warning seen" );
}

@fl = find(
    file     => accessed_after => File::Spec->catfile( $cmp_dir_name, 'today' ),
    relative => in             => $dir_name
);
is_deeply( \@fl, ['now'], "accessed_after today (File)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_after => $today->epoch,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['now'], "accessed_after today (Number)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_after => $today,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['now'], "accessed_after today (DateTime)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_after => $now - $today,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['now'], "accessed_after today (DateTime::Duration)" ) or diag( explain( \@fl ) );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file     => accessed_after => "Halli-Galli",
        relative => in             => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing 2nd operand" );
    like( $warns[0], qr/^Cannot parse reference/, "Missing 2nd operator warning seen" );
}

@fl = find(
    file     => accessed_until => File::Spec->catfile( $cmp_dir_name, 'yesterday' ),
    relative => in             => $dir_name
);
is_deeply( \@fl, ['yesterday'], "accessed_until yesterday (File)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_until => $yesterday->epoch,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['yesterday'], "accessed_until yesterday (Number)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_until => $yesterday,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['yesterday'], "accessed_until yesterday (DateTime)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_until => $now - $yesterday,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['yesterday'], "accessed_until yesterday (DateTime::Duration)" ) or diag( explain( \@fl ) );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file => accessed_until => "Halli-Galli",
        in   => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing 2nd operand" );
    like( $warns[0], qr/^Cannot parse reference/, "Missing 2nd operator warning seen" );
}

@fl = find(
    file     => accessed_before => File::Spec->catfile( $cmp_dir_name, 'lastday' ),
    relative => in              => $dir_name
);
is_deeply( \@fl, ['yesterday'], "accessed_before lastday (File)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_before => $lastday->epoch,
    relative => in              => $dir_name
);
is_deeply( \@fl, ['yesterday'], "accessed_before lastday (Number)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_before => $lastday,
    relative => in              => $dir_name
);
is_deeply( \@fl, ['yesterday'], "accessed_before lastday (DateTime)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => accessed_before => $now - $lastday,
    relative => in              => $dir_name
);
is_deeply( \@fl, ['yesterday'], "accessed_before lastday (DateTime::Duration)" ) or diag( explain( \@fl ) );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file     => accessed_before => "Halli-Galli",
        relative => in              => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing 2nd operand" );
    like( $warns[0], qr/^Cannot parse reference/, "Missing 2nd operator warning seen" );
}

done_testing;
