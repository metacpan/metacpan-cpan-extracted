#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Intertangle::Punchcard::Backend::Kiwisolver::Context;

use lib 't/lib';

fun create_constraints( $context, $n_rows, $n_cols, $items ) {
	my @constraints;

	my @rows_constraints = map { $context->new_variable( name => "row.$_" ) } (0..$n_rows-1);
	my @cols_constraints = map { $context->new_variable( name => "col.$_" ) } (0..$n_cols-1);
	push @constraints, $_ >= 0 for @rows_constraints;
	push @constraints, $_ >= 0 for @cols_constraints;

	for my $row (0..$n_rows-1) {
		for my $col (0..$n_cols-1) {
			my $this_item = $items->[$row][$col];

			push @constraints, $this_item->{x} >= 0;
			push @constraints, $this_item->{y} >= 0;
			push @constraints, $cols_constraints[$col] >= $this_item->{size}[0];
			push @constraints, $rows_constraints[$row] >= $this_item->{size}[1];

			if( $col > 0 ) {
				my $item_left0 = $items->[$row][$col-1];
				push @constraints, $item_left0->{x} + $cols_constraints[$col-1] == $this_item->{x};
			}
			if( $row > 0 ) {
				my $item_above = $items->[$row-1][$col];
				push @constraints, $item_above->{y} + $rows_constraints[$row-1] == $this_item->{y};
			}
		}
	}

	\@constraints;
}

fun create_items($context, $n_rows, $n_cols) {
	my $items;
	my $item_iter = 0;
	for my $row (0..$n_rows-1) {
		for my $col (0..$n_cols-1) {
			$items->[$row][$col] = {
				x => $context->new_variable( name => "${item_iter}.x" ),
				y => $context->new_variable( name => "${item_iter}.y" ),
			};
			$item_iter++;
		}
	}
	@{ $items->[0][0] }{qw( size color )} = ( [100, 200], 'blue' );
	@{ $items->[0][1] }{qw( size color )} = ( [100, 100], 'green' );
	@{ $items->[1][0] }{qw( size color )} = ( [300, 100], 'red' );
	@{ $items->[1][1] }{qw( size color )} = ( [100, 400], 'yellow' );
	@{ $items->[2][0] }{qw( size color )} = ( [100, 100], 'cyan' );
	@{ $items->[2][1] }{qw( size color )} = ( [100, 100], 'brown' );

	$items;
}

subtest "Test grid constraints" => fun() {
	my ($n_rows, $n_cols) = (3, 2);
	my $context = Intertangle::Punchcard::Backend::Kiwisolver::Context->new;
	my $solver = $context->solver;

	my $items = create_items($context, $n_rows, $n_cols);
	my $constraints = create_constraints( $context, $n_rows, $n_cols, $items );

	for my $constraint (@$constraints) {
		$solver->add_constraint($constraint);
	}
	$solver->add_edit_variable($items->[0][0]{x}, Intertangle::API::Kiwisolver::Strength::STRONG );
	$solver->add_edit_variable($items->[0][0]{y}, Intertangle::API::Kiwisolver::Strength::STRONG );
	$solver->suggest_value($items->[0][0]{x}, 0);
	$solver->suggest_value($items->[0][0]{y}, 0);
	$solver->update;
	#use DDP; p @constraints;
	#use DDP; p $items;


	use SVG;
	my $svg = SVG->new;
	for my $row (0..2) {
		for my $col (0..1) {
			my $item = $items->[$row][$col];
			$svg->rect(
				x => $item->{x}->value,
				y => $item->{y}->value,
				width => $item->{size}[0],
				height => $item->{size}[1],
				fill => $item->{color},
			);
		}
	}
	use Browser::Open;
	my $file = path('_output')->child(__FILE__ . '.svg');
	$file->parent->mkpath;
	$file->spew_utf8($svg->xmlify);
	#Browser::Open::open_browser($file);

	pass;
};

done_testing;
