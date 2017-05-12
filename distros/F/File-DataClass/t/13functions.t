use t::boilerplate;

use Test::More;
use English                    qw( -no_match_vars );
use File::DataClass::Functions qw( :all );
use Unexpected::Functions      qw( is_class_loaded );

my $osname       = lc $OSNAME;
my $result_class = 'File::DataClass::Result';

ensure_class_loaded( $result_class, { ignore_loaded => 1 } );

ok is_class_loaded( $result_class ), 'Ensure class loaded with options';

eval { ensure_class_loaded( 'TestTypo' ) };

like $EVAL_ERROR, qr{ package \s undefined }mx,
   'Class loaded package undefined';

eval { ensure_class_loaded( 'DoesNotExists' ) };

like $EVAL_ERROR, qr{ \Qt locate DoesNotExists\E }mx, 'Package not loaded';

extension_map( 'test', [ qw( .test .test ) ] );
extension_map();
is extension_map->{ '.json' }->[ 0 ], 'JSON',
   'Extension map loads on first use';
is extension_map->{ '.test' }->[ 1 ], undef, 'Extension map deduplicates';

ok !is_arrayref(), 'Is array ref without an argument';
ok !is_coderef(),  'Is code  ref without an argument';
ok !is_hashref(),  'Is hash  ref without an argument';
is  is_member( undef ), undef, 'Is member without argument';
is  is_member( 'x', [] ), 0, 'Is member with array ref';
is  is_member( 'x', qw( x y ) ), 1, 'Is member with list';
ok  is_stale( {}, 0, 1 ), 'Is stale - true';

SKIP: {
   ($osname eq 'mswin32' or $osname eq 'cygwin')
      and skip 'NTFS cache is always stale', 1;

   ok !is_stale( {}, 1, 0 ), 'Is stale - false';
}

my $list = map_extension2class( '.json' );

is $list->[ 0 ], 'JSON', 'Maps extension to class';

my $dest = { }; my $src = {  x => 'y' };

merge_attributes $dest, $src;
merge_attributes $dest, $src, [ 'x' ];

is $dest->{x}, 'y', 'Merge attributes';

$dest = {  x => undef }; merge_file_data( $dest, {  x => { z => 'y' } });

is $dest->{x}->{z}, undef, 'Merge file data';

ok( (is_member '.json', supported_extensions()), 'Lists supported extensions' );

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
