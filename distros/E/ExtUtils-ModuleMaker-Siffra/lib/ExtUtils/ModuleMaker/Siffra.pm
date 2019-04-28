package ExtUtils::ModuleMaker::Siffra;

use 5.014;
use strict;
use warnings;
use Carp;
use utf8;
use Data::Dumper;
use DDP;
use Log::Any qw($log);
use Scalar::Util qw(blessed);
$Carp::Verbose = 1;


BEGIN
{
    require ExtUtils::ModuleMaker;
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.05';
    @ISA     = qw(Exporter ExtUtils::ModuleMaker);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
} ## end BEGIN

=head3 C<block_new_method()>

  Usage     : $self->block_new_method() within text_pm_file()
  Purpose   : Build 'new()' method as part of a pm file
  Returns   : String holding sub new.
  Argument  : $module: pointer to the module being built
              (as there can be more than one module built by EU::MM);
              for the primary module it is a pointer to $self
  Throws    : n/a
  Comment   : This method is a likely candidate for alteration in a subclass,
              e.g., pass a single hash-ref to new() instead of a list of
              parameters.

=cut

sub block_new_method
{
    my $self = shift;
    return <<'EOFBLOCK';

=head2 C<new()>

  Usage     : $self->block_new_method() within text_pm_file()
  Purpose   : Build 'new()' method as part of a pm file
  Returns   : String holding sub new.
  Argument  : $module: pointer to the module being built
              (as there can be more than one module built by EU::MM);
              for the primary module it is a pointer to $self
  Throws    : n/a
  Comment   : This method is a likely candidate for alteration in a subclass,
              e.g., pass a single hash-ref to new() instead of a list of
              parameters.

=cut

sub new
{
    my ($class, %parameters) = @_;

    my $self = {};
    #my $self = $class->SUPER::new( %parameters );

    $self = bless ($self, ref ($class) || $class);

    $log->info( "new", { progname => $0, pid => $$, perl_version => $], package => __PACKAGE__ } );

    #$self->_initialize( %parameters );
    return $self;
}

EOFBLOCK
} ## end sub block_new_method

=head3 C<block_begin()>

  Usage     : $self->block_begin($module) within text_pm_file()
  Purpose   : Composes the standard code for top of a Perl pm file
  Returns   : String holding code for top of pm file
  Argument  : $module: pointer to the module being built
              (as there can be more than one module built by EU::MM);
              for the primary module it is a pointer to $self
  Throws    : n/a
  Comment   : This method is a likely candidate for alteration in a subclass,
              e.g., you don't need Exporter-related code if you're building
              an OO-module.
  Comment   : References $self keys NAME and (indirectly) VERSION

=cut

