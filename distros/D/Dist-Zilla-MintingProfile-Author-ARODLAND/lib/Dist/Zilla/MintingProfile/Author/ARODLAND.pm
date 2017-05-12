package Dist::Zilla::MintingProfile::Author::ARODLAND;
# ABSTRACT: Make new modules like ARODLAND does
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY
our $VERSION = '0.02'; # VERSION

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Dist::Zilla::MintingProfile::Author::ARODLAND - Make new modules like ARODLAND does

=head1 VERSION

version 0.02

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
