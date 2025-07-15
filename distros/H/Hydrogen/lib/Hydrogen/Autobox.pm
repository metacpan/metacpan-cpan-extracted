use 5.008001;
use strict;
use warnings;

use Hydrogen ();
use Hydrogen::ArrayRef ();
use Hydrogen::CodeRef ();
use Hydrogen::Counter ();
use Hydrogen::HashRef ();
use Hydrogen::Number ();
use Hydrogen::Scalar ();
use Hydrogen::String ();
use Hydrogen::Curry::ArrayRef ();
use Hydrogen::Curry::CodeRef ();
use Hydrogen::Curry::Counter ();
use Hydrogen::Curry::HashRef ();
use Hydrogen::Curry::Number ();
use Hydrogen::Curry::Scalar ();
use Hydrogen::Curry::String ();

use autobox ();
use Import::Into ();

package Hydrogen::Autobox;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021000';

sub import {
	my ( $class, $also ) = ( shift, @_ );
	my $caller = caller;
	
	'autobox'->import::into( $caller, {
		ARRAY      => [ 'Hydrogen::ArrayRef', 'Hydrogen::Curry::ArrayRef', @{ $also->{ARRAY}   or [] } ],
		CODE       => [ 'Hydrogen::CodeRef',  'Hydrogen::Curry::CodeRef',  @{ $also->{CODE}    or [] } ],
		INTEGER    => [ 'Hydrogen::Counter',  'Hydrogen::Curry::Counter',  @{ $also->{INTEGER} or [] } ],
		HASH       => [ 'Hydrogen::HashRef',  'Hydrogen::Curry::HashRef',  @{ $also->{HASH}    or [] } ],
		NUMBER     => [ 'Hydrogen::Number',   'Hydrogen::Curry::Number',   @{ $also->{NUMBER}  or [] } ],
		SCALAR     => [ 'Hydrogen::Scalar',   'Hydrogen::Curry::Scalar',   @{ $also->{SCALAR}  or [] } ],
		STRING     => [ 'Hydrogen::String',   'Hydrogen::Curry::String',   @{ $also->{STRING}  or [] } ],
	} );
}

1;

=head1 NAME

Hydrogen::Autobox - provides access to Hydrogen functions via L<autobox>.

=head1 SYNOPSIS

  use Hydrogen::Autobox;
  use feature 'say';
  
  my $number = 600;
  
  $number->add( 66 );
  
  if ( $number->eq(666) ) {
    say "It worked!"
  }

=head1 BUGS

Please report any bugs to
L<http://github.com/tobyink/p5-hydrogen/issues>.

=head1 SEE ALSO

L<Hydrogen>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