sub block_begin
{
    my ( $self, $module ) = @_;
    my $version               = $self->process_attribute( $module, 'VERSION' );
    my $package_line          = "package $module->{NAME};\n\n";
    my $min_perl_version_line = "use " . ( $self->{ MIN_PERL_VERSION } // 5.010 ) . ";\n";
    my $Id_line               = q{#$Id#} . "\n";
    my $strict_line           = "use strict;\n";
    my $warnings_line         = "use warnings;\n";                                           # not included in standard version
    my $carp_line             = "use Carp;\n";
    my $carp_verbose          = "\$Carp::Verbose = 1;\n";
    my $encoding_line         = "use utf8;\n";
    my $data_dumper_line      = "use Data::Dumper;\n";
    my $log_line              = "use Log::Any qw(\$log);\n";
    my $scalar_util_line      = "use Scalar::Util qw(blessed);\n";
    my $begin_block           = <<"END_OF_BEGIN";

BEGIN {
    use Exporter ();
    use vars qw(\$VERSION \@ISA \@EXPORT \@EXPORT_OK \%EXPORT_TAGS);
    \$VERSION     = '$version';
    \@ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    \@EXPORT      = qw();
    \@EXPORT_OK   = qw();
    \%EXPORT_TAGS = ();
}

END_OF_BEGIN

    my $text = $package_line;
    $text .= $min_perl_version_line if $self->{ MIN_PERL_VERSION };
    $text .= $Id_line               if $self->{ INCLUDE_ID_LINE };
    $text .= $strict_line;
    $text .= $warnings_line         if $self->{ INCLUDE_WARNINGS };
    $text .= $carp_line;
    $text .= $encoding_line;
    $text .= $data_dumper_line;
    $text .= $log_line;
    $text .= $scalar_util_line;
    $text .= $carp_verbose;
    $text .= $begin_block;
    return $text;
} ## end sub block_begin

=head3 C<default_values()>

  Usage     : $self->default_values() within complete_build()
  Purpose   : Build Makefile
  Returns   : Hash holding default_values
  Argument  : n/a
  Throws    : n/a
  Comment   : This method is a likely candidate for alteration in a subclass

=cut

sub default_values
{
    my $self         = shift;
    my $defaults_ref = $self->SUPER::default_values();

    $defaults_ref->{ AUTHOR }       = 'Luiz Benevenuto';
    $defaults_ref->{ EMAIL }        = 'luiz@siffra.com.br';
    $defaults_ref->{ CPANID }       = 'LUIZBENE';
    $defaults_ref->{ WEBSITE }      = 'https://siffra.com.br';
    $defaults_ref->{ ORGANIZATION } = 'Siffra TI';

    $defaults_ref->{ VERBOSE }          = 1;
    $defaults_ref->{ MIN_PERL_VERSION } = '5.014';

    $defaults_ref->{ LICENSE }                   = 'perl';
    $defaults_ref->{ INCLUDE_LICENSE }           = 1;
    $defaults_ref->{ INCLUDE_WARNINGS }          = 1;
    $defaults_ref->{ INCLUDE_MANIFEST_SKIP }     = 1;
    $defaults_ref->{ INCLUDE_POD_COVERAGE_TEST } = 1;
    $defaults_ref->{ INCLUDE_POD_TEST }          = 1;
    $defaults_ref->{ INCLUDE_PERLCRITIC_TEST }   = 1;
    $defaults_ref->{ INCLUDE_SCRIPTS_DIRECTORY } = 1;
    $defaults_ref->{ INCLUDE_FILE_IN_PM }        = '/home/luiz/.modulemaker/ExtUtils/ModuleMaker/include_module.pm';

    return $defaults_ref;
} ## end sub default_values

=head3 C<text_Makefile()>

  Usage     : $self->text_Makefile() within complete_build()
  Purpose   : Build Makefile
  Returns   : String holding text of Makefile
  Argument  : n/a
  Throws    : n/a
  Comment   : This method is a likely candidate for alteration in a subclass

=cut

sub text_Makefile
{
    my $self = shift;

    my %escaped = ();
    for my $key ( qw| NAME FILE AUTHOR EMAIL ABSTRACT LICENSE MIN_PERL_VERSION ORGANIZATION CPANID | )
    {
        my $value = $self->{ $key };
        ( $escaped{ $key } = $value ) =~ s{'}{\\'}g;
    }

    ( my $nameFormat = $escaped{ NAME } ) =~ s{\:\:}{\-}g;

    my $text_of_Makefile = <<END_OF_MAKEFILE_TEXT;
use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME             => '$escaped{NAME}',
    VERSION_FROM     => '$escaped{FILE}',
    ABSTRACT_FROM    => '$escaped{FILE}',
    AUTHOR           => '$escaped{AUTHOR} ($escaped{EMAIL})',
    MIN_PERL_VERSION => '$escaped{MIN_PERL_VERSION}',
    LICENSE          => '$escaped{LICENSE}',
    INSTALLDIRS      => (\$] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM => {

        # Default req
        'strict'       => 0,
        'warnings'     => 0,
        'Carp'         => 0,
        'utf8'         => 0,
        'Data::Dumper' => 0,
        'DDP'          => 0,
        'Log::Any'     => 0,
        'Scalar::Util' => 0,
        'version'      => 0,
        'Test::More'   => 0,
        # Default req

    },
    BUILD_REQUIRES => {
        'Test::More'          => 0,
        'ExtUtils::MakeMaker' => 0,
    },
    (
        eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? ()
        : (
            META_MERGE => {
                'meta-spec'    => { version => 2 },
                dynamic_config => 1,
                resources      => {
                    homepage   => 'https://siffra.com.br',
                    repository => {
                        url  => 'git\@github.com:SiffraTI/$nameFormat.git',
                        web  => 'https://github.com/SiffraTI/$nameFormat',
                        type => 'git',
                    },
                    bugtracker => {
                        web => 'https://github.com/SiffraTI/$nameFormat/issues',
                    },
                },
            }
        )
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => '$nameFormat-* *.old *.bak' },
);

WriteMakefile(\%WriteMakefileArgs);
END_OF_MAKEFILE_TEXT

    return $text_of_Makefile;
} ## end sub text_Makefile

=head3 C<pod_wrapper()>

  Usage     : $self->pod_wrapper($string) within block_pod()
  Purpose   : When writing POD sections, you have to 'escape'
              the POD markers to prevent the compiler from treating
              them as real POD.  This method 'unescapes' them and puts header
              and closer around main POD block in pm file, along with warning
              about stub documentation.
  Argument  : String holding text of POD which has been built up
              within block_pod().
  Comment   : $head and $tail inside pod_wrapper() are optional and, in a
              subclass, could be redefined as empty strings;
              but $cutline is mandatory as it supplies the last =cut

=cut

sub pod_wrapper
{
    my ( $self, $podtext ) = @_;
    my $head = <<'END_OF_HEAD';

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

END_OF_HEAD

    my $cutline = <<'END_OF_CUT';

 ====cut

END_OF_CUT

    my $tail = <<'END_OF_TAIL';
#################### main pod documentation end ###################

END_OF_TAIL

    my $encoding_section = <<'END_OF_ENCODING_SECTION';

 ====encoding UTF-8

END_OF_ENCODING_SECTION

    $cutline =~ s/\n ====/\n=/g;
    $encoding_section =~ s/\n ====/\n=/g;
    return join(
        q{},
        $head,                # optional
        $encoding_section,    # optional
        $podtext,             # required
        $cutline,             # required
        $tail                 # optional
    );
} ## end sub pod_wrapper

=head3 C<text_perlcritic_test()>

  Usage     : $self->text_perlcritic_test() within complete_build()
  Purpose   : Composes text for t/pod-coverage.t
  Returns   : String with text of t/pod-coverage.t
  Argument  : n/a
  Throws    : n/a
  Comment   : Adapted from Andy Lester's Module::Starter
  Comment   : I don't think of much of this metric, but Andy and Damian do,
              so if you want it you set INCLUDE_POD_COVERAGE_TEST => 1

=cut

sub text_perlcritic_test
{
    my $self = shift;

    my $text_of_perlcritic_test_test = <<'END_OF_TEXT_PERLCRITIC_TEST_TEST';
#!perl

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::Perl::Critic::all_critic_ok();
END_OF_TEXT_PERLCRITIC_TEST_TEST

    return $text_of_perlcritic_test_test;
} ## end sub text_perlcritic_test

=head3 C<complete_build()>

  Usage     : $self->pod_wrapper($string) within block_pod()
  Purpose   : When writing POD sections, you have to 'escape'
              the POD markers to prevent the compiler from treating
              them as real POD.  This method 'unescapes' them and puts header
              and closer around main POD block in pm file, along with warning
              about stub documentation.
  Argument  : String holding text of POD which has been built up
              within block_pod().
  Comment   : $head and $tail inside pod_wrapper() are optional and, in a
              subclass, could be redefined as empty strings;
              but $cutline is mandatory as it supplies the last =cut

=cut

sub complete_build
{
    my $self = shift;

    $self->create_base_directory();

    $self->create_directory( map { File::Spec->catdir( $self->{ Base_Dir }, $_ ) } qw{ lib t } );    # always on

    $self->create_directory( map { File::Spec->catdir( $self->{ Base_Dir }, $_ ) } qw{ scripts } )
        if $self->{ INCLUDE_SCRIPTS_DIRECTORY };                                                     # default is on

    $self->print_file( 'README', $self->text_README() );                                             # always on

    $self->print_file( 'LICENSE', $self->{ LicenseParts }{ LICENSETEXT } )
        if $self->{ INCLUDE_LICENSE };                                                               # default is on

    $self->print_file( 'Todo', $self->text_Todo() )
        if $self->{ INCLUDE_TODO };                                                                  # default is on

    $self->print_file( 'Changes', $self->text_Changes() )
        unless ( $self->{ CHANGES_IN_POD } );                                                        # default is off

    $self->print_file( 'MANIFEST.SKIP', $self->text_MANIFEST_SKIP() )
        if $self->{ INCLUDE_MANIFEST_SKIP };                                                         # default is off

    $self->print_file( qq|t/pod-coverage.t|, $self->text_pod_coverage_test() )
        if $self->{ INCLUDE_POD_COVERAGE_TEST };                                                     # default is off

    $self->print_file( qq|t/pod.t|, $self->text_pod_test() )
        if $self->{ INCLUDE_POD_TEST };                                                              # default is off

    $self->print_file( qq|t/perlcritic.t|, $self->text_perlcritic_test() )
        if $self->{ INCLUDE_PERLCRITIC_TEST };                                                       # default is off

    if ( $self->{ BUILD_SYSTEM } eq 'ExtUtils::MakeMaker' )
    {
        $self->print_file( 'Makefile.PL', $self->text_Makefile() );
    }
    else
    {
        $self->print_file( 'Build.PL', $self->text_Buildfile() );
        if (   $self->{ BUILD_SYSTEM } eq 'Module::Build and proxy Makefile.PL'
            or $self->{ BUILD_SYSTEM } eq 'Module::Build and Proxy' )
        {
            $self->print_file( 'Makefile.PL', $self->text_proxy_makefile() );
        }
    } ## end else [ if ( $self->{ BUILD_SYSTEM...})]

    my @pmfiles = ( $self );
    foreach my $f ( @{ $self->{ EXTRA_MODULES } } )
    {
        push @pmfiles, $f;
    }
    foreach my $module ( @pmfiles )
    {
        my ( $dir, $file ) = $self->_get_dir_and_file( $module );
        $self->create_directory( join( '/', $self->{ Base_Dir }, $dir ) );
        my $text_of_pm_file = $self->text_pm_file( $module );
        $self->print_file( join( '/', $dir, $file ), $text_of_pm_file );
    } ## end foreach my $module ( @pmfiles...)

    # How test files are created depends on how tests for EXTRA_MODULES
    # are handled: 1 test file per extra module (default) or all tests for all
    # modules in a single file (example:  PBP).
    unless ( $self->{ EXTRA_MODULES_SINGLE_TEST_FILE } )
    {
        my $ct = $self->{ FIRST_TEST_NUMBER };
        foreach my $module ( @pmfiles )
        {
            my ( $teststart, $testmiddle );

            # Are we going to derive the lexical part of the test name from
            # the name of the module it is testing?  (non-default)
            # Or are we simply going to use our pre-defined test name?
            # (default)
            if ( $self->{ TEST_NAME_DERIVED_FROM_MODULE_NAME } )
            {
                $testmiddle = $self->process_attribute( $module, 'NAME' );
                $testmiddle =~ s|::|$self->{TEST_NAME_SEPARATOR}|g;
            }
            else
            {
                $testmiddle = $self->{ TEST_NAME };
            }
            #
            # Are we going to include a number at start of test name?
            # (default)  If so, what is sprintf format and what character is
            # used to separate it from the lexical part of the test name?
            my $testfilename;
            if ( defined $self->{ TEST_NUMBER_FORMAT } )
            {
                $teststart = "t/" . $self->{ TEST_NUMBER_FORMAT } . $self->{ TEST_NAME_SEPARATOR };
                $testfilename = sprintf( $teststart . $testmiddle . q{.t}, $ct );
            }
            else
            {
                $teststart    = "t/";
                $testfilename = $teststart . $testmiddle . q{.t};
            }

            $self->print_file( $testfilename, $self->text_test( $testfilename, $module ) );
            $ct++;
        } ## end foreach my $module ( @pmfiles...)
    } ## end unless ( $self->{ EXTRA_MODULES_SINGLE_TEST_FILE...})
    else
    {
        my ( $teststart, $testfilename );
        if ( defined $self->{ TEST_NUMBER_FORMAT } )
        {
            $teststart = "t/" . $self->{ TEST_NUMBER_FORMAT } . $self->{ TEST_NAME_SEPARATOR };
            $testfilename = sprintf( $teststart . $self->{ TEST_NAME } . q{.t}, $self->{ FIRST_TEST_NUMBER } );
        }
        else
        {
            $teststart    = "t/";
            $testfilename = $teststart . $self->{ TEST_NAME } . q{.t};
        }
        $self->print_file( $testfilename, $self->text_test_multi( $testfilename, \@pmfiles ) );
    } ## end else

    $self->print_file( 'MANIFEST', join( "\n", @{ $self->{ MANIFEST } } ) );
    $self->make_selections_defaults() if $self->{ SAVE_AS_DEFAULTS };
    return 1;
} ## end sub complete_build

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=encoding UTF-8


=head1 NAME

ExtUtils::ModuleMaker::Siffra - Create a module

=head1 SYNOPSIS

  use ExtUtils::ModuleMaker::Siffra;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Luiz Benevenuto
    CPAN ID: LUIZBENE
    Siffra TI
    luiz@siffra.com.br
    https://siffra.com.br

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

1;

# The preceding line will help the module return a true value

