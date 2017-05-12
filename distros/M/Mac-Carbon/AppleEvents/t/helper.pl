#!/usr/bin/perl
use warnings;
use strict;

# 4/5
sub CheckDesc {
	my($desc, $type, $datum) = @_;

	CheckRef($desc, $type);
	CheckType($desc, $type);
	CheckVal($desc, $type, $datum);
	CheckDispose($desc);
}

# 1
sub CheckVal {
	my($desc, $type, $datum) = @_;

	my @val = $desc->get;
	my $val = $val[0];

	if (@val > 1) {
		my $ok = 1;
		for (0 .. $#val) {
			$ok = 0 unless $datum->[$_] eq $val[$_];
		}
		ok($ok,				"Check value: '@val' == '@$datum'");
	} elsif ($type eq typeShortFloat || $type eq typeFloat) {
		my $num = abs($val - $datum);
		ok($num < .01,			"Check value: $val ~ $datum");
	} elsif ($type eq typeFSS) {
		is(MakePath($val), $datum,	"Check value: $datum");
	} else {
		is($val, $datum,		"Check value: $val == $datum");
	}
}

# 1/2
sub CheckRef {
	my($desc, $type) = @_;
	my $ref = ref $desc;

	if ($ref eq 'AEKeyDesc') {
		# ok, so this is kinda lame, oh well ... we know if we are here,
		# though, we are expecting the second test, so our numbers will
		# be off if we don't get here
		is($ref, 'AEKeyDesc',		'Create AEKeyDesc');
		is($desc->key, $type,		"Check key: $type");
	} else {
		is($ref, 'AEDesc',		'Create AEDesc');
	}
}

# 1
sub CheckType {
	my($desc, $type) = @_;

	is($desc->type, $type,			"Check type: $type");
}

sub CheckRefType {
	my($desc, $type) = @_;
	CheckRef($desc, $type);
	CheckType($desc, $type);
}

# 1
sub CheckDispose {
	my($desc) = @_;
	my $ref = ref $desc;

	ok($desc->dispose,			'Dispose');
}

1;

__END__
