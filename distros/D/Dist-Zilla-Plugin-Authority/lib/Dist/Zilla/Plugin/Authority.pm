#
# This file is part of Dist-Zilla-Plugin-Authority
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Dist::Zilla::Plugin::Authority;
# git description: release-1.008-1-g9f0cbc2
$Dist::Zilla::Plugin::Authority::VERSION = '1.009';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Add the $AUTHORITY variable and metadata to your distribution

use Moose 1.03;
use PPI 1.206;
use File::Spec;
use File::HomeDir;
use Dist::Zilla::Util;

with(
	'Dist::Zilla::Role::MetaProvider' => { -version => '4.102345' },
	'Dist::Zilla::Role::FileMunger' => { -version => '4.102345' },
	'Dist::Zilla::Role::FileFinderUser' => {
		-version => '4.102345',
		default_finders => [ ':InstallModules', ':ExecFiles' ],
	},
    'Dist::Zilla::Role::PPI' => { -version => '4.300001' },
);

#pod =attr authority
#pod
#pod The authority you want to use. It should be something like C<cpan:APOCAL>.
#pod
#pod Defaults to the username set in the %PAUSE stash in the global config.ini or dist.ini ( Dist::Zilla v4 addition! )
#pod
#pod If you prefer to not put it in config/dist.ini you can put it in "~/.pause" just like Dist::Zilla did before v4.
#pod
#pod =cut

