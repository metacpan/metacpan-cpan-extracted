#!/usr/bin/perl

# Portions contributed by Jim Keenan
BEGIN {
    use Test::More 
    # tests => 1;
    qw(no_plan);
    use_ok('List::oo', qw| L |);
}
use strict;
use warnings;
use Data::Dumper;

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);

my ($greaterthan, $l, $g);

$greaterthan = [ grep { $_ gt 'bzzzzz' } @a0 ];
$l = L(@a0);
$g = $l->grep(sub { $_ gt 'bzzzzz' });
is_deeply($greaterthan, $g, 'grep gives predicted results');

$greaterthan = [ grep { $_ gt 'dzzzzz' } @a1 ];
$l = L(@a1);
$g = $l->grep(sub { $_ gt 'dzzzzz' });
is_deeply($greaterthan, $g, 'grep gives predicted results');

my ($results, $m);

$results = [ map { $_ . q{z} } @a0 ];
$l = L(@a0);
$m = $l->map(sub { $_ . q{z} });
is_deeply($results, $m, 'map gives predicted results');

$results = [ map { q{z} . $_  } @a1 ];
$l = L(@a1);
$m = $l->map(sub { q{z} . $_  });
is_deeply($results, $m, 'map gives predicted results');

my ($rev, $r);

$rev = [ reverse @a0 ];
$l = L(@a0);
$r = $l->reverse();
is_deeply($rev, $r, 'reverse gives predicted resuls');

$rev = [ reverse @a1 ];
$l = L(@a1);
$r = $l->reverse();
is_deeply($rev, $r, 'reverse gives predicted resuls');

{
# pretend this is someone else's sub -- e.g. something that requires a
# whole list and returns a whole list and therefore can't be fed
# piecewise ala map.
my $rsub = sub {
	my (@l) = @_;
	my $n = 4;
	my @out;
	while(@l) {
		push(@out, []);
		for(1..$n) {
			@l or last;
			push(@{$out[-1]}, shift(@l));
		}
	}
	return(@out);
}; # end rsub

{
	my @expect = $rsub->(@a0);
	my $dice = L(@a0)->dice($rsub);
	is_deeply([ @expect ], $dice, 'dice gives predicted results');
}

{
	my @expect = $rsub->(@a1);
	my $dice = L(@a1)->dice($rsub);
	is_deeply([ @expect ], $dice, 'dice gives predicted results');
}
}


__END__
print STDERR Dumper(\$greaterthan);
print STDERR Dumper(\$results);
print STDERR Dumper(\$g);
my @a2 = qw(fargo golfer hilton icon icon jerky);
my @a3 = qw(fargo golfer hilton icon icon);
my @a4 = qw(fargo fargo golfer hilton icon);
my @a8 = qw(kappa lambda mu);
print STDERR Dumper(\$m);
print STDERR Dumper(\$n);
