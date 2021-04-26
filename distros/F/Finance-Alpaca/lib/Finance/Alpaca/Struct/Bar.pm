package Finance::Alpaca::Struct::Bar 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Bar];
    use Type::Utils;
    use Types::Standard qw[Bool Enum Int Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Bar, { class => __PACKAGE__ };
    coerce( Bar, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use lib './lib';
    use Finance::Alpaca::Types;
    has timestamp => ( is => 'ro', isa => Timestamp, required => 1, init_arg => 't', coerce => 1 );
    has open      => ( is => 'ro', isa => Num, required  => 1, init_arg => 'o' );
    has high      => ( is => 'ro', isa => Num, required  => 1, init_arg => 'h' );
    has low       => ( is => 'ro', isa => Num, required  => 1, init_arg => 'l' );
    has close     => ( is => 'ro', isa => Num, required  => 1, init_arg => 'c' );
    has volume    => ( is => 'ro', isa => Int, required  => 1, init_arg => 'v' );
    has symbol    => ( is => 'ro', isa => Str, predicate => 1, init_arg => 'S' );   # If from stream

}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Bar - A Single Bar Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my @bars = Finance::Alpaca->new( ... )->bars(
        symbol    => 'MSFT',
        timeframe => '1Min',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

    say $bars[0]->high;

=head1 DESCRIPTION

The bars API serves aggregate historical data.

=head1 Properties

The following properties are contained in the object.

    $bar->close();

=over

=item C<timestamp> - Timestamp with nanosecond precision as a Time::Moment object

=item C<open> - Open price

=item C<high> - High price

=item C<low> - Low price

=item C<close> - Close price

=item C<volume> - Volume

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
