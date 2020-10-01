package Mail::BIMI::Prelude;
# ABSTRACT: Setup system wide prelude
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use strict;
use warnings;
require feature;


use open ':std', ':encoding(UTF-8)';
use Import::Into;
use Mail::BIMI::Constants;
use Carp;
use JSON;

sub import {
  strict->import;
  warnings->import;
  feature->import($_) for ( qw{ postderef signatures } );
  warnings->unimport($_) for ( qw{ experimental::postderef experimental::signatures } );
  Mail::BIMI::Constants->import::into(scalar caller);
  Carp->import::into(scalar caller);
  JSON->import::into(scalar caller);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Prelude - Setup system wide prelude

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Distribution wide pragmas and imports

=head1 REQUIRES

=over 4

=item * L<Carp|Carp>

=item * L<Import::Into|Import::Into>

=item * L<JSON|JSON>

=item * L<Mail::BIMI::Constants|Mail::BIMI::Constants>

=item * L<feature|feature>

=item * L<feature|feature>

=item * L<open|open>

=item * L<strict|strict>

=item * L<warnings|warnings>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
