#!/usr/bin/env perl
# Convert dbix exceptions into report

use warnings;
use strict;

use Log::Report;
use Log::Report::Die 'exception_decode';
use Test::More;

use Data::Dumper;

$! = 3;
my $errno  = $!+0;

{   # I do not want a dependency: fake implementation of this object
    package DBIx::Class::Exception;
    sub new($) { bless { msg => $_[1] }, $_[0] }
    use overload '""' => sub { shift->{msg} }, fallback => 1;
}
sub exception($) { DBIx::Class::Exception->new($_[0]) }

my $dbix1 = <<__WITHOUT_STACKTRACE;
help at /tmp/a.pl line 6.
__WITHOUT_STACKTRACE

is_deeply [ exception_decode(exception $dbix1) ]
  , [ 'caught DBIx::Class::Exception'
    , { location => [ $0, '/tmp/a.pl', '6', undef ] }
    , 'ERROR'
    , 'help'
    ], 'set 1';

my $dbix2 = <<__WITH_STACKTRACE;
main::f(): help  at /tmp/a.pl line 6.
	main::f() called at /tmp/a.pl line 8
	main::g() called at /tmp/a.pl line 10
__WITH_STACKTRACE

is_deeply [ exception_decode(exception $dbix2) ]
  , [ 'caught DBIx::Class::Exception'
    , { location => [ 'main', '/tmp/a.pl', '6', 'f' ]
      , stack    => [ [ 'main::f', '/tmp/a.pl',  '8' ]
                    , [ 'main::g', '/tmp/a.pl', '10' ]
                    ]
      }
    , 'PANIC'
    , 'help'
    ], 'set 2';

my $dbix3 = <<__WITHOUT_STACKTRACE;  # not inside function
{UNKNOWN}: help  at /tmp/a.pl line 6.
__WITHOUT_STACKTRACE

is_deeply [ exception_decode(exception $dbix3) ]
  , [ 'caught DBIx::Class::Exception'
    , { location => [ $0, '/tmp/a.pl', '6', undef ] }
    , 'ERROR'
    , 'help'
    ], 'set 3';

my $dbix4 = <<'__FROM_DB';  # contributed by Andrew
DBIx::Class::Storage::DBI::_dbh_execute(): DBI Exception: DBD::Pg::st execute failed: ERROR:  duplicate key value violates unique constraint "gdpaanswer_pkey" DETAIL: Key (identifier)=(18.5) already exists. [for Statement "INSERT INTO "gdpaanswer" ( "answer", "identifier", "section", "site_id") VALUES ( ?, ?, ?, ?)" with ParamValues: 1='2', 2='18.5', 3='18', 4=undef] at /home/abeverley/git/Isaas/bin/../lib/Isaas/DBIC.pm line 18
__FROM_DB

#warn "DBIx4:", Dumper exception_decode(exception $dbix4);

is_deeply [ exception_decode(exception $dbix4) ]
  , [ 'caught DBIx::Class::Exception'
    , { location =>
         [ 'DBIx::Class::Storage::DBI'
         , '/home/abeverley/git/Isaas/bin/../lib/Isaas/DBIC.pm'
         , '18'
         , '_dbh_execute'
         ] }
    , 'ERROR'
    , q{DBI Exception: DBD::Pg::st execute failed: ERROR:  duplicate key value violates unique constraint "gdpaanswer_pkey" DETAIL: Key (identifier)=(18.5) already exists. [for Statement "INSERT INTO "gdpaanswer" ( "answer", "identifier", "section", "site_id") VALUES ( ?, ?, ?, ?)" with ParamValues: 1='2', 2='18.5', 3='18', 4=undef]}
    ], 'set 4';


### Test automatic conversion

try { die exception $dbix1 };
my $exc = $@->wasFatal;
isa_ok $exc, 'Log::Report::Exception';
is "$exc", "error: help\n";

my $msg = $exc->message;
isa_ok $msg, 'Log::Report::Message';
is $msg->toString, 'help';


### Test report with object

try { error exception $dbix1 };
my $err = $@->wasFatal;
isa_ok $err, 'Log::Report::Exception';
is "$err", "error: help at /tmp/a.pl line 6.\n";

done_testing;

1;
