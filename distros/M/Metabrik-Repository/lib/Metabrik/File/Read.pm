#
# $Id: Read.pm,v de0c829662da 2018/10/09 14:39:51 gomor $
#
# file::read Brik
#
package Metabrik::File::Read;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: de0c829662da $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         fd => [ qw(file_descriptor) ],
         as_array => [ qw(0|1) ],
         eof => [ qw(0|1) ],
         count => [ qw(count) ],
         strip_crlf => [ qw(0|1) ],
         skip_comment => [ qw(0|1) ],
         skip_blank_line => [ qw(0|1) ],
      },
      attributes_default => {
         as_array => 0,
         eof => 0,
         count => 1,
         strip_crlf => 1,
         skip_comment => 0,
         skip_blank_line => 0,
      },
      commands => {
         open => [ qw(file|OPTIONAL) ],
         close => [ ],
         offset => [ ],
         seek => [ qw(offset) ],
         read => [ ],
         read_until_blank_line => [ ],
         read_until_ini_block => [ ],
         read_line => [ qw(count|OPTIONAL) ],
         is_eof => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         encoding => defined($self->global) && $self->global->encoding || 'utf8',
      },
   };
}

sub open {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('open', $input) or return;

   my $r;
   my $out;
   my $encoding = $self->encoding || 'ascii';
   if ($encoding eq 'ascii') {
      $r = open($out, '<', $input);
   }
   else {
      $r = open($out, "<$encoding", $input);
   }
   if (! defined($r)) {
      return $self->log->error("open: open: file [$input]: $!");
   }

   return $self->fd($out);
}

sub close {
   my $self = shift;

   if (defined($self->fd)) {
      close($self->fd);
      $self->eof(0);
   }

   return 1;
}

sub offset {
   my $self = shift;

   my $fd = $self->fd;
   $self->brik_help_run_undef_arg('open', $fd) or return;

   my $r = CORE::tell($fd);
   if (! defined($r)) {
      return $self->log->error("offset: unable to get offset: [$!]");
   }

   return $r;
}

sub seek {
   my $self = shift;
   my ($offset) = @_;

   my $fd = $self->fd;
   $self->brik_help_run_undef_arg('open', $fd) or return;
   $self->brik_help_run_undef_arg('seek', $offset) or return;

   my $r = CORE::seek($fd, $offset, 0);
   if (! $r) {
      return $self->log->error("seek: unable to seek to offset [$offset]: [$!]");
   }

   return $offset;
}

sub read {
   my $self = shift;

   my $fd = $self->fd;
   $self->brik_help_run_undef_arg('open', $fd) or return;

   my $strip_crlf = $self->strip_crlf;
   my $skip_comment = $self->skip_comment;
   my $skip_blank_line = $self->skip_blank_line;

   if ($self->as_array) {
      my @out = ();
      while (<$fd>) {
         if ($skip_comment) {
            next if m{^\s*#};
         }
         if ($skip_blank_line) {
            next if m{^\s*$};
         }
         if ($strip_crlf) {
            s/[\r\n]*$//;
         }
         push @out, $_;
      }
      $self->eof(1);
      return \@out;
   }
   else {
      my $out = '';
      while (<$fd>) {
         if ($skip_comment) {
            next if m{^\s*#};
         }
         if ($skip_blank_line) {
            next if m{^\s*$};
         }
         $out .= $_;
      }
      $self->eof(1);
      if ($strip_crlf) {
         $out =~ s/[\r\n]*$//;
      }
      return $out;
   }

   return;
}

sub read_until_blank_line {
   my $self = shift;

   my $fd = $self->fd;
   $self->brik_help_run_undef_arg('open', $fd) or return;

   my $strip_crlf = $self->strip_crlf;
   my $skip_comment = $self->skip_comment;

   if ($self->as_array) {
      my @out = ();
      while (<$fd>) {
         if ($skip_comment) {
            next if m{^\s*#};
         }
         last if /^\s*$/;
         if ($strip_crlf) {
            s/[\r\n]*$//;
         }
         push @out, $_;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      return \@out;
   }
   else {
      my $out = '';
      while (<$fd>) {
         if ($skip_comment) {
            next if m{^\s*#};
         }
         last if /^\s*$/;
         $out .= $_;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      if ($strip_crlf) {
         $out =~ s/[\r\n]*$//;
      }
      return $out;
   }

   return;
}

sub read_until_ini_block {
   my $self = shift;

   my $fd = $self->fd;
   $self->brik_help_run_undef_arg('open', $fd) or return;

   my $strip_crlf = $self->strip_crlf;
   my $skip_comment = $self->skip_comment;
   my $skip_blank_line = $self->skip_blank_line;

   my $block = undef;
   my $offset = 0;
   if ($self->as_array) {
      my @out = ();
      while (<$fd>) {
         if ($skip_comment) {
            next if m{^\s*#};
         }
         if ($skip_blank_line) {
            next if m{^\s*$};
         }
         if ($strip_crlf) {
            s/[\r\n]*$//;
         }
         if (/^\s*\[\s*\S+\s*\]\s*$/) {
            if (!defined($block)) {
               $block = $_;
            }
            else {
               $self->seek($offset);  # New block starting, restore to previous offset
                                      # for next Command call.
               last;
            }
         }
         push @out, $_;
         $offset = $self->offset($fd) or return;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      return \@out;
   }
   else {
      my $out = '';
      while (<$fd>) {
         if ($skip_comment) {
            next if m{^\s*#};
         }
         if ($skip_blank_line) {
            next if m{^\s*$};
         }
         if (/^\s*\[\s*\S+\s*\]\s*$/) {
            if (!defined($block)) {
               $block = $_;
            }
            else {
               $self->seek($offset);  # New block starting, restore to previous offset 
                                      # for next Command call.
               last;
            }
         }
         $out .= $_;
         $offset = $self->offset($fd) or return;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      if ($strip_crlf) {
         $out =~ s/[\r\n]*$//;
      }
      return $out;
   }

   return;
}

sub read_line {
   my $self = shift;
   my ($count) = @_;

   my $fd = $self->fd;
   $self->brik_help_run_undef_arg('open', $fd) or return;

   $count ||= $self->count;

   my $strip_crlf = $self->strip_crlf;
   my $skip_comment = $self->skip_comment;
   my $skip_blank_line = $self->skip_blank_line;

   if ($self->as_array) {
      my @out = ();
      my $this = 1;
      while (<$fd>) {
         if ($skip_comment) {
            next if m{^\s*#};
         }
         if ($skip_blank_line) {
            next if m{^\s*$};
         }
         if ($strip_crlf) {
            s/[\r\n]*$//;
         }
         push @out, $_;
         last if $this == $count;
         $count++;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      return \@out;
   }
   else {
      my $out = '';
      my $this = 1;
      while (<$fd>) {
         if ($skip_comment) {
            next if m{^\s*#};
         }
         if ($skip_blank_line) {
            next if m{^\s*$};
         }
         last if /^\s*$/;
         $out .= $_;
         last if $this == $count;
         $count++;
      }
      if (eof($fd)) {
         $self->eof(1);
      }
      if ($strip_crlf) {
         $out =~ s/[\r\n]*$//;
      }
      return $out;
   }

   return;
}

sub is_eof {
   my $self = shift;

   return $self->eof;
}

1;

__END__

=head1 NAME

Metabrik::File::Read - file::read Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
