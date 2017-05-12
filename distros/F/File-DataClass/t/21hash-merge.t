use t::boilerplate;

use Test::More;
use English qw( -no_match_vars );
use File::DataClass::IO;

my $osname   = lc $OSNAME;
my $ntfs     = $osname eq 'mswin32' || $osname eq 'cygwin' ? 1 : 0;
my $path_ref = [ 't', 'default.json' ];

io( $path_ref )->is_writable
   or plan skip_all => 'File t/default.json not writable';

$ntfs and plan skip_all => 'File system not supported';

use_ok 'File::DataClass::Schema';

sub test {
   my ($obj, $method, @args) = @_; my $wantarray = wantarray; local $EVAL_ERROR;

   my $res = eval {
      $wantarray ? [ $obj->$method( @args ) ] : $obj->$method( @args );
   };

   $EVAL_ERROR and return $EVAL_ERROR; return $wantarray ? @{ $res } : $res;
}


my $schema = File::DataClass::Schema->new
   ( cache_class              => 'none',
     lock_class               => 'none',
     path                     => $path_ref,
     result_source_attributes => {
        keys                  => {
           attributes         => [ qw( vals ) ],
           defaults           => { vals => {} }, }, },
     storage_class            => 'JSON',
     tempdir                  => 't', );
my $rs     = test( $schema, 'resultset', 'keys' );
my $args   = { name => 'dummy', vals => { k1 => 'v1' } };
my $res    = test( $rs, 'create', $args );

is $res->id, 'dummy', 'Creates dummy element and inserts';

delete $args->{vals}; $res = test( $rs, 'find', $args );

is $res->vals->{k1}, 'v1', 'Finds defined value';

$args->{vals}->{k1} = 0; $res = test( $rs, 'update', $args );

delete $args->{vals}; $res = test( $rs, 'find', $args );

is $res->vals->{k1}, 0, 'Update with false value';

$args->{vals}->{k1} = undef; $res = test( $rs, 'update', $args );

delete $args->{vals}; $res = test( $rs, 'find', $args );

ok( (not exists $res->vals->{k1}), 'Delete attribute from hash' );

$res = test( $rs, 'delete', $args );

is $res, 'dummy', 'Deletes dummy element';

use File::DataClass::Functions qw( merge_for_update );

eval { merge_for_update() };

like $EVAL_ERROR, qr{ \Qnot specified\E }imx, 'Requires a destination hash ref';

my $dest = { delete_key => 1 };
my $src  = { delete_key => undef, key => 'value', key_no_value => undef, };

merge_for_update( \$dest, $src );

is $dest->{key}, 'value', 'Default merge filter';
ok !exists $dest->{delete_key}, 'Deletes unwanted keys';

merge_for_update( \$dest );

is $dest->{key}, 'value', 'No source required';

$dest = {}; $src = { new_key => {} };

my $updated = merge_for_update( \$dest, $src );

ok exists $dest->{new_key}, 'Adds empty hash';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
