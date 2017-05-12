use Test::More tests => 5;

use strict;
use warnings;

BEGIN {
	unlink( 't/test.db' );
}

use File::Slurp;
use Email::Store { only => [ qw( Mail List Language Mail::Language List::Language ) ] }, 'dbi:SQLite2:dbname=t/test.db';

Email::Store->setup;
ok( 1, 'setup()' );

my $mail = read_file( 't/email.dat' );
Email::Store::Mail->store( $mail );

my $message = Email::Store::Mail->retrieve( '20001128211546.A29664@firedrake.org' );
isa_ok( $message, 'Email::Store::Mail' );

my @languages = map { $_->language  } sort { $_->language } $message->languages;

is_deeply( \@languages, [ qw( en ) ], '$message->languages' );

my $list    = Email::Store::List->retrieve( 1 );
isa_ok( $list, 'Email::Store::List' );

@languages = map { $_->language  } sort { $_->language } $list->languages;

is_deeply( \@languages, [ qw( en ) ], '$list->languages' );