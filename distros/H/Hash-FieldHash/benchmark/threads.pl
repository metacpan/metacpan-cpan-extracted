#!perl -w
use strict;
use Benchmark qw(:all);

use threads ();
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

	$HUF->import(qw(fieldhash fieldhashes id));
}

printf "Perl %vd on $^O\n", $^V;

print "$HUF ", $HUF->VERSION, "\n";
print "Hash::FieldHash ", Hash::FieldHash->VERSION, "\n";



cmpthese timethese -2 => {
	'H::U::F' => sub{
		fieldhashes \my(%huf1, %huf2, %huf3);

		my @objects;
		for(1 .. 100){
			my $o = bless {};
			$huf1{$o} = 1;
			$huf2{$o} = 2;
			$huf3{$o} = 3;
			push @objects, $o;
		}
		for(1 .. 3){
			threads->new(sub{ my @a = @objects })->join();
		}
	},
	'H::F' => sub{
		Hash::FieldHash::fieldhashes \my(%hf1, %hf2, %hf3);

		my @objects;
		for(1 .. 100){
			my $o = bless {};
			$hf1{$o} = 1;
			$hf2{$o} = 2;
			$hf3{$o} = 3;
			push @objects, $o;
		}
		for(1 .. 3){
			threads->new(sub{ my @a = @objects })->join();
		}
	},
};
