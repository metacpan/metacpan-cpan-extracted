package Dist::Zilla::MintingProfile::Project::OSM;
BEGIN {
  $Dist::Zilla::MintingProfile::Project::OSM::AUTHORITY = 'cpan:DBR';
}
{
  $Dist::Zilla::MintingProfile::Project::OSM::VERSION = '0.2.0';
}

# ABSTRACT: A minting profile for Modules written for Project OSM

use Moose;
use namespace::autoclean;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';
 
__PACKAGE__->meta->make_immutable;


1;

__END__
=pod

=head1 NAME

Dist::Zilla::MintingProfile::Project::OSM - A minting profile for Modules written for Project OSM

=head1 VERSION

version 0.2.0

=begin wikidoc

= SYNOPSIS

    dzil new -P Project::OSM -p Handler  New::ClassName

or

    dzil new -P Project::OSM -p Model New::CommandName

This is specific minting profile for a secret project.

It comes in several flavors: one for Handlers, one for Models, etc..

= MORE

There is, on purpose, no `default` profile, so that you *have to* choose
`Handler`, `Model` or the like

= BUGS AND LIMITATIONS

From the outside this may seem obscure at best,
and one could ask "Why the hell have it on CPAN?".

For this reason, this MintingProfile hides behind
the `Project::` namespace-prefix to make clear,
that this module is an Author's "personal" module
to be includable for the team members within the
Perl toolchain(TM).

=end wikidoc

=head1 AUTHOR

DBR <dbr@cpan.org>, AHERNIT <tech@tool.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by DBR, AHERNIT.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

