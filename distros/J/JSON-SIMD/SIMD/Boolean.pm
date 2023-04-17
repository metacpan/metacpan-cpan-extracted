=head1 NAME

JSON::SIMD::Boolean - dummy module providing JSON::SIMD::Boolean

=head1 SYNOPSIS

 # do not "use" yourself

=head1 DESCRIPTION

This module exists only to provide overload resolution for Storable and
similar modules. It's only needed for compatibility with data serialised
(by other modules such as Storable) that was decoded by JSON::XS versions
before 3.0.

Since 3.0, JSON::PP::Boolean has replaced it. Support for
JSON::SIMD::Boolean will be removed in a future release.

=cut

use JSON::SIMD ();

1;

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

