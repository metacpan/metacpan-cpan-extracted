package Javonet::Sdk::Core::PerlCommand;
use strict;
use warnings;
use lib 'lib';
use Moose;
use Scalar::Util;

has 'runtime' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    reader => '_get_runtime'
);

has 'command_type' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
    reader   => '_get_command_type'
);

has 'payload' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {[]},
    writer  => '_set_payload',
    reader  => '_get_payload'
);

sub addArgumentToPayload{
    my ($self, $payload_ref) = @_;
    my @payload_array = @$payload_ref;
    my $firstVar = $self->{payload}[0];
    my @merged_payload;
    if (!defined $firstVar){
        @merged_payload = @payload_array;
    }
    else{
        my $current_payload_ref = $self->{payload};
        my @cur_payload = @$current_payload_ref;
        @merged_payload = (@cur_payload, @payload_array);
    }
    return Javonet::Sdk::Core::PerlCommand->new(runtime => $self->{runtime}, command_type => $self->{command_type}, payload => \@merged_payload);
}

# sub size{
#     my ($self) = @_;
#     my $command_size = 0;
#     my $current_payload_ref = $self->{payload};
#     my @cur_payload = @$current_payload_ref;
#     for (my $i = 0; $i < @cur_payload; $i++) {
#         if ($cur_payload[$i]->isa("Javonet::Sdk::Core::PerlCommand")) {
#             $command_size += $cur_payload[$i]->size();
#         }
#         if (Scalar::Util::looks_like_number($cur_payload[$i])){
#             $command_size += 4
#         }
#         if ( ! defined $cur_payload[$i]){
#             # undefined
#             $command_size += 0;
#         }
#         elsif ( ref $cur_payload[$i] ) {
#             # reference (return of ref will give the type)
#             $command_size += 0;
#         }
#         else{
#             $command_size += length($cur_payload[$i]);
#         }
#     }
#     return $command_size;
# }

sub drop_first_payload_argument {
    my ($self) = @_;
    my $current_payload_ref = $self->{payload};
    my @cur_payload = @$current_payload_ref;
    my $payload_length = @cur_payload;
    if ($payload_length != 0){
        shift(@cur_payload);
    }
    return Javonet::Sdk::Core::PerlCommand->new(runtime => $self->{runtime}, command_type => $self->{command_type}, payload => \@cur_payload);

}

sub prepend_arg_to_payload{
    my ($self, $current_command) = @_;
    my $current_payload_ref = $self->{payload};
    my @cur_payload = @$current_payload_ref;
    my @merged_payload;
    if(defined $current_command) {
        @merged_payload = ($current_command, @cur_payload);
    } else {
        @merged_payload = @cur_payload;
    }

    return Javonet::Sdk::Core::PerlCommand->new(runtime => $self->{runtime}, command_type => $self->{command_type}, payload => \@merged_payload);
}

no Moose;

1;
