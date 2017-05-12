package Finance::NASDAQ::Quote;

use warnings;
use strict;

use HTML::TreeBuilder;
use LWP::Simple qw($ua get);
$ua->timeout(15);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/getquote/;

=head1 NAME

Finance::NASDAQ::Quote - Fetch real time stock quotes from nasdaq.com

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

Fetch real time stock quotes from nasdaq.com

    use Finance::NASDAQ::Quote qw/getquote/;

    my %quote = getquote('F');
    my $text  = getquote('V');

=head1 EXPORT

None by default.

=head1 FUNCTIONS

=head2 getquote( SYMBOL )

In list context, returns a hash containing the price, net change,
percent change, sign ('+' or '-'), and volume for stock SYMBOL, or
an empty list on error.

In scalar context, returns a formatted string suitable for human
consumption, or undef on error.

=cut

sub getquote {
    my ($symbol,$ua) = @_;
    my $url = "http://www.nasdaq.com/aspx/nasdaqlastsale.aspx?symbol=$symbol&selected=$symbol";
    my @ids = qw/_LastSale _NetChange _PctChange _Volume/;
    my $content;
    if (defined $ua) {
        my $resp = $ua->get($url);
        $content = $resp->content() if $resp->is_success();
    } else {
        $content = get $url;
    }
    warn "NASDAQ is down" and return unless defined $content;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my %quote;
    @quote{qw/prc net pct vol/} = map { _findspan($tree, $_) } @ids;

    my $img = $tree->look_down('_tag', 'img', _id('_updownImage'));
    if ($img) {
        my ($color) = ($img->attr('src') =~ /(\w+)ArrowSmall/);
        $quote{sgn} = $color eq 'green' ? '+' : '-';
    } else {
        warn "Failed to locate updownimage";
        $quote{sgn} = undef;
    }
    if ($quote{net} eq 'unch') { $quote{net} = 0 };

    ($quote{nam}) = ($tree->find('title')->as_text() =~ /^([^(]+) \(\S+\)/);
    if (defined $quote{nam}) {
        $quote{nam} =~ s/ +$//g;
    } else {
        warn "Could not parse title";
    }

    $tree = $tree->delete();

    return if grep {not defined} values %quote;
    return wantarray ? %quote : _as_text($symbol, %quote);
}

# for look_down
sub _id {
    my $id = shift;
    return sub {
        my ($tag) = @_;
        if (defined $tag->attr('id')) {
            return $tag->attr('id') eq $id;
        } else {
            return 0;
        }
    }
}

sub _findspan {
    my ($tree,$id) = @_;
    my $elem = $tree->look_down('_tag', 'span', _id($id));
    if (defined $elem) {
        return $elem->as_text;
    } else {
        warn "Could not find span $id";
        return undef;
    }
}

# format %quote as a string
sub _as_text {
    my ($symbol,%quote) = @_;
    return sprintf ("%s (%s): \$%g, %s%s (%s%s), vol %s", $quote{nam},
                            $symbol, @quote{qw/prc sgn net sgn pct vol/});
}

=head1 AUTHOR

Ian Kilgore, C<< <iank at cpan.org> >>

=head1 BUGS/TODO

nasdaq.com (and hence getquote) returns curiously formatted strings,
rather than numbers.  getquote should 'numify' these.

It is likely that nasdaq.com will be changing their site some time
in 2009.  Watch for updates.

The module lacks many tests.  getquote could be made more modular so
as to avoid requiring an internet connection to test it.

Please report any bugs or feature requests to C<bug-finance-nasdaq-quote at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-NASDAQ-Quote>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::NASDAQ::Quote


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-NASDAQ-Quote>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-NASDAQ-Quote>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-NASDAQ-Quote>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-NASDAQ-Quote/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Ian Kilgore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
