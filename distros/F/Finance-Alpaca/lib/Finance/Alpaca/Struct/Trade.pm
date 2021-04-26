package Finance::Alpaca::Struct::Trade 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Trade];
    use Type::Utils;
    use Types::Standard qw[ArrayRef Int Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Trade, { class => __PACKAGE__ };
    coerce( Trade, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use lib './lib';
    use Finance::Alpaca::Types;
    has t         => ( is => 'ro', isa => Timestamp, required => 1, coerce => 1 );
    has [qw[x z]] => ( is => 'ro', isa => Str,       required => 1 );
    has p         => ( is => 'ro', isa => Num,       required => 1 );
    has [qw[s i]] => ( is => 'ro', isa => Int,       required => 1 );
    has c         => ( is => 'ro', isa => ArrayRef [Str], required => 1 );
    has S         => ( is => 'ro', isa => Str, predicate => 1 );    # If from stream

}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Trade - A Single Trade Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my @trades = Finance::Alpaca->new( ... )->trades(
        symbol    => 'MSFT',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

    say $quotes[0]->ap;

=head1 DESCRIPTION

The quote API provides historcial trade data for a given ticker symbol on a
specified date.

=head1 Properties

The following properties are contained in the object.

    $trade->p;

=over

=item C<t> - Timestamp with nanosecond precision as a Time::Moment object

=item C<x> - Exchange where the trade happened

=item C<p> - Trade price

=item C<s> - Trade size

=item C<c> - Trade conditions

=item C<i> - Trade ID

=item C<z> - Tape

=item C<S> - Symbol; only provided if data is from a Finance::Alpaca::Stream session

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
