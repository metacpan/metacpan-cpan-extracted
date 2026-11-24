package Google::Cloud::Chronicle::V1::DashboardChart::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TileType',
    as (Int | Str);

declare 'RenderType',
    as (Int | Str);

declare 'AxisType',
    as (Int | Str);

declare 'SeriesType',
    as (Int | Str);

declare 'SeriesStackStrategy',
    as (Int | Str);

declare 'ToolTipTrigger',
    as (Int | Str);

declare 'LegendOrient',
    as (Int | Str);

declare 'LegendAlign',
    as (Int | Str);

declare 'ButtonStyle',
    as (Int | Str);

declare 'PlotMode',
    as (Int | Str);

declare 'PointSizeType',
    as (Int | Str);

declare 'MetricFormat',
    as (Int | Str);

declare 'MetricDisplayTrend',
    as (Int | Str);

declare 'MetricTrendType',
    as (Int | Str);

declare 'VisualMapType',
    as (Int | Str);

declare 'DashboardChart',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart'];

coerce 'DashboardChart',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart'->new($_) };

declare 'RepeatedDashboardChart',
    as ArrayRef[DashboardChart()];

coerce 'RepeatedDashboardChart',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart'->new($_) } @$_ ] };

declare 'MapStringDashboardChart',
    as HashRef[DashboardChart()];

declare 'ChartDatasource',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::ChartDatasource'];

coerce 'ChartDatasource',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::ChartDatasource'->new($_) };

declare 'RepeatedChartDatasource',
    as ArrayRef[ChartDatasource()];

coerce 'RepeatedChartDatasource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::ChartDatasource'->new($_) } @$_ ] };

declare 'MapStringChartDatasource',
    as HashRef[ChartDatasource()];

declare 'Visualization',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization'];

coerce 'Visualization',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization'->new($_) };

declare 'RepeatedVisualization',
    as ArrayRef[Visualization()];

coerce 'RepeatedVisualization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization'->new($_) } @$_ ] };

declare 'MapStringVisualization',
    as HashRef[Visualization()];

declare 'Axis',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Axis'];

coerce 'Axis',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Axis'->new($_) };

declare 'RepeatedAxis',
    as ArrayRef[Axis()];

coerce 'RepeatedAxis',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Axis'->new($_) } @$_ ] };

declare 'MapStringAxis',
    as HashRef[Axis()];

declare 'Series',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series'];

coerce 'Series',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series'->new($_) };

declare 'RepeatedSeries',
    as ArrayRef[Series()];

coerce 'RepeatedSeries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series'->new($_) } @$_ ] };

declare 'MapStringSeries',
    as HashRef[Series()];

declare 'Encode',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::Encode'];

coerce 'Encode',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::Encode'->new($_) };

declare 'RepeatedEncode',
    as ArrayRef[Encode()];

coerce 'RepeatedEncode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::Encode'->new($_) } @$_ ] };

declare 'MapStringEncode',
    as HashRef[Encode()];

declare 'DataLabel',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::DataLabel'];

coerce 'DataLabel',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::DataLabel'->new($_) };

declare 'RepeatedDataLabel',
    as ArrayRef[DataLabel()];

coerce 'RepeatedDataLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::DataLabel'->new($_) } @$_ ] };

declare 'MapStringDataLabel',
    as HashRef[DataLabel()];

declare 'ItemStyle',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ItemStyle'];

coerce 'ItemStyle',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ItemStyle'->new($_) };

declare 'RepeatedItemStyle',
    as ArrayRef[ItemStyle()];

coerce 'RepeatedItemStyle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ItemStyle'->new($_) } @$_ ] };

declare 'MapStringItemStyle',
    as HashRef[ItemStyle()];

declare 'AreaStyle',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::AreaStyle'];

coerce 'AreaStyle',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::AreaStyle'->new($_) };

declare 'RepeatedAreaStyle',
    as ArrayRef[AreaStyle()];

coerce 'RepeatedAreaStyle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::AreaStyle'->new($_) } @$_ ] };

declare 'MapStringAreaStyle',
    as HashRef[AreaStyle()];

declare 'UserSelectedValues',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::UserSelectedValues'];

coerce 'UserSelectedValues',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::UserSelectedValues'->new($_) };

declare 'RepeatedUserSelectedValues',
    as ArrayRef[UserSelectedValues()];

coerce 'RepeatedUserSelectedValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::UserSelectedValues'->new($_) } @$_ ] };

declare 'MapStringUserSelectedValues',
    as HashRef[UserSelectedValues()];

declare 'ChartSliceColor',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ChartSliceColor'];

coerce 'ChartSliceColor',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ChartSliceColor'->new($_) };

declare 'RepeatedChartSliceColor',
    as ArrayRef[ChartSliceColor()];

coerce 'RepeatedChartSliceColor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ChartSliceColor'->new($_) } @$_ ] };

declare 'MapStringChartSliceColor',
    as HashRef[ChartSliceColor()];

declare 'ItemColors',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ItemColors'];

coerce 'ItemColors',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ItemColors'->new($_) };

declare 'RepeatedItemColors',
    as ArrayRef[ItemColors()];

coerce 'RepeatedItemColors',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::ItemColors'->new($_) } @$_ ] };

declare 'MapStringItemColors',
    as HashRef[ItemColors()];

declare 'GaugeValue',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::GaugeValue'];

coerce 'GaugeValue',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::GaugeValue'->new($_) };

declare 'RepeatedGaugeValue',
    as ArrayRef[GaugeValue()];

coerce 'RepeatedGaugeValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::GaugeValue'->new($_) } @$_ ] };

declare 'MapStringGaugeValue',
    as HashRef[GaugeValue()];

declare 'GaugeConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::GaugeConfig'];

coerce 'GaugeConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::GaugeConfig'->new($_) };

declare 'RepeatedGaugeConfig',
    as ArrayRef[GaugeConfig()];

coerce 'RepeatedGaugeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::GaugeConfig'->new($_) } @$_ ] };

declare 'MapStringGaugeConfig',
    as HashRef[GaugeConfig()];

declare 'MetricTrendConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::MetricTrendConfig'];

coerce 'MetricTrendConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::MetricTrendConfig'->new($_) };

declare 'RepeatedMetricTrendConfig',
    as ArrayRef[MetricTrendConfig()];

coerce 'RepeatedMetricTrendConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Series::MetricTrendConfig'->new($_) } @$_ ] };

declare 'MapStringMetricTrendConfig',
    as HashRef[MetricTrendConfig()];

declare 'Tooltip',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Tooltip'];

coerce 'Tooltip',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Tooltip'->new($_) };

declare 'RepeatedTooltip',
    as ArrayRef[Tooltip()];

coerce 'RepeatedTooltip',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Tooltip'->new($_) } @$_ ] };

declare 'MapStringTooltip',
    as HashRef[Tooltip()];

declare 'Legend',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Legend'];

coerce 'Legend',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Legend'->new($_) };

declare 'RepeatedLegend',
    as ArrayRef[Legend()];

coerce 'RepeatedLegend',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::Legend'->new($_) } @$_ ] };

declare 'MapStringLegend',
    as HashRef[Legend()];

declare 'ColumnDef',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnDef'];

coerce 'ColumnDef',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnDef'->new($_) };

declare 'RepeatedColumnDef',
    as ArrayRef[ColumnDef()];

coerce 'RepeatedColumnDef',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnDef'->new($_) } @$_ ] };

declare 'MapStringColumnDef',
    as HashRef[ColumnDef()];

declare 'ColumnRenderTypeSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnRenderTypeSettings'];

coerce 'ColumnRenderTypeSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnRenderTypeSettings'->new($_) };

declare 'RepeatedColumnRenderTypeSettings',
    as ArrayRef[ColumnRenderTypeSettings()];

coerce 'RepeatedColumnRenderTypeSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnRenderTypeSettings'->new($_) } @$_ ] };

declare 'MapStringColumnRenderTypeSettings',
    as HashRef[ColumnRenderTypeSettings()];

declare 'ColumnTooltipSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnTooltipSettings'];

coerce 'ColumnTooltipSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnTooltipSettings'->new($_) };

declare 'RepeatedColumnTooltipSettings',
    as ArrayRef[ColumnTooltipSettings()];

coerce 'RepeatedColumnTooltipSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::ColumnTooltipSettings'->new($_) } @$_ ] };

declare 'MapStringColumnTooltipSettings',
    as HashRef[ColumnTooltipSettings()];

declare 'TableConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::TableConfig'];

coerce 'TableConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::TableConfig'->new($_) };

declare 'RepeatedTableConfig',
    as ArrayRef[TableConfig()];

coerce 'RepeatedTableConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::TableConfig'->new($_) } @$_ ] };

declare 'MapStringTableConfig',
    as HashRef[TableConfig()];

declare 'GoogleMapsConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig'];

coerce 'GoogleMapsConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig'->new($_) };

declare 'RepeatedGoogleMapsConfig',
    as ArrayRef[GoogleMapsConfig()];

coerce 'RepeatedGoogleMapsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig'->new($_) } @$_ ] };

declare 'MapStringGoogleMapsConfig',
    as HashRef[GoogleMapsConfig()];

declare 'DataSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::DataSettings'];

coerce 'DataSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::DataSettings'->new($_) };

declare 'RepeatedDataSettings',
    as ArrayRef[DataSettings()];

coerce 'RepeatedDataSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::DataSettings'->new($_) } @$_ ] };

declare 'MapStringDataSettings',
    as HashRef[DataSettings()];

declare 'MapPosition',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::MapPosition'];

coerce 'MapPosition',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::MapPosition'->new($_) };

declare 'RepeatedMapPosition',
    as ArrayRef[MapPosition()];

coerce 'RepeatedMapPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::MapPosition'->new($_) } @$_ ] };

declare 'MapStringMapPosition',
    as HashRef[MapPosition()];

declare 'PointSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::PointSettings'];

coerce 'PointSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::PointSettings'->new($_) };

declare 'RepeatedPointSettings',
    as ArrayRef[PointSettings()];

coerce 'RepeatedPointSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::GoogleMapsConfig::PointSettings'->new($_) } @$_ ] };

declare 'MapStringPointSettings',
    as HashRef[PointSettings()];

declare 'VisualMap',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::VisualMap'];

coerce 'VisualMap',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::VisualMap'->new($_) };

declare 'RepeatedVisualMap',
    as ArrayRef[VisualMap()];

coerce 'RepeatedVisualMap',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::VisualMap'->new($_) } @$_ ] };

declare 'MapStringVisualMap',
    as HashRef[VisualMap()];

declare 'VisualMapPiece',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::VisualMap::VisualMapPiece'];

coerce 'VisualMapPiece',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::VisualMap::VisualMapPiece'->new($_) };

declare 'RepeatedVisualMapPiece',
    as ArrayRef[VisualMapPiece()];

coerce 'RepeatedVisualMapPiece',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::Visualization::VisualMap::VisualMapPiece'->new($_) } @$_ ] };

declare 'MapStringVisualMapPiece',
    as HashRef[VisualMapPiece()];

declare 'DrillDownConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig'];

coerce 'DrillDownConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig'->new($_) };

declare 'RepeatedDrillDownConfig',
    as ArrayRef[DrillDownConfig()];

coerce 'RepeatedDrillDownConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig'->new($_) } @$_ ] };

declare 'MapStringDrillDownConfig',
    as HashRef[DrillDownConfig()];

declare 'DrillDown',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown'];

coerce 'DrillDown',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown'->new($_) };

declare 'RepeatedDrillDown',
    as ArrayRef[DrillDown()];

coerce 'RepeatedDrillDown',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown'->new($_) } @$_ ] };

declare 'MapStringDrillDown',
    as HashRef[DrillDown()];

declare 'DefaultDrillDownSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::DefaultDrillDownSettings'];

coerce 'DefaultDrillDownSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::DefaultDrillDownSettings'->new($_) };

declare 'RepeatedDefaultDrillDownSettings',
    as ArrayRef[DefaultDrillDownSettings()];

coerce 'RepeatedDefaultDrillDownSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::DefaultDrillDownSettings'->new($_) } @$_ ] };

declare 'MapStringDefaultDrillDownSettings',
    as HashRef[DefaultDrillDownSettings()];

declare 'CustomDrillDownSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings'];

coerce 'CustomDrillDownSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings'->new($_) };

declare 'RepeatedCustomDrillDownSettings',
    as ArrayRef[CustomDrillDownSettings()];

coerce 'RepeatedCustomDrillDownSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings'->new($_) } @$_ ] };

declare 'MapStringCustomDrillDownSettings',
    as HashRef[CustomDrillDownSettings()];

declare 'DrillDownQuery',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownQuery'];

coerce 'DrillDownQuery',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownQuery'->new($_) };

declare 'RepeatedDrillDownQuery',
    as ArrayRef[DrillDownQuery()];

coerce 'RepeatedDrillDownQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownQuery'->new($_) } @$_ ] };

declare 'MapStringDrillDownQuery',
    as HashRef[DrillDownQuery()];

declare 'DrillDownFilter',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownFilter'];

