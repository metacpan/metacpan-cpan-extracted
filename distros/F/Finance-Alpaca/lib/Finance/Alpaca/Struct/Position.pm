package Finance::Alpaca::Struct::Position 0.9902 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Position];
    use Type::Utils;
    use Types::Standard qw[Bool Enum Int Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Position, { class => __PACKAGE__ };
    coerce( Position, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use Types::UUID;
    use lib './lib';
    use Finance::Alpaca::Types;
    has asset_id                 => ( is => 'ro', isa => Uuid, required => 1 );
    has [qw[asset_class symbol]] => ( is => 'ro', isa => Str,  required => 1 );
    has exchange                 =>
        ( is => 'ro', isa => Enum [qw[AMEX ARCA BATS NYSE NASDAQ NYSEARCA OTC]], required => 1 );

    has [
        qw[avg_entry_price change_today cost_basis current_price lastday_price market_value qty unrealized_intraday_pl unrealized_intraday_plpc unrealized_pl unrealized_plpc]
    ] => ( is => 'ro', isa => Num, required => 1 );
    has side => ( is => 'ro', isa => Enum [qw[long short]], required => 1 );

}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Position - A Single Account Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my $tsla = Finance::Alpaca->new( ... )->position( 'TSLA' );
    say sprintf '%s %f shares of %s', ucfirst $tsla->side, abs $tsla->qty, $tsla->symbol

=head1 DESCRIPTION

The positions API provides information about an account’s current open
positions. The response will include information such as cost basis, shares
traded, and market value, which will be updated live as price information is
updated. Once a position is closed, it will no longer be queryable through this
API.

=head1 Properties

The following properties are contained in the object.

    $position->change_today();

=over

=item C<asset_id> - Asset ID (UUID)

=item C<asset_class> - Asset class name (us_equity)

=item C<exchange> - Exchange name of the asset

=item C<symbol> - Symbol name of the asset

=item C<avg_entry_price> - Average entry price of the position

=item C<qty> - The number of shares

=item C<side> - "long"

=item C<market_value> - Total dollar amount of the position

=item C<cost_basis> - Total cost basis in dollar

=item C<unrealized_pl> - Unrealized profit/loss in dollars

=item C<unrealized_plpc> - Unrealized profit/loss percent (by a factor of 1)

=item C<unrealized_intraday_pl> - Unrealized profit/loss in dollars for the day

=item C<unrealized_intraday_plpc> - Unrealized profit/loss percent (by a factor of 1)

=item C<current_price> - Current asset price per share

=item C<lastday_price> - Last day’s asset price per share based on the closing value of the last trading day

=item C<change_today> - Percent change from last day price (by a factor of 1)

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords queryable

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/positions/
