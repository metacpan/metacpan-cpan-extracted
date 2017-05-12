#!/usr/bin/perl
use warnings;
use strict;
use FindBin '$Bin';

use Test::More tests => 1 + 22 + (8+1146+14+715+495+8) + (13+13+13);

BEGIN {
	use_ok('Mac::AppleEvents');
	require "$Bin/helper.pl";
}

use Mac::Types;
use MacPerl 'MakePath';

my $fourcharcode = ['abcd', '1   ', "\0\0\0\0"];
my $stringdata   = ['a', 'ab', 'abc', @$fourcharcode, 'abcde', 'abcdef', "this is some random text I am just gonna add here OK?"];

# 15
my %types = (
	# 3 * 5 = 15
	typeEnumerated()	=> $fourcharcode,
 	typeType()		=> $fourcharcode,
 	typeKeyword()		=> $fourcharcode,
 	typeApplSignature()	=> $fourcharcode,
 	typeProperty()		=> $fourcharcode,

	# 9
 	typeChar()		=> $stringdata,

	# 2, 3 * 5 = 17
 	typeBoolean()		=> [0, 1],
 	typeShortInteger()	=> [0, 123, -1234],
 	typeInteger()		=> [0, -2**24, 2**31-1],
 	typeShortFloat()	=> [0, 123.45, -1234.56],
 	typeFloat()		=> [0, 12345678.91, (-2**24 + .234234)],
 	typeMagnitude()		=> [0, 2**32-1, 2**31],

	# 1
	typeFSS()		=> ['/System/Library/CoreServices/Finder.app'],
	typeQDRectangle()	=> [ [1, 240, 320, 2000] ],
	typeRGBColor()		=> [ [65535, 0, 0] ],

	# qdrt, cRGB, STR, STR#
); # = 44

SKIP: {
#	skip "Basic AEDesc tests", 22;

	my $desc = AEDesc->new(typeChar);
	is(ref($desc), 'AEDesc',				'Create AEDesc');
	is($desc->type, typeChar,				'Check type');
	ok(!defined($desc->get),				'No data');

	my $hand = Handle->new('something');
	is($desc->type(typeType), typeType,			'Change type');
	ok(!defined($desc->get),				'No data');
	is(ref($hand), 'Handle',				'Create handle');
	ok($desc->data($hand),					'Add handle');
	is($desc->get, 'some',					'Check value'); # truncated due to typeType

	is($desc->type(typeChar), typeChar,			'Change type');
	# 6 * 2 = 12
	for my $i (0, 1, 10, 100, 1000, 10000) {
		ok($desc->data(Handle->new($i)),		'Add handle');
		is($desc->get, $i,				'Check value');
	}

	ok(AEDisposeDesc($desc),				'Dispose');
}

SKIP: {
#	skip "AEDesc and AEList tests", 8+1146+14+715+495+8;

	# 8
	my $list = AECreateList('', 0);
	is($list->type, typeAEList,					'Create AEList');
	my $reco = AECreateList('', 1);
	is($reco->type, typeAERecord,					'Create AERecord');

	my $list2 = AECreateList('', 0);
	is($list2->type, typeAEList,					'Create AEList');
	my $reco2 = AECreateList('', 1);
	is($reco2->type, typeAERecord,					'Create AERecord');

	my $lists = AEStream->new;
	is(ref $lists, 'AEStream',					'Create AEStream list');
	ok($lists->OpenList,						'OpenList');
	my $recos = AEStream->new;
	is(ref $recos, 'AEStream',					'Create AEStream list');
	ok($recos->OpenRecord,						'OpenRecord');

	my($listg_fmt, $recog_fmt, @g_param) = ('', '');

	# 44 * 4 * 5 = 880, + 44, + 33 * 4 = 132, + 15 * 6 = 90 = 1146
	for my $type (sort keys %types) {
		my $data = $types{$type};
		for my $datum (@$data) {
			my $packed = exists($MacPack{$type}) ? MacPack($type, (ref $datum ? @$datum : $datum)) : $datum;

			my $desc1 = AEDesc->new($type, $packed);
			my $desc2 = AEKeyDesc->new($type, $type, $packed);
			my $desc3 = AECreateDesc($type, $packed);
			my $desc4 = AEDuplicateDesc($desc1);

			# http://developer.apple.com/technotes/tn/tn2045.html
			my $builddata = $datum;
			my $lit = 0;
			my $skip = 0;
			my $hand = 0;
			if ($type eq typeFSS) {
				$builddata = $packed;
			} elsif ($datum =~ /\0/) {
				$builddata = MakeHex($datum);
				$lit = 1;
			} elsif ($type eq typeType) {
				$builddata = Handle->new(MakeFourChar($datum));
				$hand = 1;
			} elsif ($type eq typeKeyword) {
				$builddata = MakeFourChar($datum);
			} elsif ($type eq typeApplSignature || $type eq typeProperty || $type eq typeEnumerated) {
				$builddata = "'$datum'";
				$lit = 1;
			} elsif ($type eq typeBoolean) {
				$builddata = MakeNumHex($datum);
				$lit = 1;
			} elsif ($type eq typeShortInteger || $type eq typeInteger) {
				$lit = 1;
			} elsif (SkipType($type)) {
				# no idea why this doesn't work, oh well
				$skip = 1;
			}

			my $desc5 = $skip ? '' :
				$lit  ? AEBuild("$type($builddata)") :
				$hand ? AEBuild("$type(\@@)", $builddata) :
				        AEBuild("$type(\@)",  $builddata);

			# http://developer.apple.com/technotes/tn/tn2046.html
			my $stream = AEStream->new;
			$stream->WriteDesc($type, $packed);
			my $desc6 = $stream->Close;

			#diag("$type: $datum");

			if ($datum eq $data->[-1]) {
				ok(AEPut($list, AECountItems($list)+1, $type, $packed),	'AEPut');
				ok(AEPutKey($reco, $type, $type, $packed), 		'AEPutKey');

				ok(AEPutDesc($list2, AECountItems($list2)+1, $desc4),	'AEPutDesc');
				ok(AEPutKeyDesc($reco2, $type, $desc4), 		'AEPutKeyDesc');

				ok($lists->WriteDesc($type, $packed),			'WriteDesc list');
				ok($recos->WriteKeyDesc($type, $type, $packed),		'WriteKeyDesc record');

				unless ($skip) {
					if ($lit) {
						$listg_fmt .= "$type($builddata), ";
						$recog_fmt .= "$type : $type($builddata), ";
					} else {
						my $at = $hand ? '@@' : '@';
						$listg_fmt .= "$type($at), ";
						$recog_fmt .= "$type : $type($at), ";
						push @g_param, $builddata;
					}
				}
			}

			#diag("$type($builddata)");
			#diag(AEPrint($desc4));
			#diag(AEPrint($desc5)) if $desc5;
			for my $desc ($desc1, $desc2, $desc3, $desc4, $desc5, $desc6) {
				next unless $desc;
				CheckDesc($desc, $type, $datum);
			}
		}
	}

	# 14
	s/, $// for ($listg_fmt, $recog_fmt);
	my $listg = AEBuild("[$listg_fmt]", @g_param);
	is($listg->type, typeAEList,			'Create AEList');
	my $recog = AEBuild("{$recog_fmt}", @g_param);
	is($recog->type, typeAERecord,			'Create AERecord');

	ok($lists->CloseList,				'CloseList');
	ok($recos->CloseRecord,				'CloseRecord');

	ok(my $list3 = $lists->Close,			'Close list');
	ok(my $reco3 = $recos->Close,			'Close record');

	my $count = scalar keys %types;
	for my $L ($list, $list2, $list3, $reco, $reco2, $reco3) {
		is(AECountItems($L), $count,		'Count list items');
	}

	my $countg = $count - 5;
	for my $L ($listg, $recog) {
		is(AECountItems($L), $countg,		'Count list items');
	}

	# 15 * 13 * 3 = 585, + 13 * 10 = 715
	my $i = 0;
	my $g = 0;
	for my $type (sort keys %types) {
		$i++; $g++;
		my $datum = $types{$type}[-1];
		#diag("AEList: $type: $datum");

		my $j = 0;
		for my $L ($list, $list2, $list3, $listg) {
			my $k = $i;
			if (++$j == 4) {
				#diag("ok!: $type: $g");
				if (SkipType($type)) {
					$g--;
					next;
				}
				$k = $g;
			}
			my $desc = AEGetNthDesc($L, $k);
			CheckDesc($desc, $type, $datum);
		}

		$j = 0;
		for my $L ($reco, $reco2, $reco3, $recog) {
			my $k = $i;
			if (++$j == 4) {
				#diag("ok!!: $type: $g");
				if (SkipType($type)) {
					next;
				}
				$k = $g;
			}
			my $desc = AEGetKeyDesc($L, $type);
			CheckDesc($desc, $type, $datum);

			# same as above, but fetch by index
			($desc, my($key)) = AEGetNthDesc($L, $k);
			is($key, $type,			'Check key');
			CheckDesc($desc, $type, $datum);
		}
	}

	# 15 * 11 * 3 = 495
	$i = 0;
	for my $type (sort keys %types) {
		$i++;
		my $datum = $types{$type}[-1];
		#diag("AEDelete: $type: $datum");

		for my $L ($list, $list2, $list3) {
			my $desc = AEGetNthDesc($L, 1);
			CheckDesc($desc, $type, $datum);
			AEDeleteItem($L, 1);
			my $tab = AECountItems($L);
			cmp_ok($tab, '==', $count-$i,	'Count items remaining');
		}

		for my $L ($reco, $reco2, $reco3) {
			my($desc, $key) = AEGetNthDesc($L, 1);
			is($key, $type,			'Check key');
			CheckDesc($desc, $type, $datum);
			AEDeleteItem($L, 1);
			my $tab = AECountItems($L);
			$tab =~ s/\D+//;
			is($tab, $count-$i,		'Count items remaining');
		}
	}

	# 8
	for my $L ($list, $list2, $list3, $listg, $reco, $reco2, $reco3, $recog) {
		ok(AEDisposeDesc($L), 			'Dispose list');
	}
}

