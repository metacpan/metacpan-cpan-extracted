package Eval::Compile;

use 5.008008;
use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Eval::Compile ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ceval cached_eval cache_this cache_eval cache_eval_undef) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
);

our $VERSION = '0.11';

require XSLoader;
XSLoader::load('Eval::Compile', $VERSION);
1;
__END__
=head1 NAME

Eval::Compile - Perl extension for compile eval 

=head1 SYNOPSIS

  use Eval::Compile qw(ceval cache_this cache_eval_undef);
  my $eval_string = '1+$a';

  for my $a  ( 1, 2, 3){
	  my $result = ceval( $eval_string ); # like eval only faster 
	  print $eval_string, " = ", $result, "\n";
  }
  # prints
#  1+$a = 2
#  1+$a = 3
#  1+$a = 4
	
  cache_eval_undef( ) ; # flush out current compiled eval cache

  # Simple results caching
  for my $b  ( 1,1,3,4){
	  my $r = cache_this( $b, sub { my $c = shift; heavy ops here ; return $heavy } ); # called only once for each $b
  }

  sub print_if_i_have_seen_this{
	  my $this = shift;
	  cache_this( $this, sub { print $this, "\n" }); #Stupid but efficient
  }

=head1 DESCRIPTION

Faster replacement for string evals. 
It takes evaled strings and compiles into specific perl sub with some data, and do it once for any given string
So next execution take a fraction of first eval to execute.

=THREAD SAFE

Not yet ready. This module is not threads safe

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<PadWalker>, L<perlapi>, L<perlfunc>

=head1 AUTHOR

A. G. Grishayev, E<lt>grian@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A. G. Grishayev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
