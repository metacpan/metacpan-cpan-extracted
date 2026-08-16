package IO::K8s::Api::Core::V1::FileKeySelector;
# ABSTRACT: FileKeySelector selects a key of the env file.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s key => Str, 'required';


k8s optional => Bool;


k8s path => Str, 'required';


k8s volumeName => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::FileKeySelector - FileKeySelector selects a key of the env file.

=head1 VERSION

version 1.107

=head2 key

The key within the env file. An invalid key will prevent the pod from starting. The keys defined within a source may consist of any printable ASCII characters except '='. During Alpha stage of the EnvFiles feature gate, the key size is limited to 128 characters.

=head2 optional

Specify whether the file or its key must be defined. If the file or key does not exist, then the env var is not published. If optional is set to true and the specified key does not exist, the environment variable will not be set in the Pod's containers.

If optional is set to false and the specified key does not exist, an error will be returned during Pod creation.

=head2 path

The path within the volume from which to select the file. Must be relative and may not contain the '..' path or start with '..'.

=head2 volumeName

The name of the volume mount containing the env file.

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