SKIP: {
#	skip "AECoerce tests", 13+13+13;

	my $string = "abcdef";
	my $desc = AEDesc->new(typeChar, $string);
	my $desc2 = AECoerceDesc($desc, typeUnicodeText);
	my $desc3 = AECoerce(typeChar, $string, typeUnicodeText);

	# 13
	CheckDesc($desc, typeChar, $string);

	CheckRef($desc2, typeUnicodeText);
	CheckType($desc2, typeUnicodeText);
	is(length($desc2->get), 2*length($string),		'Length check');

	CheckRef($desc3, typeUnicodeText);
	CheckType($desc3, typeUnicodeText);
	is(length($desc3->get), 2*length($string),		'Length check');

	is($desc2->get, $desc3->get,				'Value check');

	CheckDispose($desc2);
	CheckDispose($desc3);


	my $keyw = "abcd";
	$desc = AEDesc->new(typeKeyword, $keyw);
	$desc2 = AECoerceDesc($desc, typeChar);
	$desc3 = AECoerce(typeKeyword, $keyw, typeChar);

	# 13
	CheckDesc($desc, typeKeyword, $keyw);
	is($desc2->get, $desc3->get,				'Value check');
	CheckDesc($desc2, typeChar, $keyw);
	CheckDesc($desc3, typeChar, $keyw);



	my $num = 2**18;
	my $num2 = $num + .45;
	$desc = AEDesc->new(typeFloat, MacPack(typeFloat, $num2));
	$desc2 = AECoerceDesc($desc, typeInteger);
	$desc3 = AECoerce(typeFloat, MacPack(typeFloat, $num2), typeInteger);

	# 13
	CheckDesc($desc, typeFloat, $num2);

	CheckRef($desc2, typeInteger);
	CheckType($desc2, typeInteger);
	is($desc2->get, $num,					'Value check');

	CheckRef($desc3, typeInteger);
	CheckType($desc3, typeInteger);
	is($desc3->get, $num,					'Value check');

	is($desc2->get, $desc3->get,				'Value check');

	CheckDispose($desc2);
	CheckDispose($desc3);
}

sub MakeFourChar {
	pack "N", unpack "L", $_[0];
}

sub MakeHex {
	'$' . join('', map { sprintf("%02X", ord) } split //, MakeFourChar($_[0])) . '$';
}

sub MakeNumHex {
	my $hex = '$' . sprintf("%02X", $_[0]) . '$';
	if (length($hex) % 2) {
		$hex =~ s/^\$/\$0/;
	}
	return $hex;
}

sub SkipType {
	my($type) = @_;
	return 1 if $type eq typeShortFloat || $type eq typeFloat || $type eq typeMagnitude || $type eq typeQDRectangle || $type eq typeRGBColor;
	return 0;
}

=pod

=head1 TODO

=over 4

* location/range/comparison/logical?

* AEBuild doesn't work with unsigned 32-bit or floats?

* AEBuild doesn't automatically handle byteswapping of OSTypes

* AEStream WriteData, same problem

=back



__END__
