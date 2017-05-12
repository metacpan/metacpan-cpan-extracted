package HTML::TurboForm::Element::Radio;
use warnings;
use strict;
use Tie::IxHash;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ class special listmode pre post position labelclass/);

sub render{
    my ($self, $options, $view)=@_;
    if ($view) { $self->{view}=$view; }
    my $request=$self->request;
    my $result='';
    my $disabled='';
    my $class='form_radio';

    if ($self->label) {
       $self->label('&nbsp;') if ($self->label eq '');
	} else {
		$self->label('&nbsp;');
	}
	
    $class=$self->{class}  if exists($self->{class});
    $class=' class="'.$class.'" ';
    my $aha=$self->options;
    my $name=' name="'.$self->name.'" ';
    my $checked='';
    if ($options->{frozen}){ $disabled=' disabled ' if ($options->{frozen} == 1) ; }

    my $pre='';
    my $post='';
    my $after='';

   if ( $self->listmode ){
        $result.='<ul>';
        $pre='<li>';
        $post='</li>';
        $after='</ul>';
    }

   $pre.=$self->pre if ($self->pre);
   $post.=$self->post if ($self->post);

   my $norm_hash=1;
   if ($self->options){
       foreach (%{$self->options}){
           $norm_hash=2 if (ref($_) eq 'HASH');
       }
   
    if ($norm_hash==2){
       for my $k2 ( sort{ $a <=> $b} keys %{$self->options} ) {
            while ( my( $key,$value) = each %{$self->options->{$k2}}){
         my $values = $request->{ $self->name };
         if (! $values){
            $values = $self->default;
         }

         $values = [ $values ] unless ref( $values ) =~ /ARRAY/;
         $checked='';
         if ([ $values ]) { $checked=' checked="true" ' if ( grep { $_ eq $value } @{ $values } ); }
         my $special='';
         #$special='<input type="text" '.$name.'>' if ($self->special==$k2);
         $result.=$pre.'<input type="radio" '.$class.$checked.$disabled.$name.' value="'.$value.'">'.$key.$special.$post;
         $result.='<input type="hidden" '.$name.' value="'.$value.'">' if (($disabled ne '')&& ( $checked ne ''));
     }

       }
    } else {    
        while ( my( $key,$value) = each %{$self->options}){
    #        if (ref($value) eq 'HASH'){ print "wkfndfkhvbkh";}       
            my $values = $request->{ $self->name };
            if (! $values){
               $values = $self->default;
            }
    
            $values = [ $values ] unless ref( $values ) =~ /ARRAY/;
            $checked='';
            if ([ $values ]) { $checked=' checked ' if ( grep { $_ eq $value } @{ $values } ); }
            $result.=$pre.'<input type="radio" '.$class.$checked.$disabled.$name.' value="'.$value.'">'.$key.$post;        
            $result.='<input type="hidden" '.$name.' value="'.$value.'">' if (($disabled ne '')&& ( $checked ne ''));        
        }
    }
    
   }
    if ($self->optionsnum){	    
	    foreach (@{$self->optionsnum}){
            while( my ($key, $value) = each %$_ ) {
                      my $values = $request->{ $self->name };
            if (! $values){
               $values = $self->default;
            }
            if($self->labelclass){
                $key='<div class="'.$self->labelclass.'">'.$key.'</div>';
            }
            
            my $keyr=$key;            
            my $keyl='';
            if ($self->position){
                if ($self->position eq 'left') {                    
                    $keyl=$key;
                    $keyr='';
                }
            }   
    
            $values = [ $values ] unless ref( $values ) =~ /ARRAY/;
            $checked='';
            
            if ([ $values ]) { $checked=' checked ' if ( grep { $_ eq $value if ($_) } @{ $values } ); }
            
            $result.=$pre.$keyl.'<input type="radio" '.$class.$checked.$disabled.$name.' value="'.$value.'">'.$keyr.$post;        
            $result.='<input type="hidden" '.$name.' value="'.$value.'">' if (($disabled ne '')&& ( $checked ne ''));   
            }
        }
    }

   $result.=$after;
   $result= $self->vor($options).$result.$self->nach if ($self->check_param('norow')==0);
  return $result;
}

1;


__END__

=head1 HTML::TurboForm::Element::Radio

Representation class for HTML Radiobox element.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 render

Arguments: $options

returns HTML Code for Radiobox.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut
