#
# $Id: Imap.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# email::imap Brik
#
package Metabrik::Email::Imap;
use strict;
use warnings;

use base qw(Metabrik::Email::Mbox);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(imap_uri) ],
         _folder => [ qw(INTERNAL) ],
      },
      commands => {
         open => [ qw(imap_uri|OPTIONAL) ],
         read => [ ],
         read_next => [ ],
         close => [ ],
      },
      require_modules => {
         'Email::Folder' => [ ],
         'Email::Folder::IMAP' => [ ],
         'Email::Folder::IMAPS' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('open', $input) or return;

   eval("use Email::FolderType::Net;");

   my $folder = Email::Folder->new($input);
   if (! defined($folder)) {
      return $self->log->error("open: Email::Folder new failed for imap [$input]");
   }

   return $self->_folder($folder);
}

1;

__END__

=head1 NAME

Metabrik::Email::Imap - email::imap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
