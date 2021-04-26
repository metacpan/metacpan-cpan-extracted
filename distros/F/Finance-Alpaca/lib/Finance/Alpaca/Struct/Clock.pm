package Finance::Alpaca::Struct::Clock 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Clock];
    use Type::Utils;
    use Types::Standard qw[Bool Enum Int Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Clock, { class => __PACKAGE__ };
    coerce( Clock, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use lib './lib';
    use Finance::Alpaca::Types;
    has [qw[next_open next_close timestamp]] =>
        ( is => 'ro', isa => Timestamp, required => 1, coerce => 1 );
    has is_open => ( is => 'ro', isa => Bool, required => 1, coerce => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Clock - A Single Clock Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my $clock = Finance::Alpaca->new( ... )->clock;
    say sprintf $clock->timestamp->strftime('It is %l:%M:%S %p on a %A and the market is %%sopen!'),
           $clock->is_open ? '' : 'not ';

=head1 DESCRIPTION

The clock endpoint serves the current market timestamp, whether or not the
market is currently open, as well as the times of the next market open and
close.

=head1 Properties

The following properties are contained in the object.

    $clock->is_open( );

=over

=item C<timestamp> - Current timestamp

=item C<is_open> - Boolean value indicating whether or not the market is open

=item C<next_open> - Next market open timestamp

=item C<next_close> - Next market close timestamp

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/clock/
