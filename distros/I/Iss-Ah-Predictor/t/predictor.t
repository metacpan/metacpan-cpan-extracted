#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use ISS::AH::Predictor;

plan tests => 3;

subtest 'should modify params', sub {
  my %params = ISS::AH::Predictor::_modify_params(
    age      => 12,
    bone_age => 12,
  );
  is_deeply \%params,
    {
    age              => 12,
    bone_age         => 12,
    bone_age_per_age => 1,
    },
    'params as expected';
};

subtest 'should get model', sub {
  my $model = ISS::AH::Predictor::get_model(
    age           => 12,
    body_height   => 130,
    father_height => 180,
    bone_age      => 12,
    sex           => 'male',
  );
  ok $model, 'model retrieved';
  is $model->[0], 94.2381, 'intercept param as expected';

  $model = ISS::AH::Predictor::get_model(
    body_height   => 130,
    father_height => 180,
    bone_age      => 12,
    sex           => 'male',
  );
  ok !$model, 'missing required params, no model retrieved';

  $model = ISS::AH::Predictor::get_model(
    age           => 12,
    body_height   => 130,
    father_height => 180,
    bone_age      => 12,
    sex           => 'male',
    models        => [],
  );
  ok !$model, 'empty custom models, no model retrieved';

  $model = ISS::AH::Predictor::get_model(
    age    => 12,
    models => [ [ 1, 1 ] ],
  );
  ok $model, 'custom model retrieved';
  is $model->[0], 1, 'intercept param as expected';
};

subtest 'should perform prediction', sub {
  my $prediction = ISS::AH::Predictor::predict(
    age           => 12,
    body_height   => 130,
    father_height => 180,
    bone_age      => 12,
    sex           => 'male',
  );
  is $prediction, 164.6488, 'prediction as expected';

  $prediction = ISS::AH::Predictor::predict(age => 12);
  ok !$prediction, 'invalid input, prediction is undef';
};

done_testing;
