#
# $Id: Msoffice.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# remote::msoffice Brik
#
package Metabrik::Remote::Msoffice;
use strict;
use warnings;

use base qw(Metabrik::Remote::Winexe);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         host => [ qw(host) ],
         user => [ qw(username) ],
         password => [ qw(password) ],
         winword_exe_path => [ qw(path) ],
      },
      attributes_default => {
         winword_exe_path => 'C:\Program Files (x86)\Microsoft Office\Office12\WINWORD.EXE',
      },
      commands => {
         install => [ ],  # Inherited
         open_word_document => [ qw(path) ],
      },
   };
}

sub open_word_document {
   my $self = shift;
   my ($doc) = @_;

   $self->brik_help_run_undef_arg('open_word_document', $doc) or return;

   my $winword_exe_path = $self->winword_exe_path;

   # winexe -UUSER%PASS //IP '"C:\Program Files (x86)\Microsoft Office\Office12\WINWORD.EXE" "test.docx"'
   return $self->execute("'\"$winword_exe_path\" \"$doc\"'");
}

1;

__END__

=head1 NAME

Metabrik::Remote::Msoffice - remote::msoffice Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
