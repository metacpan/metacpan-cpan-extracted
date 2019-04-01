package Finance::Bank::Postbank_de::APIv1::Position;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.57';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Position - Postbank position

=head1 SYNOPSIS

=cut

has [ 'depotCurrWinOrLoss',
      'winOrLoss',
      'isin',
      'branchOfTrade',
      'amountType',
      'averageQuoteCurrency',
      'depotCurrency',
      'country',
      'assetGroup',
      'winOrLossCurrency',
      'productType',
      'wkn',
      'exchangerate',
      'depotCurrQuote',
      'depotCurrValue',
      'quoteCurrency',
      'quoteDate',
      'currency',
      'messages',
      'positionId',
      'averageQuote',
      'value',
      'shortDescription',
      'fullDescription',
      'lastBookInDate',
      'amount',
      'assetGroupDescription',
      'availableAmount',
      'depotCurrAverageQuote',
    ] => ( is => 'ro' );

1;

