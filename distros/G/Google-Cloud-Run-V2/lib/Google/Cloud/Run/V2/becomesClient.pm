package Google::Cloud::Run::V2::becomesClient;

use strict;
use warnings;

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Run::V2::ContainerStatus;
use Google::Cloud::Run::V2::Status;
use Google::Cloud::Run::V2::TrafficTarget;
use Google::Cloud::Run::V2::InstanceSplit;
use Google::Cloud::Run::V2::VendorSettings;
use Google::Cloud::Run::V2::K8sMin;
use Google::Cloud::Run::V2::Condition;
use Google::Cloud::Run::V2::Build;
use Google::Cloud::Run::V2::SourceUpload;
use Google::Cloud::Run::V2::Sandbox;
use Google::Cloud::Run::V2::Instance;
use Google::Cloud::Run::V2::Task;
use Google::Cloud::Run::V2::RevisionTemplate;
use Google::Cloud::Run::V2::WorkerPoolRevisionTemplate;
use Google::Cloud::Run::V2::Revision;
use Google::Cloud::Run::V2::TaskTemplate;
use Google::Cloud::Run::V2::Service;
use Google::Cloud::Run::V2::WorkerPool;
use Google::Cloud::Run::V2::Execution;
use Google::Cloud::Run::V2::ExecutionTemplate;
use Google::Cloud::Run::V2::Job;

our $VERSION = '0.06';
1; # End of Google::Cloud::Run::V2::becomesClient

__END__

=head1 NAME

Google::Cloud::Run::V2::becomesClient - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::BuildsClient;

    my $client = Google::Cloud::Run::V2::BuildsClient->new();

=head1 CLIENTS

This distribution provides the following service client classes:

=over 4

=item * L<Google::Cloud::Run::V2::BuildsClient>

=item * L<Google::Cloud::Run::V2::ExecutionsClient>

=item * L<Google::Cloud::Run::V2::InstancesClient>

=item * L<Google::Cloud::Run::V2::JobsClient>

=item * L<Google::Cloud::Run::V2::RevisionsClient>

=item * L<Google::Cloud::Run::V2::ServicesClient>

=item * L<Google::Cloud::Run::V2::SourceUploadClient>

=item * L<Google::Cloud::Run::V2::TasksClient>

=item * L<Google::Cloud::Run::V2::WorkerPoolsClient>

=item * L<Google::Cloud::Run::V2::becomesClient>

=back

=head1 SEE ALSO

L<Google::Cloud::Run::V2::BuildsClient>, L<Google::Cloud::Run::V2::ExecutionsClient>, L<Google::Cloud::Run::V2::InstancesClient>, L<Google::Cloud::Run::V2::JobsClient>, L<Google::Cloud::Run::V2::RevisionsClient>, L<Google::Cloud::Run::V2::ServicesClient>, L<Google::Cloud::Run::V2::SourceUploadClient>, L<Google::Cloud::Run::V2::TasksClient>, L<Google::Cloud::Run::V2::WorkerPoolsClient>, L<Google::Cloud::Run::V2::becomesClient>

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/run/v2/build.proto>

=item * C<googleapis/google/cloud/run/v2/condition.proto>

=item * C<googleapis/google/cloud/run/v2/container_status.proto>

=item * C<googleapis/google/cloud/run/v2/execution.proto>

=item * C<googleapis/google/cloud/run/v2/execution_template.proto>

=item * C<googleapis/google/cloud/run/v2/instance.proto>

=item * C<googleapis/google/cloud/run/v2/instance_split.proto>

=item * C<googleapis/google/cloud/run/v2/job.proto>

=item * C<googleapis/google/cloud/run/v2/k8s.min.proto>

=item * C<googleapis/google/cloud/run/v2/revision.proto>

=item * C<googleapis/google/cloud/run/v2/revision_template.proto>

=item * C<googleapis/google/cloud/run/v2/sandbox.proto>

=item * C<googleapis/google/cloud/run/v2/service.proto>

=item * C<googleapis/google/cloud/run/v2/source_upload.proto>

=item * C<googleapis/google/cloud/run/v2/status.proto>

=item * C<googleapis/google/cloud/run/v2/task.proto>

=item * C<googleapis/google/cloud/run/v2/task_template.proto>

=item * C<googleapis/google/cloud/run/v2/traffic_target.proto>

=item * C<googleapis/google/cloud/run/v2/vendor_settings.proto>

=item * C<googleapis/google/cloud/run/v2/worker_pool.proto>

=item * C<googleapis/google/cloud/run/v2/worker_pool_revision_template.proto>



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
