package Finance::Alpaca::Struct::Watchlist 0.9902 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Watchlist];
    use Type::Utils;
    use Types::Standard qw[ArrayRef Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Watchlist, { class => __PACKAGE__ };
    coerce( Watchlist, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use Types::UUID;
    use lib './lib';
    use Finance::Alpaca::Struct::Asset qw[Asset];
    use Finance::Alpaca::Types;
    has [qw[account_id id ]]        => ( is => 'ro', isa => Uuid,      required => 1 );
    has [qw[created_at updated_at]] => ( is => 'ro', isa => Timestamp, required => 1, coerce => 1 );
    has name                        => ( is => 'ro', isa => Str,       required => 1 );
    has assets => ( is => 'ro', isa => ArrayRef [Asset], coerce => 1, predicate => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Watchlist - A Single Watchlist Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my @watchlists = Finance::Alpaca->new( ... )->watchlists;

=head1 DESCRIPTION

The assets API provides CRUD operation for the account’s watchlist. An
account can have multiple watchlists and each is uniquely identified by C<id>
but can also be addressed by user-defined C<name>. Each watchlist is an ordered
list of L<assets|Finance::Alpaca::Struct::Asset>.

=head1 Properties

The following properties are contained in the object.

    for my $asset ($watchlist->assets()) {
        say $asset->symbol;
    }

=over

=item C<id> - Watchlist ID (UUID)

=item C<created_at> - Timestamp as a Time::Moment object

=item C<updated_at> - Timestamp as a Time::Moment object

=item C<name> - User-defined watchlist name (up to C<64> characters)

=item C<account_id> - Account ID (UUID)

=item C<assets> - The content of this watchlist in the order as registered by the client

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/watchlist/#watchlist-entity
