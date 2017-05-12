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
		my $o = bless {};
		for(1 .. 10){
			$huf{$o} = $_;
			$huf{$o} = $huf{$o} + $huf{$o} + $huf{$o};
			$huf{$o} == ($_*3) or die $huf{$o};
		}
	},
	'H::F' => sub{
		my $o = bless {};
		for(1 .. 10){
			$hf{$o} = $_;
			$hf{$o} = $hf{$o} + $hf{$o} + $hf{$o};
			$hf{$o} == ($_*3) or die $hf{$o};
		}
	},
	'normal' => sub{
		my $o = bless {};
		for(1 .. 10){
			$o->{value} = $_;
			$o->{value} = $o->{value} + $o->{value} + $o->{value};
			$o->{value} == ($_*3) or die $o->{value};
		}
	},
	
};
