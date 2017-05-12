package Math::Geometry::Construction::Role::Output;
use Moose::Role;

use 5.008008;

use Carp;

=head1 NAME

C<Math::Geometry::Construction::Role::Output> - graphical output issues

=head1 VERSION

Version 0.019

=cut

our $VERSION = '0.019';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

requires 'construction';
requires 'id';

has 'hidden'         => (isa     => 'Bool',
		         is      => 'rw',
		         default => 0);

has 'label'          => (isa       => 'Str',
		         is        => 'rw',
		         clearer   => 'clear_label',
		         predicate => 'has_label');

has 'label_offset_x' => (isa     => 'Num',
		         is      => 'rw',
		         default => 0);

has 'label_offset_y' => (isa     => 'Num',
		         is      => 'rw',
		         default => 0);

has 'style'          => (isa     => 'HashRef[Str|ArrayRef]',
		         is      => 'rw',
		         reader  => 'style_hash',
		         writer  => '_style_hash',
		         traits  => ['Hash'],
		         default => sub { {} },
		         handles => {style => 'accessor'});

has 'label_style'    => (isa     => 'HashRef[Str|ArrayRef]',
		         is      => 'rw',
		         reader  => 'label_style_hash',
		         writer  => '_label_style_hash',
		         traits  => ['Hash'],
		         default => sub { {} },
		         handles => {label_style => 'accessor'});

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub draw_label {
    my ($self, %args) = @_;

    if($self->has_label) {
	my $label = $self->label;
	return $self->construction->draw_text
	    ('x'   => $args{x} + $self->label_offset_x,
	     'y'   => $args{y} + $self->label_offset_y,
	     style => $self->label_style_hash,
	     text  => defined($label) ? $label : '',
	     id    => $self->id.'_label');
    }

    return;
}

###########################################################################
#                                                                         #
#                              Change Data                                # 
#                                                                         #
###########################################################################

1;


__END__

=pod

=head1 DESCRIPTION

This role provides attributes and methods that are common to all
classes which actually draw something.

=head1 INTERFACE

=head2 Public Attributes

=head3 hidden

If set to a true value, the respective object does not create any
drawing output.

=head3 style

Hash reference with style settings. You can get the reference using
the C<style_hash> accessor. However, the recommended way to set
arguments after construction is to use the C<style> accessor to
access single entries of the hash. (For people familiar with
L<Moose|Moose>, this is the C<accessor> method of the C<Hash>
trait.)

Example:

  $point->style(fill => 'red') if(!$point->style('fill'));

The valid keys and values depend on the output type. From the point
of view of C<Math::Geometry::Construction>, any defined strings for
keys and values are allowed. For C<SVG> output, the hash is handed
over as a style hash to the respective element (see L<SVG|SVG>). For
C<TikZ> output, the style settings are realized by C<raw_mod> calls
(see L<LaTeX::TikZ|LaTeX::TikZ>).

=head2 Labels

A label is a little piece of text next to an object. The default
text anchor for the label is provided by the class consuming this
role. The positioning of the label is a tricky task. For example,
should the label of a point be printed left of right of the point,
above or below etc.? - Ideally, wherever is most space left by lines
and circles crossing that point. Obviously, the extension of the
label's bounding box has to be taken into account.

So far, I have not come up with a very convincing concept for
achieving this. At the moment, the label positions provided by the
objects are very primitive. For example, for a point, it is just the
position of the point itself. This looks very ugly and has to be
corrected by setting L<label_offset_x|/label_offset_x> and/or
L<label_offset_y|/label_offset_y>. In the future, these might be
estimated if not set by the user. Also possibly, the user might be
able to provide some kind of direction and the distance is
calculated automatically. All I can say at the moment is that label
positioning is prone to change and that currently, you will only get
decently looking results if you set the C<offset> values yourself.

=head3 label

Holds the label text. If not set nothing is drawn. If C<undef> the
empty string is drawn. Usually there will be no visible
difference. However, to really disable label output, call the
C<clear_label> method instead of setting the label to C<undef>.

=head3 label_offset_x

Offset in x direction.

=head3 label_offset_y

Offset in y direction.

=head3 label_style

Style settings for the label. The comments for the L<style|/style>
attribute also apply here.

=head2 Methods

=head3 draw_label

Draws the label. Called by objects that have consumed this role.


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

