##############################################################################
#
#  Copyright (c) 2000 Jan 'Kozo' Vajda <Jan.Vajda@pobox.sk>
#  All rights reserved.
#
##############################################################################

package Finance::Bank::Sporo;
require Exporter;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use URI::Escape;

### my initial version was 0.11
$VERSION = '0.16';

@ISA = qw(Exporter);

# Items to export into callers namespace by default
@EXPORT =	qw();

# Other items we are prepared to export if requested
@EXPORT_OK =	qw();


=head1 NAME

  Finance::Bank::Sporo - Perl extension for B<SporoPay> of Slovenska Sporitelna.

=head1 VERSION

  0.16

=head1 SYNOPSIS

  use Finance::Bank::Sporo;

  $sporo_obj = Bank::Sporo->new($prenumber,$number);

  $sporo_obj->configure(
	      amt	=> $amt,
	      vs	=> $vs,
	      ss	=> $ss,
	      rurl	=> $rurl,
	      param	=> $param,
  );


  print $sporo_obj->pay_form();

=head1 DESCRIPTION

  Module for generating pay forms and links for B<SporoPay> of Slovenska
  Sporitelna (http://www.slsp.sk/).

=head1 USE

=head2 Functions ( or Methods ? )

=item new

	$sporo_obj  = Finance::Bank::Sporo->new($prenumber,$number);

This creates a new Finance::Bank::Sporo object using $prenumber as a "Predcisle uctu"
and $number as a "Cislo uctu"

=cut


sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	croak "Usage $class->new (PRENUMBER, NUMBER)" if ( @_ != 2 ) ;
	my $self = {};
	bless $self, $class;

	$self->{'prenumber'} = shift;
	$self->{'prenumber'} = sprintf("%06.0d",$self->{'prenumber'});
	$self->{'number'} = shift;
	$self->{'number'} = sprintf("%010.0d",$self->{'number'});

	croak "Number must be 10 numbers" if ( length($self->{'number'}) != 10 );
	croak "PreNumber must be 6 numbers" if ( length($self->{'prenumber'}) != 6 );
	
	$self->_init;

	return($self);
}

sub _init {
  my $self = shift;

  ### default values
  $self->{'action_url'} = "https://ib.slsp.sk/epayment/epayment/epayment.xml";
  $self->{'image_src'} = '/PICS/sporopay_logo.gif';
  $self->{'currency'} = 'SKK';
  $self->{'kbanky'} = '0900';
  $self->{'ss'} = '';
  return($self);
}


=item configure

	$sporo_obj->configure(
	      amt	=> $amt,
	      vs	=> $vs,
	      ss	=> $ss,
	      rurl	=> $rurl,
	      param	=> $param,
              image_src => '/PICS/sporopay_logo.gif',
        );


Set correct values to object.
Possible parameters is:
       amt => Amount
        vs => Variable Symbol
        ss => Specific Symbol
      rurl => Redirect URL
 image_src => Path to image ( relative to DocumentRoot )
     param => any parameter
         
Possible but default correct parameter is:

  action_url => SporoPayPay action URL
  default:
    https://ib.slsp.sk/epayment/epayment/epayment.xml

  image_src => Path to image ( relative to DocumentRoot )
  default:
    /PICS/sporopay_logo.gif

    

=cut

sub configure {
	my $self = shift;
	my (%arg) = @_;

	### normalization
	foreach (keys %arg) {
		### konvert name to lowercase
		$self->{"\L$_"} = $arg{$_};
	}
	return($self);
}

=item pay_form

  print $sporo_obj->pay_form();

  Return HTML FORM.

=cut

sub pay_form {
  my $self =shift;

  my $action = $self->{action_url};


my $sporo_form = <<EOM;
<!-- SporoPay form start -->
<form action="$action" method=POST>
<input type=hidden name=pu_predcislo value="$self->{prenumber}">
<input type=hidden name=pu_cislo value="$self->{number}">
<input type=hidden name=pu_kbanky value="$self->{kbanky}">
<input type=hidden name=suma value="$self->{amt}">
<input type=hidden name=mena value="$self->{currency}">
<input type=hidden name=vs value="$self->{vs}">
<input type=hidden name=ss value="$self->{ss}">
<input type=hidden name=url value="$self->{rurl}">
<input type=hidden name=param value="$self->{param}">
<input type=image src="$self->{image_src}" border=0>
</form>
<!-- SporoPay form end -->
EOM

  return($sporo_form);
}

=item generic_pay_form

  print $sporo_obj->generic_pay_form($type);

  Return HTML FORM for payment with submit button.

=cut

sub generic_pay_form {
  my $self =shift;

  my $action = $self->{action_url};


my $sporo_form = <<EOM;
<!-- SporoPay form start -->
<form action="$action" method=POST>
<input type=hidden name=pu_predcislo value="$self->{prenumber}">
<input type=hidden name=pu_cislo value="$self->{number}">
<input type=hidden name=pu_kbanky value="$self->{kbanky}">
<input type=hidden name=suma value="$self->{amt}">
<input type=hidden name=mena value="$self->{currency}">
<input type=hidden name=vs value="$self->{vs}">
<input type=hidden name=ss value="$self->{ss}">
<input type=hidden name=url value="$self->{rurl}">
<input type=hidden name=param value="$self->{param}">
<input type=submit value="Suhlasim">
</form>
<!-- SporoPay form end -->
EOM

  return($sporo_form);
}



=item pay_link

  print $sporo_obj->pay_link();

  Return URL for payment.

=cut

sub pay_link {
  my $self =shift;

  my $action = $self->{action_url};

my $sporo_form = <<EOM;
$action ?
pu_predcislo=$self->{prenumber} & 
pu_cislo=$self->{number} & 
pu_kbanky=$self->{kbanky} &
suma=$self->{amt} & 
mena=$self->{currency} & 
vs=$self->{vs} & 
ss=$self->{ss} & 
url=$self->{rurl} & 
EOM

if ( $self->{param} ) {
my $param = uri_escape($self->{param},"^A-Za-z0-9");
$sporo_form .= <<EOM;
param=$param
EOM
}
$sporo_form =~ s/\n//og;
$sporo_form =~ s/\s+//og;

  return($sporo_form);
}


sub AUTOLOAD {
  my $self = shift;
  my $value = shift;
  my ($name) = $AUTOLOAD;

  ($name) = ( $name =~ /^.*::(.*)/);

  $self->{$name} = $value if ( defined $value );

  return($self->{$name});
 
}

sub DESTROY {
  ### bye bye 
}

1;

__END__

=head1 EXAMPLES

  Look at B<SYNOPSIS>, t/*, examples/* and use the source.
  ( lookin for a volunteer for writing documentation and man pages)

=head1 AUTHOR INFORMATION

  Copyright 2000 Jan ' Kozo ' Vajda, Jan.Vajda@alert.sk. All rights
reserved.  It may be used and modified freely, but I do request that this
copyright notice remain attached to the file.  You may modify this module as
you wish, but if you redistribute a modified version, please attach a note
listing the modifications you have made.

Address bug reports and comments to:
Jan.Vajda@alert.sk

=head1 CREDITS

Thanks very much to:

=over 4

=item my wife Erika & kozliatko

for patience and love

=back

=head1 SEE ALSO

  perl(1),Finance::Bank::TB(1).

=cut
