
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id$
#
###################################################################################

package Embperl::Form::Control ;

use strict ;
use vars qw{%fdat} ;

use Embperl::Inline ;

# ---------------------------------------------------------------------------
#
#   new - create a new control
#


sub new

    {
    my ($class, $args) = @_ ;

    my $self = { %$args } ;
    bless $self, $class ;

    $self -> init ;

    return $self ;
    }

# ---------------------------------------------------------------------------
#
#   init - init the new control
#

sub init

    {
    my ($self) = @_ ;

    my $eventattrs = '' ;
    if (my $e = $self -> {event}) 
        {
        for (my $i = 0; $i < @$e; $i += 2) 
            {
            $eventattrs .= $e -> [$i] . '="' . $e -> [$i+1] . '" ' ;
            }
        }
    $self -> {eventattrs} = $eventattrs ;
    $self -> {imagedir} ||= '/images' ;
    
    return $self ;
    }


# ---------------------------------------------------------------------------
#
#   noframe - do not draw frame border if this is the only control
#

sub noframe

    {
    return ;
    }

# ---------------------------------------------------------------------------
#
#   is_disabled - do not display this control at all
#

sub is_disabled

    {
    my ($self, $req) = @_ ;

    my $disable = $self -> {disable} || $req -> {form_options_masks}{$self->{name}}{disable} || $req -> {form_options_masks}{'*'}{disable} ;
    $disable = &{$disable}($self, $req) if (ref ($disable) eq 'CODE') ;

    return $disable ;
    }

# ---------------------------------------------------------------------------
#
#   is_blanked - display this control as blank field
#

sub is_blanked

    {
    my ($self, $req) = @_ ;

    my $disable = $self -> {blank} || $req -> {form_options_masks}{$self->{name}}{blank} || $req -> {form_options_masks}{'*'}{blank} ;
    $disable = &{$disable}($self, $req) if (ref ($disable) eq 'CODE') ;

    return $disable ;
    }

# ---------------------------------------------------------------------------
#
#   is_readonly - could value of this control be changed ?
#

sub is_readonly

    {
    my ($self, $req) = @_ ;

    my $readonly = $self -> {readonly}  || $req -> {form_options_masks}{$self->{name}}{readonly} || $req -> {form_options_masks}{'*'}{readonly}  ;
    $readonly = &{$readonly}($req) if (ref ($readonly) eq 'CODE') ;

    return $readonly ;
    }

# ---------------------------------------------------------------------------
#
#   is_with_id - returns true if the control shows something that has an internal id
#

sub is_with_id

    {
    my ($self, $req) = @_ ;

    return 0 ;
    }

# ---------------------------------------------------------------------------
#
#   is_hidden - returns true if this is a hidden control
#

sub is_hidden

    {
    my ($self, $req) = @_ ;

    return  ;
    }

# ---------------------------------------------------------------------------
#
#   has_code_refs - returns true if is_readonly or is_disabled are coderefs
#

sub has_code_refs

    {
    my ($self, $req) = @_ ;

    return  ref ($self -> {readonly}) eq 'CODE' || ref ($self -> {disable}) eq 'CODE'  || ref ($self -> {blank}) eq 'CODE'  ;
    }


# ---------------------------------------------------------------------------
#
#   code_ref_fingerprint - returns fingerprint of is_readonly and is_disabled
#

sub code_ref_fingerprint

    {
    my ($self, $req) = @_ ;

    return  ($self -> is_readonly($req)?'R':'W') . ($self -> is_disabled($req)?'D':'E') . ($self -> is_blanked($req)?'B':'S') ;
    }

# ---------------------------------------------------------------------------
#
#   constrain_attrs - returns attrs that might change the form layout
#                     if there value changes
#

sub constrain_attrs

    {
    my ($self, $req) = @_ ;

    return () ;
    }

# ---------------------------------------------------------------------------
#
#   get_on_show_code
#
#   retuns js code that should be excuted when form becomes visible
#

sub get_on_show_code
    {
    return ;
    }

# ---------------------------------------------------------------------------
#
#   get_active_id - get the id of the value which is currently active
#

sub get_active_id

    {
    return ;
    }

# ---------------------------------------------------------------------------
#
#   form - return form object
#

sub form
    {
    my ($self) = @_ ;

    return $Embperl::FormData::forms{$self -> {formptr}} ;
    }

