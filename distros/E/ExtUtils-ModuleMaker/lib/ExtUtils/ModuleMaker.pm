package ExtUtils::ModuleMaker;
use strict;
use warnings;
BEGIN {
    use vars qw( $VERSION @ISA );
    $VERSION = 0.56;
    use base qw(
        ExtUtils::ModuleMaker::Defaults
        ExtUtils::ModuleMaker::Initializers
        ExtUtils::ModuleMaker::StandardText
    );
};
use Carp;
use File::Path;
use File::Spec;
use Cwd;
use File::Save::Home qw(
    get_subhome_directory_status
    make_subhome_directory
);

#################### PUBLICLY CALLABLE METHODS ####################

sub new {
    my $class = shift;

    my $self = ref($class) ? bless( {}, ref($class) )
                           : bless( {}, $class );

    # multi-stage initialization of EU::MM object

    # 1.  Pull in arguments supplied to constructor -- but don't do anything
    # with them yet.  These will come from one of three sources:
    # a.  In a script:  KEY => 'Value' pairs supplied to new();
    # b.  From modulemaker command-line:  -option 'Value' pairs following
    # 'modulemaker';
    # c.  From modulemaker interactive mode:  hard-wired values which may
    # supersede (b) values.
    my @arglist = @_;
    croak "Must be hash or balanced list of key-value pairs: $!"
        if (@arglist % 2);
    my %supplied_params = @arglist;

    # 2. Determine if there already exists on system a directory capable of
    # holding user ExtUtils::ModuleMaker::Personal::Defaults.  The name of
    # such a directory and whether it exists at THIS point are stored in an
    # array, a reference to which is the return value of
    # _preexists_mmkr_directory and which is then stored in the object.
    # NOTE:  If the directory does not yet exists, it is NOT automatically
    # created.
    $self->{mmkr_dir_ref} =  get_subhome_directory_status(".modulemaker");
    {
        my $mmkr_dir = $self->{mmkr_dir_ref}->{abs};
        if (defined $self->{mmkr_dir_ref}->{flag}) {
            push @INC, $mmkr_dir;
        }
        my $pers_file = File::Spec->catfile( $mmkr_dir,
            qw| ExtUtils ModuleMaker Personal Defaults.pm |
        );
        if (-f $pers_file) {
            require ExtUtils::ModuleMaker::Personal::Defaults;
            unshift @ISA, qw(ExtUtils::ModuleMaker::Personal::Defaults);
        }
    }

    # 3.  Populate object with default values.  These values will come from
    # lib/ExtUtils/ModuleMaker/Defaults.pm, unless a Personal::Defaults file
    # has been located in step 1 above.
    my $defaults_ref;
    $defaults_ref = $self->default_values();
    foreach my $param ( keys %{$defaults_ref} ) {
        $self->{$param} = $defaults_ref->{$param};
    }


    # 4.  Process key-value pairs supplied as arguments to new() either
    # from user-written program or from modulemaker utility.
    # These override default values (or may provide additional elements).
    foreach my $param ( keys %supplied_params ) {
        $self->{$param} = $supplied_params{$param};
    }

    # 5.  Initialize keys set from information supplied above, system
    # info or EU::MM itself.
    $self->set_author_composite();
    $self->set_dates();
    $self->{eumm_version} = $VERSION;
    $self->{MANIFEST} = ['MANIFEST'];

    # 6.  Validate values supplied so far to weed out most likely errors
    $self->validate_values();

    # 7.  Initialize $self->{FILE} (done here because it presumes a validated
    # NAME, which was only done in step 6).  But allow exception for
    # Interactive mode because it throws a spurious warning.
    $self->set_file_composite() unless $self->{INTERACTIVE};

    # 8.  Initialize keys set from EU::MM::Licenses::Local or
    # EU::MM::Licenses::Standard
    $self->initialize_license();

    # 9.  Any EU::MM methods stored in ExtUtils::ModuleMaker::Standard Text
    # can be overriden by supplying a
    # value for ALT_BUILD (command-line option 'd') where the value is a Perl
    # module located in @INC
    if (defined $self->{ALT_BUILD}) {
        my $alt_build = $self->{ALT_BUILD};
        unless ($alt_build =~ m{^ExtUtils::ModuleMaker::}) {
            $alt_build = q{ExtUtils::ModuleMaker::} . $alt_build;
        }
        eval "require $alt_build";
        if ($@) {
            croak "Unable to locate $alt_build for alternative methods: $!";
        } else {
            unshift @ISA, $alt_build;
        };
    }
    return $self;
}

