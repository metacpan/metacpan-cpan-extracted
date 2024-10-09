
use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Required to be able to use the DBUG modules ...
my %requires = ( FileHandle         => 0,
                 File::Basename     => 0,
                 Cwd                => 0,
                 Config             => 0,
                 Sub::Identify      => 0,
                 Perl::OSType       => 0,
		 Perl::AtEndOfScope => 0,

                 # Term::ANSIColor   => '2.00',   # Optional ...
                 # Time::HiRes       => 1,        # Optional ...
               );

# Sourced in by "require", varies by OS ...
if ( $^O eq "MSWin32" ) {
   # $requires{"Win32::Console::ANSI"} = "1.04";   # So Term::ANSIColor works.
}

# These additional modules are required to run the test scripts ...
# Support for this added in $ExtUtils::MakeMaker::VERSION >= 6.55_03.
my %build = ( ExtUtils::MakeMaker   => 6.30,
              File::Spec            => 0,
              File::Copy            => 0,
              Test::Builder::Module => 0,
              Test::More            => 0.88
            );

# The NAME value controls both where to install the modules as well as what
# to call the distribution when "make dist" is run!
my $prog = 'full_developer_test.pl';
my %params = ( NAME           => 'Fred::Fish::DBUG',
               VERSION_FROM   => 'DBUG.pm',      # Finds $VERSION
               PREREQ_PM      => \%requires,
               BUILD_REQUIRES => \%build,
               PL_FILES       => { "${prog}.src" => ${prog} }
             );
unlink ( $prog );

## Add these new keywords supported since 5.005
if ( $] >= 5.005 ) {
   $params{AUTHOR}   = 'Curtis Leach <cleach at cpan dot com>';
   $params{ABSTRACT} = 'Perl implementation of the Fred Fish C/C++ macros for Perl.';
}

## An Extra Kwalitee Metric setting.
if ( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
   $params{LICENSE} = 'perl';
}

## An Extra Kwalitee Metric setting.
## The earliest release of Perl I've personally tested this module with!
## Comment out this section out if you wish to try it with an earlier release!
if ( $ExtUtils::MakeMaker::VERSION >= 6.48 ) {
   $params{MIN_PERL_VERSION} = '5.014000';      # Perl Version 5.14.0
   $params{MIN_PERL_VERSION} = '5.008008';      # Perl Version 5.8.8
}

WriteMakefile ( %params );