# ---------------------------------------------------------------------------
#
#   load_form - load a form to a given formptr.
#
#   This class method should be overwritten, to load a form to a given
#   formptr, in case it is not already loaded
#   The formptr maybe passed in the options hash during form creation
#
#   in  $formptr
#


sub load_form
    {
    my ($class, $formptr) = @_ ;
    
    }
    
# ---------------------------------------------------------------------------
#
#   get_control_from_id
#

sub get_control_from_id
    {
    my ($class, $id) = @_ ;
    
    my ($formptr, $ctlid) = split /#/, $id ;
    my $form = $Embperl::FormData::forms{$formptr} ;
    
    if (!$form)
        {
        $class -> load_form ($formptr) ;
        $form = $Embperl::FormData::forms{$formptr} ;
        die "Form for '$formptr' is not available" if (!$form) ;
        }
    
    my $ctl  = $form -> {controlids}{$ctlid} ;
    die "Control '$ctlid' in Form '$formptr' is not available" if (!$ctl) ;
    
    return $ctl ;
    }
    
# ---------------------------------------------------------------------------
#
#   get_id_for_control
#

sub get_id_for_control
    {
    my ($self, $reqdata) = @_ ;
    
    return "$self->{formptr}#$self->{id}" ;
    }
    
# ---------------------------------------------------------------------------
#
#   label_text - return text of label
#

sub label_text
    {
    my ($self, $req) = @_ ;

    my $key = 'label_text' . ($req -> {form_options}{language_fingerprint} || $req -> {form_options}{language}) ;

    return $self -> {$key} if ($self -> {$key}) ;

    return $self -> {$key} = $self -> {showtext}?($self->{text} ||
                                   $self->{name}):$self -> form -> convert_label ($self, undef, undef, $req) ;
    }


# ---------------------------------------------------------------------------
#
#   get_validate_auto_rules - get rules for validation, in case user did
#                             not specify any
#                             should be overwritten by control
#

sub get_validate_auto_rules
    {
    my ($self, $req) = @_ ;
    
    return if (!$self -> {required}) ;
    return [ required => 1 ] ;
    }
    
# ---------------------------------------------------------------------------
#
#   get_validate_rules - get rules for validation
#

sub get_validate_rules
    {
    my ($self, $req) = @_ ;

    my @local_rules ;
    if ($self -> {validate})
        {
        @local_rules = ( -key => $self->{name} );
        push @local_rules, -name => $self -> label_text ($req);
        push @local_rules, @{$self -> {validate}};
        }
    else
        {
        my $auto = $self -> get_validate_auto_rules ($req) ;
        if ($auto)
            {
            @local_rules = ( -key => $self->{name} );
            push @local_rules, -name => $self -> label_text ($req) ;
            push @local_rules, @{$auto};
            }
        }    
    return \@local_rules ;
    }

# ---------------------------------------------------------------------------
#
#   has_validate_rules - check if there is anything to validate and
#                        create auto rules
#

sub has_validate_rules
    {
    my ($self, $req) = @_ ;

    if ($self -> {validate})
        {
        return scalar(@{$self -> {validate}}) ;   
        }
    my $auto = $self -> get_validate_auto_rules ($req) ;
    if ($auto)
        {
        $self -> {validate} = $auto ;
        return scalar(@$auto) ;
        }
        
    $self -> {validate} = [] ;
    return 0 ;
    }

# ---------------------------------------------------------------------------
#
#   has_auto_label_size - returns true if label should be auto sized for this control
#

sub has_auto_label_size
    {
    return 1 ;
    }

    
# ---------------------------------------------------------------------------
#
#   get_value - return the current value for the control
#               if dataprefix is set, every hash key within dataprefix is tried
#

sub get_value
    {
    my ($self, $req) = @_ ;
    
    my $fdat       = $req -> {docdata} || \%Embperl::fdat ;
    my $name       = $self -> {srcname} || $self -> {force_name} || $self -> {name} ;
    return $fdat -> {$name} ;
    my $dataprefix = $self -> {dataprefix} ;

    return $fdat -> {$name} if (!$dataprefix) ;
    
    foreach my $prefix (@$dataprefix)
        {
        my $item = $prefix?$fdat -> {$prefix}{$name}:$fdat -> {$name} ;
        return $item if (defined ($item)) ;
        }
    
    return ;
    }


# ---------------------------------------------------------------------------
#
#   get_std_control_attr - return the default attributes for the control
#
#   ret     string with all standard attribute, already html escaped
#