sub complete_build {
    my $self = shift;

    $self->create_base_directory();

    $self->create_directory( map { File::Spec->catdir( $self->{Base_Dir}, $_ ) }
        qw{ lib t } );                                      # always on

    $self->create_directory( map { File::Spec->catdir( $self->{Base_Dir}, $_ ) }
        qw{ scripts } )
            if $self->{INCLUDE_SCRIPTS_DIRECTORY};          # default is on

    $self->print_file( 'README',  $self->text_README() );   # always on

    $self->print_file( 'LICENSE', $self->{LicenseParts}{LICENSETEXT} )
        if $self->{INCLUDE_LICENSE};                        # default is on

    $self->print_file( 'Todo',    $self->text_Todo() )
        if $self->{INCLUDE_TODO};                           # default is on

    $self->print_file( 'Changes', $self->text_Changes() )
        unless ( $self->{CHANGES_IN_POD} );                 # default is off

    $self->print_file( 'MANIFEST.SKIP',
        $self->text_MANIFEST_SKIP() )
            if $self->{INCLUDE_MANIFEST_SKIP};              # default is off

    $self->print_file( qq|t/pod-coverage.t|, $self->text_pod_coverage_test() )
            if $self->{INCLUDE_POD_COVERAGE_TEST};          # default is off

    $self->print_file( qq|t/pod.t|, $self->text_pod_test() )
            if $self->{INCLUDE_POD_TEST};                   # default is off

    if ( $self->{BUILD_SYSTEM} eq 'ExtUtils::MakeMaker' ) {
        $self->print_file( 'Makefile.PL', $self->text_Makefile() );
    }
    else {
        $self->print_file( 'Build.PL', $self->text_Buildfile() );
        if ( $self->{BUILD_SYSTEM} eq 'Module::Build and proxy Makefile.PL'
         or  $self->{BUILD_SYSTEM} eq 'Module::Build and Proxy') {
            $self->print_file( 'Makefile.PL',
                $self->text_proxy_makefile() );
        }
    }

    my @pmfiles = ( $self );
    foreach my $f ( @{ $self->{EXTRA_MODULES} } ) {
        push @pmfiles, $f;
    }
    foreach my $module ( @pmfiles ) {
        my ($dir, $file) = _get_dir_and_file($module);
        $self->create_directory( join( '/',  $self->{Base_Dir}, $dir ) );
        my $text_of_pm_file = $self->text_pm_file($module);
        $self->print_file( join( '/', $dir, $file ), $text_of_pm_file );
    }

    # How test files are created depends on how tests for EXTRA_MODULES
    # are handled: 1 test file per extra module (default) or all tests for all
    # modules in a single file (example:  PBP).
    unless ($self->{EXTRA_MODULES_SINGLE_TEST_FILE}) {
        my $ct = $self->{FIRST_TEST_NUMBER};
        foreach my $module ( @pmfiles ) {
            my ($teststart, $testmiddle);

            # Are we going to derive the lexical part of the test name from
            # the name of the module it is testing?  (non-default)
            # Or are we simply going to use our pre-defined test name?
            # (default)
            if ($self->{TEST_NAME_DERIVED_FROM_MODULE_NAME}) {
                $testmiddle = $self->process_attribute( $module, 'NAME' );
                $testmiddle =~ s|::|$self->{TEST_NAME_SEPARATOR}|g;
            } else {
                $testmiddle = $self->{TEST_NAME};
            }
            #
            # Are we going to include a number at start of test name?
            # (default)  If so, what is sprintf format and what character is
            # used to separate it from the lexical part of the test name?
            my $testfilename;
            if (defined $self->{TEST_NUMBER_FORMAT}) {
                $teststart = "t/" . $self->{TEST_NUMBER_FORMAT} .
                    $self->{TEST_NAME_SEPARATOR};
                $testfilename = sprintf( $teststart . $testmiddle . q{.t}, $ct );
            } else {
                $teststart = "t/";
                $testfilename = $teststart . $testmiddle . q{.t};
            }

            $self->print_file( $testfilename,
                $self->text_test( $testfilename, $module ) );
            $ct++;
        }
    } else {
        my ($teststart, $testfilename);
        if (defined $self->{TEST_NUMBER_FORMAT}) {
            $teststart = "t/" . $self->{TEST_NUMBER_FORMAT} .
                $self->{TEST_NAME_SEPARATOR};
            $testfilename = sprintf( $teststart . $self->{TEST_NAME} . q{.t},
                $self->{FIRST_TEST_NUMBER});
        } else {
            $teststart = "t/";
            $testfilename = $teststart . $self->{TEST_NAME} . q{.t};
        }
        $self->print_file( $testfilename,
            $self->text_test_multi( $testfilename, \@pmfiles ) );
    }

    $self->print_file( 'MANIFEST', join( "\n", @{ $self->{MANIFEST} } ) );
    $self->make_selections_defaults() if $self->{SAVE_AS_DEFAULTS};
    return 1;
}

sub dump_keys {
    my $self = shift;
    my %keys_to_be_shown = map {$_, 1} @_;
    require Data::Dumper;
    my ($k, $v, %retry);
    while ( ($k, $v) = each %{$self} ) {
        $retry{$k} = $v if $keys_to_be_shown{$k};
    }
    my $d = Data::Dumper->new( [\%retry] );
    return $d->Dump;
}

sub dump_keys_except {
    my $self = shift;
    my %keys_not_shown = map {$_, 1} @_;
    require Data::Dumper;
    my ($k, $v, %retry);
    while ( ($k, $v) = each %{$self} ) {
        $retry{$k} = $v unless $keys_not_shown{$k};
    }
    my $d = Data::Dumper->new( [\%retry] );
    return $d->Dump;
}

sub get_license {
    my $self = shift;
    return (join ("\n\n",
        "=====================================================================",
        "=====================================================================",
        $self->{LicenseParts}{LICENSETEXT},
        "=====================================================================",
        "=====================================================================",
        $self->{LicenseParts}{COPYRIGHT},
        "=====================================================================",
        "=====================================================================",
    ));
}

sub make_selections_defaults {
    my $self = shift;
    my %selections = %{$self};
    my @dv = keys %{ $self->default_values() };
    my $topfile = <<'END_TOPFILE';
package ExtUtils::ModuleMaker::Personal::Defaults;
use strict;

my %default_values = (
END_TOPFILE

    my @keys_needed;
    for my $k (@dv) {
        push @keys_needed, $k
            unless (
                $k eq 'ABSTRACT'         or
                $k eq 'SAVE_AS_DEFAULTS'
            );
    }

    my $kvpairs;
    foreach my $k (@keys_needed) {
        $kvpairs .=
            (' ' x 8) .
            (sprintf '%-16s', $k) .
            '=> q{' .
            $selections{$k} .
            "},\n";
    }
    $kvpairs .=
        (' ' x 8) .
        (sprintf '%-16s', 'ABSTRACT') .
        '=> q{Module abstract (<= 44 characters) goes here}' .
        "\n";

    my $bottomfile = <<'END_BOTTOMFILE';
);

sub default_values {
    my $self = shift;
    return { %default_values };
}

1;

END_BOTTOMFILE

    my $output =  $topfile . $kvpairs . $bottomfile;

    my $mmkr_dir = make_subhome_directory($self->{mmkr_dir_ref});
    my $full_dir = File::Spec->catdir($mmkr_dir,
        qw| ExtUtils ModuleMaker Personal |
    );
    if (! -d $full_dir) {
        mkpath( $full_dir );
        if ($@) {
            croak "Unable to make directory for placement of personal defaults file: $!"; };
    }
    my $pers_full = File::Spec->catfile( $full_dir, q{Defaults.pm} );
    if (-f $pers_full ) {
        my $modtime = (stat($pers_full))[9];
        rename $pers_full,
               "$pers_full.$modtime"
            or croak "Unable to rename $pers_full: $!";
    }
    open my $fh, '>', $pers_full
        or croak "Unable to open $pers_full for writing: $!";
    print $fh $output or croak "Unable to print $pers_full: $!";
    close $fh or croak "Unable to close $pers_full after writing: $!";
}

