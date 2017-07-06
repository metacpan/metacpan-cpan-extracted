package Finance::GDAX::API::TypeConstraints;
our $VERSION = '0.01';
use 5.20.0;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'PositiveInt',
    as 'Int',
    where { $_ > 0 },
    message { "$_ is not a positive number" };

subtype 'PositiveNum',
    as 'Num',
    where { $_ > 0 },
    message { "$_ is not a positive number" };

subtype 'PositiveNumOrZero',
    as 'Num',
    where { $_ >= 0 },
    message { "$_ is not a positive number or zero" };

subtype 'ProductLevel',
    as 'Int',
    where { $_ >= 1 and $_ <= 3 },
    message { "Product level must be 1, 2 or 3" };

enum 'FundingStatus',                [qw(outstanding settled rejected)];
enum 'MarginTransferType',           [qw(deposit withdraw)];
enum 'OrderSelfTradePreventionFlag', [qw(dc co cn cb)];
enum 'OrderSide',                    [qw(buy sell)];
enum 'OrderTimeInForce',             [qw(GTC GTT IOC FOK)];
enum 'OrderType',                    [qw(limit market stop)];
enum 'ReportFormat',                 [qw(pdf csv)];
enum 'ReportType',                   [qw(fills account)];

__PACKAGE__->meta->make_immutable;
1;

