#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03-util.t 68 2019-06-08 10:59:56Z minus $
#
#########################################################################
use Test::More tests => 3;
use MToken::Util qw/tcd_load tcd_save/;
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

1;
