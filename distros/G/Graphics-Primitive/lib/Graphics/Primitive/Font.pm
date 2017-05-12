package Graphics::Primitive::Font;
use Moose;
use MooseX::Storage;
use Moose::Util::TypeConstraints;

with 'MooseX::Clone';
with Storage (format => 'JSON', io => 'File');

enum 'Graphics::Primitive::Font::AntialiasModes' => [
    qw(default none gray subpixel)
];
enum 'Graphics::Primitive::Font::HintMetrics' => [
    'default', 'off', 'on'
];
enum 'Graphics::Primitive::Font::HintStyles' => [
    'default', 'none', 'slight', 'medium', 'full'
];
enum 'Graphics::Primitive::Font::Slants' => [
    'normal', 'italic', 'oblique'
];
enum 'Graphics::Primitive::Font::SubpixelOrders' => [
    qw(default rgb bgr vrgb vbgr)
];
enum 'Graphics::Primitive::Font::Variants' => [
    'normal', 'small-caps'
];
enum 'Graphics::Primitive::Font::Weights' => [
    'normal', 'bold'
];

has 'antialias_mode' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Font::AntialiasModes',
    default => 'default'
);
has 'family' => (
    is => 'rw',
    isa => 'Str',
    default => $ENV{GRAPHICS_PRIMITIVE_DEFAULT_FONT} || ($^O eq 'MSWin32'?'Arial':'Sans')
);
has 'hint_metrics' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Font::HintMetrics',
    default => 'default'
);
has 'hint_style' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Font::HintStyles',
    default => 'default'
);
has 'size' => (
    is => 'rw',
    isa => 'Num',
    default => sub { 12 }
);
has 'slant' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Font::Slants',
    default => 'normal'
);
has 'subpixel_order' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Font::SubpixelOrders',
    default => 'default'
);
has 'variant' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Font::Variants',
    default => 'normal'
);
has 'weight' => (
    is => 'rw',
    isa => 'Graphics::Primitive::Font::Weights',
    default => 'normal'
);

__PACKAGE__->meta->add_method('face' => __PACKAGE__->can('family'));

sub derive {
    my ($self, $args) = @_;

    return unless ref($args) eq 'HASH';
    my $new = $self->clone;
    foreach my $key (keys %{ $args }) {
        $new->$key($args->{$key}) if($new->can($key));
    }
    return $new;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Font - Text styling

=head1 DESCRIPTION

Graphics::Primitive::Font represents the various options that are available
when rendering text.  The options here may or may not have an effect on your
rendering.  They represent a cross-section of the features provided by
various drivers.  Setting them should B<not> break anything, but may not
have an effect if the driver doesn't understand the option.

=head1 SYNOPSIS

  use Graphics::Primitive::Font;

  my $font = Graphics::Primitive::Font->new({
    family => 'Arial',
    size => 12,
    slant => 'normal'
  });

=head1 METHODS

=head2 Constructor

=over 4

=back

=head1 Attributes

=head2 antialias_modes

Set the antialiasing mode for this font. Possible values are default, none,
gray and subpixel.

=head2 family

Set this font's family.

=head2 hint_metrics

Controls whether to hint font metrics.  Hinting means quantizing them so that
they are integer values in device space.  This improves the consistency of
letter and line spacing, however it also means that text will be laid out
differently at different zoom factors.  May not be supported by all drivers.

=head2 hint_style

Set the the type of hinting to do on font outlines.  Hinting is the process of
fitting outlines to the pixel grid in order to improve the appearance of the
result. Since hinting outlines involves distorting them, it also reduces the
faithfulness to the original outline shapes. Not all of the outline hinting
styles are supported by all drivers.  Options are default, none, slight,
medium and full.

=head2 size

Set/Get the size of this font.

=head2 slant

Set/Get the slant of this font.  Valid values are normal, italic and oblique.

=head2 subpixel_order

Set the order of color elements within each pixel on the display device when
rendering with subpixel antialiasing.  Value values are default, rgb, bgr,
vrgb and vbgr.

=head2 variant

Set/Get the variant of this font.  Valid values are normal or small-caps.

=head2 weight

Set/Get the weight of this font.  Value valies are normal and bold.

=head1 METHODS

=head2 new

Creates a new Graphics::Primitive::Font.

=head2 derive

Clone this font but change one or more of it's attributes by passing in a
hashref of options:

  my $new = $font->derive({ attr => $newvalue });
  
The returned font will be identical to the cloned one, save the attributes
specified.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
