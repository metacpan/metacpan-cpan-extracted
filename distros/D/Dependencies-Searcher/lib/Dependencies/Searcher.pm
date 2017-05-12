package Dependencies::Searcher;

use 5.010;
use Data::Printer;
use feature qw(say);
# Since 2.99 a is_core() method is available :)
use Module::CoreList 2.99;
use Module::Version 'get_version';
use autodie;
use Moose;
use IPC::Cmd qw[can_run run];
use Dependencies::Searcher::AckRequester;
use Log::Minimal env_debug => 'LM_DEBUG';
use File::Stamped;
use IO::File;
use File::HomeDir;
use File::Spec::Functions qw(catdir catfile);
use Version::Compare;
use Path::Class;
use ExtUtils::Installed;

our $VERSION = '0.065';

=head1 NAME

Dependencies::Searcher - Search for modules used or required by a
distribution and build a report that can be used as L<Carton|Carton>
cpanfile .

=cut

=head1 SYNOPSIS

    use Dependencies::Searcher;

    my $searcher = Dependencies::Searcher->new();
    my @elements = $searcher->get_files();
    my @uses = $searcher->get_modules($path, "use");
    my @uniq_modules = $searcher->uniq(@uses);

    $searcher->dissociate(@uniq_modules);

    $searcher->generate_report($searcher->non_core_modules);

    # Prints to cpanfile
    # requires 'Data::Printer', '0.35';
    # requires Moose, '2.0602';
    # requires IPC::Cmd;
    # requires Module::Version;
    # ...

=cut

=head1 DESCRIPTION

Maybe you don't want to have to list all the dependencies of your Perl
application by hand and want an automated way to build it. Maybe you
forgot to do it for a long time ago. Or just during a short period.
Anyway, you've add lots of CPAN modules. L<Carton|Carton> is here to help you
manage dependencies between your development environment and
production, but how to keep track of the list of modules you will pass
to L<Carton|Carton>?

Event if it is a no brainer to keep track of this list by adding it by
hand, it can be much better not to have to do it.

You will need a tool that will check for any I<requires> or I<use> in
your module package, and report it into a file that could be used as an
input L<Carton|Carton> cpanfile. Any duplicated entry will be removed and
modules versions will be checked and made available. Core modules will be
ommited because you don't need to install them (except in some special
case, see C<dissociate()> documentation).

This project has begun because it has happened to me, and I don't want
to search for modules to install by hand, I just want to run a simple
script that update the list in a convenient way. It was much more
longer to write the module than to search by hand so I wish it could
be useful for you now.

This module is made to search dependencies for I<installed
distributions>, it is not supposed to manage anything else.

=cut

=head1 WHY ISN'T IT JUST ANOTHER MODULE::SCANDEPS ?

Module::ScanDeps is a bi-dimentional recursive scanner: it features
dependencies and directories recursivity.

Dependencies::Searcher only found direct dependencies, not
dependencies of dependencies, it scans recursively directories but not
dependencies..

These direct dependencies are passed to the Perl toolchain (cpanminus)
that will take care of any recursive dependencies.

=cut

# Init parameters
has 'non_core_modules' => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    default    => sub { [] },
    handles    => {
	add_non_core_module    => 'push',
	count_non_core_modules => 'count',
    },
);

has 'core_modules' => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    default => sub { [] },
    handles    => {
	add_core_module    => 'push',
	count_core_modules => 'count',
    },
);

# Log stuff here
local $ENV{LM_DEBUG} = 0; # 1 for debug logs, 0 for info

my $work_path = File::HomeDir->my_data;
my $log_fh = File::Stamped->new(
    pattern => catdir($work_path,  "dependencies-searcher.log.%Y-%m-%d.out"),
);

say("tail -vf $work_path for log");

# Overrides Log::Minimal PRINT
$Log::Minimal::PRINT = sub {
    my ( $time, $type, $message, $trace) = @_;
    print {$log_fh} "$time [$type] $message\n";
};

infof('  * * * * * * * * * * * * * * * * * * * *');
infof('* H E R E   I S   A   N E W   S E A R C H *');
infof('  * * * * * * * * * * * * * * * * * * * *');

infof("Dependencies::Searcher $VERSION debugger init.");
infof("Log file available in " . $work_path);
# End of log init

sub get_modules {
    # @path contains files and directories
    my ($self, $pattern, @path) = @_;

    debugf("Ack pattern : " . $pattern);

    # The regex add the terminal semicolon at the end of the line to
    # make the difference between comments and code, because "use" is
    # a word that you can find often in a POD section, more much in
    # the beginning of line than you could think
    $pattern = "$pattern" . qr/.+;$/;

    my @params = ('--perl', '-hi', $pattern, @path);
    foreach my $param (@params) {
	debugf("Param : " . $param);
    }

    my $requester = Dependencies::Searcher::AckRequester->new();

    my $ack_path = $requester->get_path();
    debugf("Ack path : " . $ack_path);

    my $cmd_use = $requester->build_cmd(@params);

    my @moduls = $requester->ack($cmd_use);
    infof("Found $pattern modules : " . @moduls);

    if ( defined $moduls[0]) {
	if ($moduls[0] =~ m/^use/ or $moduls[0] =~ m/^require/) {
	    return @moduls;
	} else {
	    critf("Failed to retrieve modules with Ack");
	    die "Failed to retrieve modules with Ack";
	}
    } else {
	say "No use or require found !";
    }
}

sub get_files {
    my $self = shift;
    # Path::Class  functions allows a more portable module
    my $lib_dir = dir('lib');
    my $make_file = file('Makefile.PL');
    my $script_dir = dir('script');

    my @structure;
    $structure[0] = "";
    $structure[1] = "";
    $structure[2] = "";
    if (-d $lib_dir) {

	$structure[0] = $lib_dir;

    } else {
	# TODO : TEST IF THE PATH IS OK ???
	die "Don't look like we are working on a Perl module";
    }

    if (-f $make_file) {
	$structure[1] = $make_file;
    }

    if (-d $script_dir) {
	$structure[2] = $script_dir;
    }

    return @structure;
}

# Generate a "1" when merging if one of both is empty
# Will be clean in make_it_real method
sub merge_dependencies {
    my ($self, @uses, @requires) = @_;
    my @merged_dependencies = (@uses, @requires);
    infof("Merged use and require dependencies");
    return @merged_dependencies;
}

# Remove special cases that aren't need at all
sub make_it_real {
    my ($self, @merged) = @_;
    my @real_modules;
    foreach my $module ( @merged ) {
	push(@real_modules, $module) unless

	$module =~ m/say/

	# Describes a minimal Perl version
	or $module =~ m/^use\s[0-9]\.[0-9]+?/
	or $module =~ m/^use\sautodie?/
	or $module =~ m/^use\swarnings/
	# Kind of bug generated by merge_dependencies() when there is
	# only one array to merge
	or $module =~ m/^1$/
	or $module =~ m/^use\sDependencies::Searcher/;
    }
    return @real_modules;
}

