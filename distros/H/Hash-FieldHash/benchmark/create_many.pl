#!perl -w
use strict;
use Benchmark qw(:all);

use Hash::FieldHash ();

my $HUF;
BEGIN{
	if( eval{ require Hash::Util::FieldHash } ){
		$HUF = 'Hash::Util::FieldHash';
	}
	else{
		require Hash::Util::FieldHash::Compat;
		$HUF = 'Hash::Util::FieldHash::Compat';
	}

	$HUF->import(qw(fieldhash));
}

printf "Perl %vd on $^O\n", $^V;

print "$HUF ", $HUF->VERSION, "\n";
print "Hash::FieldHash ", Hash::FieldHash->VERSION, "\n";

fieldhash my %huf;
Hash::FieldHash::fieldhash my %hf;

my %hash;

cmpthese timethese -1 => {
	'H::U::F' => sub{
		my @list;

		for(1 .. 1000){
			my $o = bless {};
			$huf{$o}++;
			push @list, $o;
		}
	},
	'H::F' => sub{
		my @list;

		for(1 .. 1000){
			my $o = bless {};
			$hf{$o}++;
			push @list, $o;
		}
	},
	'normal' => sub{
		my @list;

		for(1 .. 1000){
			my $o = bless {};
			$o->{value}++;
			push @list, $o;
		}
	},
	
};
