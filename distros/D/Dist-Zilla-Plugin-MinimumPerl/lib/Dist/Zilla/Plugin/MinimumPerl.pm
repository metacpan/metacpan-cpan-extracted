#
# This file is part of Dist-Zilla-Plugin-MinimumPerl
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Dist::Zilla::Plugin::MinimumPerl;
# git description: release-1.005-7-g9a97c25
$Dist::Zilla::Plugin::MinimumPerl::VERSION = '1.006';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Detects the minimum version of Perl required for your dist

use Moose 1.03;
use Perl::MinimumVersion 1.26;
use MooseX::Types::Perl 0.101340 qw( LaxVersionStr );

with(
	'Dist::Zilla::Role::PrereqSource' => { -version => '5.006' }, # for the updated encoding system in dzil, RJBS++
	'Dist::Zilla::Role::FileFinderUser' => {
		finder_arg_names => [ 'runtime_finder' ],
		method => 'found_runtime',
		default_finders => [ ':InstallModules', ':ExecFiles' ]
	},
	'Dist::Zilla::Role::FileFinderUser' => {
		finder_arg_names => [ 'test_finder' ],
		method => 'found_tests',
		default_finders => [ ':TestFiles' ]
	},
	'Dist::Zilla::Role::FileFinderUser' => {
		-version => '4.200006',	# for :IncModules
		finder_arg_names => [ 'configure_finder' ],
		method => 'found_configure',
		default_finders => [ ':IncModules' ]
	},
);

#pod =attr perl
#pod
#pod Specify a version of perl required for the dist. Please specify it in a format that Build.PL/Makefile.PL understands!
#pod If this is specified, this module will not attempt to automatically detect the minimum version of Perl.
#pod
#pod The default is: undefined ( automatically detect it )
#pod
#pod Example: 5.008008
#pod
#pod =cut

{
	use Moose::Util::TypeConstraints 1.01;

	has perl => (
		is => 'ro',
		isa => subtype( 'Str'
			=> where { LaxVersionStr->check( $_ ) }
			=> message { "Perl must be in a valid version format - see version.pm" }
		),
		predicate => '_has_perl',
	);

	no Moose::Util::TypeConstraints;
}

has _scanned_perl => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {} },
);

sub register_prereqs {
	my ($self) = @_;

	# TODO should we check to see if it was already set in the metadata?

	# Okay, did the user set a perl version explicitly?
	if ( $self->_has_perl ) {
		foreach my $p ( qw( runtime configure test ) ) {
			$self->zilla->register_prereqs(
				{ phase => $p },
				'perl' => $self->perl,
			);
		}
	} else {
		# Go through our 3 phases
		$self->_scan_file( 'runtime', $_ ) for @{ $self->found_runtime };
		$self->_finalize( 'runtime' );
		$self->_scan_file( 'configure', $_ ) for @{ $self->found_configure };
		$self->_finalize( 'configure' );
		$self->_scan_file( 'test', $_ ) for @{ $self->found_tests };
		$self->_finalize( 'test' );
	}
}

sub _scan_file {
	my( $self, $phase, $file ) = @_;

	# We don't parse files marked with the 'bytes' encoding as they're special - see RT#96071
	return if $file->is_bytes;

	# TODO skip "bad" files and not die, just warn?
	my $pmv = Perl::MinimumVersion->new( \$file->content );
	if ( ! defined $pmv ) {
		$self->log_fatal( "Unable to parse '" . $file->name . "'" );
	}
	my $ver = $pmv->minimum_version;
	if ( ! defined $ver ) {
		$self->log_fatal( "Unable to extract MinimumPerl from '" . $file->name . "'" );
	}

	# cache it, letting _finalize take care of it
	if ( ! exists $self->_scanned_perl->{$phase} || $self->_scanned_perl->{$phase}->[0] < $ver ) {
		$self->_scanned_perl->{$phase} = [ $ver, $file ];
	}
}

sub _finalize {
	my( $self, $phase ) = @_;

	my $v;

	# determine the version we will use
	if ( ! exists $self->_scanned_perl->{$phase} ) {
		# We don't complain for test and inc!
		$self->log_fatal( 'Found no perl files, check your dist?' ) if $phase eq 'runtime';

		# ohwell, we just copy the runtime perl
		$self->log_debug( "Determined that the MinimumPerl required for '$phase' is v" . $self->_scanned_perl->{'runtime'}->[0] . " via defaulting to runtime" );
		$v = $self->_scanned_perl->{'runtime'}->[0];
	} else {
		$self->log_debug( "Determined that the MinimumPerl required for '$phase' is v" . $self->_scanned_perl->{$phase}->[0] . " via " .  $self->_scanned_perl->{$phase}->[1]->name );
		$v = $self->_scanned_perl->{$phase}->[0];
	}

	$self->zilla->register_prereqs(
		{ phase => $phase },
		'perl' => $v,
	);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan dist prereqs

=for Pod::Coverage register_prereqs

=head1 NAME

Dist::Zilla::Plugin::MinimumPerl - Detects the minimum version of Perl required for your dist

=head1 VERSION

  This document describes v1.006 of Dist::Zilla::Plugin::MinimumPerl - released October 31, 2014 as part of Dist-Zilla-Plugin-MinimumPerl.

=head1 DESCRIPTION

This plugin uses L<Perl::MinimumVersion> to automatically find the minimum version of Perl required
for your dist and adds it to the prereqs.

	# In your dist.ini:
	[MinimumPerl]

=head1 ATTRIBUTES

=head2 perl

Specify a version of perl required for the dist. Please specify it in a format that Build.PL/Makefile.PL understands!
If this is specified, this module will not attempt to automatically detect the minimum version of Perl.

The default is: undefined ( automatically detect it )

Example: 5.008008

=head1 CONFIGURATION OPTIONS

The plugin uses L<FileFinders|Dist::Zilla::Role::FileFinder> for finding files
to scan.  The predefined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> and
L<[FileFinder::Filter]|Dist::Zilla::Plugin::FileFinder::Filter> plugins.

Additionally, all files whose encoding has been specified as C<bytes> are
omitted from consideration.  (See L<[Encoding]|Dist::Zilla::Plugin::Encoding>
for more information.)

Each prerequisite phase is configured separately:

=head2 C<runtime_finder>

Finds files to scan for runtime prerequisites.  The default value is
C<:InstallModules> and C<:ExecFiles> (see also
L<Dist::Zilla::Plugin::ExecDir>.

=head2 C<test_finder>

Finds files to scan for test prerequisites. The default value is C<:TestFiles>.

=head2 C<configure_finder>

Finds files to scan for configure prerequisites. The default value is C<:IncModules>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla|Dist::Zilla>

=item *

L<Dist::Zilla::Plugin::MinimumPerlFast|Dist::Zilla::Plugin::MinimumPerlFast>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::MinimumPerl

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Plugin-MinimumPerl>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-MinimumPerl>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-MinimumPerl>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-MinimumPerl>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-MinimumPerl>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Dist-Zilla-Plugin-MinimumPerl>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/Dist-Zilla-Plugin-MinimumPerl>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-MinimumPerl>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-MinimumPerl>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::MinimumPerl>

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

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-minimumperl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-MinimumPerl>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-dist-zilla-plugin-minimumperl>

  git clone git://github.com/apocalypse/perl-dist-zilla-plugin-minimumperl.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head2 CONTRIBUTORS

=for stopwords Karen Etheridge Nigel Gregoire Olivier Mengué Pedro Melo

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Nigel Gregoire <nigelg@airg.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Pedro Melo <melo@simplicidade.org>

=back

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
