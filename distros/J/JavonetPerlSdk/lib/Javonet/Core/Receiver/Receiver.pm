package Javonet::Core::Receiver::Receiver;
use strict;
use warnings;
use Config;
use File::Basename;

my $perlLibDirJavonet;
my $perlLibDirDeps;

BEGIN {
    my $thisFileDir = dirname(__FILE__);
    $perlLibDirJavonet = "$thisFileDir/../../../";
    $perlLibDirDeps = "$thisFileDir/../../../../deps/lib/perl5"
}

use lib "$perlLibDirJavonet";
use lib "$perlLibDirDeps";
use aliased 'Javonet::Core::Interpreter::Interpreter' => 'Interpreter', qw(process);
use aliased 'Javonet::Sdk::Core::RuntimeLogger' => 'RuntimeLogger', qw(print_runtime_info);


BEGIN {
    RuntimeLogger->print_runtime_info();
}

sub heart_beat {
    my ($self, $message_byte_array_ref) = @_;
    my @response_byte_array = (49, 48);
    return \@response_byte_array;
}

sub send_command {
    my ($self, $message_byte_array_ref) = @_;
    my @message_byte_array = @$message_byte_array_ref;
    my @response_byte_array = Javonet::Core::Interpreter::Interpreter->process(\@message_byte_array);
    return \@response_byte_array;
}

1;
