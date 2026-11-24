package Google::Devicesandservices::Health::V4::DataModel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HeartRateZoneType',
    as (Int | Str);

declare 'FoodAccessLevel',
    as (Int | Str);

declare 'MealType',
    as (Int | Str);

declare 'EnergyUnit',
    as (Int | Str);

declare 'Nutrient',
    as (Int | Str);

declare 'WeightUnit',
    as (Int | Str);

declare 'VolumeUnit',
    as (Int | Str);

declare 'OvulationTestResult',
    as (Int | Str);

declare 'ActiveZoneMinutes',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActiveZoneMinutes'];

coerce 'ActiveZoneMinutes',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActiveZoneMinutes'->new($_) };

declare 'RepeatedActiveZoneMinutes',
    as ArrayRef[ActiveZoneMinutes()];

coerce 'RepeatedActiveZoneMinutes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActiveZoneMinutes'->new($_) } @$_ ] };

declare 'MapStringActiveZoneMinutes',
    as HashRef[ActiveZoneMinutes()];

declare 'HeartRateZone',
    as (Int | Str);

declare 'ActiveZoneMinutesRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActiveZoneMinutesRollupValue'];

coerce 'ActiveZoneMinutesRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActiveZoneMinutesRollupValue'->new($_) };

declare 'RepeatedActiveZoneMinutesRollupValue',
    as ArrayRef[ActiveZoneMinutesRollupValue()];

coerce 'RepeatedActiveZoneMinutesRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActiveZoneMinutesRollupValue'->new($_) } @$_ ] };

declare 'MapStringActiveZoneMinutesRollupValue',
    as HashRef[ActiveZoneMinutesRollupValue()];

declare 'ActiveMinutes',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActiveMinutes'];

coerce 'ActiveMinutes',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActiveMinutes'->new($_) };

declare 'RepeatedActiveMinutes',
    as ArrayRef[ActiveMinutes()];

coerce 'RepeatedActiveMinutes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActiveMinutes'->new($_) } @$_ ] };

declare 'MapStringActiveMinutes',
    as HashRef[ActiveMinutes()];

declare 'ActivityLevel',
    as (Int | Str);

declare 'ActiveMinutesByActivityLevel',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActiveMinutes::ActiveMinutesByActivityLevel'];

coerce 'ActiveMinutesByActivityLevel',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActiveMinutes::ActiveMinutesByActivityLevel'->new($_) };

declare 'RepeatedActiveMinutesByActivityLevel',
    as ArrayRef[ActiveMinutesByActivityLevel()];

coerce 'RepeatedActiveMinutesByActivityLevel',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActiveMinutes::ActiveMinutesByActivityLevel'->new($_) } @$_ ] };

declare 'MapStringActiveMinutesByActivityLevel',
    as HashRef[ActiveMinutesByActivityLevel()];

declare 'ActiveMinutesRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActiveMinutesRollupValue'];

coerce 'ActiveMinutesRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActiveMinutesRollupValue'->new($_) };

declare 'RepeatedActiveMinutesRollupValue',
    as ArrayRef[ActiveMinutesRollupValue()];

coerce 'RepeatedActiveMinutesRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActiveMinutesRollupValue'->new($_) } @$_ ] };

declare 'MapStringActiveMinutesRollupValue',
    as HashRef[ActiveMinutesRollupValue()];

declare 'ActiveMinutesRollupByActivityLevel',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActiveMinutesRollupValue::ActiveMinutesRollupByActivityLevel'];

coerce 'ActiveMinutesRollupByActivityLevel',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActiveMinutesRollupValue::ActiveMinutesRollupByActivityLevel'->new($_) };

declare 'RepeatedActiveMinutesRollupByActivityLevel',
    as ArrayRef[ActiveMinutesRollupByActivityLevel()];

coerce 'RepeatedActiveMinutesRollupByActivityLevel',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActiveMinutesRollupValue::ActiveMinutesRollupByActivityLevel'->new($_) } @$_ ] };

declare 'MapStringActiveMinutesRollupByActivityLevel',
    as HashRef[ActiveMinutesRollupByActivityLevel()];

declare 'ActivityLevel',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActivityLevel'];

coerce 'ActivityLevel',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActivityLevel'->new($_) };

declare 'RepeatedActivityLevel',
    as ArrayRef[ActivityLevel()];

coerce 'RepeatedActivityLevel',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActivityLevel'->new($_) } @$_ ] };

declare 'MapStringActivityLevel',
    as HashRef[ActivityLevel()];

declare 'ActivityLevelType',
    as (Int | Str);

declare 'ActivityLevelRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActivityLevelRollupValue'];

coerce 'ActivityLevelRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActivityLevelRollupValue'->new($_) };

declare 'RepeatedActivityLevelRollupValue',
    as ArrayRef[ActivityLevelRollupValue()];

coerce 'RepeatedActivityLevelRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActivityLevelRollupValue'->new($_) } @$_ ] };

declare 'MapStringActivityLevelRollupValue',
    as HashRef[ActivityLevelRollupValue()];

declare 'ActivityLevelRollupByActivityLevelType',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActivityLevelRollupValue::ActivityLevelRollupByActivityLevelType'];

coerce 'ActivityLevelRollupByActivityLevelType',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActivityLevelRollupValue::ActivityLevelRollupByActivityLevelType'->new($_) };

declare 'RepeatedActivityLevelRollupByActivityLevelType',
    as ArrayRef[ActivityLevelRollupByActivityLevelType()];

coerce 'RepeatedActivityLevelRollupByActivityLevelType',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActivityLevelRollupValue::ActivityLevelRollupByActivityLevelType'->new($_) } @$_ ] };

declare 'MapStringActivityLevelRollupByActivityLevelType',
    as HashRef[ActivityLevelRollupByActivityLevelType()];

declare 'Altitude',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Altitude'];

coerce 'Altitude',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Altitude'->new($_) };

declare 'RepeatedAltitude',
    as ArrayRef[Altitude()];

