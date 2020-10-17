#!/usr/bin/env perl

use Test::Most tests => 1;
use Renard::Incunabula::Common::Setup;
use Intertangle::Taffeta::Transform::Affine2D::Translation;

subtest "Build an affine translation" => sub {
	my $translate = Intertangle::Taffeta::Transform::Affine2D::Translation->new(
		translate => [2, 4],
	);

	is $translate->apply_to_point( [0, 0] ), [2, 4], 'translate [0,0] -> [2,4]';
	is $translate->apply_to_point( [8, 6] ), [10, 10], 'translate [8,6] -> [10,10]';
};

done_testing;
