#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Intertangle::Jacquard::Actor;
use Intertangle::Jacquard::Layout::Grid;

use lib 't/lib';

package SVGActor {
	use SVG;
	use Mu;
	extends qw(Intertangle::Jacquard::Actor);

	ro 'color';

	ro 'width';
	ro 'height';

	method render($svg) {
		$svg->rect(
			x => $self->x->value,
			y => $self->y->value,
			width => $self->width,
			height => $self->height,
			fill => $self->color,
		);
	}

	with qw(Intertangle::Jacquard::Role::Geometry::Position2D);
	#Intertangle::Jacquard::Role::Geometry::Size2D
}

subtest "Test grid layout" => fun() {
	my $layout_group = Moo::Role->create_class_with_roles(
		'Intertangle::Jacquard::Actor' => qw(
		Intertangle::Jacquard::Role::Geometry::Position2D
		Intertangle::Jacquard::Role::Geometry::Size2D
		Intertangle::Jacquard::Role::Render::QnD::SVG::Group
		Intertangle::Jacquard::Role::Render::QnD::Layout
	));
	my $group = $layout_group->new(
		layout => Intertangle::Jacquard::Layout::Grid->new( rows => 3, columns => 2 ),
	);

	$group->x->value( 0 );
	$group->y->value( 0 );

	my @child_data = (
		[ [100, 200], 'blue' ],
		[ [100, 100], 'green' ],
		[ [300, 100], 'red' ],
		[ [100, 400], 'yellow' ],
		[ [100, 100], 'cyan' ],
		[ [100, 100], 'brown' ],
	);

	for my $cd (@child_data) {
		my $actor = SVGActor->new(
			color => $cd->[1],
			width  => $cd->[0][0],
			height => $cd->[0][1],
		);
		#$actor->width->value ( $cd->[0][0] );
		#$actor->height->value( $cd->[0][1] );
		$group->add_child($actor);
	}

	$group->update_layout;

	my $svg = SVG->new;
	$group->render($svg);
	my $file = path('_output')->child(__FILE__ . '.svg');
	$file->parent->mkpath;
	$file->spew_utf8($svg->xmlify);
	#use Browser::Open; Browser::Open::open_browser($file);

	pass;
};

done_testing;
