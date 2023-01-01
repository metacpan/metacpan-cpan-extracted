package HTTP::Throwable::Role::Status::RequestedRangeNotSatisfiable 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Types::Standard qw(Str);

use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 416 }
sub default_reason      { 'Requested Range Not Satisfiable' }

has 'content_range' => ( is => 'ro', isa => Str );

around 'build_headers' => sub {
    my $next    = shift;
    my $self    = shift;
    my $headers = $self->$next( @_ );
    if ( my $content_range = $self->content_range ) {
        push @$headers => ('Content-Range' => $content_range);
    }
    $headers;
};

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::RequestedRangeNotSatisfiable - 416 Requested Range Not Satisfiable

=head1 VERSION

version 0.028

=head1 DESCRIPTION

A server SHOULD return a response with this status code if a
request included a Range request-header field, and none of the
range-specifier values in this field overlap the current extent
of the selected resource, and the request did not include an
If-Range request-header field. (For byte-ranges, this means that
the first-byte-pos of all of the byte-range-spec values were greater
than the current length of the selected resource.)

When this status code is returned for a byte-range request, the
response SHOULD include a Content-Range entity-header field specifying
the current length of the selected resource. This response MUST NOT
use the multipart/byteranges content-type.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <cpan@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 416 Requested Range Not Satisfiable

#pod =head1 DESCRIPTION
#pod
#pod A server SHOULD return a response with this status code if a
#pod request included a Range request-header field, and none of the
#pod range-specifier values in this field overlap the current extent
#pod of the selected resource, and the request did not include an
#pod If-Range request-header field. (For byte-ranges, this means that
#pod the first-byte-pos of all of the byte-range-spec values were greater
#pod than the current length of the selected resource.)
#pod
#pod When this status code is returned for a byte-range request, the
#pod response SHOULD include a Content-Range entity-header field specifying
#pod the current length of the selected resource. This response MUST NOT
#pod use the multipart/byteranges content-type.
#pod
