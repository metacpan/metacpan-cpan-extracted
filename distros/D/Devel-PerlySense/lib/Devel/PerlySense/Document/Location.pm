=head1 NAME

Devel::PerlySense::Document::Location - A file name + cursor position

=head1 SYNOPSIS




=head1 DESCRIPTION

A location describes a cursor position (optional) in a file, and
optional properties.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Document::Location;
$Devel::PerlySense::Document::Location::VERSION = '0.0221';




use Spiffy -Base;
use Carp;
use Data::Dumper;
use Storable "dclone";
use PPI;
use File::Slurp;





=head1 PROPERTIES

=head2 file

Default: ""

=cut
field "file" => "";



=head2 row

The row (0..) of the location. The actual rows are 1.., 0 means N/A.

Default: 0

=cut
field "row";





=head2 col

The col (0..) of the location. The actual cols are 1.., 0 means N/A.

Default: 0

=cut
field "col";





=head2 rhProperty

Hash ref with (names: name of payload, keys: some payload).

A generic container for whatever things may be attached to this
location, like POD text, a PPI::Node, a type string or whatever.

Default: {}

=cut
field "rhProperty" => {};





=head1 API METHODS

=head2 new(file => $file, row => $row, col => $col)

Create new Location object.

=cut
sub new(@) {
    my $pkg = shift;
    my (%p) = @_;

    my $self = bless {}, $pkg;

    $self->file($p{file} || "");
    $self->row($p{row} || 0);
    $self->col($p{col} || 0);
    $self->rhProperty($p{rhProperty} || {});

    return($self);    
}





=head2 clone()

Return clone of this object.

Die on errors.

=cut
sub clone {
    return(dclone($self));
}





=head2 rhInfo()

Return a hash ref with the complete attributes of the class, i.e. both
the file and the properties in rhProperty.

=cut
sub rhInfo {
    my $rhInfo = dclone($self->rhProperty);
    for my $field (qw/ file row col /) {
        $rhInfo->{$field} = $self->$field;
    }
    
    return($rhInfo);
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
