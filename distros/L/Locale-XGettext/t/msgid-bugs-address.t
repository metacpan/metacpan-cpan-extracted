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

use Test::More tests => 2;

use Locale::XGettext::Text;

my $test_dir = __FILE__;
$test_dir =~ s/[-a-z0-9]+\.t$//i;
chdir $test_dir or die "cannot chdir to $test_dir: $!";

my $sol = '(?:\\A|\\\\n)';
my $eol = '(?:\\E|\\\\n)';

my @po = Locale::XGettext::Text->new({}, 'files/hello.txt')->run->po;
like $po[0]->msgstr, qr/${sol}Report-Msgid-Bugs-To: ${eol}/m;

@po = Locale::XGettext::Text->new({msgid_bugs_address => 'bugtracker'}, 
                                  'files/hello.txt')->run->po;
like $po[0]->msgstr, qr/${sol}Report-Msgid-Bugs-To: bugtracker${eol}/m;
