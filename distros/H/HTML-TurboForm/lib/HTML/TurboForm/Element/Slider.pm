package HTML::TurboForm::Element::Slider;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ min max steps label_addon start modules zerovalue / );


sub init{
    my ($self)=@_;

    my $min = 0;
    my $max = 100;
    my $step = 10;
    my $start = $self->start;

    $min=$self->min;
    $min-- if($self->zerovalue);
    $step=$self->steps;
    $max=$self->max;

    my $js_min='';
    $js_min ='if (ui.value == '.$min.') label="'.$self->zerovalue.'";' if($self->zerovalue);

    @{$self->{modules}} = ('jquery/jquery','jquery/ui.core.min','jquery/ui.slider.min');

    my $labelchange='';
    $labelchange = 'if (label != "'.$self->zerovalue.'") label+="'.$self->label_addon.'";' if ($self->label_addon);
    $self->{js} = '
        $("#'.$self->name.'_slider").slider({
 	        "steps": '.$step.',
			"min": '.$min.',
			"max": '.$max.',
			"startValue": '.$start.',
			"slide": function(e, ui){
			    var label = ui.value;
			    '.$js_min.'
				$("#'.$self->name.'").val(ui.value);
				'.$labelchange.'
                $("#'.$self->name.'_label").html(label);
			}
		});  ';
    $self->{value}=$self->request->{ $self->name };
    if ($self->{value}){
        $self->{js} .=  '$("#'.$self->name.'_slider").slider("moveTo",'.$self->{value}.');';
    }
}

sub get_dbix{
    my ($self)=@_;

    my $dbname=$self->name if ($self->name);
    $dbname   =$self->dbsearchfield if ($self->dbsearchfield);
    my $val = $self->get_value();
    if($val ne '') {
        if ($val < $self->min) {
            return 0;
        } else {
        	if (!$self->dbop){
            	return { $dbname => $val } ;
        	} else {
				return { $dbname => { $self->dbop => $val }} ;
        	}

        }
    } else {
        return 0;
    }
}

sub get_value{
    my ($self)=@_;
    return 0 if (($self->zerovalue) && ( $self->{value} == ($self->{min}-1)));
    return $self->{value};
}

sub freeze{
    my ($self)=@_;
    $self->{js} .=  '$("#'.$self->name.'_slider").slider("disable");';
}

sub render {
  my ($self, $options, $view)=@_;
  if ($view) { $self->{view}=$view; }
  my $request=$self->request;
  my $result='';
  my $disabled='';
  my $class='form_text';

  $class = $self->class if ($self->class);

  my $name=$self->name;
  my $minlabel = $self->min;
  my $maxlabel = $self->max;
  $minlabel = $self->zerovalue if ($self->zerovalue);

  $result='
             <div class="slider_label">
             <span class="slider_pos_label" id="'.$name.'_label">'.$minlabel.'</span>
             </div>
             <div id="'.$name.'_slider" class="ui-slider-1">
                <div class="ui-slider-handle">&nbsp;</div>
            </div>
            <input class="slider_v" type="hidden" name="'.$name.'" id="'.$name.'" value="">';



  return $self->vor($options).$result.$self->nach;
}
1;

__END__

=head1 HTML::TurboForm::Element::Slider

Representation class for HTML SLider input element. This Element uses the jquery Javascript library !

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


