package Finance::IBrokers::Types;

=head1 NAME

Finance::IBrokers::Types - Supporting data types for Finance::IBrokers::MooseCallback

=head1 VERSION

Version 0.01

=cut

use MooseX::Types -declare => [ qw( Contract Order OrderState ContractDetails Execution boolean long UnderComp) ];

use MooseX::Types::Moose qw(Str Int Object Bool Num Any);
#use MooseX::Types::DateTimeX qw( DateTime );
use MooseX::Types::URI qw(Uri FileUri DataUri);

subtype Contract, as Any;
subtype Order, as Any;
subtype OrderState, as Any;
subtype ContractDetails, as Any;
subtype Execution, as Any;
subtype boolean, as Bool;
subtype long, as Num;
subtype UnderComp, as Any;

1;
