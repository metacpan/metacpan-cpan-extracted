#
# This file is part of Dist-Zilla-Plugin-ApocalypseTests
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Dist::Zilla::Plugin::ApocalypseTests;
# git description: release-1.001-2-g2b50bf3
$Dist::Zilla::Plugin::ApocalypseTests::VERSION = '1.002';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Creates the Test::Apocalypse testfile for Dist::Zilla

use Moose 1.03;

extends 'Dist::Zilla::Plugin::InlineFiles' => { -version => '2.101170' };
with 'Dist::Zilla::Role::FileMunger' => { -version => '2.101170' };

# TODO how do I fix this in pod-weaver? I think it's the __DATA__ section that screws it up?
# Perl::Critic found these violations in "blib/lib/Dist/Zilla/Plugin/ApocalypseTests.pm":
# [Documentation::RequirePodAtEnd] POD before __END__ at line 69, column 1.  (Severity: 1)
## no critic ( RequirePodAtEnd )

#pod =attr allow
#pod
#pod This option will be passed directly to L<Test::Apocalypse> to control which sub-tests you want to run.
#pod
#pod The default is nothing.
#pod
#pod =cut

has allow => (
	is => 'ro',
	isa => 'Str',
	predicate => '_has_allow',
);

#pod =attr deny
#pod
#pod This option will be passed directly to L<Test::Apocalypse> to control which sub-tests you want to run.
#pod
#pod The default is nothing.
#pod
#pod =cut

has deny => (
	is => 'ro',
	isa => 'Str',
	predicate => '_has_deny',
);

sub munge_file {
	my ($self, $file) = @_;

	return unless $file->name eq 't/apocalypse.t';

	# replace strings in the file
	my $content = $file->content;
	my( $allow, $deny );
	if ( $self->_has_allow ) {
		$allow = "allow => '" . $self->allow . "',\n";
	} else {
		$allow = '';
	}
	$content =~ s/ALLOW/$allow/;

	if ( $self->_has_deny ) {
		$deny = "deny => '" . $self->deny . "',\n";
	} else {
		$deny = '';
	}
	$content =~ s/DENY/$deny/;

	$file->content( $content );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

#pod =pod
#pod
#pod =for Pod::Coverage munge_file
#pod
#pod =for stopwords dist
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
#pod the following files:
#pod
#pod =over 4
#pod
#pod =item * t/apocalypse.t - Runs the dist through Test::Apocalypse
#pod
#pod For more information on what the test does, please look at L<Test::Apocalypse>.
#pod
#pod 	# In your dist.ini:
#pod 	[ApocalypseTests]
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod Dist::Zilla
#pod Test::Apocalypse
#pod
#pod =cut

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan dist

=for Pod::Coverage munge_file

=head1 NAME

Dist::Zilla::Plugin::ApocalypseTests - Creates the Test::Apocalypse testfile for Dist::Zilla

=head1 VERSION

  This document describes v1.002 of Dist::Zilla::Plugin::ApocalypseTests - released October 27, 2014 as part of Dist-Zilla-Plugin-ApocalypseTests.

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following files:

=over 4

=item * t/apocalypse.t - Runs the dist through Test::Apocalypse

For more information on what the test does, please look at L<Test::Apocalypse>.

	# In your dist.ini:
	[ApocalypseTests]

=back

=head1 ATTRIBUTES

=head2 allow

This option will be passed directly to L<Test::Apocalypse> to control which sub-tests you want to run.

The default is nothing.

=head2 deny

This option will be passed directly to L<Test::Apocalypse> to control which sub-tests you want to run.

The default is nothing.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla|Dist::Zilla>

=item *

L<Test::Apocalypse|Test::Apocalypse>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::ApocalypseTests

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Plugin-ApocalypseTests>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-ApocalypseTests>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-ApocalypseTests>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-ApocalypseTests>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-ApocalypseTests>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Dist-Zilla-Plugin-ApocalypseTests>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/Dist-Zilla-Plugin-ApocalypseTests>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-ApocalypseTests>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-ApocalypseTests>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::ApocalypseTests>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-apocalypsetests at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-ApocalypseTests>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-dist-zilla-plugin-apocalypsetests>

  git clone git://github.com/apocalypse/perl-dist-zilla-plugin-apocalypsetests.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__DATA__
___[ t/apocalypse.t ]___
#!perl
use strict; use warnings;

use Test::More;
eval "use Test::Apocalypse 1.000";
if ( $@ ) {
	plan skip_all => 'Test::Apocalypse required for validating the distribution';
} else {
	is_apocalypse_here( {
		ALLOWDENY
	} );
}
