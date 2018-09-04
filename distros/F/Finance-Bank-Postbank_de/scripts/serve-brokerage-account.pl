#!perl -w
package main;
use strict;
use JSON 'decode_json';
use Finance::Bank::Postbank_de::APIv1;
use Mojolicious::Lite;
use POSIX 'strftime';

use Getopt::Long;
use Pod::Usage;

GetOptions(
    'username=s'      => \my $username,
    'password=s'      => \my $password,
) or pod2usage(2);

$username ||= 'Petra.Pfiffig';
$password ||= '12345678';

get '/depot.html' => sub {
    my( $c ) = @_;
    my @table = fetch_information( $username, $password );
    $c->stash( table => \@table );
    $c->stash( timestamp => strftime '%Y-%m-%d %H:%M:%S', localtime );
    $c->render( 'index' );
};

sub fetch_information {
    my( $username, $password ) = @_;

    my $api = Finance::Bank::Postbank_de::APIv1->new();
    $api->configure_ua();
    
    my $postbank = $api->login( $username, $password );
    
    my $finanzstatus = $postbank->navigate(
        class => 'Finance::Bank::Postbank_de::APIv1::Finanzstatus',
        path => ['banking_v1' => 'financialstatus']
    );
    
    my @columns = qw(isin shortDescription amount averageQuote depotCurrQuote quoteCurrency depotCurrValue winOrLoss winOrLossCurrency );
    my %nums; undef @nums{ qw(amount averageQuote depotCurrQuote depotCurrValue winOrLoss ) };
    my @output;
    push @output, \@columns;
    my ($bp) = $finanzstatus->get_businesspartners;
    for my $account ( grep { $_->productType eq 'depot' } $bp->get_accounts ) {
    
        my $depot = $account->fetch_resource('depot', class => 'Finance::Bank::Postbank_de::APIv1::Depot');
    
        for my $pos ($depot->positions) {
            push @output, [ map { my $v = $pos->$_; exists $nums{ $_ } ? $v =~ s/\./,/r : $v } @columns ];
        };
    };
    @output
}

app->start();

__DATA__

@@index.html.ep
<html lang="de">
<head><title>Depot</title>
<meta charset="UTF-8">
</head>
<body>
<p>Your depot</p>
<table id="depot">
<thead>
%  for my $row ( $table->[0] ) {
<tr>
%    for my $col (@$row) {
<th><%= $col %></th>
%    }
</tr>
%  }
</thead>
<tbody>
%  for my $row (@{ $table }[1..$#$table]) {
<tr>
%    for my $col (@$row) {
<td><%= $col %></td>
%    }
</tr>
%  }
</tr>
</tbody>
</table>
<div id="timestamp"><%= $timestamp %></div>
</body>
</html>