# Clean correct lines that can't be removed
sub clean_everything {
    my ($self, @dirty_modules) = @_;
    my @clean_modules = ();

    foreach my $module ( @dirty_modules ) {

	debugf("Dirty module : " . $module);

	# remove the 'use' and the space next
	$module =~ s{
			use \s
		}
		    {}xi; # Empty subtitution

	# remove the require, quotes and the space next
	# but returns the captured module name (non-greedy)
	# i = not case-sensitive
	$module =~ s{
			requires \s
			'
			(.*?)
			'
		}{$1}xi; # Note -> don't insert spaces here

	# Remove the ';' at the end of the line
	$module =~ s/ ; //xi;

	# Remove any qw(xxxxx xxxxx) or qw[xxx xxxxx]
	# '\(' are for real 'qw()' parenthesis not for grouping
	# Also removes empty qw()

        # With spaces and parenthesis e.g. qw( foo bar )
        $module =~ s{
			\s qw
			\(
			(\s*[A-Za-z]+(\s*[A-Za-z]*))*\s*
			\)
		}{}xi;

        # Without spaces, with  parenthesis e.g. qw(foo bar) and optionnal [method_names
        $module =~ s{
			\s qw
			\(
			([A-Za-z]+(_[A-Za-z]+)*(\s*[A-Za-z]*))*
			\)
		}{}xi;

        # With square brackets e.g. qw[foo bar] and optionnal [method_names]
	$module =~ s{
			\s qw
			\[
			([A-Za-z]+(_[A-Za-z]+)*(\s*[A-Za-z]*))*
			\]
		}
		    {}xi; # Empty subtitution
        # With spaces and parenthesis e.g. qw/ foo bar /
	$module =~ s{
			\s qw
			\/
			(\s[A-Za-z]+(_[A-Za-z]+)*(\s*[A-Za-z]*))*\s
			\/
		}
		    {}xi; # Empty subtitution

	# Remove method names between quotes (those that can be used
	# without class instantiation)
	$module =~ s{
			\s
			'
			[A-Za-z]+(_[A-Za-z]+)*
			'
		}
		    {}xi; # Empty subtitution

	# Remove dirty bases and quotes.
	# This regex that substitute My::Module::Name
	# to a "base 'My::Module::Name'" by capturing
	# the name in a non-greedy way
	$module =~ s{
			base \s
			'
			(.*?)
			'
		}
		    {$1}xi;

	# Remove some warning sugar
	$module =~ s{
			([a-z]+)
			\s FATAL
			\s =>
			\s 'all'
		}
		    {$1}xi;

	# Remove version numbers
	# See "a-regex-for-version-number-parsing" :
	# http://stackoverflow.com/questions/82064/
	$module =~ s{
			\s
			(\*|\d+(\.\d+)
			    {0,2}
			    (\.\*)?)$
		}
		    {}x;

	# Remove configuration stuff like env_debug => 'LM_DEBUG' but
	# the quoted words have been removed before
	$module =~ s{
			\s
			([A-Za-z]+(_[A-Za-z]+)*( \s*[A-Za-z]*))*
			\s
			=>
		}
		    {}xi;

	debugf("Clean module : " . $module);
	push @clean_modules, $module;
    }
    return @clean_modules;
}


sub uniq {
    my ($self, @many_modules) = @_;
    my @unique_modules = ();
    my %seen = ();
    foreach my $element ( @many_modules ) {
	next if $seen{ $element }++;
	debugf("Uniq element added : " . $element);
	push @unique_modules, $element;
    }
    return @unique_modules;
}

sub dissociate {
    my ($self, @common_modules) = @_;

    foreach my $nc_module (@common_modules) {

	# The old way before 2.99 corelist
	# my $core_list_answer = `corelist $nc_module`;

	my $core_list_answer = Module::CoreList::is_core($nc_module);

	if (
	    # "$]" is Perl version
	    (exists $Module::CoreList::version{ $] }{"$nc_module"})
	    or
	    # In case module don't have a version number
	    ($core_list_answer == 1)
	) {

	    # A module can be in core but the wanted version can be
	    # more fresh than the core one...
	    # Return the most recent version
	    my $mversion_version = get_version($nc_module);
	    # Return the corelist version
	    my $corelist_version = $Module::CoreList::version{ $] }{"$nc_module"};

	    debugf("Mversion version : " . $mversion_version);
	    debugf("Corelist version : " . $corelist_version);

	    # Version::Compare warns about versions numbers with '_'
	    # are 'non-numeric values'
	    $corelist_version =~ s/_/./;
	    $mversion_version =~ s/_/./;

	    # It's a fix for this bug
	    # https://github.com/smonff/dependencies-searcher/issues/25
	    # Recent versions of corelist modules are not include in
	    # all Perl versions corelist
	    if (&Version::Compare::version_compare(
		$mversion_version, $corelist_version
	    ) == 1) {
		infof(
		    $nc_module . " version " . $mversion_version .
		    " is in use but  " .
		    $corelist_version .
		    " is in core list"
		);
		$self->add_non_core_module($nc_module);
		infof(
		    $nc_module .
		    " is in core but has been added to non core " .
		    "because it's a fresh core"
		);
		next;
	    }

	    # Add to core_module

	    # The old way
	    # You have to push to an array ref (Moose)
	    # http://www.perlmonks.org/?node_id=695034
	    # push @{ $self->core_modules }, $nc_module;

	    # The "Moose" trait way
	    # http://metacpan.org/module/Moose::Meta::Attribute::Native::Trait::Array
	    $self->add_core_module($nc_module);
	    infof($nc_module . " is core");

	} else {
	    $self->add_non_core_module($nc_module);
	    infof($nc_module . " is not in core");
	    # push @{ $self->non_core_modules }, $nc_module;
	}
    }
}

