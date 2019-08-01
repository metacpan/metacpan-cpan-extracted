package Finance::Bank::SCSB::TW;
use 5.008;
our $VERSION = '0.14';

use strict;
use utf8;
use Carp;
use WWW::Mechanize;
use HTML::Selector::XPath qw(selector_to_xpath);
use HTML::TreeBuilder::XPath;
use List::MoreUtils qw(mesh);
use Finance::Bank::SCSB::TW::CurrencyExchangeRateCollection;

{
    my $ua;
    sub ua {
        return $ua if $ua;
        $ua = WWW::Mechanize->new(
            env_proxy => 1,
            keep_alive => 1,
            timeout => 60,
        );
        $ua->agent_alias("Mac Mozilla");
        return $ua;
    }
}

sub _login {
    my ($id, $username, $password, $menu) = @_;
    $menu ||= "menu1";

    ua->get('https://ibank.scsb.com.tw/');
    ua->get('https://ibank.scsb.com.tw/mainbody.jsp');

    ua->submit_form(
        form_name => 'loginForm',
        fields => {
            userID => $id,
            loginUID => $username
        }
    );

    ua->submit_form(
        form_name => 'loginForm',
        fields => {
            password => $password,
            'wlw-radio_button_group_key:{actionForm.loginAP}' => $menu
        }
    );

    return ua->content;
}

sub logout {
    ua->get("https://ibank.scsb.com.tw/logout.do");
}

sub css {
    selector_to_xpath(shift)
}

sub _cssQuery {
    my ($content, $selector) = @_;
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($content);
    $tree->findnodes( selector_to_xpath($selector) );
}

sub check_balance {
    my ($id, $username, $password) = @_;

    die "Invalid parameters." unless $id && $username && $password;

    my $content = _login($id, $username, $password, "menu3");

    my $nodes = _cssQuery($content, ".txt07 div[align='center'], .txt10 div[align='center'] span");

    my %balance = ( map { $_->as_trimmed_text } @$nodes );

    for (keys %balance) {
        $balance{$_} =~ s/,//;
    }

    logout;

    return $balance{"存款"} if defined($balance{"存款"});
    return -1;
}

sub currency_exchange_rate {
    my $url = 'https://ibank.scsb.com.tw/netbank.portal?_nfpb=true&_pageLabel=page_other12&_nfls=false';
    ua->get($url);
    my $content = ua->content;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($content);

    my @xp = map {
        [ map { $_->as_trimmed_text } $tree->findnodes($_) ]
    } (
        selector_to_xpath("td.txt09 > span"),
        selector_to_xpath("td.txt09 + td > span"),
        selector_to_xpath("td.txt09 + td + td.txt101 > span"),
        selector_to_xpath("td.txt09 + td + td.txt101 + td.txt101 > span")
    );

    my $table = [];
    my @field_names = qw(zh_currency_name en_currency_name buy_at sell_at);
    for my $row (0..scalar(@{$xp[0]})-1) {
        my @row = ();
        for my $node_text (@xp) {
            my $str = $node_text->[$row];
            push @row, $str;
        }
        $row[0] =~ s/\p{IsSpace}+//g;

        push @$table, { mesh @field_names, @row };
    }

    return bless $table, "Finance::Bank::SCSB::TW::CurrencyExchangeRateCollection";
}

1;

__END__

=head1 NAME

Finance::Bank::SCSB::TW - Check Taiawn SCSB bank info

=head1 SYNOPSIS

    use Finance::Bank::SCSB::TW;

    my $rate = Finance::Bank::SCSB::TW::currency_exchange_rate

    print YAML::Dump($rate);

=head1 DESCRIPTION

This module provides a rudimentary interface to the online SCSB
banking system at L<http://www.scsb.com.tw/>.

You will need either B<Crypt::SSLeay> or B<IO::Socket::SSL> installed
for HTTPS support to work with LWP.

=head1 FUNCTIONS

=over 4

=item currency_exchange_rate

Retrieve the table of foriegn currency exchange rate. All rates are
exchanged with NTD. It returns an arrayref of hash with each one looks
like this:

    {
        zh_currency_name => "美金現金",
        en_currency_name => "USD CASH",
        buy_at           => 33.06,
        sell_at          => 33.56
    }

The returned reference is also an object of
L<Finance::Bank::SCSB::TW::CurrencyExchangeRateCollection>, see the
documents there for the reference of instance methods.

=item check_balance($id, $username, $password)

Retrieve your NTD balance. id is the 10-digit Taiwan ID. username and
password is whatever you defined at the bank.

=back

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
