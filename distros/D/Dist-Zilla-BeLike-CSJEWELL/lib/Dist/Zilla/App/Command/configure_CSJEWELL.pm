package Dist::Zilla::App::Command::configure_CSJEWELL;

use 5.008003;
use strict;
use warnings;
use Dist::Zilla::App -command;
use autodie;
use File::Spec;

our $VERSION = '0.900';
$VERSION =~ s/_//sm;

sub abstract { ## no critic(ProhibitAmbiguousNames)
	return q{configure the 'CSJEWELL' minting profile.};
}

sub validate_args {
	my ( $self, undef, $args ) = @_;

	if ( 0 != @{$args} ) {
		$self->usage_error('Too many arguments');
	}

	return;
}

sub execute {
	my ( $self, undef, undef ) = @_;

	my $chrome = $self->app()->chrome();

	## no critic(ProtectPrivateSubs)
	my $config_root = Dist::Zilla::Util->_global_config_root();

	if (   not -d $config_root
		or not -f File::Spec->catfile( $config_root, 'config.ini' ) )
	{
		$chrome->logger()->log_fatal( [
				'A per-user configuration file does not exist in %s',
				"$config_root",
			] );

		return;
	}

	my $homepage = $chrome->prompt_str(
		'Where is your homepage?',
		{   check => sub { defined $_[0] and $_[0] =~ /\S/ms },
			default => 'http://search.cpan.org/~username/',
		},
	);

	my $repo = $chrome->prompt_str(
		'Where are your repositories?',
		{   check => sub { defined $_[0] and $_[0] =~ /\S/ms },
			default => 'http://bitbucket.org/username/',
		},
	);

	open my $fh, '>>', $config_root->file('config.ini');

	$fh->print("\n[%DefaultURLs]\n");
	$fh->print("homepage            = $homepage\n");
	$fh->print("repository_location = $repo\n\n");

	close $fh;

	$self->log('Added to config.ini file.');

	return;
} ## end sub execute

1;

__END__

=pod

=head1 NAME

Dist::Zilla::App::Command::configure_CSJEWELL - set up the global config file

=head1 VERSION

This document describes Dist::Zilla::App::Command::configure_CSJEWELL version 0.900.

=head1 SYNOPSIS

  C:\> dzil configure_CSJEWELL

This command prompts the user for information that is used in the CSJEWELL 
minting profile and stores it in F<config.ini>.

=for Pod::Coverage abstract validate_args execute 

=head1 AUTHOR

Curtis Jewell <CSJewell@cpan.org>

=head1 SEE ALSO

L<Dist::Zilla::BeLike::CSJEWELL|Dist::Zilla::BeLike::CSJEWELL>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Curtis Jewell C<< CSJewell@cpan.org >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