## C<_get_dir_and_file()>
##
## This subroutine was originally in lib/ExtUtils/ModuleMaker/Utility.pm.
## As other subroutines therein were superseded by calls to File::Save::Home
## functions, they were no longer called in the .pm or .t files, hence, became
## superfluous and uncovered by test suite.  When _get_dir_and_file() became the
## last called subroutine from Utility.pm, I decided it was simpler to pull it
## into the current package.
##
## Usage     : _get_dir_and_file($module) within complete_build()
## Purpose   : Get directory and name for .pm file being processed
## Returns   : 2-element list: First $dir; Second: $file
## Argument  : $module: pointer to the module being built
##             (as there can be more than one module built by EU::MM);
##             for the primary module it is a pointer to $self
## Comment   : Merely a utility subroutine to refactor code; not a method call.

sub _get_dir_and_file {
    my $module = shift;
    my @layers      = split( /::/, $module->{NAME} );
    my $file        = pop(@layers) . '.pm';
    my $dir         = join( '/', 'lib', @layers );
    return ($dir, $file);
}

1;

#################### DOCUMENTATION ####################

=head1 NAME

ExtUtils::ModuleMaker - Better than h2xs for creating modules

=head1 SYNOPSIS

At the command prompt:

    %   modulemaker

Inside a Perl program:

    use ExtUtils::ModuleMaker;

    $mod = ExtUtils::ModuleMaker->new(
        NAME => 'Sample::Module'
    );

    $mod->complete_build();

    $mod->dump_keys(qw|
        ...  # key provided as argument to constructor
        ...  # same
    |);

    $mod->dump_keys_except(qw|
        ...  # key provided as argument to constructor
        ...  # same
    |);

    $license = $mod->get_license();

    $mod->make_selections_defaults();

=head1 VERSION

This document references version 0.56 of ExtUtils::ModuleMaker, released
to CPAN on January 30 2017.

=head1 DESCRIPTION

This module is a replacement for the most typical use of the F<h2xs>
utility bundled with all Perl distributions:  the creation of the
directories and files required for a pure-Perl module to be installable with
F<make> and distributable on the Comprehensive Perl Archive Network (CPAN).

F<h2xs> has many options which are useful -- indeed, necessary -- for
the creation of a properly structured distribution that includes C code
as well as Perl code.  Most of the time, however, F<h2xs> is used as follows

    %   h2xs -AXn My::Module

to create a distribution containing only Perl code.  ExtUtils::ModuleMaker is
intended to be an easy-to-use replacement for I<this> use of F<h2xs>.

While you can call ExtUtils::ModuleMaker from within a Perl script (as in
the SYNOPSIS above), it's easier to use with a command-prompt invocation
of the F<modulemaker> script bundled with this distribution:

    %   modulemaker

Then respond to the prompts.  For Perl programmers, laziness is a
virtue -- and F<modulemaker> is far and away the laziest way to create a
pure Perl distribution which meets all the requirements for worldwide
distribution via CPAN.

=head1 USAGE

=head2 Usage from the command-line with F<modulemaker>

The easiest way to use ExtUtils::ModuleMaker is to invoke the
F<modulemaker> script from the command-line.  You can control the content of
the files built by F<modulemaker> either by supplying command-line options or
-- easier still -- replying to the screen prompts in F<modulemaker>'s
interactive mode.

B<I<If you are encountering ExtUtils::ModuleMaker for the
first time, you should turn now to the documentation for F<modulemaker> which
is bundled this distribution.>>  Return to this document once you have become
familiar with F<modulemaker>.

=head2 Use of Public Methods within a Perl Program

You can use ExtUtils::ModuleMaker within a Perl script to generate the
directories and files needed to begin work on a CPAN-ready Perl distribution.
You will need to call C<new()> and C<complete_build()>, both of which are
described in the next section.  These two methods control the
building of the file and directory structure for a new Perl distribution.

There are four other publicly available methods in this version of
ExtUtils::ModuleMaker.  C<dump_keys>, C<dump_keys_except> and
C<get_license> are intended primarily as shortcuts for
trouble-shooting problems with an ExtUtils::ModuleMaker object.
C<make_selections_defaults> enables you to be even lazier in your use of
ExtUtils::ModuleMaker by saving keystrokes entered for attributes.

=head3 C<new>

Creates and returns an ExtUtils::ModuleMaker object.  Takes a list
containing key-value pairs with information specifying the
structure and content of the new module(s).  (In this documentation, we will
sometimes refer to these key-value pairs as the I<attributes> of the
ExtUtils::ModuleMaker object.)  With the exception of
key C<EXTRA_MODULES> (see below), the values in these pairs
are all strings.  Like most such lists of key-value pairs, this list
is probably best held in a hash.   Keys which may be specified are:

=over 4

=item * Required Argument

=over 4

=item * NAME

The I<only> required feature.  This is the name of the primary module
(with 'C<::>' separators if needed).  Will no longer support the older,
Perl 4-style separator ''C<'>'' like the module F<D'Oh>.  There is no
current default for NAME; you must supply a name explicitly.

=back

=item * Other Important Arguments

=over 4

=item * ABSTRACT

A short description of the module.  CPAN likes
to use this feature to describe the module.  If the abstract contains an
apostrophe (C<'>), then the value corresponding to key C<ABSTRACT> in
the list passed to the constructor must be double-quoted; otherwise
F<Makefile.PL> gets messed up.  Certain CPAN indexing features still work
better if the abstract is 44 or fewer characters in length, but this does not
appear to be as mandatory as in the past.  (Defaults to dummy copy.)

=item * VERSION

A string holding the version number.  For alpha releases, include an
underscore to the right of the dot like C<0.31_21>. (Default is C<0.01>.)

=item * LICENSE

Which license to include in the Copyright section.  You can choose one of
the standard licenses by including 'perl', 'gpl', 'artistic', and 18 others
approved by opensource.org.  The default is to choose the 'perl' flavor
which is to share it ''under the same terms as Perl itself.''

Other licenses can be added by individual module authors to
ExtUtils::ModuleMaker::Licenses::Local to keep your company lawyers happy.

Some licenses include placeholders that will be replaced with AUTHOR
information.

=item * BUILD_SYSTEM

This can take one of three values:

=over 4

=item * C<'ExtUtils::MakeMaker'>

The first generates a basic Makefile.PL file for your module.

=item * C<'Module::Build'>

The second creates a Build.PL file.

=item * C<'Module::Build and Proxy'>

The third creates a Build.PL along with a proxy Makefile.PL
script that attempts to install Module::Build if necessary, and then
runs the Build.PL script.  This option is recommended if you want to
use Module::Build as your build system.  See Module::Build::Compat for
more details.

B<Note:>  To correct a discrepancy between the documentation and code in
earlier versions of ExtUtils::ModuleMaker, we now explicitly provide
this synonym for the third option:

    'Module::Build and proxy Makefile.PL'

(Thanks to David A Golden for spotting this bug.)

=back

=item * COMPACT

For a module named ''Foo::Bar::Baz'' creates a base directory named
''Foo-Bar-Baz'' instead of Foo/Bar/Baz.  (Default is off.)

=item * VERBOSE

Prints messages to STDOUT as it creates directories, writes files, etc. (Default
is off.)

=item * PERMISSIONS

Used to create new directories.  (Default is 0.56:  group and world can not
write.)

=item * USAGE_MESSAGE

Message given when the module C<die>s.  Scripts should set this to the same
string it would print if the user asked for help.  (A reasonable default is
provided.)

=item * NEED_POD

Include POD section in F<*.pm> files created.  (Default is on.)

=item * NEED_NEW_METHOD

Include a simple C<new()> method in the F<*.pm> files created.  (Default is
on.)

=item * CHANGES_IN_POD

Omit a F<Changes> file, but instead add a HISTORY section to the POD.
(Default is off).

=item * INCLUDE_MANIFEST_SKIP

Boolean value which, if true, includes a F<MANIFEST.SKIP> file in the
distribution with reasonable default values facilitating use of the F<make
manifest> command during module development.  (Thanks to David A Golden for
this feature.  Default is off.)

=item * INCLUDE_TODO

Boolean value which, if true, includes a F<Todo> file in the distribution in
which the module's author or maintainer can discuss future lines of
development.  (Default is on.)

=item * INCLUDE_LICENSE

Boolean value which, if true, includes a F<LICENSE> file in the distribution.
(Which LICENSE file is determined in the LICENSE option.)  (Default is on.)

=item * INCLUDE_SCRIPTS_DIRECTORY

Boolean value which, if true, includes a F<scripts/> directory (at the same
level as F<lib/> or F<t/>).  (Default is on.)

=item * INCLUDE_WARNINGS

Boolean value which, if true, inserts C<use warnings;> in all Perl modules
created by use of this module.  (Default is off.)

=item * INCLUDE_ID_LINE

Boolean value which, if true, inserts C<#$Id$> in all Perl modules
created by use of this module for the purpose of inserting a Subversion file
'Id' string.  (Default is off.)

=back

=item * Arguments Related to the Module's Author

=over 4

=item * AUTHOR

Name of the author.  If the author's name contains an apostrophe (C<'>),
then the corresponding value in the list passed to the constructor must
be double-quoted; otherwise F<Makefile.PL> gets messed up.
(Defaults to dummy copy.)

=item * EMAIL

