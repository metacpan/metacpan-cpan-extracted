#!/usr/bin/perl
use warnings;
use strict;
use FindBin '$Bin';

use Test::More tests => 1+(42+15)+(37+5)+(4+41+19)+(47*3);

BEGIN {
	use_ok('Mac::AppleEvents');
	require "$Bin/helper.pl";
}

use File::Spec::Functions qw(catdir tmpdir);
use Mac::Files;
use Mac::Types;

my $name = 'mac-carbon-aeevent-test';
my $file = catdir(tmpdir(), $name);
my $filehex = MakeHexUTF16($name);

my $newname = 'mac-carbon-aeevent-test2';
my $newfile = $file . '2';

END {
#	unlink $file;
#	unlink $newfile;
}


SKIP: {
	skip "AECreateAppleEvent", 42+15+47
		unless $ENV{MAC_CARBON_GUI};

	## reveal file 4+1+15+20+2=42
	# 4
	my $target = AEDesc->new(typeApplSignature, 'MACS');
	CheckRefType($target, typeApplSignature);
	# misc/mvis = reveal
	my $event = AECreateAppleEvent('misc', 'mvis', $target);
	CheckRefType($event, typeAppleEvent);

	# 1
	{ open my $fh, '>', $file or die $!;
	  print $fh "testing\n";
	}
	ok(-e $file,							'Check test file exists');

	# 15
	my $alias = NewAliasMinimalFromFullPath($file);
	is(ref $alias, 'Handle',					'Check Handle ref type');

	my $aliasdesc = AEDesc->new(typeAlias, $alias);
	CheckRefType($aliasdesc, typeAlias);
	ok(AEPutParamDesc($event, keyDirectObject, $aliasdesc),		'AEPutParamDesc');
	CheckDispose($aliasdesc);

	my $reply = CheckSuccess($event);
	my $filedesc = AEGetParamDesc($reply, keyDirectObject);
	CheckRefType($filedesc, typeObjectSpecifier);

	# 20
	CheckAttributes($event, $reply, qw(misc mvis MACS));

	# 2
	CheckDispose($event);
	CheckDispose($reply);

	## change file name 2+2+11=15
	# 2
	$event = AECreateAppleEvent('core', 'setd', $target);
	CheckRefType($event, typeAppleEvent);

	# 2
	my $filenamedesc = AECreateList('', 1);
	CheckRefType($filenamedesc, typeAERecord);

	# 11
	ok(AEPutKey    ($filenamedesc, keyAEForm,         typeEnumerated, typeProperty), 	'AEPutKey');
	ok(AEPutKey    ($filenamedesc, keyAEDesiredClass, typeType,       typeProperty), 	'AEPutKey');
	ok(AEPutKeyDesc($filenamedesc, keyAEContainer,    $filedesc), 				'AEPutKeyDesc');
	ok(AEPutKey    ($filenamedesc, keyAEKeyData,      typeType,       'pnam'), 		'AEPutKey'); # name
	my $obj = AECoerceDesc($filenamedesc, typeObjectSpecifier);
	CheckRefType($obj, typeObjectSpecifier);
	CheckDispose($filenamedesc);

	ok(AEPutParamDesc($event, keyDirectObject, $obj),		'AEPutParamDesc');
	ok(AEPutParam($event, 'data', typeChar, $newname), 		'AEPutParam');

	CheckDispose($obj);

	CheckDispose($target);

	Finish($event);
}

