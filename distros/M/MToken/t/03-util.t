#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03-util.t 82 2021-03-15 08:28:17Z minus $
#
#########################################################################
use Test::More tests => 4;
use MToken::Util qw/tcd_load tcd_save sha1sum/;
ok(MToken::Util->VERSION,'MToken::Util version');

# TCD test
{
	my $tcd_file = "test.tcd";
	my $string = "Blah-Blah-Blah!";
	ok(tcd_save($tcd_file, $string), "Save TCD04 file");
	my $result = tcd_load($tcd_file) // "";
	is($result, $string, "Load TCD04 file");
	unlink($tcd_file) if -e $tcd_file;
}

# SHA1 test
SKIP: {
	skip "LICENSE file not exists", 1 unless -e 'LICENSE';
	my $sha1 = sha1sum('LICENSE');
	is($sha1, "1a6f4a41ae8eec2da84dbfa48636e02e33575dbd", "SHA1 for LICENSE")
}


1;
