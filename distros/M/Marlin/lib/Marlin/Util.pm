use 5.008008;
use strict;
use warnings;

package Marlin::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006000';

use parent 'Exporter::Tiny';

our ( %EXPORT_TAGS, @EXPORT_OK );

use constant do {
	my %attr = map {; $_ => $_ } qw( bare lazy ro rw rwp );
	$EXPORT_TAGS{attr} = [ keys %attr ];
	push @EXPORT_OK, keys %attr;
	
	my %bool = ( true => !!1, false => !!0 );
	$EXPORT_TAGS{bool} = [ keys %bool ];
	push @EXPORT_OK, keys %bool;
	
	+{ %attr, %bool };
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::Util - exports a few keywords it's nice to have with Marlin

=head1 SYNOPSIS

  use v5.20.0;
  no warnings "experimental::signatures";
  
  package Person {
    use Types::Common -lexical, -all;
    use Marlin::Util -lexical, -all;
    use Marlin
      'name'  => { is => ro, isa => Str, required => true },
      'age'   => { is => rw, isa => Int, predicate => true },
      -strict;
    
    signature_for introduction => (
      method   => true,
      named    => [ audience => Optional[InstanceOf['Person']] ],
    );
    
    sub introduction ( $self, $arg ) {
      say "Hi " . $arg->audience . "!" if $arg->has_audience;
      say "My name is " . $self->name . ".";
    }
  }

=head1 DESCRIPTION

There are a few common values that often appear when defining attributes
in Marlin (and Moo and Moose)! This module exports constants for them so
they can be used as barewords.

If you add the C<< -lexical >> export tag, everything will be exported as
lexical keywords.

=head2 String constants for C<is>

Export these with C<< use Marlin::Util -attr >> or C<< use Marlin::Util -all >>.

=over

=item C<ro>

=item C<rw>

=item C<rwp>

=item C<lazy>

=item C<bare>

=back

=head2 Boolean constants

Export these with C<< use Marlin::Util -bool >> or C<< use Marlin::Util -all >>.

=over

=item C<true>

=item C<false>

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

This module uses L<Exporter::Tiny>.

L<Marlin>, L<Moose>, L<Moo>.

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
