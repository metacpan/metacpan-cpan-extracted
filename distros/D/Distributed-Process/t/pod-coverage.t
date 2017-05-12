#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
if ( $@ ) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage";
}
else {
    plan tests => 9;
}
pod_coverage_ok('Distributed::Process');
$trustme = { trustme => [ qr/^new$/ ] };
pod_coverage_ok('Distributed::Process::Server', $trustme);
pod_coverage_ok('Distributed::Process::BaseWorker', $trustme);
pod_coverage_ok('Distributed::Process::Interface', $trustme);

# Subclasses of P::D::Interface
push @{$trustme->{trustme}}, qr/^(?:command_handlers|(?:in_|out_)?handle)$/;
pod_coverage_ok('Distributed::Process::Master', $trustme);
pod_coverage_ok('Distributed::Process::Client', $trustme);

# Subclasses of P::D::BaseWorker
$trustme = { trustme => [ qr/^(?:new|synchro|run|postpone|time|result)$/ ] };
pod_coverage_ok('Distributed::Process::LocalWorker', $trustme);
pod_coverage_ok('Distributed::Process::Worker', $trustme);

# P::D::RemoteWorker is also a P::D::Interface
TODO:{
    local $TODO = "Distributed::Process::RemoteWorker not documented yet";
    push @{$trustme->{trustme}}, qr/^(?:command_handlers|(?:in_|out_)?handle)$/;
    pod_coverage_ok('Distributed::Process::RemoteWorker', $trustme);
}
