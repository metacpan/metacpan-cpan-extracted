use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::SpellingCommonMistakesTests;
BEGIN {
  $Dist::Zilla::Plugin::SpellingCommonMistakesTests::VERSION = '1.001000';
}
BEGIN {
  $Dist::Zilla::Plugin::SpellingCommonMistakesTests::AUTHORITY = 'cpan:LESPEA';
}

#ABSTRACT:  Release tests for common POD spelling mistakes



use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';


__PACKAGE__->meta->make_immutable;
no Moose;

#  Happy ending
1;


## no critic (Documentation::RequirePodAtEnd)



=pod

=head1 NAME

Dist::Zilla::Plugin::SpellingCommonMistakesTests - Release tests for common POD spelling mistakes

=head1 VERSION

version 1.001000

=head1 SYNOPSIS

In your dist.ini file:

    [SpellingCommonMistakesTests]

=head1 DESCRIPTION

This is an extension of Dist::Zilla::Plugin::InlineFiles, providing the following file:

    xt/release/common_spelling.t - a standard Pod::Spell::CommonMistakes test

=encoding utf8

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Spell::CommonMistakes|Pod::Spell::CommonMistakes>

=item *

L<Test::Pod::Spelling::CommonMistakes|Test::Pod::Spelling::CommonMistakes>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::SpellingCommonMistakesTests

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-SpellingCommonMistakesTests>

=item *

RT: CPAN's Bug Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-SpellingCommonMistakesTests>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-SpellingCommonMistakesTests>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-SpellingCommonMistakesTests>

=item *

CPAN Forum

L<http://cpanforum.com/dist/Dist-Zilla-Plugin-SpellingCommonMistakesTests>

=item *

CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Dist-Zilla-Plugin-SpellingCommonMistakesTests>

=item *

CPAN Testers Results

L<http://cpantesters.org/distro/D/Dist-Zilla-Plugin-SpellingCommonMistakesTests.html>

=item *

CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-SpellingCommonMistakesTests>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-spellingcommonmistakestests at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-SpellingCommonMistakesTests>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/lespea/dist-zilla-plugin-spellingcommonmistakestests>

  git clone git://github.com/lespea/dist-zilla-plugin-spellingcommonmistakestests.git

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__DATA__
___[ xt/release/common_spelling.t ]___
#!/usr/bin/perl
use strict; use warnings;

use Test::More;

eval "use Test::Pod::Spelling::CommonMistakes";
if ( $@ ) {
    plan skip_all => 'Test::Pod::Spelling::CommonMistakes required for testing POD';
} else {
    all_pod_files_ok();
}