sub get_std_control_attr
    {
    my ($self, $req, $id, $type, $addclass) = @_ ;

    my $name    = $self -> {force_name} || $self -> {name} ;
    my $ctrlid  = $id || ($req -> {uuid} . '_' . $name) ;
    my $class   = $self -> {class} ;
    my $width   = $self -> {width_percent} ;
    my $events  = $self -> {eventattrs} ;
    $type     ||= $self -> {type} ;
    my $state   = $self -> {state} ;
    $state =~ s/[^-a-zA-Z0-9_]/_/g ;
    
    my $attrs = qq{class="ef-control ef-control-width-$width ef-control-$type ef-control-$type-width-$width $addclass $class $state"  id="$ctrlid" $events} ;
    return wantarray?($attrs, $ctrlid, $name):$attrs ;
    }

# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $value) = @_ ;
    
    $value = $self -> get_value ($req) if (!defined ($value)) ;

    return $value ;
    }
    
# ---------------------------------------------------------------------------
#
#   get_id_from_value - returns id for a given value
#

sub get_id_from_value

    {
    #my ($self, $value) = @_ ;

    return ;
    }

    
1 ;

# ===========================================================================

__EMBPERL__

[$syntax EmbperlBlocks $]



[# ---------------------------------------------------------------------------
#
#   show - output the whole control including the label
#]

[$sub show ($self, $req) 

$fdat{$self -> {name}} = $self -> {default} if ($fdat{$self -> {name}} eq '' && exists ($self -> {default})) ;
my $span = 0 ;

$]<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type} +] [+ $self -> {state} +]">
  <tr>
    [$ if ($self -> is_blanked ($req)) $]
    <td class="ef-label-box ef-label-box-width-100"> </td>    
    [$else$][-
    $span += $self -> show_label_cell ($req, $span);
    $self -> show_control_cell ($req, $span) ;
    -][$endif$]
  </tr>
  </table>[$  
 endsub $]

[# ---------------------------------------------------------------------------
#
#   show_sub_begin - output begin of sub form
#]

[$sub show_sub_begin ($self, $req)

my $span = $self->{width_percent}  ;
$]
<!-- sub begin --></tr><tr><td class="cBase cTabTD" colspan="[+ $span +]">
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_sub_end - output end of sub form
#]

[$sub show_sub_end ($self, $req) $]
</td><!-- sub end -->
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show - output the label
#]

[$ sub show_label ($self, $req) $][-

    if ($self -> {showoptionslabel})
        {
        my $opts = $self -> form -> convert_options ($self, [$self -> {value}], undef, $req) ;
        $self -> {text} = $opts -> [0] ;
        $self -> {showtext} = 1 ;
        }
-][+ $self -> label_text ($req) +][$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_label_icon - output the icon before the label
#]

[$sub show_label_icon ($self, $req) $]
[$if $self -> {xxsublines} $]&nbsp;<img src="/images/plus.png" style="vertical-align: middle;">[$endif$]
[$if $self -> {xxparentid} $]&nbsp;<img src="/images/vline.png" style="vertical-align: middle;">[$endif$]
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show - output the control
#]

[$ sub show_label_cell ($self, $req)

my $style = '';
$style = 'white-space:nowrap; ' if ($self->{labelnowrap}) ;
$addclass = 'ef-label-box-width-' . ($self->{width_percent}) ;
$addclass2 = 'ef-label-width-' . ($self->{width_percent}) ;
$]
   <td class="ef-label-box  [+ $addclass +] [$ if $self->{labelclass} $][+ " $self->{labelclass}" +][$ endif $]" [$ if $style $]style="[+ $style +]"[$ endif $]>
    <div class="ef-label [+ $addclass2 +]">
    [-
    $self -> show_label ($req);
    $self -> show_label_icon ($req) ;
    -]
    </div>
  </td>
  [- return $span ; -]
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_control - output the control itself
#]

[$ sub show_control ($self, $req) $]<div [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req) } +]>[+ $self->{value} +]</div>[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_control_readonly - output the control as readonly
#]

[$ sub show_control_readonly ($self, $req, $value) 

my $text  = $self -> get_display_text ($req, $value)  ;
my $name  = $self -> {force_name} || $self -> {name} ;
$]
<div [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, '', 'readonly') } +] _ef_divname="[+ $name +]">[+ $text +]</div>
[$ if $self->{hidden} $]
<input type="hidden" name="[+ $name +]" value="[+ $value +]">
[$endif$]
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_control_readonly_array - output the control as readonly, multiple
#                                 times in case of array
#]

