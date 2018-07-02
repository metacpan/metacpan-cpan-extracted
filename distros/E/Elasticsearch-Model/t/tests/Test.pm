package Test;

use Test::Class::Most attributes => [qw/live_testing_ok/];
use Module::Find;
use IO::Socket::INET;
use lib 't/lib';
use TestModel;
use TestDocumentNamespaceModel;
useall TestModel;
useall OtherTestModelClasses;
useall TestDocumentNamespaceModel;

sub startup  : Tests(startup)  {
    my $self = shift;
    my $bind_to = $ENV{ES} || '127.0.0.1:9200';
    my $live_testing_ok = IO::Socket::INET->new($bind_to);
    $self->live_testing_ok($live_testing_ok ? 1 : 0);
}
sub setup    : Tests(setup)    {}
sub teardown : Tests(teardown) {}
sub shutdown : Tests(shutdown) {}

1;
