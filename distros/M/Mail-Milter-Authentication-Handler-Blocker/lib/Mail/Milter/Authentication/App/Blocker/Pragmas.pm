package Mail::Milter::Authentication::App::Blocker::Pragmas;
# ABSTRACT: Setup system wide pragmas
our $VERSION = '2.20191120'; # VERSION
use 5.20.0;
use strict;
use warnings;
require feature;

use open ':std', ':encoding(UTF-8)';

sub import {
  strict->import();
  warnings->import();
  feature->import($_) for ( qw{ postderef signatures } );
  warnings->unimport($_) for ( qw{ experimental::postderef experimental::signatures } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::Milter::Authentication::App::Blocker::Pragmas - Setup system wide pragmas

=head1 VERSION

version 2.20191120

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
