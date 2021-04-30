package Finance::Alpaca::Struct::Quote 0.9904 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Quote];
    use Type::Utils qw[class_type from coerce];    # Do not import as()
    use Types::Standard qw[ArrayRef Int Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Quote, { class => __PACKAGE__ };
    coerce( Quote, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use lib './lib';
    use Finance::Alpaca::Types;
    has timestamp => ( is => 'ro', isa => Timestamp, required => 1, coerce => 1, init_arg => 't' );
    has ask_exchange => ( is => 'ro', isa => Str, required => 1, init_arg => 'ax' );
    has ask_price    => ( is => 'ro', isa => Str, required => 1, init_arg => 'ap' );
    has ask_size     => ( is => 'ro', isa => Str, required => 1, init_arg => 'as' );
    has bid_exchange => ( is => 'ro', isa => Str, required => 1, init_arg => 'bx' );
    has bid_price    => ( is => 'ro', isa => Str, required => 1, init_arg => 'bp' );
    has bid_size     => ( is => 'ro', isa => Str, required => 1, init_arg => 'bs' );
    has conditions   => ( is => 'ro', isa => ArrayRef [Str], required => 1, init_arg => 'c' );
    has symbol       => ( is => 'ro', isa => Str, predicate => 1, init_arg => 'S' );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Quote - A Single Quote Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my @quotes = Finance::Alpaca->new( ... )->quotes(
        symbol    => 'MSFT',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

    say $quotes[0]->ap;

=head1 DESCRIPTION

The quote API provides NBBO quotes for a given ticker symbol at a specified
date.

=head1 Properties

The following properties are contained in the object.

    $quote->ask_price;

=over

=item C<timestamp> - Timestamp with nanosecond precision as a Time::Moment object

=item C<ask_exchaneg> - Ask exchange

=item C<ask_price> - Ask price

=item C<ask_size> - Ask size

=item C<bid_exchange> - Bid exchange

=item C<bid_price> - Bid price

=item C<bid_size> - Bid size

=item C<conditions> - Quote conditions

=item C<symbol> - Symbol; only provided if data is from a Finance::Alpaca::Stream session

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/market-data/alpaca-data-api-v2/historical/#bars
