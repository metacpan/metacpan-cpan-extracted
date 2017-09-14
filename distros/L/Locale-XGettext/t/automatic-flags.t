#! /usr/bin/env perl

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

use strict;

use Test::More tests => 15;

use Locale::XGettext::Text;

BEGIN {
    my $test_dir = __FILE__;
    $test_dir =~ s/[-a-z0-9]+\.t$//i;
    chdir $test_dir or die "cannot chdir to $test_dir: $!";
    unshift @INC, '.';
}

use TestLib qw(find_entries);

my ($xgettext, @po, $entry);

$entry = { msgid => 'Hello, %s!',
           msgid_plural => 'Hello, %s and %s',
           keyword => 'nxgettext',
         };

$xgettext = Locale::XGettext::Test->new({keyword => ['nxgettext:1,2'],
                                         flag => [
                                             'nxgettext:1:c-format',
                                             'nxgettext:2:perl-format'
                                        ]});
$xgettext->_feedEntry($entry);
@po = $xgettext->run->po;
is scalar @po, 2, 'expected two entries';;
ok $po[1]->has_flag('c-format'), 'accumulate flags, singular';
ok $po[1]->has_flag('perl-format'), 'accumulate flags, plural';

$xgettext = Locale::XGettext::Test->new({keyword => ['nxgettext:1,2'],
                                         flag => [
                                             'nonxgettext:1:c-format',
                                             'nonxgettext:2:perl-format'
                                        ]});
$xgettext->_feedEntry($entry);
@po = $xgettext->run->po;
is scalar @po, 2, 'expected two entries';
ok !$po[1]->has_flag('c-format'), 'wrong flag keyword, singular';
ok !$po[1]->has_flag('perl-format'), 'wrong flag keyword, plural';

$xgettext = Locale::XGettext::Test->new({keyword => ['nxgettext:1,2'],
                                         flag => [
                                             'nxgettext:1:c-format',
                                             'nxgettext:3:perl-format'
                                        ]});
$xgettext->_feedEntry($entry);
@po = $xgettext->run->po;
is scalar @po, 2, 'expected two entries';
ok $po[1]->has_flag('c-format'), 'singular flag not taken';
ok !$po[1]->has_flag('perl-format'), 'wrong argument number';

$xgettext = Locale::XGettext::Test->new({keyword => ['nxgettext:1,2'],
                                         flag => [
                                             'nxgettext:1:pass-c-format',
                                             'nxgettext:2:pass-perl-format'
                                        ]});
$xgettext->_feedEntry($entry);
@po = $xgettext->run->po;
is scalar @po, 2, 'expected two entries';
ok $po[1]->has_flag('c-format'), 'pass- not ignored, singular';
ok $po[1]->has_flag('perl-format'), 'pass- not ignored, plural';

$xgettext = Locale::XGettext::Test->new({keyword => ['nxgettext:1,2'],
                                         flag => [
                                             'nxgettext:1:c-format',
                                             'nxgettext:1:no-c-format'
                                        ]});
$xgettext->_feedEntry($entry);
@po = $xgettext->run->po;
is scalar @po, 2, 'expected two entries';
ok !$po[1]->has_flag('no-c-format'), 'conflicting arg, second one did win';
ok $po[1]->has_flag('c-format'), 'conflicting arg, first one did not win';