coerce 'RepeatedAltitude',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Altitude'->new($_) } @$_ ] };

declare 'MapStringAltitude',
    as HashRef[Altitude()];

declare 'BasalEnergyBurned',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::BasalEnergyBurned'];

coerce 'BasalEnergyBurned',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::BasalEnergyBurned'->new($_) };

declare 'RepeatedBasalEnergyBurned',
    as ArrayRef[BasalEnergyBurned()];

coerce 'RepeatedBasalEnergyBurned',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::BasalEnergyBurned'->new($_) } @$_ ] };

declare 'MapStringBasalEnergyBurned',
    as HashRef[BasalEnergyBurned()];

declare 'BodyFat',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::BodyFat'];

coerce 'BodyFat',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::BodyFat'->new($_) };

declare 'RepeatedBodyFat',
    as ArrayRef[BodyFat()];

coerce 'RepeatedBodyFat',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::BodyFat'->new($_) } @$_ ] };

declare 'MapStringBodyFat',
    as HashRef[BodyFat()];

declare 'BodyFatRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::BodyFatRollupValue'];

coerce 'BodyFatRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::BodyFatRollupValue'->new($_) };

declare 'RepeatedBodyFatRollupValue',
    as ArrayRef[BodyFatRollupValue()];

coerce 'RepeatedBodyFatRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::BodyFatRollupValue'->new($_) } @$_ ] };

declare 'MapStringBodyFatRollupValue',
    as HashRef[BodyFatRollupValue()];

declare 'CoreBodyTemperature',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::CoreBodyTemperature'];

coerce 'CoreBodyTemperature',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::CoreBodyTemperature'->new($_) };

declare 'RepeatedCoreBodyTemperature',
    as ArrayRef[CoreBodyTemperature()];

coerce 'RepeatedCoreBodyTemperature',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::CoreBodyTemperature'->new($_) } @$_ ] };

declare 'MapStringCoreBodyTemperature',
    as HashRef[CoreBodyTemperature()];

declare 'MeasurementLocation',
    as (Int | Str);

declare 'CoreBodyTemperatureRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::CoreBodyTemperatureRollupValue'];

coerce 'CoreBodyTemperatureRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::CoreBodyTemperatureRollupValue'->new($_) };

declare 'RepeatedCoreBodyTemperatureRollupValue',
    as ArrayRef[CoreBodyTemperatureRollupValue()];

coerce 'RepeatedCoreBodyTemperatureRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::CoreBodyTemperatureRollupValue'->new($_) } @$_ ] };

declare 'MapStringCoreBodyTemperatureRollupValue',
    as HashRef[CoreBodyTemperatureRollupValue()];

declare 'CaloriesInHeartRateZoneRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::CaloriesInHeartRateZoneRollupValue'];

coerce 'CaloriesInHeartRateZoneRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::CaloriesInHeartRateZoneRollupValue'->new($_) };

declare 'RepeatedCaloriesInHeartRateZoneRollupValue',
    as ArrayRef[CaloriesInHeartRateZoneRollupValue()];

coerce 'RepeatedCaloriesInHeartRateZoneRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::CaloriesInHeartRateZoneRollupValue'->new($_) } @$_ ] };

declare 'MapStringCaloriesInHeartRateZoneRollupValue',
    as HashRef[CaloriesInHeartRateZoneRollupValue()];

declare 'CaloriesInHeartRateZoneValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::CaloriesInHeartRateZoneRollupValue::CaloriesInHeartRateZoneValue'];

coerce 'CaloriesInHeartRateZoneValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::CaloriesInHeartRateZoneRollupValue::CaloriesInHeartRateZoneValue'->new($_) };

declare 'RepeatedCaloriesInHeartRateZoneValue',
    as ArrayRef[CaloriesInHeartRateZoneValue()];

coerce 'RepeatedCaloriesInHeartRateZoneValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::CaloriesInHeartRateZoneRollupValue::CaloriesInHeartRateZoneValue'->new($_) } @$_ ] };

declare 'MapStringCaloriesInHeartRateZoneValue',
    as HashRef[CaloriesInHeartRateZoneValue()];

declare 'DailyHeartRateZones',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateZones'];

coerce 'DailyHeartRateZones',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateZones'->new($_) };

declare 'RepeatedDailyHeartRateZones',
    as ArrayRef[DailyHeartRateZones()];

coerce 'RepeatedDailyHeartRateZones',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateZones'->new($_) } @$_ ] };

declare 'MapStringDailyHeartRateZones',
    as HashRef[DailyHeartRateZones()];

declare 'HeartRateZone',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateZones::HeartRateZone'];

coerce 'HeartRateZone',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateZones::HeartRateZone'->new($_) };

declare 'RepeatedHeartRateZone',
    as ArrayRef[HeartRateZone()];

coerce 'RepeatedHeartRateZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateZones::HeartRateZone'->new($_) } @$_ ] };

declare 'MapStringHeartRateZone',
    as HashRef[HeartRateZone()];

declare 'DailyHeartRateVariability',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateVariability'];

coerce 'DailyHeartRateVariability',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateVariability'->new($_) };

declare 'RepeatedDailyHeartRateVariability',
    as ArrayRef[DailyHeartRateVariability()];

coerce 'RepeatedDailyHeartRateVariability',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailyHeartRateVariability'->new($_) } @$_ ] };

declare 'MapStringDailyHeartRateVariability',
    as HashRef[DailyHeartRateVariability()];

declare 'DailyRespiratoryRate',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailyRespiratoryRate'];

coerce 'DailyRespiratoryRate',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailyRespiratoryRate'->new($_) };

declare 'RepeatedDailyRespiratoryRate',
    as ArrayRef[DailyRespiratoryRate()];

coerce 'RepeatedDailyRespiratoryRate',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailyRespiratoryRate'->new($_) } @$_ ] };

declare 'MapStringDailyRespiratoryRate',
    as HashRef[DailyRespiratoryRate()];

declare 'DailyOxygenSaturation',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailyOxygenSaturation'];

coerce 'DailyOxygenSaturation',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailyOxygenSaturation'->new($_) };

declare 'RepeatedDailyOxygenSaturation',
    as ArrayRef[DailyOxygenSaturation()];

coerce 'RepeatedDailyOxygenSaturation',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailyOxygenSaturation'->new($_) } @$_ ] };

declare 'MapStringDailyOxygenSaturation',
    as HashRef[DailyOxygenSaturation()];

declare 'DailyRestingHeartRate',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailyRestingHeartRate'];

coerce 'DailyRestingHeartRate',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailyRestingHeartRate'->new($_) };

declare 'RepeatedDailyRestingHeartRate',
    as ArrayRef[DailyRestingHeartRate()];

coerce 'RepeatedDailyRestingHeartRate',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailyRestingHeartRate'->new($_) } @$_ ] };

declare 'MapStringDailyRestingHeartRate',
    as HashRef[DailyRestingHeartRate()];

declare 'DailyRestingHeartRateMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailyRestingHeartRate::DailyRestingHeartRateMetadata'];

coerce 'DailyRestingHeartRateMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailyRestingHeartRate::DailyRestingHeartRateMetadata'->new($_) };

declare 'RepeatedDailyRestingHeartRateMetadata',
    as ArrayRef[DailyRestingHeartRateMetadata()];

coerce 'RepeatedDailyRestingHeartRateMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailyRestingHeartRate::DailyRestingHeartRateMetadata'->new($_) } @$_ ] };

declare 'MapStringDailyRestingHeartRateMetadata',
    as HashRef[DailyRestingHeartRateMetadata()];

declare 'CalculationMethod',
    as (Int | Str);

declare 'DailySleepTemperatureDerivations',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailySleepTemperatureDerivations'];

coerce 'DailySleepTemperatureDerivations',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailySleepTemperatureDerivations'->new($_) };

declare 'RepeatedDailySleepTemperatureDerivations',
    as ArrayRef[DailySleepTemperatureDerivations()];

coerce 'RepeatedDailySleepTemperatureDerivations',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailySleepTemperatureDerivations'->new($_) } @$_ ] };

declare 'MapStringDailySleepTemperatureDerivations',
    as HashRef[DailySleepTemperatureDerivations()];

declare 'DailyVO2Max',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DailyVO2Max'];

coerce 'DailyVO2Max',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DailyVO2Max'->new($_) };

declare 'RepeatedDailyVO2Max',
    as ArrayRef[DailyVO2Max()];

coerce 'RepeatedDailyVO2Max',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DailyVO2Max'->new($_) } @$_ ] };

declare 'MapStringDailyVO2Max',
    as HashRef[DailyVO2Max()];

declare 'CardioFitnessLevel',
    as (Int | Str);

declare 'Distance',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Distance'];

coerce 'Distance',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Distance'->new($_) };

declare 'RepeatedDistance',
    as ArrayRef[Distance()];

coerce 'RepeatedDistance',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Distance'->new($_) } @$_ ] };

declare 'MapStringDistance',
    as HashRef[Distance()];

declare 'DistanceRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::DistanceRollupValue'];

coerce 'DistanceRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::DistanceRollupValue'->new($_) };

declare 'RepeatedDistanceRollupValue',
    as ArrayRef[DistanceRollupValue()];

coerce 'RepeatedDistanceRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::DistanceRollupValue'->new($_) } @$_ ] };

declare 'MapStringDistanceRollupValue',
    as HashRef[DistanceRollupValue()];

declare 'Electrocardiogram',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Electrocardiogram'];

coerce 'Electrocardiogram',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Electrocardiogram'->new($_) };

declare 'RepeatedElectrocardiogram',
    as ArrayRef[Electrocardiogram()];

coerce 'RepeatedElectrocardiogram',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Electrocardiogram'->new($_) } @$_ ] };

declare 'MapStringElectrocardiogram',
    as HashRef[Electrocardiogram()];

declare 'ResultClassification',
    as (Int | Str);

declare 'Exercise',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Exercise'];

coerce 'Exercise',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Exercise'->new($_) };

declare 'RepeatedExercise',
    as ArrayRef[Exercise()];

coerce 'RepeatedExercise',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Exercise'->new($_) } @$_ ] };

declare 'MapStringExercise',
    as HashRef[Exercise()];

declare 'ExerciseType',
    as (Int | Str);

declare 'SplitSummary',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Exercise::SplitSummary'];

coerce 'SplitSummary',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Exercise::SplitSummary'->new($_) };

declare 'RepeatedSplitSummary',
    as ArrayRef[SplitSummary()];

coerce 'RepeatedSplitSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Exercise::SplitSummary'->new($_) } @$_ ] };

declare 'MapStringSplitSummary',
    as HashRef[SplitSummary()];

declare 'SplitType',
    as (Int | Str);

declare 'ExerciseEvent',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Exercise::ExerciseEvent'];

coerce 'ExerciseEvent',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Exercise::ExerciseEvent'->new($_) };

declare 'RepeatedExerciseEvent',
    as ArrayRef[ExerciseEvent()];

coerce 'RepeatedExerciseEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Exercise::ExerciseEvent'->new($_) } @$_ ] };

declare 'MapStringExerciseEvent',
    as HashRef[ExerciseEvent()];

declare 'ExerciseEventType',
    as (Int | Str);

declare 'ExerciseMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Exercise::ExerciseMetadata'];

coerce 'ExerciseMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Exercise::ExerciseMetadata'->new($_) };

declare 'RepeatedExerciseMetadata',
    as ArrayRef[ExerciseMetadata()];

coerce 'RepeatedExerciseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Exercise::ExerciseMetadata'->new($_) } @$_ ] };

declare 'MapStringExerciseMetadata',
    as HashRef[ExerciseMetadata()];

declare 'Floors',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Floors'];

coerce 'Floors',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Floors'->new($_) };

declare 'RepeatedFloors',
    as ArrayRef[Floors()];

coerce 'RepeatedFloors',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Floors'->new($_) } @$_ ] };

declare 'MapStringFloors',
    as HashRef[Floors()];

declare 'FloorsRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::FloorsRollupValue'];

coerce 'FloorsRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::FloorsRollupValue'->new($_) };

declare 'RepeatedFloorsRollupValue',
    as ArrayRef[FloorsRollupValue()];

coerce 'RepeatedFloorsRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::FloorsRollupValue'->new($_) } @$_ ] };

declare 'MapStringFloorsRollupValue',
    as HashRef[FloorsRollupValue()];

declare 'AltitudeRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::AltitudeRollupValue'];

coerce 'AltitudeRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::AltitudeRollupValue'->new($_) };

declare 'RepeatedAltitudeRollupValue',
    as ArrayRef[AltitudeRollupValue()];

coerce 'RepeatedAltitudeRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::AltitudeRollupValue'->new($_) } @$_ ] };

declare 'MapStringAltitudeRollupValue',
    as HashRef[AltitudeRollupValue()];

declare 'HeartRate',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HeartRate'];

coerce 'HeartRate',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HeartRate'->new($_) };

declare 'RepeatedHeartRate',
    as ArrayRef[HeartRate()];

coerce 'RepeatedHeartRate',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HeartRate'->new($_) } @$_ ] };

declare 'MapStringHeartRate',
    as HashRef[HeartRate()];

declare 'HeartRateMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HeartRate::HeartRateMetadata'];

coerce 'HeartRateMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HeartRate::HeartRateMetadata'->new($_) };

declare 'RepeatedHeartRateMetadata',
    as ArrayRef[HeartRateMetadata()];

coerce 'RepeatedHeartRateMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HeartRate::HeartRateMetadata'->new($_) } @$_ ] };

declare 'MapStringHeartRateMetadata',
    as HashRef[HeartRateMetadata()];

declare 'MotionContext',
    as (Int | Str);

declare 'SensorLocation',
    as (Int | Str);

declare 'HeartRateRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HeartRateRollupValue'];

coerce 'HeartRateRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HeartRateRollupValue'->new($_) };

declare 'RepeatedHeartRateRollupValue',
    as ArrayRef[HeartRateRollupValue()];

coerce 'RepeatedHeartRateRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HeartRateRollupValue'->new($_) } @$_ ] };

declare 'MapStringHeartRateRollupValue',
    as HashRef[HeartRateRollupValue()];

declare 'RunVO2MaxRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::RunVO2MaxRollupValue'];

coerce 'RunVO2MaxRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::RunVO2MaxRollupValue'->new($_) };

declare 'RepeatedRunVO2MaxRollupValue',
    as ArrayRef[RunVO2MaxRollupValue()];

coerce 'RepeatedRunVO2MaxRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::RunVO2MaxRollupValue'->new($_) } @$_ ] };

declare 'MapStringRunVO2MaxRollupValue',
    as HashRef[RunVO2MaxRollupValue()];

declare 'RunVO2Max',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::RunVO2Max'];

coerce 'RunVO2Max',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::RunVO2Max'->new($_) };

declare 'RepeatedRunVO2Max',
    as ArrayRef[RunVO2Max()];

coerce 'RepeatedRunVO2Max',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::RunVO2Max'->new($_) } @$_ ] };

declare 'MapStringRunVO2Max',
    as HashRef[RunVO2Max()];

declare 'HeartRateVariabilityPersonalRangeRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HeartRateVariabilityPersonalRangeRollupValue'];

coerce 'HeartRateVariabilityPersonalRangeRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HeartRateVariabilityPersonalRangeRollupValue'->new($_) };

declare 'RepeatedHeartRateVariabilityPersonalRangeRollupValue',
    as ArrayRef[HeartRateVariabilityPersonalRangeRollupValue()];

coerce 'RepeatedHeartRateVariabilityPersonalRangeRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HeartRateVariabilityPersonalRangeRollupValue'->new($_) } @$_ ] };

declare 'MapStringHeartRateVariabilityPersonalRangeRollupValue',
    as HashRef[HeartRateVariabilityPersonalRangeRollupValue()];

declare 'Height',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Height'];

coerce 'Height',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Height'->new($_) };

declare 'RepeatedHeight',
    as ArrayRef[Height()];

coerce 'RepeatedHeight',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Height'->new($_) } @$_ ] };

declare 'MapStringHeight',
    as HashRef[Height()];

declare 'HeartRateVariability',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HeartRateVariability'];

coerce 'HeartRateVariability',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HeartRateVariability'->new($_) };

declare 'RepeatedHeartRateVariability',
    as ArrayRef[HeartRateVariability()];

coerce 'RepeatedHeartRateVariability',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HeartRateVariability'->new($_) } @$_ ] };

declare 'MapStringHeartRateVariability',
    as HashRef[HeartRateVariability()];

declare 'HeartRateVariabilityMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HeartRateVariability::HeartRateVariabilityMetadata'];

coerce 'HeartRateVariabilityMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HeartRateVariability::HeartRateVariabilityMetadata'->new($_) };

declare 'RepeatedHeartRateVariabilityMetadata',
    as ArrayRef[HeartRateVariabilityMetadata()];

coerce 'RepeatedHeartRateVariabilityMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HeartRateVariability::HeartRateVariabilityMetadata'->new($_) } @$_ ] };

declare 'MapStringHeartRateVariabilityMetadata',
    as HashRef[HeartRateVariabilityMetadata()];

declare 'VolumeQuantity',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::VolumeQuantity'];

coerce 'VolumeQuantity',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::VolumeQuantity'->new($_) };

declare 'RepeatedVolumeQuantity',
    as ArrayRef[VolumeQuantity()];

coerce 'RepeatedVolumeQuantity',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::VolumeQuantity'->new($_) } @$_ ] };

declare 'MapStringVolumeQuantity',
    as HashRef[VolumeQuantity()];

declare 'HydrationLog',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HydrationLog'];

coerce 'HydrationLog',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HydrationLog'->new($_) };

declare 'RepeatedHydrationLog',
    as ArrayRef[HydrationLog()];

coerce 'RepeatedHydrationLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HydrationLog'->new($_) } @$_ ] };

declare 'MapStringHydrationLog',
    as HashRef[HydrationLog()];

declare 'HydrationLogRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HydrationLogRollupValue'];

coerce 'HydrationLogRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HydrationLogRollupValue'->new($_) };

declare 'RepeatedHydrationLogRollupValue',
    as ArrayRef[HydrationLogRollupValue()];

coerce 'RepeatedHydrationLogRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HydrationLogRollupValue'->new($_) } @$_ ] };

declare 'MapStringHydrationLogRollupValue',
    as HashRef[HydrationLogRollupValue()];

declare 'VolumeQuantityRollup',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::HydrationLogRollupValue::VolumeQuantityRollup'];

coerce 'VolumeQuantityRollup',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::HydrationLogRollupValue::VolumeQuantityRollup'->new($_) };

declare 'RepeatedVolumeQuantityRollup',
    as ArrayRef[VolumeQuantityRollup()];

coerce 'RepeatedVolumeQuantityRollup',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::HydrationLogRollupValue::VolumeQuantityRollup'->new($_) } @$_ ] };

declare 'MapStringVolumeQuantityRollup',
    as HashRef[VolumeQuantityRollup()];

declare 'IrregularRhythmNotification',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification'];

coerce 'IrregularRhythmNotification',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification'->new($_) };

declare 'RepeatedIrregularRhythmNotification',
    as ArrayRef[IrregularRhythmNotification()];

coerce 'RepeatedIrregularRhythmNotification',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification'->new($_) } @$_ ] };

declare 'MapStringIrregularRhythmNotification',
    as HashRef[IrregularRhythmNotification()];

declare 'HeartBeat',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification::HeartBeat'];

coerce 'HeartBeat',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification::HeartBeat'->new($_) };

declare 'RepeatedHeartBeat',
    as ArrayRef[HeartBeat()];

coerce 'RepeatedHeartBeat',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification::HeartBeat'->new($_) } @$_ ] };

declare 'MapStringHeartBeat',
    as HashRef[HeartBeat()];

declare 'AlertWindow',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification::AlertWindow'];

coerce 'AlertWindow',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification::AlertWindow'->new($_) };

declare 'RepeatedAlertWindow',
    as ArrayRef[AlertWindow()];

coerce 'RepeatedAlertWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::IrregularRhythmNotification::AlertWindow'->new($_) } @$_ ] };

declare 'MapStringAlertWindow',
    as HashRef[AlertWindow()];

declare 'MetricsSummary',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::MetricsSummary'];

coerce 'MetricsSummary',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::MetricsSummary'->new($_) };

declare 'RepeatedMetricsSummary',
    as ArrayRef[MetricsSummary()];

coerce 'RepeatedMetricsSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::MetricsSummary'->new($_) } @$_ ] };

declare 'MapStringMetricsSummary',
    as HashRef[MetricsSummary()];

declare 'TimeInHeartRateZones',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::MetricsSummary::TimeInHeartRateZones'];

coerce 'TimeInHeartRateZones',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::MetricsSummary::TimeInHeartRateZones'->new($_) };

declare 'RepeatedTimeInHeartRateZones',
    as ArrayRef[TimeInHeartRateZones()];

coerce 'RepeatedTimeInHeartRateZones',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::MetricsSummary::TimeInHeartRateZones'->new($_) } @$_ ] };

declare 'MapStringTimeInHeartRateZones',
    as HashRef[TimeInHeartRateZones()];

declare 'MobilityMetrics',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::MetricsSummary::MobilityMetrics'];

coerce 'MobilityMetrics',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::MetricsSummary::MobilityMetrics'->new($_) };

declare 'RepeatedMobilityMetrics',
    as ArrayRef[MobilityMetrics()];

coerce 'RepeatedMobilityMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::MetricsSummary::MobilityMetrics'->new($_) } @$_ ] };

declare 'MapStringMobilityMetrics',
    as HashRef[MobilityMetrics()];

declare 'WeightQuantity',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::WeightQuantity'];

coerce 'WeightQuantity',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::WeightQuantity'->new($_) };

declare 'RepeatedWeightQuantity',
    as ArrayRef[WeightQuantity()];

coerce 'RepeatedWeightQuantity',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::WeightQuantity'->new($_) } @$_ ] };

declare 'MapStringWeightQuantity',
    as HashRef[WeightQuantity()];

declare 'EnergyQuantity',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::EnergyQuantity'];

coerce 'EnergyQuantity',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::EnergyQuantity'->new($_) };

declare 'RepeatedEnergyQuantity',
    as ArrayRef[EnergyQuantity()];

coerce 'RepeatedEnergyQuantity',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::EnergyQuantity'->new($_) } @$_ ] };

declare 'MapStringEnergyQuantity',
    as HashRef[EnergyQuantity()];

declare 'NutrientQuantity',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::NutrientQuantity'];

coerce 'NutrientQuantity',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::NutrientQuantity'->new($_) };

declare 'RepeatedNutrientQuantity',
    as ArrayRef[NutrientQuantity()];

coerce 'RepeatedNutrientQuantity',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::NutrientQuantity'->new($_) } @$_ ] };

declare 'MapStringNutrientQuantity',
    as HashRef[NutrientQuantity()];

declare 'NutritionLog',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::NutritionLog'];

coerce 'NutritionLog',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLog'->new($_) };

declare 'RepeatedNutritionLog',
    as ArrayRef[NutritionLog()];

coerce 'RepeatedNutritionLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLog'->new($_) } @$_ ] };

declare 'MapStringNutritionLog',
    as HashRef[NutritionLog()];

declare 'Serving',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::NutritionLog::Serving'];

coerce 'Serving',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLog::Serving'->new($_) };

declare 'RepeatedServing',
    as ArrayRef[Serving()];

coerce 'RepeatedServing',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLog::Serving'->new($_) } @$_ ] };

declare 'MapStringServing',
    as HashRef[Serving()];

declare 'Food',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Food'];

coerce 'Food',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Food'->new($_) };

declare 'RepeatedFood',
    as ArrayRef[Food()];

coerce 'RepeatedFood',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Food'->new($_) } @$_ ] };

declare 'MapStringFood',
    as HashRef[Food()];

declare 'FoodServing',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Food::FoodServing'];

coerce 'FoodServing',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Food::FoodServing'->new($_) };

declare 'RepeatedFoodServing',
    as ArrayRef[FoodServing()];

coerce 'RepeatedFoodServing',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Food::FoodServing'->new($_) } @$_ ] };

declare 'MapStringFoodServing',
    as HashRef[FoodServing()];

declare 'NutritionLogRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue'];

coerce 'NutritionLogRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue'->new($_) };

declare 'RepeatedNutritionLogRollupValue',
    as ArrayRef[NutritionLogRollupValue()];

coerce 'RepeatedNutritionLogRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue'->new($_) } @$_ ] };

declare 'MapStringNutritionLogRollupValue',
    as HashRef[NutritionLogRollupValue()];

declare 'WeightQuantityRollup',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::WeightQuantityRollup'];

coerce 'WeightQuantityRollup',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::WeightQuantityRollup'->new($_) };

declare 'RepeatedWeightQuantityRollup',
    as ArrayRef[WeightQuantityRollup()];

coerce 'RepeatedWeightQuantityRollup',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::WeightQuantityRollup'->new($_) } @$_ ] };

declare 'MapStringWeightQuantityRollup',
    as HashRef[WeightQuantityRollup()];

declare 'EnergyQuantityRollup',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::EnergyQuantityRollup'];

coerce 'EnergyQuantityRollup',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::EnergyQuantityRollup'->new($_) };

declare 'RepeatedEnergyQuantityRollup',
    as ArrayRef[EnergyQuantityRollup()];

coerce 'RepeatedEnergyQuantityRollup',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::EnergyQuantityRollup'->new($_) } @$_ ] };

declare 'MapStringEnergyQuantityRollup',
    as HashRef[EnergyQuantityRollup()];

declare 'NutrientQuantityRollup',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::NutrientQuantityRollup'];

coerce 'NutrientQuantityRollup',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::NutrientQuantityRollup'->new($_) };

declare 'RepeatedNutrientQuantityRollup',
    as ArrayRef[NutrientQuantityRollup()];

coerce 'RepeatedNutrientQuantityRollup',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::NutritionLogRollupValue::NutrientQuantityRollup'->new($_) } @$_ ] };

declare 'MapStringNutrientQuantityRollup',
    as HashRef[NutrientQuantityRollup()];

declare 'OxygenSaturation',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::OxygenSaturation'];

coerce 'OxygenSaturation',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::OxygenSaturation'->new($_) };

declare 'RepeatedOxygenSaturation',
    as ArrayRef[OxygenSaturation()];

coerce 'RepeatedOxygenSaturation',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::OxygenSaturation'->new($_) } @$_ ] };

declare 'MapStringOxygenSaturation',
    as HashRef[OxygenSaturation()];

declare 'RestingHeartRatePersonalRangeRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::RestingHeartRatePersonalRangeRollupValue'];

coerce 'RestingHeartRatePersonalRangeRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::RestingHeartRatePersonalRangeRollupValue'->new($_) };

declare 'RepeatedRestingHeartRatePersonalRangeRollupValue',
    as ArrayRef[RestingHeartRatePersonalRangeRollupValue()];

coerce 'RepeatedRestingHeartRatePersonalRangeRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::RestingHeartRatePersonalRangeRollupValue'->new($_) } @$_ ] };

declare 'MapStringRestingHeartRatePersonalRangeRollupValue',
    as HashRef[RestingHeartRatePersonalRangeRollupValue()];

declare 'FoodMeasurementUnit',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::FoodMeasurementUnit'];

coerce 'FoodMeasurementUnit',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::FoodMeasurementUnit'->new($_) };

declare 'RepeatedFoodMeasurementUnit',
    as ArrayRef[FoodMeasurementUnit()];

coerce 'RepeatedFoodMeasurementUnit',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::FoodMeasurementUnit'->new($_) } @$_ ] };

declare 'MapStringFoodMeasurementUnit',
    as HashRef[FoodMeasurementUnit()];

declare 'RespiratoryRateSleepSummary',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::RespiratoryRateSleepSummary'];

coerce 'RespiratoryRateSleepSummary',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::RespiratoryRateSleepSummary'->new($_) };

declare 'RepeatedRespiratoryRateSleepSummary',
    as ArrayRef[RespiratoryRateSleepSummary()];

coerce 'RepeatedRespiratoryRateSleepSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::RespiratoryRateSleepSummary'->new($_) } @$_ ] };

declare 'MapStringRespiratoryRateSleepSummary',
    as HashRef[RespiratoryRateSleepSummary()];

declare 'RespiratoryRateSleepSummaryStatistics',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::RespiratoryRateSleepSummary::RespiratoryRateSleepSummaryStatistics'];

coerce 'RespiratoryRateSleepSummaryStatistics',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::RespiratoryRateSleepSummary::RespiratoryRateSleepSummaryStatistics'->new($_) };

declare 'RepeatedRespiratoryRateSleepSummaryStatistics',
    as ArrayRef[RespiratoryRateSleepSummaryStatistics()];

coerce 'RepeatedRespiratoryRateSleepSummaryStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::RespiratoryRateSleepSummary::RespiratoryRateSleepSummaryStatistics'->new($_) } @$_ ] };

declare 'MapStringRespiratoryRateSleepSummaryStatistics',
    as HashRef[RespiratoryRateSleepSummaryStatistics()];

declare 'Sleep',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Sleep'];

coerce 'Sleep',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Sleep'->new($_) };

declare 'RepeatedSleep',
    as ArrayRef[Sleep()];

coerce 'RepeatedSleep',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Sleep'->new($_) } @$_ ] };

declare 'MapStringSleep',
    as HashRef[Sleep()];

declare 'SleepType',
    as (Int | Str);

declare 'SleepStageType',
    as (Int | Str);

declare 'SleepStage',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepStage'];

coerce 'SleepStage',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepStage'->new($_) };

declare 'RepeatedSleepStage',
    as ArrayRef[SleepStage()];

coerce 'RepeatedSleepStage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepStage'->new($_) } @$_ ] };

declare 'MapStringSleepStage',
    as HashRef[SleepStage()];

declare 'OutOfBedSegment',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Sleep::OutOfBedSegment'];

coerce 'OutOfBedSegment',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::OutOfBedSegment'->new($_) };

declare 'RepeatedOutOfBedSegment',
    as ArrayRef[OutOfBedSegment()];

coerce 'RepeatedOutOfBedSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::OutOfBedSegment'->new($_) } @$_ ] };

declare 'MapStringOutOfBedSegment',
    as HashRef[OutOfBedSegment()];

declare 'SleepMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepMetadata'];

coerce 'SleepMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepMetadata'->new($_) };

declare 'RepeatedSleepMetadata',
    as ArrayRef[SleepMetadata()];

coerce 'RepeatedSleepMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepMetadata'->new($_) } @$_ ] };

declare 'MapStringSleepMetadata',
    as HashRef[SleepMetadata()];

declare 'StagesState',
    as (Int | Str);

declare 'SleepSummary',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepSummary'];

coerce 'SleepSummary',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepSummary'->new($_) };

declare 'RepeatedSleepSummary',
    as ArrayRef[SleepSummary()];

coerce 'RepeatedSleepSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepSummary'->new($_) } @$_ ] };

declare 'MapStringSleepSummary',
    as HashRef[SleepSummary()];

declare 'StageSummary',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepSummary::StageSummary'];

coerce 'StageSummary',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepSummary::StageSummary'->new($_) };

declare 'RepeatedStageSummary',
    as ArrayRef[StageSummary()];

coerce 'RepeatedStageSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Sleep::SleepSummary::StageSummary'->new($_) } @$_ ] };

declare 'MapStringStageSummary',
    as HashRef[StageSummary()];

declare 'Steps',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Steps'];

coerce 'Steps',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Steps'->new($_) };

declare 'RepeatedSteps',
    as ArrayRef[Steps()];

coerce 'RepeatedSteps',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Steps'->new($_) } @$_ ] };

declare 'MapStringSteps',
    as HashRef[Steps()];

declare 'StepsRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::StepsRollupValue'];

coerce 'StepsRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::StepsRollupValue'->new($_) };

declare 'RepeatedStepsRollupValue',
    as ArrayRef[StepsRollupValue()];

coerce 'RepeatedStepsRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::StepsRollupValue'->new($_) } @$_ ] };

declare 'MapStringStepsRollupValue',
    as HashRef[StepsRollupValue()];

declare 'SwimLengthsData',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::SwimLengthsData'];

coerce 'SwimLengthsData',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::SwimLengthsData'->new($_) };

declare 'RepeatedSwimLengthsData',
    as ArrayRef[SwimLengthsData()];

coerce 'RepeatedSwimLengthsData',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::SwimLengthsData'->new($_) } @$_ ] };

declare 'MapStringSwimLengthsData',
    as HashRef[SwimLengthsData()];

declare 'SwimStrokeType',
    as (Int | Str);

declare 'SwimLengthsDataRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::SwimLengthsDataRollupValue'];

coerce 'SwimLengthsDataRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::SwimLengthsDataRollupValue'->new($_) };

declare 'RepeatedSwimLengthsDataRollupValue',
    as ArrayRef[SwimLengthsDataRollupValue()];

coerce 'RepeatedSwimLengthsDataRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::SwimLengthsDataRollupValue'->new($_) } @$_ ] };

declare 'MapStringSwimLengthsDataRollupValue',
    as HashRef[SwimLengthsDataRollupValue()];

declare 'TimeInHeartRateZone',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZone'];

coerce 'TimeInHeartRateZone',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZone'->new($_) };

declare 'RepeatedTimeInHeartRateZone',
    as ArrayRef[TimeInHeartRateZone()];

coerce 'RepeatedTimeInHeartRateZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZone'->new($_) } @$_ ] };

declare 'MapStringTimeInHeartRateZone',
    as HashRef[TimeInHeartRateZone()];

declare 'TimeInHeartRateZoneRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZoneRollupValue'];

coerce 'TimeInHeartRateZoneRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZoneRollupValue'->new($_) };

declare 'RepeatedTimeInHeartRateZoneRollupValue',
    as ArrayRef[TimeInHeartRateZoneRollupValue()];

coerce 'RepeatedTimeInHeartRateZoneRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZoneRollupValue'->new($_) } @$_ ] };

declare 'MapStringTimeInHeartRateZoneRollupValue',
    as HashRef[TimeInHeartRateZoneRollupValue()];

declare 'TimeInHeartRateZoneValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZoneRollupValue::TimeInHeartRateZoneValue'];

coerce 'TimeInHeartRateZoneValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZoneRollupValue::TimeInHeartRateZoneValue'->new($_) };

declare 'RepeatedTimeInHeartRateZoneValue',
    as ArrayRef[TimeInHeartRateZoneValue()];

coerce 'RepeatedTimeInHeartRateZoneValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::TimeInHeartRateZoneRollupValue::TimeInHeartRateZoneValue'->new($_) } @$_ ] };

declare 'MapStringTimeInHeartRateZoneValue',
    as HashRef[TimeInHeartRateZoneValue()];

declare 'TotalCaloriesRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::TotalCaloriesRollupValue'];

coerce 'TotalCaloriesRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::TotalCaloriesRollupValue'->new($_) };

declare 'RepeatedTotalCaloriesRollupValue',
    as ArrayRef[TotalCaloriesRollupValue()];

coerce 'RepeatedTotalCaloriesRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::TotalCaloriesRollupValue'->new($_) } @$_ ] };

declare 'MapStringTotalCaloriesRollupValue',
    as HashRef[TotalCaloriesRollupValue()];

declare 'VO2Max',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::VO2Max'];

coerce 'VO2Max',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::VO2Max'->new($_) };

declare 'RepeatedVO2Max',
    as ArrayRef[VO2Max()];

coerce 'RepeatedVO2Max',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::VO2Max'->new($_) } @$_ ] };

declare 'MapStringVO2Max',
    as HashRef[VO2Max()];

declare 'MeasurementMethod',
    as (Int | Str);

declare 'Weight',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Weight'];

coerce 'Weight',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Weight'->new($_) };

declare 'RepeatedWeight',
    as ArrayRef[Weight()];

coerce 'RepeatedWeight',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Weight'->new($_) } @$_ ] };

declare 'MapStringWeight',
    as HashRef[Weight()];

declare 'WeightRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::WeightRollupValue'];

coerce 'WeightRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::WeightRollupValue'->new($_) };

declare 'RepeatedWeightRollupValue',
    as ArrayRef[WeightRollupValue()];

coerce 'RepeatedWeightRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::WeightRollupValue'->new($_) } @$_ ] };

declare 'MapStringWeightRollupValue',
    as HashRef[WeightRollupValue()];

declare 'BloodGlucose',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::BloodGlucose'];

coerce 'BloodGlucose',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::BloodGlucose'->new($_) };

declare 'RepeatedBloodGlucose',
    as ArrayRef[BloodGlucose()];

coerce 'RepeatedBloodGlucose',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::BloodGlucose'->new($_) } @$_ ] };

declare 'MapStringBloodGlucose',
    as HashRef[BloodGlucose()];

declare 'MeasurementSource',
    as (Int | Str);

declare 'MealType',
    as (Int | Str);

declare 'MeasurementTiming',
    as (Int | Str);

declare 'Specimen',
    as (Int | Str);

declare 'BloodGlucoseRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::BloodGlucoseRollupValue'];

coerce 'BloodGlucoseRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::BloodGlucoseRollupValue'->new($_) };

declare 'RepeatedBloodGlucoseRollupValue',
    as ArrayRef[BloodGlucoseRollupValue()];

coerce 'RepeatedBloodGlucoseRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::BloodGlucoseRollupValue'->new($_) } @$_ ] };

declare 'MapStringBloodGlucoseRollupValue',
    as HashRef[BloodGlucoseRollupValue()];

declare 'SedentaryPeriod',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::SedentaryPeriod'];

coerce 'SedentaryPeriod',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::SedentaryPeriod'->new($_) };

declare 'RepeatedSedentaryPeriod',
    as ArrayRef[SedentaryPeriod()];

coerce 'RepeatedSedentaryPeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::SedentaryPeriod'->new($_) } @$_ ] };

declare 'MapStringSedentaryPeriod',
    as HashRef[SedentaryPeriod()];

declare 'SedentaryPeriodRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::SedentaryPeriodRollupValue'];

coerce 'SedentaryPeriodRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::SedentaryPeriodRollupValue'->new($_) };

declare 'RepeatedSedentaryPeriodRollupValue',
    as ArrayRef[SedentaryPeriodRollupValue()];

coerce 'RepeatedSedentaryPeriodRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::SedentaryPeriodRollupValue'->new($_) } @$_ ] };

declare 'MapStringSedentaryPeriodRollupValue',
    as HashRef[SedentaryPeriodRollupValue()];

declare 'ActiveEnergyBurned',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActiveEnergyBurned'];

coerce 'ActiveEnergyBurned',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActiveEnergyBurned'->new($_) };

declare 'RepeatedActiveEnergyBurned',
    as ArrayRef[ActiveEnergyBurned()];

coerce 'RepeatedActiveEnergyBurned',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActiveEnergyBurned'->new($_) } @$_ ] };

declare 'MapStringActiveEnergyBurned',
    as HashRef[ActiveEnergyBurned()];

declare 'ActiveEnergyBurnedRollupValue',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::ActiveEnergyBurnedRollupValue'];

coerce 'ActiveEnergyBurnedRollupValue',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::ActiveEnergyBurnedRollupValue'->new($_) };

declare 'RepeatedActiveEnergyBurnedRollupValue',
    as ArrayRef[ActiveEnergyBurnedRollupValue()];

coerce 'RepeatedActiveEnergyBurnedRollupValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::ActiveEnergyBurnedRollupValue'->new($_) } @$_ ] };

declare 'MapStringActiveEnergyBurnedRollupValue',
    as HashRef[ActiveEnergyBurnedRollupValue()];

declare 'MenstrualPeriod',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::MenstrualPeriod'];

coerce 'MenstrualPeriod',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::MenstrualPeriod'->new($_) };

declare 'RepeatedMenstrualPeriod',
    as ArrayRef[MenstrualPeriod()];

coerce 'RepeatedMenstrualPeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::MenstrualPeriod'->new($_) } @$_ ] };

declare 'MapStringMenstrualPeriod',
    as HashRef[MenstrualPeriod()];

declare 'OvulationTest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::OvulationTest'];

coerce 'OvulationTest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::OvulationTest'->new($_) };

declare 'RepeatedOvulationTest',
    as ArrayRef[OvulationTest()];

coerce 'RepeatedOvulationTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::OvulationTest'->new($_) } @$_ ] };

declare 'MapStringOvulationTest',
    as HashRef[OvulationTest()];

declare 'Symptoms',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Symptoms'];

coerce 'Symptoms',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Symptoms'->new($_) };

declare 'RepeatedSymptoms',
    as ArrayRef[Symptoms()];

coerce 'RepeatedSymptoms',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Symptoms'->new($_) } @$_ ] };

declare 'MapStringSymptoms',
    as HashRef[Symptoms()];

declare 'SymptomValue',
    as (Int | Str);

declare 'Moods',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataModel::Moods'];

coerce 'Moods',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataModel::Moods'->new($_) };

declare 'RepeatedMoods',
    as ArrayRef[Moods()];

coerce 'RepeatedMoods',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataModel::Moods'->new($_) } @$_ ] };

declare 'MapStringMoods',
    as HashRef[Moods()];

declare 'Mood',
    as (Int | Str);

declare 'Valence',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Devicesandservices::Health::V4::DataModel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
