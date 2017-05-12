#!/usr/bin/perl
use Data::Dumper;
close STDERR;
my $browsemaster = shift || 'localhost';
my $file = $ENV{HOME}.'/nethood.pd';

sub dumper {
		my $self = shift;
		open(STOR,">$file") or return;
		print STOR Dumper($self->{net});
		close STOR
}
sub ls_wg {
   map { s/^\s*//;s/\s*$//;$_} split/(?:\s{2,}|\n)/, qx{smbclient -NL $browsemaster | grep -A 1000 'Workgroup            Master' | sed -e 1,2d};
}

sub ls_bm {
   my @a=map { /^\t(.*?)\s{2,}/ ;$1 } split/\n/, qx{smbclient -NL $_[0] | grep -A 1000 'Server               Comment' | grep -B 1000 'Workgroup            Master' | sed -e 1,2d};
   pop@a;
   pop@a;
   @a
}

sub broadcast {
	my $self = shift;
	$self->{net} = {};
	my %ar = ls_wg();
	for my $bm (keys %ar) {
		$bm || next;
		for $host (ls_bm($bm)) {
			$host || next;
			my $ip = get_ip($host);
			$self->{net}{$host} = { shares => [grep {length} ls_sh($host)], ip => $ip};
			dumper($self);
		}
	}
	#map { print "$ar{$_}\n"; map { print "\t$_\n"; map { print "\t\t$_\n" } ls($_) } ls_bm($ar{$_})  } keys %ar;
}

sub ls_sh {
	my $host = shift;
	my @shares;
	open(SMB, "smbclient -NL //$host|") or return;
	my $dead = <SMB>;
	chomp($dead);
	while (length($dead)) {
	      $dead = <SMB>;
	      chomp($dead);
	}
	my $head = <SMB>;
	$dead = <SMB>;
	$head =~ m/^\t(\w+\s+)\w+/;
	my $len = length($1);
	while (<SMB>) {
		chomp;
		last unless length;
		my $share = substr($_, 1, $len);
		$share =~ s{\s+$}{};
		next if $share  =~ /\$$/;
		push @shares, $share;
	}
	close SMB;
	@shares;
}

sub get_ip {
	my $host = shift;
	my $c = qq#smbclient -d 3 -NL //$host 2>&1 | grep 'Connecting to' | awk ' {print \$3 }' | sort -u#;
	my $i = qx{$c};
	chomp($i);
	$i;
}

broadcast({});

