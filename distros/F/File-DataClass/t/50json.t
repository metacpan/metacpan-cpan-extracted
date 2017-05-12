use t::boilerplate;

use Test::More;
use English               qw( -no_match_vars );
use File::DataClass::IO;
use File::Spec::Functions qw( catfile );
use Text::Diff;

my $osname = lc $OSNAME;
my $ntfs   = $osname eq 'mswin32' || $osname eq 'cygwin' ? 1 : 0;

io( 't' )->is_writable or plan skip_all => 'Directory t not writable';

$ntfs and plan skip_all => 'File system not supported';

sub test {
   my ($obj, $method, @args) = @_; my $wantarray = wantarray; local $EVAL_ERROR;

   my $res = eval {
      $wantarray ? [ $obj->$method( @args ) ] : $obj->$method( @args );
   };

   $EVAL_ERROR and return $EVAL_ERROR; return $wantarray ? @{ $res } : $res;
}

use_ok 'File::DataClass::Schema';

my $path_ref = [ 't', 'default.json' ]; my $path = catfile( @{ $path_ref } );
my $schema   = File::DataClass::Schema->new
   (  path                     => $path,
      result_source_attributes => {
         globals               => { attributes => [ 'text' ], }, },
      storage_class            => 'Any',
      tempdir                  => 't' );

isa_ok $schema, 'File::DataClass::Schema';
is $schema->storage->extn, undef, 'Undefined extension';
is $schema->storage->meta_pack( 1 )->{mtime}, 1, 'Storage meta pack';
is $schema->storage->meta_unpack( { mtime => 1 } ), 1, 'Storage meta unpack';
is $schema->storage->meta_pack()->{mtime}, 1, 'Storage meta pack - cached';
is scalar keys %{ $schema->storage->load() }, 0, 'Storage load empty default';

my $dumped = catfile( qw( t dumped.json ) ); io( $dumped )->unlink;

$schema->dump( { data => $schema->load, path => $dumped } );

my $diff = diff $path, $dumped;

ok !$diff, 'Load and dump roundtrips'; io( $dumped )->unlink;

$schema->dump( { data => $schema->load, path => $dumped } );

$diff = diff $path, $dumped;

ok !$diff, 'Load and dump roundtrips 2'; io( $dumped )->unlink;

eval { $schema->dump( { data => sub {}, path => $dumped } ) };

my $e = $EVAL_ERROR;

like $e->error, qr{ CODE }mx, 'Throws on bad data';

my $data = test( $schema, 'load', $path, catfile( qw( t other.json ) ) );

like $data->{ '_cvs_default' } || q(), qr{ @\(\#\)\$Id: }mx,
   'Has reference element 1';

like $data->{ '_cvs_other' } || q(), qr{ @\(\#\)\$Id: }mx,
   'Has reference element 2';

my $rs   = test( $schema, qw( resultset globals ) );
my $args = { name => 'dummy', text => 'value3' };

is test( $rs, 'create_or_update', $args )->id, 'dummy',
   'Create or update creates';

$args->{text} = 'value4';

is test( $rs, 'create_or_update', $args )->id, 'dummy',
   'Create or update updates';

like test( $rs, 'create_or_update', $args ), qr{ \Qnothing updated\E }imx,
   'No update without change';

my $result = $rs->find( { name => 'dummy' } );

is test( $rs, 'delete', $args ), 'dummy', 'Deletes';

$schema->storage->create_or_update( io( $path ), $result, 1, sub { 1 } );

is test( $rs, 'delete', $args ), 'dummy', 'Deletes again';

like test( $rs, 'delete', $args ), qr{ \Qdoes not exist\E }mx,
   "Delete non existant throws";

$args->{optional} = 1;

is test( $rs, 'delete', $args ), undef, "Delete optional doesn't throw";

$schema->storage->validate_params( io( $path ), 'globals' );

eval { $schema->storage->validate_params( io( 'no.chance' ), 'globals' ) };

like $EVAL_ERROR, qr{ \Qhas no class\E }mx, 'Extension without class';

my $translate = catfile( qw( t translate.json ) ); io( $translate )->unlink;

$args = { from => $path,      from_class => 'JSON',
          to   => $translate, to_class   => 'JSON', };

$e = test( $schema, 'translate', $args ); $diff = diff $path, $translate;

ok !$diff, 'Can translate from JSON to JSON';

File::DataClass::Schema->translate( { from => $path, to => $translate } );

ok !$diff, 'Can translate from JSON to JSON - class method';

$path_ref = [ 't', 'utf8.json' ]; $path = catfile( @{ $path_ref } );
$schema   = File::DataClass::Schema->new
   (  path                     => $path,
      result_source_attributes => {
         globals               => { attributes => [ 'text' ], }, },
      storage_attributes       => { encoding => 'UTF-8' },
      storage_class            => 'Any',
      tempdir                  => 't' );

$schema->dump( { data => $schema->load, path => $dumped } );

$diff = diff $path, $dumped;

ok !$diff, 'Load and dump roundtrips - uft8';

$schema   = File::DataClass::Schema->new
   (  path                     => catfile( 't', 'bad_format.json' ),
      result_source_attributes => {
         globals               => { attributes => [ 'text' ], }, },
      storage_class            => 'Any',
      tempdir                  => 't' );

eval { $schema->load };

like $EVAL_ERROR, qr{ \QFile-DataClass-Storage-JSON\E }mx, 'Bad format';

done_testing;

# Cleanup
io( $dumped )->unlink;
io( $translate )->unlink;
io( catfile( qw( t ipc_srlock.lck ) ) )->unlink;
io( catfile( qw( t ipc_srlock.shm ) ) )->unlink;
io( catfile( qw( t file-dataclass-schema.dat ) ) )->unlink;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
