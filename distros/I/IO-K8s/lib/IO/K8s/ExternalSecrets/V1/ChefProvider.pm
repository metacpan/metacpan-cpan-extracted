package IO::K8s::ExternalSecrets::V1::ChefProvider;
# ABSTRACT: Chef configures this store to sync secrets with chef server
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth      => '+IO::K8s::ExternalSecrets::V1::ChefAuth', { required => 'schema' };
k8s serverUrl => Str, { required => 'schema' };
k8s username  => Str, { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ChefProvider - Chef configures this store to sync secrets with chef server

=head1 VERSION

version 1.108

=head2 auth

Auth defines the information necessary to authenticate against chef Server

=head2 serverUrl

ServerURL is the chef server URL used to connect to. If using orgs you should include your org in the url and terminate the url with a "/"

=head2 username

UserName should be the user ID on the chef server

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
