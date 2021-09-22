package Mail::AuthenticationResults;
# ABSTRACT: Object Oriented Authentication-Results Headers

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Carp;

use Mail::AuthenticationResults::Parser;


sub new {
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}


sub parser {
    my ( $self, $auth_headers ) = @_;
    return Mail::AuthenticationResults::Parser->new( $auth_headers );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults - Object Oriented Authentication-Results Headers

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

Object Oriented Authentication-Results email headers.

This parser copes with most styles of Authentication-Results header seen in the wild, but is not yet fully RFC7601 compliant

Differences from RFC7601

key/value pairs are parsed when present in the authserv-id section, this is against RFC but has been seen in headers added by Yahoo!.

Comments added between key/value pairs will be added after them in the data structures and when stringified.

=head1 METHODS

=head2 new()

Return a new Mail::AuthenticationResults object

=head2 parser()

Returns a new Mail::AuthenticationResults::Parser object
for the supplied $auth_results header

=head1 BUGS

Please report bugs via the github tracker.

https://github.com/marcbradshaw/Mail-AuthenticationResults/issues

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
