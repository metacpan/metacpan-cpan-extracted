package Finance::QuoteTW::Paradigm;
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
	my $response = $b->get('http://www.paradigm-fund.com/location.asp?oversea=0');
	my $current_encoding = encoding_from_http_message($response);

	my $te = HTML::TableExtract->new;
	$te->parse($b->content);

	my @ts = $te->tables;
	my @result;
	my @rows = $ts[0]->rows;
	shift @rows;

	foreach my $row (@rows) {
		my @data = map { s/\s+//g; $_ } @$row;
		from_to($data[0], $current_encoding, $self->{encoding});
		(my $change) = $data[3] =~ /([-]?\d+(\.\d+)?)/;
		my $date = [localtime]->[5] + 1900 . "/$data[1]";
		$date =~ s/\W$//;
		$data[2] =~ s/\W$//;

		push @result, {
			name     => $data[0],
			date     => $date,
			nav      => $data[2],
			change   => $change,
			currency => 'TWD',
			type     => 'N/A',
		};
	}

	return @result;
}

__END__

=head1 NAME 

Finance::QuoteTW::Paradigm - Get fund quotes from www.paradigm-fund.com

=head1 SYNOPSIS

See L<Finance::QuoteTW>.

=head1 DESCRIPTION

Get fund quotes from www.paradigm-fund.com

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

