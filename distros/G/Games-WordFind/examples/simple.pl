#!/usr/bin/perl -w
use lib '../blib/lib';
use strict;
use Games::WordFind;
#
# very simple example:
my $puz=Games::WordFind->new({cols=>12});
my @words = qw(linux perl free great);
$puz->create_puzzle(@words);
print $puz->get_plain({solution=>1});
# # re-use the object for another puzzle:
@words = qw(zippity doo dah);
$puz->create_puzzle(@words);
print $puz->get_plain({solution=>1});
__END__
