package Dist::Zilla::MintingProfile::GEEKRUTH;
use Modern::Perl;
our $VERSION   = '2.0000';           # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH';    # AUTHORITY

# ABSTRACT: GEEKRUTH's Dist::Zilla minting profiles

use Moose;
with q(Dist::Zilla::Role::MintingProfile::ShareDir);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::GEEKRUTH - GEEKRUTH's Dist::Zilla minting profiles

=head1 VERSION

version 2.0000

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
