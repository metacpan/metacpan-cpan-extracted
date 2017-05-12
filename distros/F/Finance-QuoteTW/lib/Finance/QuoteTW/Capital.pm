package Finance::QuoteTW::Capital;
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
	my $response = $b->get('https://www.capitalfund.com.tw/Capital_Frontend/Fund_Index.action');
	my $current_encoding = encoding_from_http_message($response);

	my $te = HTML::TableExtract->new;
	$te->parse($b->content);

	my @ts = $te->tables;
	my @result;

    foreach my $index (1,5,9,13) {
        my @rows = $ts[$index]->rows;
        shift @rows;
        shift @rows;

        foreach my $row (@rows) {
            my @data = map { s/\s+//g if defined $_; $_ } @$row;
            from_to( $data[0], $current_encoding, $self->{encoding} );
            my $date = join q{/}, $data[6] =~ /(\d{4})(\d{2})(\d{2})/;

            push @result, {
                name     => $data[0],
                date     => $date,
                nav      => $data[8],
                change   => 'N/A',
                currency => 'TWD',
                type     => 'N/A',
            };
        }
    }

	return @result;
}

__END__

=head1 NAME 

Finance::QuoteTW::Capital - Get fund quotes from www.capitalfund.com.tw

=head1 SYNOPSIS

See L<Finance::QuoteTW>.

=head1 DESCRIPTION

Get fund quotes from www.capitalfund.com.tw

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

