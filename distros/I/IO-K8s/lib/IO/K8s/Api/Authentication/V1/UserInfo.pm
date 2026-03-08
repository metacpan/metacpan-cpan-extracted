package IO::K8s::Api::Authentication::V1::UserInfo;
# ABSTRACT: UserInfo holds the information about the user needed to implement the user.Info interface.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s extra => { Str => 1 };


k8s groups => [Str];


k8s uid => Str;


k8s username => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Authentication::V1::UserInfo - UserInfo holds the information about the user needed to implement the user.Info interface.

=head1 VERSION

version 1.006

=head2 extra

Any additional information provided by the authenticator.

=head2 groups

The names of groups this user is a part of.

=head2 uid

A unique value that identifies this user across time. If this user is deleted and another user by the same name is added, they will have different UIDs.

=head2 username

The name that uniquely identifies this user among all active users.

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
