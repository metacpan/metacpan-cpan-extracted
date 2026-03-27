package ServiceTest;
use Test2::V1 -ip;
use IPC::Manager qw/ipcm_service ipcm_default_protocol/;

note("Using $main::PROTOCOL");
ipcm_default_protocol($main::PROTOCOL);

my $parent_pid = $$;

my $got_req = 0;
my $handle = ipcm_service foo => sub {
    my $self = shift;
    my ($activity) = @_;

    return if $activity->{interval} && keys(%$activity) == 1;

    if (my $msgs = $activity->{messages}) {
        for my $msg (@$msgs) {
            my $c = $msg->content;

            if (ref($c) eq 'HASH') {
                if ($c->{ipcm_request_id}) {
                    $got_req = 1;
                    is($msg->content->{request}, "${parent_pid} blah?", "Got request from parent pid");
                    $self->send_response($msg->from, $c->{ipcm_request_id}, "$$ blah!");
                }
                elsif($c->{terminate}) {
                    ok($got_req, "$$ Got the request!");
                }
            }
        }
    }
};

my $service_pid = $handle->service_pid;

my $got_resp = 0;
$handle->send_request(
    foo => "$$ blah?",
    sub {
        my ($resp, $msg) = @_;
        $got_resp = 1;
        is($msg->content->{response}, "${service_pid} blah!", "Got expected response");
    }
);

$handle->await_all_responses;

ok($got_resp, "Got response!");

eval { $handle = undef; 1 } or die "XXX: $@";

1;
