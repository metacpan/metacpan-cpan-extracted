#
# $Id$
#
# email::mbox Brik
#
package Metabrik::Email::Mbox;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(mbox_file) ],
         _folder => [ qw(INTERNAL) ],
      },
      commands => {
         open => [ qw(mbox_file|OPTIONAL) ],
         read => [ ],
         read_next => [ ],
         close => [ ],
      },
      require_modules => {
         'Email::Folder' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('open', $input) or return;

   my $folder = Email::Folder->new($input);
   if (! defined($folder)) {
      return $self->log->error("open: Email::Folder new failed for mbox [$input]");
   }

   return $self->_folder($folder);
}

sub read {
   my $self = shift;

   my $folder = $self->_folder;
   $self->brik_help_run_undef_arg('open', $folder) or return;

   my @messages = ();
   for my $message ($folder->messages) {
      my $subject = $message->header('Subject');
      $self->log->verbose("read: Subject [$subject]");

      push @messages, $message;
   }

   return \@messages;
}

sub read_next {
   my $self = shift;

   my $folder = $self->_folder;
   $self->brik_help_run_undef_arg('open', $folder) or return;

   my $message = $folder->next_message;

   return $message;
}

sub close {
   my $self = shift;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Email::Mbox - email::mbox Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
