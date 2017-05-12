#!/usr/bin/env perl
#===============================================================================
#       AUTHOR:  Alec Chen , <alec@cpan.org>
#===============================================================================

use strict;
use warnings;
use Finance::QuoteTW;
use Data::TreeDumper;
use Term::Pulse;

my $q = Finance::QuoteTW->new;

=pod
my @result = $q->fetch( site => 'allianz' );
print DumpTree(\@result);
=cut

pulse_start( rotate => 1, time => 1 );
my %result = $q->fetch_all;
pulse_stop();
print DumpTree(\%result);

foreach my $key (keys %result) {
    print "useless = $key\n" if @{ $result{$key} } == 0;
}
