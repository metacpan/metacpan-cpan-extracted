#!/usr/bin/perl


use IPC::Open2;

my $config = '/home/xgg/probas_fl/omeugl.cfg';
my $freeling = '/usr/local/bin/analyze';

open2(RD, WR, "$freeling -f $config --outf morfo --noprob --flush");
$| = 1;

my $out;
while (<>) {
	print WR $_;
	my $out;
	my $word = "";
	do {
		chomp($out = <RD>);
		$word .= $out;
	} while ($out !~ /^$/);

	$word =~ s/\n/ /g;
	print reformat($word);
}

	
sub reformat {
	my $palabra = shift;
	my $ow = $palabra;
	$palabra =~ s/'//g;
	$palabra = "[$palabra]\n";
	$palabra =~ s/\[[\wαινσϊόρ]+ /\[\{/g;
        $palabra =~ s/ -1 /'\}, \{/g;
        $palabra =~ s/ -1\]/'\}\]/g;
        $palabra =~ s/\{([\wαινσϊόρ]+) /\{'lema' => '$1','CAT' => '/g;	
        return "[]\n" if ($palabra eq "[$ow]\n");
        return ( length($palabra) > 3 )?$palabra:"";
    }


