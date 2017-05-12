package HTML::TurboForm::Element::Imagegalerie;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ del_link all_link max dir noimgs / );

sub render{
    my ($self, $options, $view)=@_;
    if ($view) { $self->{view}=$view; }
    my $result='';
    my $disabled='';
    my $class='form_imagegalerie';
    my $request=$self->request;

    $self->label('&nbsp;') if ($self->label eq '');
    $class=$self->{class}  if exists($self->{class});
    my $aha=$self->options;
    my $name=$self->name;
    my $nr_obj = scalar(@{ $self->{options} });

    $disabled=' disabled ' if ($options->{frozen} == 1);
    my $dir='';
	$dir = $self->dir if ($self->dir);
	$result.='<div class="'.$class.'" id="'.$name.'">'."\n";
	$result.='<table class="galerielist"><tr>';

    foreach (@{$self->{options}}){
    	my $col_fn = $self->dbid;
    	my $col_label = $self->dblabel;
	    my $fn ='';
    	$fn = $_->$col_fn if ($_->$col_fn);

    	if (!$self->noimgs){
	    	if ($self->all_link){
	    		my $label = '';
	    		$label = '<br /><span class="galerielabel">'.$_->$col_label.'</span>' if($self->dblabel);
                $result.='<td><input class="del_btn" type="submit" name="'.$self->name.'_delete_'.$fn.'" value="Delete" />
                <input class="del_btn" type="submit" name="'.$self->name.'_prev_'.$fn.'" value="<-" />
                <input class="del_btn" type="submit" name="'.$self->name.'_next_'.$fn.'" value="->" /><br />
                <img src="'.$dir.$fn.'" class="galerie_image" border="0"/>
                '.$label.'
                </td>'."\n";
            }else{
                $result.='<td><img src="'.$dir.$fn.'" border="0"/></td>'."\n";
            }
        }
        if ($self->noimgs){ $result.='<td>'.$fn.'</td>'."\n";}
    }

   	$result.='</tr></table></div>';

  $result='' if ($nr_obj ==0);
  $result= $self->vor($options).$result.$self->nach if ($self->check_param('norow')==0);
  return $result;
}

sub init{
    my ($self)=@_;
    my $name=$self->name;
}

sub get_dbix{
    my ($self)=@_;
    return 0;
}

1;


__END__

=head1 HTML::TurboForm::Element::Imageslider

Representation class for Imageslider element.

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



