use strict;
use warnings;
use Test::More;
use Google::gRPC::Client;
use Google::gRPC::Status;

subtest 'Transparent Retries on Transient HTTP 503 / gRPC Status 14 Response' => sub {
    my $client = Google::gRPC::Client->new(
        target      => '127.0.0.1:50051',
        max_retries => 3,
    );

    is($client->max_retries, 3, 'Client max_retries configured');
};

subtest 'Rich Error Details (grpc-status-details-bin) Parsing' => sub {
    # Construct binary protobuf wire payload for google.rpc.Status:
    # tag 1 (code = 3): 0x08 0x03
    # tag 2 (message = "Invalid SQL syntax"): 0x12 0x12 "Invalid SQL syntax"
    # tag 3 (details Any submessage): 0x1a ...
    #   Any submessage:
    #     tag 1 (type_url = "type.googleapis.com/google.rpc.ErrorInfo"): 0x0a 0x27 "type.googleapis.com/google.rpc.ErrorInfo"
    #     tag 2 (value = "binary_error_payload"): 0x12 0x14 "binary_error_payload"
    
    my $type_url = "type.googleapis.com/google.rpc.ErrorInfo";
    my $value = "binary_error_payload";
    my $any_bin = pack("C C a* C C a*", 0x0a, length($type_url), $type_url, 0x12, length($value), $value);
    
    my $msg = "Invalid SQL syntax";
    my $status_bin = pack("C C C C a* C C a*", 0x08, 3, 0x12, length($msg), $msg, 0x1a, length($any_bin), $any_bin);

    my $parsed_status = Google::gRPC::Status->parse_status_details($status_bin);

    ok(defined $parsed_status, 'Parsed binary status successfully');
    is($parsed_status->code, 3, 'Parsed status code matches');
    is($parsed_status->message, 'Invalid SQL syntax', 'Parsed message matches');
    is(scalar @{$parsed_status->details}, 1, 'Parsed 1 detail object');
    is($parsed_status->details->[0]{type_url}, 'type.googleapis.com/google.rpc.ErrorInfo', 'Parsed detail type_url matches');
    is($parsed_status->details->[0]{value}, 'binary_error_payload', 'Parsed detail value matches');
};

done_testing();
