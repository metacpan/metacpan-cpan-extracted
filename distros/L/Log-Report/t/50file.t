#!/usr/bin/env perl
# test the file back-end, without translations

use warnings;
use strict;

use Test::More tests => 39;

use Log::Report;
use POSIX 'locale_h';

setlocale(LC_ALL, 'en_US');

my @disp = dispatcher 'list';
cmp_ok(scalar(@disp), '==', 1);
isa_ok($disp[0], 'Log::Report::Dispatcher');

# start new dispatcher to file

my $file1 = '';
open my($fh1), ">", \$file1 or die $!;
my $d = dispatcher FILE => 'file1', to => $fh1, format => sub {shift};

@disp = dispatcher 'list';
cmp_ok(scalar(@disp), '==', 2);

ok(defined $d, 'created file dispatcher');
isa_ok($d, 'Log::Report::Dispatcher::File');
ok($d==$disp[0] || $d==$disp[1], 'in disp list');
ok(!$d->isDisabled);
is($d->name, 'file1');

my @needs = $d->needs;
cmp_ok(scalar(@needs), '>', 7, 'needs');
is($needs[0], 'NOTICE');
is($needs[-1], 'PANIC');

# start a second dispatcher to a file, which does accept everything
# trace-info.

my $file2 = '';
open my($fh2), ">", \$file2 or die $!;
my $e = dispatcher FILE => 'file2'
  , format_reason => 'UPPERCASE'
  , to => $fh2, accept => '-INFO'
  , format => sub {shift};
ok(defined $e, 'created second disp');
isa_ok($e, 'Log::Report::Dispatcher::File');

@disp = dispatcher 'list';
cmp_ok(scalar(@disp), '==', 3);

@needs = $e->needs;
cmp_ok(scalar(@needs), '>=', 3, 'needs');
is($needs[0], 'TRACE');
is($needs[-1], 'INFO');

# silence default dispatcher for tests

dispatcher close => 'default';

@disp = dispatcher 'list';
cmp_ok(scalar(@disp), '==', 2);

#
# Start producing messages
#

cmp_ok(length $file1, '==', 0);
cmp_ok(length $file2, '==', 0);

trace "trace";
cmp_ok(length $file1, '==', 0, 'disp1 ignores trace');
my $t = length $file2;
cmp_ok($t, '>', 0, 'disp2 take trace');
is($file2, "TRACE: trace\n");

my $linenr = __LINE__ +1;
assert "assertive";
cmp_ok(length $file1, '==', 0, 'disp1 ignores assert');
my $t2 = length $file2;
cmp_ok($t2, '>', $t, 'disp2 take assert');
is(substr($file2, $t), "ASSERT: assertive\n at $0 line $linenr\n");

info "just to inform you";
cmp_ok(length $file1, '==', 0, 'disp1 ignores info');
my $t3 = length $file2;
cmp_ok($t3, '>', $t2, 'disp2 take info');
is(substr($file2, $t2), "INFO: just to inform you\n");

notice "note this!";
my $s = length $file1;
cmp_ok($s, '>', 0, 'disp1 take notice');
is($file1, "notice: note this!\n");  # format_reason LOWERCASE
my $t4 = length $file2;
cmp_ok($t4, '==', $t3, 'disp2 ignores notice');

warning "oops, be warned!";
my $s2 = length $file1;
cmp_ok($s2, '>', $s, 'disp1 take warning');
like(substr($file1, $s), qr/^warning: oops, be warned!/);
my $t5 = length $file2;
cmp_ok($t5, '==', $t4, 'disp2 ignores warnings');

#
# test filters
#

my (@messages, @messages2);
dispatcher filter => sub { push @messages,  $_[3]; @_[2,3] }, 'file1';
dispatcher filter => sub { push @messages2, $_[3]; @_[2,3] }, 'file2';

notice "here <we> are";
cmp_ok(scalar(@messages), '==', 1, 'capture message');
is($messages[0]->toString, 'here <we> are', 'toString');
is($messages[0]->toHTML, 'here &lt;we&gt; are', 'toHTML');

cmp_ok(scalar(@messages2), '==', 0, 'do not capture message');
