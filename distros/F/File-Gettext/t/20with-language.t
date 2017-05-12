use t::boilerplate;

use Test::More;
use Test::Requires 'Hash::MoreUtils';
use English qw( -no_match_vars );
use File::DataClass::IO;
use File::Spec::Functions qw( catdir catfile );
use Scalar::Util qw( blessed );
use Text::Diff;

my $osname = lc $OSNAME;
my $ntfs   = $osname eq 'mswin32' || $osname eq 'cygwin' ? 1 : 0;

$ntfs and plan skip_all => 'File system not supported';

sub diagnostic ($) {
   warn $_[ 0 ]; return 1;
}

sub test ($$$) {
   my ($obj, $method, @args) = @_; local $EVAL_ERROR;

   my $wantarray = wantarray; my $res;

   eval {
      if ($wantarray) { $res = [ $obj->$method( @args ) ] }
      else            { $res =   $obj->$method( @args )   }
   };

   my $e = $EVAL_ERROR; $e and return $e;

   return $wantarray ? @{ $res } : $res;
}

use_ok 'File::Gettext';
use_ok 'File::Gettext::Constants';
use_ok 'File::Gettext::Schema';

my $default = catfile( qw( t default.json ) );
my $schema  = File::Gettext::Schema->new
   ( path      => $default,
     language  => 'en',
     localedir => catdir( qw( t locale ) ),
     result_source_attributes => {
        pages => {
           attributes => [ qw( columns heading ) ],
           language           => 'en',
           language_dependent => { qw( heading 1 ) }, }, },
     tempdir => 't' );

isa_ok $schema, 'File::DataClass::Schema';
is $schema->language, 'en', 'Has language attribute';

my $dumped = catfile( qw( t dumped.json ) );
my $pofile = catfile( qw( t locale de LC_MESSAGES dumped.po ) );
my $source = $schema->source( 'pages' );
my $rs     = $source->resultset;
my $args   = { name => 'dummy', columns => 3, heading => 'This is a heading', };
my $res    = test $rs, 'create', $args;

SKIP: {
   blessed $res eq 'File::DataClass::Exception'
       and diagnostic $res->message and $ntfs and skip 'Possible NTFS issue', 1;

   is $res->id, 'dummy', 'Creates dummy element and inserts';

   $args->{columns} = '2'; $args->{heading} = 'This is a heading also';

   $res = test $rs, 'update', $args;

   is $res->id, 'dummy', 'Can update';

   $ntfs and $schema->path->close; # See if this fixes winshite

   delete $args->{columns}; delete $args->{heading};

   $res = test $rs, 'find', $args;

   is $res->columns, 2, 'Can find';

   $ntfs and $schema->path->close; # See if this fixes winshite

   my $e = test $rs, 'create', $args;

   ok $e =~ m{ already \s+ exists }mx, 'Detects already existing element';

   $ntfs and $schema->path->close; # See if this fixes winshite

   $res = test $rs, 'delete', $args;

   is $res, 'dummy', 'Deletes dummy element';

   $e = test $rs, 'delete', $args;

   ok $e =~ m{ does \s+ not \s+ exist }mx, 'Detects non existing element';

   $schema->language( 'de' ); $args->{name} = 'dummy';

   $args->{columns} = 3; $args->{heading} = 'This is a heading';

   $res = test $rs, 'create', $args;

   is $res->id, 'dummy', 'Creates dummy element and inserts 2';

   my $data   = $schema->load;

   $schema->dump( { data => $data, path => $dumped } );

   my $gettext = File::Gettext->new( path => $pofile, tempdir => 't' );

   $data = $gettext->load;

   my $key  = 'pages.heading'.CONTEXT_SEP().'dummy';
   my $text = $data->{ 'po' }->{ $key }->{ 'msgstr' }->[ 0 ];

   ok $text eq 'This is a heading', 'Dumps';

   $res = test $rs, 'delete', $args;

   is $res, 'dummy', 'Deletes dummy element 2';
}

done_testing;

# Cleanup
io( $dumped )->unlink;
io( $pofile )->unlink;
io( catfile( qw( t locale de LC_MESSAGES default.po ) ) )->unlink;
io( catfile( qw( t locale en LC_MESSAGES default.po ) ) )->unlink;
io( catfile( qw( t ipc_srlock.lck ) ) )->unlink;
io( catfile( qw( t ipc_srlock.shm ) ) )->unlink;
io( catfile( qw( t file-dataclass-schema.dat ) ) )->unlink;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
