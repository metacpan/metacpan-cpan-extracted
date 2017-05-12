use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::MintingProfile::Author::KENTNL;

# ABSTRACT: KENTNL's Minting Profile

our $VERSION = '2.025021';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with );
use namespace::autoclean;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';
















__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Author::KENTNL - KENTNL's Minting Profile

=head1 VERSION

version 2.025021

=head1 SYNOPSIS

    dzil new -P Author::KENTNL Some::Dist::Name

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::MintingProfile::Author::KENTNL",
    "inherits":"Moose::Object",
    "does":"Dist::Zilla::Role::MintingProfile::ShareDir",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
