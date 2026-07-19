use strict;
use Test::More 0.98;

use_ok $_ for qw(
    GraphQL::Houtou
    GraphQL::Houtou::Schema
    GraphQL::Houtou::Directive
    GraphQL::Houtou::Role::Input
    GraphQL::Houtou::Role::Output
    GraphQL::Houtou::Role::Composite
    GraphQL::Houtou::Role::Abstract
    GraphQL::Houtou::Role::Leaf
    GraphQL::Houtou::Role::Named
    GraphQL::Houtou::Role::FieldsEither
    GraphQL::Houtou::Role::FieldsInput
    GraphQL::Houtou::Role::FieldsOutput
    GraphQL::Houtou::Role::FieldDeprecation
    GraphQL::Houtou::Role::HashMappable
    GraphQL::Houtou::Type
    GraphQL::Houtou::Type::Object
    GraphQL::Houtou::Type::Interface
    GraphQL::Houtou::Type::Union
    GraphQL::Houtou::Type::InputObject
    GraphQL::Houtou::Type::Enum
    GraphQL::Houtou::Type::List
    GraphQL::Houtou::Type::NonNull
    GraphQL::Houtou::Type::Scalar
    GraphQL::Houtou::Promise::PromiseXS
    GraphQL::Houtou::Validation
    GraphQL::Houtou::Runtime::OperationCompiler
    GraphQL::Houtou::Runtime::SchemaGraph
    GraphQL::Houtou::Runtime::SchemaBlock
    GraphQL::Houtou::Runtime::ExecState
    GraphQL::Houtou::Runtime::VMCompiler
    GraphQL::Houtou::Runtime::NativeRuntime
);

done_testing;
