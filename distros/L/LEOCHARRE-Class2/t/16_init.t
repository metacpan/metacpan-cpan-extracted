package AppThing;
use lib './lib';
use LEOCHARRE::Class2;
use Smart::Comments '###';
use strict;
__PACKAGE__->make_constructor_init;
__PACKAGE__->make_accessor_setget( 'val' );
__PACKAGE__->make_accessor_setget_aref( 'files' );

sub init {
   my $self = shift;

   $self->val('ran');
   
   my @files = split(/\n/, `find './' -type f`);
   $self->files( \@files );


   
}

1;



use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Smart::Comments '###';
use Cwd;


ok(1);

my $o = new AppThing;
ok  $o;

ok $o->val ;

ok( $o->val eq 'ran' );

my $files = $o->files;

my $fcount = $o->files_count;
ok( $fcount, "files count $fcount");

