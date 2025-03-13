package Javonet::Core::Handler::CommandHandler::InvokeGlobalFunctionHandler;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Moose;
use Nice::Try;
use aliased 'Javonet::Core::Exception::Exception' => 'Exception';
extends 'Javonet::Core::Handler::CommandHandler::AbstractCommandHandler';

sub new {
    my $class = shift;
    my $self = {
        required_parameters_count => 1
    };
    return bless $self, $class;
}

sub process {
    my ($self, $command) = @_;
    try {
        # Get the payload array reference and convert to array
        my $payload_ref = $command->{payload};
        my @payload = @$payload_ref;
        my $parameters_length = scalar @payload;

        # Verify at least one parameter is provided
        if ($parameters_length < $self->{required_parameters_count}) {
            die Exception->new("InvokeGlobalFunctionHandler parameters mismatch: requires at least one parameter (fully qualified method name)");
        }

        # The first parameter should be the fully qualified method name
        my $fully_qualified_method = $payload[0];

        # Extract the package name and method name using a regex
        unless ($fully_qualified_method =~ /^(.*)::([^:]+)$/) {
            die Exception->new("Invalid fully qualified method name: $fully_qualified_method");
        }
        my ($package, $function_name) = $fully_qualified_method =~ /^(.*)::([^:]+)$/;

        # Attempt to load the package (if not already loaded)
        eval "require $package";
        if ($@) {
            die Exception->new("Failed to load package '$package': $@");
        }
        #
        # Check if the package can perform the method
        my $code_ref = $package->can($function_name);
        unless ($code_ref) {
            die Exception->new("Method '$function_name' not found in package '$package'");
        }

        # Any additional payload elements are passed as arguments to the method
        my @args = @payload[1 .. $#payload];

        # Invoke the method with the arguments and return the result
        return $code_ref->(@args);
    }
    catch ($e) {
        return Exception->new($e);
    }
}

1;