package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::StatusCause;
# ABSTRACT: StatusCause provides more information about an api.Status failure, including cases when multiple errors are encountered.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s field => Str;


k8s message => Str;


k8s reason => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::StatusCause - StatusCause provides more information about an api.Status failure, including cases when multiple errors are encountered.

=head1 VERSION

version 1.100

=head2 field

The field of the resource that has caused this error, as named by its JSON serialization. May include dot and postfix notation for nested attributes. Arrays are zero-indexed.  Fields may appear more than once in an array of causes due to fields having multiple errors. Optional. Examples: "name" - the field "name" on the current resource; "items[0].name" - the field "name" on the first array entry in "items"

=head2 message

A human-readable description of the cause of the error.  This field may be presented as-is to a reader.

=head2 reason

A machine-readable description of the cause of the error. If this value is empty there is no information available.

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
