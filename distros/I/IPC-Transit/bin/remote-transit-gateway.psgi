#!plackup

use strict;use warnings;
use Dancer2::Core::Route;
use Data::Dumper;
use Plack::Request;
use IPC::Transit::Remote;

$| = 1;

{
my $done;
sub set_env {
    return if $done;
    my $env = $ENV{PLACK_ENV};
    if($env and $env eq 'cpan') {
        $done = 1;
        $IPC::Transit::config_dir = '/tmp/ipc_transit_test';
    } elsif($env and $env eq 'cpan-proxy') {
        $done = 1;
        $IPC::Transit::config_dir = '/tmp/ipc_transit_test';

        $IPC::Transit::Remote::config->{proxy_callback} = sub {
            return 1;
        };
    }
}
}

my $app = sub {
    my $env = shift;
    open my $fh, '>', '/tmp/app';
    print $fh "app\n";
    close $fh;
    set_env();
    my $req = Plack::Request->new($env);
    my $ref = {
        serialized_wire_data => ''
    };
    #It might also be useful for backwards compability, but at this point,
    #I'm srsly thinking about doing this change 'whole'
    my $transit_sending_host = $env->{HTTP_TRANSIT_SENDING_HOST};
    read $env->{'psgi.input'}, $ref->{serialized_wire_data}, 102400000;
    my ($message_ct, $total_length) = IPC::Transit::Remote::handle_raw_messages($ref);
    my $return_serialized_wire_data = IPC::Transit::Remote::get_proxy_send($transit_sending_host);
    return [ 200, [ 'Content-Type' => 'text/plain'], [$return_serialized_wire_data] ];
};