{
	use Moose::Util::TypeConstraints 1.01;

	has authority => (
		is => 'ro',
		isa => subtype( 'Str'
			=> where { $_ =~ /^\w+\:\S+$/ }
			=> message { "Authority must be in the form of 'cpan:PAUSEID'" }
		),
		lazy => 1,
		default => sub {
			my $self = shift;
			my $stash = $self->zilla->stash_named( '%PAUSE' );
			if ( defined $stash ) {
				$self->log_debug( [ 'using PAUSE id "%s" for AUTHORITY from Dist::Zilla config', uc( $stash->username ) ] );
				return 'cpan:' . uc( $stash->username );
			} else {
				# Argh, try the .pause file?
				# Code ripped off from Dist::Zilla::Plugin::UploadToCPAN v4.200001 - thanks RJBS!
				my $file = File::Spec->catfile( File::HomeDir->my_home, '.pause' );
				if ( -f $file ) {
					open my $fh, '<', $file or $self->log_fatal( "Unable to open $file - $!" );
					while (<$fh>) {
						next if /^\s*(?:#.*)?$/;
						my ( $k, $v ) = /^\s*(\w+)\s+(.+)$/;
						if ( $k =~ /^user$/i ) {
							$self->log_debug( [ 'using PAUSE id "%s" for AUTHORITY from ~/.pause', uc( $v ) ] );
							return 'cpan:' . uc( $v );
						}
					}
					close $fh or $self->log_fatal( "Unable to close $file - $!" );
					$self->log_fatal( 'PAUSE user not found in ~/.pause' );
				} else {
					$self->log_fatal( 'PAUSE credentials not found in "config.ini" or "dist.ini" or "~/.pause"! Please set it or specify an authority for this plugin.' );
				}
			}
		},
	);

	no Moose::Util::TypeConstraints;
}

#pod =attr do_metadata
#pod
#pod A boolean value to control if the authority should be added to the metadata.
#pod
#pod Defaults to true.
#pod
#pod =cut

has do_metadata => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

#pod =attr do_munging
#pod
#pod A boolean value to control if the $AUTHORITY variable should be added to the modules.
#pod
#pod Defaults to true.
#pod
#pod =cut

has do_munging => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

#pod =attr locate_comment
#pod
#pod A boolean value to control if the $AUTHORITY variable should be added where a
#pod C<# AUTHORITY> comment is found.  If this is set then an appropriate comment
#pod is found, and C<our $AUTHORITY = 'cpan:PAUSEID';> is inserted preceding the
#pod comment on the same line.
#pod
#pod This basically implements what L<OurPkgVersion|Dist::Zilla::Plugin::OurPkgVersion>
#pod does for L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>.
#pod
#pod Defaults to false.
#pod
#pod NOTE: If you use this method, then we will not use the pkg style of declaration! That way, we keep the line numbering consistent.
#pod
#pod =cut

has locate_comment => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

#pod =attr authority_style
#pod
#pod A value to control the type of the $AUTHORITY declaration. There are two styles: 'pkg' or 'our'. In the past
#pod this module defaulted to the 'pkg' style but due to various issues 'our' is now the default. Here's what both styles
#pod would look like in the resulting code:
#pod
#pod 	# pkg
#pod 	BEGIN {
#pod 		$Dist::Zilla::Plugin::Authority::AUTHORITY = 'cpan:APOCAL';
#pod 	}
#pod
#pod 	# our
#pod 	our $AUTHORITY = 'cpan:APOCAL';
#pod
#pod =cut

{
	use Moose::Util::TypeConstraints 1.01;

	has authority_style => (
		is => 'ro',
		isa => enum( [ qw( pkg our ) ] ),
		default => 'our',
	);

	no Moose::Util::TypeConstraints;
}

# sanity check ourselves...
my $seen_author;

sub metadata {
	my( $self ) = @_;

	return if ! $self->do_metadata;

	if ( ! defined $seen_author ) {
		$seen_author = $self->authority;
	} else {
		if ( $seen_author ne $self->authority ) {
			die "Specifying multiple authorities will not work! We got '$seen_author' and '" . $self->authority . "'";
		}
	}

	$self->log_debug( 'adding AUTHORITY to metadata' );

	return {
		'x_authority'	=> $self->authority,
	};
}

sub munge_files {
	my( $self ) = @_;

	return if ! $self->do_munging;

	if ( ! defined $seen_author ) {
		$seen_author = $self->authority;
	} else {
		if ( $seen_author ne $self->authority ) {
			die "Specifying multiple authorities will not work! We got '$seen_author' and '" . $self->authority . "'";
		}
	}

	$self->_munge_file( $_ ) for @{ $self->found_files };
}

sub _munge_file {
	my( $self, $file ) = @_;

	return $self->_munge_perl($file) if $file->name    =~ /\.(?:pm|pl)$/i;
	return $self->_munge_perl($file) if $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
	return;
}

# create an 'our' style assignment string of Perl code
# ->_template_our_authority({
#       whitespace => 'some white text preceeding the our',
#		authority  => 'the author to assign authority to',
#       comment    => 'original comment string',
# })
sub _template_our_authority {
	my $variable = "AUTHORITY";
	return sprintf qq[%sour \$%s = '%s'; %s\n], $_[1]->{whitespace}, $variable, $_[1]->{authority}, $_[1]->{comment};
}

# create a 'pkg' style assignment string of Perl code
# ->_template_pkg_authority({
#		package => 'the package the variable is to be created in',
#       authority => 'the author to assign authority to',
# })
sub _template_pkg_authority {
	my $variable = sprintf "%s::AUTHORITY", $_[1]->{package};
	return sprintf qq[BEGIN {\n  \$%s = '%s';\n}\n], $variable, $_[1]->{authority};
}

# Generate a PPI element containing our assignment
sub _make_authority {
	my ( $self, $package ) = @_;

	my $code_hunk;
	if ( $self->authority_style eq 'our' ) {
		$code_hunk = $self->_template_our_authority({ whitespace => '', authority => $self->authority, comment => '' });
	} else {
		$code_hunk = $self->_template_pkg_authority({ package => $package, authority => $self->authority });
	}

	my $doc = PPI::Document->new( \$code_hunk );
	my @children = $doc->schildren;
	return $children[0]->clone;
}

# Insert an AUTHORITY assignment inside a <package $package { }> declaration( $block )
sub _inject_block_authority {
	my ( $self, $block, $package ) = @_ ;
	$self->log_debug( [ 'Inserting inside a package NAME BLOCK statement' ] );

	# TODO watch https://github.com/neilbowers/Perl-MinimumVersion/issues/1
	# because Perl::MinimumVersion didn't specify 5.14 we got: http://www.cpantesters.org/cpan/report/ffab485c-5e2a-11e4-846d-e015e1bfc7aa
	# and tons of FAIL on perls < 5.14 :(
	unshift @{ $block->{children} },
		PPI::Token::Whitespace->new("\n"),
		$self->_make_authority( $package ),
		PPI::Token::Whitespace->new("\n");
	return;
}

# Insert an AUTHORITY assignment immediately after the <package $package> declaration ( $stmt )
sub _inject_plain_authority {
	my ( $self, $file, $stmt, $package ) = @_ ;
	$self->log_debug( [ 'Inserting after a plain package declaration' ] );
	Carp::carp( "error inserting AUTHORITY in " . $file->name )
		unless $stmt->insert_after( $self->_make_authority($package) )
		and    $stmt->insert_after( PPI::Token::Whitespace->new("\n") );
}

# Replace the content of $line with an AUTHORITY assignment, preceeded by $ws, succeeded by $comment
sub _replace_authority_comment {
	my ( $self, $file, $line, $ws, $comment ) = @_ ;
	$self->log_debug( [ 'adding $AUTHORITY assignment to line %d in %s', $line->line_number, $file->name ] );
	$line->set_content(
			$self->_template_our_authority({ whitespace => $ws, authority => $self->authority, comment => $comment })
	);
	return;
}

# Uses # AUTHORITY comments to work out where to put declarations
sub _munge_perl_authority_comments {
	my ( $self, $document, $file ) = @_ ;

	my $comments = $document->find('PPI::Token::Comment');

	return unless ref $comments;

	return unless ref $comments eq 'ARRAY';

	my $found_authority = 0;

	foreach my $line ( @$comments ) {
		next unless $line =~ /^(\s*)(\#\s+AUTHORITY\b)$/xms;
		$self->_replace_authority_comment( $file, $line, $1, $2 );
		$found_authority = 1;
	}
    if (  not $found_authority ) {
		$self->log( [ 'skipping %s: consider adding a "# AUTHORITY" comment', $file->name ] );
		return;
	}

	$self->save_ppi_document_to_file( $document, $file );
	return 1;
}

# Places Fully Qualified $AUTHORITY values in packages
sub _munge_perl_packages {
	my ( $self, $document, $file ) = @_ ;

	return unless my $package_stmts = $document->find( 'PPI::Statement::Package' );

	my %seen_pkgs;

	for my $stmt ( @$package_stmts ) {
		my $package = $stmt->namespace;

		# Thanks to rafl ( Florian Ragwitz ) for this
		if ( $seen_pkgs{ $package }++ ) {
			$self->log( [ 'skipping package re-declaration for %s', $package ] );
			next;
		}

		# Thanks to autarch ( Dave Rolsky ) for this
		if ( $stmt->content =~ /package\s*(?:#.*)?\n\s*\Q$package/ ) {
			$self->log( [ 'skipping private package %s', $package ] );
			next;
		}
		$self->log_debug( [ 'adding $AUTHORITY assignment to %s in %s', $package, $file->name ] );

		if( my $block = $stmt->find_first('PPI::Structure::Block') ) {
			$self->_inject_block_authority( $block, $package );
			next;
		}
		$self->_inject_plain_authority( $file, $stmt, $package );
		next;
	}
	$self->save_ppi_document_to_file( $document, $file );
}

sub _munge_perl {
	my( $self, $file ) = @_;

    my $document = $self->ppi_document_for_file($file);

    if ( $self->document_assigns_to_variable( $document, '$AUTHORITY' ) ) {
        $self->log( [ 'skipping %s: assigns to $AUTHORITY', $file->name ] );
        return;
    }

	# Should we use the comment to insert the $AUTHORITY or the pkg declaration?
	if ( $self->locate_comment ) {
		return  $self->_munge_perl_authority_comments($document, $file);
	} else {
		return $self->_munge_perl_packages( $document, $file );
	}
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Dave Fredric Kent Metheringham Nigel Randy Rolsky Stauner cpan
testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto
metadata placeholders metacpan RJBS FLORA dist ini json username yml

=for Pod::Coverage metadata munge_files

=head1 NAME

Dist::Zilla::Plugin::Authority - Add the $AUTHORITY variable and metadata to your distribution

=head1 VERSION

  This document describes v1.009 of Dist::Zilla::Plugin::Authority - released October 27, 2014 as part of Dist-Zilla-Plugin-Authority.

=head1 DESCRIPTION

This plugin adds the authority data to your distribution. It adds the data to your modules and metadata. Normally it
looks for the PAUSE author id in your L<Dist::Zilla> configuration. If you want to override it, please use the 'authority'
attribute.

	# In your dist.ini:
	[Authority]

This code will be added to any package declarations in your perl files:

	our $AUTHORITY = 'cpan:APOCAL';

Your metadata ( META.yml or META.json ) will have an entry looking like this:

	x_authority => 'cpan:APOCAL'

=head1 ATTRIBUTES

=head2 authority

The authority you want to use. It should be something like C<cpan:APOCAL>.

Defaults to the username set in the %PAUSE stash in the global config.ini or dist.ini ( Dist::Zilla v4 addition! )

If you prefer to not put it in config/dist.ini you can put it in "~/.pause" just like Dist::Zilla did before v4.

=head2 do_metadata

A boolean value to control if the authority should be added to the metadata.

Defaults to true.

=head2 do_munging

A boolean value to control if the $AUTHORITY variable should be added to the modules.

Defaults to true.

=head2 locate_comment

A boolean value to control if the $AUTHORITY variable should be added where a
C<# AUTHORITY> comment is found.  If this is set then an appropriate comment
is found, and C<our $AUTHORITY = 'cpan:PAUSEID';> is inserted preceding the
comment on the same line.

This basically implements what L<OurPkgVersion|Dist::Zilla::Plugin::OurPkgVersion>
does for L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>.

Defaults to false.

NOTE: If you use this method, then we will not use the pkg style of declaration! That way, we keep the line numbering consistent.

=head2 authority_style

A value to control the type of the $AUTHORITY declaration. There are two styles: 'pkg' or 'our'. In the past
this module defaulted to the 'pkg' style but due to various issues 'our' is now the default. Here's what both styles
would look like in the resulting code:

	# pkg
	BEGIN {
		$Dist::Zilla::Plugin::Authority::AUTHORITY = 'cpan:APOCAL';
	}

	# our
	our $AUTHORITY = 'cpan:APOCAL';

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla|Dist::Zilla>

=item *

L<http://www.perlmonks.org/?node_id=694377|http://www.perlmonks.org/?node_id=694377>

=item *

L<http://perlcabal.org/syn/S11.html#Versioning|http://perlcabal.org/syn/S11.html#Versioning>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::Authority

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Plugin-Authority>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Authority>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Authority>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Authority>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Authority>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Dist-Zilla-Plugin-Authority>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/Dist-Zilla-Plugin-Authority>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Authority>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Authority>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Authority>

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

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-authority at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-Authority>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-dist-zilla-plugin-authority>

  git clone git://github.com/apocalypse/perl-dist-zilla-plugin-authority.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head2 CONTRIBUTORS

=for stopwords Dave Rolsky Kent Fredric Nigel Metheringham Randy Stauner

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Kent Fredric <kentnl@cpan.org>

=item *

Nigel Metheringham <nigel.metheringham@dev.intechnology.co.uk>

=item *

Randy Stauner <randy@magnificent-tears.com>

=back

=head1 ACKNOWLEDGEMENTS

This module is basically a rip-off of RJBS' excellent L<Dist::Zilla::Plugin::PkgVersion>, thanks!

Props goes out to FLORA for prodding me to improve this module!

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
