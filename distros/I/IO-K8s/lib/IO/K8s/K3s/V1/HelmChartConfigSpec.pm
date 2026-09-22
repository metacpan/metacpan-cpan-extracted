package IO::K8s::K3s::V1::HelmChartConfigSpec;
# ABSTRACT: HelmChartConfigSpec represents additional user-configurable details of an installed and configured Helm chart release.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s failurePolicy  => Str, { enum => [qw(abort reinstall retry)], default => 'reinstall' };
k8s forceConflicts => Bool;
k8s serverSide     => Str, { enum => [qw(true false auto)] };
k8s values         => 'Apiextensions::V1::JSON';
k8s valuesContent  => Str;
k8s valuesSecrets  => ['+IO::K8s::K3s::V1::SecretSpec'];







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::HelmChartConfigSpec - HelmChartConfigSpec represents additional user-configurable details of an installed and configured Helm chart release.

=head1 VERSION

version 1.108

=head2 failurePolicy

Configures handling of failed chart installation or upgrades.
- `abort` will take no action and leave the chart in a failed state so that the administrator can manually resolve the error.
- `reinstall` will perform a clean uninstall and reinstall of the chart; this is the default behavior.
- `retry` will attempt to retry the install or upgrade whenever chart configuration changes.

=head2 forceConflicts

Set to true if helm should configure server-side apply to force changes when conflicts arise in ownership of managed fields.
Helm CLI positional argument/flag: `--force-conflicts`

=head2 serverSide

Set to true if helm should enable server-side apply when updating objects. Defaults to `true` for install, and `auto` for upgrade.
- `true` enables server-side apply.
- `false` disables server-side apply.
- `auto` enables server-side apply if the chart was installed with server-side apply enabled.
Helm CLI positional argument/flag: `--server-side`

=head2 values

Override complex Chart values via structured YAML. Takes precedence over options set via valuesContent.
Helm CLI positional argument/flag: `--values`

=head2 valuesContent

Override complex Chart values via inline YAML content.
Helm CLI positional argument/flag: `--values`

=head2 valuesSecrets

Override complex Chart values via references to external Secrets.
Helm CLI positional argument/flag: `--values`

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
