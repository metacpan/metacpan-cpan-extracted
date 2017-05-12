#!/usr/bin/perl
# vim: set ft=perl:
use strict;
use Test::More tests => 4;
use ExtUtils::Manifest 'maniread';
use File::Find::Match 'IGNORE', 'MATCH';
use Fatal qw( open close );

my $have  = maniread();
my %found = ();
my @rules;
my $fh;
open $fh, 'MANIFEST.SKIP';
while (my $re = <$fh>) {
    chomp $re;
    push @rules, qr/$re/ => sub { IGNORE };
}
close $fh;

push(@rules,
    dir     => sub { MATCH },
    default => sub { 
        my $s = shift;
        $s =~ s!^\./!!;
        $found{$s} = $have->{$s} = 1;
        return undef;
    },
);
my $finder = new File::Find::Match(@rules);
$finder->find;

is_deeply($have, \%found, 'Check directory structure with File::Find::Match');

%found = ();
$finder = new File::Find::Match(
    -d => sub { MATCH },
    -f => sub { 
        my $s = shift;
        $s =~ s!^\./!!;
        $found{$s} = $have->{$s} = 1;
        return [];
    },
);

$finder->find('.');

is_deeply($have, \%found, 'Check directory structure with File::Find::Match');

eval { File::Find::Match->new(dir => []) };

if ($@) {
	pass("Non-CODEref action died. Yay!");
} else {
	fail("Non-CODEref action did not died. Booh!");
}

eval { File::Find::Match->new(dir => undef) };

if ($@) {
	pass("undef action died. Yay!");
} else {
	fail("undef action did not died. Booh!");
}

