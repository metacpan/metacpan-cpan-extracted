package Javonet::Core::Receiver::Receiver;
use strict;
use warnings;
use Config;
use File::Basename;

use Exporter qw(import);
our @EXPORT = qw(heart_beat send_command get_runtime_info);

my $perlLibDirJavonet;
my $perlLibDirDeps;

BEGIN {
    my $thisFileDir = dirname(__FILE__);
    $perlLibDirJavonet = "$thisFileDir/../../../";
    $perlLibDirDeps = "$thisFileDir/../../../../deps/lib/perl5"
}

use lib "$perlLibDirJavonet";
use lib "$perlLibDirDeps";
#use Nice::Try; Try-catch statement causes unhandler exception in c++
use aliased 'Javonet::Core::Interpreter::Interpreter' => 'Interpreter';
use aliased 'Javonet::Sdk::Core::RuntimeLogger' => 'RuntimeLogger';
use aliased 'Javonet::Core::Exception::ExceptionSerializer' => 'ExceptionSerializer';
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Sdk::Core::PerlCommandType' => 'Javonet::Sdk::Core::PerlCommandType';
use aliased 'Javonet::Sdk::Core::RuntimeLib' => 'Javonet::Sdk::Core::RuntimeLib';
use aliased 'Javonet::Core::Protocol::CommandSerializer' => 'CommandSerializer';
#use aliased 'Javonet::Core::Exception::Exception' => 'Exception';


sub heart_beat {
    my ($class, $message_byte_array_ref) = @_;
    my @response_byte_array = (49, 48);
    return \@response_byte_array;
}

sub send_command {
    my ($class, $message_byte_array_ref) = @_;
    my @message_byte_array = @$message_byte_array_ref;
    my @response_byte_array;
#    try {
        @response_byte_array = Javonet::Core::Interpreter::Interpreter->process(\@message_byte_array);
#    }
#    catch ( $e ) {
#        my $exception = Exception->new($e);
#        my $exception_command = Javonet::Core::Exception::ExceptionSerializer->serialize($exception);
#        @response_byte_array = CommandSerializer->serialize($exception_command, 0, 0, 0);
#    };

    return \@response_byte_array;


}

sub get_runtime_info {
    my ($class) = @_;
    return RuntimeLogger->rl_get_runtime_info();
}

1;
