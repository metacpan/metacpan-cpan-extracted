package Language::XSB::Register;

our $VERSION = '0.01';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(@XsbReg
		 $XsbCmd
		 $XsbQuery
		 $XsbVars
		 $XsbSub
		 $XsbArgs
		 $XsbResult
		 $XsbException);

our @XsbReg;
tie @XsbReg, 'Language::XSB::RegArray';

our ($XsbCmd, $XsbQuery, $XsbVars,
     $XsbSub, $XsbArgs,
     $XsbResult, $XsbException);
tie $XsbCmd, 'Language::XSB::Reg', 0;
tie $XsbQuery, 'Language::XSB::Reg', 1;
tie $XsbVars, 'Language::XSB::Reg', 2;
tie $XsbSub, 'Language::XSB::Reg', 3;
tie $XsbArgs, 'Language::XSB::Reg', 4;
tie $XsbResult, 'Language::XSB::Reg', 5;
tie $XsbException, 'Language::XSB::Reg', 6;

package Language::XSB::Reg;
use Tie::Scalar;
use Carp;
use Language::XSB::Base;
use Language::XSB qw(xsb_nreg);


our @ISA=qw(Tie::Scalar);

sub TIESCALAR {
  my ($class, $index)=@_;
  my $self=\$index;
  bless $self, $class;
  return $self;
}

sub FETCH { getreg($ {$_[0]}) }

sub STORE { setreg($ {$_[0]}, $_[1]) }

sub type { regtype($ {$_[0]}) }

package Language::XSB::RegArray;
use Tie::Array;
use Carp;
use Language::XSB::Base;
use Language::XSB qw(xsb_nreg);

our @ISA=qw(Tie::Array);

sub TIEARRAY {
  my $class=shift;
  my $self=\$class;
  bless $self, $class;
  return $self;
}

sub FETCH { getreg($_[1]) }

sub STORE { setreg($_[1], $_[2]) }

sub FETCHSIZE { return xsb_nreg }

sub STORESIZE { croak "\@XsbReg can not be resized" }

sub EXTEND {}

sub EXISTS { $_[1]>0 and $_[1]<xsb_nreg }

sub DELETE { croak "elements can not be deleted from \@XsbReg" }


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Language::XSB::Register - Direct access to XSB SLG-WAM registers.

=head1 SYNOPSIS

  use Language::XSB::Register;

  print "@XsbReg\n";

=head1 ABSTRACT

This package allows direct access to the SLG-WAM registers from Perl.

=head1 DESCRIPTION

This package is only for development of Language::XSB

=head2 EXPORT

=over 4

=item C<@XsbReg>

alias for XSB SLG-WAN registers

=item C<$XsbCmd>

alias for register 1

=item C<$XsbQuery>

alias for register 2

=item C<$XsbVars>

alias for register 3

=item C<$XsbSub>

alias for register 4

=item C<$XsbArgs>

alias for register 5

=item C<$XsbResult>

alias for register 6

=item C<$XsbException>

alias for register 7

=back



=head1 SEE ALSO

L<Language::XSB::Base>

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
