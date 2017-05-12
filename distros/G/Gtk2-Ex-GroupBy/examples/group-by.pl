#!/usr/bin/perl -w
use strict;
use Gtk2 -init;
use Glib ':constants';
use Gtk2::Ex::GroupBy;
use Data::Dumper;

my $groupby = Gtk2::Ex::GroupBy->new;
$groupby->set_model({
	'groupby' => [
		[
			'Product', 'Category'
		],
		[
			'State', 'Country'
		],
	],
	'formula'  => [
		[
			{ field => 'Revenue', formula => 'SUM of'},
			{ field => 'Expenses', formula => 'SUM of'},
			{ field => 'Margin', formula => 'AVG of'},
			{ field => 'Sales', formula => 'SUM of'},
		],
		[
			{ field => 'Costs', formula => 'SUM of'},
			{ field => 'Price', formula => 'AVG of'},
		],
	]
});
$groupby->signal_connect( 'changed' => 
	sub {
		#_make_sql($groupby->get_model);
	}
);
$groupby->signal_connect( 'closed' => 
	sub {	
		_make_sql($groupby->get_model, "my_table");
		Gtk2->main_quit;
	}
);

my $window = Gtk2::Window->new;
$window->signal_connect (destroy => sub { Gtk2->main_quit });
#$window->set_default_size(300, 400);
$window->add ($groupby->get_widget);
$window->show_all;
Gtk2->main;

sub _make_sql {
	my ($model, $table) = @_;
	print Dumper $model;
	my @group;
	my @formula;
	foreach my $x (@{$model->{'groupby'}->[0]}) {
		push @group, $x;
	}
	foreach my $x (@{$model->{'formula'}->[0]}) {
		my $f = $x->{'formula'};
		$f =~ s/ of$//;
		push @formula, $f.'('.$x->{'field'}.')';
	}
	my $groupstr = join ',', @group;
	my $formulastr = join ',', @formula;
	print Dumper \@group;
	print Dumper \@formula;
	my $query = "select $groupstr,$formulastr from $table group by $groupstr"
		if $groupstr;
	print Dumper $query;
}