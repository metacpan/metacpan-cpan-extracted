package Dist::Zilla::MintingProfile::Author::BBYRD;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.06'; # VERSION
# ABSTRACT: DZIL MintingProfile for BBYRD

use sanity;
use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

__PACKAGE__->meta->make_immutable;
42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Author::BBYRD - DZIL MintingProfile for BBYRD

=head1 SYNOPSIS

    dzil new -P Author::BBYRD [distro_name]

=head1 DESCRIPTION

This is a personalized Author minting profile for DZIL.

=head1 NAMING SCHEME

I'm a strong believer in structured order in the chaos that is the CPAN
namespace.  There's enough cruft in CPAN, with all of the forked modules,
legacy stuff that should have been removed 10 years ago, and confusion over
which modules are available vs. which ones actually work.  (Which all stem
from the same base problem, so I'm almost repeating myself...)

Like I said, I hate writing these personalized modules on CPAN.  I even bantered
around the idea of using L<MetaCPAN's author JSON input|https://github.com/SineSwiper/Dist-Zilla-PluginBundle-BeLike-You/blob/master/BeLike-You.pod>
to store the plugin data.  However, keeping the Author plugins separated from the
real PluginBundles is a step in the right direction.  See
L<KENTNL's comments on the Author namespace|Dist::Zilla::PluginBundle::Author::KENTNL/NAMING-SCHEME>
for more information.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-PluginBundle-Author-BBYRD>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::Author::BBYRD/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
