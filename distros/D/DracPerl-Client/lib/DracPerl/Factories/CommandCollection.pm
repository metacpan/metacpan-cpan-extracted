package DracPerl::Factories::CommandCollection;

use MooseX::AbstractFactory;

implementation_class_via
    sub { 'DracPerl::Models::Commands::Custom::' . ucfirst(shift) };

1;
