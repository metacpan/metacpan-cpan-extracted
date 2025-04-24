package Javonet::Sdk::Core::RuntimeLogger;
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT = qw(rl_get_runtime_info print_runtime_info);

use Config qw(%Config);
use Cwd;
use Sys::Hostname;

my $not_logged_yet = 1;

sub rl_get_runtime_info {
    my $info;
    eval {
        $info = "Perl Managed Runtime Info:\n" .
            "Perl Version: $]\n" .
            "Perl executable path: $^X\n" .
            "Perl \\@INC Path: @INC\n" .
            "OS Version: " . $Config{osname} . " " . $Config{osvers} . "\n" .
            "Process Architecture: " . $Config{archname} . "\n" .
            "Current Working Directory: " . getcwd() . "\n";
    };
    if ($@) {
        $info = "Perl Managed Runtime Info:\n Error while fetching runtime info";
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