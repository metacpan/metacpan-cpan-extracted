package Google::Api::Distribution::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Distribution',
    as InstanceOf['Google::Api::Distribution::Distribution'];

coerce 'Distribution',
    from HashRef, via { 'Google::Api::Distribution::Distribution'->new($_) };

declare 'RepeatedDistribution',
    as ArrayRef[Distribution()];

coerce 'RepeatedDistribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Distribution::Distribution'->new($_) } @$_ ] };

declare 'MapStringDistribution',
    as HashRef[Distribution()];

declare 'Range',
    as InstanceOf['Google::Api::Distribution::Distribution::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Api::Distribution::Distribution::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Distribution::Distribution::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'BucketOptions',
    as InstanceOf['Google::Api::Distribution::Distribution::BucketOptions'];

coerce 'BucketOptions',
    from HashRef, via { 'Google::Api::Distribution::Distribution::BucketOptions'->new($_) };

declare 'RepeatedBucketOptions',
    as ArrayRef[BucketOptions()];

coerce 'RepeatedBucketOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Distribution::Distribution::BucketOptions'->new($_) } @$_ ] };

declare 'MapStringBucketOptions',
    as HashRef[BucketOptions()];

declare 'Linear',
    as InstanceOf['Google::Api::Distribution::Distribution::BucketOptions::Linear'];

coerce 'Linear',
    from HashRef, via { 'Google::Api::Distribution::Distribution::BucketOptions::Linear'->new($_) };

declare 'RepeatedLinear',
    as ArrayRef[Linear()];

coerce 'RepeatedLinear',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Distribution::Distribution::BucketOptions::Linear'->new($_) } @$_ ] };

declare 'MapStringLinear',
    as HashRef[Linear()];

declare 'Exponential',
    as InstanceOf['Google::Api::Distribution::Distribution::BucketOptions::Exponential'];

coerce 'Exponential',
    from HashRef, via { 'Google::Api::Distribution::Distribution::BucketOptions::Exponential'->new($_) };

declare 'RepeatedExponential',
    as ArrayRef[Exponential()];

coerce 'RepeatedExponential',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Distribution::Distribution::BucketOptions::Exponential'->new($_) } @$_ ] };

declare 'MapStringExponential',
    as HashRef[Exponential()];

declare 'Explicit',
    as InstanceOf['Google::Api::Distribution::Distribution::BucketOptions::Explicit'];

coerce 'Explicit',
    from HashRef, via { 'Google::Api::Distribution::Distribution::BucketOptions::Explicit'->new($_) };

declare 'RepeatedExplicit',
    as ArrayRef[Explicit()];

coerce 'RepeatedExplicit',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Distribution::Distribution::BucketOptions::Explicit'->new($_) } @$_ ] };

declare 'MapStringExplicit',
    as HashRef[Explicit()];

declare 'Exemplar',
    as InstanceOf['Google::Api::Distribution::Distribution::Exemplar'];

coerce 'Exemplar',
    from HashRef, via { 'Google::Api::Distribution::Distribution::Exemplar'->new($_) };

declare 'RepeatedExemplar',
    as ArrayRef[Exemplar()];

coerce 'RepeatedExemplar',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Distribution::Distribution::Exemplar'->new($_) } @$_ ] };

declare 'MapStringExemplar',
    as HashRef[Exemplar()];

1;
