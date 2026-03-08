package IO::K8s::Api::Core::V1::WindowsSecurityContextOptions;
# ABSTRACT: WindowsSecurityContextOptions contain Windows-specific options and credentials.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s gmsaCredentialSpec => Str;


k8s gmsaCredentialSpecName => Str;


k8s hostProcess => Bool;


k8s runAsUserName => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::WindowsSecurityContextOptions - WindowsSecurityContextOptions contain Windows-specific options and credentials.

=head1 VERSION

version 1.006

=head2 gmsaCredentialSpec

GMSACredentialSpec is where the GMSA admission webhook (https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the GMSA credential spec named by the GMSACredentialSpecName field.

=head2 gmsaCredentialSpecName

GMSACredentialSpecName is the name of the GMSA credential spec to use.

=head2 hostProcess

HostProcess determines if a container should be run as a 'Host Process' container. All of a Pod's containers must have the same effective HostProcess value (it is not allowed to have a mix of HostProcess containers and non-HostProcess containers). In addition, if HostProcess is true then HostNetwork must also be set to true.

=head2 runAsUserName

The UserName in Windows to run the entrypoint of the container process. Defaults to the user specified in image metadata if unspecified. May also be set in PodSecurityContext. If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.

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
