
package Embperl::MyForm ;

use Embperl::Form ;

use Embperl::Inline ;
use base 'Embperl::Form' ;


# ---------------------------------------------------------------------------

sub form_id { 'topdiv' }


# ---------------------------------------------------------------------------

sub setup_form_obj
    {
    my ($self, $options, $fields) = @_ ;

    my $key = ref $self ;
    
    return if (ref $self && $self -> {id}) ;
    return $epreq->{forms}{$key} if (exists $epreq->{forms}{$key}) ;
   
    $options ||= {} ;


    $self = $self -> new ($fields,
                  { formname    => 'myform',
		    valign      =>  'top',
                    jsnamespace => 'top',
                    language    => 'de',
                    %$options},
                    $self -> form_id) ;

    $self -> layout ;
    $key = ref $self ;

    return $epreq->{forms}{$key} = $self ;
    }        

# ---------------------------------------------------------------------------


sub on_prepare_fdat

    {
    my ($self, $epreq) = @_ ;

    $self = $self -> setup_form_obj ;
    
    $self -> prepare_fdat ($Embperl::req);
    }

# ---------------------------------------------------------------------------

sub showfields

    {
    my ($self, $fields, $options) = @_ ;

    $self = $self -> setup_form_obj($options, $fields) ;

    $self -> init_data ($Embperl::req) ;
    $self -> show_controls ($Embperl::req);
    }

# ---------------------------------------------------------------------------
#
#   get_control_packages
#
#   returns an array ref with packges where to search for controls
#

sub get_control_packages
    {
    my ($self) = @_ ;

    my $packages = $self ->SUPER::get_control_packages ;

    unshift @$packages, 'Embperl::MyForm::Control' ;
    return $packages ;
    }

# ---------------------------------------------------------------------------
#
#   get_datasrc_packages
#
#   returns an array ref with packges where to search for data source classes
#

sub get_datasrc_packages
    {
    my ($self) = @_ ;

    my $packages = $self ->SUPER::get_datasrc_packages ;

    unshift @$packages, 'Embperl::MyForm::DataSource' ;
    return $packages ;
    }

1 ;

__END__

##--> the following can be used to translate form content...

#------------------------------------------------------------------------------------------
#
#   convert_label
#
#   converts the label of a control to the text that should be outputed.
#   By default does return the text or name parameter of the control.
#   Can be overwritten to allow for example internationalization.
#
#   in $ctrl        Embperl::Form::Control object
#      $name        optional: name to translate, if not given take $ctrl -> {name}
#

sub convert_label
    {
    my ($self, $ctrl, $name, $text) = @_ ;
    
    my $prefix = $ctrl -> {nameprefix} ;
    
    return _t ($prefix . ($name || $ctrl->{basename})) if ($prefix =~ /:/)  ;
    return _t ('attr:' . $prefix . ($name || $ctrl->{basename}))  ;
    }

#------------------------------------------------------------------------------------------
#
#   convert_text
#
#   converts the text of a control to the text that should be outputed.
#   By default does return the text or name parameter of the control.
#   Can be overwritten to allow for example internationalization.
#
#   in $ctrl        Embperl::Form::Control object
#

sub convert_text
    {
    my ($self, $ctrl, $value, $text) = @_ ;
    
    my $prefix = $ctrl -> {nameprefix} ;
    $value ||= $ctrl->{basename} ;
    
    return _t ($value) if ($value =~ /:/) ;
    return _t ($prefix . $value) if ($prefix =~ /:/) ;
    return _t ('info:' . $prefix . $value)  ;
    }

#------------------------------------------------------------------------------------------
#
#   convert_options
#
#   converts the values of a control to the text that should be outputed.
#   By default does nothing.
#   Can be overwritten to allow for example internationalization.
#
#   in  $ctrl        Embperl::Form::Control object
#       $values     values of the control i.e. values that are submitted
#       $options    options of the control i.e. text that should be displayed
#

sub convert_options
    {
    my ($self, $ctrl, $values, $options) = @_ ;

    my @options ;
    my $prefix = $ctrl -> {nameprefix} ;
    my $prefix1 = "val:$ctrl->{nameprefix}$ctrl->{basename}:" ;
    my $prefix2 = $prefix =~ /:/?$prefix:"val:" ;
    
    foreach my $val (@$values)
        {
        my $value = ref $val?$val -> [0]:$val ;
        my $val1 = $prefix1 . $value ;
        my $val2 = $prefix2 . $value ;

        my $opt = _t ($val1) ;
        $opt = _t ($val2) if ($opt eq $val1) ;
            
        push @options, $opt eq $val2?"$val1 | $val2":$opt ;
        }
        
    return \@options ;
    }



1;

