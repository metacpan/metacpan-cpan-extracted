use v5.26;
use utf8;

package Distribution::Cooker;
use experimental qw(signatures);

our $VERSION = '2.003';

use Carp                  qw(croak carp);
use Cwd;
use Config::IniFiles;
use File::Find;
use File::Basename        qw(dirname);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile abs2rel);
use IO::Interactive       qw(is_interactive);
use Mojo::File;
use Mojo::Template;
use Mojo::Util            qw(decode encode trim dumper);

__PACKAGE__->run( @ARGV ) unless caller;

=encoding utf8

=head1 NAME

Distribution::Cooker - Create a Perl module directory from your own templates

=head1 SYNOPSIS

	# The dist_cooker is a wrapper for the module
	% dist_cooker Foo::Bar "This module does that" repo_slug

	# The dist_cooker can prompt for what's missing
	% dist_cooker Foo::Bar
	Description> This module does that
	Repo name> foo-bar

	# the script just passes @ARGV to the module
	use Distribution::Cooker;
	Distribution::Cooker->run( @ARGV );

	# if you don't like something, subclass and override
	package Local::Distribution::Cooker {
		use parent qw(Distribution::Cooker);
		sub config_file_path  { ... }
		}

=head1 DESCRIPTION

This module takes a directory of templates and processes them with
L<Mojo::Template>. It's specifically tooled toward Perl modules, and
the templates are given a set of variables.

The templates have special values for C<line_start>, C<tag_start>, and
C<tag_end> since the default L<Mojo::Template> values get confused when
there's Perl code outside them.

Tags use « (U+00AB) and » (U+00BB), and whole lines use ϕ (U+03D5):

    This is the « $module » module

    ϕ This is a line of Perl code

My own templates are at L<https://github.com/briandfoy/module_templates>.

=head2 Process methods

=over 4

=item * cook

Take the templates and cook them. This version uses L<Mojo::Template>
Toolkit, but you can make a subclass to override it. See the notes
about Mojo::Template.

I assume my own favorite values, and haven't made these
customizable yet.

=over 4

=item * Your distribution template directory is F<~/.templates/dist_cooker>

=item * Your module template name is F<lib/Foo.pm>, which will be moved into place later

=back

This uses L<Mojo::Template> to render the templates, and various
settings. The values from C<template_vars> are passed to the templates
and its keys are available as named variables.

By default, these tag settings are used because these characters
are unlikely to appear in Perl code:

	* the line_start is ϕ (U+03D5)
	* the tag start is »
	* the line start is «

For example:

	This is module « $module »

When C<cook> processes the templates, it provides definitions for
these template variables listed for C<template_vars>.

While processing the templates, C<cook> ignores F<.git>, F<.svn>, and
F<CVS> directories.


=cut

sub cook ( $self ) {
	my $dir = lc $self->dist;

	my $cwd = Cwd::getcwd;

	make_path( $dir );
	croak "<$dir> does not exist" unless -d $dir;
	chdir $dir        or croak "chdir $dir: $!";

	my $files = $self->template_files;

	my $old = catfile( 'lib', $self->module_template_basename );
	my $new = catfile( 'lib', $self->module_path );

	my $vars = $self->template_vars;

	my $mt = Mojo::Template->new
		->line_start( $self->{line_start} )
		->tag_start(  $self->{tag_start}  )
		->tag_end(    $self->{tag_end}    )
		->vars(1);
	foreach my $file ( $files->@* ) {
		my $new_file = abs2rel( $file, $self->template_dir );

		if( -d $file ) {
			make_path( $new_file );
			next;
			}

		my $contents = decode( 'UTF-8', Mojo::File->new( $file )->slurp );
		my $rendered = $mt->vars(1)->render( $contents, $vars );
		Mojo::File->new( $new_file )->spew( encode( 'UTF-8', $rendered ) );
		}

	make_path dirname($new);
	rename $old => $new
		or croak "Could not rename [$old] to [$new]: $!";
	}

=item * init

Initialize the object. There's nothing fancy here, but if you need
something more powerful you can create a subclass and run some info here.

This step happens right after object create and configuration handling
and before the C<pre_run> step. By default, this does nothing.

=cut

sub init { 1 }

=item * new

Creates the bare object with the name and email of the module author,
looking for values in this order, with any combination for author and
email:

	* take values from the env: DIST_COOKER_AUTHOR and DIST_COOKER_EMAIL
	* look at git config for C<user.name> and C<user.email>
	* use default values from the method C<default_name> and C<default_email>

This looks for F<~/.dist_cooker.ini> to read the INI config and add that
information to the object.

Override C<config_file_name> to use a different name.


=cut

sub new ( $class ) { bless $class->get_config, $class }

=item * pre_run

Runs right before C<cook> does its work.

run() calls this method immediately after it creates the object and
after it initializes it. By default, this does nothing.


=cut

sub pre_run  { 1 }

=item * post_run

C<run()> calls this method right after it processes the template files.
By default, this does nothing.

=cut

sub post_run { 1 }

=item * report

=cut

sub report ( $self ) {
	open my $fh, '>', 'cooker_report.txt' or return;

	print { $fh } "$0 " . localtime() . "\n";

	print { $fh } dumper( $self->template_vars ), "\n";
	}

=item * run( [ MODULE_NAME, [ DESCRIPTION ] ] )

The C<run> method kicks off everything, and gives you a chance to
do things between steps/.

	* create the object
	* run init (by default, does nothing)
	* run pre_run (by default, does nothing)
	* collects information and prompts interactively for what it needs
	* cooks the templates (~/.templates/modules by default)
	* run post_run (by default, does nothing)
	* create cooker_report.txt (it's in .gitignore)

If you don't specify the module name, it prompts you. If you don't
specify a description, it prompts you.

=cut

sub run ( $class, $module, @args ) {
	my( $description, $repo_name ) = @args;

	my $self = $class->new;
	$self->init;

	$self->pre_run;

	$self->module( $module || prompt( "Module name" ) );
	croak( "No module specified!\n" ) unless $self->module;
	croak( "Illegal module name [$module]\n" )
		unless $self->module =~ m/ \A [A-Za-z0-9_]+ ( :: [A-Za-z0-9_]+ )* \z /x;
	$self->description( $description || prompt( "Description" ) || "An undescribed module" );

	$self->repo_name( $repo_name || prompt( "Repo name" ) );

	$self->dist( $self->module_to_distname( $self->module ) );

	$self->cook;

	$self->post_run;

	$self->report;

	$self;
	}


=back

=head2 Informative methods

These provide information the processing needs to do its work.

=over 4

=item * config_file_name

Return the filename (the basename) of the config file. The default is
F<.dist_cooker.ini>.

=cut

sub config_file_name { '.dist_cooker.ini' }

=item * default_author_email

=item * default_author_name

Returns the last resort values for author name or email. These are
C<Frank Serpico> and C<serpico@example.com>.

=cut

sub default_author_email ( $class ) { 'serpico@example.com' }
sub default_author_name  ( $class ) { 'Frank Serpico' }

=item * description( [ DESCRIPTION ] )

Returns the description of the module. With an argument, it sets
the value.

The default name is C<TODO: describe this module>. You can override
this in a subclass.

=cut

sub description ( $class, @args ) {
	$class->{description} = $args[0] if defined $args[0];
	$class->{description} || 'TODO: describe this module'
	}

=item * template_dir

Returns the path for the distribution templates. The default is
F<$ENV{HOME}/.templates/modules>. If that path is a symlink, this
returns that target of that link.

=cut

sub template_dir {
	my $path = catfile( $ENV{HOME}, '.templates', 'modules' );
	$path = readlink($path) if -l $path;

	croak "Couldn't find templates at $path!\n" unless -d $path;

	$path;
	}

=item * default_config

Returns a hash reference of the config values.

	* author_name
	* email
	* line_start
	* tag_end
	* tag_start

This looks for values in this order, and in any combination:

	* take values from the env: DIST_COOKER_AUTHOR and DIST_COOKER_EMAIL
	* look at git config for C<user.name> and C<user.email>
	* use default values from the method C<default_author_name> and C<default_author_email>

=cut

sub _git_user_name {
	my $name = `git config user.name`;
	$name =~ s/\R//g;
	trim( $name ) if length $name;
	$name;
	}

sub _git_user_email {
	my $email = `git config user.email`;
	$email =~ s/\R//g;
	trim( $email ) if defined $email;
	$email;
	}

sub default_config ( $class ) {
	my( $author, $email ) = (
		$ENV{DIST_COOKER_AUTHOR} // _git_user_name()  // $class->default_author_name,
		$ENV{DIST_COOKER_EMAIL}  // _git_user_email() // $class->default_author_email,
		);

	{
		author_name => $author,
		email       => $email,
		line_start  => 'ϕ',
		tag_end     => '»',
		tag_start   => '«',
	}

	}

=item * dist( [ DIST_NAME ] )

Return the dist name. With an argument, set the module name.

=cut

sub dist ( $self, @args ) {
	$self->{dist} = $args[0] if defined $args[0];
	$self->{dist};
	}

=item * module( [ MODULE_NAME ] )

Return the module name. With an argument, set the module name.

=cut

sub module ( $self, @args ) {
	$self->{module} = $args[0] if defined $args[0];
	$self->{module};
	}

=item * module_path()

Return the module path under F<lib/>. You must have set C<module>
already.

=cut

sub module_path ( $self ) {
	my @parts = split /::/, $self->{module};
	return unless @parts;
	$parts[-1] .= '.pm';
	my $path = catfile( @parts );
	}

=item * module_to_distname( MODULE_NAME )

Take a module name, such as C<Foo::Bar>, and turn it into a
distribution name, such as C<Foo-Bar>.

=cut

sub module_to_distname ( $self, $module ) { $module =~ s/::/-/gr }

=item * module_template_basename

Returns the name of the template file that is the module. The default
name is F<Foo.pm>. This file is moved to the right place under F<lib/>
in the cooked templates.

=cut

sub module_template_basename ( $class ) { 'Foo.pm' }

=item * repo_name

Returns the repo_name for the project. This defaults to the module
name all lowercased with C<::> replaced with C<->. You can override
this in a subclass.

=cut

sub repo_name ( $class, @args ) {
	$class->{repo_name} = $args[0] if defined $args[0];
	$class->{repo_name} // $class->module =~ s/::/-/gr
	}

=item * template_files

Return the list of templates to process. These are all the files in
the C<template_dir> excluding F<.git>, F<.svn>, F<CVS>,
and C<.infra>.

=cut

sub template_files ( $self ) {
	my @files;
	my $wanted = sub {
		if( /\A(\.git|\.svn|CVS|\.infra)\b/ ) {
			$File::Find::prune = 1;
			return;
			}
		push @files, $File::Find::name;
		};

	find( $wanted, $self->template_dir );

	return \@files;
	}

=item * template_vars

Returns a hash reference of values to fill in the templates. This hash
is passed to the L<Mojo::Template> renderer.

=over 4

=item author_name    => the name of the module author

=item cooker_version => version of Distribution::Cooker

=item cwd            => the current working directory of the new module

=item description    => the module description

=item dir            => path to module file

=item dist           => dist name (Foo-Bar)

=item email          => author email

=item module         => the package name (Foo::Bar)

=item module_path    => module path under lib/ (Foo/Bar.pm)

=item repo_name      => lowercase module with hyphens (foo-bar)

=item template_path  => the source of the template files

=item year           => the current year

=back

=cut

sub template_vars ( $self ) {
	state $hash = {
		author_name    => $self->{author_name},
		cooker_version => $VERSION,
		cwd            => cwd(),
		description    => $self->description,
		dir            => catfile( 'lib', dirname( $self->module_path ) ),
		dist           => $self->dist,
		email          => $self->{email},
		module         => $self->module,
		module_path    => $self->module_path,
		repo_name      => $self->repo_name,
		template_path  => $self->template_dir,
		year           => ( localtime )[5] + 1900,
		};

	$hash;
	}

=back

=head2 Utility methods

=over 4

=item * config_file_path

Returns the path to the config file. By default, this is the value of
C<config_file_name> under the home directory.

=cut

sub config_file_path ( $class ) {
	catfile( $ENV{HOME}, $class->config_file_name )
	}

=item * get_config

Returns a hash reference of the config values. These are the values
that apply across runs.

First, this populates a hash with C<default_config>, then replaces
values from the config file (C<config_file_path>).

This version uses L<Config::IniFiles>

	[author]
	name=...
	email=...

	[templates]
	line_start=...
	tag_end=...
	tag_start=...

=cut

sub get_config ( $class ) {
	my $file = $class->config_file_path;

	my $hash = $class->default_config;

	my @table = (
		[ qw( author_name  author    name       ) ],
		[ qw( author_email author    email      ) ],
		[ qw( line_start   templates line_start ) ],
		[ qw( tag_end      templates tag_end    ) ],
		[ qw( tag_start    templates tag_start  ) ],
		);

	if( -e $file ) {
		require Config::IniFiles;
		my $config = Config::IniFiles->new( -file => $file );

		foreach my $row ( @table ) {
			my( $config_name, $section, $field ) = @$row;
			$hash->{$config_name} = $config->val( $section, $field )
				if $config->exists( $section, $field );
			}
		}

	$hash;
	}

=item * prompt( MESSAGE )

Show the user MESSAGE, grap a line from STDIN, and return it. If the
session is not interactive, this returns nothing.

Most things that prompt should have a default value in the case that
C<prompt> cannot work.

=cut

sub prompt ( @args ) {
	return unless is_interactive();

	print join "\n", @args;
	print "> ";

	chomp( my $line = <STDIN> );
	$line;
	}

=back

=head1 TO DO

Right now, C<Distribution::Cooker> uses the defaults that I like, but
that should come from a configuration file.

=head1 SEE ALSO

Other modules, such as C<Module:Starter>, do a similar job but don't
give you as much flexibility with your templates.

=head1 SOURCE AVAILABILITY

This module is in Github:

	http://github.com/briandfoy/distribution-cooker/

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2024, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
