use strict;
use warnings;

=head1 NAME

path.t - make sure our database is where we want it

=head1 DESCRIPTION

L<DBM::Deep> doesn't like to put the database anywhere but the CWD. This is not the DustyDB way.

=cut

use Test::More tests => 3;
use_ok('DustyDB');

my $db = DustyDB->new( path => 't/path.db ' );
ok($db, 'loaded the database object');

TODO: {
local $TODO = 'DBM::Deep ignores the path spec. This needs to be fixed here or there.';

ok(-f 't/path.db', 'the database exists');

}

unlink 't/path.db';