[!
 
sub show_control_readonly_array
    {
     my ($self, $req, $value) = @_ ;

    $value  = $self -> get_value ($req) if (!defined ($value)) ;

    if (ref ($value) eq 'ARRAY')
        {
        foreach my $subval (@$value)
            {
            
            $self -> show_control_readonly ($req, defined ($subval)?$subval:'') ;    
            }
        }
    else
        {
        $self -> show_control_readonly ($req, $value) ;    
        }
    }
!]

[# ---------------------------------------------------------------------------
#
#   show_control_addons - output additional things after the control
#]

[$ sub show_control_addons ($self, $req) $][$endsub$]


[# ---------------------------------------------------------------------------
#
#   show_controll_cell - output the table cell for the control
#]

[$ sub show_control_cell ($self, $req, $x)

    my $ro = $self -> is_readonly ($req) ;
    my $addclass = 'ef-control-box-width-' . ($self->{width_percent} || 50 ) ;
    $addclass .= ' ef-control-box-readonly' if ($ro) ;    
$]
    <td class="ef-control-box [+ $addclass +]">
    [*
    my @ret = $ro?$self -> show_control_readonly_array($req):$self -> show_control ($req);
    $self -> show_control_addons ($req) ;
     *]
    </td>
[* return @ret ; *]
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control - Base class for controls inside an Embperl Form


=head1 SYNOPSIS

Do not use directly, instead derive a class

=head1 DESCRIPTION

This class is not used directly, it is used as a base class for
all controls inside an Embperl Form. It provides a set of methods
that could be overwritten to customize the behaviour of your controls.

=head1 METHODS

=head2 new

Create a new control

=head2 init

Init the new control

=head2 noframe

Do not draw frame border if this is the only control

=head2 is_disabled

Do not display this control at all.

=head2 is_readonly

Could value of this control be changed ?

=head2 label_text

Returns the text of the label

=head2 show

Output the control

=head2 get_on_show_code

Returns JavaScript code that should be executed when the form becomes visible

=head2 get_active_id

Get the id of the value which is currently active

=head2 form

Return the form object of this control

=head2 show_sub_begin

Output begin of sub form

=head2 show_sub_end

Output end of sub form

=head2 show_label

Output the label of the control

=head2 show_label_icon

Output the icon after the label

=head2 show_label_cell

Output the table cell in which the label will be displayed

Must return the columns it spans (default: 1)

=head2 show_control

Output the control itself

=head2 show_control_readonly

Output the control itself as readonly

=head2 show_control_addons

output additional things after the control

=head2 show_control_cell

Output the table cell in which the control will be displayed

Gets the x position as argument


=head1 PARAMETERS

=head3 name

Specifies the name of the control

=head3 text

Will be used as label for the control, if not given
'name' is used as default.

Normaly the the name and text parameters are processed
by the method C<convert_label> of the C<Embperl::Form>
object. This method can be overwritten, to allow translation etc.

If the parameter C<showtext> is given a true value, C<convert_label>
is not called and the text is displayed as it is.

=head3 showtext

Display label without passing it through C<convert_label>. See C<text>.

=head2 labelnowrap

If set, the text label will not be line wrapped.

=head2 labelclass

If set, will be used as additional CSS classes for the label text cell.

=head2 readonly

If set, displays a readonly version of the control.

=head2 disable

If set, the control will not be displayed at all.

=head2 newline

If set to 1, forces a new line before the control.
If set to -1, forces a new line after the control.

=head2 width

Gives the widths of the control. The value is C<1/width>
of the the whole width of the form. So if you want to
have four controls in one line set C<width> to 4. The default value
is 2.

=head2 width_percent

With this parameter you can also specify the width of
the control in percent. This parameter take precedence over
C<width>

=head2 default

Default value of the control

=head2 imagedir

Basepath where to find images, in case the control uses images.
Default value is /images

=head2 trigger

When set will trigger state changes of other controls. See "state".

=head2 state

Can be used to hide/show disable/enable the control trigger by
other controls.

Checkbox define the following states:

=over

=item * <id-of-checkbox>-show

Show control if checkbox checked

=item * <id-of-checkbox>-hide

Hide control if checkbox checked

=item * <id-of-checkbox>-enable

Enable control if checkbox checked

=item * <id-of-checkbox>-disable

Disable control if checkbox checked

=back



=head1 AUTHOR

G. Richter (richter at embperl dot org)

=head1 SEE ALSO

perl(1), Embperl, Embperl::Form

