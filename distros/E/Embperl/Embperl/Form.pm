
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


package Embperl::Form ;

use strict ;

use lib qw{..} ;

use Embperl ;
use Embperl::Form::Control ;
use Embperl::Form::Validate ;
use Embperl::Form::Control::blank ;

use Embperl::Inline ;

use Data::Dumper ;
use Storable ;
use MIME::Base64 ;

our %forms ;
our $form_cnt = 1 ;
our %CLEANUP = ('forms' => 0) ;

use vars qw{$epreq} ;

# ---------------------------------------------------------------------------
#
#   sub_new - create a new sub form
#


sub sub_new

    {
    my ($class, $controls, $options, $id, $toplevel, $parentptr) = @_ ;

    $id ||= 'topdiv' ;
    $options ||= {} ;
    $toplevel = 1 if (!defined ($toplevel)) ;

    my $self = ref $class?$class:{} ;

    $self -> {controls}       = $controls ;
    $self -> {options}        = $options ;
    $self -> {id}             = $id ;
    $self -> {parentptr}      = $parentptr ;
    $self -> {formname}       = $options -> {formname} || 'topform' ;
    $self -> {bottom_code}    = [] ;
    $self -> {validate_rules} = [] ;
    $self -> {toplevel}       = $toplevel ;
    $self -> {checkitems}     = $options -> {checkitems} ;
    $self -> {valign}         = $options -> {valign}   || 'top' ;
    $self -> {jsnamespace}    = $options -> {jsnamespace} || '' ;
    $self -> {jsnamespace}   .= '.' if ($self -> {jsnamespace}) ;
    $self -> {disable}        = $options -> {disable} ;
    $self -> {control_packages} = $options -> {control_packages} ;
    $self -> {datasrc_packages} = $options -> {datasrc_packages} ;
    $self -> {formptr}          = ($options -> {formptr} || "$self") . '/' . $id  ;
    bless $self, $class if (!ref $class);

    # The following lines needs to there twice!
    # some weired bug in Perl?
    $Embperl::FormData::forms{$self -> {formptr}} = $self ;
    $Embperl::FormData::forms{$self -> {formptr}} = $self ;

    if ($toplevel)
        {
        $self -> {fields2empty} = [] ;
        $self -> {init_data}    = [] ;
        $self -> {init_markup}  = [] ;
        $self -> {prepare_fdat} = [] ;
        $self -> {code_refs}    = [] ;
        $self -> {constrain_attrs} = [] ;
        $self -> {do_validate}  = [] ;
        }
    else
        {
        $self -> {fields2empty} = $self -> parent_form -> {fields2empty} ;
        $self -> {init_data}    = $self -> parent_form -> {init_data} ;
        $self -> {init_markup}  = $self -> parent_form -> {init_markup} ;
        $self -> {prepare_fdat} = $self -> parent_form -> {prepare_fdat} ;
        $self -> {constrain_attrs}    = $self -> parent_form -> {constrain_attrs} ;
        $self -> {code_refs}    = $self -> parent_form -> {code_refs} ;
        $self -> {do_validate}  = $self -> parent_form -> {do_validate} ;
        }
    push @{$self -> {code_refs}}, $self if ($self -> has_code_refs) ;

    $self -> new_controls ($controls, $options, undef, $id, $options -> {masks}, $options -> {defaults}) ;

    $self -> {noframe} = 1 if ($controls && @$controls > 0 &&
                               $controls -> [0] -> noframe) ;


    return $self ;
    }

# ---------------------------------------------------------------------------
#
#   new - create a new form
#

sub new
    {
    my $class = shift ;
    return $class -> sub_new (@_) ;
    }

# ---------------------------------------------------------------------------
#
#   DESTROY
#

sub DESTROY
    {
    my ($self) = @_ ;

    delete $Embperl::FormData::forms{$self -> {formptr}} ;
    }

# ---------------------------------------------------------------------------
#
#   get_control_packages
#
#   returns an array ref with packges where to search for control classes
#

sub get_control_packages
    {
    my ($self) = @_ ;

    return $self -> {control_packages} || ['Embperl::Form::Control'] ;
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

    return $self -> {datasrc_packages} || ['Embperl::Form::DataSource'] ;
    }

# ---------------------------------------------------------------------------
#
#   new_object - load a control or datasrc class and create a new object of
#                this class
#
#   in  $packages   arrayref of packages to search the class
#       $name       name of the class. Either a full package name or
#                   only the last part of the package. In the later
#                   @$packages are searched for this class
#   ret             reference to the object
#

