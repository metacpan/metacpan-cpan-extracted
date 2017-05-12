package HTTP::Response::Switch::HandlerDeclinedResponse;
{
  $HTTP::Response::Switch::HandlerDeclinedResponse::VERSION = '1.1.1';
}
# ABSTRACT: unrecognised HTTP::Response exception class


use Moose;
use namespace::autoclean;

use Throwable 0.200001 (); # for correct prerequisites
with 'Throwable';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=for :stopwords Alex Peters unrecognised

=head1 NAME

HTTP::Response::Switch::HandlerDeclinedResponse - unrecognised HTTP::Response exception class

=head1 VERSION

This module is part of distribution HTTP-Response-Switch v1.1.1.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 SYNOPSIS

    use TryCatch;
    try {
        HTTP::Response::Switch::HandlerDeclinedResponse->throw;
    }
    catch (
        HTTP::Response::Switch::HandlerDeclinedResponse $e
    ) {
        warn "caught HandlerDeclinedResponse exception: $e";
    }

=head1 DESCRIPTION

Objects of classes consuming the L<HTTP::Response::Switch::Handler>
role throw this exception (via their
L<"decline"|HTTP::Response::Switch::Handler/decline> method) when they
determine that they cannot handle the type of L<HTTP::Response> object
passed to them in this instance.

This exception is internal to L<HTTP::Response::Switch> and will never
propagate past classes consuming that role.  They should only need to
be directly caught when verifying
L<"decline"|HTTP::Response::Switch::Handler/decline> behaviour in unit
tests for L<HTTP::Response::Switch::Handler> implementations.

=head1 AUTHOR

Alex Peters <lxp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alex Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
'LICENSE' file included with this distribution.

=cut
