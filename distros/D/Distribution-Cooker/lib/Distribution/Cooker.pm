package Distribution::Cooker;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '1.01';

=head1 NAME

Distribution::Cooker - Create a module directory from your own templates

=head1 SYNOPSIS

	use Distribution::Cooker;

=head1 DESCRIPTION

=over 4

=cut

use Carp qw(croak carp);
use Cwd;
use Config::IniFiles;
use File::Spec::Functions qw(catfile);

__PACKAGE__->run( $ARGV[0] ) unless caller;

=item run( [ MODULE_NAME, [ DESCRIPTION ] ] )

Calls pre-run, collects information about the module you want to
create, cooks the templates, and calls post-run.

If you don't specify the module name, it prompts you. If you don't
specify a description, it prompts you.

=cut

sub run {
	my( $class, $module, $description ) = @_;

	my $self = $class->new;
	$self->init;

	$self->pre_run;

	$self->module(
		$module || prompt( "Module name> " )
		);
	croak( "No module specified!" ) unless $self->module;

	$self->description(
		$description || prompt( "Description> " )
		);

	$self->dist(
		$self->module_to_distname( $self->module )
		);

	$self->cook;

	$self->post_run;

	$self;
	}

=item new

Create the bare object. There's nothing fancy here, but if you need
something more powerful you can create a subclass.

=cut

sub new { bless {}, $_[0] }

=item init

Initialize the object. There's nothing fancy here, but if you need
something more powerful you can create a subclass.

=cut

sub init { 1 }

=item pre_run

Method to call before run() starts its work. run() will call this for
you. By default this is a no-op, but you can redefine it or override
it in a subclass.

run() calls this method immediately after it creates the object but
before it initializes it.

=cut

sub pre_run  { 1 }

=item post_run

Method to call after C<run()> ends its work. C<run()> calls this for
you. By default this is a no-op, but you can redefine it or override
it in a subclass.

=cut

sub post_run { 1 }

=item cook

Take the templates and cook them. This version uses Template
Toolkit, but you can make a subclass to override it.

I assume my own favorite values, and haven't made these
customizable yet.

=over 4

=item ttree (from Template) is in C</usr/local/bin/ttree>

=item Your distribution template directory is F<~/.templates/dist_cooker>

=item Your module template name is F<lib/Foo.pm>

=back

When C<cook> processes the templates, it provides definitions for
these template variables:

=over 4

=item description => the module description

=item module      => the package name (Foo::Bar)

=item module_dist => the distribution name (Foo-Bar)

=item module_file => module file name (Bar.pm)

=item module_path => module path under lib/ (Foo/Bar.pm)

=item year        => the current year

=back

While processing the templates, C<cook> ignores F<.git>, F<.svn>, and
F<CVS> directories.

=cut

sub cook {
	my( $module, $dist, $path ) =
		map { $_[0]->$_() } qw( module dist module_path );

	mkdir $dist, 0755 or croak "mkdir $dist: $!";
	chdir $dist       or croak "chdir $dist: $!";

	my $cwd = cwd();
	my $year = ( localtime )[5] + 1900;

	system $_[0]->ttree_command                 ,
		"-s", $_[0]->distribution_template_dir  ,
		"-d", cwd(),                            ,
		"-define", qq|module='$module'|         ,
		"-define", qq|module_dist='$dist'|      ,
		"-define", qq|year='$year'|             ,
		"-define", qq|module_path='$path'|      ,
		q{--ignore=\\b(\\.git|\\.svn|CVS)\\b}   ,
		;

	rename
		catfile( 'lib', $_[0]->module_template_basename ),
		catfile( 'lib', $path ) or croak "Could not rename module template: $!";
	}

=item ttree_command

Returns the name for the ttree command from template, and croaks if
that path does not exist or is not executable.

The default path is F</usr/local/bin/ttree>. You can override this in
a subclass.

=cut

sub ttree_command {
	my $path = "/usr/local/bin/ttree";

	croak "Didn't find ttree at $path!\n" unless -e $path;
	croak "$path is not executable!\n"    unless -x $path;

	$path;
	}

=item distribution_template_dir

Returns the name of the directory that contains the distribution
templates.

The default path is F<~/.templates/modules>. You can override this in
a subclass.

=cut

sub distribution_template_dir {
	my $path = catfile( $ENV{HOME}, '.templates', 'modules' );

	croak "Couldn't find templates at $path!\n" unless -d $path;

	$path;
	}

=item description

Returns the description of the module.

The default name is C<TODO: describe this module>. You can override
this in a subclass.

=cut

sub description {
	$_[0]->{description} = $_[1] if defined $_[1];
	$_[0]->{description} || 'TODO: describe this module'
	}

=item module_template_basename

Returns the name of the file that is the module.

The default name is F<Foo.pm>. You can override this in a subclass.

=cut

sub module_template_basename {
	"Foo.pm";
	}

=item module( [ MODULE_NAME ] )

Return the module name. With an argument, set the module name.

=cut

sub module {
	$_[0]->{module} = $_[1] if defined $_[1];
	$_[0]->{module};
	}

=item module_path()

Return the module path under F<lib/>. You must have set C<module>
already.

=cut

sub module_path {
	my @parts = split /::/, $_[0]->{module};
	return unless @parts;
	$parts[-1] .= '.pm';
	my $path = catfile( @parts );
	}

=item dist( [ DIST_NAME ] )

Return the dist name. With an argument, set the module name.

=cut

sub dist {
	$_[0]->{dist} = $_[1] if defined $_[1];
	$_[0]->{dist};
	}

=item module_to_distname( MODULE_NAME )

Take a module name, such as C<Foo::Bar>, and turn it into a
distribution name, such as C<Foo-Bar>.

=cut

sub module_to_distname {
	my( $self, $module ) = @_;

	my $dist   = $module; $dist =~ s/::/-/g;
	my $file   = $module; $file =~ s/.*:://; $file .= ".pm";

	return $dist;
	}

=item prompt( MESSAGE )

Show the user MESSAGE, grap a line from STDIN, and return it.

=cut

sub prompt {
	print join "\n", @_;
	print "> ";

	my $line = <STDIN>;
	chomp $line;
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

	http://github.com/briandfoy/distribution--cooker/

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
