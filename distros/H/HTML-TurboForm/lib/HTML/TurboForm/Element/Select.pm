package HTML::TurboForm::Element::Select;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ default first optionstext/ );

sub render{
    my ($self, $options, $view)=@_;
    if ($view) { $self->{view}=$view; }
    my $request=$self->request;
    my $result='';
    my $disabled='';
    my $class='form_select';
    $self->label('&nbsp;') if (!$self->label);
    $class=$self->{class}  if exists($self->{class});
    my $name=' name="'.$self->name.'" ';
    my $id=' id="'.$self->name.'" ';
    my $checked='';

    $self->{submitted} = 1 if ($request->{ $self->name });
    if ($self->{submitted} == 0){
    	$request->{ $self->name } = $self->default if($self->default);
    }
    if ($options->{frozen}){
        $disabled=' disabled ' if ($options->{frozen} == 1);
    }

    if ($self->dbdata and $self->dbid and $self->dblabel){
       my @t = @{ $self->dbdata };
       foreach (@t){
            my $label_method = $self->dblabel;
            my $value_method = $self->dbid;
            my $l=$_->$label_method;
            my $v=$_->$value_method;
            $self->options->{$l}=$v;
       }
    }

    $result.='<select class="'.$class.'" '.$self->get_attr().$disabled.$id.$name.'>';
    my $result2='';
    if (($self->options)or ($self->optionsnum)or ($self->optionstext)){
        my $optiontags ='';
	    my $first = '';
	
	if ($self->optionstext){
		my $values = $request->{ $self->name };		
		$values = [ $values ] unless ref( $values ) =~ /ARRAY/;
		
		$checked='';		
		$optiontags=$self->optionstext;
		my $tmptext=$optiontags;
		foreach (@{$values}){ $optiontags=~s/value=\"$_\"/value=\"$_\" selected /g if ($_); }		
		#$result2.='<input type="hidden" '.$id.$name.' value="'.$value.'">' if (($disabled ne '')&& ( $checked ne ''));
	}
	    
	if ($self->optionsnum){	    
	    foreach (@{$self->optionsnum}){
		while( my ($key, $value) = each %$_ ) {
		    my $values = $request->{ $self->name };
		    $values = [ $values ] unless ref( $values ) =~ /ARRAY/;
		    $checked='';
		    if ( @{ $values } && $value) {				
			    if ( grep { $_ eq $value if ($_) } @{ $values } ){ $checked=' selected '; }				
		    }
		
		    if ($self->first) {
				if ($value ne $self->first){
					$optiontags.='<option '.$checked.' value="'.$value.'">'.$key.'</option>';
				} else {
					$first =  '<option '.$checked.' value="'.$value.'">'.$key.'</option>';
				}
			} else  {
                $optiontags.='<option '.$checked.' value="'.$value.'">'.$key.'</option>';
			}			
		    $result2.='<input type="hidden" '.$id.$name.' value="'.$value.'">' if (($disabled ne '')&& ( $checked ne ''));
		}
	    }
	}

        if ($self->options){
	    foreach my $key(sort keys %{$self->options}){
		my $value = $self->options->{$key};
                $value="" if (!$value);
		my $values = $request->{ $self->name };
		$values = [ $values ] unless ref( $values ) =~ /ARRAY/;
		$checked='';
		if (@{ $values } && $value) {
		    foreach (@{$values}){
		        #if ( grep { $_ eq $value } @{ $values } ){
		        if ($_){ $checked=' selected ' if $_ eq $value; }
		    }
		}
		$self->first('') if (!$self->first);
		if ($value ne $self->first){
		    $optiontags.='<option '.$checked.' value="'.$value.'">'.$key.'</option>';
		} else {
		    $first =  '<option '.$checked.' value="'.$value.'">'.$key.'</option>';
		}
		$result2.='<input type="hidden" '.$id.$name.' value="'.$value.'">' if (($disabled ne '')&& ( $checked ne ''));
	    }
	}
	
	$result .= $first.$optiontags;
    }
    $result.='</select>';
  return $self->vor($options).$result.$result2.$self->nach if ($self->{pure});
  return $self->vor($options).$result.$result2.$self->nach;
}

sub get_value{
    my ($self) = @_;
    my $result='';
    $result=$self->{request}->{$self->name} if exists($self->{request}->{$self->name});
    $result='' if ($result eq '-1');
    return $result;
}



1;


__END__

=head1 HTML::TurboForm::Element::Select

Representation class for HTMl SelectBox element.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 render

Arguments: $options

returns HTML Code for select element.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut
