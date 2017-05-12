#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Logger;

use strict;
use utf8;

use FileHandle;

sub get_filename                { shift->{filename}                     }
sub get_filename_fh             { shift->{filename_fh}                  }

sub get_fh_lref                 { shift->{fh_lref}                      }
sub get_min_level               { shift->{min_level}                    }

sub set_fh_lref                 { shift->{fh_lref}              = $_[1] }
sub set_min_level               { shift->{min_level}            = $_[1] }

sub new {
    my $class = shift;
    my %par = @_;
    my  ($filename, $fh_lref, $min_level) =
    @par{'filename','fh_lref','min_level'};

    my $filename_fh;
    if ( $filename ) {
        $filename_fh = FileHandle->new;
        open ($filename_fh, ">>$filename")
                or die "can't write log $filename";
        $filename_fh->autoflush(1);
    }

    if ( $fh_lref ) {
        foreach my $fh ( @{$fh_lref} ) {
            my $old_fh = select $fh;
            $| = 1;
            select $old_fh;
        }
    }
    else {
        $fh_lref = [];
    }

    my $self = bless {
        filename        => $filename,
        filename_fh     => $filename_fh,
        fh_lref         => $fh_lref,
        min_level       => $min_level,
    }, $class;

    return $self;
}

sub DESTROY {
    my $self = shift;

    my $filename_fh = $self->get_filename_fh;
    close $filename_fh if $filename_fh;

    1;
}

sub log {
    my $self = shift;
    my ($level, $msg);

    if ( @_ == 2 ) {
        $level = $_[0];
        $msg   = $_[1];
    }
    else {
        $level = 1;
        $msg = $_[0];
    }

    return if $level > $self->get_min_level;

    $msg .= "\n" if $msg !~ /\n$/;

    my $str = localtime(time)." [$level] $msg";

    for my $fh ( @{$self->get_fh_lref} ) {
        print $fh $str if $fh;
    }

    my $fh = $self->get_filename_fh;
    print $fh $str if $fh;

    1;
}

sub add_fh {
    my $self = shift;
    my ($fh) = @_;

    push @{$self->get_fh_lref}, $fh;

    1;
}

sub remove_fh {
    my $self = shift;
    my ($fh) = @_;

    my $fh_lref = $self->get_fh_lref;

    my $i;
    for ( $i=0; $i<@{$fh_lref}; ++$i ) {
        last if $fh_lref->[$i] eq $fh;
    }

    return if $i == @{$fh_lref};
    splice @{$fh_lref}, $i, 1;

    1;
}

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Logger - Logging facility for Event::RPC

=head1 SYNOPSIS

  use Event::RPC::Server;
  use Event::RPC::Logger;
  
  my $server = Event::RPC::Server->new (
      ...
      logger => Event::RPC::Logger->new(
          filename  => "/var/log/myserver.log",
          fh_lref   => [ $fh, $sock ],
          min_level => 2,
      ),
      ...
  );

  $server->start;

=head1 DESCRIPTION

This modules implements a simple logging facility for the
Event::RPC framework. Log messages may be written to a
specific file and/or a bunch of filehandles, which may be
sockets as well.

=head1 CONFIGURATION OPTIONS

This is a list of options you can pass to the new() constructor:

=over 4

=item B<filename>

All log messages are appended to this file.

=item B<fh_lref>

All log messages are printed into this list of filehandles.

=item B<min_level>

This is the minimum log level. Output of messages with a lower level
is suppressed. This option may be altered using set_min_level() even
in a running server.

=back

=head1 METHODS

=over 4

=item $logger->B<log> ( [$level, ] $msg )

The log() method does the actual logging. Called with one argument
the messages gets the default level of 1. With two argumens the first
is the level for the message.

=item $logger->B<add_fh> ( $fh )

This adds a filehandle to the internal list of filhandles all log
messages are written to.

=item $logger->B<remove_fh> ( $fh )

Removes a filehandle.

=back

=head1 AUTHORS

  Jörn Reder <joern AT zyn.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
