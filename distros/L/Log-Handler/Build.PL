use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_readme      => 1,
    create_makefile_pl => "traditional",
    license            => "perl",
    module_name        => "Log::Handler",
    dist_author        => "Jonny Schulz",
    sign               => 0,
    recommends         => {
        "Config::General"    => 0,
        "Config::Properties" => 0,
        "DBI"                => 0,
        "IO::Socket"         => 0,
        "Net::SMTP"          => 0,
        "Email::Date"        => 0,
        "YAML"               => 0,
    },
    requires => {
        "Carp"               => 0,
        "Data::Dumper"       => 0,
        "Fcntl"              => 0,
        "File::Spec"         => 0,
        "Params::Validate"   => 0,
        "POSIX"              => 0,
        "Test::More"         => 0,
        "Time::HiRes"        => 0,
        "Sys::Hostname"      => 0,
        "UNIVERSAL"          => 0,
    },
);

$build->create_build_script;
