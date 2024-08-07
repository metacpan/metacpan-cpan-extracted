
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2015 Gerald Richter
#   Embperl - Copyright (c) 2015-2023 actevy.io
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

package Embperl::Form::Control::datetime ;

use strict ;
use base 'Embperl::Form::Control::number' ;

use Embperl::Inline ;
use POSIX qw(strftime);
use Time::Local qw(timelocal_nocheck timegm_nocheck);
use Date::Calc qw{Delta_DHMS Add_Delta_Days} ;

use vars qw{%fdat} ;

our $tz_local = (timegm_nocheck(localtime())-time())/60;


# ---------------------------------------------------------------------------
#
#   init - init the new control
#

sub init

    {
    my ($self) = @_ ;

    $self->{unit}      ||= '' ;

    
    return $self ;
    }
    
# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $time) = @_ ;
    
    $time = $self -> get_value ($req) if (!defined ($time)) ;
    return $time if ($self -> {format} eq '-' || ($time =~ /\./)) ;
    return if ($time eq '' && !exists $self -> {onempty}) ;

    if ($self -> {dynamic} && ($time =~ /^\s*((?:s|i|h|d|w|m|y|q)(?:\+|-)?(?:\d+)?)\s*/))
        {
        return $time ;#$1 ;
        }
    

    my ($y, $m, $d, $h, $min, $s, $z) ;

    if ($self -> {onempty})
        {
        ($s,$min,$h,$d,$m,$y) = localtime ;
        $m++ ;
        $y += 1900 ;
        if ($self -> {onempty} eq 'b')
            { 
            $h = $min = $s = 0 ;
            }
        elsif ($self -> {onempty} eq 'e')
            { 
            $h   = 23 ;
            $min = 59 ;
            $s   = 59 ;
            }
        }
    else
        {
        ($y, $m, $d, $h, $min, $s, $z) = (($time . '00000000000000Z') =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(.)/) ;
        }

    my $date ;
    if ($time =~ /^(\d\d\d\d)-(\d+)$/)
        {
        $date = $time ;    
        }
    elsif ($d == 0 && $m == 0)
        {
        $date = $y ;    
        }
    elsif ($d == 0)
        {
        $date = "$m.$y" ;    
        }
    else
        {
        # Getting the local timezone

        $date = eval
            {
            my @time = gmtime(timegm_nocheck($s,$min,$h,$d,$m-1,$y-1900)+($tz_local*60));

            my $format = $self -> {notime} || ($s == 0 && $h == 0 && $min == 0)?'%d.%m.%Y':'%d.%m.%Y, %H:%M' ;
            $format = '%d.%m.%Y, %H:%M:%S' if ($self -> {fulltime}) ;
            strftime ($format, @time[0..5]) ;
            } ;
        }

    if ($time && !$date && ($time =~ /\d+\.\d+\.\d+/))
        {
        $date = $time ;
        }

    return $date ;
    }


# ------------------------------------------------------------------------------------------
#
#   get_sort_value - returns the value that should be used to sort
#

sub get_sort_value
    {
    my ($self, $req, $value) = @_ ;
    
    $value = $self -> get_value ($req) if (!defined ($value)) ;
    return $value ;
    }
    
# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req, $parentctrl, $force) = @_ ;

    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name    = $self->{name} ;
    my $time    = $fdat->{$name} ;

    return if (($time eq '' && !exists $self -> {onempty}) || $self -> {format} eq '-' || ($req -> {"ef_datetime_init_done_$name"} && !$force)) ;

    $fdat->{$name} = $self -> get_display_text ($req, $time) ;
    $req -> {"ef_datetime_init_done_$name"} = 1 ;
    }

# ---------------------------------------------------------------------------
#
#   init_markup - add any dynamic markup to the form data
#

sub init_markup

    {
    my ($self, $req, $parentctl, $method) = @_ ;

    return if (!$self -> is_readonly($req) && (! $parentctl || ! $parentctl -> is_readonly($req))) ;
    
    return $self -> init_data ($req, $parentctl) ;
    }


# ---------------------------------------------------------------------------
#
#   str2time
#

