package ExtUtils::ModuleMaker::Opts;
#$Id$
use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.56;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
use Carp;

my %opts;
getopts( "bhqsCIPVcn:a:v:l:u:p:o:w:e:t:r:d:", \%opts );

sub new {
    my $class = shift;
    my $eumm_package  = shift;
    my $eumm_script   = shift;
    my $self = bless( {}, $class );
    $self->{NAME} = $class;
    {
        eval "require $eumm_package";
        no strict 'refs';
        $self->{VERSION} = ${$eumm_package . "::VERSION"};
    }
    $self->{PACKAGE} = $eumm_package;
    $self->{SCRIPT} = $eumm_script;
    my %standard_options = (
        ( ( $opts{c} ) ? ( COMPACT               => $opts{c} ) : () ),
        ( ( $opts{V} ) ? ( VERBOSE               => $opts{V} ) : () ),
        ( ( $opts{C} ) ? ( CHANGES_IN_POD        => $opts{C} ) : () ),
        ( ( $opts{P} ) ? ( NEED_POD              => 0        ) : () ),
        ( ( $opts{q} ) ? ( NEED_NEW_METHOD       => 0        ) : () ),
    #    ( ( $opts{I} ) ? ( INTERACTIVE           => 0        ) : 1  ),
        INTERACTIVE      => ( ( $opts{I} ) ? 0 : 1 ),
        ( ( $opts{s} ) ? ( SAVE_AS_DEFAULTS      => $opts{s} ) : () ),
        
        ( ( $opts{n} ) ? ( NAME                  => $opts{n} ) : () ),
        ( ( $opts{a} ) ? ( ABSTRACT              => $opts{a} ) : () ),
        ( ( $opts{b} ) ? ( BUILD_SYSTEM          => $opts{b} ) : () ),
        ( ( $opts{v} ) ? ( VERSION               => $opts{v} ) : () ),
        ( ( $opts{l} ) ? ( LICENSE               => $opts{l} ) : () ),
        ( ( $opts{u} ) ? ( AUTHOR                => $opts{u} ) : () ),
        ( ( defined $opts{p} ) ? ( CPANID                => $opts{p} ) : () ),
        ( ( defined $opts{o} ) ? ( ORGANIZATION          => $opts{o} ) : () ),
        ( ( defined $opts{w} ) ? ( WEBSITE               => $opts{w} ) : () ),
        ( ( $opts{e} ) ? ( EMAIL                 => $opts{e} ) : () ),
        ( ( $opts{r} ) ? ( PERMISSIONS           => $opts{r} ) : () ),
        ( ( $opts{d} ) ? ( ALT_BUILD             => $opts{d} ) : () ),
        USAGE_MESSAGE => Usage(
            $self->{SCRIPT},
            $self->{PACKAGE},
            $self->{VERSION},
        ),
    );
    $self->{STANDARD_OPTIONS} = { %standard_options };
    
    return $self;
}


sub get_standard_options {
    my $self = shift;
    return %{ $self->{STANDARD_OPTIONS} };
}

sub Usage {
    my ($script, $eumm_package, $eumm_version) = @_;
    my $message = <<ENDOFUSAGE;
modulemaker [-CIPVch] [-v version] [-n module_name] [-a abstract]
        [-u author_name] [-p author_CPAN_ID] [-o organization]
        [-w author_website] [-e author_e-mail]
        [-l license_name] [-b build_system] [-s save_selections_as_defaults ]

Currently Supported Features
    -a   Specify (in quotes) an abstract for this extension
    -b   Specify a build system for this extension
    -c   Flag for compact base directory name
    -C   Omit creating the Changes file, add HISTORY heading to stub POD
    -d   Call methods which override default methods from this module
    -e   Specify author's e-mail address
    -h   Display this help message
    -I   Disable INTERACTIVE mode, the command line arguments better be complete
    -l   Specify a license for this extension
    -n   Specify a name to use for the extension (required)
    -o   Specify (in quotes) author's organization
    -p   Specify author's CPAN ID
    -P   Omit the stub POD section
    -q   Flag to omit a constructor from module
    -r   Specify permissions
    -s   Flag to save selections as new personal default values
    -u   Specify (in quotes) author's name
    -v   Specify a version number for this extension
    -V   Flag for verbose messages during module creation
    -w   Specify author's web site

$script version: $VERSION
$eumm_package version: $eumm_version
ENDOFUSAGE

    return ($message);
}

1;

################### DOCUMENTATION ################### 

=head1 NAME

ExtUtils::ModuleMaker::Opts - Process command-line options for F<modulemaker>

=head1 SYNOPSIS

    use ExtUtils::ModuleMaker::Opts;

    $eumm_package = q{ExtUtils::ModuleMaker};
    $eumm_script  = q{modulemaker};
    
    $opt = ExtUtils::ModuleMaker::Opts->new(
        $eumm_package,
        $eumm_script,
    );
    
    $mod = ExtUtils::ModuleMaker::Interactive->new(
        $opt->get_standard_options()
    );

=head1 DESCRIPTION

The methods in this package provide processing of command-line options for 
F<modulemaker>, the command-line utility associated with Perl extension
ExtUtils::ModuleMaker, and for similar utilities associated with Perl
extensions which subclass ExtUtils::ModuleMaker.

=head1 METHODS

=head2 C<new()>

  Usage     : $opt = ExtUtils::ModuleMaker::Opts->new($package,$script) from
              inside a command-line utility such as modulemaker
  Purpose   : Creates an ExtUtils::ModuleMaker::Opts object
  Returns   : An ExtUtils::ModuleMaker::Opts object
  Argument  : Two arguments:
              1. String holding 'ExtUtils::ModuleMaker' or a package
              subclassed therefrom, e.g., 'ExtUtils::ModuleMaker::PBP'.
              2. String holding 'modulemaker' or the name of a command-line
                 utility similar to 'modulemaker' and found in the 
                 'scripts/' directory of the distribution named in 
                 argument 1

=head2 C<get_standard_options()>

  Usage     : %standard_options = $opt->get_standard_options from
              inside a command-line utility such as modulemaker
  Purpose   : Provide arguments to ExtUtils::ModuleMaker::Interactive::new()
              or to the constructor of the 'Interactive' package of a 
              distribution subclassing ExtUtils::ModuleMaker
  Returns   : A hash suitable for passing to 
              ExtUtils::ModuleMaker::Interactive::new() or similar constructor
  Argument  : n/a

=head1 SEE ALSO

F<ExtUtils::ModuleMaker>, F<modulemaker>,
F<ExtUtils::ModuleMaker::Interactive>, F<ExtUtils::ModuleMaker::PBP>,
F<mmkrpbp>.

=cut

