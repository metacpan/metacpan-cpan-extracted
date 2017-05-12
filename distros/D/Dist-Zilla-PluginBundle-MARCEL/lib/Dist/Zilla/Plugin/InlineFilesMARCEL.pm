use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::InlineFilesMARCEL;
$Dist::Zilla::Plugin::InlineFilesMARCEL::VERSION = '1.161760';
# ABSTRACT: Write static files that I always use
use Moose;
use Test::Synopsis;
extends 'Dist::Zilla::Plugin::InlineFiles';

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=encoding UTF-8

=for test_synopsis 1;
__END__

=for stopwords Quelin Mengu Mengué

=head1 NAME

Dist::Zilla::Plugin::InlineFilesMARCEL - Write static files that I always use

=head1 VERSION

version 1.161760

=head1 SYNOPSIS

In C<dist.ini>:

    [InlineFilesMARCEL]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  t/perlcriticrc
  MANIFEST.SKIP

They contain the settings which I always use in my distributions. This plugin
is automatically included in the C<@MARCEL> plugin bundle.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-MARCEL>.

=head1 AVAILABILITY

The project homepage is L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-MARCEL/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::MARCEL/>.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Jerome Quelin <jquelin@cpan.org>

=item *

Olivier Mengue <dolmen@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Olivier Mengué.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ t/perlcriticrc ]___
# no strict 'refs'
[TestingAndDebugging::ProhibitNoStrict]
allow = refs

[-BuiltinFunctions::ProhibitStringyEval]
[-ControlStructures::ProhibitMutatingListFunctions]
[-Subroutines::ProhibitExplicitReturnUndef]
[-Subroutines::ProhibitSubroutinePrototypes]
[-Variables::ProhibitConditionalDeclarations]

# for mkdir $dir, 0777
[-ValuesAndExpressions::ProhibitLeadingZeros]

___[ MANIFEST.SKIP ]___
# Version control files and dirs.
\\bRCS\b
\\bCVS\b
\\.svn
\\.git
,v$

# Makemaker/Build.PL generated files and dirs.
MYMETA.yml
MYMETA.json
MANIFEST.old
^Makefile$
^Build$
^blib
^pm_to_blib$
^_build
^MakeMaker-\d
embedded
cover_db
smoke.html
smoke.yaml
smoketee.txt
sqlnet.log
BUILD.SKIP
COVER.SKIP
CPAN.SKIP
t/000_standard__*
Debian_CPANTS.txt
nytprof.out

# Temp, old, emacs, vim, backup files.
~$
\\.old$
\\.swp$
\\.tar$
\\.tar\.gz$
^#.*#$
^\.#
.shipit

# Local files, not to be included
^scratch$
^core$
^var$
