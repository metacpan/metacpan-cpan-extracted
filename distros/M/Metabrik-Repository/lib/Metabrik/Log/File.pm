#
# $Id$
#
# log::file Brik
#
package Metabrik::Log::File;
use strict;
use warnings;

use base qw(Metabrik::Core::Log);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable logging) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         level => [ qw(0|1|2|3) ],
         output => [ qw(file) ],
         time_prefix => [ qw(0|1) ],
         text_prefix => [ qw(0|1) ],
         _fd => [ qw(file_descriptor) ],
      },
      attributes_default => {
         time_prefix => 1,
         text_prefix => 1,
      },
      commands => {
         message => [ qw(string caller|OPTIONAL) ],
         info => [ qw(string caller|OPTIONAL) ],
         verbose => [ qw(string caller|OPTIONAL) ],
         warning => [ qw(string caller|OPTIONAL) ],
         error => [ qw(string caller|OPTIONAL) ],
         fatal => [ qw(string caller|OPTIONAL) ],
         debug => [ qw(string caller|OPTIONAL) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;

   return {
      attributes_default => {
         level => $self->log->level,
         output => $datadir.'/output.log',
      },
   };
}

sub brik_init {
   my $self = shift;

   my $output = $self->output;
   open(my $fd, '>>', $output)
      or return $self->log->error("brik_init: can't open output file [$output]: $!");

   $self->log->verbose("brik_init: now logging to file [$output]");

   # Makes the file handle unbuffered
   my $current = select;
   select($fd);
   $|++;
   select($current);

   $self->_fd($fd);

   return $self->SUPER::brik_init;
}

sub _print {
   my $self = shift;
   my ($msg, $text, $graph, $caller) = @_;

   my $fd = $self->_fd;

   my $prefix = $self->text_prefix ? $text : $graph;
   my $time = $self->time_prefix ? localtime().' ' : '';
   my $buffer = $time."$prefix ".$self->message($msg, ($caller) ||= caller());

   print $fd $buffer;

   return 1;
}

sub warning {
   my $self = shift;
   my ($msg, $caller) = @_;

   return $self->_print($msg, 'WARN ', '[!]', ($caller) ||= caller());
}

sub error {
   my $self = shift;
   my ($msg, $caller) = @_;

   $self->_print($msg, 'ERROR', '[-]', ($caller) ||= caller());

   # Returning undef is my official way of stating an error occured:
   # Number 0 is for stating a false condition occured, not an error.
   return;
}

sub fatal {
   my $self = shift;
   my ($msg, $caller) = @_;

   $self->_print($msg, 'FATAL', '[F]', ($caller) ||= caller());

   my $prefix = $self->text_prefix ? 'FATAL' : '[F]';
   my $time = $self->time_prefix ? localtime().' ' : '';
   my $buffer = $time."$prefix ".$self->message($msg, ($caller) ||= caller());

   die($buffer);
}

sub info {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 0;

   return $self->_print($msg, 'INFO ', '[+]', ($caller) ||= caller());
}

sub verbose {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 1;

   return $self->_print($msg, 'VERB ', '[*]', ($caller) ||= caller());
}

sub debug {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 2;

   $self->_print($msg, 'DEBUG', '[D]', ($caller) ||= caller());

   return 1;
}

sub brik_fini {
   my $self = shift;

   my $fd = $self->_fd;
   if (defined($fd)) {
      close($fd);
      $self->_fd(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Log::File - log::file Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
