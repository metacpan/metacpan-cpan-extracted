package Javonet::Core::Handler::CommandHandler::LoadLibraryHandler;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Moose;
use File::Basename;
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
        my $current_payload_ref = $command->{payload};
        my @cur_payload = @$current_payload_ref;
        my $parameters_length = @cur_payload;
        if ($parameters_length != $self->{required_parameters_count}) {
            die Exception->new("Exception: LoadLibrary parameters mismatch");
        }
        my $path_to_file = $command->{payload}[0];
        my $path_to_file_dir = dirname($path_to_file);
        my $file_name = basename($path_to_file);

        push(@INC, "$path_to_file_dir");
        eval(require $file_name);
        return 0;
    }
    catch ( $e ) {
        return Exception->new($e);
    }
}

no Moose;
1;
