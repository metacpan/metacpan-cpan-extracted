# bundle.pl to conditionally install a bundled submodule

package Sys::CpuLoadX;
use ExtUtils::MakeMaker;
use strict;
use warnings;

my $buildClass = 'Sys::CpuLoadX::Custom::Builder';
my $SuperModule = 'Forks::Super';
my $TargetModule = 'Sys::CpuLoadX';
my $TargetModuleMinVersion = '0.01';
if ($^O =~ /netbsd/i) {
    # NetBSD fix in 0.03
    $TargetModuleMinVersion = '0.03';
}


my $version = MM->parse_version('lib/Sys/CpuLoadX.pm');

my $TargetModulePitch = qq[

The Sys::CpuLoadX module provides a (cross-fingers) portable way
to access your system's current CPU load. The Forks::Super module
can use this information to decide whether your system is too
busy to launch more background processes. Without Sys::CpuLoadX,
Forks::Super will not make use of CPU load information.

Installation of this module is entirely optional. The  Module::Build
module is required to install this module. The installation of
Forks::Super will proceed even if the installation of Sys::CpuLoadX
is unsuccessful.
]; 

my $TargetModulePrompt 
    = "Do you want to attempt to install Sys::CpuLoadX v$version?";

my $TargetModulePromptDefault = 'y'; # was 'n' before Forks::Super v0.39
my $TargetModuleDeclineMessage =
    qq[Some features of $SuperModule may not be available.\n];

sub run_auto_generated_Makefile_PL {
    unless (eval "use Module::Build::Compat 0.02; 1" ) {
	print "This module requires Module::Build to install itself.\n";

	require ExtUtils::MakeMaker;
	my $yn = ExtUtils::MakeMaker::prompt
	    ('  Install Module::Build now from CPAN?', 'y');

	unless ($yn =~ /^y/i) {
	    die " *** Cannot install without Module::Build.  Exiting ...\n";
	}

	require Cwd;
	require File::Spec;
	require CPAN;

	# Save this 'cause CPAN will chdir all over the place.
	my $cwd = Cwd::cwd();

	CPAN::Shell->install('Module::Build::Compat');
	CPAN::Shell->expand("Module", "Module::Build::Compat")->uptodate
	    or die "Couldn't install Module::Build, giving up.\n";

	chdir $cwd or die "Cannot chdir() back to $cwd: $!";
    }
    eval "use Module::Build::Compat 0.02; 1" or die $@;
    use lib '_build/lib';
    Module::Build::Compat->run_build_pl(args => \@ARGV);
    my $build_script = 'Build';
    $build_script .= '.com' if $^O eq 'VMS';
    exit(0) unless(-e $build_script); # cpantesters convention

    eval "require $buildClass"; die $@ if $@;
    Module::Build::Compat->write_makefile(build_class => $buildClass);

}

do '../conditionally-install-submodule.pl';
&conditionally_install_submodule
(
  superModule => $SuperModule,
  targetModule => $TargetModule,
  minVersion => $TargetModuleMinVersion,
  pitch => $TargetModulePitch,
  prompt => $TargetModulePrompt,
  promptDefault => $TargetModulePromptDefault,
  declineMessage => "Some features of Forks::Super may not be available",
  force => scalar(grep { /force/ } @ARGV),
  reinstall => $ENV{BUNDLE_REINSTALL}
);


