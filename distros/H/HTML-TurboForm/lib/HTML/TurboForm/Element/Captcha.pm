package HTML::TurboForm::Element::Captcha;
use warnings;
use strict;
use Crypt::Lite;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ session length keyname keyphrase/ );

sub render {
  my ($self, $options, $view)=@_;
  if ($view) { $self->{view}=$view; }
  my $request=$self->request;
  my $result='';
  my $disabled='';
  my $class='form_text';
  $class = $self->class if ($self->class);
  $self->length(4) if (!$self->length);
  my $name=' name="'.$self->name.'_input" ';
  my $value='';

  $value=' value="'.$request->{ $self->name }.'" ' if ($request->{ $self->name });

  if ($options->{frozen} == 1) {
    my $text= $value;
    $disabled=' disabled ';
    $result='<input type="hidden" '.$name.$value.'" />';
  }

  my @numbers = (0,1,2,3,4,5,6,7,8,9);
  my $random = '';
  for (my $i=0; $i < $self->length;$i++){
    my $x = int(rand(scalar(@numbers)));
    $random .= $x;
  }
  my $k='_captcha';
  $k=$self->keyname if ($self->keyname);  
  
  $result=$self->print_number($random);
  my $crypt = Crypt::Lite->new( debug => 0, encoding => 'hex8' );
  
  if ($self->keyphrase){      
	  $random=$crypt->encrypt($random,$self->keyphrase);      
  }
  
  my $tstamp=time();
  $tstamp=$crypt->encrypt($tstamp,$self->keyphrase);
  
  if ($self->session && $self->name){
    $self->session->{ $self->name.$k}=$random;
    $self->session->{ $self->name.$k.'2'}=$tstamp;
  }
  
  $self->{value}=$random;
 # $result .='<input class="form_std" type="'.$self->type.'"'.$disabled.$name.$class.$value.'>' ;
  return $self->vor($options).$result.$self->nach;
}

sub get_value{
  my ($self)=@_;
  my $k='_captcha';
  $k=$self->keyname if ($self->keyname);
  my $val=$self->session->{ $self->name.$k };
  
  if ($self->keyphrase){
      my $crypt = Crypt::Lite->new( debug => 0, encoding => 'hex8' );
	  $val=$crypt->decrypt($val,$self->keyphrase);
  }  
  return  $val;
}

sub get_digit_matrix{
  my ($self, $number)=@_;

  my @bitmasks = (31599, 18742, 29607, 31143, 18921, 31183, 31695, 18855, 31727, 31215);
  my @bits = (1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384);

  my @matrix=(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

  my $mask = $bitmasks[$number];

  for (my $i=14;$i>0;$i--){
    if (($mask / $bits[$i])>1) {
      $mask = $mask - $bits[$i];
      $matrix[$i]=1;
    }
  }
  if ($mask == 1) { $matrix[0]=1; }

  return @matrix ;
}

sub print_matrix{
  my ($self, @matrix)=@_;

  my $output ='';
  my $size = @matrix;
  for (my $i=0;$i<5;$i++) {
    for (my $k=0;$k < $size ;$k++){
      for (my $j=0;$j<3;$j++) {
        if ( $matrix[$k][($j+(3*$i))] == 1 ){
          $output.='<span class="b">&nbsp;&nbsp;</span>';
        } else {
          $output.='<span class="w">&nbsp;&nbsp;</span>';
        }
      }
      $output.='<span class="w">&nbsp;&nbsp;</span>';
    }
    $output.='<br />';
  }

  return $output;
}

sub print_number{
  my ($self, $number)=@_;

  my @matrix;

  for(my $i=0; $i<length($number); $i++) {
     my $digit = substr($number, $i, 1);
     $matrix[$i]= [ $self->get_digit_matrix($digit) ];
  }

  return $self->print_matrix(@matrix);
}

1;

__END__

=head1 HTML::TurboForm::Element::Captcha

Representation class for Captcha element.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 render

Arguments: $options

returns HTML Code for element.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut

