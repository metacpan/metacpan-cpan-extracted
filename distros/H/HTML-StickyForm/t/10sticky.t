#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Test::More tests => 17;
use Test::NoWarnings;

my $Form;
BEGIN{
  use_ok($Form='HTML::StickyForm');
  use_ok('CGI');
}

# Set up empty and full
my $q_empty=CGI->new('');
my $q_full=CGI->new('abc=1');
isa_ok(my $empty=$Form->new($q_empty),$Form,'empty');
isa_ok(my $full=$Form->new($q_full),$Form,'full');

# Check the initial sticky status
ok(!$empty->get_sticky,'empty not sticky');
ok($full->set_sticky,'full sticky');

# Update the request objects, which shouldn't change the sticky status
$q_empty->param(abc => 1);
ok(!$empty->get_sticky,'empty still not sticky');
$q_full->delete(abc =>);
ok($full->get_sticky,'full still sticky');

# Set the sticky status according to the new parameters
ok($empty->set_sticky,'empty sticky!');
ok(!$full->set_sticky,'full not sticky!');

# Make sure it stays set
ok($empty->get_sticky,'empty still sticky');
ok(!$full->get_sticky,'full still not sticky');

# Set the sticky status according to an explcit argument
ok(!$empty->set_sticky(0),'empty not sticky!');
ok($full->set_sticky(1),'full sticky!');

# Make sure it stays set
ok(!$empty->get_sticky,'empty still not sticky');
ok($full->get_sticky,'full still sticky');

