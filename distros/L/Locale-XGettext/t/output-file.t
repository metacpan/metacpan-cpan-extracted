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

use Test::More tests => 26;

use Locale::XGettext::Text;

BEGIN {
    my $test_dir = __FILE__;
    $test_dir =~ s/[-a-z0-9]+\.t$//i;
    chdir $test_dir or die "cannot chdir to $test_dir: $!";
    unshift @INC, '.';
}

$SIG{DIE} = sub {
    unlink 'messages.po';
    unlink 'domain.po';
    unlink 'output/messages.po';
    unlink 'output/domain.po';
    rmdir 'output';
};

$SIG{DIE}->();

die "could not unlink messages.po" if -e 'messages.po';
die "could not unlink domain.po" if -e 'domain.po';
die "could not unlink output/messages.po" if -e 'output/messages.po';
die "could not unlink output/domain.po" if -e 'output/domain.po';
die "could not rmdir output/" if -e 'output';

ok mkdir 'output';

ok(Locale::XGettext::Text->new({}, 'files/hello.txt')->run->output);
ok -e 'messages.po';
ok unlink 'messages.po';

ok(Locale::XGettext::Text->new({output => 'domain.po'}, 'files/hello.txt')
                         ->run->output);
ok -e 'domain.po';
ok unlink 'domain.po';

ok(Locale::XGettext::Text->new({default_domain => 'domain'}, 
                               'files/hello.txt')
                         ->run->output);
ok -e 'domain.po';
ok unlink 'domain.po';

ok(Locale::XGettext::Text->new({output_dir => 'output'}, 
                               'files/hello.txt')
                         ->run->output);
ok -e 'output/messages.po';
ok unlink 'output/messages.po';

ok(Locale::XGettext::Text->new({output_dir => 'output', output => 'domain.po'}, 
                               'files/hello.txt')
                         ->run->output);
ok -e 'output/domain.po';
ok unlink 'output/domain.po';

ok(Locale::XGettext::Text->new({output_dir => 'output', 
                                default_domain => 'domain'}, 
                                'files/hello.txt')
                         ->run->output);
ok -e 'output/domain.po';
ok unlink 'output/domain.po';

open STDOUT, '>', 'domain.po';
ok(Locale::XGettext::Text->new({default_domain => '-'}, 
                               'files/hello.txt')
                         ->run->output);
ok -e 'domain.po';
ok !-e '-.po';
unlink '-.po';

ok(Locale::XGettext::Text->new({output => '-'}, 
                              'files/hello.txt')
                         ->run->output);
ok -e 'domain.po';
ok !-e '-.po';
unlink '-.po';

ok rmdir 'output';

$SIG{DIE}->();
