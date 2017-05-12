# -*- perl -*-
#
#   HTML::EP	- A Perl based HTML extension.
#
#
#   Copyright (C) 1998              Jochen Wiedmann
#                                   Am Eisteich 9
#                                   72555 Metzingen
#                                   Germany
#
#                                   Email: joe@ispsoft.de
#
#
#   Portions Copyright (C) 1999	    OnTV Pittsburgh, L.P.
#			  	    123 University St.
#			  	    Pittsburgh, PA 15213
#			  	    USA
#
#			  	    Phone: 1 412 681 5230
#			  	    Developer: Jason McMullan <jmcc@ontv.com>
#			            Developer: Erin Glendenning <erg@ontv.com>
#
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

use HTML::Parser ();


package HTML::EP::Parser;

$HTML::EP::Parser::VERSION = '0.01';
@HTML::EP::Parser::ISA = qw(HTML::Parser);


sub new {
    my $self = shift->SUPER::new(@_);
    $self->{'_ep_tokens'} = [];
    $self->{'_ep_text'} = undef;
    $self;
}

sub declaration {
    my($self, $decl) = @_;
    $self->text("<!$decl>");
}

sub start {
    my($self, $tag, $attr, $attrseq, $origtext) = @_;
    return $self->text($origtext) unless $tag =~ /^ep-/;
    push(@{$self->{'_ep_tokens'}},
	 {'type' => 'S',
	  'tag' => $tag,
	  'attr' => $attr,
	  'attrseq' => $attrseq,
	  'origtext' => $origtext});
    $self->{'_ep_text'} = undef;
}

sub end {
    my($self, $tag, $origtext) = @_;
    return $self->text($origtext) unless $tag =~ /^ep-/;
    push(@{$self->{'_ep_tokens'}},
	 {'type' => 'E', 'tag' => $tag, 'origtext' => $origtext});
    $self->{'_ep_text'} = undef;
}

sub text {
    my($self, $text) = @_;
    if (my $t = $self->{'_ep_text'}) {
	$t->{'text'} .= $text;
    } else {
	push(@{$self->{'_ep_tokens'}},
	     ($self->{'_ep_text'} = {'type' => 'T', 'text' => $text}));
    }
}

sub comment {
    my($self, $comment) = @_;
    $self->text("<!--$comment-->");
}


package HTML::EP::Tokens;

sub new {
    my $proto = shift;
    my $self = { (@_ == 1) ? %{shift()} :  @_ };
    die "Missing token array"              unless exists $self->{'tokens'};
    $self->{'first'} = 0                   unless exists $self->{'first'};
    $self->{'last'} = @{$self->{'tokens'}} unless exists $self->{'last'};
    bless($self, (ref($proto) || $proto));
}

sub Clone {
    my($proto, $first, $last) = @_;
    my $self = {%$proto};
    $self->{'first'} = $first if defined $first;
    $self->{'last'} = $last if defined $first;
    bless($self, ref($proto));    
}

sub First {
    my $self = shift;
    if (@_) { $self->{'first'} = shift() } else { $self->{'first'} }
}
sub Last {
    my $self = shift;
    if (@_) { $self->{'last'} = shift() } else { $self->{'last'} }
}
sub Token {
    my $self = shift();
    my $first = $self->{'first'};
    return undef if $first >= $self->{'last'};
    $self->{'first'} = $first+1;
    $self->{'tokens'}->[$first];
}
sub Replace {
    my($self, $index, $token) = @_;
    $self->{'tokens'}->[$index] = $token;
}

1;
