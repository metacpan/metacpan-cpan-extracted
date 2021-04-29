package Finance::Alpaca::Struct::Asset 0.9902 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Asset];
    use Type::Utils;
    use Types::Standard qw[Bool Enum Int Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Asset, { class => __PACKAGE__ };
    coerce( Asset, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use Types::UUID;
    use lib './lib';
    use Finance::Alpaca::Types;
    has id                 => ( is => 'ro', isa => Uuid, required => 1 );
    has [qw[class symbol]] => ( is => 'ro', isa => Str,  required => 1 );
    has exchange           =>
        ( is => 'ro', isa => Enum [qw[AMEX ARCA BATS NYSE NASDAQ NYSEARCA OTC]], required => 1 );
    has status => ( is => 'ro', isa => Enum [qw[active inactive]], required => 1 );
    has [qw[easy_to_borrow fractionable marginable shortable tradable]] =>
        ( is => 'ro', isa => Bool, required => 1, coerce => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Asset - A Single Account Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    Finance::Alpaca->new( ... )->assets;

=head1 DESCRIPTION

The assets API serves as the master list of assets available for trade and data
consumption from Alpaca. Assets are sorted by asset class, exchange and symbol.
Some assets are only available for data consumption via Polygon, and are not
tradable with Alpaca. These assets will be marked with the flag
C<tradable=false>.

=head1 Properties

The following properties are contained in the object.

    $account->id;

=over

=item C<id> - UUID

=item C<class> - String (us_equity)

=item C<exchange> - C<AMEX>, C<ARCA>, C<BATS>, C<NYSE>, C<NASDAQ>, C<NYSEARCA>, or C<OTC>

=item C<symbol> - String

=item C<status> - C<active> or C<inactive>

=item C<tradable> - Boolean indicating whether the asset is tradable on Alpaca or not

=item C<marginable> - Boolean indicating whether the asset is marginable or not

=item C<shortable> - Boolean indicating whether the asset is shortable or not

=item C<easy_to_borrow> - Boolean indicating the asset is easy-to-borrow or not (filtering for easy_to_borrow = True is the best way to check whether the name is currently available to short at Alpaca)

=item C<fractionable> - Boolean indicating the asset is fractionable or not

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords marginable shortable

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/account/
