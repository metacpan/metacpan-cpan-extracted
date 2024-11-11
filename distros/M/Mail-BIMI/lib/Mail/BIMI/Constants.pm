package Mail::BIMI::Constants;
# ABSTRACT: Setup system wide constants
our $VERSION = '3.20241111'; # VERSION
use 5.20.0;
use strict;
use warnings;
use parent 'Exporter';

use constant LOGOTYPE_OID          => '1.3.6.1.5.5.7.1.12';
use constant USAGE_OID             => '1.3.6.1.5.5.7.3.31';
use constant IS_EXPERIMENTAL_OID   => '1.3.6.1.4.1.53087.4.1';
use constant SUBJECT_MARK_TYPE_OID => '1.3.6.1.4.1.53087.1.13';

our @EXPORT = qw( LOGOTYPE_OID USAGE_OID IS_EXPERIMENTAL_OID SUBJECT_MARK_TYPE_OID );
our @EXPORT_OK = ( @EXPORT );
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Constants - Setup system wide constants

=head1 VERSION

version 3.20241111

=head1 REQUIRES

=over 4

=item * L<Exporter|Exporter>

=item * L<constant|constant>

=item * L<parent|parent>

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
