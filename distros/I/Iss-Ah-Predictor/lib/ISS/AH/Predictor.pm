package ISS::AH::Predictor;

use v5.10;
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

=head1 NAME

ISS::AH::Predictor - Provides prediction models for adult height (AH) in patients with idiopathic short stature (ISS).

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

  use ISS::AH::Predictor;

=head1 ATTRIBUTES

=head2 MODELS

This attribute contains the default models and parameters, estimated by Blum et al.

  my $models = ISS::AH::Predictor::MODELS;

  # each element of the $models arrayref is an arrayref with estimated parameters of one model
  $models->[0]->[0]; # first parameter (intercept) of the first model

=cut

use constant MODELS => [
  [ 63.3339,  -2.9595, 0.7256, 0.3173, undef,  undef,  -13.0399, 1.2695, -6.2213 ],
  [ 62.1795,  -2.9892, 0.7328, 0.3442, undef,  undef,  -12.6821, undef,  -6.3021 ],
  [ 50.3654,  -2.6372, 0.6408, 0.3986, undef,  undef,  undef,    undef,  -5.9171 ],
  [ 80.3645,  -3.4309, 0.8241, undef,  0.2242, undef,  -15.1678, 1.2688, -10.2474 ],
  [ 83.4866,  -3.4717, 0.8374, undef,  0.2234, undef,  -14.7156, undef,  -10.6257 ],
  [ 75.8792,  -3.1944, 0.7581, undef,  0.2449, undef,  undef,    undef,  -10.9519 ],
  [ 93.2475,  -3.4020, 0.8239, undef,  undef,  0.1203, -14.2739, 1.6156, -10.0340 ],
  [ 94.2381,  -3.5784, 0.8759, undef,  undef,  0.1348, -14.2476, undef,  -10.5319 ],
  [ 84.3600,  -3.2207, 0.7623, undef,  undef,  0.1775, undef,    undef,  -10.8759 ],
  [ 110.8863, -4.1250, 0.9661, undef,  undef,  undef,  -16.0541, undef,  -10.4331 ],
];

=head2 PARAMETER_NAMES

Hashref that contains the names of the model parameters for each variable index.

=cut

use constant PARAMETER_NAMES => {
  0 => 'intercept',
  1 => 'age',
  2 => 'body_height',
  3 => 'target_height',
  4 => 'mother_height',
  5 => 'father_height',
  6 => 'bone_age_per_age',
  7 => 'birth_weight',
  8 => 'sex',
};

=head1 SUBROUTINES/METHODS

=head2 predict

Provide a hash with properties of a subject to predict adult height (AH).
You can also provide custom model parameters to overwrite the default once from Blum et al.

  my $ah = ISS::AH::Predictor::predict(
    age           => ...,    # years
    body_height   => ...,    # cm
    target_height => ...,    # cm
    mother_height => ...,    # cm
    father_height => ...,    # cm
    bone_age      => ...,    # years
    birth_weight  => ...,    # kg
    sex           => ...,    # 'male' or 'female'
    models        => [ ... ],
  );

=cut

sub predict {
  my %params = _modify_params(@_);
  my $model  = get_model(%params) or return undef;
  my $result = $model->[0];                          # intercept

  for my $index (keys %{ PARAMETER_NAMES() }) {
    my $parameter_name = PARAMETER_NAMES->{$index};
    next if ($parameter_name eq 'intercept');
    next unless (defined $model->[$index] and defined $params{$parameter_name});
    $result += $model->[$index] * $params{$parameter_name};
  }

  return $result;
}

=head2 get_model

Returns an appropriate model with a set of parameters for the given subject properties.
The returned model is determined by the amount of available parameters.
You can also provide custom model parameters to overwrite the default once from Blum et al.

If no model is appropriate, the result is undef.
If there are multiple matching models (with identical parameter count), the first one will be returned.

  my $model = ISS::AH::Predictor::get_model(
    age           => ...,    # years
    body_height   => ...,    # cm
    target_height => ...,    # cm
    mother_height => ...,    # cm
    father_height => ...,    # cm
    bone_age      => ...,    # years
    birth_weight  => ...,    # kg
    sex           => ...,    # 'male' or 'female'
    models        => [ ... ],
  );

=cut

sub get_model {
  my %params  = _modify_params(@_);
  my $models  = $params{models} || MODELS;
  my $results = [];

  for my $model (@$models) {
    my $match = 1;
    for my $index (keys %{ PARAMETER_NAMES() }) {
      my $parameter_name = PARAMETER_NAMES->{$index};
      $match = 0 if (defined $model->[$index] and !looks_like_number($model->[$index]));
      next if ($parameter_name eq 'intercept');
      $match = 0 unless (defined $params{$parameter_name} xor !defined $model->[$index]);
      last       unless ($match);
    }
    push @$results, $model if ($match);
  }

  return (scalar @$results) ? $results->[0] : undef;
}

sub _modify_params {
  my %params = @_;

  $params{bone_age_per_age} = $params{bone_age} / $params{age}
    if (defined $params{bone_age} and $params{age});

  if (defined $params{sex}) {
    my $sex = lc $params{sex};
    $params{sex} = ($sex eq 'male') ? 1 : ($sex eq 'female') ? 2 : $sex;
  }

  for my $parameter_name (values %{ PARAMETER_NAMES() }) {
    if (defined $params{$parameter_name} and !looks_like_number($params{$parameter_name})) {
      warn "input parameter $parameter_name removed, because value $params{$parameter_name} is not numeric";
      delete $params{$parameter_name};
    }
  }

  return %params;
}

=head1 AUTHOR

Christoph Beger, C<< <christoph.beger at medizin.uni-leipzig.de> >>

=cut

1;