Email address of the author.  If the author's e-mail address contains
an apostrophe (C<'>), then the corresponding value in the list passed
to the constructor must be double-quoted; otherwise
F<Makefile.PL> gets messed up.  (Defaults to dummy copy.)

=item * CPANID

The CPANID of the author.  If this is omitted, then the line will not
be added to the documentation.  (Defaults to dummy copy.)

=item * WEBSITE

The personal or organizational website of the author.  If this is
omitted, then the line will not be added to the documentation.
(Defaults to dummy copy.)

=item * ORGANIZATION

Company or group owning the module.  If this is omitted, then the line
will not be added to the documentation.  (Defaults to dummy copy.)

=back

=item * Argument Related to Multiple Modules within a Distribution

=over 4

=item * EXTRA_MODULES

A reference to an array of hashes, each of which contains values for
additional modules in the distribution.

    $mod = ExtUtils::ModuleMaker->new(
        NAME           => 'Alpha::Beta',
        EXTRA_MODULES  => [
            { NAME => 'Alpha::Beta::Gamma' },
            { NAME => 'Alpha::Beta::Delta' },
            { NAME => 'Alpha::Beta::Gamma::Epsilon' },
        ],
    );

As with the primary module, the only attribute required for each extra
module is C<NAME>.  Other attributes may be supplied but the primary
module's values will be used if no value is given here.

Each extra module will be created in the correct relative place in the
F<lib> directory.  By default, a test file will also be created in the F<t>
directory corresponding to each extra module to test that it loads
properly.  (See EXTRA_MODULES_SINGLE_TEST_FILE below to learn how to change
this behavior.)  However, no other supporting documents (I<e.g.,> README,
Changes) will be created.

This is one major improvement over the earlier F<h2xs> as you can now
build multi-module packages.

=back

=item * Arguments Related to Test Files

=over 4

=item * FIRST_TEST_NUMBER

A non-negative natural number from which the count begins in test files that
are numerically ordered.  (Default is C<1>.)

=item * TEST_NUMBER_FORMAT

In test files that are numerically ordered, a Perl C<sprintf> formatting
string that specifies how FIRST_TEST_NUMBER is to be formatted.  (Default is
C<"%03d">.)

=item * TEST_NAME

String forming the core of the name of a test file.  (Default is C<load>).

=item * TEST_NAME_DERIVED_FROM_MODULE_NAME

Boolean value which, when true, tells ExtUtils::ModuleMaker to create a file
in the test suite with a name derived from the F<.pm> package it is testing,
thereby overriding any value set in the TEST_NAME attribute.  For example, for
a module called 'Alpha::Sigma::Tau', a test file named F<t/Alpha_Sigma_Tau.t>
will be created.  (Default is off.)

=item * TEST_NAME_SEPARATOR

String holding the character which joins components of a test file's name,
I<e.g.,> the character used to join C<001> and <load> in a file named
F<001_load.t>.  (Defaults to an underscore C<_>.)

=item * EXTRA_MODULES_SINGLE_TEST_FILE

Boolean value which, when true and when extra modules have been specified in
the EXTRA_MODULES attribute, will put tests for those extra modules in a
single test file rather than in individual test files corresponding to each
module.  (Default is off.)

=item * INCLUDE_POD_COVERAGE_TEST

Boolean value which, if true, causes a test file called F<t/pod-coverage.t>
to be included in the F<t/> directory.  This test is advocated by some Perl
quality assurance experts and module authors.  However, since the maintainer
of ExtUtils::ModuleMaker is not persuaded of its worth, default is off.

=item * INCLUDE_POD_TEST

Boolean value which, if true, causes a test file called F<t/pod.t>
to be included in the F<t/> directory.  This test is advocated by some Perl
quality assurance experts and module authors.  However, since the maintainer
of ExtUtils::ModuleMaker is not persuaded of its worth, default is off.

=item * INCLUDE_FILE_IN_PM

String holding a path to a file containing Perl code and/or documentation
which will be included in each F<lib/*.pm> file created in a particular
distribution. By default, such content is placed after any constructor and
before the main POD block.  This could, for example, be used to insert stub
subroutines in each package within a distribution.  Default is off.

=back

=item * Arguments for Advanced Usages

=over 4

=item * INTERACTIVE

Activates interactive mode in F<modulemaker> utility.  The interactive mode
presents the user with a series of menus from which the user selects features
by entering text at the command prompt.  This attribute should only be used
by interactive scripts like F<modulemaker>.  (Default is off.)

=item * ALT_BUILD

Name of a Perl package holding methods which override those called withiin
C<complete_build> to shape the content of files created by using
ExtUtils::ModuleMaker.  See "An Alternative Approach to Subclassing" below.

=back

=back

=head3 C<complete_build>

Creates all directories and files as configured by the key-value pairs
passed to C<ExtUtils::ModuleMaker::new>.  Returns a
true value if all specified files are created -- but this says nothing
about whether those files have been created with the correct content.

=head3 C<dump_keys>

When troubleshooting problems with an ExtUtils::ModuleMaker object, it
is often useful to use F<Data::Dumper> to dump the contents of the
object.  Use C<dump_keys()> when you only need to examine a few of the
object's attributes.

    $mod->dump_keys( qw| NAME ABSTRACT | );

=head3 C<dump_keys_except>

When troubleshooting problems with an ExtUtils::ModuleMaker object, it
is often useful to use F<Data::Dumper> to dump the contents of the
object.  However, since certain elements of that object are often quite
lengthy (I<e.g,> the values of keys C<LicenseParts> and
C<USAGE_MESSAGE>), it's handy to have a dumper function that dumps all
keys I<except> certain designated keys.

    $mod->dump_keys_except(qw| LicenseParts USAGE_MESSAGE |);

=head3 C<get_license>

Returns a string which nicely formats a short version of the License
and Copyright information.

    $license = $mod->get_license();
    print $license;

... will print something like this:

    =====================================================================
    =====================================================================
    [License Information]
    =====================================================================
    =====================================================================
    [Copyright Information]
    =====================================================================
    =====================================================================

(Earlier versions of ExtUtils::ModuleMaker contained a
C<Display_License> function in each of submodules
F<ExtUtils::ModuleMaker::Licenses::Standard> and
F<ExtUtils::ModuleMaker::Licenses::Local>.  These functions were never
publicly documented or tested.  C<get_license()> is intended as a
replacement for those two functions.)

=head3 C<make_selections_defaults()>

Saves the values you entered as arguments passed to C<new()> in a personal
defaults file so that they supersede the defaults provided by
ExtUtils::ModuleMaker itself.

This is an advanced usage of ExtUtils::ModuleMaker.
If you have used ExtUtils::ModuleMaker more than once, you have probably typed
in a choice for C<AUTHOR>, C<EMAIL>, etc., more than once.  To save
unnecessary typing and reduce typing errors, ExtUtils::ModuleMaker now offers
you the possibility of establishing B<personal default values> which override
the default values supplied with the distribution and found in
F<lib/ExtUtils/ModuleMaker/Defaults.pm>.

Suppose that you have called C<ExtUtils::ModuleMaker::new()> as follows:

    $mod = ExtUtils::ModuleMaker->new(
        NAME            => 'Sample::Module',
        ABSTRACT        => 'Now is the time to join the party',
        AUTHOR          => 'Hilton Stallone',
        CPANID          => 'RAMBO',
        ORGANIZATION    => 'Parliamentary Pictures',
        WEBSITE         => 'http://parliamentarypictures.com',
        EMAIL           => 'hiltons@parliamentarypictures.com',
    );

While C<$mod> is still in scope, you can call:

    $mod->make_selections_defaults()

and the values selected  -- B<with two important exceptions>
-- will be saved in a F<Personal/Defaults.pm> file stored in your home
directory.  The next time you invoke ExtUtils::ModuleMaker, the new
values will appear in the appropriate locations in the files created
by C<complete_build()>.  They will also appear in the menus provided on screen
by the F<modulemaker> utility.

What are those two important exceptions?

=over 4

=item * C<NAME>

You cannot enter a default value for C<NAME>:  the name of the module
you are creating.  ExtUtil::ModuleMaker's own defaults file omits a value for
C<NAME> to prevent you from overwriting an already existing module.  (More
precisely, the default value is an empty string.  ExtUtil::ModuleMaker will
throw an error if you attempt to create a module whose name is empty.)  This
precaution applies to your personal defaults file as well.

=item * C<ABSTRACT>

Since every module you create presumably has its own unique purpose, every
module must have a unique C<ABSTRACT> to summarize that purpose.
ExtUtil::ModuleMaker supplies the following string as the default value for
the C<ABSTRACT> key:

    Module abstract (<= 44 characters) goes here

... a string which, not coincidentally, happens to be exactly 44 characters
long -- so you can just overstrike it.  This will be the default value for
C<ABSTRACT> in any F<Personal/Defaults.pm> file you create as well.

=back

=head1 CUSTOMIZATION

ExtUtils::ModuleMaker is designed to be customizable to your needs and to
offer you more flexibility as you become more experienced with it.

=head2 Via F<modulemaker> Utility Interactive Mode

As with everything else about ExtUtils::ModuleMaker, the easiest,
laziest way to get started is via the F<modulemaker> utility; see
its documentation.  Suppose that you have entered your correct name,
email address and website at the prompts in F<modulemaker>'s Author Menu.

  ------------------------

  modulemaker: Author Menu

      Feature       Current Value
  N - Author        'John Q Public'
  C - CPAN ID       'MODAUTHOR'
  O - Organization  'XYZ Corp.'
  W - Website       'http://public.net/~jqpublic'
  E - Email         'jqpublic@public.net'

  R - Return to main menu
  X - Exit immediately

  Please choose which feature you would like to edit:

Why should you ever have to enter this information again?  Return
to the F<modulemaker> Main Menu (C<R>).

  ------------------------

  modulemaker: Main Menu

      Feature                     Current Value
  N - Name of module              ''
  S - Abstract                    'Module abstract (<= 44 characters) goes here'
  A - Author information
  L - License                     'perl'
  D - Directives
  B - Build system                'ExtUtils::MakeMaker'

  G - Generate module
  H - Generate module;
      save selections as defaults

  X - Exit immediately

  Please choose which feature you would like to edit:

Select C<H> instead of C<G> to generate the distribution.  An internal
call to C<make_selections_defaults()> will save those selections in a
personal defaults file and present them to you on the Author Menu the
next time you go to use it.

=head2 Via F<modulemaker> Utility Command-Line Options Mode

For simplicity, not all of ExtUtils::ModuleMaker's default values are
represented on F<modulemaker>'s menus.  Those that are not represented on
those menus cannot be changed from there.  They I<can>, however, in many
cases be specified as options passed to F<modulemaker> on the command-line and
automatically saved as personal defaults by including the C<s> flag as one of
those options.  If, for example, your name is 'John Q Public' and you want all
modules you create to have compact top-level directories, you would call:

    %   modulemaker -Icsn Sample::Module -u 'John Q Public'

A distribution with a top-level directory F<Sample-Module> would be created.
'John Q Public' would appear in appropriate places in
F<Sample-Module/Makefile.PL> and F<Sample-Module/lib/Sample/Module.pm>.  You
could then throw away the entire F<Sample-Module> directory tree.  The I<next>
time you call C<modulemaker>, the call

    %   modulemaker -In Second::Module

would suffice to generate a compact top-level directory and 'John Q Public'
would appear in appropriate locations instead of the dreaded 'A. U. Thor'.

=head2 Via C<ExtUtils::ModuleMaker::new()>

In I<all> cases, ExtUtils::ModuleMaker's default values can be overridden with
arguments passed to C<new()> inside a Perl program.  The overriding can then
be made permanent by calling C<make_selections_defaults()>.

Suppose, for example,

=over 4

=item 1

that you want the files in your test suite to appear in a numerical
order starting from C<0> rather than ExtUtils::ModuleMaker's own default
starting point of C<1>;

=item 2

that you want the number in
the test file's name to be formatted as a two-digit string padded with zeroes
rather than ExtUtils::ModuleMaker's own default format of a three-digit,
zero-padded string;

=item 3

that you want the numerical part of the test filename to be joined to the
lexical part with a dot (C<.>) rather than ExtUtils::ModuleMaker's own
default linkage character of an underscore (C<_>); and

=item 4

that you want the lexical part of the test filename to reflect the module's
name rather than ExtUtils::ModuleMaker's default of C<load>.

=back

Your Perl program would look like this:

    #!/usr/local/bin/perl
    use strict;
    use warnings;
    use ExtUtils::ModuleMaker;

    my $mod = ExtUtils::ModuleMaker->new(
        NAME        => 'Sample::Module',
        AUTHOR      => 'John Q Public',
        COMPACT     => 1,
        FIRST_TEST_NUMBER    => 0,
        TEST_NUMBER_FORMAT   => "%02d",
        TEST_NAME_SEPARATOR  => q{.},
        TEST_NAME_DERIVED_FROM_MODULE_NAME => 1,
    );

    $mod->make_selections_defaults();

A subsequent call to the F<modulemaker> utility,

    %    modulemaker -In Second::Balcony::Jump

would generate a directory tree with a compact top-level, 'John Q Public' in
appropriate locations in F<Second-Balcony-Jump/Makefile.PL> and
F<Second-Balcony-Jump/lib/Second/Balcony/Jump.pm> and a test file called
F<Second-Balcony-Jump/t/00.Second.Balcony.Jump.t>.

=head2 Via Subclassing ExtUtils::ModuleMaker

If you're a power-user, once you start playing with ExtUtils::ModuleMaker, you
won't be able to stop.  You'll ask yourself, ''Self, if I can change the
default values, why can't I change the 'boilerplate' copy that appears inside
the files which ExtUtils::ModuleMaker creates?''

Now, you can.  You can hack on the methods which
C<ExtUtils::ModuleMaker::new()> and C<complete_build()> call internally to
customize their results to your heart's desire.  The key:  build an entirely
new Perl extension whose F<lib/*.pm> file has methods that override the methods
you need overridden -- and I<only> those methods.  Follow these steps:

=head3 1. Study F<ExtUtils::ModuleMaker::Defaults>, F<::Initializers> and F<::StandardText>

ExtUtils::ModuleMaker's default values are stored in
F<lib/ExtUtils/ModuleMaker/Defaults.pm>, specifically, in its
C<default_values()> method.  Identify those values which you wish to change.

ExtUtils::ModuleMaker's other internal methods are found in two other files:
F</lib/ExtUtils/ModuleMaker/Initializers.pm> and
F<lib/ExtUtils/ModuleMaker/StandardText.pm>.  Rule of thumb:  If an internal
method is called within C<new()>, it is found in
ExtUtils::ModuleMaker::Initializers.  If it is called within
C<complete_build()>, it is found in ExtUtils::ModuleMaker::StandardText.
Study these two packages to identify the methods you wish to override.

I<Hint:>  If changing a default value in ExtUtils::ModuleMaker::Defaults will
achieve your objective, make that change rather than trying to override
methods in ExtUtils::ModuleMaker::Initializers or
ExtUtils::ModuleMaker::StandardText.

I<Hint:>  You should probably think about overriding methods in
ExtUtils::ModuleMaker::StandardText before overriding those in
ExtUtils::ModuleMaker::Initializers.

=head3 2. Use F<modulemaker> to Create the Framework for a New Distribution

You're creating a new Perl extension.  Who ya gonna call?  F<modulemaker>,
natch!  (If you have not read the documentation for F<modulemaker> by this
point, do so now.)

Suppose that you've gotten on the 'Perl Best Practices' bandwagon and want to
create all your Perl extensions in the style recommended by Damian Conway in
the book of the same name.  Use F<modulemaker> to create the framework:

    %    modulemaker -Icqn ExtUtils::ModuleMaker::PBP \
         -u 'James E Keenan' \
         -p JKEENAN \
         -o 'Perl Seminar NY' \
         -w http://search.cpan.org/~jkeenan/

You used the C<-q> option above because you do I<not> want or need a
constructor in the new package you are creating.  That package will I<inherit>
its constructor from ExtUtils::ModuleMaker.

=head3 3. Edit the F<lib/*.pm> File

Open up the best text-editor at your disposal and proceed to hack:

    %    vi ExtUtils-ModuleMaker-PBP/lib/ExtUtils/ModuleMaker/PBP.pm

Add this line near the top of the file:

    use base qw{ ExtUtils::ModuleMaker };

so that ExtUtils::ModuleMaker::PBP inherits from ExtUtils::ModuleMaker (which,
in turn, inherits from ExtUtils::ModuleMaker::Defaults,
ExtUtils::ModuleMaker::Initializers and ExtUtils::ModuleMaker::StandardText).

If you have carefully studied ExtUtils::ModuleMaker::Defaults,
ExtUtils::ModuleMaker::StandardText and I<Perl Best Practices>, you will write
methods including the following:

    sub default_values {
        my $self = shift;
        my $defaults_ref = $self->SUPER::default_values();
        $defaults_ref->{COMPACT}                        = 1;
        $defaults_ref->{FIRST_TEST_NUMBER}              = 0;
        $defaults_ref->{TEST_NUMBER_FORMAT}             = "%02d";
        $defaults_ref->{EXTRA_MODULES_SINGLE_TEST_FILE} = 1;
        $defaults_ref->{TEST_NAME_SEPARATOR}            = q{.};
        $defaults_ref->{INCLUDE_TODO}                   = 0;
        $defaults_ref->{INCLUDE_POD_COVERAGE_TEST}      = 1;
        $defaults_ref->{INCLUDE_POD_TEST}               = 1;
        return $defaults_ref;;
    }

    sub text_Makefile {
        my $self = shift;
        my $Makefile_format = q~
    use strict;
    use warnings;
    use ExtUtils::MakeMaker;

    WriteMakefile(
        NAME            => '%s',
        AUTHOR          => '%s <%s>',
        VERSION_FROM    => '%s',
        ABSTRACT_FROM   => '%s',
        PL_FILES        => {},
        PREREQ_PM    => {
            'Test::More'    => 0,
            'version'       => 0,
        },
        dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
        clean           => { FILES => '%s-*' },
    );
    ~;
        my $text_of_Makefile = sprintf $Makefile_format,
            map { my $s = $_; $s =~ s{'}{\\'}g; $s; }
                $self->{NAME},
                $self->{AUTHOR},
                $self->{EMAIL},
                $self->{FILE},
                $self->{FILE},
                $self->{FILE};
        return $text_of_Makefile;
    }

Of course, for true Perl laziness, you'll use CPAN distribution
ExtUtils::ModuleMaker::PBP, written by the author of ExtUtils::ModuleMaker as
an exemplar of subclassing ExtUtils::ModuleMaker and generating the same
output as Damian Conway's Module::Starter::PBP.

=head3 4. Test

How do you know you have correctly subclassed ExtUtils::ModuleMaker?  With a
test suite, of course.  With careful editing, you can use many of
ExtUtils::ModuleMaker's own tests in your new distribution.  You will, of
course, have to change a number of tests, because the default values implied
by Conway's recommendations are different from ExtUtils::ModuleMaker's own
defaults.  Among other things, you will have to do a search-and-replace on all
constructor calls.

    %    perl -pi'*.bak' -e 's{ExtUtils::ModuleMaker->new}{ExtUtils::ModuleMaker::PBP->new}g;'

Of course, you I<should> have written your tests first, right?

=head3 5. Install and Use

You would install your new distribution as you would any other Perl
distribution, I<i.e.,> with either ExtUtils::MakeMaker or Module::Build,
depending on which you chose in creating your subclass.

    #!/usr/local/bin/perl
    use strict;
    use warnings;
    use ExtUtils::ModuleMaker::PBP;

    my $mod = ExtUtils::ModuleMaker::PBP->new(
        NAME        => 'Sample::Module',
    );

    $mod->complete_build();

For an adaptation of the F<modulemaker> utility to work with
ExtUtils::ModuleMaker::PBP, see F<mmkrpbp> which is bundled with the latter
package.

=head3 An Alternative Approach to Subclassing

There is one other way to subclass to ExtUtils::ModuleMaker which bears
mentioning, more because the author used it in the development of this version
of ExtUtils::ModuleMaker than because it is recommended.  If for some reason
you do not wish to create a full-fledged Perl distribution for your subclass,
you can simply write the subclassing package and store it in the same
directory hierarchy on your system in which your personal defaults file is
stored.

For example, suppose you are experimenting and only wish to override one
method in ExtUtils::ModuleMaker::StandardText.  You can create a package
called ExtUtils::ModuleMaker::AlternativeText.  If you are working on a
Unix-like system, you would move that file such that its path would be:

    "$ENV{HOME}/.modulemaker/ExtUtils/ModuleMaker/AlternativeText.pm"

You would then add one argument to your call to
C<ExtUtils::ModuleMaker::new()>:

    my $mod = ExtUtils::ModuleMaker->new(
        NAME        => 'Sample::Module',
        ALT_BUILD   => 'ExtUtils::ModuleMaker::AlternativeText',
    );

=head1 CAVEATS

=over 4

=item * Tests Require Perl 5.6

While the maintainer has attempted to make the code in
F<lib/ExtUtils/Modulemaker.pm> and the F<modulemaker> utility compatible
with versions of Perl older than 5.6, the test suite currently requires
5.6 or later.  The tests which require 5.6 or later are placed in SKIP blocks.
Since the overwhelming majority of the tests I<do> require 5.6, running the
test suite on earlier Perl versions won't report much that is meaningful.

=item * Testing of F<modulemaker>'s Interactive Mode

The easiest, laziest and recommended way of using this distribution is
the command-line utility F<modulemaker>, especially its interactive
mode.  However, this is necessarily the most difficult test, as its
testing would require capturing the STDIN, STDOUT and STDERR for a
process spawned by a C<system('modulemaker')> call from within a test
file.  For now, the maintainer has relied on repeated visual inspection
of the screen prompts generated by F<modulemaker>.  With luck, F<Expect>-based
tests will be available in a future version.

=item * Testing F<modulemaker> on Non-*nix-Like Operating Systems

Since testing the F<modulemaker> utility from within the test suite
requires a C<system()> call, a clean test run depends in part on the way
a given operating system parses command-line arguments.  The maintainer
has tested this on Darwin and Win32 and, thanks to a suggestion by A.
Sinan Unur, solved a problem on Win32.  Results on other operating
systems may differ; feedback is welcome.

=back

=head1 TO DO

=over 4

=item *

Tests for F<modulemaker>'s interactive mode.

=item *

Possible new C<USE_AS_BASE> attribute which would insert modules from which
user's new module will inherit.

    USE_AS_BASE => [ qw|
        Template::Toolkit
        Module::Build
        Lingua::Romana::Perligata
        Acme::Buffy
    | ],

Such an attribute would require replacement copy for
C<ExtUtils::ModuleMaker::StandardText::block_begin()>.

=item *

Creation of a mailing list for ExtUtils::ModuleMaker.

=back

=head1 AUTHOR/MAINTAINER

ExtUtils::ModuleMaker was originally written in 2001-02 by R. Geoffrey Avery
(modulemaker [at] PlatypiVentures [dot] com).  Since version 0.33 (July
2005) it has been maintained by James E. Keenan (jkeenan [at] cpan [dot]
org).

=head1 SUPPORT

Send email to jkeenan [at] cpan [dot] org.  Please include 'modulemaker'
in the subject line.  Please report any bugs or feature requests to
C<bug-ExtUtils-ModuleMaker@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

Development repository: L<https://github.com/jkeenan/extutils-modulemaker>

=head1 ACKNOWLEDGMENTS

Thanks first and foremost to Geoff Avery for creating ExtUtils::Modulemaker
and popularizing it via presentations I attended at YAPC::NA::2003 (Boca
Raton) and YAPC::EU::2003 (Paris).

Soon after I took over maintenance of ExtUtils::ModuleMaker, David A
Golden became a driving force in its ongoing development, providing
suggestions for additional functionality as well as bug reports.  David is the
author of ExtUtils::ModuleMaker::TT which, while not a pure subclass of
ExtUtils::ModuleMaker, extends its functionality for users of
Template::Toolkit.

Thanks for suggestions about testing the F<modulemaker> utility to
Michael G Schwern on perl.qa and A Sinan Unur and Paul Lalli on
comp.lang.perl.misc.  Thanks for help in dealing with a nasty bug in the
testing to Perlmonks davidrw and tlm.  That well known Perl hacker, Anonymous
Guest, contributed another bug report  on rt.cpan.org.

As development proceeded, several issues were clarified by members of
Perlmonks.org.  CountZero, xdg, Tanktalus, holli, TheDamian and nothingmuch
made particularly useful suggestions, as did Brian Clarkson.

Thanks also go to the following beta testers:  Alex Gill, Marc Prewitt, Scott
Godin, Reinhard Urban and imacat.

Version 0.39 of ExtUtils::ModuleMaker encountered spurious testing failure reports
from testers.cpan.org.  These were eventually diagnosed as being due to bugs
in the automated testing programs and/or their operating environments on
different systems -- I<i.e.,> to problems outside ExtUtils::ModuleMaker
itself.  Several Perlmonks helped investigate this problem:  chromatic,
dave_the_m, randyk, and njh.

Thanks to Paul M Sirianni for reporting bugs that led to versions 0.48 and
0.51.

Thanks to Chris Kirke for pointing to reports at
http://cpants.cpanauthors.org/dist/ExtUtils-ModuleMaker of inconsistent
$VERSION numbers across the component files.

=head1 COPYRIGHT

Copyright (c) 2001-2002 R. Geoffrey Avery.
Revisions from v0.33 forward (c) 2005-2015 James E. Keenan.
All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
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

=head1 SEE ALSO

F<modulemaker>, F<perlnewmod>, F<h2xs>, F<ExtUtils::MakeMaker>, F<Module::Build>,
F<ExtUtils::ModuleMaker::PBP>, F<ExtUtils::ModuleMaker::TT>, F<mmkrpbp>.

=cut

