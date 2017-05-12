package GitHub::Extract;

=pod

=head1 NAME

GitHub::Extract - Extract an exported copy of a GitHub project

=head1 SYNOPSIS

	my $project = GitHub::Extract->new(
		username => 'adamkennedy',
		project  => 'PPI',
	);
	
	$project->extract( to => '/my/directory' );

=head1 DESCRIPTION

L<GitHub::Extract> is a simple light weight interface to
L<http://github.com/> for the sole purpose of retrieving and extracting
a "zipball" of a public (and likely open source) project.

It makes use of the plain route used by the user interface "zip" button,
and as a result it avoids the need to use the full GitHub API and client.

This module shares extends (and emulates where needed) the API of
L<Archive::Extract>. Any existing tooling code which uses L<Archive::Extract>
to work with release tarballs should be trivially upgradable to work with
projects directly from GitHub instead.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Carp                  ();
use File::Spec       3.30 ();
use File::Temp       0.21 ();
use File::pushd      1.00 ();
use HTTP::Tiny      0.019 ();
use Params::Util     1.00 ();
use Archive::Extract 0.56 ();
use IO::Socket::SSL  1.56 (); # Needed for HTTP::Tiny SSL

our $VERSION = '0.02';
our $WARN    = 1;
our $DEBUG   = 0;

use Object::Tiny 1.01 qw{
	username
	repository
	branch
	url
	http
	archive
	archive_extract
};






######################################################################
# Constructor

=pod

=head2 new

	my $branch = GitHub::Extract->new(
		username   => 'adamkennedy',
		repository => 'PPI',

		# Fetch a branch other than master
		branch     => 'mybranch',

		# A custom HTTP client can be provided to any constructor
		http       => HTTP::Tiny->new(
			# Custom HTTP setup goes here
		),
	);

The C<new> constructor identifies a project to download (but does not take any
immediate action to do the download).

It takes a number of simple parameters to control where to download from.

=over 4

=item username

The GitHub username identifying the owner of the repository.

=item repository

The name of the repository within the account or organisation.

=item branch

An optional parameter identifying a particular branch to download. If not
specificied, the 'master' branch will be fetched.

=item http

L<GitHub::Extract> will create a L<HTTP::Tiny> object with default settings to
download the zipball from GitHub.

This parameter allows you to use your own custom L<HTTP::Tiny> client with
alternative settings.

=back

Returns a new L<GitHub::Extract> object, or false on error.

=head2 username

The C<username> method returns the GitHub username for the request.

=head2 repository

The C<repository> method returns the GitHub repository name for the request.

=head2 branch

The C<branch> method returns the name of the branch to be fetched.

=head2 url

The C<url> method returns the full download URL used to fetch the zipball.

=head2 http

The C<http> method returns the HTTP client that will be used for the request. 

=head2 archive

The C<archive> method will return the absolute path to the downloaded zip file
on disk, if the download was successful.

Returns C<undef> if the download was not completed successfully.

=head2 archive_extract

The C<archive_extract> method will return the L<Archive::Extract> object used
to extract the files from the zipball, whether or not it extracted
successfully.

Returns C<undef> if the download was not completed successfully.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Generate the URL from the pieces
	unless ( $self->url ) {
		# Apply defaults
		unless ( $self->branch ) {
			$self->{branch} = 'master';
		}

		# Check params to make the url
		my $username   = $self->username   or return;
		my $repository = $self->repository or return;
		my $branch     = $self->branch     or return;

		$self->{url} = "https://github.com/$username/$repository/zipball/$branch";
	}

	unless ( Params::Util::_INSTANCE($self->http, 'HTTP::Tiny') ) {
		$self->{http} = HTTP::Tiny->new;
	}

	return $self;
}





######################################################################
# Main Methods

=pod

=head2 extract

	$project->extract( to => '/output/path' );

Extracts the archive represented by the L<GitHub::Extract> object to
the path of your choice as specified by the C<to> argument. Defaults to
C<cwd()>.

In the case that you did not specify a C<to> argument, the output
file will be the name of the archive file, stripped from its C<.gz>
suffix, in the current working directory.

It will return true on success, and false on failure.

=cut

sub extract {
	my $self = shift;
	my @to   = @_;

	# Clear any previous errors
	delete $self->{_error_msg};
	delete $self->{_error_msg_long};

	# Download the code as a GitHub "zipball"
	my $url      = $self->url;
	my $tempdir  = File::Temp::tempdir( CLEANUP => 1 );
	my $archive  = File::Spec->catfile( $tempdir, "github-extract.zip" );
	my $response = $self->http->mirror( $url, $archive );
	unless ( $response->{success} ) {
		return $self->_error("Failed to download $url");
	}
	$self->{archive} = $archive;

	# Hand off extraction to Archive::Extract
	local $Archive::Extract::WARN  = $WARN;
	local $Archive::Extract::DEBUG = $DEBUG;
	$self->{archive_extract} = Archive::Extract->new( archive => $archive );
	return $self->{archive_extract}->extract(@to);
}

=pod

=head2 pushd

	my $guard = $project->pushd( to => '/output/path' );

The C<pushd> method downloads and extracts the project from GitHub, and then
temporarily changes the current working directory into the extract path of the
project.

Returns a L<File::pushd> guard object which will return the current working
directory to the original location when it is deleted, or false if the archive
was not extracted.

=cut

sub pushd {
	my $self   = shift;
	my $result = $self->extract(@_);
	return $result unless $result;
	return File::pushd::pushd( $self->extract_path );
}
	




######################################################################
# Proxied Methods

=pod

=head2 extract_path

	# Prints '/output/path/myproject-0.01-af41bc'
	if ( $project->extract( to => '/output/path' ) ) {
		print $project->extract_path;
	}

The C<extract_path> method returns the absolute path of the logical root
directory of the zipball, once it has been extracted.

Since some archives will contain a single root directory within the zip file
with which the content is placed (and some will not) this compensates for the
different, detecting the logical root automatically.

See L<Archive::Extract/extract> for more details.

=cut

sub extract_path {
	my $self    = shift;
	my $extract = $self->archive_extract or return;

	return $self->archive_extract->extract_path;
}

=pod

=head2 files

The C<files> method returns an array ref with the paths of all the files in the
archive, relative to the C<to> argument you specified.

To get the full path to an extracted file, you would use:

    File::Spec->catfile( $to, $ae->files->[0] );

See L<Archive::Extract/extract> for more details.

=cut

sub files {
	my $self    = shift;
	my $extract = $self->archive_extract or return;

	return $self->archive_extract->files;
}

=pod

=head2 error

	my $simple  = $project->error;
	my $verbose = $project->error(1);

The C<error> method returns the last encountered error as string.

Pass it a true value to get the detailed output instead, as produced by
L<Carp/longmess>.

=cut

sub error {
	my $self = shift;

	# Hand off to the underlying extract object if we got that far
	if ( $self->archive_extract ) {
		return $self->archive_extract->error(@_);
	}

	# Fall back to showing our own errors
	my $aref = $self->{ $_[0] ? '_error_msg_long' : '_error_msg' } || [];
	return join $/, @$aref;
}

# Add an error system compatible with Archive::Extract
sub _error {
	my $self    = shift;
	my $error   = shift;
	my $lerror  = Carp::longmess($error);

	$self->{_error_msg}      ||= [];
	$self->{_error_msg_long} ||= [];

	push @{$self->{_error_msg}},      $error;
	push @{$self->{_error_msg_long}}, $lerror;

	# Set $GitHub::Extract::WARN to 0 to disable printing of errors
	Carp::carp( $DEBUG ? $lerror : $error ) if $WARN;

	return;
}

1;

=pod

=head1 GLOBAL VARIABLES

All global variables share the names and behaviour of the equivalent variables
in L<Archive::Extract>. Their value will be propogated down to the equivalent
variables in L<Archive::Extract> whenever it is being used.

=head2 $GitHub::Extract::DEBUG

Set this variable to C<true> to have all calls to command line tools
be printed out, including all their output.

This also enables C<Carp::longmess> errors, instead of the regular
C<carp> errors.

Good for tracking down why things don't work with your particular
setup.

Defaults to C<false>.

=head2 $GitHub::Extract::WARN

This variable controls whether errors encountered internally by
C<GitHub::Extract> should be C<carp>'d or not.

Set to false to silence warnings. Inspect the output of the C<error()>
method manually to see what went wrong.

Defaults to C<true>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GitHub-Extract>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Archive::Extract>

L<http://github.com/>

=head1 COPYRIGHT

Copyright 2012-2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
