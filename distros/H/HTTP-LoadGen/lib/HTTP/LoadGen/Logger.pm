package HTTP::LoadGen::Logger;

use strict;
use Coro;
use Coro qw/:prio/;
use Coro::Channel;
use Coro::Handle;

our $VERSION = '0.02';

sub get {
  my ($fh, $fmt)=@_;
  my $queue=Coro::Channel->new;
  $fh=\*STDOUT unless $fh;
  unless( ref $fh ) {
    my $name=$fh;
    undef $fh;
    open $fh, '>>', $name or die "Cannot open logfile $name: $!\n";
  }
  $fh=unblock $fh;
  my $thr=async {
    my ($fh)=@_;
    $Coro::current->prio(PRIO_MIN);
    while(defined(my $l=$queue->get)) {
      $fh->syswrite($l);
      cede;
    }
  } $fh;

  if($fmt) {
    return sub {
      if(@_) {
	$queue->put(scalar $fmt->(@_));
      } else {
	$queue->shutdown;
	$thr->join;
      }
    };
  } else {
    return sub {
      if(@_) {
	$queue->put(join("\t", @_)."\n");
      } else {
	$queue->shutdown;
	$thr->join;
      }
    };
  }
}

1;
__END__

=encoding utf8

=head1 NAME

HTTP::LoadGen::Logger - a Coro based logger

=head1 SYNOPSIS

 use HTTP::LoadGen::Logger;

 # get a logger
 $logger=HTTP::LoadGen::Logger::get $filehandle_or_name, $formatter;

 # use it
 $logger->(@data);

 # close it
 $logger->();

=head1 DESCRIPTION

This module implements a L<Coro>-aware logger. A logger here is a function
reference. When called it passes its arguments to the formatter function and
pushs the resulting string into a queue. This queue is then processed by a
separate L<Coro> thread that runs with the lowest possible priority.
The thread prints each line to the C<$filehandle> that was given when the
logger was created.

This logger tries to stay out of the way of normal processing as much as
possible. The drawback is that when your program has always something other
to do all logging output is buffered in RAM.

=head2 Functions

=head3 $logger=HTTP::LoadGen::Logger::get $filehandle_or_name, $formatter

creates a logger that writes to C<$filehandle>.

If a file name is passed it is opened to append. On open failure an execption
is thrown.

The logger is then used as:

 $logger->(@parameters);

C<$formatter> is expected to be a function reference that returns a string.
It is called in scalar context as:

 $formatter->(@parameters);

where C<@parameters> are the parameters passed to the logger.

Both C<$filehandle> and C<$formatter> are optional. If omitted C<STDOUT>
is used as output stream and

 join("\t, @parameters)."\n"

as formatter.

If the logger is called without arguments as:

 $logger->();

it is signaled that logging is done. This call waits for the writer thread
to write out all remaining data. It returns only after the writer thread is
done. Note, the file handle is not closed by this call.

=head2 EXPORT

None.

=head1 SEE ALSO

L<HTTP::LoadGen>

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
