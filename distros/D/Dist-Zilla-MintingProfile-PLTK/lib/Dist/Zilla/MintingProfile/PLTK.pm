package Dist::Zilla::MintingProfile::PLTK;
BEGIN {
  $Dist::Zilla::MintingProfile::PLTK::AUTHORITY = 'cpan:DBR';
}
{
  $Dist::Zilla::MintingProfile::PLTK::VERSION = '0.2.0';
}

# ABSTRACT: A minting profile for Modules written with MooseX::Declare

use Moose;
use namespace::autoclean;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';
 
__PACKAGE__->meta->make_immutable;


1;

__END__
=pod

=encoding utf8

=head1 NAME

Dist::Zilla::MintingProfile::PLTK - A minting profile for Modules written with MooseX::Declare

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

     dzil new -P PLTK -p Class   New::ClassName

or

     dzil new -P PLTK -p Command New::CommandName

This is specific minting profile for the PLTK project.

It comes in two flavors: one for Classes and one for Commands.

=head1 MORE

There is, on purpose, no `default` profile, so that you B<have to> choose
`Class` or `Command`

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Daniel B <dbr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel B.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

