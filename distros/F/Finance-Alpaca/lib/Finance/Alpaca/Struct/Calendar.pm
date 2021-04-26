package Finance::Alpaca::Struct::Calendar 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';    #
    use Type::Library 0.008 -base, -declare => qw[Calendar];
    use Type::Utils;
    use Types::Standard qw[ArrayRef Dict Int Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Calendar, { class => __PACKAGE__ };
    coerce( Calendar, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use lib './lib';
    use Finance::Alpaca::Types;

    has [qw[date open close session_open session_close]] =>
        ( is => 'ro', isa => Str, required => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Calendar - A Single Calendar Date Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my @days = $camelid->calendar(
        start => Time::Moment->now,
        end   => Time::Moment->now->plus_days(14)
    );
    for my $day (@days) {
        say sprintf '%s the market opens at %s Eastern',
            $day->date, $day->open;
    }

=head1 DESCRIPTION

The calendar endpoint serves the full list of market days from 1970 to 2029. It
can also be queried by specifying a start and/or end time to narrow down the
results. In addition to the dates, the response also contains the specific open
and close times for the market days, taking into account early closures.

=head1 Properties

A calendar day contains the following properties:

    $day->date();

=over

=item C<date> - Date string in "%Y-%m-%d" format

=item C<open> - The time the market opens at on this date in "%H:%M" format

=item C<close> - The time the market closes at on this date in "%H:%M" format

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/calendar/
