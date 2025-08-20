use strict;
use warnings;
use lib 'lib';
use aliased 'Javonet::Core::Receiver::Receiver' => 'Receiver';
use Test::More qw(no_plan);
use Config;
use Cwd;

my @message_byte_array = (4, 0, 0, 0, 0, 0, 0, 0, 0, 4, 11);
my $expected = "Perl Managed Runtime Info:\n" .
    "Perl Version: $]\n" .
    "Perl executable path: $^X\n" .
    "Perl \\@INC Path: @INC\n" .
    "OS Version: $Config{osname} $Config{osvers}\n" .
    "Process Architecture: $Config{archname}\n" .
    "Current Working Directory: " . getcwd() . "\n";

is_deeply(Receiver->heart_beat(@message_byte_array), [49, 48], 'heart beat test');
is(Receiver->get_runtime_info(), $expected, 'get runtime info test');

# it is commented out because it requires exception throwing in Receiver.pm which is not implemented yet due to problem with c++ (see comment in Receiver.pm)
# my @invalid_message_byte_array = (3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 49, 50);
# my $response_byte_array_ref = Receiver->send_command(\@invalid_message_byte_array);
# my $response_as_string = '';
# if ($response_byte_array_ref && @$response_byte_array_ref) {
#     $response_as_string = join('', map { chr($_) } @$response_byte_array_ref);
# }
#
# ok(defined $response_as_string, 'response is defined');
# like($response_as_string, qr/(Exception|Error)/, 'response contains Exception or Error');
# like($response_as_string, qr/49/, 'response contains "49"');
1;
