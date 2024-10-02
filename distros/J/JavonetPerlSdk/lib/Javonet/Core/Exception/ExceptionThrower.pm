package Javonet::Core::Exception::ExceptionThrower;
use strict;
use warnings FATAL => 'all';
use Moose;
use Nice::Try;
use aliased 'Javonet::Core::Exception::Exception' => 'Exception';
use lib 'lib';


sub throwException {
    my ($self, $exception_command) = @_;
    my $exception_name = $exception_command->{payload}[2];
    my $exception_message =$exception_name . "\n " . $exception_command->{payload}[3];
    my $stack_trace = "";
    if (defined($exception_command->{payload}[4])){
        $stack_trace = create_stack_trace($exception_command->{payload}[4], $exception_command->{payload}[5], $exception_command->{payload}[6], $exception_command->{payload}[7]);
    }
    my $exception_msg = $exception_name . " \n " . $exception_message . " \n " .$stack_trace;
    die $exception_msg;
}

sub create_stack_trace {
    my ($stack_trace_classes, $stack_trace_methods, $stack_trace_lines, $stack_trace_files) = @_;
    my @classes = split /\|/, $stack_trace_classes;
    my @methods = split /\|/, $stack_trace_methods;
    my @lines = split /\|/, $stack_trace_lines;
    my @files = split /\|/, $stack_trace_files;

    my $stack_trace = "";
    for (my $i = 0; $i < scalar(@classes); $i++) {
        $stack_trace .= "  at $methods[$i] ";
        $stack_trace .= "($files[$i] line $lines[$i])";
        $stack_trace .= "\n";
    }

    return $stack_trace;
}

no Moose;
1;