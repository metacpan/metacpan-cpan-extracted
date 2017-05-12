package Finance::NASDAQ::Markets;

use 5.012004;
use strict;
use warnings;


# Preloaded methods go here.
use LWP::Simple qw($ua get);
$ua->timeout(15);
use HTML::TableExtract;
use HTML::TableContentParser;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Finance::NASDAQ::Markets ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
index sector
);

our $VERSION = '0.01';


#http://quotes.nasdaq.com/aspx/marketindices.aspx
#http://quotes.nasdaq.com/aspx/sectorindices.aspx

sub sector {  
return getdata("http://quotes.nasdaq.com/aspx/sectorindices.aspx");
}
sub index {  
return getdata("http://quotes.nasdaq.com/aspx/marketindices.aspx");
}

sub getdata {  
    my ($url) = @_;
    my @ids = qw/_LastSale _NetChange _PctChange _Volume/;
    my $content;
    my @set=()  ;
    $content = get $url;
 
    warn "NASDAQ is down" and return unless defined $content;


    my $p = HTML::TableContentParser->new();
    my @check=();
    my $tables = $p->parse($content);
         for my $t (@$tables) {
           for my $r (@{$t->{rows}}) {
          #   print "Row: ";
             for my $c (@{$r->{cells}}) {
             
                next unless($c->{data});
                
                if($c->{data}=~/redarrow/){
                   push @check,"-";
                }
                if($c->{data}=~/greenarrow/){
                   push @check,"+";
                }
             }
             #print "\n";
           }
         }

    
     my $te = HTML::TableExtract->new( headers => [("Symbol",  "Name", "Index Value","Change Net / %", "High", "Low")] );
        $te->parse($content);
    
        my $i=0;
        foreach my  $ts ($te->tables) {
           
           foreach my $row ($ts->rows) {
          #print Dumper $ts;



           map  {if(defined($_)){ $_=~s/(InfoQuote|Charting)//g; $_=_trim($_)}} @$row;
           
            if(defined($check[$i])) {
            
               if($check[$i] =~ /-/){
                push @$row,'down';
               }elsif($check[$i] =~/\+/){
                push @$row,'up';
               }
              
                
                $row->[3] =~s/[^\0-\x80][^\0-\x80]/ $check[$i]/g;
                
                
                #print Dumper split("",$row->[3]);
              
                push @set,[@$row];
                $i++;
               }
           }

        }


    
    return @set;

}



sub _trim
{
    my $string = shift;
    $string =  "" unless  $string;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string =~ s/\t//;
    $string =~ s/^\s//;
    return $string;
}

package main;
  use Data::Dumper;
  my @idx = Finance::NASDAQ::Markets::index();
  my @sec = Finance::NASDAQ::Markets::sector();
  print Dumper [@idx,@sec];
  
  
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::NASDAQ::Markets - Perl extension to download realtime quotes for all major markets indices sectors

=head1 SYNOPSIS

  use Finance::NASDAQ::Markets;
  use Data::Dumper;
  my @idx = Finance::NASDAQ::Markets::index();
  my @sec = Finance::NASDAQ::Markets::sector();
  print Dumper [@idx,@sec];

=head1 DESCRIPTION

Loads the quotes and change pct. information 
for a wide range of indices and sectors
from nasdaq. should be realtime!

=head2 EXPORT

None by default.

=head1 SEE ALSO

Finance::Optical::StrongBuy
Finance::Google::Sector::Mean

=head1 AUTHOR

Hagen Geissler

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Hagen Geissler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut


