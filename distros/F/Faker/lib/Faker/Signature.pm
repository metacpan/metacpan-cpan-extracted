package Faker::Signature;

use parent 'Function::Parameters';

our $VERSION = '0.12'; # VERSION

@Function::Parameters::type_reifiers = (
    *_reify_type_default = sub {
        require Faker::Type;
        require Type::Registry;
        my $registry = Type::Registry->for_me;
           $registry->add_types(-Standard);
           $registry->add_types('Faker::Type');
           $registry->lookup($_[0]);
    }
);

1;