sub str2time

    {
    my ($date) = @_ ;

    my ($year, $mon, $day, $hour, $min, $sec) ;
    if ($date eq '*' || $date eq '.')
        {
        my $offset ||= 0 ;
        ($sec, $min, $hour, $day, $mon, $year) = gmtime (time + $offset) ;
        $year += 1900 ;
        $mon++ ;
        }
    else
        {
        $date =~ tr/,;/  / ;
        my ($d, $t) = split (/\s+/, $date) ;
        if ($d =~ /:/)
	    {
	    $t = $d ;
 	    $d = '' ;
	    }
        ($day, $mon, $year) = map { $_ + 0 } split (/\./, $d) ;
        ($hour, $min, $sec) = map { $_ + 0 } split (/\:/, $t) ;

        if ($year == 0 || $mon == 0 || $day == 0)
            {
            my ($s, $min, $h, $md, $m, $y) = localtime ;

            $day  ||= $md ;
            $mon  ||= $m + 1;
            $year ||= $y + 1900 ;
            }

        if ($year < 70)
            {
            $year += 2000 ;
            }
        elsif ($year >= 70 && $year < 100)
            {
            $year += 1900 ;
            }
        if ($year < 1907)
            {
            $year = $year % 100 + 2000 ;
            }

        ($year,$mon,$day, $hour,$min,$sec) =
             Date::Calc::Add_Delta_DHMS($year,$mon,$day, $hour,$min,$sec,
                            0, 0, -$tz_local, 0) if ($hour || $min || $sec) ;
        }

    return $year?sprintf ('%04d%02d%02d%02d%02d%02dZ', $year, $mon, $day, $hour, $min, $sec):'' ;
    }


# ------------------------------------------------------------------------------------------
#
#   prepare_fdat - daten zusammenfuehren
#

sub prepare_fdat
    {
    my ($self, $req) = @_ ;

    return if ($self -> is_readonly ($req) || $self -> {format} eq '-') ;
    
    my $fdat  = $req -> {form} || \%fdat ;
    my $name    = $self->{name} ;
    return if (!exists $fdat->{$name}) ;
    my $date    = $fdat -> {$name} ;
    return if ($date eq '') ;

    if ($self -> {dynamic} && ($date =~ /^\s*((?:s|i|h|d|w|m|y|q)\s*(?:\+|-)?\s*(?:\d+)?)\s*/))
        {
        $fdat->{$name} = $date ; #$1 ;
        $fdat->{$name} =~ s/\s//g ;
        return ;
        }
    
    
    $fdat -> {$name} = str2time ($date) ;
    }

# ---------------------------------------------------------------------------
#
#   get_validate_auto_rules - get rules for validation, in case user did
#                             not specify any
#

sub get_validate_auto_rules
    {
    my ($self, $req) = @_ ;
    
    return [ $self -> {required}?(required => 1):(emptyok => 1), -type => 'DateTime' ] ;
    }

1 ;

__EMBPERL__


[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self)

$self -> {size} ||= 80 / ($self -> {width} || 2) ;
my $class = $self -> {class} ||= '' ;
my $fullid   = $req -> {uuid} . '_' . $self ->{id} ;
$]

<input type="text" name="[+ $self -> {force_name} || $self -> {name} +]"  [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, $fullid) } +]
[$if $self -> {size} $]size="[+ $self->{size} +]"[$endif$]
[$if $self -> {maxlength} $]maxlength="[+ $self->{maxlength} +]"[$endif$]
_ef_attach="ef_datetime" _ef_dynamic="[+ $self -> {dynamic}?'true':'' +]"
>
[#
<script type="text/javascript">
    $('#[+ $fullid +]').datepicker ({ showWeek: true,
                                    [$if $self -> {dynamic} $]constrainInput: false, [$endif$]
                                    showButtonPanel: true
                                    }) ;
</script>
#]

[$endsub$]


__END__

=pod

=head1 NAME

Embperl::Form::Control::price - A price input control with optional unit inside an Embperl Form


=head1 SYNOPSIS

  {
  type => 'price',
  text => 'blabla',
  name => 'foo',
  unit => 'sec',
  }

=head1 DESCRIPTION

Used to create a datetime input control inside an Embperl Form.
Will format number as a date/time.
See Embperl::Form on how to specify parameters.

Datetime format in %fdat is expected as YYYYMMTTHHMMSSZ

=head2 PARAMETER

=head3 type

Needs to be 'datetime'

=head3 name

Specifies the name of the control

=head3 text

Will be used as label for the numeric input control

=head3 size

Gives the size in characters. (Default: 10)

=head3 notime

does not display time

=head3 dynamic

allows the following values to be entered:

d, m, y, d-N, d+N, m-N, m+N, y-N, y+N

N is any number. This values are simply passed through and need
to be process somewhere else.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