# Open a file handle to > cpanfile
sub generate_report {

    my $self = shift;

    #
    # TODO !!! Check if the module is installed already with
    # ExtUtils::Installed. If it it not, cry that
    # Dependencies::Searcher is designed to be used in the complete env
    #

    open my $cpanfile_fh, '>', 'cpanfile' or die "Can't open cpanfile : $:!";

    foreach my $module_name ( @{$self->non_core_modules} ) {

	my $version = get_version($module_name);

	# if not undef
	if ($version) {
	    debugf("Module + version : " . $module_name . " " . $version);

	    # Add the "requires $module_name\n" to the next line of the file
	    chomp($module_name, $version);

	    if ($version =~ m/[0-9]\.[0-9]+/ ) {
		say $cpanfile_fh "requires '$module_name', '$version';";
	    } # else : other case ?

	} else {
	    debugf("Module + version : " . $module_name);
	    say $cpanfile_fh "requires '$module_name';";
	}

    }

    close $cpanfile_fh;
    infof("File has been generated and is waiting for you");
}

1;

__END__

=pod

=head1 SUBROUTINES/METHODS

=head2 get_files()

C<get_files()> returns an array containing which file or directories has
been found in the current root distribution directory. We suppose it
can find dependancies in 3 different places :

=over 2

=item * files in C<lib/> directory, recursively

=item * C<Makefile.PL>

=item * C<script/> directory, i.e. if we use a Catalyst application

=item * maybe it should look in C<t/> directory (todo)

=back

If the C<lib/> directory don't exist, the program die because we
consider we are not into a plain old Perl Module.

This is work in progress, if you know other places where we can find
stuff, please report a bug.

=cut

=head2 get_modules("pattern", @elements)

You must pass a pattern to search for, and the elements (files or
directories) where you want to search (array of strings from C<get_files()>).

These patterns should be C<^use> or C<^require>.

Then, Ack will be used to retrieve modules names into lines containing
patterns and return them into an array (containing also some dirt).
See L<Dependencies::Searcher::AckRequester> for more informations.

=cut

=head2 merge_dependencies(@modules, @modules)

Simple helper method that will merge C<use> and C<require> arrays if you
search for both. Return an uniq array. It got a little caveat, see
CAVEATS.

=cut

=head2 make_it_real(@modules)

Move dependencies lines from an array to an another unless it is
considered as a special case : minimal Perl versions, C<use autodie>,
C<use warnings>. These stuff has to be B<removed>. Return a I<real
modules> array (I<real interresting> modules).

=cut

=head2 clean_everything(@modules)

After removing irrelevant stuff, we need to B<clean> what is leaving
and is considered as being crap (not strictly <CName::Of::Module>) but
needs some cleaning. We are going to remove everything but the module
name (even version numbers).

This code section is well commented (because it is regex-based) so,
please refer to it directly.

It returns an array of I<clean modules>.

=cut

=head2 uniq(@modules)

Make each array element uniq, because one dependency can be found many
times. Return an array of unique modules.

=cut

=head2 dissociate(@modules)

Dissociate I<core> / I<non-core> modules using the awesome
C<Module::Corelist::is_core method>, that search in the current Perl
version if the module is from Perl core or not. Note that results can
be different according to the environment.