coerce 'DrillDownFilter',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownFilter'->new($_) };

declare 'RepeatedDrillDownFilter',
    as ArrayRef[DrillDownFilter()];

coerce 'RepeatedDrillDownFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownFilter'->new($_) } @$_ ] };

declare 'MapStringDrillDownFilter',
    as HashRef[DrillDownFilter()];

declare 'DrillDownDashboardFilter',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownFilter::DrillDownDashboardFilter'];

coerce 'DrillDownDashboardFilter',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownFilter::DrillDownDashboardFilter'->new($_) };

declare 'RepeatedDrillDownDashboardFilter',
    as ArrayRef[DrillDownDashboardFilter()];

coerce 'RepeatedDrillDownDashboardFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownFilter::DrillDownDashboardFilter'->new($_) } @$_ ] };

declare 'MapStringDrillDownDashboardFilter',
    as HashRef[DrillDownDashboardFilter()];

declare 'DrillDownExternalLink',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownExternalLink'];

coerce 'DrillDownExternalLink',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownExternalLink'->new($_) };

declare 'RepeatedDrillDownExternalLink',
    as ArrayRef[DrillDownExternalLink()];

coerce 'RepeatedDrillDownExternalLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart::DrillDownConfig::DrillDown::CustomDrillDownSettings::DrillDownExternalLink'->new($_) } @$_ ] };

declare 'MapStringDrillDownExternalLink',
    as HashRef[DrillDownExternalLink()];

declare 'Button',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::Button'];

coerce 'Button',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::Button'->new($_) };

declare 'RepeatedButton',
    as ArrayRef[Button()];

coerce 'RepeatedButton',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::Button'->new($_) } @$_ ] };

declare 'MapStringButton',
    as HashRef[Button()];

declare 'Properties',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::Button::Properties'];

coerce 'Properties',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::Button::Properties'->new($_) };

declare 'RepeatedProperties',
    as ArrayRef[Properties()];

coerce 'RepeatedProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::Button::Properties'->new($_) } @$_ ] };

declare 'MapStringProperties',
    as HashRef[Properties()];

declare 'Markdown',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::Markdown'];

coerce 'Markdown',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::Markdown'->new($_) };

declare 'RepeatedMarkdown',
    as ArrayRef[Markdown()];

coerce 'RepeatedMarkdown',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::Markdown'->new($_) } @$_ ] };

declare 'MapStringMarkdown',
    as HashRef[Markdown()];

declare 'MarkdownProperties',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::Markdown::MarkdownProperties'];

coerce 'MarkdownProperties',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::Markdown::MarkdownProperties'->new($_) };

declare 'RepeatedMarkdownProperties',
    as ArrayRef[MarkdownProperties()];

coerce 'RepeatedMarkdownProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::Markdown::MarkdownProperties'->new($_) } @$_ ] };

declare 'MapStringMarkdownProperties',
    as HashRef[MarkdownProperties()];

declare 'GetDashboardChartRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::GetDashboardChartRequest'];

coerce 'GetDashboardChartRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::GetDashboardChartRequest'->new($_) };

declare 'RepeatedGetDashboardChartRequest',
    as ArrayRef[GetDashboardChartRequest()];

coerce 'RepeatedGetDashboardChartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::GetDashboardChartRequest'->new($_) } @$_ ] };

declare 'MapStringGetDashboardChartRequest',
    as HashRef[GetDashboardChartRequest()];

declare 'BatchGetDashboardChartsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::BatchGetDashboardChartsRequest'];

coerce 'BatchGetDashboardChartsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::BatchGetDashboardChartsRequest'->new($_) };

declare 'RepeatedBatchGetDashboardChartsRequest',
    as ArrayRef[BatchGetDashboardChartsRequest()];

coerce 'RepeatedBatchGetDashboardChartsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::BatchGetDashboardChartsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchGetDashboardChartsRequest',
    as HashRef[BatchGetDashboardChartsRequest()];

declare 'BatchGetDashboardChartsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardChart::BatchGetDashboardChartsResponse'];

coerce 'BatchGetDashboardChartsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardChart::BatchGetDashboardChartsResponse'->new($_) };

declare 'RepeatedBatchGetDashboardChartsResponse',
    as ArrayRef[BatchGetDashboardChartsResponse()];

coerce 'RepeatedBatchGetDashboardChartsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardChart::BatchGetDashboardChartsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchGetDashboardChartsResponse',
    as HashRef[BatchGetDashboardChartsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::DashboardChart::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
