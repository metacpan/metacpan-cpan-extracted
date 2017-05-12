package HTML::TurboForm::Element::Safety;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ class special listmode pre post position labelclass/);


sub init{
    my ($self)=@_;

    my @prefixes=('form_','e_','formmail_','mailer_','m_','fm_','f_','i_','input_','email_');
    my @names_o=('realname','firstname','surname','state','workphone','zipcode','country','website','address','workaddress','homeaddress');
    my @names_e=('name','cell','workcell','work','home','province','postalcode','city','shippingcity','shipping','comments','lastname','county');      
    my @possible_values=('6049297969','1283 West Cordova Street','Canada','Quam','Viet Naam','Bruce Lee','Earl','brandon','lee','ninja','hanzo','7788342901','934 north cordova road','xiuIUvuicv998');

    $self->{prefixes}=[@prefixes];    
    $self->{names_o}=[@names_o];
    $self->{names_e}=[@names_e];
    $self->{p_v}=[@possible_values];
    my $n_e;
    my $n_o;
    my $c_pre_e;
    my $c_pre_o;
    while ( my ($k, $v) = each($self->{request}) ) {
        foreach(@prefixes){
            my $current_prefix=$_;
            if ($k=~/^$_/g){
                $k=~s/$_//g;                
                foreach(@names_e){
                    if ($_ eq $k){                        
                        $n_e=$_;
                        $c_pre_e=$current_prefix;
                    }                    
                }
                foreach(@names_o){                    
                    if ($_ eq $k){
                        $n_o=$_;
                        $c_pre_o=$current_prefix;
                    }
                }
            }            
        }       
    }
    
    my $tmp=0;    
    if ($n_e){    
        my $val=$self->{request}->{$c_pre_e.$n_e};
        foreach(@possible_values){ $tmp=1 if ($_ eq $val); }        
    }
    $self->{value}='spam';
    $self->{value}='1' if ($n_o && !$self->{request}->{$c_pre_o.$n_o} && $tmp==1);
}

sub get_value{
    my ($self) = @_;
    return $self->{value};
}

sub render{
    my ($self, $options, $view)=@_;
    if ($view) { $self->{view}=$view; }
    my $request=$self->request;
        
   my $result='';   
   my $name_o= $self->{names_o}[rand(scalar(@{ $self->{names_o}}))];
   my $name_e= $self->{names_e}[rand(scalar(@{ $self->{names_e}}))];
   my $pre1= $self->{prefixes}[rand(scalar(@{ $self->{prefixes}}))];
   my $pre2= $self->{prefixes}[rand(scalar(@{ $self->{prefixes}}))];   
   
   my $rval= $self->{p_v}[rand(scalar(@{ $self->{p_v}}))];      
   $result.='<div class="invisible">';
   $result.='<input type="text" name="'.$pre1.$name_o.'">';
   $result.='<input type="text" name="'.$pre2.$name_e.'">';
   $result.='</div>';   
   $result.='<script>$("[name='.$pre2.$name_e.']").attr("value","'.$rval.'");</script>';      
  return $result;
}

1;

__END__

=head1 HTML::TurboForm::Element::Safety

Representation class for HTML Safety element.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 render

Arguments: $options

returns HTML Code for Safety.

=head1 AUTHOR

Thorsten Drobnik, thorsten@base-10.net

=cut