More, B<you can have two versions of the same module installed on your
environment> (even if you use L<local::lib|local::lib> when you
install a recent version of a file that has been integrated into Perl
core (this version hasn't necessary been merged into core).

So C<dissociate()> checks both and compares it, to be sure that the found core
module is the "integrated" version, not a fresh one that you have
installed yourself. If it is fresh, the module is considered as a I<non-core>.

This method don't return anything, but it stores found dependencies on the two
C<core_modules> and C<non_core_modules> L<Moose|Moose> attributes arrays.

=cut

=head2 generate_report()

Generate the C<cpanfile> for L<Carton|Carton>, based on data contained into
C<core_modules> and C<non_core_modules> attributes, with optionnal
version number (if version number can't be found, dependency name is
print alone).

Generate a hash containing the modules could be achieved. Someday.

=cut

=head2 Log::Minimal::PRINT override

Just override the way Log::Minimal is used. See LOGGING AND DEBUGGING
for more informations.

=cut

=head1 LOGGING AND DEBUGGING

This module has a very convenient logging system that use
L<Log::Minimal|Log::Minimal> and L<File::Stamped|File::Stamped> to
write to a file that you will find in the directory where local
applications should store their internal data for the current
user. This is totally portable (Thanks to Nikolay Mishin
(mishin)). For exemple, on a Debian-like OS :

    ~/.local/share/dependencies-searcher.[y-M-d].out

To debug and use these logs :

    $ tail -vf ~/local/share/dependencies-searcher.[y-M-d].out

For more information on how to configure log level, read
L<Log::Minimal|Log::Minimal> documentation.

For a simple exemple on how to use it, see this blog post http://bit.ly/1lJwyX7

=head1 CAVEATS

=head2 Low Win32 / Cygwin support

This module was'nt supposed to run under Win32 / Cygwin environments
because it was using non portable code with slashes. I hope this gets
better since it has been rewritten using L<Path::Class|Path::Class>
but it still need some testing.

It also us-e Ack as a hack through a system command even if it was not
supposed to be used like that. Yes, this is dirty. Yes, I plan to change
things, even if Ack do the stuff proudly this way.

Thanks to cpantesters.org community reports, things should go better and
better.

=head2 Fun : some are able to do it using a one-liner

Command Line Magic (@climagic) tweeted 4:17 PM on lun., nov. 25, 2013

    # Not perfect, but gives you a start on the Perl modules in use.
    grep -rh ^use --include="*.pl" --include="*.pm" . | sort | uniq -c

See original Tweet https://twitter.com/climagic/status/404992356513902592

=cut

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dependencies-searcher at  rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dependencies-Searcher>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 TODOs

Most of the time, todos and features are on Github and Questub.
See https://github.com/smonff/dependencies-searcher/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dependencies::Searcher

You can also look for information at:

    See https://github.com/smonff/dependencies-searcher/

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dependencies-Searcher>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dependencies-Searcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dependencies-Searcher>

=item * Search CPAN

L<http://search.cpan.org/dist/Dependencies-Searcher/>

=back

=head1 AUTHOR

smonff, C<< <smonff at gmail.com> >>

=head1 CONTRIBUTORS

=over

=item * Nikolay Mishin (mishin) helps to make it more cross-platform

=item * Alexandr Ciornii (chorny) advises on version numbers

=back

=cut

=head1 ACKNOWLEDGEMENTS

=over

=item * Brian D. Foy's L<Module::Extract::Use|Module::Extract::Use>

Was the main inspiration for this one. First, I want to use it for my needs
but it was not recursive...

See L<https://metacpan.org/module/Module::Extract::Use>

=item * L<Module::CoreList|Module::CoreList>

What modules shipped with versions of perl. I use it extensively to detect
if the module is from Perl Core or not.

See L<http://perldoc.perl.org/Module/CoreList.html>

=item * Andy Lester's Ack

I've use it as the main source for the module. It was pure Perl so I've choose
it, even if Ack is not meant for being used programatically, this use do the
job.

See L<http://beyondgrep.com/>

=back

See also :

=over 2

=item * https://metacpan.org/module/Perl::PrereqScanner

=item * http://stackoverflow.com/questions/17771725/

=item * https://metacpan.org/module/Dist::Zilla::Plugin::AutoPrereqs

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 smonff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut


