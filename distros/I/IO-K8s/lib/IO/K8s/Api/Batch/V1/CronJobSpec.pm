package IO::K8s::Api::Batch::V1::CronJobSpec;
# ABSTRACT: CronJobSpec describes how the job execution will look like and when it will actually run.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s concurrencyPolicy => Str;


k8s failedJobsHistoryLimit => Int;


k8s jobTemplate => 'Batch::V1::JobTemplateSpec', 'required';


k8s schedule => Str, 'required';


k8s startingDeadlineSeconds => Int;


k8s successfulJobsHistoryLimit => Int;


k8s suspend => Bool;


k8s timeZone => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Batch::V1::CronJobSpec - CronJobSpec describes how the job execution will look like and when it will actually run.

=head1 VERSION

version 1.006

=head2 concurrencyPolicy

Specifies how to treat concurrent executions of a Job. Valid values are:

- "Allow" (default): allows CronJobs to run concurrently; - "Forbid": forbids concurrent runs, skipping next run if previous run hasn't finished yet; - "Replace": cancels currently running job and replaces it with a new one

=head2 failedJobsHistoryLimit

The number of failed finished jobs to retain. Value must be non-negative integer. Defaults to 1.

=head2 jobTemplate

Specifies the job that will be created when executing a CronJob.

=head2 schedule

The schedule in Cron format, see https://en.wikipedia.org/wiki/Cron.

=head2 startingDeadlineSeconds

Optional deadline in seconds for starting the job if it misses scheduled time for any reason.  Missed jobs executions will be counted as failed ones.

=head2 successfulJobsHistoryLimit

The number of successful finished jobs to retain. Value must be non-negative integer. Defaults to 3.

=head2 suspend

This flag tells the controller to suspend subsequent executions, it does not apply to already started executions.  Defaults to false.

=head2 timeZone

The time zone name for the given schedule, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones. If not specified, this will default to the time zone of the kube-controller-manager process. The set of valid time zone names and the time zone offset is loaded from the system-wide time zone database by the API server during CronJob validation and the controller manager during execution. If no system-wide time zone database can be found a bundled version of the database is used instead. If the time zone name becomes invalid during the lifetime of a CronJob or due to a change in host configuration, the controller will stop creating new new Jobs and will create a system event with the reason UnknownTimeZone. More information can be found in https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
