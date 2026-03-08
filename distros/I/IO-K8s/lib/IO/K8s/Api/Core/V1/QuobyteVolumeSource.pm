package IO::K8s::Api::Core::V1::QuobyteVolumeSource;
# ABSTRACT: Represents a Quobyte mount that lasts the lifetime of a pod. Quobyte volumes do not support ownership management or SELinux relabeling.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s group => Str;


k8s readOnly => Bool;


k8s registry => Str, 'required';


k8s tenant => Str;


k8s user => Str;


k8s volume => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::QuobyteVolumeSource - Represents a Quobyte mount that lasts the lifetime of a pod. Quobyte volumes do not support ownership management or SELinux relabeling.

=head1 VERSION

version 1.006

=head2 group

group to map volume access to Default is no group

=head2 readOnly

readOnly here will force the Quobyte volume to be mounted with read-only permissions. Defaults to false.

=head2 registry

registry represents a single or multiple Quobyte Registry services specified as a string as host:port pair (multiple entries are separated with commas) which acts as the central registry for volumes

=head2 tenant

tenant owning the given Quobyte volume in the Backend Used with dynamically provisioned Quobyte volumes, value is set by the plugin

=head2 user

user to map volume access to Defaults to serivceaccount user

=head2 volume

volume is a string that references an already created Quobyte volume by name.

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