SKIP: {
	skip "AEBuildAppleEvent", 37+5+47
		unless $ENV{MAC_CARBON_GUI} && $ENV{MAC_CARBON_AEFMT};

	## reveal file 2+1+12+20+2=37
	# 2
	# misc/mvis = reveal
	my $event = AEBuildAppleEvent('misc', 'mvis', typeApplSignature, 'MACS', kAutoGenerateReturnID, kAnyTransactionID, '');
	CheckRefType($event, typeAppleEvent);

	# 1
	{ open my $fh, '>', $file or die $!;
	  print $fh "testing\n";
	}
	ok(-e $file,							'Check test file exists');

	# 12
	my $alias = NewAliasMinimalFromFullPath($file);
	is(ref $alias, 'Handle',					'Check Handle ref type');

	ok(AEBuildParameters($event, q"'----':alis(@@)", $alias), 	'AEBuildParameters');

	my $reply = CheckSuccess($event);
	my $filedesc = AEGetParamDesc($reply, keyDirectObject);
	CheckRefType($filedesc, typeObjectSpecifier);

	# 20
	CheckAttributes($event, $reply, qw(misc mvis MACS));

	# 2
	CheckDispose($event);
	CheckDispose($reply);

	## change file name 2+3=5
	# 2
	$event = AEBuildAppleEvent('core', 'setd', typeApplSignature, 'MACS', kAutoGenerateReturnID, kAnyTransactionID, '');
	CheckRefType($event, typeAppleEvent);

	# 3
	my $filedesc_print = AEPrint($filedesc);
	like($filedesc_print, qr/^'?obj /,				'AEPrint');
	#diag($filedesc_print);

	# Apple bugs ... really, since the format of AEPrint can change,
	# this might be a bad way to do the tests, but I'll worry about it
	# when it breaks ... for now, I just need to get it done, and besides,
	# this helped me identify some bugs in AEPrint
	$filedesc_print =~ s/''null''/'null'/g;
	$filedesc_print =~ s/'?want'?:'(\w+)'/'want':type($1)/g;
	$filedesc_print =~ s/'?seld'?:'sdsk'/'seld':type(sdsk)/g;

	#diag($filehex);
	while ($filedesc_print =~ /\(\$(.+?)\$\)/g) {
		my $x = my $y = $1;
		$x =~ s/[^A-F0-9]+//g;
		#diag($x);
		next unless $filehex =~ /^\Q$x\E/;
		#diag('!!');
		if ($x ne $y) {
			$filedesc_print =~ s/'?utxt'?\(\$$y\$\)/'TEXT'(\@)/;
		}
	}
	#diag($filedesc_print);

	#$filedesc_print =~ s/'utxt':("mac-carbon-aeevent-test")/'TEXT'(\@)/;
	my $fmt = "'----':'obj '{ 'form':'prop', 'want':type(prop), 'from':$filedesc_print, 'seld':type(pnam) }";
	# $fmt = q"'----':'obj '{ 'form':prop, 'want':type(prop), 'from':'obj '{ 'want':type(docf), 'from':'obj '{ 'want':type(cfol), 'from':'obj '{ 'want':type(cobj), 'from':'obj '{ 'want':type(prop), 'from':'null'(), 'form':prop, 'seld':type(sdsk) }, 'form':name, 'seld':'utxt'($0070007200690076006100740065$) }, 'form':name, 'seld':'utxt'($0074006D0070$) }, 'form':name, 'seld':'TEXT'(@) }, 'seld':type(pnam) }";
	#diag($fmt);

	my @params = ($event, $fmt);
	push @params, 'mac-carbon-aeevent-test' if $fmt =~ /\@/;
	#diag($fmt);
	ok(AEBuildParameters(@params),  'AEBuildParameters');
	#diag($@);

	ok(AEBuildParameters($event, 'data:TEXT(@)', $newname),         'AEBuildParameters');
	#diag(AEPrint($event));

	Finish($event);
}

SKIP: {
	skip "AEStream", 4+41+19+47
		unless $ENV{MAC_CARBON_GUI};

	## Quick Abort check 4
	ok(my $stream_abort = AEStream->new,				'AEStream->new/Open');
	ok($stream_abort->OpenDesc(typeInteger),			'OpenDesc');
	ok($stream_abort->WriteData(12334567890),			'WriteData');
	is($stream_abort->Abort, 0,					'Abort!');

	## reveal file 3+1+15+20+2=41
	# 3
	# misc/mvis = reveal
	# OpenEvent
	my $event1 = AEBuildAppleEvent('misc', 'mvis', typeApplSignature, 'MACS', kAutoGenerateReturnID, kAnyTransactionID, '');
	CheckRefType($event1, typeAppleEvent);
	ok(my $stream = AEStream->new($event1),				'AEStream->new/OpenEvent');

	# 1
	{ open my $fh, '>', $file or die $!;
	  print $fh "testing\n";
	}
	ok(-e $file,							'Check test file exists');

	# 16
	my $alias = NewAliasMinimalFromFullPath($file);
	is(ref $alias, 'Handle',					'Check Handle ref type');

	ok($stream->WriteKey(keyDirectObject),				'WriteKey keyDirectObject');
	ok($stream->OpenDesc(typeAlias), 				'OpenDesc typeAlias');
	ok($stream->WriteData($alias->get), 				'WriteData alias');
	ok($stream->CloseDesc,						'CloseDesc');

	my $event = $stream->Close;
	CheckRefType($event, typeAppleEvent);

	my $reply = CheckSuccess($event);
	my $filedesc = AEGetParamDesc($reply, keyDirectObject);
	CheckRefType($filedesc, typeObjectSpecifier);

	# 20
	CheckAttributes($event, $reply, qw(misc mvis MACS));

	# 2
	CheckDispose($event);
	CheckDispose($reply);

	## change file name 19
	# CreateEvent
	ok($stream = AEStream->new('core', 'setd', typeApplSignature, 'MACS'),		'AEStream->new/CreateEvent');

	ok($stream->WriteKey(keyDirectObject),						'WriteKey direct object');
	ok($stream->OpenRecord(typeLogicalDescriptor),					'OpenRecord logical typeLogicalDescriptor');
	ok($stream->WriteKeyDesc(keyAEForm,         typeEnumerated, typeProperty),	'WriteKeyDesc form prop');
	ok($stream->WriteKeyDesc(keyAEDesiredClass, typeType,       typeProperty),	'WriteKeyDesc want prop');
	ok($stream->WriteKey(keyAEContainer),						'WriteKeyDesc from');
	ok($stream->WriteAEDesc($filedesc),						'WriteAEDesc from');
	ok($stream->WriteKeyDesc(keyAEKeyData,      typeType,       'pnam'),		'WriteKeyDesc seld pnam');
	ok($stream->SetRecordType(typeObjectSpecifier),					'SetRecordType keyDirectObject');
	ok($stream->CloseRecord,							'CloseRecord');

	ok($stream->OpenKeyDesc('data', typeChar),					'OpenKeyDesc data typeChar');
	ok($stream->WriteData($newname),						'WriteData name');
	ok($stream->CloseDesc, 								'CloseDesc');

	ok($stream->WriteKeyDesc('doof', typeChar, 'floobydoo!'),			'WriteKeyDesc for optional');
	ok($stream->OptionalParam('doof'),						'OptionalParam');

	$event = $stream->Close;

	CheckRefType($event, typeAppleEvent);

	Finish($event);
}

# 6+11+28+2=47
sub Finish {
	my($event) = @_;
	# 6
	ok(AEPutAttribute($event, keyOptionalKeywordAttr, typeInteger, MacPack(typeInteger, 1)), 	'AEPutAttribute');

	my $vers = 'version .129381231';
	my $miss = AEDesc->new(typeChar, $vers);
	ok(AEPutAttributeDesc($event, keyAEVersion, $miss),						'AEPutAttributeDesc');
	CheckDesc($miss, typeChar, $vers);

	# 11
	my $reply = CheckSuccess($event);

	SKIP: {
		skip "Set MAC_CARBON_GUI in env to run tests", 3
			unless $ENV{MAC_CARBON_GUI};

		is(AECountItems($reply), 1,					'Count reply');
		ok(AEDeleteParam($reply, keyDirectObject),			'Delete reply');
		cmp_ok(AECountItems($reply), '==', 0,				'Count reply');
	}

	# 28
	CheckAttributes($event, $reply, qw(core setd MACS));
	CheckAttribute($event, keyOptionalKeywordAttr, typeInteger, 1);
	CheckAttribute($event, keyAEVersion, typeChar, $vers);

	# 2
	CheckDispose($event);
	CheckDispose($reply);

	unlink $file;
	unlink $newfile;
}

# 8
sub CheckSuccess {
	my($event) = @_;

	my $reply = AESend($event, kAEWaitReply);

	CheckRefType($event, typeAppleEvent);
	CheckRefType($reply, typeAppleEvent);

	SKIP: {
		skip "Set MAC_CARBON_GUI in env to run tests", 4
			unless $ENV{MAC_CARBON_GUI};

		my $errn = AEGetParamDesc($reply, keyErrorNumber);
		cmp_ok($!, '==', -1701,						'No error');

		my $errs = AEGetParamDesc($reply, keyErrorString);
		cmp_ok($!, '==', -1701,						'No error');

		for my $err ($errn, $errs) {
			if ($err) {
				is($err->get, 0, 'Error?');
			} else {
				pass('Still no error');
			}
		}
	}

	#diag(AEPrint($event));
	#diag(AEPrint($reply));

	return $reply;
}

# 4
sub CheckAttribute {
	my($event, $key, $type, $val) = @_;

	my $desc = AEGetAttributeDesc($event, $key, $type);
	CheckDesc($desc, $type, $val);
}

# 20
sub CheckAttributes {
	my($event, $reply, @vals) = @_;

	CheckAttribute($event, keyEventClassAttr, typeType,          $vals[0]);
	CheckAttribute($event, keyEventIDAttr,    typeChar,          $vals[1]); # for fun
	CheckAttribute($event, keyAddressAttr,    typeApplSignature, $vals[2]);
	CheckAttribute($reply, keyEventClassAttr, typeChar,          'aevt');
	CheckAttribute($reply, keyEventIDAttr,    typeType,          'ansr');
}

sub MakeHexUTF16 {
	use Config;
	my $fmt = $Config{byteorder} == 4321 ? '00%02X' : '%02X00';
	join('', map { sprintf($fmt, ord) } split //, $_[0]);
}

__END__
