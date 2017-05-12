#!/usr/bin/perl -w

use strict;
use Test::More tests => 35;
BEGIN { use_ok('Exception::Class::DBI') or die }
# Use PurePerl to get around CursorName bug.
BEGIN { $ENV{DBI_PUREPERL} = 2 }
use DBI;

ok( my $dbh = DBI->connect('dbi:ExampleP:dummy', '', '',
                           { PrintError => 0,
                             RaiseError => 0,
                             HandleError => Exception::Class::DBI->handler
                           }),
    "Connect to database" );

END { $dbh->disconnect if $dbh };

# Check that the error_handler has been installed.
isa_ok( $dbh->{HandleError}, 'CODE' );

# Trigger an exception.
eval {
    my $sth = $dbh->prepare("select * from foo");
    $sth->execute;
};

# Make sure we got the proper exception.
ok( my $err = $@, "Get exception" );
my $bang = $!;
isa_ok( $err, 'Exception::Class::DBI' );
isa_ok( $err, 'Exception::Class::DBI::H' );
isa_ok( $err, 'Exception::Class::DBI::STH' );

is( $err->err, 2, "Check err" );
is( $err->errstr, "opendir(foo): $bang",
    "Check errstr" );
like( $err->error,
      qr/^DBD::ExampleP::st execute failed: opendir\(foo\): \E$bang/,
      "Check error" );
is( $err->state, 'S1000', "Check state" );
ok( ! defined $err->retval, "Check retval" );

is( $err->warn, 1, 'Check warn' );
ok( !$err->active, 'Check active' );
is( $err->kids, 0, 'Check kids' );
is( $err->active_kids, 0, 'Check active_kids' );
ok( ! $err->compat_mode, 'Check compat_mode' );
ok( ! $err->inactive_destroy, 'Check inactive_destroy' );

{
    # PurePerl->{TraceLevel} should return an integer, but it doesn't. It
    # returns undef instead.
    local $SIG{__WARN__} = sub {};
    cmp_ok( $err->trace_level, '==', 0, 'Check trace_level' );
}

is( $err->fetch_hash_key_name, 'NAME', 'Check fetch_hash_key_name' );
ok( ! $err->chop_blanks, 'Check chop_blanks' );
is( $err->long_read_len, 80, 'Check long_read_len' );
ok( ! $err->long_trunc_ok, 'Check long_trunc_ok' );
ok( ! $err->taint, 'Check taint' );
is( $err->num_of_fields, 14, 'Check num_of_fields' );
is( $err->num_of_params, 0, 'Check num_of_params' );
is( ref $err->field_names, 'ARRAY', "Check field_names" );

# These tend to return undef. Probably ought to try to add tests to make
# sure that they have array refs when they're supposed to.
ok( ! defined $err->type, "Check type" ); # isa ARRAY
ok( ! defined $err->precision, "Check precision" ); # isa ARRAY
isa_ok( $err->scale, 'ARRAY', "Check scale" );
ok( ! defined $err->param_values, "Check praram_values" ); # isa HASH

is( ref $err->nullable, 'ARRAY', "Check nullable" );
# ExampleP fails to get the CursorName attribute under DBI. Which is
# why this test is using PurePerl, instead.
ok( ! defined $err->cursor_name, "Check cursor_name" );
is( $err->statement, 'select * from foo', 'Check statement' );
ok( ! defined $err->rows_in_cache, "Check rows_in_cache" );

# This keeps Perl 5.6.2 from trying to run tests again. I've no idea why it
# does that. :-(
exit;
