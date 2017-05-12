# routines to conditionally install a bundled submodule
# expect this file to be required'd from a submodule's Makefile.PL
# expect the submodule to use Module::Build and Build.PL
# expect the caller to define:
#
#   &run_auto_generated_Makefile_PL 
#         (from default Makefile.PL created by Build.PL)
#
# this script automatically cleans up after itself (calls 'Build clean'),
# whether or not the installation was successful. To debug a submodule
# installation, change into the submodule's directory and run
# "perl Build.PL", "./Build", etc.  yourself.
#

use ExtUtils::MakeMaker;
use strict;
use warnings;

my ($SuperModule, $TargetModule, $TargetModuleVersion,
    $TargetModuleMinVersion, $TargetModulePitch, $TargetModulePrompt,
    $TargetModulePromptDefault, $TargetModuleDeclineMessage,
    $forceInstall, $reinstallOk);

sub conditionally_install_submodule {

    my %params = @_;

    print "@_" if $ENV{BUILD_DEBUG};


    $SuperModule = $params{"superModule"} || "the super module";
    $TargetModule = $params{"targetModule"} || die "targetModule required";
    $TargetModuleMinVersion = $params{"minVersion"} || undef;
    $TargetModulePitch = $params{"pitch"} 
        || "$TargetModule is available for installation.\n";
    $TargetModulePrompt = $params{"prompt"}
        || "Do you want to install $TargetModule? ";
    $TargetModulePromptDefault = $params{"promptDefault"} || 'n';
    $TargetModuleDeclineMessage = $params{"declineMessage"} || "";
    $forceInstall = $params{"force"} || 0;
    $reinstallOk = $params{"reinstall"} || 0;

    if (!check_install_is_necessary()) {
	print "Installation of $TargetModule is not necessary.\n";
	return 1;
    }
    if (!check_install_is_desired()) {
	print "$TargetModule will not be installed.\n";
	print $TargetModuleDeclineMessage, "\n";
	return 1;
    }

    &build_and_install_submodule;
    return;
}

1;

sub check_install_is_necessary {
    local $@;
    eval {
	eval "require $TargetModule"; die $@ if $@;
	$TargetModuleVersion = eval '$' . $TargetModule . '::VERSION';
	$TargetModulePromptDefault = 'yes';
	die if $TargetModuleMinVersion
	    && $TargetModuleVersion lt $TargetModuleMinVersion;
	$TargetModulePromptDefault = 'no';
	if (defined $TargetModuleVersion) {
	    print "$TargetModule v$TargetModuleVersion is already installed.\n";
	}
    };
    if ($forceInstall) {
	print "Forcing install/reinstall of $TargetModule.\n";
	$TargetModulePromptDefault = 'always';
	return 1;
    } elsif (!$@ && $reinstallOk == 0) {
	return 0;
    }
    return 1;
}

sub check_install_is_desired {
    print $TargetModulePitch;
    my $answer;
    while (1) {
	print "\n";
	$answer = $TargetModulePromptDefault eq 'always' 
	    ? 'yes' : prompt($TargetModulePrompt, $TargetModulePromptDefault);
	last if $answer =~ /^[ynq]/i;
    }

    print "\n";
    if ($answer =~ /^n/i || $answer =~ /^q/i) {
	return 0;
    }
    return 1;
}

sub build_and_install_submodule {

    my $Build_cmd = $^O eq 'MSWin32' ? "$^X Build" : './Build';
    unlink "Build", "Build.bat";

    local $@ = undef;
    eval {
	&run_auto_generated_Makefile_PL;
    };
    if ($@) { print $@;  }
    return 0 if $@;

    $ENV{BUILD_EVEN_IF_AUTOMATED_TESTING} = 1;
    if (system("$Build_cmd") 
	|| system("$Build_cmd test") 
	|| system("$Build_cmd install")) {

	clean($Build_cmd);

	unlink "Makefile", "./Build", "./Build.bat";
	print "\n$TargetModule installation failed. ",
		"Continuing with $SuperModule build.\n";
	return 0;
    } else {

	clean($Build_cmd);

	unlink "Makefile", "./Build", "./Build.bat";
	print "\n$TargetModule successfully installed. ",
		"Continuing with $SuperModule build.\n";
	return 1;
    }
}

sub clean {
    my ($Build_cmd) = @_;

    system("$Build_cmd clean");
}


