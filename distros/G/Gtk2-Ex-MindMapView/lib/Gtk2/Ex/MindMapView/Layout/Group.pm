package Gtk2::Ex::MindMapView::Layout::Group;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use constant COLUMN_MAX_WIDTH=>400; # pixels

use constant PAD_HEIGHT=>10; # pixels

use constant PAD_WIDTH=>30; # pixels

sub new
{
    my $class = shift(@_);

    my %args = @_;

    my $self = \%args;

    bless $self, $class;

    _zero($self, qw(x y height width));

    return $self;
}


# my @values = $group->get(qw(x y width height));

sub get
{
    my $self = shift(@_);

    return undef if (scalar @_ == 0);

    return _get($self,shift(@_)) if (scalar @_ == 1);

    my @values = ();

    foreach my $key (@_) { push @values, _get($self,$key); }

    return @values;
}


# $group->get_horizontal_padding();

sub get_horizontal_padding()
{
    return PAD_WIDTH;
}


# $group->get_max_width();

sub get_max_width
{
    return COLUMN_MAX_WIDTH;
}


# $group->get_vertical_padding();

sub get_vertical_padding()
{
    return PAD_HEIGHT;
}


# $group->set(x=>0, y=>10, width=>20, height=>30);

sub set
{
    my $self = shift(@_);

    my %args = @_;

    foreach my $key (keys %args)
    {
	$self->{$key} = $args{$key};
    }
}


sub _get
{
    my ($self, $key) = @_;

    my $value = $self->{$key};

    croak "Undefined value for key $key.\n" if (!defined $value);

    return $value;
}


sub _zero
{
    my $self = shift(@_);

    foreach my $arg (@_)
    {
	if (!defined $self->{$arg}) { $self->{$arg} = 0; }
    }
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Gtk2::Ex::MindMapView::Layout::Group - A group of items displayed on canvas.


=head1 VERSION

This document describes Gtk2::Ex::MindMapView::Layout::Group version 0.0.1


=head1 SYNOPSIS

use base 'Gtk2::Ex::MindMapView::Layout::Group';
  

=head1 DESCRIPTION

Base class for the layout modules. This module is internal to
Gtk2::Ex::MindMapView.


=head1 INTERFACE 

=over

=item C<new()>

Instantiates an object and intializes the x, y, width, and height
properties of the object.

=item C<get('property')>

Returns the value of the x, y, width or height properties.

=item C<get_horizontal_padding()>

Returns the horizontal padding between columns.

=item C<get_max_width()>

Returns the maximum width of a column. This is used to limit the width
of a Gtk2::Ex::MindMapView::Item when it is first placed in the
Gtk2::Ex::MindMapView.


=item C<get_vertical_padding()>

Returns the vertical spacing between Gtk2::Ex::MindMapView::Items.

=item C<set(property=E<gt>$value)>

Sets the value of the x, y, width or height properties.

=back


=head1 DIAGNOSTICS

=over

=item C<Undefined value for key $key.>

You tried to 'get' a value that is not defined in this module.

=back


=head1 DEPENDENCIES

None.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-gtk2-ex-mindmapview@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

James Muir  C<< <hemlock@vtlink.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, James Muir C<< <hemlock@vtlink.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
