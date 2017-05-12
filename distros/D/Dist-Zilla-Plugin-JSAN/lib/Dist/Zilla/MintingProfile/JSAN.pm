package Dist::Zilla::MintingProfile::JSAN;
BEGIN {
  $Dist::Zilla::MintingProfile::JSAN::VERSION = '0.06';
}

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

# ABSTRACT: a profile provider, pointing to the default JSAN distribution profile


1;

__END__
=pod

=head1 NAME

Dist::Zilla::MintingProfile::JSAN - a profile provider, pointing to the default JSAN distribution profile

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Default minting profile provider. The profile is a directory, containing arbitrary
files used during creation of new distribution. Among other things notably it should
contain the 'profile.ini' file, listing the plugins used for minter initialization.

This provider looks first in the ~/.dzil/profiles/$profile_name directory, if not found
it looks among the default profiles, shipped with Dist::Zilla.

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

