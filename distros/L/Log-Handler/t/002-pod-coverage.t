use strict;
use warnings;
use Test::More;
eval "use Test::Pod::Coverage";

if ($@) {
    plan skip_all => "Test::Pod::Coverage required for testing pod coverage";
    exit 0;
}

my @modules = qw(
    Log::Handler::Output
    Log::Handler::Pattern
    Log::Handler::Output
    Log::Handler::Output::Forward
    Log::Handler::Output::File
    Log::Handler::Output::Sendmail
    Log::Handler::Output::Socket
    Log::Handler::Output::Screen
    Log::Handler::Levels
    Log::Handler
);

eval "use Config::Properties";

if (!$@) {
    push @modules, "Log::Handler::Plugin::Config::Properties";
}

eval "Config::General";

if (!$@) {
    push @modules, "Log::Handler::Plugin::Config::General";
}

eval "YAML";

if (!$@) {
    push @modules, "Log::Handler::Plugin::YAML";
}

eval "DBI";

if (!$@) {
    push @modules, "Log::Handler::Output::DBI";
}

eval "use Email::Date; use Net::SMTP";

if (!$@) {
    push @modules, "Log::Handler::Output::Email";
}

plan tests => scalar @modules;

foreach my $mod (@modules) {
    pod_coverage_ok($mod, "$mod is covered");
}
