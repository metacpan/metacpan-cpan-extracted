package Dist::Zilla::MintingProfile::SYP;
# ABSTRACT: SYP's Dist::Zilla minting profile

use strict;
use utf8;
use warnings qw(all);

use Moose;
with q(Dist::Zilla::Role::MintingProfile::ShareDir);

our $VERSION = '0.009'; # VERSION

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::SYP - SYP's Dist::Zilla minting profile

=head1 VERSION

version 0.009

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
