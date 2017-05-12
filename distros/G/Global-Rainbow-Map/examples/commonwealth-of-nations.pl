
use Global::Rainbow::Map;
use constant {
	current_member     => '#ff0000',
	former_member      => '#009900',
	suspended_member   => '#3333ff',
	prospective_member => '#ffa000',
};

my $map = Global::Rainbow::Map->new(
	(map { $_ => current_member } qw<
		ag au bs bd bb bz bw bn cm ca cy dm gm gh gd gy in jm
		ke ki ls mw my mv mt mu mz na nr nz ng pk pg rw kn lc
		vc ws sc sl sg sb za lk sz tz to tt tv ug gb vu zm >),
	(map { $_ => former_member } qw< ie zw >),
	(map { $_ => suspended_member } qw< fj >),
	(map { $_ => prospective_member } qw< dz mg ss sd ye >),
);

print $map->svg;
