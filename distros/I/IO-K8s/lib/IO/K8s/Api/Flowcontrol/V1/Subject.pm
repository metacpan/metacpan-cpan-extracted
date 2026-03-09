package IO::K8s::Api::Flowcontrol::V1::Subject;
# ABSTRACT: Subject matches the originator of a request, as identified by the request authentication system. There are three ways of matching an originator; by user, group, or service account.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s group => 'Flowcontrol::V1::GroupSubject';


k8s kind => Str, 'required';


k8s serviceAccount => 'Flowcontrol::V1::ServiceAccountSubject';


k8s user => 'Flowcontrol::V1::UserSubject';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Flowcontrol::V1::Subject - Subject matches the originator of a request, as identified by the request authentication system. There are three ways of matching an originator; by user, group, or service account.

=head1 VERSION

version 1.008

=head2 group

`group` matches based on user group name.

=head2 kind

`kind` indicates which one of the other fields is non-empty. Required

=head2 serviceAccount

`serviceAccount` matches ServiceAccounts.

=head2 user

`user` matches based on username.

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
