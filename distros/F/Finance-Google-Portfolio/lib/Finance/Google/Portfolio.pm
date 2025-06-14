package Finance::Google::Portfolio;
# ABSTRACT: Manipulate Google Finance portfolios a little

use 5.010;
use strict;
use warnings;

use Moo;
use namespace::clean;
use LWP::UserAgent;
use HTML::Form;
use JSON::PP;
use Carp 'croak';
use URI;

our $VERSION = '1.08'; # VERSION

has user      => ( is => 'rwp' );
has passwd    => ( is => 'rwp' );
has is_authed => ( is => 'rwp', default => 0 );
has hash      => ( is => 'rwp' );
has json      => ( is => 'ro', default => sub { JSON::PP->new->utf8->allow_barekey } );
has ua        => (
    is      => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new(
            max_redirect => 24,
        );
        push( @{ $ua->requests_redirectable }, 'POST' );
        $ua->cookie_jar({});
        return $ua;
    },
);

sub BUILD {
    my ($self) = @_;
    $self->login( $self->user, $self->passwd ) if ( $self->user and $self->passwd );
}

sub login {
    my ( $self, $user, $passwd ) = @_;

    $self->_set_user($user)     if ($user);
    $self->_set_passwd($passwd) if ($passwd);

    croak('Must provide "user" and "passwd" values to login() or new()')
        unless ( $self->user and $self->passwd );

    my $form = ( HTML::Form->parse(
        $self->ua->request( HTTP::Request->new( 'GET', 'https://mail.google.com/tasks/ig' ) )
    ) )[0];
    $form->value( 'Email', $self->user );
    $form = ( HTML::Form->parse( $self->ua->request( $form->click ) ) )[0];
    $form->value( 'Passwd', $self->passwd );

    my $res = $self->ua->request( $form->click );

    croak('Authentication failed; check user and passwd values and that LWP::Protocol::https is installed')
        if ( $res->content =~ /<title>Sign in/ );

    $self->_set_is_authed(1);
    return $self;
}

sub portfolio {
    my ( $self, $pid ) = @_;
    $pid ||= 1;

    my $res = $self->ua->request(
        HTTP::Request->new( 'GET', 'https://www.google.com/finance/portfolio?action=view&pid=' . $pid )
    );

    my ($fgp_data_string) = grep { $_ =~ /^\s*google\.finance\.data\s/ } split( "\n", $res->content );
    $fgp_data_string =~ s/^\s*google\.finance\.data\s*=\s*//;
    $fgp_data_string =~ s/;$//;

    my $fgp_data = $self->json->decode($fgp_data_string);
    $self->_set_hash( $fgp_data->{common}{hash} );

    return $fgp_data->{portfolio_view}{portfolio_table}{cps};
}

{
    my @months = qw( January February March April May June July August September October November December );
    sub add {
        my ( $self, $details ) = @_;
        croak('Transaction details must be supplied to add() as a hashref') unless ( ref $details eq 'HASH' );

        my $uri = URI->new;
        $uri->query_form(
            editmode             => 'trans',
            menu_type            => 'transaction',
            pid                  => $details->{pid} || 1,
            add_ttype_1          => uc( $details->{type} || '' ),
            add_symbols_1        => $details->{symbol},
            add_shares_1         => $details->{shares},
            add_price_1          => $details->{price},
            add_commission_1     => $details->{commission},
            add_notes_1          => $details->{notes},
            add_is_cash_synced_1 => 'on',
            add_date_1           => $details->{date} || do {
                my ( $month, $day, $year ) = ( localtime() )[ 4, 3, 5 ];
                $months[$month] . ' ' . $day . ', ' . ( $year + 1900 );
            },
        );

        my $req = HTTP::Request->new(
            'POST',
            'https://www.google.com/finance/portfolio?action=add&hash=' . $self->hash,
        );
        $req->content( $uri->query );
        $self->ua->request($req);
    }
}

