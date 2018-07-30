package Test;

use Test::Class::Most attributes => [qw/live_testing_ok/];
use Module::Find;
use IO::Socket::INET;
use IPC::System::Simple qw/capturex/;
use lib 't/lib';
use TestModel;
use TestDocumentNamespaceModel;
useall TestModel;
useall OtherTestModelClasses;
useall TestDocumentNamespaceModel;

sub startup  : Tests(startup)  {
    my $self = shift;
    $ENV{TESTING_ELASTICSEARCH_MODEL} = 1;
    my $bind_to = $ENV{ES} || '127.0.0.1:9200';
    my ($live_testing_ok,$version_ok,$server_running);
    $server_running = IO::Socket::INET->new($bind_to);
    if ($server_running) {
        $ENV{'PATH'} = '/bin:/usr/bin';
        delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
        my $es_version = capturex("curl","-s","-q","-c","-XGET", "$bind_to/_cat/nodes?h=version");
        chomp $es_version;
        $es_version =~ m/^(\d).*$/;
        $es_version = $1;
        $version_ok = ($es_version >= 6) ? 1 : 0;
    }
    $self->live_testing_ok(($server_running and $version_ok)? 1 : 0);
}
sub setup    : Tests(setup)    {}
sub teardown : Tests(teardown) {}
sub shutdown : Tests(shutdown) {}

1;
