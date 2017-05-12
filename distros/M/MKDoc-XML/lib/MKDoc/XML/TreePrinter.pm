# -------------------------------------------------------------------------------------
# MKDoc::XML::TreePrinter
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This module is the counterpart of MKDoc::XML::TreePrinter. It turns an XML
# tree back into a string.
#
# This module is distributed under the same license as Perl itself.
# -------------------------------------------------------------------------------------
package MKDoc::XML::TreePrinter;
use warnings;
use strict;


##
# $class->process (@nodes);
# ----------------------------
# Does the stuff.
##
sub process
{
    my $class  = shift;
    my @nodes  = @_;
    my @res = ();
    
    foreach my $node (@nodes)
    {
        ref $node or do {
            push @res, $node;
            next;
        };

        $node->{_tag} =~ /\~pi/ and do {
            push @res, "<?$node->{text}?>";
            next;
        };

        $node->{_tag} =~ /\~declaration/ and do {
            push @res, "<!$node->{text}>";
            next;
        };

        $node->{_tag} =~ /\~comment/ and do {
            push @res, "<!--" . $node->{text} . "-->";
            next;
        };

        my $tag   = $node->{_tag};
        my %att   = map { $_ => _encode_quot ($node->{$_}) } grep !/^_/, keys %{$node};
        my $attr  = join " ", map { "$_=\"$att{$_}\"" } keys %att;
        my $open  = $node->{_open};
        my $close = $node->{_close};
        
        $open && $close && do {
            if ($attr) { push @res, "<$tag $attr />" }
            else       { push @res, "<$tag />"       }
            next;
        };
        
        my $open_tag  = $attr ? "<$tag $attr>" : "<$tag>";
        my $close_tag = "</$tag>";
        my @desc      = $node->{_content} ? @{$node->{_content}} : ();
        
        my $res = $open_tag . $class->process (@desc) . $close_tag;
        push @res, $res;
        next;
    };

    return join '', @res;
}


sub _encode_quot
{
    my $res = shift;
    return '' unless (defined $res);

    $res =~ s/\"/\&quot\;/g;
    return $res;
}


1;


__END__


=head1 NAME

MKDoc::XML::TreePrinter - Builds XML data from a parsed tree


=head1 SYNOPSIS

  my $xml_data = MKDoc::XML::TreePrinter->process_data (@top_nodes);


=head1 SUMMARY

L<MKDoc::XML::TreePrinter> takes trees which are produced by
L<MKDoc::XML::TreeBuilder> to turn a parsed tree back into XML data. This means
you can parse some stuff using L<MKDoc::TreeBuilder>, fiddle around with the
tree, and then get the result back as XML data. 


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::TreeBuilder>

=cut
