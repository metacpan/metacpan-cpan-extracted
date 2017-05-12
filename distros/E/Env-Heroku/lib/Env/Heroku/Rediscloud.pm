use strict;
package Env::Heroku::Rediscloud;
our $AUTHORITY = 'cpan:PNU';
# ABSTRACT: env for rediscloud

use warnings;
use URI;

our $VERSION = '0.003'; # VERSION

sub import {
    my ($self) = @_;

    my $redisurl = $ENV{REDISCLOUD_URL} || 'redis://localhost:6379/';
    if ( $redisurl and $redisurl =~ s/^redis:// ) {
        my $url = URI->new( $redisurl, 'http' );
        $ENV{REDISHOST} = $url->host;
        $ENV{REDISPORT} = $url->port;
        (undef,$ENV{REDISPASSWORD}) = split ':', $url->userinfo
            if $url->userinfo;
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Env::Heroku::Rediscloud - env for rediscloud

=head1 VERSION

version 0.003

=head1 AUTHOR

Panu Ervamaa <pnu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Panu Ervamaa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
