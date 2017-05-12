use 5.10.0;
use strict;
use warnings;

package Dist::Zilla::Plugin::DistIller::MetaGeneratedBy;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1408';

use Moose;
use namespace::autoclean;
with 'Dist::Zilla::Role::MetaProvider';

use Dist::Iller;

sub metadata {
    return {
        generated_by => sprintf 'Dist::Iller version %s, Dist::Zilla version %s',
                                 Dist::Iller->VERSION,
                                 shift->zilla->VERSION,
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DistIller::MetaGeneratedBy

=head1 VERSION

Version 0.1408, released 2016-03-12.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
