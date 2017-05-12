package Finance::Google::Sector::Mean;

use Statistics::Basic qw(:all);
use List::Util qw(min max);
use HTML::TreeBuilder;
use LWP::Simple qw($ua get);
require Exporter;

$ua->timeout(15);


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
sectorsummary
);

our $VERSION = '0.08';



sub sectorsummary{
   
    my ($symbol,$source) = @_;
    my @buffer = ();
    my $url = "";
    $url = "http://www.google.com/finance";
   
    my @ids = qw/secperf/;

    my $content = get $url;
    return unless defined $content;


    my $tree = HTML::TreeBuilder->new;

    
    $tree->parse($content);
    my %quote;
    my %out=();
    
     @quote{qw/secperf/} = map { _finddiv($tree,$_,'id') } @ids;
     
     
    if(defined($quote{secperf})){
#        $quote{yfnc_modtitlew2} =~s/(&|-|\"|\'|\,|\.|amp;)//g;
#        $quote{yfnc_modtitlew2} =~ m/Sector:(.*?)Industry:(.*?)Full/;
        
        
        $out{SectorChange}{buffer}=[split "%        |down / up",$quote{secperf}];
        
        pop @{$out{SectorChange}{buffer}};
    }

                

    foreach(@{$out{SectorChange}{buffer}}){
        my @set = ();
        $_ = trim($_);
        next if($_ =~/SectorChange/ || $_ eq '');
        
        if($_ =~/Non*Cyclical/ && $_ =~/\+/){
            @set = split /\+/,$_;
            $set[0] = "ConsNonCyclical";


            $out{sectors}->{pos}->{$set[0]}=sprintf("%3.3f",$set[1]);
        }elsif($_ =~/Non*Cyclical/ && $_ =~/\-/){
            @set = split /\-/,$_;
            $set[0] = "ConsNonCyclical";
            $set[1] = $set[2];

            
            $out{sectors}->{pos}->{$set[0]}=sprintf("%3.3f",$set[1]);
        
        }else{
        
            
            if($_ =~ /\+/){
                @set = split /\+/,$_;
                
                $out{sectors}->{pos}->{$set[0]}=sprintf("%3.3f",$set[1]);
            }else{
                @set = split /-/,$_;

                
                
                $set[1]=0.00 unless($set[1]);
                $out{sectors}->{neg}->{$set[0]}=sprintf("%3.3f",$set[1]);
            }
            
        }
    
    }    
    
    $tree = $tree->delete();

    my $i = 0;
    
    $out{avgs}->{pos}->{mean} = mean(values %{$out{sectors}->{pos}});
    $out{avgs}->{pos}->{max} = max(values %{$out{sectors}->{pos}});
    $out{avgs}->{pos}->{min} = min(values %{$out{sectors}->{pos}});

    $out{avgs}->{neg}->{mean} = mean(values %{$out{sectors}->{neg}});
    $out{avgs}->{neg}->{max} = max(values %{$out{sectors}->{neg}});
    $out{avgs}->{neg}->{min} = min(values %{$out{sectors}->{neg}});

    
    


    foreach my $sec(keys %{$out{sectors}->{pos}}){
    
        if($out{avgs}->{pos}->{mean} <= $out{sectors}->{pos}->{$sec}){
            $out{sectors}->{overavg}->{$sec} = $out{sectors}->{pos}->{$sec};
        }
    }
    
    
    
    
    
    return \%out;
    

   
}

sub trim
{
	my $string = shift;
    $string =  "" unless  $string;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	$string =~ s/\t//;
	$string =~ s/^\s//;
	return $string;
}


# for look_down
sub _id {
    my $id = shift;
    return sub {
        my ($tag) = @_;
        if (defined $tag->attr('id')) {
            return $tag->attr('id') eq $id;
        } else {
            return 0;
        }
    }
}

# for look_down
sub _class {
    my $id = shift;
    return sub {
        my ($tag) = @_;
        if (defined $tag->attr('class')) {
            return $tag->attr('class') eq $id;
        } else {
            return 0;
        }
    }
}

sub _findGeneric {
    my ($tree,$tag,$id) = @_;
    my $elem = $tree->look_down('_tag',$tag, _id($id));
    return defined $elem ? $elem->as_text : undef;
}

sub _findspan {
    my ($tree,$id) = @_;
    my $elem = $tree->look_down('_tag', 'span', _id($id));
    return defined $elem ? $elem->as_text : undef;
}
sub _findtd {
    my ($tree,$id) = @_;
    my $elem = $tree->look_down('_tag', 'td', _class($id));
    return defined $elem ? $elem->as_text : undef;
}

sub _findtable {
    my ($tree,$id,$type) = @_;
    my $elem = $tree->look_down('_tag', 'table', $type eq 'id'? _id($id) :  _class($id));



    return defined $elem ? $elem->as_text : undef;
}
sub _findResults {
   my ($tree,$id,$type) = @_;
    my $elem = $tree->look_down('_tag', 'table', $type eq 'id'? _id($id) :  _class($id));



    return defined $elem ? $elem : undef;
}

sub _finddiv {
    my ($tree,$id,$type) = @_;
    my $elem = $tree->look_down('_tag', 'div', $type eq 'id'? _id($id) :  _class($id));



    return defined $elem ? $elem->as_text : undef;
}

sub _findol {
    my ($tree,$id,$type) = @_;
    my $elem = $tree->look_down('_tag', 'ol', $type eq 'id'? _id($id) :  _class($id));



    return defined $elem ? $elem->as_text : undef;
}

# format %quote as a string
sub _as_text {
    my ($symbol,%quote) = @_;
    return sprintf ("%s: \$%2.2f, %s%s (%s%s), vol %s", $symbol,
                            @quote{qw/prc sgn net sgn pct vol/});
}





1;
__DATA__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::Google::Sector::Mean - Perl extension shows you the finance.google.com sectors and there realtime quote+performance grouped in [negative,positive,above average performance]

=head1 SYNOPSIS

    use Finance::Google::Sector::Mean;
    use Data::Dumper;

    my @sector = sectorsummary();

    print Dumper [@sector];

=head1 DESCRIPTION

shows you the finance.google.com sectors and there realtime quote+performance grouped in [negative,positive,above average performance]
check out
Finance::NASDAQ::Markets
which gives additional sectors and indice's

=head2 EXPORT

None by default.

=head1 SEE ALSO

Finance::Optical::StrongBuy
Finance::NASDAQ::Markets


=head2 MORE

    #!/usr/bin/perl
    package main;

    use Data::Dumper;
    use Finance::Optical::StrongBuy;
    use Finance::NASDAQ::Markets;
    use Finance::Google::Sector::Mean;




    my @sector = sectorsummary();

    my @idx = index();

    my @sec = sector();



    my $new = Finance::Optical::StrongBuy->new("/tmp");
    foreach my $symbol (qw/C BAC WFC WM F GE AAPL GOOG/){
        $new->callCheck($symbol);
    }

    print Dumper [@idx,@sec,@sector ,$new];


    1;

=head1 AUTHOR

Hagen Geissler

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Hagen Geissler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut


