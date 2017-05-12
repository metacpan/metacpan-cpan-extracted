package Finance::QuoteTW::Blackrock;
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
	my $response = $b->get('http://www.blackrock.com.tw/IndividualInvestors/FundCentre/NAV/BGF/index.htm');
	my $current_encoding = encoding_from_http_message($response);
    my $content = $b->content;
    my $te = HTML::TableExtract->new;
    $te->parse($content);
    my @ts = $te->tables;
    my @result;
    foreach my $table (@ts) {
        my $previous_name;
        my @rows = $table->rows;

        foreach my $row (@rows) {
            my @data = map { s/\s+//g if $_; $_ } @{$row};
            next unless $data[1] =~ /^[A-C]/;

			from_to($data[0], $current_encoding, $self->{encoding});
            $previous_name = $data[0] if $data[0];

            my $currency = 
                $data[3] eq '美元' ? 'USD' :
                $data[3] eq '歐元' ? 'EUR' :
                $data[3] eq '日文' ? 'JPN' :
                $data[3] eq '英鎊' ? 'GPB' : q{N/A};

            my ($type) = $data[1] =~ /^(\w)/;

            push @result, {
                name     => $data[0] || $previous_name,
                date     => $data[2],
                nav      => $data[4],
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

Finance::QuoteTW::Blackrock - Get fund quotes from www.blackrock.com.tw

=head1 SYNOPSIS

See L<Finance::QuoteTW>.

=head1 DESCRIPTION

Get fund quotes from www.blackrock.com.tw

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

