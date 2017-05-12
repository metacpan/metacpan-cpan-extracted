# -------------------------------------------------------------------------------------
# MKDoc::XML::Stripper
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This module removes user-defined markup from an existing XML file / variable.
#
# This module is distributed under the same license as Perl itself.
# -------------------------------------------------------------------------------------
package MKDoc::XML::Stripper;
use MKDoc::XML::Tokenizer;
use File::Spec;
use strict;
use warnings;


##
# $class->new();
# --------------
# Returns a new MKDoc::XML::Stripper object.
##
sub new
{
    my $class = shift;
    my $self  = bless { @_ }, $class;
    return $self;
}


sub load_def
{
    my $self = shift;
    my $file = shift;
    
    $file =~ /\// and return $self->_load_def ($file);
    $file =~ /\./ and return $self->_load_def ($file);
    
    $file .= '.txt';
    for (@INC)
    {
	my $path = File::Spec->catfile ($_, qw /MKDoc XML Stripper/, $file);
	-e $path and -f $path and return $self->_load_def ($path);
    }
    
    warn "Cannot read-open $file. Reason: Doesn't seem to be anywhere in \@INC";
}


sub _load_def
{
    my $self = shift;
    my $file = shift;
    
    open FP, "<$file" || do {
	warn "Cannot read-open $file. Reason: $!";
	return;
    };

    # clean $self 
    for (keys %{$self}) { delete $self->{$_} }
    while (<FP>) {
	chomp();
	s/\#.*$//;
	s/^\s*//;
	s/\s*$//;
	next unless ($_ ne '');
	
	my @l = split /\s+/, $_;
	$self->allow (@l);
    }
    
    close FP;
}


##
# $self->allow ($tag, @attributes);
# ---------------------------------
# Allows the tag $tag to be present along with a list of attributes,
# i.e.
#
# $self->allow (qw /p class id/);
##
sub allow
{
    my $self = shift;
    my $tag  = shift;
    $self->{$tag} ||= {};
    for (@_) { $self->{$tag}->{$_} = 1 };
}


##
# $self->disallow ($tag, @attributes);
# ------------------------------------
# Disallows the tag $tag to be present.
##
sub disallow
{
    my $self = shift;
    my $tag  = shift;
    delete $self->{$tag};
}


##
# $self->process_data ($data);
# ----------------------------
# Strips tags on $data and returns the stripped result.
##
sub process_data
{
    my $self   = shift;
    my $data   = shift;
    my $tokens = MKDoc::XML::Tokenizer->process_data ($data);
    my @result = map { $self->strip ($_) } @{$tokens};
    return join '', map { $$_ } @result;
}


##
# $self->process_file ($file);
# ----------------------------
# Strips tags on $file and returns the stripped result.
##
sub process_file
{
    my $self   = shift;
    my $file   = shift;
    my $tokens = MKDoc::XML::Tokenizer->process_file ($file);
    my @result = map { $self->strip ($_) } @{$tokens};
    return join '', map { $$_ } @result;
}


##
# $self->strip ($token);
# ----------------------
# Returns this token stripped out of the stuff which we don't want.
# Returns an empty list if the token is not allowed.
##
sub strip
{
    my $self  = shift;
    my $token = shift;
    my $node  = $token->tag();
    defined $node || return $token;
    
    my $tag = $node->{_tag};
    return unless ( $self->{$tag} );
    
    for (keys %{$node})
    {
	/^_/ and next;
	delete $node->{$_} unless $self->{$tag}->{$_};
    }
    
    return new MKDoc::XML::Token ( _node_to_tag ($node) );
}


sub _node_to_tag
{
    my $node  = shift;
    my $tag   = $node->{_tag};
    my $open  = $node->{_open};
    my $close = $node->{_close};
    my %attr  = map { /^_/ ? () : ($_ => $node->{$_}) } keys %{$node};
    my $attr  = join ' ', map {
	my $key = $_;
	my $val = $attr{$key};
	($val =~ /\"/) ? "$key='$val'" : "$key=\"$val\""
    } keys %attr;
    
    my $res = '<';
    $res .= '/'  if ($close and not $open);
    $res .= $tag;
    $res .= " $attr" if ($attr and $open);
    $res .= ' /' if ($open and $close);
    $res .= '>';
    return $res;
}


1;


__END__


=head1 NAME

MKDoc::XML::Stripper - Remove unwanted XML / XHTML tags and attributes


=head1 SYNOPSIS

  use MKDoc::XML::Stripper;

  my $stripper = new MKDoc::XML::Stripper;
  $stripper->allow (qw /p class id/);

  my $ugly = '<p class="para" style="color:red">Hello, <strong>World</strong>!</p>';
  my $neat = $stripper->process_data ($ugly);
  print $neat;

Should print:

  <p class="para">Hello, World!</p>


=head1 SUMMARY

MKDoc::XML::Stripper is a class which lets you specify a set of tags and attributes
which you want to allow, and then cheekily strip any XML of unwanted tags and attributes.

In MKDoc, this is used so that editors use structural XHTML rather than presentational tags,
i.e. strip anything which looks like a <font> tag, a 'style' attribute or other tags
which would break separation of structure from content.


=head1 DISCLAIMER

B<This module does low level XML manipulation. It will somehow parse even broken XML
and try to do something with it. Do not use it unless you know what you're doing.>


=head1 API


=head2 my $stripper = MKDoc::XML::Stripper->new()

Instantiates a new MKDoc::XML::Stripper object.


=head2 $stripper->load_def ($def_name);

Loads a definition located somewhere in @INC under MKDoc/XML/Stripper.

Available definitions are:

=over

=item xhtml10frameset

=item xhtml10strict

=item xhtml10transitional

=item mkdoc16 - MKDoc 1.6. XHTML structural markup

=back

You can also load your own definition file, for instance:

  $stripper->load_def ('my_def.txt');

Definitions are simple text files as follows:

  # allow p with 'class' and id
  p class
  p id

  # allow more stuff
  td class
  td id
  td style  

  # etc...

=head2 $stripper->allow ($tag, @attributes)

Allows "<$tag>" to appear in the stripped XML. Additionally, allows
@attributes to appear as attributes of <$tag>, so for instance:

  $stripper->allow ('p', 'class', 'id');

Will allow the following:

  <p>
  <p class="foo">
  <p id="bar">
  <p class="foo" id="bar">

However any extra attributes will be stripped, i.e.

  <p class="foo" id="bar" style="font-color: red">

Will be rewritten as

  <p class="foo" id="bar">


=head2 $stripper->disallow ($tag)

Explicitly disallows a tag and all its associated attributes.
By default everything is disallowed.


=head2 $stripper->process_data ($some_xml);

Strips $some_xml according to the rules that were given with the
allow() and disallow() methods and returns the result. Does not
modify $some_xml in place.


=head2 $stripper->process_file ('/an/xml/file.xml');

Strips '/an/xml/file.xml' according to the rules that were given with the
allow() and disallow() methods and returns the result. Does not
modify '/an/xml/file.xml' in place.


=head1 NOTES

L<MKDoc::XML::Stripper> does not really parse the XML file you're giving to it
nor does it care if the XML is well-formed or not. It uses L<MKDoc::XML::Tokenizer>
to turn the XML / XHTML file into a series of L<MKDoc::XML::Token> objects
and strictly operates on a list of tokens.

For this same reason MKDoc::XML::Stripper does not support namespaces.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::Tokenizer>
L<MKDoc::XML::Token>


=cut
