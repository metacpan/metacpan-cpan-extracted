use t::boilerplate;
use utf8;

use Test::More;
use Test::Requires 'Hash::MoreUtils';
use English qw( -no_match_vars );
use File::DataClass::IO;
use File::Spec::Functions qw( catfile );
use Text::Diff;

my $osname = lc $OSNAME;
my $ntfs   = $osname eq 'mswin32' || $osname eq 'cygwin' ? 1 : 0;

$ntfs and plan skip_all => 'File system not supported';

use_ok 'File::Gettext';

my $orig   = catfile( qw( t messages.po ) );
my $dumped = io( [ qw( t dumped.messages ) ] ); $dumped->unlink;
my $schema = File::Gettext->new( { charset => 'UTF-8',
                                   path => $orig, tempdir => 't' } );

isa_ok $schema, 'File::Gettext';

my $data = $schema->load;

$schema->dump( { data => $data, path => $dumped } );

my $diff = diff $orig, $dumped->pathname;

ok !$diff, 'Load and dump roundtrips' ; $dumped->unlink;

$schema->dump( { data => $schema->load, path => $dumped } );
$diff = diff $orig, $dumped->pathname;

ok !$diff, 'Load and dump roundtrips 2';

$orig   = catfile( qw( t existing.po ) );
$schema = File::Gettext->new( path => $orig, tempdir => 't' );
$data   = $schema->load;

ok $data->{po}->{January}->{msgstr}->[ 0 ] eq 'Januar', 'PO message lookup';
ok $data->{po}->{March}->{msgstr}->[ 0 ] eq 'März', 'PO charset decode';

$orig   = catfile( qw( t existing.mo ) );
$schema = File::Gettext->new( {
   path => $orig, source_name => q(mo), tempdir => 't' } );
$data   = $schema->load;

ok $data->{mo}->{January}->{msgstr}->[ 0 ] eq 'Januar', 'MO message lookup';
ok $data->{mo}->{March}->{msgstr}->[ 0 ] eq 'März', 'MO charset decode';

ok $schema->dump( { data => $data, path => $dumped } ), 'Does not dump MO';

use File::Gettext::Constants qw( DIRECTORIES MAGIC_N );

my @dirs = DIRECTORIES;

is $dirs[ 0 ]->[ 0 ]->[ 3 ], 'locale', 'Default directories';

is MAGIC_N, 2500072158, 'Magic number N';

done_testing;

# Cleanup

$dumped->unlink;
io( catfile( qw( t ipc_srlock.lck ) ) )->unlink;
io( catfile( qw( t ipc_srlock.shm ) ) )->unlink;
io( catfile( qw( t file-dataclass-schema.dat ) ) )->unlink;

# Local Variables:
# coding: utf-8
# mode: perl
# tab-width: 3
# End:
