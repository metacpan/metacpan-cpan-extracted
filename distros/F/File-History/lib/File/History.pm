package File::History;
use strict;
use warnings;
use IO::File;
use Fcntl qw(:flock);
use File::ReadBackwards;
use Carp;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors($_) for qw(history buf pointer filename);

our $VERSION = '0.00002';

sub new {
    my $class = shift;
    my %args  = @_;

    unless ( exists $args{filename} ) {
        croak "Must provide filename";
    }

    unless ( -f $args{filename} ) {
        my $io = IO::File->new($args{filename}, 'w+')
            or croak "Could not make file $args{filename}";
        $io->close;
    }

    my $self = $class->SUPER::new();
    $self->filename( $args{filename} );
    $self->pointer(0);
    $self->buf( [] );

    my $history = File::ReadBackwards->new( $args{filename} );
    $self->history($history);

    return $self;
}

sub find_history {
    my $self = shift;
    my $buf  = $self->buf;
    my $line;

    if ( scalar(@$buf) > 0 ) {
        if ( defined( $line = $buf->[ $self->pointer ] ) ) {
            my $pointer = $self->pointer + 1;
            $self->pointer($pointer);
            return $line;
        }
    }
    if ( defined( $line = $self->history->readline ) ) {
        chomp($line);
        return $line;
    }

    return ();
}

sub add_history {
    my $self = shift;
    my $buf  = $self->buf;

    unshift @$buf, shift;
    $self->pointer(0);
}

sub flush {
    my $self     = shift;
    my $filename = $self->filename;
    my $buf      = $self->buf;

    if ( scalar(@$buf) > 0 ) {
        my $io = IO::File->new( $filename, '>>' );
        flock( $io, LOCK_EX );
        for ( reverse @$buf) {
            $io->print($_."\n");
        }
        flock( $io, LOCK_UN );
        $io->close;
    }
}

1;
__END__

=head1 NAME

File::History - It is a simple history file maker. 

=head1 SYNOPSIS

  use File::History;

  my $history = File::History->new(
      filename  => '/path/to/.history'
  );

  my $cmd = $history->find_history();
  $history->add_history($cmd);
  $history->flush;

=head1 DESCRIPTION

File::History is simpel history file maker

=head1 METHOD

=head2 new(filename => $filename)

  The constructor must specify passing the history file.

=head2 find_history();

  This method picks up a record from input history.

=head2 add_history($cmd);

  The command newly input is stored in the memory.

=head2 flush();

  This method writes file the input history.
  When you finish a terminal, this method is called.

=head1 AUTHOR

Kazuhiro Nishikawa E<lt>kazuhiro.nishikawa@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
