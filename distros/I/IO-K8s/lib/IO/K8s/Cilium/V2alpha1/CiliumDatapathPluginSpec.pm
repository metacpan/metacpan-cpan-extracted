package IO::K8s::Cilium::V2alpha1::CiliumDatapathPluginSpec;
# ABSTRACT: CiliumDatapathPluginSpec
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s attachmentPolicy => Str, { required => 'schema', enum => [qw(Always BestEffort)] };
k8s version          => Str, { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumDatapathPluginSpec - CiliumDatapathPluginSpec

=head1 VERSION

version 1.108

=head2 attachmentPolicy

AttachmentPolicy dictates how Cilium behaves when it cannot talk to
a plugin.

=head2 version

Version is an opaque string used to indicate the datapath plugin version.
Update this when deploying a new version of a datapath plugin to trigger a datapath
reinitialization.

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
