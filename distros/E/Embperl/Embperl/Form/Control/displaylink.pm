
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

package Embperl::Form::Control::displaylink ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

# ---------------------------------------------------------------------------
#
#   show_control_readonly - output readonly control
#

sub show_control_readonly
    {
    my ($self, $req) = @_ ;

    $self -> show_control ($req) ;
    }

1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req)

my $name     = $self->{name};
my $hrefs    = $self -> {href} ;
my $targets  = $self -> {target} ;
my $opens    = $self -> {open} ;
my $displays = $self -> {link} || $self -> {value} ;
my $form     = $self -> form ;
my $showoptions = $self -> {showoptions} ;
my $state    = $self -> {state} ;

$hrefs     = [$hrefs] if (!ref $hrefs) ;
$targets   = [$targets] if ($targets && !ref $targets) ;
$opens     = [$opens] if ($opens && !ref $opens) ;
$displays  = [$displays] if (!ref $displays) ;


@hrefs = map { my $x = $_ ;    $x =~ s/%%%name%%%/$epreq->Escape ($fdat{$name},6)/eg ; $x =~ s/%%(.+?)%%/$epreq->Escape ($fdat{$1}, 6)/eg ; $x } ref ($hrefs)?@$hrefs:($hrefs) ;
@opens = map { my $x = $_ ;    $x =~ s/%%%name%%%/$epreq->Escape ($fdat{$name},6)/eg ; $x =~ s/%%(.+?)%%/$epreq->Escape ($fdat{$1}, 6)/eg ; $x } ref ($opens)?@$opens:($opens) ;
@displays = map { my $x = $_ ; $x =~ s/%%%name%%%/$fdat{$name}/g ; $x =~ s/%%(.+?)%%/$fdat{$1}/eg ; $x } @$displays ;

my $dispn = 0 ;
$]
<div [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, '', 'readonly') } +]>
[$ foreach $display (@displays) $]
    [$if $opens[$dispn] $]
        <a href="#" class="[+ $state +]" onclick="if (this.className.search('ef-disabled') == -1) [+ $opens[$dispn] +][$if $hrefs[$dispn] $]('[+ $hrefs[$dispn] +]')[$endif$]" [+ do { local $escmode = 0 ; $self -> {eventattrs} } +]>
    [$else$]
        <a href="[+ do {local $escmode=0;$hrefs[$dispn]} +]" class="[+ $state +]"
	    [$if $targets -> [$dispn] $]target="[+ $targets -> [$dispn] +]"[$endif$]
             [+ do { local $escmode = 0 ; $self -> {eventattrs} } +]>
    [$endif$][$ if $showoptions < 0 $][+ do { local $escmode = 0 ; $display } +][$else$][+ $showoptions?$display:$form -> convert_text ($self, $display, undef, $req) +][$endif$]</a>&nbsp;
    [- $dispn++ -]
[$endforeach$]
</div>
__END__

=pod

=head1 NAME

Embperl::Form::Control::displaylink - A control to display links inside an Embperl Form


=head1 SYNOPSIS

  { 
  type   => 'displaylink',
  text   => 'blabla', 
  link   => ['ecos', 'bb5000'],
  href   => ['http://www.ecos.de', 'http://www.bb5000.info']  
  }

=head1 DESCRIPTION

Used to create a control which displays links inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be set to 'displaylink'.

=head3 text 

Will be used as label for the text display control.

=head3 link

Arrayref with texts for the links that should be shown to the user

=head3 href

Arrayref with hrefs

%%<name>%% is replaced by $fdat{<name>} 

=head3 open

Arrayref, if a value is given for the link, the value will be used as
javascript function which is executed onclick. href will be pass as
argument.

%%<name>%% is replaced by $fdat{<name>} 

=head3 target

Arrayref with targets

=head3 showtext

If set the texts from the link parameter will not be passed thru convert_text

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


