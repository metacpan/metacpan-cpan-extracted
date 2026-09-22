package IO::K8s::ExternalSecrets::V1::ExternalSecretSyncWindowEntry;
# ABSTRACT: ExternalSecretSyncWindowEntry defines a single cron-schedule + duration pair within a SyncWindows block.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s duration => Str, { required => 'schema' };
k8s schedule => Str, { required => 'schema', pattern => '^(@(annually|yearly|monthly|weekly|daily|midnight|hourly)|@every [^\\s]+.*|[^\\s]+( [^\\s]+){4})$' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretSyncWindowEntry - ExternalSecretSyncWindowEntry defines a single cron-schedule + duration pair within a SyncWindows block.

=head1 VERSION

version 1.108

=head2 duration

Duration specifies how long the window stays open after each Schedule
firing. Example: "8h".

=head2 schedule

Schedule is a standard 5-field cron expression evaluated in UTC, or a
named shorthand such as @daily or @every 1h. It marks the start time of
each window occurrence.
Example: "0 22 * * 1-5" opens a window every weekday at 22:00 UTC.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
