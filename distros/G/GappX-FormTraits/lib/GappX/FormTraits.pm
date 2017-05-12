package GappX::FormTraits;
{
  $GappX::FormTraits::VERSION = '0.300';
}

use GappX::FormTraits::Meta::Widget::Custom::Trait::CityEntry;
use GappX::FormTraits::Meta::Widget::Custom::Trait::EmailEntry;
use GappX::FormTraits::Meta::Widget::Custom::Trait::StateEntry;
use GappX::FormTraits::Meta::Widget::Custom::Trait::StreetEntry;
use GappX::FormTraits::Meta::Widget::Custom::Trait::ZipCodeEntry;

1;

__END__

=pod

=head1 NAME

GappX::FormTraits - Traits for form fields

=head1 SYNOPSIS

    use Gapp;
    use GappX::FormTraits;

    $e = GappX::Entry->new( traits => [qw( CityEntry )], field => ... );

    $e = GappX::Entry->new( traits => [qw( EmailEntry )], field => ...  );

    $e = GappX::Entry->new( traits => [qw( StateEntry )], field => ... );

    $e = GappX::Entry->new( traits => [qw( StreetEntry )], field => ...  );

    $e = GappX::Entry->new( traits => [qw( ZipCodeEntry )], field => ...  );

=head1 DESCRIPTION

Provides traits to use with your form fields.

=head2 PROVIDED TRAITS

=over 4

=item B<CityEntry>

Sets C<width-chars> to 25.

=item B<EmailEntry>

Sets C<width-chars> to 60.

=item B<StateEntry>

Sets C<width-chars> to 2.

=item B<StreetEntry>

Sets C<width-chars> to 35.

=item B<ZipCodeEntry>

Sets C<width-chars> to 5.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut

