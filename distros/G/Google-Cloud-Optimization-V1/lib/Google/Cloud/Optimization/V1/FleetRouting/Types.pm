package Google::Cloud::Optimization::V1::FleetRouting::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OptimizeToursRequest',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursRequest'];

coerce 'OptimizeToursRequest',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursRequest'->new($_) };

declare 'RepeatedOptimizeToursRequest',
    as ArrayRef[OptimizeToursRequest()];

coerce 'RepeatedOptimizeToursRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursRequest'->new($_) } @$_ ] };

declare 'MapStringOptimizeToursRequest',
    as HashRef[OptimizeToursRequest()];

declare 'SolvingMode',
    as (Int | Str);

declare 'SearchMode',
    as (Int | Str);

declare 'OptimizeToursResponse',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse'];

coerce 'OptimizeToursResponse',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse'->new($_) };

declare 'RepeatedOptimizeToursResponse',
    as ArrayRef[OptimizeToursResponse()];

coerce 'RepeatedOptimizeToursResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse'->new($_) } @$_ ] };

declare 'MapStringOptimizeToursResponse',
    as HashRef[OptimizeToursResponse()];

declare 'Metrics',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'CostsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse::Metrics::CostsEntry'];

coerce 'CostsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse::Metrics::CostsEntry'->new($_) };

declare 'RepeatedCostsEntry',
    as ArrayRef[CostsEntry()];

coerce 'RepeatedCostsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse::Metrics::CostsEntry'->new($_) } @$_ ] };

declare 'MapStringCostsEntry',
    as HashRef[CostsEntry()];

declare 'BatchOptimizeToursRequest',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursRequest'];

coerce 'BatchOptimizeToursRequest',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursRequest'->new($_) };

declare 'RepeatedBatchOptimizeToursRequest',
    as ArrayRef[BatchOptimizeToursRequest()];

coerce 'RepeatedBatchOptimizeToursRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursRequest'->new($_) } @$_ ] };

declare 'MapStringBatchOptimizeToursRequest',
    as HashRef[BatchOptimizeToursRequest()];

declare 'AsyncModelConfig',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursRequest::AsyncModelConfig'];

coerce 'AsyncModelConfig',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursRequest::AsyncModelConfig'->new($_) };

declare 'RepeatedAsyncModelConfig',
    as ArrayRef[AsyncModelConfig()];

coerce 'RepeatedAsyncModelConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursRequest::AsyncModelConfig'->new($_) } @$_ ] };

declare 'MapStringAsyncModelConfig',
    as HashRef[AsyncModelConfig()];

declare 'BatchOptimizeToursResponse',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursResponse'];

coerce 'BatchOptimizeToursResponse',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursResponse'->new($_) };

declare 'RepeatedBatchOptimizeToursResponse',
    as ArrayRef[BatchOptimizeToursResponse()];

coerce 'RepeatedBatchOptimizeToursResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::BatchOptimizeToursResponse'->new($_) } @$_ ] };

declare 'MapStringBatchOptimizeToursResponse',
    as HashRef[BatchOptimizeToursResponse()];

declare 'ShipmentModel',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel'];

coerce 'ShipmentModel',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel'->new($_) };

declare 'RepeatedShipmentModel',
    as ArrayRef[ShipmentModel()];

coerce 'RepeatedShipmentModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel'->new($_) } @$_ ] };

declare 'MapStringShipmentModel',
    as HashRef[ShipmentModel()];

declare 'DurationDistanceMatrix',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::DurationDistanceMatrix'];

coerce 'DurationDistanceMatrix',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::DurationDistanceMatrix'->new($_) };

declare 'RepeatedDurationDistanceMatrix',
    as ArrayRef[DurationDistanceMatrix()];

coerce 'RepeatedDurationDistanceMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::DurationDistanceMatrix'->new($_) } @$_ ] };

declare 'MapStringDurationDistanceMatrix',
    as HashRef[DurationDistanceMatrix()];

declare 'Row',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::DurationDistanceMatrix::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::DurationDistanceMatrix::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::DurationDistanceMatrix::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'PrecedenceRule',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::PrecedenceRule'];

coerce 'PrecedenceRule',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::PrecedenceRule'->new($_) };

declare 'RepeatedPrecedenceRule',
    as ArrayRef[PrecedenceRule()];

coerce 'RepeatedPrecedenceRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::PrecedenceRule'->new($_) } @$_ ] };

declare 'MapStringPrecedenceRule',
    as HashRef[PrecedenceRule()];

declare 'BreakRule',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule'];

coerce 'BreakRule',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule'->new($_) };

declare 'RepeatedBreakRule',
    as ArrayRef[BreakRule()];

coerce 'RepeatedBreakRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule'->new($_) } @$_ ] };

declare 'MapStringBreakRule',
    as HashRef[BreakRule()];

declare 'BreakRequest',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule::BreakRequest'];

coerce 'BreakRequest',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule::BreakRequest'->new($_) };

declare 'RepeatedBreakRequest',
    as ArrayRef[BreakRequest()];

coerce 'RepeatedBreakRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule::BreakRequest'->new($_) } @$_ ] };

declare 'MapStringBreakRequest',
    as HashRef[BreakRequest()];

declare 'FrequencyConstraint',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule::FrequencyConstraint'];

coerce 'FrequencyConstraint',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule::FrequencyConstraint'->new($_) };

declare 'RepeatedFrequencyConstraint',
    as ArrayRef[FrequencyConstraint()];

coerce 'RepeatedFrequencyConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel::BreakRule::FrequencyConstraint'->new($_) } @$_ ] };

declare 'MapStringFrequencyConstraint',
    as HashRef[FrequencyConstraint()];

declare 'Shipment',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Shipment'];

coerce 'Shipment',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment'->new($_) };

declare 'RepeatedShipment',
    as ArrayRef[Shipment()];

coerce 'RepeatedShipment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment'->new($_) } @$_ ] };

declare 'MapStringShipment',
    as HashRef[Shipment()];

declare 'VisitRequest',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Shipment::VisitRequest'];

coerce 'VisitRequest',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment::VisitRequest'->new($_) };

declare 'RepeatedVisitRequest',
    as ArrayRef[VisitRequest()];

coerce 'RepeatedVisitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment::VisitRequest'->new($_) } @$_ ] };

declare 'MapStringVisitRequest',
    as HashRef[VisitRequest()];

declare 'LoadDemandsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Shipment::VisitRequest::LoadDemandsEntry'];

coerce 'LoadDemandsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment::VisitRequest::LoadDemandsEntry'->new($_) };

declare 'RepeatedLoadDemandsEntry',
    as ArrayRef[LoadDemandsEntry()];

coerce 'RepeatedLoadDemandsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment::VisitRequest::LoadDemandsEntry'->new($_) } @$_ ] };

declare 'MapStringLoadDemandsEntry',
    as HashRef[LoadDemandsEntry()];

declare 'Load',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Shipment::Load'];

coerce 'Load',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment::Load'->new($_) };

declare 'RepeatedLoad',
    as ArrayRef[Load()];

coerce 'RepeatedLoad',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment::Load'->new($_) } @$_ ] };

declare 'MapStringLoad',
    as HashRef[Load()];

declare 'LoadDemandsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Shipment::LoadDemandsEntry'];

coerce 'LoadDemandsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment::LoadDemandsEntry'->new($_) };

declare 'RepeatedLoadDemandsEntry',
    as ArrayRef[LoadDemandsEntry()];

coerce 'RepeatedLoadDemandsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Shipment::LoadDemandsEntry'->new($_) } @$_ ] };

declare 'MapStringLoadDemandsEntry',
    as HashRef[LoadDemandsEntry()];

declare 'ShipmentTypeIncompatibility',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentTypeIncompatibility'];

coerce 'ShipmentTypeIncompatibility',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentTypeIncompatibility'->new($_) };

declare 'RepeatedShipmentTypeIncompatibility',
    as ArrayRef[ShipmentTypeIncompatibility()];

coerce 'RepeatedShipmentTypeIncompatibility',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentTypeIncompatibility'->new($_) } @$_ ] };

declare 'MapStringShipmentTypeIncompatibility',
    as HashRef[ShipmentTypeIncompatibility()];

declare 'IncompatibilityMode',
    as (Int | Str);

declare 'ShipmentTypeRequirement',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentTypeRequirement'];

coerce 'ShipmentTypeRequirement',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentTypeRequirement'->new($_) };

declare 'RepeatedShipmentTypeRequirement',
    as ArrayRef[ShipmentTypeRequirement()];

coerce 'RepeatedShipmentTypeRequirement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentTypeRequirement'->new($_) } @$_ ] };

declare 'MapStringShipmentTypeRequirement',
    as HashRef[ShipmentTypeRequirement()];

declare 'RequirementMode',
    as (Int | Str);

declare 'RouteModifiers',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::RouteModifiers'];

coerce 'RouteModifiers',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::RouteModifiers'->new($_) };

declare 'RepeatedRouteModifiers',
    as ArrayRef[RouteModifiers()];

coerce 'RepeatedRouteModifiers',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::RouteModifiers'->new($_) } @$_ ] };

declare 'MapStringRouteModifiers',
    as HashRef[RouteModifiers()];

declare 'Vehicle',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Vehicle'];

coerce 'Vehicle',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle'->new($_) };

declare 'RepeatedVehicle',
    as ArrayRef[Vehicle()];

coerce 'RepeatedVehicle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle'->new($_) } @$_ ] };

declare 'MapStringVehicle',
    as HashRef[Vehicle()];

declare 'TravelMode',
    as (Int | Str);

declare 'UnloadingPolicy',
    as (Int | Str);

declare 'LoadLimit',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimit'];

coerce 'LoadLimit',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimit'->new($_) };

declare 'RepeatedLoadLimit',
    as ArrayRef[LoadLimit()];

coerce 'RepeatedLoadLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimit'->new($_) } @$_ ] };

declare 'MapStringLoadLimit',
    as HashRef[LoadLimit()];

declare 'Interval',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimit::Interval'];

coerce 'Interval',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimit::Interval'->new($_) };

declare 'RepeatedInterval',
    as ArrayRef[Interval()];

coerce 'RepeatedInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimit::Interval'->new($_) } @$_ ] };

declare 'MapStringInterval',
    as HashRef[Interval()];

declare 'DurationLimit',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Vehicle::DurationLimit'];

coerce 'DurationLimit',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::DurationLimit'->new($_) };

declare 'RepeatedDurationLimit',
    as ArrayRef[DurationLimit()];

coerce 'RepeatedDurationLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::DurationLimit'->new($_) } @$_ ] };

declare 'MapStringDurationLimit',
    as HashRef[DurationLimit()];

declare 'LoadLimitsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimitsEntry'];

coerce 'LoadLimitsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimitsEntry'->new($_) };

declare 'RepeatedLoadLimitsEntry',
    as ArrayRef[LoadLimitsEntry()];

coerce 'RepeatedLoadLimitsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::LoadLimitsEntry'->new($_) } @$_ ] };

declare 'MapStringLoadLimitsEntry',
    as HashRef[LoadLimitsEntry()];

declare 'ExtraVisitDurationForVisitTypeEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Vehicle::ExtraVisitDurationForVisitTypeEntry'];

coerce 'ExtraVisitDurationForVisitTypeEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::ExtraVisitDurationForVisitTypeEntry'->new($_) };

declare 'RepeatedExtraVisitDurationForVisitTypeEntry',
    as ArrayRef[ExtraVisitDurationForVisitTypeEntry()];

coerce 'RepeatedExtraVisitDurationForVisitTypeEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Vehicle::ExtraVisitDurationForVisitTypeEntry'->new($_) } @$_ ] };

declare 'MapStringExtraVisitDurationForVisitTypeEntry',
    as HashRef[ExtraVisitDurationForVisitTypeEntry()];

declare 'TimeWindow',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::TimeWindow'];

coerce 'TimeWindow',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::TimeWindow'->new($_) };

declare 'RepeatedTimeWindow',
    as ArrayRef[TimeWindow()];

coerce 'RepeatedTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::TimeWindow'->new($_) } @$_ ] };

