package Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReportCauseCode',
    as (Int | Str);

declare 'IpUtilizationInfo',
    as InstanceOf['Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::IpUtilizationInfo'];

coerce 'IpUtilizationInfo',
    from HashRef, via { 'Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::IpUtilizationInfo'->new($_) };

declare 'RepeatedIpUtilizationInfo',
    as ArrayRef[IpUtilizationInfo()];

coerce 'RepeatedIpUtilizationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::IpUtilizationInfo'->new($_) } @$_ ] };

declare 'MapStringIpUtilizationInfo',
    as HashRef[IpUtilizationInfo()];

declare 'SubnetIpUtilization',
    as InstanceOf['Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::IpUtilizationInfo::SubnetIpUtilization'];

coerce 'SubnetIpUtilization',
    from HashRef, via { 'Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::IpUtilizationInfo::SubnetIpUtilization'->new($_) };

declare 'RepeatedSubnetIpUtilization',
    as ArrayRef[SubnetIpUtilization()];

coerce 'RepeatedSubnetIpUtilization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::IpUtilizationInfo::SubnetIpUtilization'->new($_) } @$_ ] };

declare 'MapStringSubnetIpUtilization',
    as HashRef[SubnetIpUtilization()];

declare 'Report',
    as InstanceOf['Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::Report'];

coerce 'Report',
    from HashRef, via { 'Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::Report'->new($_) };

declare 'RepeatedReport',
    as ArrayRef[Report()];

coerce 'RepeatedReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::Report'->new($_) } @$_ ] };

declare 'MapStringReport',
    as HashRef[Report()];

declare 'Priority',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'ReportStatus',
    as (Int | Str);

declare 'ReportGroup',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Networkanalyzer::Logging::V1::AnalyzerLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
