package Git::Github::Creator;

use strict;
use warnings;
use subs qw(INFO DEBUG);
use vars qw($VERSION);

$VERSION = '0.18';

=head1 NAME

Git::Github::Creator - Create a GitHub repository from your local repository

=head1 SYNOPSIS

	# edit ~/.github_creator.ini

	# Inside a git repo
	% github_creator --name my-project --desc "an awesome thing"

	# for a Perl distro, figure it out through META.yml
	% github_creator

=head1 DESCRIPTION

This is a short script you can run from within an existing git
repository to create a remote repo on GitHub using a previously
created account. This does not create GitHub accounts
(that would violate the
L<GitHub terms of service|https://help.github.com/articles/github-terms-of-service#a-account-terms>).

If the C<--name> and C<--desc> switches are not given, it will try
to find them in META.yml. If the script doesn't find a META.yml, it
tries to run `make metafile` (or `Build distmeta`) to create one.

From META.yml it gets the module name and abstract, which it uses for
the GitHub project name and description. It uses the CPAN Search page
as the homepage (e.g. http://search.cpan.org/dist/Foo-Bar).

Once it creates the remote repo, it adds a git remote named "origin"
(unless you change that in the config), then pushes master to it.

If GitHub sends back the right page, the script ends by printing the
private git URL.

=head2 METHODS

=over 4

=item run( LIST )

Makes the magic happen. LIST is the stuff you'd put on the command line.
If you call the module as a script, the C<run> method is called for you
automatically.

=back

=head2 CONFIGURATION

The configuration file is an INI file named F<.github_creator.ini>
which the script looks for in the current directory or your home
directory (using the first one it finds).

Example:

	[github]
	login_page="https://github.com/login"
	api-token=123456789023455667890234deadbeef
	account=joe@example.com
	password=foobar
	remote_name=github
	debug=1

=head2 Section [github]

=over 4
  
=item login_page (default = https://github.com/login)

This shouldn't change, but what the hell. It's the only URL
you need to know.

=item account (default = GITHUB_USER environment var)

Your account name, which is probably your email address.

=item api-token

The old GitHub API used an access token, but the new v3 API uses
OAuth. Instead of an old access token, you can create an OAuth
one by following the example from C<Net::GitHub>:

	my $gh = Net::GitHub::V3->new( login => 'fayland', pass => 'secret' );
	my $oauth = $gh->oauth;
	my $o = $oauth->create_authorization( {
		scopes => ['user', 'public_repo', 'repo', 'gist'], # just ['public_repo']
		note   => 'test purpose',
	} );
	print $o->{token};

If you have a token, you don't need the C<account> or C<password>.

=item password (default = GITHUB_PASS environment var)

=item remote_name (default = origin)

I like to use "github" though.

=item debug (default = 0)

Do everything but don't actually create the GitHub repo.

=back

=cut

=head1 ISSUES

The GitHub webserver seems to not return the right page every so
often, so things might go wrong. Try again a couple times.

Sometimes there is a delay in the availability of your new repo. This
script sleeps a couple of seconds then tries to verify that the new repo
is there. If it can't see it, look at GitHub first to see if it showed up.

=head1 SOURCE AVAILABILITY

This source is part of a GitHub project:

	git://github.com/briandfoy/github_creator.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

David Golden and Ricardo SIGNES contributed to the code.

=head1 COPYRIGHT

Copyright (c) 2008-2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Should we run?

__PACKAGE__->run( @ARGV ) unless caller;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# It's all a big method right now, but we can refactor it.
# This is just a quick way to get it indexed in PAUSE as
# a module.

sub run {
	my ($class, @argv) = @_;

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Read config
	require Config::IniFiles;
	my %Config = ();
	my $debug;
	my $Section = 'github';
	my $ini;

	my $basename = File::Basename::basename( $0 );

	foreach my $dir ( ".", $ENV{HOME} ) {
		my $file = File::Spec->catfile( $dir, ".$basename.ini" );
		DEBUG( "Trying config file [$file]" );
		next unless -e $file;

		$ini = Config::IniFiles->new( -file => $file );

		last;
		}

	die "Could not read config file!\n" unless defined $ini;

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Setup logging
	{
	$debug = $ini->val( 'github', 'debug' ) || 0;

	use Log::Log4perl qw(:easy);
	Log::Log4perl->easy_init( $debug ? $DEBUG : $INFO );
	}

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Read config
	{
	chomp( my @remotes = `git remote` );
	my %remotes = map { $_, 1 } @remotes;
	DEBUG( "Remotes are [@remotes]\n" );
	die "github remote already exists! Exiting\n"
		if exists $remotes{'github'};
	}

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Okay, we should run, so pull in the modules
	{
	require File::Basename;
	require File::Find;
	require File::Find::Closures;
	require File::Spec;
	require Net::GitHub::V3;


	my %Defaults = (
		login_page  => "https://github.com/login",
		account     => $ENV{GITHUB_USER} || '',
		password    => $ENV{GITHUB_PASS} || '',
		remote_name => 'origin',
		debug       => 0,
        'api-token' => $ENV{GITHUB_TOKEN} ||'',
		);

	foreach my $key ( keys %Defaults ) {
		$Config{$key} = $ini->val( $Section, $key ) || $Defaults{$key};
		DEBUG( "$key is $Config{$key}" );
		}
	}

	my $opts = $class->_getopt(\@argv);
	my $self = bless $opts => $class;

	my $meta = $self->_get_metadata;

	my $name = $meta->{name};
	my $desc = $meta->{desc};

	DEBUG( "Project is [$name]" );
	DEBUG( "Project description is [$desc]" );

	my $homepage = "http://search.cpan.org/dist/$name";
	DEBUG( "Project homepage is [$homepage]" );

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Get to Github

	my $credentials = do {
		if( defined $Config{'api-token'} ) {
			my $hash = {
				access_token => $Config{'api-token'}
				};
			}
		elsif( defined $Config{'account'} ) {
			my $hash = {
				login => $Config{account},
				pass  => $Config{password},
				},
			}
		else {
			my $hash = {},
			}
		};

	my $github = Net::GitHub::V3->new( %$credentials );

	DEBUG( "Got to GitHub" );

	die "Exiting since you are debugging\n" if $Config{debug};
	DEBUG( "Logged in" );

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Create the repository

	my $resp = $github->repos->create( {
		name        => $name,
		description => $desc,
		homepage    => $homepage,
		}
		);

	{
	no warnings 'uninitialized';
	if( $resp->{error} =~ /401 Unauthorized/ ) {
		die "Authorization failed! Wrong account or api token.\n";
		}
	}

	if( my $error = $resp->{error} ) {
		die $error->[0]{error}, "\n";  # ugh
		}

	my $private = sprintf 'git@github.com:%s/%s.git', 
		                $Config{account}, $name;

	DEBUG( "Private URL is [$private]" );

	sleep 5; # github needs a moment to think

	system( "git remote add $Config{remote_name} $private" );
	system( "git push $Config{remote_name} master" );
	}

sub _meta_yml {
	my ($self, $name) = @_;

	return $self->{meta_yml} ||= do
		{
		# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
		# Get module info from META.yml
		if ( ! -e 'META.yml' ) {
			if ( -e 'Makefile.PL' ) {
				system "$^X Makefile.PL" unless -e 'Makefile';
				system "make metafile"   if     -e 'Makefile';
				}
		 elsif( -e 'Build.PL' ) {
				system "$^X Build.PL"     unless -e 'Build';
				system './Build distmeta' if     -e 'Build';
				}
			}

		my @files = grep { -e } qw(MYMETA.yml META.yml), glob( "*/META.yml" );
		DEBUG( "$files[0] found" );

		die "No META.yml found\n" unless -e $files[0];
		DEBUG( "$files[0] found" );

		require YAML;
		YAML::LoadFile( $files[0] );
		};
	}

sub _get_metadata {
	my ($self) = @_;

	return
		{
		name => $self->{name} || $self->_meta_yml->{name},
		desc => $self->{desc} || '(Perl) ' . $self->_meta_yml->{abstract},
		};
	}

sub _getopt {
	my ($self, $argv) = @_;

	require Getopt::Long;

	my %opt;
	Getopt::Long::GetOptionsFromArray(
		$argv,
		'desc|d=s' => \$opt{desc},
		'name|n=s' => \$opt{name},
		);

	return \%opt
	}

1;