sub new_object

    {
    my ($self, $packages, $name, $args) = @_ ;

    my $ctlmod ;
    my $obj ;

    $args ||= {} ;

    if ($name =~ /::/)
        {
        if (!defined (&{"$name\:\:new"}))
            {
            {
            local $SIG{__DIE__} ;
            eval "require $name" ;
            }
            if ($@)
                {
                my $modfile = $name . '.pm' ;
                $modfile =~ s/::/\//g ;
                if ($@ !~ /Can\'t locate $modfile/)
                    {
                    die "require $name: $@" ;
                    }
                }
            }

        $obj = $name -> new ($args) ;
        $ctlmod = $name ;
        }
    else
        {
        foreach my $package (@$packages)
            {
            my $mod = "$package\:\:$name"  ;
            if ($mod -> can('new'))
                {
                $obj = $mod -> new ($args) ;
                $ctlmod = $mod ;
                last ;
                }
            }
        if (!$ctlmod)
            {
            foreach my $package (@$packages)
                {
                my $mod = "$package\:\:$name"  ;
                {
                local $SIG{__DIE__} ;
                eval "require $mod" ;
                }
                if ($@)
                    {
                    my $modfile = $mod . '.pm' ;
                    $modfile =~ s/::/\//g ;
                    if ($@ !~ /Can\'t locate $modfile/)
                        {
                        die "require $mod: $@" ;
                        }
                    }
                if ($mod -> can('new'))
                    {
                    $obj = $mod -> new ($args) ;
                    $ctlmod = $mod ;
                    last ;
                    }
                }
            }
        }
    die "No Module found for type = $name, searched: @$packages" if (!$ctlmod || !$obj) ;

    return $obj ;
    }


# ---------------------------------------------------------------------------
#
#   new_controls - transform elements to control objects
#


sub new_controls

    {
    my ($self, $controls, $options, $id, $formid, $masks, $defaults, $no_init) = @_ ;

    my $n = 0 ;
    my $packages = $self -> get_control_packages ;

    foreach my $control (@$controls)
        {
        die "control definition must be a hashref or an object, is '$control' " if (!ref $control || ref $control eq 'ARRAY');

        my $ctlid = $control->{name} ;
        my $q  = 2 ;
        while (exists $self -> {controlids}{$ctlid})
            {
            $ctlid = $control->{name} . '_' . $q ;
            $q++ ;
            }
        
        my $name = $control -> {name} ;
        $control -> {type}      =~ s/sf_select.+/select/ ;
        $control -> {type}      ||= ($control -> {name}?'input':'blank') ;
        $control -> {parentid}  = $id if ($id) ;
        $control -> {id}      ||= $ctlid ;
        $control -> {basename}  = $control->{name} ;
        $control -> {formid}    = $formid ;
        $control -> {formptr}   = $self -> {formptr}  ;

        my $type    = $control -> {type} ;
        my $default = $defaults -> {$name} || $defaults -> {"*$type"} || $defaults -> {'*'};
        my $mask    = $masks    -> {$name} || $masks -> {"*$type"} || $masks -> {'*'};

        if ($mask)
            {
            foreach (keys %$mask)
                {
                $control -> {$_} = $mask -> {$_}  ;
                }
            }
        if ($default)
            {
            foreach (keys %$default)
                {
                $control -> {$_} = $default -> {$_} if (!exists $control -> {$_}) ;
                }
            }

        if (ref $control eq 'HASH')
            {
            my $type = $control -> {type}  ;
            $control = $self -> new_object ($packages, $type, $control) ;
            if (!$no_init)
                {
                push @{$self -> {init_data}}, $control if ($control -> can ('init_data')) ;
                push @{$self -> {init_markup}}, $control if ($control -> can ('init_markup')) ;
                push @{$self -> {prepare_fdat}}, $control if ($control -> can ('prepare_fdat')) ;
                push @{$self -> {code_refs}}, $control if ($control -> has_code_refs) ;
                push @{$self -> {do_validate}}, $control if ($control -> has_validate_rules) ;
                push @{$self -> {constrain_attrs}}, $control -> constrain_attrs ;
                }
            }
        $self -> {controlids}{$control->{id}} = $control ;
        
        next if ($control -> is_disabled ()) ;
        if ($control -> {sublines})
            {
            my $i = 0 ;
            my $name = $control -> {name} ;
            foreach my $subcontrols (@{$control -> {sublines}})
                {
                next if (!$subcontrols) ;
                $self -> new_controls ($subcontrols, $options, "$name-$i", $formid, $masks, $defaults, $no_init) ;
                $i++ ;
                }
            }
        if ($control -> {subforms})
            {
            my @obj ;
            my @ids ;
            my $i = 0 ;

            foreach my $subcontrols (@{$control -> {subforms}})
                {
                next if (!$subcontrols) ;
                my $ctlid = $control -> {values}[$i] || $control->{name} ;
                my $q  = 2 ;
                while (exists $self -> {controlids}{$ctlid})
                    {
                    $ctlid = $control->{name} . '_' . $q ;
                    $q++ ;
                    }
                my $class = ref $self ;
                local $options -> {disable} = $control -> {disables}[$i] ;
                my $subform = $class -> sub_new ($subcontrols, $options, $ctlid, 0, $self -> {formptr}) ;
                $subform -> {text} ||= $control -> {options}[$i] if (exists ($control -> {options}) && $control -> {options}[$i]) ;
                $subform -> {parent_control} = $control ;
                push @ids, $ctlid ;
                push @obj, $subform ;
                $i++ ;
                }
            $control -> {subobjects} = \@obj ;
            $control -> {subids}     = \@ids ;
            }
        $n++ ;
        }
    }

# ---------------------------------------------------------------------------
#
#   parent_form - return parent form object if any
#

sub parent_form
    {
    my ($self) = @_ ;

    return $Embperl::FormData::forms{$self -> {parentptr}} ;
    }



# ---------------------------------------------------------------------------
#
#   add_code_at_bottom - add js code at the bottom of the page
#

sub add_code_at_bottom

    {
    my ($self, $code) = @_ ;

    push @{$self->{bottom_code}}, $code ;
    }


# ---------------------------------------------------------------------------
#
#   layout - build the layout of the form
#

sub layout

    {
    my ($self, $controls, $level) = @_ ;

    $controls ||= $self -> {controls} ;
    $level    ||= 1 ;

    my $hidden = $self -> {hidden} ||= [] ;

    my $x     = 0 ;
    my $max_x = 100 ;
    my $line  = [] ;
    my @lines ;
    my $max_num = 0 ;
    my $num = 0 ;
    my $last_state ;
    foreach my $control (@$controls)
        {
        next if ($control -> is_disabled ()) ;
	if ($control -> is_hidden)
	    {
	    $control -> {width_percent} = 0 ;
            push @$hidden, $control  ;
	    next ;
            }
        my $width = ($control -> {width} eq 'expand')?100:$control -> {width_percent} || int($max_x / ($control -> {width} || 2)) ;
        #$width = 21 if ($x == 0 && $width < 21) ;
        if ($x + $width > $max_x || $control -> {newline} > 0 || (($control -> {sublines} || $control -> {subobjects}) && @$line))
            { # new line
            if ($x < $max_x)
                {
                push @$line, Embperl::Form::Control::blank -> new (
                        {width_percent => int($max_x - $x), level => $level, x_percent => int($x), state => $last_state }) ;
                }
            push @lines, $line ;
            $line = [] ;
            $x    = 0 ;
            $num  = 0 ;
            }
        push @$line, $control  ;
        $last_state = $control -> {state} ;
        $control -> {width_percent} = $control -> {width} eq 'expand'?'expand':int($width) ;
        $control -> {x_percent}     = int($x) ;
	$control -> {level}         = $level ;
        $x += $width ;
        $num++ ;
        $max_num = $num if ($num > $max_num) ;
        if ($control -> {subobjects} || $control -> {sublines} || $control -> {newline} < 0)
            { # new line
            if ($x < $max_x)
                {
                push @$line, Embperl::Form::Control::blank -> new (
                        {width_percent => int($max_x - $x), level => $level, x_percent => int($x), state => $last_state }) ;
                $num++ ;
                $max_num = $num if ($num > $max_num) ;
                }
            push @lines, $line ;
            $line = [] ;
            $x    = 0 ;
            $num  = 0 ;
            }

        if ($control -> {sublines})
            {
            foreach my $subcontrols (@{$control -> {sublines}})
                {
                next if (!$subcontrols) ;
                my $sublines = $self -> layout ($subcontrols, $level + 1) ;
                push @lines, @$sublines ;
                }
            }
        if ($control -> {subobjects})
            {
            my @obj ;
            foreach my $subobj (@{$control -> {subobjects}})
                {
                next if (!$subobj) ;
                $subobj -> layout ;
		push @$hidden, @{$subobj -> {hidden}} ;
	        delete $subobj -> {hidden} ;
                }
            }
        }

    if ($x > 0 && $x < $max_x)
                {
                push @$line, Embperl::Form::Control::blank -> new (
                        {width_percent => int($max_x - $x), level => $level, x_percent => int($x), state => $last_state  }) ;
                $num++ ;
                $max_num = $num if ($num > $max_num) ;
                }
    push @lines, $line if (@$line);
    $self -> {max_num} = $max_num ;
    return $self -> {layout} = \@lines ;
    }


# ---------------------------------------------------------------------------
#
#   show_controls - output the form control area
#

sub show_controls

    {
    my ($self, $req, $activeid, $options) = @_ ;

    if ($self -> {toplevel})
        {
        $req -> {form_options_masks} = ($options && $options -> {masks}) || {} ;
        $req -> {uuid} ||= $form_cnt++ ;
        @{$self -> {fields2empty}} = () ;
        }
    my $lines = $self -> {layout} ;
    my %n ;
    my $activesubid ;
    my @activesubid ;

    $self -> show_controls_begin ($req, $activeid) ;
    my $lineno = 0 ;
    foreach my $line (@$lines)
        {
        my $linelevel = @$line?$line->[0]{level}:0 ;
        my $lineid    = @$line && $line->[0]{parentid}?"$line->[0]{parentid}":'id' ;
        $n{$lineid} ||= 10 ;
        my $visible = $self -> show_line_begin ($req, $lineno, "$lineid-$n{$lineid}", $activesubid[$linelevel-1] || $activeid);
        foreach my $control (@$line)
            {
#            my $newactivesubid = $control -> {subobjects} && $visible?$control -> get_active_id ($req):'-' ;
            my $newactivesubid = ($control -> {subobjects} || $control -> {sublines}) && $visible?$control -> get_active_id ($req):'' ;
            $control -> show ($req) if (!$control -> is_disabled ($req)) ;
            $activesubid[$control -> {level}] = $newactivesubid if ($newactivesubid) ;
            if ($control -> {subobjects})
                {
                my @obj ;
                $control -> show_sub_begin ($req) ;
                foreach my $subobj (@{$control -> {subobjects}})
                    {

                    next if (!$subobj || !$subobj -> {controls} || !@{$subobj -> {controls}} || $subobj -> is_disabled ($req)) ;

                    $subobj -> show ($req, $activesubid[$control -> {level}]) ;
                    }
                $control -> show_sub_end ($req) ;
                }
            }
        $self -> show_line_end ($req, $lineno);
        $lineno++ ;
        $n{$lineid}++ ;
        }
    $self -> show_controls_end ($req) ;
    $self -> show_controls_hidden ($req) if ($self -> {hidden}) ;
    $self -> show_checkitems ($req) if ($self -> {checkitems} && $self -> {toplevel}) ;

    return ;
    }

# ---------------------------------------------------------------------------
#
#   init_validate - init validate functions
#

sub init_validate

    {
    my ($self, $req, $options) = @_ ;

    if ($self -> {toplevel})
        {
        my $epf = $self -> {validate} ;
        if (!defined ($epf))
            {
            my @validate_rules ;
            foreach my $control (@{$self -> {do_validate}})
                {
                push @validate_rules, $control -> get_validate_rules ($req) ;
                }
            if (@validate_rules)
                {
                $epf = $self -> {validate} = Embperl::Form::Validate -> new (\@validate_rules, $self -> {formname}, $options -> {language}, $options -> {charset})  ;
                $self -> add_code_at_bottom ($epf -> get_script_code) ;
                }
            else
                {
                $self -> {validate}  = 0 ;    
                }
            }
        }
    
    return $self -> {validate}?1:0 ;    
    }

# ---------------------------------------------------------------------------
#
#   show - output the form
#

sub show

    {
    my ($self, $req, $activeid, $options) = @_ ;

    if ($self -> {toplevel})
        {
        $self -> init_validate ($req, $options) ;
        $self -> init_data ($req) ;
        $self -> show_form_begin ($req) ;
        }
    
    #$self -> validate ($req) if ($self -> {toplevel});
    $self -> show_controls ($req, $activeid, $options) ;
    $self -> show_form_end  ($req) if ($self -> {toplevel});
    }


# ---------------------------------------------------------------------------
#
#   init_data - init fdat before showing
#

sub init_data

    {
    my ($self, $req, $options) = @_ ;

    if ($self -> {toplevel} && $options)
        {
        $req -> {form_options_masks} = ($options && $options -> {masks}) || {} ;
        }
    foreach my $control (@{$self -> {init_data}})
        {
        $control -> init_data ($req) if (!$control -> is_disabled ($req)) ;
        }
    }

# ---------------------------------------------------------------------------
#
#   init_markup - add any dynamic markup to the form data
#

sub init_markup

    {
    my ($self, $req, $parentctl, $method, $options) = @_ ;

    if ($self -> {toplevel} && $options)
        {
        $req -> {form_options_masks} = ($options && $options -> {masks}) || {} ;
        }
    foreach my $control (@{$self -> {init_markup}})
        {
        $control -> init_markup ($req, $parentctl, $method)  if (!$control -> is_disabled ($req)) ;
        }
    }

# ---------------------------------------------------------------------------
#
#   prepare_fdat - change fdat after submit
#

sub prepare_fdat

    {
    my ($self, $req, $options) = @_ ;

    if ($self -> {toplevel} && $options)
        {
        $req -> {form_options_masks} = ($options && $options -> {masks}) || {} ;
        }
    foreach my $control (@{$self -> {prepare_fdat}})
        {
        $control -> prepare_fdat ($req)  if (!$control -> is_disabled ($req)) ;
        }
    }
    
# ---------------------------------------------------------------------------
#
#   is_disabled - do not display this control at all
#

sub is_disabled

    {
    my ($self, $req) = @_ ;

    my $disable = $self -> {disable}  ;

    $disable = &{$disable}($self, $req) if (ref ($disable) eq 'CODE') ;

    return $disable ;
    }


# ---------------------------------------------------------------------------
#
#   has_code_refs - returns true if is_readonly or is_disabled are coderefs
#

sub has_code_refs

    {
    my ($self, $req) = @_ ;

    return  ref ($self -> {disable}) eq 'CODE'  ;
    }


# ---------------------------------------------------------------------------
#
#   code_ref_fingerprint - returns fingerprint of is_disabled
#

sub code_ref_fingerprint

    {
    my ($self, $req) = @_ ;

    return  ($self -> is_disabled($req)?'D':'E') ;
    }


# ---------------------------------------------------------------------------
#
#   all_code_ref_fingerprints - returns a fingerprint of the result of all code refs
#                           can be used to check if is_readonly or is_disabled
#                           has dynamicly changed
#

sub all_code_ref_fingerprints

    {
    my ($self, $req) = @_ ;

    my $fp ;
    foreach my $control (@{$self -> {code_refs}})
        {
        $fp .= $control -> code_ref_fingerprint ($req) ;
        }
    return $fp ;    
    }

# ---------------------------------------------------------------------------
#
#   constrain_attrs - returns attrs that might change the form layout
#                     if there value changes
#

sub constrain_attrs

    {
    my ($self, $req) = @_ ;

    return $self -> {constrain_attrs} ;
    }


# ---------------------------------------------------------------------------
#
#   validate - validate the form input
#

sub validate

    {
    my ($self, $fdat, $pref, $epreq) = @_ ;
    
    my $validate = $self -> {validate} ;
    my $result = $validate -> validate ($fdat, $pref, $epreq) ;
    my @msgs ;
    foreach my $err (@$result)
        {
        my $msg = $validate -> error_message ($err, $pref, $epreq) ;
        push @msgs, $msg ;    
        }

    return ($result, \@msgs) ;    
    }


#------------------------------------------------------------------------------------------
#
#   add_tabs
#
#   fügt ein tab element mit subforms zu einem Formular hinzu
#   wird nur eine Subform übergeben, werden nur diese Felder zurückgeliefert
#	ohne tabs
#
#   in $subform     array mit hashs
#                       text => <anzeige text>
#                       fn   => Dateiname
#                       fields => Felddefinitionen (alternativ zu fn)
#      $args	    wird an fields funktionen durchgereicht
#      $tabs_per_line    anzahl tabs pro Zeile
#

sub add_tabs

    {
    my ($self, $subforms, $args, $tabs_per_line) = @_ ;
    my @forms ;
    my @values ;
    my @options ;
    my @grids;
    $args ||= {} ;

    foreach my $file (@$subforms)
        {
        my $fn        = $file -> {fn} ;
        my $subfields = $file -> {fields} ;

        push @options, $file -> {text};
        if ($fn)
            {
            my $obj = Execute ({object => $fn} ) ;
            $subfields = $obj -> fields ($epreq, {%$file, %$args}) ;
            }
        push @forms,  $subfields;
        push @grids,  $file -> {grid};
        push @values, $file -> {value} ||= scalar(@forms);
        }

    if (@forms == 1)
	{
	return @{$forms[0]} ;
	}

    return {
            section => 'cSectionText',
            name    => '__auswahl',
            type    => 'tabs',
            values  => \@values,
            grids   => \@grids,
            options => \@options,
            subforms=> \@forms,
            width   => 1,
            'tabs_per_line' => $tabs_per_line,
            },
    }

#------------------------------------------------------------------------------------------
#
#   add_line
#
#   adds the given controls into one line
#
#

sub add_line

    {
    my ($self, $controls, $cnt) = @_ ;

    $cnt ||= @$controls ;
    foreach my $control (@$controls)
        {
        $control -> {width} = $cnt ;
        }

    return @$controls ;
    }

#------------------------------------------------------------------------------------------
#
#   add_sublines
#
#   fügt ein tab elsement mit subforms zu einem Formular hinzu
#
#   in $subform     array mit hashs
#                       text => <anzeige text>
#                       fn   => Dateiname
#                       fields => Felddefinitionen (alternativ zu fn)
#


sub add_sublines
    {
    my ($self, $object_data, $subforms, $type) = @_;

    $object_data ||= {} ;
    $object_data -> {text} ||= $object_data -> {name} ;

    my @forms ;
    my @values ;
    my @options ;

    foreach my $file (@$subforms)
        {
        my $fn        = $file -> {fn} ;
        my $subfields = $file -> {fields} ;
        if ($fn)
            {
            my $obj = Execute ({object => "$fn"} ) ;
            $subfields = $obj -> fields ($epreq, $file) ;
            }
        $subfields ||= [] ;
        foreach (@$subfields)
            {
            $_ -> {state} = $object_data -> {name} . '-show-' .  ($file->{value} || $file->{name}) ;   
            }
        push @forms, $subfields  ;
        push @values,  $file->{value} || $file->{name};
        push @options, $file -> {text} || $file->{value} || $file->{name};
        }
    $object_data -> {trigger} = 1 ;
    return { %$object_data, type => $type || 'select',
             values => \@values, options => \@options, sublines => \@forms,
	     };

    }

#------------------------------------------------------------------------------------------
#
#   fields_add_checkbox_subform
#
#   fügt ein checkbox Element mit Subforms hinzu
#
#   in $subform     array mit hashs
#                       text => <anzeige text>
#                       name => <name des Attributes>
#                       value => <Wert der checkbox>
#                       fn   => Dateiname
#                       fields => Felddefinitionen (alternativ zu fn)
#

sub add_checkbox_subform
    {
    my ($self, $subform, $args) = @_ ;
    $args ||= {} ;

    my $name    = $subform->{name};
    my $text    = $subform->{text};
    my $value   = $subform->{value} || 1 ;

    my $width   = $subform->{width};
    my $section;

    if(! $subform->{nosection})
        {
        $section = $subform->{section};
        $section ||= 1;
        }

    $name   ||= "__$value";
    $width  ||= 1;

    my $subfield;
    my $fn;
    if($subfield = $subform->{fields})
        {
        # .... ok
        }
    elsif($fn = $subform->{fn})
        {
        my $obj = Execute ({object => "./$fn"} ) ;
        #$subfield = [eval {$obj -> fields ($r, { %$file, %$args} ) || undef}];
        }
    
    my $subfields = $subfield -> [0] ;
    foreach (@$subfields)
        {
        $_ -> {state} = $subform -> {name} . '-show' ;   
        }
    $subfields = $subfield -> [1] ;
    foreach (@$subfields)
        {
        $_ -> {state} = $subform -> {name} . '-hide';   
        }
        
    return  {type => 'checkbox' , trigger => 1, section => $section, width => $width, name => $name, text => $text, value => $value, sublines => $subfield}

    }

#------------------------------------------------------------------------------------------
#
#   convert_label
#
#   converts the label of a control to the text that should be outputed.
#   By default does return the text or name parameter of the control.
#   Can be overwritten to allow for example internationalization.
#
#   in $ctrl        Embperl::Form::Control object
#      $name        optional: name to translate, if not given take $ctrl -> {text}
#

sub convert_label
    {
    my ($self, $ctrl, $name, $text, $req) = @_ ;
    
    return $text || $ctrl->{text} || $name || $ctrl->{name} ;
    }

#------------------------------------------------------------------------------------------
#
#   convert_options
#
#   converts the values/options of a control to the text that should be outputed.
#   By default does nothing.
#   Can be overwritten to allow for example internationalization.
#
#   in  $ctrl        Embperl::Form::Control object
#       $values     values of the control i.e. values that are submitted
#       $options    options of the control i.e. text that should be displayed
#

sub convert_options
    {
    my ($self, $ctrl, $values, $options, $req) = @_ ;
    
    return $options ;
    }

#------------------------------------------------------------------------------------------
#
#   convert_text
#
#   converts the text of a controls like transparent to the text that should be outputed.
#   By default does nothing.
#   Can be overwritten to allow for example internationalization.
#
#   in  $ctrl        Embperl::Form::Control object
#       $value       value that is shown
#

sub convert_text
    {
    my ($self, $ctrl, $value, $text, $req) = @_ ;
    
    return $value || $ctrl->{text} || $ctrl->{name} ;
    }


#------------------------------------------------------------------------------------------
#
#   diff_checkitems
#
#   Takes the posted form data and the checkitems, compares them and return the
#   fields that have changed
#
#   in  $check  optional: arrayref with fieldnames that should be checked
#   ret \%diff  fields that have changed
#

sub diff_checkitems
    {
    my ($self, $check) = @_ ;
    
    my %diff ;
    my $checkitems = eval { Storable::thaw(MIME::Base64::decode ($Embperl::fdat{-checkitems})) } ;

    foreach ($check?@$check:keys %Embperl::fdat)
        {
        next if ($_ eq '-checkitems') ;
        $diff{$_} = 1 if ($checkitems -> {$_} ne $Embperl::fdat{$_}) ;
        }

    return \%diff ;    
    }


1;


__EMBPERL__

[$syntax EmbperlBlocks $]

[# ---------------------------------------------------------------------------
#
#   show_form_begin - output begin of form
#]

[$ sub show_form_begin ($self, $req) $]
<script language="javascript">var doValidate = 1 ;</script>
<script src="/js/EmbperlForm.js"></script>
<script src="/js/TableCtrl.js"></script>

<form id="[+ $self->{formname} +]" name="[+ $self->{formname} +]" method="post" action="[+ $self->{actionurl}+]"
[$ if ($self -> {on_submit_function}) $]
onSubmit="s=[+ $self->{on_submit_function} +];if (s) { v=doValidate; doValidate=1; return ((!v) || epform_validate_[+ $self->{formname} +]()); } else { return false; }"
[$else$]
onSubmit="v=doValidate; doValidate=1; return ( (!v) || epform_validate_[+ $self->{formname}+]());"
[$endif$]
>
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_form_end - output end of form
#]

[$ sub show_form_end ($req) $]
</form>
[$endsub$]

[ ---------------------------------------------------------------------------
#
#   show_controls_begin - output begin of form controls area
#]

[$ sub show_controls_begin  ($self, $req, $activeid)

my $parent = $self -> parent_form ;
my $class  = $self -> {options}{classdiv} || ($parent -> {noframe}?'ef-tabs-border-u':'ef-tabs-border') ;
my $parent_control = $self -> {parent_control} ;
$]

[$if $parent_control && $parent_control -> can('show_subform_controls_begin') $]
[- $parent_control -> show_subform_controls_begin ($self, $req, $activeid) -]
[$else$]
<div  id="[+ $self -> {unique_id} +]_[+ $self->{id} +]" class="ef-tabs-content"
[$if ($activeid && $self->{id} ne $activeid) $] style="display: none" [$endif$]
>
[$if (!$self -> {noframe}) $]<table class="[+ $class +]"><tr><td class="ef-tabs-content-cell"> [$endif$]
[$endif$]
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_controls_end - output end of form controls area
#]

[$sub show_controls_end ($self, $req)
 my $parent_control = $self -> {parent_control} ;
$]
[$if $parent_control && $parent_control -> can('show_subform_controls_end') $]
[- $parent_control -> show_subform_controls_end ($self, $req) -]
[$else$]
[$ if (!$self -> {noframe}) $]</td></tr></table> [$endif$]
</div>
[$endif$]

[$ if (@{$self->{bottom_code}}) $]
<script language="javascript">
[+ do { local $escmode = 0; join ("\n", @{$self->{bottom_code}}) } +]
</script>
[$endif$]
[$ if ($self -> {toplevel} && @{$self -> {fields2empty}}) $]
<input type="hidden" name="-fields2empty" value="[+ join (' ', @{$self -> {fields2empty}}) +]">
[$endif$]
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_controls_hidden - output hidden controls and the end of form
#]

[$sub show_controls_hidden ($self, $req) $]

[$ foreach my $ctl (@{$self->{hidden}}) $]
[- $ctl -> show ($req) ; -]
[$ endforeach $]

[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_checkitems - output data to allow verifying if any data has changed
#]

[$sub show_checkitems ($self, $req)
 
my $checkitems = MIME::Base64::encode (Storable::freeze (\%idat)) ; 
$]
<input type="hidden" name="-checkitems" value="[+ $checkitems +]">

[$endsub$]


[# ---------------------------------------------------------------------------
#
#   show_line_begin - output begin of line
#]

[$ sub show_line_begin ($self, $req, $lineno, $id, $activeid)

    my $baseid ;
    my $baseidn ;
    my $baseaid ;
    my $baseaidn ;
    if ($id =~ /^(.+)-(\d+?)-(\d+?)$/)
        {
        $baseid = $1 ;
        $baseidn = $2 ;
        }
    if ($activeid =~ /^(.+)-(\d+?)$/)
        {
        $baseaid = $1 ;
        $baseaidn = $2 ;
        }

    my $class = $lineno == 0?'cTableRow1':'cTableRow' ;
$]<!-- line begin -->
   [# <tr class="[+ $class +]" valign="[+ $self->{valign} +]"
    [$if $id $] id="[+ $id +]" [$endif$]
    [$if ($activeid eq '-' || ($baseid eq $baseaid && $baseidn != $baseaidn)) $] style="display: none" [$endif$]
    >
    #][* return !($activeid eq '-' || ($baseid eq $baseaid && $baseidn != $baseaidn)) 
*][$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_line_end - output end of line
#]

[$ sub show_line_end ($req) $]<!-- line end -->[$endsub$]


__END__

=pod

=head1 NAME

Embperl::Form - Embperl Form class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new ($controls, $options)

=over 4

=item * $controls

Array ref with controls which should be displayed
inside the form. Each control needs either to be a
hashref with all parameters for the control or
a control object.

If hash refs are given it's necessary to specify
the C<type> parameter, to let Embperl::Form
know which control to create.

See Embperl::Form::Control and Embperl::Form::Control::*
for a list of available parameters.

=item * $options

Hash ref which can take the following parameters:

=over 4

=item * formname

Will be used as name and id attribute of the form. If you have more
then one form on a page it's necessary to have different form names
to make form validation work correctly.

=item * masks

Contains a hash ref which can specify a set of masks
for the controls. A mask is a set of parameter which
overwrite the setting of a control. You can specify
a mask for a control name (key is name), for a control
type (key is *type) or for all controls (key is *).

Example:

    {
    'info'      => { readonly => 1},
    '*textarea' => { cols => 80 },
    '*'         => { labelclass => 'myclass', labelnowrap => 1}
    }

This will force the control with the name C<info> to be readonly, it
will force all C<textarea> controls to have 80 columns and
it will force the label of all controls to have a class of myclass
and not to wrap the text.

=item * defaults

Contains a hash ref which can specify a set of defaults
for the controls. You can specify
a default for a control name (key is name), for a control
type (key is *type) or for all controls (key is *).

Example:

    {
    'info'      => { readonly => 1},
    '*textarea' => { cols => 80 },
    '*'         => { labelclass => 'myclass', labelnowrap => 1}
    }

This will make the control with the name C<info> to default to be readonly, it
will default all C<textarea> controls to have 80 columns and
it will set the default class for the labels of all controls to
myclass and not to wrap the text.

=item * language

Language setting is used for Embperl::Form::Validate, e.g. 'en' or 'de'

=item * charset

Charset setting is used for Embperl::Form::Validate, e.g. 'utf-8'

=item * valign

valign for control cells. Defaults to 'top' .

=item * jsnamespace

Give the JavaScript Namespace. This allows one to load js files in
a top frame or different frame, which will speed up page loading,
because the browser does not need to reload the js code on every load.

Example:

    jsnamespace => 'top'

=item * classdiv

Gives the CSS class of the DIV arround the form. Default cTableDiv.

=item * checkitems

If set to true, allow to call the function diff_checkitems after the data is
posted and see which form fields are changed.

=item * control_packages

Arrayref with package names to search for form controls. Alternativly you can
overwrite the method get_control_packages.

=item * datasrc_packages

Arrayref with package names to search for form data source modules. Alternativly you can
overwrite the method get_datasrc_packages.


=back

=back

=head2 layout

=head2 validate

=head2 show

=head2 convert_label

Converts the label of a control to the text that should be outputed.
By default does return the text or name parameter of the control.
Can be overwritten to allow for example internationalization.

=over

=item $ctrl

Embperl::Form::Control object

=item $name

optional: name to translate, if not given take $ctrl -> {name}

=back

=head2 convert_text

Converts the text of a control to the text that should be outputed.
By default does return the text or name parameter of the control.
Can be overwritten to allow for example internationalization.

=over

=item $ctrl

Embperl::Form::Control object

=back

=head2 convert_options

Converts the values of a control to the text that should be outputed.
By default does nothing.
Can be overwritten to allow for example internationalization.

=over

=item $ctrl

Embperl::Form::Control object

=item $values

values of the control i.e. values that are submitted

=item $options

options of the control i.e. text that should be displayed

=back

=head1 AUTHOR

G. Richter (richter at embperl dot org)

=head1 SEE ALSO

perl(1), Embperl, Embperl::Form::Control





