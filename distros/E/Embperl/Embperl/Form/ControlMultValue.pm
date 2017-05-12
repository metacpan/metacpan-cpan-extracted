
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

package Embperl::Form::ControlMultValue ;

use strict ;
use vars qw{%fdat} ;

use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

# ---------------------------------------------------------------------------
#
#   init - Init the new control
#


sub init

    {
    my ($self) = @_ ;

    if ($self -> {datasrc})
        {
        my $name = $self -> {datasrc} ;
        $name =~ s/[#\/].+$// ;
        my $form = $self -> form ;
        my $packages = $form -> get_datasrc_packages ;
        $self -> {datasrcobj} = $form -> new_object ($packages, $name, $self, { datarsc => $self -> {datasrc}}) ;
        }

    $self -> SUPER::init ;

    return $self ;
    }

# ---------------------------------------------------------------------------
#
#   constrain_attrs - returns attrs that might change the form layout
#                     if there value changes
#

sub constrain_attrs

    {
    my ($self, $req) = @_ ;

    return if (!$self -> {datasrcobj}) ;
        
    return $self -> {datasrcobj} -> constrain_attrs ($req) ;
    }

# ---------------------------------------------------------------------------
#
#   get_all_values - returns all values and options, including addtop and addbottom
#

sub get_all_values

    {
    my ($self, $req) = @_ ;

    my $key = "all_values:$self" ;
    my $v ;
    return @$v if ($v = $req -> {$key}) ;

    my $addtop = $self -> {addtop} ;
    my $addbottom = $self -> {addbottom} ;

    my $values ;
    my $options ;
    my $nocache = 0 ;
    
    if ($self -> {datasrcobj})
        {
        my $key = "all_values_datasrc:$self->{datasrcobj}" ;
        if (my $v = $req -> {$key})
            {
            ($values, $options) = @$v ;
            }
        else
            {
            ($values, $options) = $self -> {datasrcobj} -> get_values ($req, $self)  ;
            $options ||= $values ;
            $nocache = $self -> {datasrcobj} -> values_no_cache ;
            $req -> {$key} = [$values, $options] if (!$nocache) ;
            }
        }
    else
        {
        $values  = $self -> {values} ;    
        $options = $self -> {options} || $values ;
        $options = $self -> form -> convert_options ($self, $self -> {values}, $options, $req)
            if (!$self -> {showoptions}) ;
        }
 
    if (!$addtop && !$addbottom)
        {
        $req -> {$key} = [$values, $options] ;
        return ($values, $options) 
        }
    my @values ;
    my @options ;    
    if ($addtop)
        {
        push @values,  map { ref $_?$_ -> [0]:$_ } @$addtop ;
        push @options, map { ref $_?$_ -> [1]:$_ } @$addtop ;
        }
        
    if ($values)
        {
        if ($addtop && $values -> [0] eq '' && $options -> [0] eq '---')
            {
            push @values, @{$values}[1..$#$values] ;
            push @options, @{$options}[1..$#$options]  ;
            }
        else
            {
            push @values, @$values ;
            push @options, @$options  ;
            }
        }
        
    if ($addbottom)
        {
        push @values, map { $_ -> [0] } @$addbottom ;
        push @options, map { $_ -> [1] } @$addbottom ;
        }

    $req -> {$key} = [\@values, \@options] if (!$nocache) ;
    return (\@values, \@options) ;
    }

# ---------------------------------------------------------------------------
#
#   get_values - returns values and options, possibly filter applied
#

sub get_values

    {
    my ($self, $req) = @_ ;

    
    my ($values, $options) = $self -> get_all_values ($req) ;
    my $filter = $self -> {filter} ;
    return ($values, $options) if (!$filter) ;

    my @values ;
    my @options ;
    my $i = 0 ;
    foreach (@$values)
        {
        if (/$filter/)
            {
            push @values, $_ ;
            push @options, $options -> [$i] ;
            }
        $i++ ;
        }
    return (\@values, \@options) ;
    }
        

# ---------------------------------------------------------------------------
#
#   get_datasource_controls - returns additional controls provided by the
#   datasource object e.g. a browse button
#

sub get_datasource_controls

    {
    my ($self, $req) = @_ ;

    return $self -> {datasrcobj} -> get_datasource_controls ($req, $self) if ($self -> {datasrcobj}) ;
    return ;
    }

# ---------------------------------------------------------------------------
#
#   get_id_from_value - returns id for a given value
#

sub get_id_from_value

    {
    my ($self, $value) = @_ ;

    return if (!$self -> {datasrcobj}) ;
    return $self -> {datasrcobj} -> get_id_from_value ($value) ;
    }

# ---------------------------------------------------------------------------
#
#   get_option_form_value - returns the option for a given value
#
#   in  $value  value
#   ret         option
#

sub get_option_from_value

    {
    my ($self, $value, $req) = @_ ;
    
    my $addtop = $self -> {addtop} ;
    if ($addtop)
        {
        foreach (@$addtop)
            {
            if ($_ -> [0] eq $value)
                {
                return $_ -> [1] ;
                }
            }
        }    

    if ($self->{datasrc})
        {
        my $option = $self -> {datasrcobj} -> get_option_from_value ($value, $req, $self) ;
    
        return $option if (defined ($option)) ;
        }
    elsif (ref $self -> {values})
        {
        my $i = 0 ;
        foreach (@{$self -> {values}})
            {
            if ($_ eq $value)
                {
                my $options = [$self -> {options}[$i] || $value] ;
                $options = $self -> form -> convert_options ($self, [$value], $options, $req)
                    if (!$self -> {showoptions}) ;
                return $options -> [0] ;
                }
            $i++ ;
            }
        }

    my $addbottom = $self -> {addbottom} ;
    if ($addbottom)
        {
        foreach (@$addbottom)
            {
            if ($_ -> [0] eq $value)
                {
                return $_ -> [1] ;
                }
            }
        }    

    return ;
    }

# ---------------------------------------------------------------------------
#
#   get_active_id - get the id of the value which is currently active
#

sub get_active_id

    {
    my ($self, $req)   = @_ ;

    my $key = "active_id:$self" ;
    my $id ;
    return $id if ($id = $req -> {$key}) ;

    my ($values, $options) = $self -> get_values ($req) ;
    my $name     = $self -> {name} ;
    my $dataval  = $fdat{$name} || $values -> [0] ;
    my $activeid ;

    my $i = 0 ;
    foreach my $val (@$values)
        {
        if ($val eq $dataval)
            {
            $activeid = "$name-$i" ;
            last ;
            }
        $i++ ;
        }

    return $req -> {$key} = $activeid ;
    }

# ---------------------------------------------------------------------------
#
#   is_with_id - returns true if the control shows something that has an internal id
#

sub is_with_id

    {
    my ($self, $req) = @_ ;

    return 1 ;
    }
    
# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $value) = @_ ;

    $value = $self -> get_value ($req) if (!defined ($value)) ;
    $value = $self -> get_option_from_value ($value, $req) ;

    return $value ;
    }
    
# ---------------------------------------------------------------------------
#
#   init_markup - add any dynamic markup to the form data
#

sub init_markup

    {
    my ($self, $req, $parentctl, $method) = @_ ;

    return if (!$self -> is_readonly($req) && (! $parentctl || ! $parentctl -> is_readonly($req))) ;
    
    my $val = $self -> get_value ($req) ;
    if ($val ne '')
        {
        my $name = $self -> {name} ;
        my $fdat = $req -> {docdata} || \%Embperl::fdat ;
        $fdat -> {'_opt_' . $name} = $self -> get_option_from_value ($val, $req) ;
        $fdat -> {'_id_' .  $name} = $self -> get_id_from_value ($val, $req) ;
        }
    }
    
1 ;

# damit %fdat etc definiert ist
__EMBPERL__


[# ---------------------------------------------------------------------------
#
#   show_control_readonly - output the control as readonly
#]

[$ sub show_control_readonly ($self, $req, $value) 

my $text  = $self -> get_display_text ($req, $value)  ;
my $id    = $self -> get_id_from_value ($val, $req) ; 
my $name  = $self -> {force_name} || $self -> {name} ;
$]
<div [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, '', 'readonly', 'ef-control-with-id') } +] _ef_divname="_opt_[+ $name +]">[+ $text +]</div>
[$ if $self->{hidden} $]
<input type="hidden" name="[+ $name +]" value="[+ $value +]">
[$endif$]
<input type="hidden" name="_id_[+ $name +]" value="[+ $id +]">
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_control_addons - output additional things after the control
#]

[$ sub show_control_addons ($self, $req)
 
my $datasrc_ctrls  ;
$datasrc_ctrls = $self -> get_datasource_controls ($req)
    unless ($self -> {no_datasource_controls}) ;

$][$if $datasrc_ctrls $]
[$foreach my $ctrl (@$datasrc_ctrls) $]
<a class="cControlAddonA" href="[+ $ctrl->{href} +]" onClick="[+ $ctrl->{onclick} +]">[$if $ctrl -> {icon} $]<img class="cControlAddonImg" src="[+ $ctrl -> {icon} +]" title="[+ $ctrl -> {text} +]" alt="[+ $ctrl -> {text} +]">[$else$][+ $ctrl -> {text} +][$endif$]</a>
[$endforeach$]
[$endif$]
[$endsub$]


__END__

=pod

=head1 NAME

Embperl::Form::ControlMultValue - Base class for controls inside
an Embperl Form which have multiple values to select from, like
a select box or radio buttons.


=head1 SYNOPSIS

Do not use directly, instead derive a class

=head1 DESCRIPTION

This class is not used directly, it is used as a base class for
all controls which have multiple values to select from inside
an Embperl Form. It provides a set of methods
that could be overwritten to customize the behaviour of your controls.

=head1 METHODS

=head2 get_values

returns the values and options

=head2 get_datasource_controls

returns additional controls provided by the
datasource object e.g. a browse button

=head2 get_active_id

get the id of the value which is currently active

=head1 PARAMETERS

=head3 values

Arrayref with the values to select from. This is what gets
submited back to the server.

=head3 options

Arrayref with the options to select from. This is what the user sees.

=head3 datasrc

Name of an class which provides the values for the
values and options parameters. Either a full package name or
a name, in which case all packages which are returned
by Embperl::Form::get_datasrc_packages are searched.
Everything after '#' is ignored and can be used by the
DataSource module to do further selections.

=head3 no_datasource_controls

Disables the output of the additional controls

=head1 AUTHOR

G. Richter (richter at embperl dot org)

=head1 SEE ALSO

perl(1), Embperl, Embperl::Form, Embperl::From::Control, Embperl::Form::DataSource

