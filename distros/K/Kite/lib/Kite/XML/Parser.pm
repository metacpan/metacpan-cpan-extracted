#============================================================= -*-perl-*-
#
# Kite::XML::Parser
#
# DESCRIPTION
#   XML parser for kite related XML markup.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# VERSION 
#   $Id: Parser.pm,v 1.1 2000/10/17 11:58:16 abw Exp $
#
#========================================================================
 
package Kite::XML::Parser;

require 5.004;

use strict;
use XML::Parser;
use Kite::Base;
use base qw( Kite::Base );
use vars qw( $VERSION $DEBUG $AUTOLOAD $NODEBASE $NODEPKG );

$VERSION  = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG    = 0 unless defined $DEBUG;
$NODEBASE = 'Kite::XML::Node';
$NODEPKG  = {
    kite  => "$NODEBASE\::Kite",
};


#------------------------------------------------------------------------
# new(@xml_parser_args)
# 
# Constructor method which returns an XML::Parser instance.
#------------------------------------------------------------------------

sub new {
    my $self = shift;
    return XML::Parser->new(@_, Handlers => {
	Init  => \&xml_init,
	Start => \&xml_start,
	Char  => \&xml_char,
	End   => \&xml_end,
	Final => \&xml_final,
    });
}

#------------------------------------------------------------------------
# xml_init($expat)
#
# Called at start of parse.  Initialises element stack.
#------------------------------------------------------------------------

sub xml_init {
    my $expat = shift;
    $expat->{ STACK } = [];
    debug("init\n") if $DEBUG;
    return 1;
}

#------------------------------------------------------------------------
# xml_start($expat, element, @attributes)
#
# Called on each element start tag.  Instantiates new node elements and
# pushes it onto the stack.
#------------------------------------------------------------------------

sub xml_start {
    my ($expat, $element, @attr) = @_;
    my $stack = $expat->{ STACK };
    my $top   = $stack->[-1];
    my ($factory, $node);

    if ($top) {
	$node = $top->child($element, @attr)
	    || die($top->error(), " at line ", 
		   $expat->current_line(), "\n");
    }
    else {
	# determine package name
	my $pkg = $NODEPKG->{ $element }
	    || die("invalid element '$element' at line ",
		   $expat->current_line(), "\n");

	# load module
	my $mod = $pkg;
	$mod =~ s/::/\//g;
	$mod .= '.pm';
	require $mod;

	# instantiate node
	$node = $pkg->new(@attr)
	    || die ($pkg->error(), " at line ",
		    $expat->current_line(), "\n");
    }
    push(@$stack, $node);
}

#------------------------------------------------------------------------
# xml_char($expat, $text)
#
# Called when character data is encountered.  Calls the char() method
# on the element node on top of the stack.
#------------------------------------------------------------------------

sub xml_char {
    my ($expat, $text) = @_;
    my $stack = $expat->{ STACK };
    my $top = $stack->[-1];
    $top->char($text)
	|| die ($top->error(), " at line ", $expat->current_line, "\n");
}

#------------------------------------------------------------------------
# xml_end($expat, element)
#
# Called on each element end tag.  Pops the top element node off the 
# stack, saving it in RESULT if it's the last item.
#------------------------------------------------------------------------

sub xml_end {
    my ($expat, $element) = @_;
    my $stack = $expat->{ STACK };

    my $node = pop(@$stack);
    $expat->{ RESULT } = $node
	unless @$stack;
}

#------------------------------------------------------------------------
# xml_final($expat)
#
# Called at end of parse.  Returns RESULT.
#------------------------------------------------------------------------

sub xml_final {
    my $expat = shift;
    return $expat->{ RESULT };
}


1;

__END__
	

=head1 NAME

Kite::XML::Parser - XML parser for kite related markup

=head1 SYNOPSIS

    package Kite::XML::Parser;

    my $parser = Kite::XML::Parser->new();
    my $kite   = $parser->parsefile($filename);

=head1 DESCRIPTION

This is a simple stack based parser built around the XML::Parser module.
It parses XML text and instantiates Kite::XML::Node::* objects as it 
identifies various elements in the markup.  These are automatically 
constructed into a tree (a.k.a 'grove').  A node object representing 
the root object is returned.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 REVISION

$Revision: 1.1 $

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also <Kite::XML::Node> and <Kite::XML::Node::Kite>

=cut


