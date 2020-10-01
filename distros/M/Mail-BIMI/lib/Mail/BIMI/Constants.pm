package Mail::BIMI::Constants;
# ABSTRACT: Setup system wide constants
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use strict;
use warnings;
use base 'Exporter';

use constant LOGOTYPE_OID => '1.3.6.1.5.5.7.1.12';
use constant USAGE_OID    => '1.3.6.1.5.5.7.3.31';

our @EXPORT = qw( LOGOTYPE_OID USAGE_OID );
our @EXPORT_OK = ( @EXPORT );
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Constants - Setup system wide constants

=head1 VERSION

version 2.20200930.1

=head1 REQUIRES

=over 4

=item * L<Exporter|Exporter>

=item * L<base|base>

=item * L<constant|constant>

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
