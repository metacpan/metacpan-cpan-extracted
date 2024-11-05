package Javonet::Sdk::Core::RuntimeLogger;
use strict;
use warnings;
use Config qw(%Config);
use Cwd;
use Sys::Hostname;

our $not_logged_yet = 1;

sub get_runtime_info {
    my $info;
    eval {
        $info = "Perl Managed Runtime Info:\n" .
            "Perl Version: $]\n" .
            "Perl executable path: $^X\n" .
            "Perl \@INC Path: @INC\n" .
            "OS Version: " . $Config{osname} . " " . $Config{osvers} . "\n" .
            "Process Architecture: " . $Config{archname} . "\n" .
            "Current Directory: " . getcwd() . "\n";
    };
    if ($@) {
        $info = "Perl Managed Runtime Info: Error while fetching runtime info";
    }
    return $info;
}

sub print_runtime_info {
    if ($not_logged_yet) {
        print get_runtime_info();
        $not_logged_yet = 0;
    }
}

1;