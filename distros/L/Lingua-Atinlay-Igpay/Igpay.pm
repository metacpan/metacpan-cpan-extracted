package Lingua::Atinlay::Igpay;

use strict;

require Exporter;

use vars qw[@ISA %EXPORT_TAGS @EXPORT_OK $VERSION];
@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw[ enhay2igpayatinlay ] ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

$VERSION = '0.03';

sub enhay2igpayatinlay {
  my @list     = @_;
  my @new_list = ();
  while ( defined( $_ = shift @list ) ) {
    my @tokens = split /\b/, $_;
    foreach ( 0 .. $#tokens ) {
      my $tok     = $tokens[$_];
      my $alluc   = ( $tok eq uc $tok              ? 1 : 0 );
      my $firstuc = ( $tok =~ /^[A-Z]/ && ! $alluc ? 1 : 0 );
      if (    $tok =~ s/^([aeiou].*)/${1}hay/gsi
           || $tok =~ s/^([b-d,f-h,j-n,p-t,v-z]{2,})(.+)/${2}${1}ay/gsi
           || $tok =~ s/^([b-d,f-h,j-n,p-t,v-z])(.+)/${2}${1}ay/gsi ) {
                $tok = uc $tok if $alluc;
                if ( $firstuc ) {
                  $tok =  ucfirst $tok;
                  $tok =~ s/((?:.h|.)ay)$/lc $1/e;
                }
      }
      $tokens[$_] = $tok;
    }
    push @new_list, join '', @tokens;
  }
  return @new_list;
}

1;
__END__

=head1 AMENAY

Ingualay::Atinlayhay::Igpayhay - Erlpay Odulemay otay Onvertcay Englishhay otay Igpay Atinlay

=head1 OPSISSYNAY

  usehay Ingualay::Atinlayhay::Igpayhay wqay[:allhay]; # ortershay anthay enhay2igpayatinlayhay()

=head1 ESCRIPTIONDAY

=head2 enhay2igpayatinlayhay( ISTLAY )

Onvertcay Englishhay otay Igpay Atinlay

=head1 AUTHORHAY

Aseycay Estway <F<aseycay@eeknestgay.omcay>>

=head1 OPYRIGHTCAY

Opyrightcay (c) 2002 Aseycay R. Estway <aseycay@eeknestgay.omcay>.  Allhay
ightsray eservedray.  Isthay ogrampray ishay eefray oftwaresay; ouyay ancay
edistributeray ithay andhay/orhay odifymay ithay underhay ethay amesay ermstay ashay
Erlpay itselfhay.

=head1 EESAY ALSOHAY

erlpay(1).

=cut
