package Kubernetes::REST::HTTPResponse;
our $VERSION = '1.100';
# ABSTRACT: HTTP response object
use Moo;
use Types::Standard qw/Str Int/;


has content => (is => 'ro', isa => Str);


has status => (is => 'ro', isa => Int);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::HTTPResponse - HTTP response object

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    use Kubernetes::REST::HTTPResponse;

    my $res = Kubernetes::REST::HTTPResponse->new(
        status => 200,
        content => '{"items":[]}',
    );

=head1 DESCRIPTION

Internal HTTP response object used by L<Kubernetes::REST>.

=head2 content

The response body content.

=head2 status

The HTTP status code (e.g., 200, 404, 500).

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST::HTTPRequest> - Request object

=item * L<Kubernetes::REST::Role::IO> - IO interface

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org> (JLMARTIN, original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
