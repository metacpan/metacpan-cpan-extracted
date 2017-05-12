package Digest::Elf;

use 5.006;
use strict;
use warnings;
use vars qw( $VERSION );

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Digest::Elf ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	elf
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

$VERSION = sprintf( "%s", q{$Id: Elf.pm,v 1.42 2016/03/05 04:18:47 steve Exp $} =~ /(\d+\.\d+)/ );

bootstrap Digest::Elf $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Digest::Elf - Perl extension for generating ElfHash values.

=head1 SYNOPSIS

  use Digest::Elf;
  print Digest::Elf::elf( "foo" );

=head1 DESCRIPTION

Digest::Elf is an implementation of the ElfHash algorithm.

=head1 FUNCTIONS

=over

=item elf( VALUE )

Create a hash value based on the input value.

=back

=head1 AUTHOR

Steve McKay, E<lt>steve@colgreen.comE<gt>

=head1 SEE ALSO

=over

=item Digest::MD5

=back

=cut

