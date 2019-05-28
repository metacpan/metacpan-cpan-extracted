use strict;
use warnings;
use Test::More tests => 27;
BEGIN { use_ok('Exception::Class::DBI') or die }
use DBI;

ok( my $dbh = DBI->connect(
    'dbi:ExampleP:dummy', '', '',
    {
        PrintError => 0,
        RaiseError => 0,
        HandleError => Exception::Class::DBI->handler
    }),
    'Connect to database' );

END { $dbh->disconnect if $dbh };

# Check that the error_handler has been installed.
isa_ok( $dbh->{HandleError}, 'CODE' );

# Trigger an exception.
eval {
    $dbh->do('select foo from foo');
};

# Make sure we got the proper exception.
ok( my $err = $@, "Get exception" );
isa_ok( $err, 'Exception::Class::DBI' );
isa_ok( $err, 'Exception::Class::DBI::H' );
isa_ok( $err, 'Exception::Class::DBI::DBH' );

# Check the accessor values.
NOWARN: {
    # Prevent Perl 5.6 from complaining about usng $DBI::stderr only once.
    local $^W;
    is( $err->err, $DBI::stderr || 1, "Check err" );
}
is( $err->errstr, 'Unknown field names: foo', "Check errstr" );
is( $err->error, 'DBD::ExampleP::db do failed: Unknown field names: foo',
    "Check error" );
is( $err->state, 'S1000', "Check state" );
ok( ! defined $err->retval, "Check retval" );
is( $err->warn, 1, "Check warn" );
is( $err->active, 1, "Check active" );
# For some reason, under perl < 5.6.2, $dbh->{Kids} returns a different value
# inside the HandleError scope than it does outside that scope. So we're
# checking for the perl version here to cover our butts on this test. This may
# be fixed in the DBI soon. I'm using the old form of the Perl version number
# as it seems safer with older Perls. See
# http://groups.google.com/group/perl.dbi.dev/browse_thread/thread/6a1903e2eb251d45
# for details.
is( $err->kids, ($] < 5.006_002 ? 1 : 0), "Check kids" );
is( $err->active_kids, 0, "Check active_kids" );
ok( ! $err->inactive_destroy, "Check inactive_destroy" );
is( $err->trace_level, 0, "Check trace_level" );
is( $err->fetch_hash_key_name, 'NAME', "Check fetch_hash_key_name" );
ok( ! $err->chop_blanks, "Check chop_blanks" );
is( $err->long_read_len, 80, "Check long_read_len" );
ok( ! $err->long_trunc_ok, "Check long_trunc_ok" );
ok( ! $err->taint, "Check taint" );
ok( $err->auto_commit, "Check auto_commit" );
is( $err->db_name, 'dummy', "Check db_name" );
is( $err->statement, 'select foo from foo', "Check statement" );
ok( ! defined $err->row_cache_size, "Check row_cache_size" );

# This keeps Perl 5.6.2 from trying to run tests again. I've no idea why it
# does that. :-(
exit;