sub watchlist {
    my ( $self, $details ) = @_;

    my $uri = URI->new;
    $uri->query_form(
        editmode  => 'trans',
        pid       => $details->{pid} || 1,
        watchlist => (
            ( ref( $details->{list} ) eq 'ARRAY' )
                ? join( ' ', @{ $details->{list} } )
                : $details->{list}
        ),
    );

    my $req = HTTP::Request->new(
        'POST',
        'https://www.google.com/finance/portfolio?action=edit_portfolio_del_btn&hash=' . $self->hash,
    );
    $req->content( $uri->query );
    $self->ua->request($req);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Google::Portfolio - Manipulate Google Finance portfolios a little

=head1 VERSION

version 1.08

=for markdown [![test](https://github.com/gryphonshafer/Finance-Google-Portfolio/workflows/test/badge.svg)](https://github.com/gryphonshafer/Finance-Google-Portfolio/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Finance-Google-Portfolio/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Finance-Google-Portfolio)

=head1 SYNOPSIS

    use Finance::Google::Portfolio;

    my $fg_portfolio = Finance::Google::Portfolio->new();
    $fg_portfolio->login( user => 'user', passwd => 'passwd' );

    my $fgp = Finance::Google::Portfolio->new(
        user   => 'user',
        passwd => 'passwd',
    );

    for my $holding ( @{ $fgp->portfolio(1) } ) {
        my ( $name, $symbol, $shares ) = @{$holding}{ qw( lname s sh ) };
        printf "%-50s %-7s %4d\n", $name, $symbol, $shares;
    }

    $fgp->add({
        type       => 'buy',
        symbol     => 'AAPL',
        shares     => 42,
        price      => 11.38,
        commission => 5,
    });

    $fgp->watchlist({ list => 'AAPL MSFT EXPE TWTR' });

=head1 DESCRIPTION

This module is an attempt to provide a simple means to manipulate a Google
Finance portfolio, at least a little. Google deprecated its API to Google
Finance, so this module attempts some not-likely-to-be-stable web scraping.
There is very little (read: no) error checking or proper handling of edge-cases.
It's not well tested. I make no warranties or guarantees about this code
what-so-ever. Consequently, this module should probably not be used by anyone,
ever.

=head1 LIBRARY METHODS AND ATTRIBUTES

The following are methods and attributes of the module:

=head2 new

This instantiator is provided by L<Moo>. It can optionally accept a username
and password, and if so provided, it will call C<login()> automatically.

    my $fgp  = Finance::Google::Portfolio->new;
    my $fgp2 = Finance::Google::Portfolio->new(
        user   => 'user',
        passwd => 'passwd',
    );

=head2 login

This method accepts a username and password for a valid/current Google account,
then attempts to authenticate the user and start up a session.

    $fgp->login( user => 'user', passwd => 'passwd' );

The method returns a reference to the object from which the call was made. And
please note that the authentication takes place via a simple L<LWP::UserAgent>
scrape of a web form. For this to work, L<LWP::Protocol::https> must be
installed and SSL support must be available.

=head2 portfolio

This method gets a whole lot of data from a given portfolio. With Google Finance,
you can setup multiple portfolios. They're numbered sequentially starting at 1.
The C<portfolio()> method accepts an integer representing the portfolio number.
If omitted, it assumes you want portfolio 1.

    my $fgp_portfolio_1_data = $fgp->portfolio;
    my $fgp_portfolio_2_data = $fgp->portfolio(2);

What's returned is a hashref data structure. What you may be most interested
in could be: $data->{portfolio_view}{portfolio_table}{cps}, an arrayref of
the current items in the portfolio.

=head2 add

This method allows you to add a transaction to a portfolio. This is buying,
selling, shorting, or covering equities.

    $fgp->add({
        type       => 'buy', # transaction type: buy, sell, etc.
        symbol     => 'AAPL',
        shares     => 42,
        price      => 11.38,
        commission => 5,

        pid   => 1,             # optional; indicates portfolio; defaults to 1
        notes => '',            # optional
        date  => 'May 4, 2015', # optional date; defaults to current day
    });

=head2 watchlist

This method sets your watchlist, which is the items listed in your portfolio.
Note that what's in your watchlist is not the same as what's in your transaction
history. The method requires a "list" parameter which is a space-separated
list of symbols for the watchlist. If you want to remove an item from your
watchlist, you need to provide the whole list of symbols minus the item you
want removed.

    $fgp->watchlist({
        list => 'AAPL MSFT EXPE TWTR',
        pid  => 1, # optional; indicates portfolio; defaults to 1
    });

=head1 SEE ALSO

L<Moo>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Finance-Google-Portfolio>

=item *

L<MetaCPAN|https://metacpan.org/pod/Finance::Google::Portfolio>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Finance-Google-Portfolio/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Finance-Google-Portfolio>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Finance-Google-Portfolio>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/G/Finance-Google-Portfolio.html>

=back

=for Pod::Coverage BUILD is_authed json passwd ua user hash

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
