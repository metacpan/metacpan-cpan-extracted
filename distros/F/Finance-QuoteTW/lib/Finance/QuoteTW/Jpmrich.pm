package Finance::QuoteTW::Jpmrich;
use Spiffy -Base;
use WWW::Mechanize;
use HTML::TableExtract;
use Encode qw/from_to encode decode/;
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
	my %args = @_;
	my $fund_type = $args{type} || q{};

	my $b = WWW::Mechanize->new;
	my $response = $b->get('http://www.jpmrich.com.tw');
	my $current_encoding = encoding_from_http_message($response) || 'big5';
	$b->follow_link(n => 1);

	my $url = "http://www.jpmrich.com.tw/cgi-bin/jfonline/funds/fund_nav_detail.jsp?BV_SessionID=$1"
	  if $b->content =~ /\?BV_SessionID=([^"]+)/;
	$b->get($url);
	my $year = ${[localtime]}[5] + 1900;

	my @result;
	foreach my $option (0..1) {
		next if $fund_type eq 'onshore'  && $option == 0;
		next if $fund_type eq 'offshore' && $option == 1;
		my $form = $b->form_name('frmQuery');
		my $input = $form->find_input('fund_corp');
		$input->{current} = $option;
		$b->submit;

		my $te = HTML::TableExtract->new;
		$te->parse($b->content);

		my @ts = $te->tables;
		my @rows = $ts[0]->rows;
		shift @rows;

		foreach my $row (@rows) {
			next unless $row->[1];
			my @data = map { s/\+//; $_ }
					   map { s/(\d+\/\d+)/$year\/$1/; $_ }
					   map { s/\(([^)]+)\)/$1/; $_ }
					   map { split /\n/, $_ } @$row;
			my $type = 'N/A';
			my $currency = $data[1] =~ /([a-z]{3})/i ? $1 : 'TWD';

			if ( $current_encoding ne $self->{encoding} ) {
				from_to( $data[0], $current_encoding, $self->{encoding} );
			}

			push @result, {
				name     => $data[0],
				date     => $data[3],
				nav      => $data[2],
				change   => $data[5],
				currency => $currency,
				type     => $type,
			};
		}
	}

	return @result;
}

__END__

=head1 NAME 

Finance::QuoteTW::Jpmrich - Get fund quotes from www.jpmrich.com.tw

=head1 SYNOPSIS

See L<Finance::QuoteTW>.

=head1 DESCRIPTION

Get fund quotes from www.jpmrich.com.tw

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

