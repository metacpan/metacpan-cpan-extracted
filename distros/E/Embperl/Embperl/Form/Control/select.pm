
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

package Embperl::Form::Control::select ;

use strict ;
use vars qw{%fdat $escmode} ;
use base 'Embperl::Form::ControlMultValue' ;

use Embperl::Inline ;
#use HTML::Escape qw/escape_html/ ;

sub escape_html
    {
    my $v = shift ;
    $v =~ s/&/&amp;/g ;
    $v =~ s/"/&quot;/g ;
    $v =~ s/>/&gt;/g ;
    $v =~ s/</&lt;/g ;
    return $v ;
    }

sub show_control
    {
    my ($self, $req, $filter) = @_ ;

push @{$req -> {timing}}, ([Time::HiRes::gettimeofday()], 'start show_control ' . $self->{name} . ' ' . __FILE__ . '#' . __LINE__) if ($req -> {timing});
    
    my $name     = $self -> {name} ;
    my $fdat     = $req -> {docdata} || \%Embperl::fdat ;
    my $value    = $fdat -> {$name} ;
    $Embperl::idat{$name} = $value ;
    $filter      ||= $self -> {filter} ;
    my $nsprefix = $self -> form -> {jsnamespace} ;
    my $val ;
    my $i = 0 ;
    my ($values, $options) = $self -> get_all_values ($req) ;
    my ($ctlattrs, $ctlid, $ctlname) =  $self -> get_std_control_attr($req) ;
    $values ||= [] ;

    my $multiple = $self->{multiple}?'multiple':'' ;
    my @opt ;
    my $out = '<select name="' .escape_html ($ctlname) . '" ' . $ctlattrs ;
    $out .= ' size="' . escape_html ($self->{rows}) . '" ' if ($self->{rows}) ;
    $out .= ' _ef_attach="ef_select" ' if ($self -> {trigger}) ;
    push @{$req -> {timing}}, ([Time::HiRes::gettimeofday()], 'start show_control4 ' . $self->{name} . ' value: ' . scalar(@$values) . ' : ' . __FILE__ . '#' . __LINE__) if ($req -> {timing});
    my $i = 0 ; 
    my $escval ;
    my $escopt ;
    my $selected ;
    foreach $val (@$values)
        {
        $escval = escape_html ($val) ;
        $escopt = escape_html ($options ->[$i])  ;
        $selected = $val eq $value?'selected':'' ;
        push @opt, qq{<option value="$escval" $selected>} . ($escopt) . q{</option>} if (!defined ($filter) || ($val =~ /$filter/i)) ;
        $i++ ;
        }
    $out .= ">\n" . join ("\n", @opt) . "\n" . '</select>' . "\n" ;

    local $escmode = 0 ;
    print OUT $out ;

push @{$req -> {timing}}, ([Time::HiRes::gettimeofday()], 'end show_control ' . $self->{name} . ' ' . __FILE__ . '#' . __LINE__) if ($req -> {timing});

    }
    
1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_hidden - out hidden field
#]

[$ sub show_hidden ($self, $req) $]
<input type="hidden" name="[+ $self -> {name} +]">
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub xshow_control ($self, $req, $filter)

    my $name     = $self -> {name} ;
    $filter      ||= $self -> {filter} ;
    my $nsprefix = $self -> form -> {jsnamespace} ;
    my $val ;
    my $i = 0 ;
push @{$req -> {timing}}, ([Time::HiRes::gettimeofday], 'start show_control ' . $self->{name} . ' ' . __FILE__ . '#' . __LINE__) if ($req -> {timing});
    my ($values, $options) = $self -> get_all_values ($req) ;
push @{$req -> {timing}}, ([Time::HiRes::gettimeofday], 'start show_control2 ' . $self->{name} . ' ' . __FILE__ . '#' . __LINE__) if ($req -> {timing});
    my ($ctlattrs, $ctlid, $ctlname) =  $self -> get_std_control_attr($req) ;
push @{$req -> {timing}}, ([Time::HiRes::gettimeofday], 'start show_control3 ' . $self->{name} . ' ' . __FILE__ . '#' . __LINE__) if ($req -> {timing});
    $values ||= [] ;
$]
<select name="[+ $ctlname +]" [+ $self->{multiple}?'multiple':''+] [+ do { local $escmode = 0 ; $ctlattrs } +] 
[$if ($self -> {rows}) $] size="[+ $self->{rows} +]" [$endif$]
[$if ($self -> {trigger}) $]_ef_attach="ef_select"[$endif$]
>
[-
push @{$req -> {timing}}, ([Time::HiRes::gettimeofday], 'start show_control4 ' . $self->{name} . ' value: ' . scalar(@$values) . ' : ' . __FILE__ . '#' . __LINE__) if ($req -> {timing});
-]
[* $i = 0 ; *]
[$ foreach $val (@$values) $]
    [$if !defined ($filter) || ($val =~ /$filter/i) $]
    <option value="[+ $val +]">[+ $options ->[$i] || $val +]</option>
    [$endif$]
    [* $i++ ; *]
[$endforeach$]
</select>
[-
push @{$req -> {timing}}, ([Time::HiRes::gettimeofday], 'end show_control3 ' . $self->{name} . ' ' . __FILE__ . '#' . __LINE__) if ($req -> {timing});
-]
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::select - A select control inside an Embperl Form


=head1 SYNOPSIS

  {
  type    => 'select',
  text    => 'blabla',
  name    => 'foo',
  values  => [1,2,3],
  options => ['foo', 'bar', 'none'],
  rows    => 5
  }

=head1 DESCRIPTION

Used to create an select control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'select'

=head3 name

Specifies the name of the select control

=head3 text

Will be used as label for the select control

=head3 values

Gives the values as an array ref of the select control.

=head3 options

Gives the options as an array ref that should be displayed to the user.
If no options are given, the values from values are used.

=head3 rows

If specified a select box is display with the given number of lines.
If not specified or undef, a drop down list is shown.

=head3 addtop

Array ref which contains items that should be added at the top
of the select box. Each item consists of an array ref with two
entries, the first is the value and the second is the option
that is displayed on the page. If the second is missing the
value (first entry)is displayed. Example:

    addtop => [ [1 => 'first item'], [2 => 'second item']]

=head3 addbottom

Array ref which contains items that should be added at the bottom
of the select box. Each item consists of an array ref with two
entries, the first is the value and the second is the option
that is displayed on the page. If the second is missing the
value (first entry)is displayed. Example:

    addbottom => [ [9999 => 'last item'], [9999 => 'very last item']]

=head3 filter

If given, only items where the value matches the regex given in
C<filter> are displayed.

=head3 multiple

If set to true, allows multiple selections.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


