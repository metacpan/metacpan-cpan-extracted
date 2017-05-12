package Graphics::Color;
$Graphics::Color::VERSION = '0.31';
use Moose;
use Moose::Util::TypeConstraints;

with qw(MooseX::Clone Graphics::Color::Equal MooseX::Storage::Deferred);

# ABSTRACT: Device and library agnostic color spaces.


sub derive {
    my ($self, $args) = @_;

    return unless ref($args) eq 'HASH';
    my $new = $self->clone;
    foreach my $key (keys %{ $args }) {
        $new->$key($args->{$key}) if($new->can($key));
    }
    return $new;
}


sub equal_to {
    die("Override me!");
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

__END__

=pod

=head1 NAME

Graphics::Color - Device and library agnostic color spaces.

=head1 VERSION

version 0.31

=head1 SYNOPSIS

  my $color = Graphics::Color::RGB->new(
      red => .5, green => .5, blue => .5, alpha => .5
  );
  say $color->as_string;

=head1 DESCRIPTION

Graphics color is a device and library agnostic system for creating and
manipulating colors in various color spaces.

=head1 DISCLAIMER

I'm not an art student or a wizard of arcane color knowledge.  I'm a normal
programmer with a penchant for things graphical.  Hence this module is likely
incomplete in some places.  Patches are encouraged.  I've intentions of adding
more color spaces as well as conversion routines (where applicable).

=head1 COLOR TYPES

The following color types are supported.

L<CMYK|Graphics::Color::CMYK>

L<HSL|Graphics::Color::HSL>

L<HSV|Graphics::Color::HSV>

L<RGB|Graphics::Color::RGB>

L<YIQ|Graphics::Color::YIQ>

L<YUV|Graphics::Color::YUV>

=head1 METHODS

=head2 derive

Clone this color but allow one of more of it's attributes to change by passing
in a hashref of options:

  my $new = $color->derive({ attr => $newvalue });

The returned color will be identical to the cloned one, save the attributes
specified.

=head2 equal_to

Compares this color to the provided one.  Returns 1 if true, else 0;

=head2 not_equal_to

The opposite of equal_to.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
