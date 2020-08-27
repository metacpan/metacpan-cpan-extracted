use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		eval => q|KatoType { 
			curae :t(ArrayRef[ArrayRef[ArrayRef[ArrayRef[Int, 1, 10], 2, 20], 1, 10]])
			penthos :t(HashRef[ArrayRef[ArrayRef[ArrayRef[Int, 1, 10], 2, 20], 1, 10]]) 
			phobos :t(HashRef[HashRef[HashRef[ArrayRef[Str]]]]) 
			aporia :t(CodeRef)	
			oneiroi :t(RegexpRef)
			thanato :t(GlobRef)
			gaudi :t(Object)
			nosoi :t(Map[Str, Map[Str, Map[Str, ArrayRef[Str]]]]) 
			hypnos :t(Tuple[Str, ArrayRef[Str, 1, 10], Map[Str, ArrayRef[Str]]]) 
			geras :t(Dict[nosoi => Tuple[Str, ArrayRef[Str, 1, 10], Map[Str, ArrayRef[Str]]], hypnos => ArrayRef[ArrayRef[ArrayRef[ArrayRef[Int, 1, 10], 2, 20], 1, 10]]]) 
			limos :t(ScalarRef[SCALA]) 
		}|,
		lib => 't/lib',
		tlib => 't/lib',
	});
	use lib 't/lib';
}

my $lame = 't/lib/KatoType.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
eval $content;
print $@;
