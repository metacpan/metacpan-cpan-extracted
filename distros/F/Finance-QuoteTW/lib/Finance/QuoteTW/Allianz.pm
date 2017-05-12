package Finance::QuoteTW::Allianz;
use Spiffy -Base;
use WWW::Mechanize;
use HTML::TableExtract;
use Encode qw/from_to/;
use Encode::TW;
use HTML::Encoding 'encoding_from_http_message';
use Data::TreeDumper;

#---------------------------------------------------------------------------
#  Variables
#---------------------------------------------------------------------------

use version; our $VERSION = qv('0.02');

#---------------------------------------------------------------------------
#  Methods
#---------------------------------------------------------------------------

sub fetch {
	my $b = WWW::Mechanize->new;
	my $response = $b->get('http://www.allianzglobalinvestors.com.tw/Allianz_WebSite/Overview.htm');
	my $current_encoding = encoding_from_http_message($response);
	my @result;

	my $te = HTML::TableExtract->new;
	$te->parse($b->content);
    my @ts = $te->tables;
    my @rows = $ts[16]->rows;
    shift @rows;

	foreach my $row (@rows) {
		my @data = @{$row};
        my ($nav, $date) = $data[12] =~ /(\d+\.\d+)\(([^)]+)/;
		from_to($data[3], $current_encoding, $self->{encoding});

		push @result, {
			name     => $data[3],
			date     => $date,
			nav      => $nav,
			change   => 'N/A',
			currency => $data[9],
			type     => 'N/A',
		};
	}

	return @result;
}

__END__

=head1 NAME 

Finance::QuoteTW::Allianz - Get fund quotes from www.allianzglobalinvestors.com.tw

=head1 SYNOPSIS

See L<Finance::QuoteTW>.

=head1 DESCRIPTION

Get fund quotes from www.allianzglobalinvestors.com.tw

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

