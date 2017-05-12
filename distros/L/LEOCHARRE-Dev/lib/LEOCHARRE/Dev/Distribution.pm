package LEOCHARRE::Dev::Distribution;
use strict;
use LEOCHARRE::Class2;
use LEOCHARRE::Dev;


__PACKAGE__->make_accessor_setget_ondisk_dir('abs_path');

__PACKAGE__->make_accessor_setget(qw(
abs_makefile
abs_manifest
name
version_from
ls_manifest
code_manifest
version
));

__PACKAGE__->make_constructor_init;

sub init {
   my $self = shift;

   $self->abs_path or die("Missing abs_path\n");   
   LEOCHARRE::Dev::is_pmdist($self->abs_path) or die;

   $self->name( LEOCHARRE::Dev::pmdist_guess_name($self->abs_path) ) or die("can't guess name");
   $self->version_from( LEOCHARRE::Dev::pmdist_guess_version_from($self->abs_path) ) or die;
   $self->abs_makefile($self->abs_path.'/Makefile.PL'); 
   $self->abs_manifest($self->abs_path.'/MANIFEST'); # of if not there

   my @lsm = grep { defined } LEOCHARRE::Dev::ls_pmdist($self->abs_path);
   $self->ls_manifest( \@lsm );
   $self->code_manifest(  join( "\n", @lsm ) );


}




sub reset_manifest {
   my $self = shift;  
   open(FILE, '>', $self->abs_manifest ) or die;
   print FILE $self->code_manifest;
   close FILE;
   return $self->code_manifest;
}





1;













