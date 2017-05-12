package JSON::YAJL;
use strict;
use warnings;
use JSON::YAJL::Generator;
use JSON::YAJL::Parser;
our $VERSION = '0.10';

1;

=head1 NAME

JSON::YAJL - An interface to the YAJL JSON parsing and generation library

=head1 SYNOPSIS

  use JSON::YAJL;
  # see JSON::YAJL::Generator or JSON::YAJL::Parser

=head1 DESCRIPTION

YAJL is Yet Another JSON Library. YAJL is a small event-driven (SAX-style) JSON
parser written in ANSI C, and a small validating JSON generator, by Lloyd
Hilaiel. This module is a Perl interface to that library.

To find out more about YAJL, please visit http://lloyd.github.com/yajl/

For the generation library, see L<JSON::YAJL::Generator> and for the
parsing library, see L<JSON::YAJL::Parser>.

This is a very early release to see how cross-platform the underlying code is.
The API may change in future.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<JSON::YAJL::Generator>, L<JSON::YAJL::Parser>
