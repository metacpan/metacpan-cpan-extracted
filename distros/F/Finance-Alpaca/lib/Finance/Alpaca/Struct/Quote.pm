package Finance::Alpaca::Struct::Quote 0.9902 {
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
    has t => ( is => 'ro', isa => Timestamp, required => 1, coerce => 1 );
    has ax => ( is => 'ro', isa => Str, required => 1 );

    has [qw[ap bp]] => ( is => 'ro', isa => Num, required => 1 );
    has [qw[as bs]] => ( is => 'ro', isa => Int, required => 1 );
    has c           => ( is => 'ro', isa => ArrayRef [Str], required => 1 );
    has S           => ( is => 'ro', isa => Str, predicate => 1 );    # If from stream
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

    $quote->ap;

=over

=item C<t> - Timestamp with nanosecond precision as a Time::Moment object

=item C<ax> - Ask exchange

=item C<ap> - Ask price

=item C<as> - Ask size

=item C<bx> - Bid exchange

=item C<bp> - Bid price

=item C<bs> - Bid size

=item C<c> - Quote conditions

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
