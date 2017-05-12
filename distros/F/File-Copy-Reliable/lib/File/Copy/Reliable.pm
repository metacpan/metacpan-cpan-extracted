package File::Copy::Reliable;
use strict;
use warnings;
use Carp qw(croak);
use File::Copy;
use Path::Class;
use Exporter 'import';
our @EXPORT  = qw(copy_reliable move_reliable);
our $VERSION = '0.32';

sub copy_reliable {
    my ( $source, $destination ) = @_;
    my $source_size = (-s $source) || 0;

    copy( $source, $destination )
        || croak("copy_reliable($source, $destination) failed: $!");
    my $destination_file = $destination;
    if (-d $destination) {
        $destination_file = file( $destination, file( $source )->basename );
    }
    my $destination_size = (-s $destination_file) || 0;
    croak(
        "copy_reliable($source, $destination) failed copied $destination_size bytes out of $source_size"
        )
        if ( $source_size != $destination_size );
    1;

}

sub move_reliable {
    my ( $source, $destination ) = @_;
    my $source_size = (-s $source) || 0;

    move( $source, $destination )
        || croak("move_reliable($source, $destination) failed: $!");
    my $destination_file = $destination;
    if (-d $destination) {
        $destination_file = file( $destination, file( $source )->basename );
    }
    my $destination_size = (-s $destination_file) || 0;
    croak(
        "move_reliable($source, $destination) failed copied $destination_size bytes out of $source_size"
        )
        if ( $source_size != $destination_size );
    1;
}

1;

__END__

=head1 NAME

File::Copy::Reliable - file copying and moving with extra checking

=head1 SYNOPSIS

  use File::Copy::Reliable;
  copy_reliable( $source, $destination );
  move_reliable( $source, $destination );

=head1 DESCRIPTION

L<File::Copy> is an excellent module which handles copying and moving
files. L<File::Copy::Reliable> provides an extra level of checking
after the copy or move. This might be useful if you are copying or
moving to unreliable network fileservers.

At the moment this checks that the file size of the copied or moved
file is the same as the source.

The exported functions throw exceptions if there was an error.

=head1 EXPORTED FUNCTIONS

=head2 copy_reliable

Copies a file:

  copy_reliable( $source, $destination );

=head2 move_reliable

Moves a file:

  move_reliable( $source, $destination );

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2006 Foxtons Ltd.

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

