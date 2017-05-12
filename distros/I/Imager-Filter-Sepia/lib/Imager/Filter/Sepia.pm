package Imager::Filter::Sepia;

use warnings;
use strict;
use Imager 0.54;
use vars qw(@ISA $VERSION);

BEGIN {
    $VERSION = "0.02";
    eval {
        require XSLoader;
        XSLoader::load('Imager::Filter::Sepia', $VERSION);
        1;
    } or do {
        require DynaLoader;
        push @ISA, 'DynaLoader';
        bootstrap Imager::Filter::Sepia $VERSION;
    };
}

my %defaults = (tone => Imager::Color->new(rgb => [ 0, 0, 0 ] ));

Imager->register_filter(type     => 'sepia',
                        callsub  => sub { my %hsh = @_; sepia($hsh{image}, $hsh{tone}) },
                        defaults => \%defaults,
                        callseq  => [ 'image' ] );


1;
__END__

=head1 NAME

Imager::Filter::Sepia - filter that convert to sepia tone.

=head1 SYNOPSIS

    use Imager;
    use Imager::Filter::Sepia;

    $img->filter(type => 'sepia');
    # or if you set color tone
    $img->filter(type => 'sepia', tone => Imager::Color->new('#FF0000'));

=head1 DESCRIPTION

This is a sepia tone filter can specify color tone of Imager.

Valid filter parameters are:

=over

=item *

tone - L<Imager::Color> instance

=back

=head1 METHODS

=over

=item sepia()

=back

=head1 SEE ALSO

L<Imager>, L<Imager::Color>, L<Imager::API>, L<Imager::APIRef>, L<http://imager.perl.org/>

=head1 AUTHOR

Yoshiki KURIHARA  C<< <kurihara __at__ cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Yoshiki KURIHARA C<< <kurihara __at__ cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