declare 'MapStringTimeWindow',
    as HashRef[TimeWindow()];

declare 'CapacityQuantity',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::CapacityQuantity'];

coerce 'CapacityQuantity',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::CapacityQuantity'->new($_) };

declare 'RepeatedCapacityQuantity',
    as ArrayRef[CapacityQuantity()];

coerce 'RepeatedCapacityQuantity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::CapacityQuantity'->new($_) } @$_ ] };

declare 'MapStringCapacityQuantity',
    as HashRef[CapacityQuantity()];

declare 'CapacityQuantityInterval',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::CapacityQuantityInterval'];

coerce 'CapacityQuantityInterval',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::CapacityQuantityInterval'->new($_) };

declare 'RepeatedCapacityQuantityInterval',
    as ArrayRef[CapacityQuantityInterval()];

coerce 'RepeatedCapacityQuantityInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::CapacityQuantityInterval'->new($_) } @$_ ] };

declare 'MapStringCapacityQuantityInterval',
    as HashRef[CapacityQuantityInterval()];

declare 'DistanceLimit',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::DistanceLimit'];

coerce 'DistanceLimit',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::DistanceLimit'->new($_) };

declare 'RepeatedDistanceLimit',
    as ArrayRef[DistanceLimit()];

coerce 'RepeatedDistanceLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::DistanceLimit'->new($_) } @$_ ] };

declare 'MapStringDistanceLimit',
    as HashRef[DistanceLimit()];

declare 'TransitionAttributes',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::TransitionAttributes'];

coerce 'TransitionAttributes',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::TransitionAttributes'->new($_) };

declare 'RepeatedTransitionAttributes',
    as ArrayRef[TransitionAttributes()];

coerce 'RepeatedTransitionAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::TransitionAttributes'->new($_) } @$_ ] };

declare 'MapStringTransitionAttributes',
    as HashRef[TransitionAttributes()];

declare 'Waypoint',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Waypoint'];

coerce 'Waypoint',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Waypoint'->new($_) };

declare 'RepeatedWaypoint',
    as ArrayRef[Waypoint()];

coerce 'RepeatedWaypoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Waypoint'->new($_) } @$_ ] };

declare 'MapStringWaypoint',
    as HashRef[Waypoint()];

declare 'Location',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'BreakRule',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::BreakRule'];

coerce 'BreakRule',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::BreakRule'->new($_) };

declare 'RepeatedBreakRule',
    as ArrayRef[BreakRule()];

coerce 'RepeatedBreakRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::BreakRule'->new($_) } @$_ ] };

declare 'MapStringBreakRule',
    as HashRef[BreakRule()];

declare 'BreakRequest',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::BreakRule::BreakRequest'];

coerce 'BreakRequest',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::BreakRule::BreakRequest'->new($_) };

declare 'RepeatedBreakRequest',
    as ArrayRef[BreakRequest()];

coerce 'RepeatedBreakRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::BreakRule::BreakRequest'->new($_) } @$_ ] };

declare 'MapStringBreakRequest',
    as HashRef[BreakRequest()];

declare 'FrequencyConstraint',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::BreakRule::FrequencyConstraint'];

coerce 'FrequencyConstraint',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::BreakRule::FrequencyConstraint'->new($_) };

declare 'RepeatedFrequencyConstraint',
    as ArrayRef[FrequencyConstraint()];

coerce 'RepeatedFrequencyConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::BreakRule::FrequencyConstraint'->new($_) } @$_ ] };

declare 'MapStringFrequencyConstraint',
    as HashRef[FrequencyConstraint()];

declare 'ShipmentRoute',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute'];

coerce 'ShipmentRoute',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute'->new($_) };

declare 'RepeatedShipmentRoute',
    as ArrayRef[ShipmentRoute()];

coerce 'RepeatedShipmentRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute'->new($_) } @$_ ] };

declare 'MapStringShipmentRoute',
    as HashRef[ShipmentRoute()];

declare 'Delay',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Delay'];

coerce 'Delay',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Delay'->new($_) };

declare 'RepeatedDelay',
    as ArrayRef[Delay()];

coerce 'RepeatedDelay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Delay'->new($_) } @$_ ] };

declare 'MapStringDelay',
    as HashRef[Delay()];

declare 'Visit',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Visit'];

coerce 'Visit',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Visit'->new($_) };

declare 'RepeatedVisit',
    as ArrayRef[Visit()];

coerce 'RepeatedVisit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Visit'->new($_) } @$_ ] };

declare 'MapStringVisit',
    as HashRef[Visit()];

declare 'LoadDemandsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Visit::LoadDemandsEntry'];

coerce 'LoadDemandsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Visit::LoadDemandsEntry'->new($_) };

declare 'RepeatedLoadDemandsEntry',
    as ArrayRef[LoadDemandsEntry()];

coerce 'RepeatedLoadDemandsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Visit::LoadDemandsEntry'->new($_) } @$_ ] };

declare 'MapStringLoadDemandsEntry',
    as HashRef[LoadDemandsEntry()];

declare 'Transition',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Transition'];

coerce 'Transition',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Transition'->new($_) };

declare 'RepeatedTransition',
    as ArrayRef[Transition()];

coerce 'RepeatedTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Transition'->new($_) } @$_ ] };

declare 'MapStringTransition',
    as HashRef[Transition()];

declare 'VehicleLoadsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Transition::VehicleLoadsEntry'];

coerce 'VehicleLoadsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Transition::VehicleLoadsEntry'->new($_) };

declare 'RepeatedVehicleLoadsEntry',
    as ArrayRef[VehicleLoadsEntry()];

coerce 'RepeatedVehicleLoadsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Transition::VehicleLoadsEntry'->new($_) } @$_ ] };

declare 'MapStringVehicleLoadsEntry',
    as HashRef[VehicleLoadsEntry()];

declare 'VehicleLoad',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::VehicleLoad'];

coerce 'VehicleLoad',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::VehicleLoad'->new($_) };

declare 'RepeatedVehicleLoad',
    as ArrayRef[VehicleLoad()];

coerce 'RepeatedVehicleLoad',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::VehicleLoad'->new($_) } @$_ ] };

declare 'MapStringVehicleLoad',
    as HashRef[VehicleLoad()];

declare 'EncodedPolyline',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::EncodedPolyline'];

coerce 'EncodedPolyline',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::EncodedPolyline'->new($_) };

declare 'RepeatedEncodedPolyline',
    as ArrayRef[EncodedPolyline()];

coerce 'RepeatedEncodedPolyline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::EncodedPolyline'->new($_) } @$_ ] };

declare 'MapStringEncodedPolyline',
    as HashRef[EncodedPolyline()];

declare 'Break',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Break'];

coerce 'Break',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Break'->new($_) };

declare 'RepeatedBreak',
    as ArrayRef[Break()];

coerce 'RepeatedBreak',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::Break'->new($_) } @$_ ] };

declare 'MapStringBreak',
    as HashRef[Break()];

declare 'TravelStep',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::TravelStep'];

coerce 'TravelStep',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::TravelStep'->new($_) };

declare 'RepeatedTravelStep',
    as ArrayRef[TravelStep()];

coerce 'RepeatedTravelStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::TravelStep'->new($_) } @$_ ] };

declare 'MapStringTravelStep',
    as HashRef[TravelStep()];

declare 'RouteCostsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::RouteCostsEntry'];

coerce 'RouteCostsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::RouteCostsEntry'->new($_) };

declare 'RepeatedRouteCostsEntry',
    as ArrayRef[RouteCostsEntry()];

coerce 'RepeatedRouteCostsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute::RouteCostsEntry'->new($_) } @$_ ] };

declare 'MapStringRouteCostsEntry',
    as HashRef[RouteCostsEntry()];

declare 'SkippedShipment',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::SkippedShipment'];

coerce 'SkippedShipment',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::SkippedShipment'->new($_) };

declare 'RepeatedSkippedShipment',
    as ArrayRef[SkippedShipment()];

coerce 'RepeatedSkippedShipment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::SkippedShipment'->new($_) } @$_ ] };

declare 'MapStringSkippedShipment',
    as HashRef[SkippedShipment()];

declare 'Reason',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::SkippedShipment::Reason'];

coerce 'Reason',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::SkippedShipment::Reason'->new($_) };

declare 'RepeatedReason',
    as ArrayRef[Reason()];

coerce 'RepeatedReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::SkippedShipment::Reason'->new($_) } @$_ ] };

declare 'MapStringReason',
    as HashRef[Reason()];

declare 'Code',
    as (Int | Str);

declare 'AggregatedMetrics',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics'];

coerce 'AggregatedMetrics',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics'->new($_) };

declare 'RepeatedAggregatedMetrics',
    as ArrayRef[AggregatedMetrics()];

coerce 'RepeatedAggregatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics'->new($_) } @$_ ] };

declare 'MapStringAggregatedMetrics',
    as HashRef[AggregatedMetrics()];

declare 'MaxLoadsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics::MaxLoadsEntry'];

coerce 'MaxLoadsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics::MaxLoadsEntry'->new($_) };

declare 'RepeatedMaxLoadsEntry',
    as ArrayRef[MaxLoadsEntry()];

coerce 'RepeatedMaxLoadsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics::MaxLoadsEntry'->new($_) } @$_ ] };

declare 'MapStringMaxLoadsEntry',
    as HashRef[MaxLoadsEntry()];

declare 'CostsEntry',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics::CostsEntry'];

coerce 'CostsEntry',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics::CostsEntry'->new($_) };

declare 'RepeatedCostsEntry',
    as ArrayRef[CostsEntry()];

coerce 'RepeatedCostsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::AggregatedMetrics::CostsEntry'->new($_) } @$_ ] };

declare 'MapStringCostsEntry',
    as HashRef[CostsEntry()];

declare 'InjectedSolutionConstraint',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint'];

coerce 'InjectedSolutionConstraint',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint'->new($_) };

declare 'RepeatedInjectedSolutionConstraint',
    as ArrayRef[InjectedSolutionConstraint()];

coerce 'RepeatedInjectedSolutionConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint'->new($_) } @$_ ] };

declare 'MapStringInjectedSolutionConstraint',
    as HashRef[InjectedSolutionConstraint()];

declare 'ConstraintRelaxation',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint::ConstraintRelaxation'];

coerce 'ConstraintRelaxation',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint::ConstraintRelaxation'->new($_) };

declare 'RepeatedConstraintRelaxation',
    as ArrayRef[ConstraintRelaxation()];

coerce 'RepeatedConstraintRelaxation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint::ConstraintRelaxation'->new($_) } @$_ ] };

declare 'MapStringConstraintRelaxation',
    as HashRef[ConstraintRelaxation()];

declare 'Relaxation',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint::ConstraintRelaxation::Relaxation'];

coerce 'Relaxation',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint::ConstraintRelaxation::Relaxation'->new($_) };

declare 'RepeatedRelaxation',
    as ArrayRef[Relaxation()];

coerce 'RepeatedRelaxation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint::ConstraintRelaxation::Relaxation'->new($_) } @$_ ] };

declare 'MapStringRelaxation',
    as HashRef[Relaxation()];

declare 'Level',
    as (Int | Str);

declare 'OptimizeToursValidationError',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursValidationError'];

coerce 'OptimizeToursValidationError',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursValidationError'->new($_) };

declare 'RepeatedOptimizeToursValidationError',
    as ArrayRef[OptimizeToursValidationError()];

coerce 'RepeatedOptimizeToursValidationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursValidationError'->new($_) } @$_ ] };

declare 'MapStringOptimizeToursValidationError',
    as HashRef[OptimizeToursValidationError()];

declare 'FieldReference',
    as InstanceOf['Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursValidationError::FieldReference'];

coerce 'FieldReference',
    from HashRef, via { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursValidationError::FieldReference'->new($_) };

declare 'RepeatedFieldReference',
    as ArrayRef[FieldReference()];

coerce 'RepeatedFieldReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursValidationError::FieldReference'->new($_) } @$_ ] };

declare 'MapStringFieldReference',
    as HashRef[FieldReference()];

1;

__END__

=head1 NAME

Google::Cloud::Optimization::V1::FleetRouting::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
