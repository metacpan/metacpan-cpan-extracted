package Gimp::Lib;

use strict;
use warnings;
use vars qw($VERSION @ISA);

BEGIN {
   $VERSION = "2.38";
   require XSLoader;
   XSLoader::load Gimp::Lib $VERSION;
   warn "$$-Loading ".__PACKAGE__ if $Gimp::verbose >= 2;
}

sub gimp_init {
   Gimp::croak Gimp::__("gimp_init not implemented for the Lib interface");
}

sub gimp_end {
   Gimp::croak Gimp::_("gimp_end not implemented for the Lib interface");
}

sub lock {
   # unimplemented, ignored
}

sub unlock {
   # unimplemented, ignored
}

sub import {}

# functions to "autobless" where the autobless mechanism
# does not work.

sub gimp_image_list {
   map _autobless($_,&Gimp::PDB_IMAGE),gimp_call_procedure "gimp_image_list";
}

sub gimp_image_get_layers {
   map _autobless($_,&Gimp::PDB_LAYER),gimp_call_procedure "gimp_image_get_layers",@_;
}

sub gimp_image_get_channels {
   map _autobless($_,&Gimp::PDB_CHANNEL),gimp_call_procedure "gimp_image_get_channels",@_;
}

# "server-side" perl code evaluation
sub server_eval {
   my @res = eval "package Gimp::Eval; $_[0]";
   die $@ if $@;
   wantarray ? @res : $res[0];
}

# this is here to be atomic over the perl-server
sub _gimp_append_data($$) {
   gimp_set_data ($_[0], gimp_get_data ($_[0]) . $_[1]);
}

# convenience functions
sub gimp_gdrawable_pixel_rgn($$$$$$$) {
   Gimp::gimp_pixel_rgn_init(@_);
}

sub gimp_progress_init {
   if (@_<2) {
      goto &_gimp_progress_init;
   } else {
      eval { gimp_call_procedure "gimp_progress_init",@_ };
      gimp_call_procedure "gimp_progress_init",shift if $@;
   }
}

sub gimp_drawable_bounds {
   my @b = (shift->mask_bounds)[1..4];
   (@b[0,1],$b[2]-$b[0],$b[3]-$b[1]);
}

warn "$$-Finished loading ".__PACKAGE__ if $Gimp::verbose >= 2;

1;
__END__

=head1 NAME

Gimp::Lib - Interface to libgimp (as opposed to Gimp::Net)

=head1 SYNOPSIS

  use Gimp; # internal use only

=head1 DESCRIPTION

This is the package that interfaces to GIMP via the libgimp interface,
i.e. the normal interface to use with GIMP. You don't normally use this
module directly, see L<Gimp>.

=head1 AUTHOR

Marc Lehmann <pcg@goof.com>

=head1 SEE ALSO

perl(1), L<Gimp>.

=cut
