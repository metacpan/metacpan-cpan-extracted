package HTML::TurboForm::Element::Checkbox;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ tablelayout listmode/ );

sub render{
    my ($self, $options, $view)=@_;
    if ($view) { $self->{view}=$view; }
    my $result='';
    my $disabled='';
    my $class='';
    my $request=$self->request;

    
    if (!$self->label){ $self->label(''); }
    $self->label('&nbsp;') if ($self->label eq '');
    

    $class=' class="'.$self->{class}.'" '  if exists($self->{class});

    my $name=' name="'.$self->name.'" ';
    my $checked='';
    if ($options->{frozen}){
        $disabled=' disabled ' if ($options->{frozen} == 1) ;
    }
    my $pre='';
    my $post='';
    my $after='';

    $self->listmode('') if (!$self->listmode);
    if ( $self->listmode ne '' ){
        $result.='<ul>';
        $pre='<li>';
        $post='</li>';
        $after='</ul>';
    }

    my $counter=0;
    my $max=0;
    if ($self->tablelayout) {
        $result.='<td>';
        $max = $self->tablelayout ;
    }

    while ( my( $key,$value) = each %{$self->options}){
        $counter++;
        if (($counter == $max) && ($self->tablelayout)) {
            $result.="</td>\n<td>";
            $counter = 0;
        }
        
        my $values = $request->{ $self->name };
        $values = [ $values ] unless ref( $values ) =~ /ARRAY/;
        
        $checked='';
        if ([ $values]){ $checked=' checked ' if ( grep { $_ eq $value if ($_) } @{ $values } ); }
        
        $result.=$pre.'<input type="checkbox" '.$class.$checked.$disabled.$name.' rel="'.lc($key).'" value="'.$value.'">'.$key.$post;
        
        $result.='<input type="hidden" '.$name.' value="'.$value.'">' if (($disabled ne '')&& ( $checked ne ''));
        $result.='<br />' if($self->tablelayout);
    }
    
    
    
    
    $result.=$after;

  $result.='</td>' if ($self->tablelayout);

  return $result if ($self->tablelayout);
  $result= $self->vor($options).$result.$self->nach if ($self->check_param('norow')==0);

  return $result;
}

1;


__END__

=head1 HTML::TurboForm::Element::Checkbox

Representation class for HTML Checkbox element.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 render

Arguments: $options

returns HTML Code for checkbox element.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut



