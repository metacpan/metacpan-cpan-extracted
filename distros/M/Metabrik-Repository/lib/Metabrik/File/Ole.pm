#
# $Id: Ole.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# file::ole Brik
#
package Metabrik::File::Ole;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable read vbs) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         olevba => [ qw(olevba.py) ],
      },
      attributes_default => {
         olevba => '/usr/local/lib/python2.7/dist-packages/oletools/olevba.py',
      },
      commands => {
         install => [ ], # Inherited
         extract_vbs => [ qw(input|OPTIONAL output|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::Os' => [ ],
         'Metabrik::System::Package' => [ ],
      },
      require_binaries => {
         'python' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(python python-pip) ],
         debian => [ qw(python python-pip) ],
      },
   };
}

sub install {
   my $self = shift;

   # Install system dependant packages
   $self->SUPER::install or return;

   # Then Python dependant packages
   $self->sudo_system('pip install oletools --upgrade');

   return 1;
}

sub extract_vbs {
   my $self = shift;
   my ($input, $output) = @_;

   $input ||= $self->input;
   $output ||= $self->output;
   my $olevba = $self->olevba;
   $self->brik_help_run_undef_arg('extract_vbs', $input) or return;
   $self->brik_help_run_undef_arg('extract_vbs', $output) or return;
   $self->brik_help_run_file_not_found('extract_vbs', $olevba) or return;

   my $out = $self->capture("python $olevba $input");

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->write($out, $output) or return;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::File::Ole - file::ole Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
