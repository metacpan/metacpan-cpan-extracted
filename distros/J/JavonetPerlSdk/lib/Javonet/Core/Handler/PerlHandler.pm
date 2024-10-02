package Javonet::Core::Handler::PerlHandler;
use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Moose;
use aliased 'Javonet::Core::Handler::CommandHandler::ValueHandler' => 'ValueHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::LoadLibraryHandler' => 'LoadLibraryHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::GetStaticFieldHandler' => 'GetStaticFieldHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::SetStaticFieldHandler' => 'SetStaticFieldHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::CreateClassInstanceHandler' => 'CreateInstanceHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::InvokeInstanceMethodHandler' => 'InvokeInstanceMethodHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::InvokeStaticMethodHandler' => 'InvokeStaticMethodHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::ResolveInstanceHandler' => 'ResolveInstanceHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::GetTypeHandler' => 'GetTypeHandler';
use aliased 'Javonet::Core::Exception::Exception' => 'Exception';
use aliased 'Javonet::Core::Handler::CommandHandler::CastingHandler' => 'CastingHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::GetInstanceFieldHandler' => 'GetInstanceFieldHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::SetInstanceFieldHandler' => 'SetInstanceFieldHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::DestructReferenceHandler' => 'DestructReferenceHandler';
use aliased 'Javonet::Core::Exception::ExceptionSerializer' => 'ExceptionSerializer';
use aliased 'Javonet::Core::Handler::CommandHandler::ArrayGetItemHandler' => 'ArrayGetItemHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::ArrayGetSizeHandler' => 'ArrayGetSizeHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::ArrayGetRankHandler' => 'ArrayGetRankHandler';
use aliased 'Javonet::Core::Handler::CommandHandler::ArraySetItemHandler' => 'ArraySetItemHandler';


use aliased 'Javonet::Sdk::Core::PerlCommandType' => 'PerlCommandType', qw(get_command_type);
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Core::Handler::ReferencesCache' => 'ReferencesCache';
use aliased 'Javonet::Core::Handler::AbstractHandler' => 'AbstractHandler';
use aliased 'Javonet::Sdk::Core::RuntimeLib' => 'RuntimeLib', qw(get_runtime);
use aliased 'Javonet::Core::Handler::HandlerDictionary' => 'HandlerDictionary', qw(get_handler);

my $value_handler = ValueHandler->new();
my $load_library_handler = LoadLibraryHandler->new();
my $get_static_field_handler = GetStaticFieldHandler->new();
my $set_static_field_handler = SetStaticFieldHandler->new();
my $create_instance_handler = CreateInstanceHandler->new();
my $invoke_instance_method_handler = InvokeInstanceMethodHandler->new();
my $invoke_static_method_handler = InvokeStaticMethodHandler->new();
my $resolve_instance_handler = ResolveInstanceHandler->new();
my $get_type_handler = GetTypeHandler->new();
my $casting_handler = CastingHandler->new();
my $get_instance_field_handler = GetInstanceFieldHandler->new();
my $set_instance_field_handler = SetInstanceFieldHandler->new();
my $destruct_reference_handler = DestructReferenceHandler->new();
my $array_get_item_handler = ArrayGetItemHandler->new();
my $array_get_size_handler = ArrayGetSizeHandler->new();
my $array_get_rank_handler = ArrayGetRankHandler->new();
my $array_set_item_handler = ArraySetItemHandler->new();


Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('Value'),
    $value_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('LoadLibrary'),
    $load_library_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('GetStaticField'),
    $get_static_field_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('SetStaticField'),
    $set_static_field_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('CreateClassInstance'),
    $create_instance_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('InvokeInstanceMethod'),
    $invoke_instance_method_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('InvokeStaticMethod'),
    $invoke_static_method_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('Reference'),
    $resolve_instance_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('GetType'),
    $get_type_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('Cast'),
    $casting_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('GetInstanceField'),
    $get_instance_field_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('SetInstanceField'),
    $set_instance_field_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('DestructReference'),
    $destruct_reference_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('ArrayGetItem'),
    $array_get_item_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('ArrayGetSize'),
    $array_get_size_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('ArrayGetRank'),
    $array_get_rank_handler
);
Javonet::Core::Handler::HandlerDictionary::add_handler_to_dict(
    Javonet::Sdk::Core::PerlCommandType::get_command_type('ArraySetItem'),
    $array_set_item_handler
);

sub handle_command {
    my ($self, $command) = @_;
    my $response = Javonet::Core::Handler::HandlerDictionary::get_handler($command->{command_type})->handle_command($command);

    if (!defined $response) {
        return PerlCommand->new(
            runtime      => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
            command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Value'),
            payload      => [ $response ]
        )
    }

    if (ref $response eq '') {
        return PerlCommand->new(
            runtime      => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
            command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Value'),
            payload      => [ $response ]
        )
    }
    # elsif (ref $response eq 'ARRAY') {
    #     {
    #         my $reference_cache = ReferencesCache->new();
    #         my $guid = $reference_cache->cache_reference($response);
    #         return PerlCommand->new(
    #             runtime      => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
    #             command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Reference'),
    #             payload      => [ $guid ]
    #         )
    #     }
    # }
    elsif (ref $response eq 'Javonet::Core::Exception::Exception') {
        return ExceptionSerializer->serialize($response)
    }
    else {
        my $reference_cache = ReferencesCache->new();
        my $guid = $reference_cache->cache_reference($response);
        return PerlCommand->new(
            runtime      => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
            command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('Reference'),
            payload      => [ $guid ]
        )
    }
}

no Moose;
1;
