#!/usr/bin/env perl

use Test2::V0;
use Test2::Compare::Float;

use Renard::Incunabula::Common::Setup;

use Intertangle::Taffeta::Transform::Affine2D::WithOrigin;
use Intertangle::Taffeta::Transform::Affine2D::Rotation;
use Intertangle::Taffeta::Transform::Affine2D::Scaling;

subtest "Rotation" => sub {
	my $t = Intertangle::Taffeta::Transform::Affine2D::WithOrigin->new(
		affine2d => Intertangle::Taffeta::Transform::Affine2D::Rotation->new( angle => 45 ),
		origin => [1, 1],
	);

	is $t->apply_to_point( [1, 1] )->to_ArrayRef, [1, 1], 'rotate 45 clockwise about [1,1] to [1,1] - origin stays in place';

	is $t->apply_to_point( [1 + sqrt(2)/2, 1 + sqrt(2)/2 ] )->to_ArrayRef,
		[
			map {
				Test2::Compare::Float->new( input => $_, tolerance => 1e-6 )
			}
			(1,2)
		], 'rotate 45 clockwise about [1,1] to [1,2] - bottom right';

	is $t->apply_to_point( [1 - sqrt(2)/2, 1 - sqrt(2)/2 ] )->to_ArrayRef,
		[
			map {
				Test2::Compare::Float->new( input => $_, tolerance => 1e-6 )
			}
			(1,0)
		], 'rotate 45 clockwise about [1,1] to [1,0] - top left';
};

subtest "Scaling" => sub {
	my $scaling = Intertangle::Taffeta::Transform::Affine2D::Scaling->new( scale => [2, 2] );
	my $t = Intertangle::Taffeta::Transform::Affine2D::WithOrigin->new(
		affine2d => $scaling,
		origin => [-1, -1],
	);

	is $scaling->apply_to_point( [1, 1] )->to_ArrayRef, [2, 2], 'scale w/o origin: [1,1] to [2,2]';
	is $t->apply_to_point( [1, 1] )->to_ArrayRef, [3, 3], 'scale w/ origin: [1,1] to [3,3]';
};

done_testing;
