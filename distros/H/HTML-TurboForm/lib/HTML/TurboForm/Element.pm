package HTML::TurboForm::Element;

use warnings;
use strict;
use Scalar::MoreUtils qw(empty);
use base qw/ Class::Accessor /;
__PACKAGE__->mk_accessors( qw/ params submit wrapper errorclass pure default dbsearchfield dbdata optionstext dbop dbid dblabel ignore_dbix type id name label text value request options optionsnum class left_class limit right_class row_class attributes table submit columns / );

sub new{
    my ($class, $request) = @_;
	
    my $self = $class->SUPER::new( $request );
    $self->{view} ='';
    $self->{submitted} = 0;
    $self->{submitted} = 1 if ($request->{ $self->name });
	
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

    if ($self->submit){
        @{$self->{modules}} = ('jquery/jquery');
        $self->{js} = ' $("#'.$self->name.'").'.$self->submit.'(function(){$("form")[0].submit(); });  ';
    }

     if ($self->dbdata and $self->dbid and not $self->dblabel){
       my @t = @{ $self->dbdata };
       my @tmp;
       foreach (@t){
            my $value_method = $self->dbid;
            my $v=$_->$value_method;
            push(@tmp,$v);
       }
       @{$self->{options}} = @tmp;
     }

    $self->init();
    return $self;
}

sub init{
   my ($self) = @_;
}

sub add_options{
   my ($self, $opt) = @_;
   $self->{options} = $opt;
}

sub reset_options{
   my ($self, $opt) = @_;
   $self->{dbdata}=[];
   $self->{options}=[];
   $self->{options} = $opt;
}

sub freeze{
    my($self) =@_;
}

sub populate{
    my($self) =@_;
}

sub get_attr{
    my ($self) =@_;
    my $result="";

    while ( my( $key,$value) = each %{$self->{attributes}}){
        if ($value) {
            $result.=' '.$key.'="'.$value.'"';
        } else {
            $result.=' '.$key;
        }
    }

    return $result.' ';
}

sub check_param{
    my ($self, $name)=@_;
    my $result=0;
    if ( exists($self->{params}->{ $name })) {
        $result=1;
    }
    return $result;
}

sub get_dbix{
    my ($self)=@_;

    if (!$self->ignore_dbix) {
        my $dbname=$self->name if ($self->name);
        $dbname   =$self->dbsearchfield if ($self->dbsearchfield);

		if ($self->type eq 'Select'){ return 0 if ($self->get_value() eq '-1'); }

        if($self->get_value() ne '') {
            return { $dbname =>  $self->get_value()};
        } else {
            return 0;
        }
    }  else {return 0;}
}

sub vor{
    my ($self,$options)=@_;

    return "" if ( $self->pure );
    my $error='';

    $error=$options->{error_message} if $options->{error_message};
    my $result='';
    my $table='';

    my $rwc='';
    my $rtc='';
    my $ltc='';
    my $class='class="form_row"';
    my $errorclass=" ".$self->errorclass if ($self->errorclass);
	
    if ($self->{class}) {       $class='class="'.$self->{class}.'"'; }
    if ($self->{row_class}) {   $rwc  = " class='".$self->{row_class}."' ";  }
    if ($self->{right_class}) { $rtc  = " class='".$self->{right_class}."' "; }
    if ($self->{left_class}) {  $ltc  = " class='".$self->{left_class}."' ";  }

    if ($self->{view} eq '') {
        $error="<div class='form_error'>$error</div>" if ($error ne '');
        
        $self->label('') if (!$self->label);
		$errorclass='' if (!$errorclass);
        $result=$table."<div ".$class.$rwc.">".$error.
                       "<div class='form_left'".$ltc.">".$self->label."</div>".
                       "<div class='form_right".$errorclass."'".$rtc.">";
		       
#$result=$table."<div ".$class.$rwc.">".$error.
#                       "<div class='form_left'".$ltc.">".$self->label."</div>".
#                       "<div class='form_right'".$rtc.">";		       
		       
        $result=$table."<div ".$class.$rwc.">" if ($self->type eq "Html");
    }

    if ($self->{view} eq 'table') {
        $error='<tr><td colspan="2">'.$error.'</td></tr>' if ($error ne '');

 $table='' if (!$table);
 $error='' if (!$error);
 $class='';
 $rwc='' if (!$rwc);
 $rtc='' if (!$rtc);
 $self->label('') if (!$self->label);

        $result = $table. $error. "<tr ". $class. $rwc.">".
                       "<td ".$ltc.">".$self->label."</td>".
                       "<td ".$rtc.">";

        $result=$table.'<tr><td colspan="2" '.$class.$rwc.'>' if ($self->type eq "Html");
    }

     if ($self->{view} eq 'column') {
        $self->label('') if (!$self->label);
        $result='<td>'.$self->label.'</td><td>';
        $result.=$error.'<br />' if ($error ne '');
    }

    if ($self->wrapper){
		my $wrap=$self->wrapper;
		my $s='';
		$s=$self->label if (!$s);		
		$wrap=~s/<label>/$s/g;		
		$wrap=~s/<error>//g if (!$error);
		$wrap=~s/<error>/$error/g if ($error ne '');
		my $pos=index($wrap,'<element>');
		$result=substr($wrap,0,$pos);
		$self->{after_wrap}=substr($wrap,$pos+9);
	}

    return $result;
}

sub nach{
    my ($self)=@_;

    return "" if ($self->pure );
    my $result= "</div></div>";
    my $table='';
	$result='' if ($self->wrapper);

    $result="</div>" if ($self->type eq "Html");
    $result="</td></tr>"  if ($self->{view} eq 'table');
    $result="</td>"  if ($self->{view} eq 'column');

	if ($self->wrapper){
		$result=$self->{after_wrap} if ($self->{after_wrap});
	}
    $result.="\n";
    return $result;
}

sub get_label{
    my ($self) = @_;
    my $result='';
    $result=$self->label if $self->label;
    return $result;
}

sub get_value{
    my ($self) = @_;
    my $result='';    
    $result=$self->{request}->{$self->name} if (!empty($self->{request}->{$self->name}));    
    return $result;
}

1;


__END__

=head1 HTML::TurboForm::Element

Base Class for HTML elements

=head1 SYNOPSIS

$form->addelement(...);

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 add_options

Arguments: $options

adds option tags to a html element

=head2 get_value

Arguments: none

returns value of the element

=head2 get_attr

Arguments: none

Return List of attributes of HTML Tag

=head2 check_param

Arguments: $name

checks if param with given name does exist

=head2 nach

Arguments: none

returns given prehtml

=head2 vor

Arguments: none

return given posthtml

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut
