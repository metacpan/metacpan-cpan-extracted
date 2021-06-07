package HashData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-01'; # DATE
our $DIST = 'HashData'; # DIST
our $VERSION = '0.1.1'; # VERSION

1;
# ABSTRACT: Specification for HashData::*, modules that contains hash data

__END__

=pod

=encoding UTF-8

=head1 NAME

HashData - Specification for HashData::*, modules that contains hash data

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.1.1 of HashData (from Perl distribution HashData), released on 2021-06-01.

=head1 SYNOPSIS

Use one of the C<Hash::*> modules.

=head1 DESCRIPTION

B<NOTE: EARLY SPECIFICATION; THINGS WILL STILL CHANGE A LOT>.

C<HashData::*> modules are modules that contain hash data. The hash can be
stored in an actual Perl hash in the source code, or as lines in the DATA
section of the source code, or in other places. The hash data can be accessed
via a standard interface (see L<HashDataRole::Spec::Basic>). Some examples of
hash data are:

=over

=item * A mapping between PAUSE IDs and CPAN author names (L<HashData::CPAN::AuthorName::ByPAUSEID>)

=item * A mapping of ISO 2-letter country codes with their English names (L<HashData::Country::EN::EnglishName::ByISO2>)

=item * A mapping of answer word and their clues from New York Times 2000 cross-word puzzles, handy for generating cross-word puzzle games (L<HashData::Word::EN::NYT::2000::Clue::ByWord>)

=item * FOLDOC dictionary, entries with their definition (L<HashData::Dict::EN::FOLDOC>)

Also eligible for cross-word or word-guessing games.

=item * Another dictionary (L<HashData::Dict::ID::KBBI>)

Also eligible for cross-word or word-guessing games.

=back

Why put data in a Perl module, as a Perl distribution? To leverage the Perl/CPAN
toolchain and infrastructure: 1) ease of installation, update, and
uninstallation; 2) allowing dependency expression and version comparison; 3)
ease of packaging further as OS packages, e.g. Debian packages (converted from
Perl distribution); 4) testing by CPAN Testers.

To get started, see L<HashDataRole::Spec::Basic> and one of existing
C<HashData::*> modules.

=head1 NAMESPACE ORGANIZATION

C<HashData> (this module) is the specification.

C<HashDataRole::*> the roles.

C<HashDataRoles-*> is name for distribution that contains several roles.

C<HashDataBase::*> the base classes. C<HashDataBases::*> are main module names
for distributions that bundle multiple base classes.

All the modules under C<HashData::*> will be modules with actual data. They
should be named using this rule:

 HashData::<CATEGORY>::<VALUE_ENTITY>::By<KEY_ENTITY>

I<CATEGORY> can be multiple levels. I<VALUE_ENTITY> and I<KEY_ENTITY> should be
in singular form. Examples:

 HashData::CPAN::AuthorName::ByPAUSEID
 HashData::Country::EN::EnglishName::ByISO2
 HashData::Country::EN::EnglishName::ByISO3
 HashData::Country::EN::IndonesianName::ByISO2
 HashData::Country::EN::IndonesianName::ByISO3
 HashData::Country::EN::ISO2::ByIndonesianName (reverse mapping of country Indonesian names to ISO 2-letter codes)

An exception is L<HashData::Dict::*> where it is assumed that keys will be
entries (usually words) and values will be the entries' definitions. Examples:

 HashData::Dict::EN::OxfordLearner (no need for: HashData::Dict::EN::OxfordLearner::Definition::ByWord)
 HashData::Dict::ID::KBBI
 HashData::Dict::EN::FOLDOC

C<HashDataBundle-*> is name for distribution that contains several C<HashData>
modules.

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Related projects: L<ArrayData>, L<TableData>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
