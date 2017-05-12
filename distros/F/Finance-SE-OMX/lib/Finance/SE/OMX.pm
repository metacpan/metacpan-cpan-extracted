package Finance::SE::OMX;
use strict;
use warnings;
our $VERSION = "1.00";

eval "use LWP::Simple";
if ($@) {
    die "This module needs LWP::Simple to function properly, or at all.";
}

eval "use 5.6.0";
if ($@) {
    warn "This module isn't tested for versions of Perl below 5.6.0\n".
	"Consider updating your Perl distribution\n";
}
use LWP::Simple;

    

sub new {
    my $inv = shift;
    my $class = ref($inv) || $inv;
    my $self = {
	@_ 
    };
    return bless $self, $class;
}

sub get_data_short {
    my $self = shift;
    my $stockname = shift or die "no stockame supplied";
    my $stockdata = get "http://www.se.omxgroup.com/stocklist.aspx?srch=$stockname&serch=true&list=all";
    my @list;

    die "couldn't fetch data from server" unless defined $stockdata;
    if ($stockdata =~ /<tbody>.*?<TR>(.*?)<\/TR>.*?<\/tbody>/si) {
	 @list = $self->stocklist_parse($1);
	 return undef unless @list;
    }
    else {
	return undef;
    }
    if ($list[11] !~ /$stockname/i) { 
	return undef;
    }
    return @list;
}

sub stocklist_parse {
    shift;
    my $table = shift || die "no table sent to table-parser";
    my @tds =();
    my @retarr;
    my $shortname;
    if ($table =~ /<TD TITLE="(.*?)".*?>(.*?)<\/TD>(.*)/si) {
	$retarr[0] = $1;
	$table = $3;
	if ($2 =~ /<nobr>(.*?)<\/nobr>/i) {
	    $shortname = $1;
	}
	else {
	    die "Couldn't get shortname";
	}
    }
    else {
	die "couldn't get company name";
    }

    foreach ($table =~ /<TD.*?>(.*?)<\/TD>/gsi) {
	push @tds, $_;
    }

    if (scalar(@tds) != 12) {
	die "wrong number of fields";
    }
    foreach (1 .. 2) {
	if ($tds[$_] =~ /<FONT.*?>(.*?)<\/FONT>/i) {
	    $retarr[$_] = $1;
	}
	
	else {
	    $retarr[$_] = $tds[$_]; #Bättre än inget
	}
    }
    
    foreach (3..7) {
	$retarr[$_] = $tds[$_];
    }
    
    foreach(8..9) {
	if ($tds[$_] =~ /<nobr>(.*?)<\/nobr>/i) {
	    $retarr[$_] = $1;
	}
	else {
	    $retarr[$_] = $tds[$_];
	}
    }
    $retarr[10] = $tds[11];
    $retarr[11] = $shortname;
    return @retarr; 
}

sub get_stocklist {
    my $self = shift;
    my $stocklist = shift; 
    if (!defined($stocklist)) { #can be zero
	die "get_stocklist() needs a list number";
    }
    my $list;
    my (@retlist, @trlist);
    
    die "get_stocklist() takes numerical list number" unless ($stocklist =~ /^\d+$/);
    if ($stocklist == 0) {
	$list = get "http://www.se.omxgroup.com/stocklist.aspx?list=SSE1&group=Kursnoteringar&listname=A-lista%20samtliga";
    }
    elsif ($stocklist == 1) {
	$list = get "http://www.se.omxgroup.com/stocklist.aspx?list=SSE2&group=Kursnoteringar&listname=A-lista%20mest%20omsatta";
    }
    elsif ($stocklist == 2) {
	$list = get "http://www.se.omxgroup.com/stocklist.aspx?list=SSE3&group=Kursnoteringar&listname=A-lista%20%C3%B6vriga";
    }
    elsif ($stocklist == 3) {
	$list = get "http://www.se.omxgroup.com/stocklist.aspx?list=SSE43&group=Kursnoteringar&listname=O-lista%20samtliga";
    }
    elsif ($stocklist == 4) {
	$list = get "http://www.se.omxgroup.com/stocklist.aspx?list=SSE10&group=Kursnoteringar&listname=O-lista%20mest%20Attract40";
    }
    elsif ($stocklist == 5) {
	$list = get "http://www.se.omxgroup.com/stocklist.aspx?list=SSE42&group=Kursnoteringar&listname=O-lista%20%EF%BF%BDvriga";
    }
    else {
	die "get_stocklist() takes a numerical argument of 0-5";
    }
    if ($list =~ /<tbody>(.*?)<\/tbody>/si) {
	$list = $1;
	foreach ($list =~ /<TR>(.*?)<\/TR>/gs) {
	    push @trlist, $_;
	}
	pop @trlist; #last <tr> isn't a stock
	for(my $i = 0; $i<scalar(@trlist); $i++) {
	    my @tmparr = $self->stocklist_parse($trlist[$i]);
	    if (@tmparr) {
		$retlist[$i] = [@tmparr];
	    }
	    else {
		die "error parsing \$trlist[$i]";
	    }
	}
    }
    return @retlist;
}

1;

__END__

=head1 NAME

Finance::SE::OMX - Getting stock information from the swedish stock exchange

=head1 SYNOPSIS

    use Finance::SE::OMX;

=head1 DESCRIPTION

Finance::SE::OMX provides a simple interface for retrieving stock information 
from the swedish stock exchange. It uses LWP::Simple for the communication
with the searchform.

=head1 METHODS

=over 4

=item new()

Standard constructor. Takes no arguments.

=back

=over 4

=item get_data_short("STOCK_SHORTNAME")

Retrieves information about a stock based on the supplied shortname.
It returns this information as an array where the elements are:
    0  - Full name of company
    1  - The increase/decrease of the stock in SEK
    2  - The increase/decrease of the stock in %
    3  - The buy share price
    4  - The sell share price
    5  - The latest share price
    6  - The highest share price 
    7  - The lowest share price
    8  - The share volume
    9  - The company's turnover
    10 - Time of last update
    11 - The short name of the company

If no stock where found, it returns undef.

=back

=over 4

=item get_stocklist(0-5)

Retrieves a whole list of stocks in an array of arrays structure.
Which list it returns is chosen by the argument given to it.
The arguments are:

    0 - A-listan samtliga
    1 - A-listan mest omsatta
    2 - A-listan övriga
    3 - O-listan samtliga
    4 - O-listan Attract40
    5 - O-listan övriga

The arrays in the array is shaped like the one that
gets returned by get_data_short(), since they both use the
same function for retrieving the data. 

It dies if it can't succeed.

=back

=head1 EXAMPLES

$stock = Finance::SE::OMX->new;

@bol = $stock->get_data_short("BOL");

print "$bol[0]\t\t$bol[5]\t\t$bol[10]\n";

=head1 BUGS

If you find any bugs, please notify me somehow and I'll fix it.
If OMX changes their website, then this module may need a 
serious update.

=head1 AUTHOR

Sebastian Cato

=head1 COPYRIGHT

Copyright (c) 2006, Sebastian Cato. All Rights Reserved.

This program is free software. You may copy and/or
redistribute it under the same terms as Perl itself.

=cut

