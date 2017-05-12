package Imager::Filter::FishEye;
use strict;
use warnings;
use 5.008001;

BEGIN {
    our $VERSION = "0.04";
    require XSLoader;
    XSLoader::load( 'Imager::Filter::FishEye', $VERSION );
}

my %defaults = ( d => 40, r => -1 );

Imager->register_filter(
    type     => 'fisheye',
    callsub  => sub { my %hsh = @_; __fisheye( $hsh{image}, $hsh{r}, $hsh{d} ) },
    defaults => \%defaults,
    callseq  => ['image']
);

1;
__END__

=encoding utf8

=head1 NAME

Imager::Filter::FishEye - fisheye filter for Imager

=head1 SYNOPSIS

    use Imager;
    use Imager::Filter::FishEye;
    my $img = Imager->new;
    $img->filter(type => 'fisheye');

=head1 DESCRIPTION

Imager::Filter::FishEye is fisheye filter for Imager.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Imager>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
