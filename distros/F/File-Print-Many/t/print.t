#!perl -w

use strict;
use warnings;
use autodie;
use Test::Most tests => 13;
use Test::NoWarnings;
use Test::TempDir::Tiny;
use File::Spec;
use Test::Carp;

BEGIN {
	use_ok('File::Print::Many');
}

PRINT: {
	my $tempdir = tempdir();
	my $tmp1 = File::Spec->catfile($tempdir, 'f1');
	my $tmp2 = File::Spec->catfile($tempdir, 'f2');

	open(my $fout1, '>', $tmp1);
	open(my $fout2, '>', $tmp2);

	my $many = File::Print::Many->new([ $fout1, $fout2 ]);

	# print $many 'hello, ', "world!\n";
	$many->print('hello, ', "world!\n");

	close $fout1;
	close $fout2;

	open(my $fin, '<', $tmp1);
	my $contents;
	while(<$fin>) {
		$contents .= $_;
	}
	close($fin);
	ok($contents eq "hello, world!\n");

	open($fin, '<', $tmp2);
	$contents = undef;
	while(<$fin>) {
		$contents .= $_;
	}
	close($fin);
	ok($contents eq "hello, world!\n");

	open($fout1, '>', $tmp1);
	open($fout2, '>', $tmp2);

	$many = File::Print::Many->new(fds => [ $fout1, $fout2 ]);

	# print $many 'hello, ', "world!\n";
	$many->print('hello, ', "world!\n");

	close $fout1;
	close $fout2;

	open($fin, '<', $tmp1);
	$contents = undef;
	while(<$fin>) {
		$contents .= $_;
	}
	close($fin);
	ok($contents eq "hello, world!\n");

	open($fin, '<', $tmp2);
	$contents = undef;
	while(<$fin>) {
		$contents .= $_;
	}
	close($fin);
	ok($contents eq "hello, world!\n");

	open($fout1, '>', $tmp1);
	open($fout2, '>', $tmp2);

	$many = File::Print::Many->new({ fds => [ $fout1, $fout2 ] });

	# print $many 'hello, ', "world!\n";
	$many->print('hello, ', "world!\n");

	close $fout1;
	close $fout2;

	open($fin, '<', $tmp1);
	$contents = undef;
	while(<$fin>) {
		$contents .= $_;
	}
	close($fin);
	ok($contents eq "hello, world!\n");

	open($fin, '<', $tmp2);
	$contents = undef;
	while(<$fin>) {
		$contents .= $_;
	}
	close($fin);
	ok($contents eq "hello, world!\n");

	unlink $tmp1;
	unlink $tmp2;

	does_croak(sub {
		my $foo = File::Print::Many->new();
	});
	does_croak(sub {
		my $foo = File::Print::Many->new(fds => { foo => 'bar' });
	});
	does_croak(sub {
		my $foo = File::Print::Many->new(fds => undef);
	});
	does_croak(sub {
		my $foo = File::Print::Many->new({ fds => [ undef ] });
	});
	does_croak(sub {
		my $foo = File::Print::Many->new({ fds => undef });
	});
}
