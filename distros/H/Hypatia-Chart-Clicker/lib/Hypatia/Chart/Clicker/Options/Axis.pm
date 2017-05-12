package Hypatia::Chart::Clicker::Options::Axis;
{
  $Hypatia::Chart::Clicker::Options::Axis::VERSION = '0.026';
}
use strict;
use warnings;
use Moose;
use MooseX::Aliases;
use Hypatia::Types qw(PositiveInt);
use Hypatia::Chart::Clicker::Types qw(Color NumBetween0And1 Font AxisPosition AxisRange);
use Graphics::Color::RGB;
use Graphics::Primitive::Font;
use Scalar::Util qw(blessed);

#ABSTRACT: Options to apply to axes in Chart::Clicker via Hypatia


has "color"=>(isa=>Color, is=>"ro",coerce=>1,default=>sub{ Graphics::Color::RGB->new({r=>0,g=>0,b=>0,a=>1}) });


has "format"=>(isa=>"Str|CodeRef", is=>"ro",default=>"%s");


has "fudge_amount"=>(isa=>NumBetween0And1, is=>"ro", default=>0);


has "hidden"=>(isa=>"Bool", is=>"ro", default=>0);


has "label"=>(isa=>"Str", is=>"ro",predicate=>"has_label_option");


has "label_color"=>(isa=>Color, is=>"ro", coerce=>1,default=>sub{ Graphics::Color::RGB->new({r=>0,g=>0,b=>0,a=>1}) });


has "label_font"=>(isa=>Font, is=>"ro", coerce=>1,default=>sub{ Graphics::Primitive::Font->new });


has "position"=>(isa=>AxisPosition, is=>"ro", predicate=>"has_position_option");


has "range"=>(isa=>AxisRange, is=>"ro", coerce=>1, predicate=>"has_range_option");


has "show_ticks"=>(isa=>"Bool", is=>"ro", default=>1);


has "staggered"=>(isa=>"Bool", is=>"ro", default=>0);


has "skip_range"=>(isa=>AxisRange, is=>"ro", coerce=>1, predicate=>"has_skip_range_option");


has "tick_font"=>(isa=>Font, is=>"ro", coerce=>1,default=>sub{ Graphics::Primitive::Font->new });


has "tick_label_angle"=>(is=>"ro",isa=>"Num",default=>0);


has "tick_label_color"=>(isa=>Color, is=>"ro", coerce=>1,default=>sub{ Graphics::Color::RGB->new({r=>0,g=>0,b=>0,a=>1}) });


has "tick_labels"=>(isa=>"ArrayRef", is=>"ro", predicate=>"has_tick_labels_option");


has "tick_values"=>(isa=>"ArrayRef", is=>"ro", predicate=>"has_tick_values_option");



has "ticks"=>(isa=>PositiveInt, is=>"ro", predicate=>"has_ticks_option", alias=>"num_ticks");

sub apply_to
{
    my $self=shift;
    my $axis=shift;
    
    confess "Argument to sub apply_to is either missing or not a Chart::Clicker::Axis object"
	unless blessed($axis) eq "Chart::Clicker::Axis";
    
    my @attrs_to_check = qw(label position range skip_range tick_labels tick_values ticks);
    
    
    foreach my $attr(__PACKAGE__->meta->get_all_attributes)
    {
	my $attr_name=$attr->name;
	
	my $apply_option_flag = 1;
	
	if(grep{$attr_name eq $_}@attrs_to_check)
	{
	    my $predicate = "has_" . $attr_name . "_option";
	    
	    $apply_option_flag = 0 unless $self->$predicate();
	}
	
	
	if($apply_option_flag)
	{
	    my $attr_value = $self->$attr_name();
	    
	    eval{$axis->$attr_name($attr_value)};
	    
	    confess $@ if $@;
	}
    }
    
    return $axis;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Hypatia::Chart::Clicker::Options::Axis - Options to apply to axes in Chart::Clicker via Hypatia

=head1 VERSION

version 0.026

=head1 NOTE

Attributes of the following object types can be coerced from the following:

=over 4

=item * L<Graphics::Color::RGB> from either a hash reference with keys of C<r>, C<g>, C<b>, and C<a>
(and values between 0 and 1) or a number between 0 and 1 that is passed in for each of
C<r>, C<g>, C<b>, and C<a>.

=item * L<Chart::Clicker::Data::Range> (for axis ranges) from an array reference of two numbers, the first of which
needs to be smaller than the second. The numbers in question are passed into the C<min> and C<max> attributes of the
L<Chart::Clicker::Data::Range> object in question.

=item * L<Graphics::Primitive::Font> from a hash reference.

=back

Also, the attributes denoting B<positions> are L<enum|https://metacpan.org/module/Moose::Util::TypeConstraints>s with values of C<north>, C<south>, C<east>, C<west>, and C<center>.

=head1 ATTRIBUTES

=head2 color

The color of the axis. Of course, this is a L<Graphics::Color::RGB> object.

=head2 format

Either a format string that is passed to each tick label via L<sprintf|http://perldoc.perl.org/functions/sprintf.html> or
a code reference that is used to format the label values. See L<Chart::Clicker::Axis> for more information.

The default is C<< %s >>.

=head2 fudge_amount

The percentage (expressed as a number between 0 and 1) by which the axis will grow at both ends (as a "fudge factor").

The default is 0.

=head2 hidden

A boolean value to determine whether or not the axis will be hidden on the plot. The default is 0.

=head2 label

The label of the axis. This attribute is optional.

=head2 label_color

A L<Graphics::Color::RGB> object representing the color of the label.

=head2 label_font

A L<Graphics::Primitive::Font> object representing the font of the label. See L<Graphics::Primitive::Font> for the particulars.

=head2 position

The position of the axis on the chart (one of left, right, top, or bottom). This attribute is optional.

=head2 range

A L<Chart::Clicker::Data::Range> object representing the range of the axis. This attribute is optional.

=head2 show_ticks

A boolean representing whether or not ticks and labels should be shown for the given axis. The default is 1.

=head2 staggered

A boolean representing whether or not the tick labels alternate between one side of the axis and the other. The default is 0.

=head2 skip_range

A L<Chart::Clicker::Data::Range> object. If supplied, this range of values will be skipped completely on the axis. See L<Chart::Clicker::Axis> for more details.

=head2 tick_font

A L<Graphics::Primitive::Font> object representing the font for the tick labels.

=head2 tick_label_angle

The angle--measured in radians--to rate the tick labels. The default is 0.

=head2 tick_label_color

A L<Graphics::Color::RGB> object representing the color of the tick labels. The default is black.

=head2 tick_labels

An array reference of labels to apply to ticks (in order). See L<Chart::Clicker::Axis> for more details.

=head2 tick_values

An array reference of values denoting where the ticks should be on the axis. See L<Chart::Clicker::Axis> for more details.

=head2 ticks (a.k.a. num_ticks)

The number of ticks to show. See L<Chart::Clicker::Axis> for more details.

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
