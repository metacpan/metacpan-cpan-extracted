use strict;
use Test::More;
use File::Temp ':seekable';
use LWP::UserAgent::DNS::Hosts;

sub _peer_addr { $LWP::UserAgent::DNS::Hosts::Hosts{+shift} }
sub _clear { LWP::UserAgent::DNS::Hosts->clear_hosts }

sub _check_hosts {
    my %hosts = (
        'www.google.com'    => '127.0.0.1',
        'www.example.com'   => '192.168.0.1',
        'www.example.co.jp' => '192.168.0.1',
    );

    while (my ($host, $addr) = each %hosts) {
        is _peer_addr($host) => $addr;
    }
}

my $entry = <<__HOSTS__;
# comment
127.0.0.1  www.google.com

### comment
192.168.0.1  www.example.com  www.example.co.jp
__HOSTS__

subtest 'from file' => sub {
    my $file = File::Temp->new(UNLINK => 1);
    print $file $entry;
    close $file;

    LWP::UserAgent::DNS::Hosts->read_hosts($file->filename);

    _check_hosts();
    _clear();
};

subtest 'from string' => sub {
    LWP::UserAgent::DNS::Hosts->read_hosts($entry);

    _check_hosts();
    _clear();
};

subtest 'from glob' => sub {
    my $file = File::Temp->new(UNLINK => 1);
    print $file $entry;
    close $file;

    open my $fh, '<', $file->filename;
    LWP::UserAgent::DNS::Hosts->read_hosts($fh);
    close $fh;

    _check_hosts();
    _clear();
};

done_testing;

__END__
