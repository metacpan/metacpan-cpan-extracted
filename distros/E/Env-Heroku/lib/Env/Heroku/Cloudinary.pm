use strict;
package Env::Heroku::Cloudinary;
our $AUTHORITY = 'cpan:PNU';
# ABSTRACT: env for cloudinary

use warnings;
use URI;

our $VERSION = '0.003'; # VERSION

sub import {
    my ($self) = @_;

    my $cloudinaryurl = $ENV{CLOUDINARY_URL};
    if ( $cloudinaryurl and $cloudinaryurl =~ s/^cloudinary:// ) {
        my $url = URI->new( $cloudinaryurl, 'http' );
        $ENV{CLOUDINARY_CLOUD} = $url->host;
        ($ENV{CLOUDINARY_API_KEY},$ENV{CLOUDINARY_API_SECRET}) = split ':', $url->userinfo
            if $url->userinfo;
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Env::Heroku::Cloudinary - env for cloudinary

=head1 VERSION

version 0.003

=head1 AUTHOR

Panu Ervamaa <pnu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Panu Ervamaa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
