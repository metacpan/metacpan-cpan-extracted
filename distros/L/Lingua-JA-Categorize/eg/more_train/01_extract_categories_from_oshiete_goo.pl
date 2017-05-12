use strict;
use warnings;
use LWP::Simple;
use HTML::TreeBuilder::XPath;
use Encode;
use Data::Dumper;
use YAML::Syck;

my $url = 'http://oshiete.goo.ne.jp/category/list/';
my $html = get($url);
$html = encode("utf8", $html);
#$html = encode( "utf8", decode( "utf8", $html ) );
my @html = split( "\n", $html );
my $num = @html + 1;
my $data;
my ( $l, $m, $s );
for my $i ( 0 .. $num ) {
    last if ( $i > $num );
    my $rec = shift @html;

	last if $rec =~ m|<div id="plus-CategoryListWrap">|;

    if ( $rec and $rec =~ m|<h2 class="oshiete-LcategoryIndex">| ) {
        my $a = shift @html;
        if ( $a =~ m|<a href="(/category/.+)">(.+)</a>| ) {
            $l = $2;
            $l =~ s/\[.+\] //g;
        }
    }
    if ( $rec and $rec =~ m|<h3 class="oshiete-McategoryIndex">| ) {
        $rec = shift @html;
        if ( $rec =~ m|<a href="(.+)">(.+)</a>| ) {
            my $url = $1;
            $m = $2;
			$s = $m;

			$l =~ s/\[.+\] //g;
			$m =~ s/\[.+\] //g;
			$s =~ s/\[.+\] //g;

			$data->{$l}->{$m}->{$s} = $url;
        }
    }

    if ( $rec and $rec =~ m|<ul class="oshiete-ScategoryIndex">| ) {
      LABEL:
        while (1) {
            my $a = shift @html;
            last LABEL if ( $a =~ m|</ul>| );
            if (    $a
                and $a =~ m|<a href="(\/[^\"]+)"><span style="white-space:nowrap;">(.+)</span></a>| )
            {
                $s = $2;
                $data->{$l}->{$m}->{$s} = $1;
            }

        }
    }

}
my $conf;
my $more_train;

while ( my ( $l, $m_ref ) = each %$data ) {
    while ( my ( $m, $s_ref ) = each %$m_ref ) {
        if ( $m =~ /その他\((.+)\)/ ) {
            $m = $1;
        }
        while ( my ( $s, $url ) = each %$s_ref ) {
            if ( $s =~ /その他\((.+)\)/ ) {
                $s = $1;
            }
            my $label = $l . ' :: ' . $m . ' :: ' . $s;

            #print $label, "\n";
            my $keyword = join( " ", split( "・|\/|＆", $s ) );

            #print $keyword,"\n";
            my $weight = 1;
            if ( $m eq $s ) {
                $weight = 3;
            }
            $more_train->{$label} = $url;
            $label   = decode( "utf8", $label );
            $keyword = decode( "utf8", $keyword );
            $weight  = decode( "utf8", $weight );
            $conf->{$label}->{keyword} = [$keyword];
            $conf->{$label}->{weight}  = $weight;
        }
    }
}
my $yaml = Dump($conf);
open( OUT, "+>./config.yaml" );
print OUT $yaml;
close(OUT);

open( MORE, "+>./more_train.data" );
print MORE Dumper($more_train);
close(MORE);
