#!/usr/bin/perl
#
#

use Getopt::Long;
use Games::Maze;
use warnings;
use strict;

my $makefn = 'rnd';
my($rows, $cols, $lvls) = (3,3,3);

my %maker = (
	rnd => \&random_dir,
	first => \&first_dir,
	altrn => \&altrn_dir,
	foreward => \&foreward_dir,
);
my $last_dir = $Games::Maze::North;

GetOptions('make=s' => \$makefn,
	'rows=i' => \$rows,
	'cols=i' => \$cols,
	'lvls=i' => \$lvls,
);

$makefn = 'rnd' unless (exists $maker{$makefn});

my $minos = Games::Maze->new(
		dimensions => [$cols, $rows, $lvls],
		fn_choosedir => $maker{$makefn},
		);

$minos->make();
print $minos->to_ascii();

#$minos->solve();
#print $minos->to_ascii();

exit(0);

sub random_dir
{
	return ${$_[0]}[int(rand(@{$_[0]}))];
}

sub first_dir
{
	return ${$_[0]}[0];
}

sub altrn_dir
{
	my($direction_ref, $position_ref) = @_;
	my($r, $c, $l) = @{$position_ref};

	if ((($c ^ $r) & 4) == 4)
	{
		return ${$direction_ref}[$#{$direction_ref}];
	}
	else
	{
		return ${$direction_ref}[0];
	}
}

sub foreward_dir
{
	foreach my $d (@{$_[0]})
	{
		return $last_dir = $d if ($last_dir <= $d);
	}
	return $last_dir = ${$_[0]}[0];
}
