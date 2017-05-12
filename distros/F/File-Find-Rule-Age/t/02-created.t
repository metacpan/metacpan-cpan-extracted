#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Temp qw/tempdir/;
use File::Touch;

use Test::More;
use File::Find::Rule::Age;

my $extended_testing = $ENV{EXTENDED_TESTING} || $ENV{RELEASE_TESTING};
$extended_testing or plan skip_all => "Long running tests are unwanted";

my $test_dir = File::Temp->newdir( CLEANUP => 1 );
my $dir_name = $test_dir->dirname;

my $cmp_test_dir = File::Temp->newdir( CLEANUP => 1 );
my $cmp_dir_name = $cmp_test_dir->dirname;

my $yesterday = DateTime->now();
File::Touch->new( time => $yesterday->epoch )->touch( File::Spec->catfile( $dir_name,     'yesterday' ) );
File::Touch->new( time => $yesterday->epoch )->touch( File::Spec->catfile( $cmp_dir_name, 'yesterday' ) );
sleep 2;

my $lastday = DateTime->now();
File::Touch->new( time => $lastday->epoch )->touch( File::Spec->catfile( $dir_name,     'lastday' ) );
File::Touch->new( time => $lastday->epoch )->touch( File::Spec->catfile( $cmp_dir_name, 'lastday' ) );
sleep 2;

my $today = DateTime->now();
File::Touch->new( time => $today->epoch )->touch( File::Spec->catfile( $dir_name,     'today' ) );
File::Touch->new( time => $today->epoch )->touch( File::Spec->catfile( $cmp_dir_name, 'today' ) );
sleep 2;

my $now = DateTime->now();
File::Touch->new( time => $now->epoch )->touch( File::Spec->catfile( $dir_name,     'now' ) );
File::Touch->new( time => $now->epoch )->touch( File::Spec->catfile( $cmp_dir_name, 'now' ) );

my @fl;

@fl = find(
    file     => created_since => File::Spec->catfile( $cmp_dir_name, 'now' ),
    relative => in            => $dir_name
);
is_deeply( \@fl, ['now'], "created_since now (File)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_since => $now->epoch,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['now'], "created_since now (Number)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_since => $now,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['now'], "created_since now (DateTime)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_since => $now - $now,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['now'], "created_since now (DateTime::Duration)" ) or diag( explain( \@fl ) );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file     => created_since => "Halli-Galli",
        relative => in            => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing 2nd operand" );
    like( $warns[0], qr/^Cannot parse reference/, "Missing 2nd operator warning seen" );
}

@fl = find(
    file     => created_after => File::Spec->catfile( $cmp_dir_name, 'today' ),
    relative => in            => $dir_name
);
is_deeply( \@fl, ['now'], "created_after today (File)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_after => $today->epoch,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['now'], "created_after today (Number)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_after => $today,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['now'], "created_after today (DateTime)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_after => $now - $today,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['now'], "created_after today (DateTime::Duration)" ) or diag( explain( \@fl ) );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file     => created_after => "Halli-Galli",
        relative => in            => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing 2nd operand" );
    like( $warns[0], qr/^Cannot parse reference/, "Missing 2nd operator warning seen" );
}

@fl = find(
    file     => created_until => File::Spec->catfile( $cmp_dir_name, 'yesterday' ),
    relative => in            => $dir_name
);
is_deeply( \@fl, ['yesterday'], "created_until yesterday (File)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_until => $yesterday->epoch,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['yesterday'], "created_until yesterday (Number)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_until => $yesterday,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['yesterday'], "created_until yesterday (DateTime)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_until => $now - $yesterday,
    relative => in            => $dir_name
);
is_deeply( \@fl, ['yesterday'], "created_until yesterday (DateTime::Duration)" ) or diag( explain( \@fl ) );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file     => created_until => "Halli-Galli",
        relative => in            => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing 2nd operand" );
    like( $warns[0], qr/^Cannot parse reference/, "Missing 2nd operator warning seen" );
}

@fl = find(
    file     => created_before => File::Spec->catfile( $cmp_dir_name, 'lastday' ),
    relative => in             => $dir_name
);
is_deeply( \@fl, ['yesterday'], "created_before lastday (File)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_before => $lastday->epoch,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['yesterday'], "created_before lastday (Number)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_before => $lastday,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['yesterday'], "created_before lastday (DateTime)" ) or diag( explain( \@fl ) );
@fl = find(
    file     => created_before => $now - $lastday,
    relative => in             => $dir_name
);
is_deeply( \@fl, ['yesterday'], "created_before lastday (DateTime::Duration)" ) or diag( explain( \@fl ) );

SCOPE:
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my @fail = find(
        file     => created_before => "Halli-Galli",
        relative => in             => $dir_name
    );
    cmp_ok( scalar @warns, "==", 1, "catched 1 warning for missing 2nd operand" );
    like( $warns[0], qr/^Cannot parse reference/, "Missing 2nd operator warning seen" );
}

done_testing;
