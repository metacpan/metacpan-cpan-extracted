package Hypatia::Chart::Clicker::Options;
{
  $Hypatia::Chart::Clicker::Options::VERSION = '0.026';
}
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use Hypatia::Types qw(PositiveNum PositiveInt);
use Hypatia::Chart::Clicker::Types qw(NumBetween0And1 Color Padding Position AxisOptions Format);
use Hypatia::Chart::Clicker::Options::Axis;
#use Hypatia::Chart::Clicker::Options::Title;
use Graphics::Color::RGB;
use Graphics::Primitive::Insets;
use Scalar::Util qw(blessed);

#ABSTRACT: Options to apply to Chart::Clicker objects via Hypatia


has [qw(domain_axis range_axis)]=>(isa=>AxisOptions,is=>"ro",coerce=>1
    ,default=>sub{ Hypatia::Chart::Clicker::Options::Axis->new });


has 'background_color'=>(isa=>Color,is=>"ro",coerce=>1,default=>sub{ Graphics::Color::RGB->new({r=>1,g=>1,b=>1,a=>1}) });


has 'format'=>(isa=>Format,is=>'ro',default=>"PNG");


has "width"=>(isa=>PositiveInt, is=>"ro", default=>500);

has 'height'=>(isa=>PositiveInt,is=>'ro',default=>300);

#TODO: Legend options


has 'legend_position'=>(isa=>Position,is=>'ro',default=>"south");


has "padding"=>(isa=>Padding,is=>"ro",coerce=>1,default=>sub{ Graphics::Primitive::Insets->new({top=>3,bottom=>3,right=>3,left=>3}) });

#has "title"=>(isa=>"TitleOptions", is=>"ro", coerce=>1, default=>sub{ Hypatia::Chart::Clicker::Options::Title->new });


has "title_position"=>(isa=>Position, is=>"ro",default=>"north");




sub apply_to
{
    my $self=shift;
    my $cc=shift;
    
    confess "Argument to sub apply_to is either missing or not a Chart::Clicker object" unless blessed($cc) eq "Chart::Clicker";
    
    foreach my $attr(__PACKAGE__->meta->get_all_attributes)
    {
	my $attr_name=$attr->name;
	
	
	my $attr_value = $self->$attr_name();
	
	if($attr_name eq "domain_axis" or $attr_name eq "range_axis")
	{
	    my $dc=$cc->get_context("default");
	    
	    my $axis=$dc->$attr_name();
	    
	    eval{$dc->$attr_name($self->$attr_name->apply_to($axis))};
	    
	    confess $@ if $@;
	}
	else
	{
	    eval{$cc->$attr_name($attr_value)};
	    
	    confess $@ if $@;
	}
    }
    
    return $cc;
    
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Hypatia::Chart::Clicker::Options - Options to apply to Chart::Clicker objects via Hypatia

=head1 VERSION

version 0.026

=head1 NOTE

Attributes of the following object types can be coerced from the following:

=over 4

=item * L<Graphics::Color::RGB> from either a hash reference with keys of C<r>, C<g>, C<b>, and C<a>
(and values between 0 and 1) or a number between 0 and 1 that is passed in for each of
C<r>, C<g>, C<b>, and C<a>.

=item * L<Hypatia::Chart::Clicker::Options::Axis> from a hash reference.

=back

#subtype "TitleOptions", as class_type("Hypatia::Chart::Clicker::Options::Title");
#coerce "TitleOptions", from "Str", via { Hypatia::Chart::Clicker::Options::Title->new({text=>$_}) };
#coerce "TitleOptions", from "HashRef", via { Hypatia::Chart::Clicker::Options::Title->new($_) };

=head1 ATTRIBUTES

=head2 domain_axis,range_axis

These hash references are passed directly into L<Hypatia::Chart::Clicker::Options::Axis> objects. Look at the documentation of that module for more details.

=head2 background_color

A L<Graphics::Color::RGB> object that, unsurprisingly, controls the color of the background. The default is white.

=head2 format

A string: one of C<png>, C<pdf>, C<ps>, or C<svg>. The default is C<png>.

=head2 width,height

The width and height of the resulting image. The defaults are 500 and 300, respectively.

=head2 legend_position

One of C<north>, C<west>, C<east>, C<south>, or C<center>. The default is C<south>.

=head2 padding

A L<Graphics::Primitive::Insets> object representing the amount of padding (in pixels) for each of the sides of the chart. You may also pass in either a hash reference (with keys of C<top>, C<bottom>, C<right>, and C<left> having positive integer values), or a positive integer (which is then assigned to each of C<top>, C<bottom>, C<right>, and C<left>).

=head2 title_position

One of C<north>, C<west>, C<east>, C<south>, or C<center>. The default is C<north>.

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
