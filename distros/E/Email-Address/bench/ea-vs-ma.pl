#!/usr/local/bin/perl;
use Benchmark qw[:all];
use strict;
$^W = 1;

use Email::Address;
use Mail::Address;

sub testit {
    my ($class) = @_;
    open CORPUS, $ARGV[0] or die $!;
    while (<CORPUS>) {
       s/-- ATAT --/@/g;
       my @objs     = $class->parse($_);
       my @new_objs = map $class->new($_->phrase, $_->address, $_->comment), @objs;
       foreach my $obj ( @objs, @new_objs ) {
           foreach ( qw[phrase address comment format name host user] ) {
               my $blah = $obj->$_;
           }
           foreach ( qw[address phrase comment] ) {
               $obj->$_('foo');
           }
       }
    }
    close CORPUS;
}

cmpthese($ARGV[1] || 10, {
  'Mail::Address'  => sub { testit 'Mail::Address' },
  'Email::Address' => sub { testit 'Email::Address' },
});
