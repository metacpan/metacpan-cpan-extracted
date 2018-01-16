use strict;
use warnings;

package Footprintless::Plugin::Database::DefaultCommandHelper;
$Footprintless::Plugin::Database::DefaultCommandHelper::VERSION = '1.04';
# ABSTRACT: The default implementation of command helper for db
# PODNAME: Footprintless::Plugin::Database::DefaultCommandHelper

use Carp;

sub new {
    return bless( {}, shift )->_init(@_);
}

sub allowed_destination {
    my ( $self, $coordinate ) = @_;
    return 1;
}

sub _init {
    my ( $self, $footprintless ) = @_;
    $self->{footprintless} = $footprintless;
    return $self;
}

sub locate_file {
    my ( $self, $file ) = @_;
    croak("file not found [$file]") unless ( -f $file );
    return $file;
}

sub post_restore {
    my ( $self, $from_coordinate, $to_coordinate ) = @_;
    my $file;
    eval { $file = $self->locate_file("$from_coordinate-$to_coordinate.sql"); };
    return $file;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::DefaultCommandHelper - The default implementation of command helper for db

=head1 VERSION

version 1.04

=head1 CONSTRUCTORS

=head2 new($footprintless)

Creates a new instance.

=head1 METHODS

=head2 allowed_destination($coordinate)

Returns a I<truthy> value if C<$coordinate> is allowed as a destination.

=head2 locate_file($file)

Returns the path to C<$file>.  Croaks if the file cannot be found.

=head2 post_restore($from_coordinate, $to_coordinate)

Returns the path to a sql script file that should be run after a restore.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=back

=cut
