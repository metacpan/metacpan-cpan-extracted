package HTML::TurboForm::Element::Imageslider;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ del_link max dir noimgs / );

sub reset_js{
  	my ($self)=@_;

  	my $name=$self->name;

  	$self->{options}=[] if (!$self->{options});
  	my $nr_obj = scalar(@{ $self->{options} });

  	#$nr_obj=1 if (($nr_obj == 0) and ($self->{options}));

  	my $max = $self->max;
 	$max = $nr_obj if($nr_obj < $max);

    if ($nr_obj > 1){
	  $self->{js} = '
	  $(function() {
	      $("#'.$name.'").jCarouselLite({
	             btnNext: "#next_'.$name.'",
	             btnPrev: "#prev_'.$name.'",
	             visible: '.$max.'
	         });
	      });
	  ';
    }
}

sub render{
    my ($self, $options, $view)=@_;
    if ($view) { $self->{view}=$view; }
    my $result='';
    my $disabled='';
    my $class='form_slider';
    my $request=$self->request;

    $self->label('&nbsp;') if ($self->label eq '');

    $class=$self->{class}  if exists($self->{class});
    my $aha=$self->options;
    my $name=$self->name;
    my $nr_obj = scalar(@{ $self->{options} });

    $disabled=' disabled ' if ($options->{frozen} == 1);
    my $dir='';
	$dir = $self->dir if ($self->dir);

    if ($nr_obj>1){
	    $result='<div class="slider_img" style="float:left;" id="prev_'.$name.'"><-</div>';
	    $result.='<div class="slider_img" style="float:right;" id="next_'.$name.'">-></div>'."\n";
	    #$result.='<div class="'.$class.'" id="'.$name.'"><ul>'."\n";
	    $result.='<div class="'.$class.'" id="'.$name.'"><ul>'."\n";
	    my $result2='';

	    foreach (@{$self->{options}}){
	        if (!$self->noimgs){
	            if ($self->del_link){
	            #	$result2.='<img src="'.$dir.$_.'" border="0"/>';
	                $result.='<li><input class="del_btn" type="submit" name="'.$self->name.'_delete_'.$_.'" value="Delete" /><br />
	                <img src="'.$dir.$_.'" border="0"/></li>'."\n";
	            }else{
	                $result.='<li><img src="'.$dir.$_.'" border="0"/></li>'."\n";
	            }
	        };
	        if ($self->noimgs){ $result.='<li>'.$_.'</li>'."\n";}
	    }
	    $result.="</ul></div>";
 	}
 	if ($nr_obj==1){
 		foreach (@{$self->{options}}){
 			$result.='<input class="del_btn" type="submit" name="'.$self->name.'_delete_'.$_.'" value="Delete" /><br />
	    	<img src="'.$dir.$_.'" border="0"/>'."\n";
 		}
 	}
 	if ($nr_obj==0){ $result = '';}

  $result= $self->vor($options).$result.$self->nach if ($self->check_param('norow')==0);
  #$result= '' if ($self->{options});
  return $result;
}


sub init{
    my ($self)=@_;

    @{$self->{modules}} = ('jquery/jquery','jquery/jcarousellite_1.0.1.min', 'jquery/easing');

    $self->{max} = 3;
    my $name=$self->name;
    $self->reset_js();
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



