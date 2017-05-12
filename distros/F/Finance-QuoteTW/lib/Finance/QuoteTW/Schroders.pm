package Finance::QuoteTW::Schroders;
use Spiffy -Base;
use WWW::Mechanize;
use HTML::TableExtract;
use Encode qw/from_to/;
use Encode::TW;
use HTML::Encoding 'encoding_from_http_message';

#---------------------------------------------------------------------------
#  Variables
#---------------------------------------------------------------------------

use version; our $VERSION = qv('0.03');

#---------------------------------------------------------------------------
#  Methods
#---------------------------------------------------------------------------

sub fetch {
	my $b = WWW::Mechanize->new;
	my $response = $b->get('http://www.schroders.com.tw');
	my $current_encoding = encoding_from_http_message($response);

	$b->get('http://schroders.moneydj.com/w/js/wfundjs.djjs?aspid=schroder&showall=0');
	my $html = $b->content;
	from_to($html, $current_encoding, $self->{encoding});
	my $string = $1 if $html =~ /var wfund_fund="([^"]+)"/;
	my %fund = splice @{[split /#/, $string]}, 2;
	my @result;

	foreach my $key (keys %fund) {
		my $url = "http://schroders.moneydj.com/w/wb/wb02_${key}_4.djhtm";
		$b->get($url);
		my $html = $b->content;

		my $te = HTML::TableExtract->new;
		$te->parse($html);

		my @ts = $te->tables;
		my $table = $ts[1];

		(my $today_nav = $table->cell(1,1))=~ s/,//g;
		(my $yesterday_nav = $table->cell(2,1)) =~ s/,//g;
		my $change = sprintf "%.4f", $today_nav - $yesterday_nav;

		push @result, {
			name     => $fund{$key},
			date     => ${[localtime]}[5] + 1900 . '/' . $table->cell(1,0),
			nav      => $today_nav,
			change   => $change,
			currency => 'N/A',
			type     => 'N/A',
		};
	}

	return @result;
}

__END__

=head1 NAME 

Finance::QuoteTW::Schroders - Get fund quotes from www.schroders.com.tw

=head1 SYNOPSIS

See L<Finance::QuoteTW>.

=head1 DESCRIPTION

Get fund quotes from www.schroders.com.tw

=head1 FUNCTIONS

=head2 fetch

see L<Finance::QuoteTW>

=head1 AUTHOR

Alec Chen <alec@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2007 by Alec Chen. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

