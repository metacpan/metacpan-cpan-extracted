package DracPerl::Factories::DellDefaultCommand;

use MooseX::AbstractFactory;

implementation_class_via sub { 'DracPerl::Models::Commands::DellDefault::' . ucfirst(shift) };

1;