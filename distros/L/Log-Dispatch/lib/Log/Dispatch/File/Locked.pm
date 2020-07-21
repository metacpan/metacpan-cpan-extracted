package Log::Dispatch::File::Locked;

use strict;
use warnings;

our $VERSION = '2.70';

use Fcntl qw(:DEFAULT :flock);

use base qw( Log::Dispatch::File );

sub log_message {
    my $self = shift;
    my %p    = @_;

    if ( $self->{close_after_write} ) {
        $self->_open_file;
    }

    my $fh = $self->{fh};

    flock( $fh, LOCK_EX )
        or die "Cannot lock '$self->{filename}' for writing: $!";

    # just in case there was an append while we waited for the lock
    seek( $fh, 0, 2 )
        or die "Cannot seek to end of '$self->{filename}': $!";

    if ( $self->{syswrite} ) {
        defined syswrite( $fh, $p{message} )
            or die "Cannot write to '$self->{filename}': $!";
    }
    else {
        print $fh $p{message}
            or die "Cannot write to '$self->{filename}': $!";
    }

    flock( $fh, LOCK_UN ) or die "Cannot unlock '$self->{filename}'";
    if ( $self->{close_after_write} ) {
        close $fh
            or die "Cannot close '$self->{filename}': $!";
        delete $self->{fh};
    }
}

1;

# ABSTRACT: Subclass of Log::Dispatch::File to facilitate locking

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::File::Locked - Subclass of Log::Dispatch::File to facilitate locking

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'File::Locked',
              min_level => 'info',
              filename  => 'Somefile.log',
              mode      => '>>',
              newline   => 1
          ]
      ],
  );

  $log->emerg("I've fallen and I can't get up");

=head1 DESCRIPTION

This module acts exactly like L<Log::Dispatch::File> except that it
obtains an exclusive lock on the file while opening it.

Note that if you are using this output because you want to write to a file
from multiple processes, you should open the file with the append C<mode>
(C<<< >> >>>), or else it's quite likely that one process will overwrite
another.

=head1 SEE ALSO

L<perlfunc/flock>

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
