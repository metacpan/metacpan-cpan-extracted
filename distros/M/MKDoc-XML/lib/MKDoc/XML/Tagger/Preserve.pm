# -------------------------------------------------------------------------------------
# MKDoc::XML::Tagger::Preserve
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This module uses MKDoc::XML::Tagger, except it preserves specific tags to prevent
# them from being tagged twice. At the moment the module uses regexes to do that so it
# might not be very generic but it should at least work for XHTML <a> tags.
# -------------------------------------------------------------------------------------
package MKDoc::XML::Tagger::Preserve;
use MKDoc::XML::Tagger;
use strict;
use warnings;
use utf8;

our @Preserve = ();


##
# $class->process_data ($xml, @expressions);
# ------------------------------------------
# Tags $xml with @expressions, where expression is a list of hashes.
#
# For example:
#
# MKDoc::XML::Tagger::Preserve->process (
#     [ 'i_will_be_preserved', 'a' ],
#     'I like oranges and bananas',
#     { _expr => 'oranges', _tag => 'a', href => 'http://www.google.com?q=oranges' },
#     { _expr => 'bananas', _tag => 'a', href => 'http://www.google.com?q=bananas' },
#
# Will return
#
# 'I like <a href="http://www.google.com?q=oranges">oranges</a> and \
# <a href="http://www.google.com?q=bananas">bananas</a>.
##
sub process_data
{
    my $class = shift;
    local @Preserve = @{shift()};
    my $text  = shift;
    my @list  = ();


    ($text, @list) = _preserve_encode ($text);
    $text          = MKDoc::XML::Tagger->process_data ($text, @_);
    $text          = _preserve_decode ($text, @list);

    return $text;
}


sub process_file
{
    my $class = shift;
    my $file  = shift;
    open FP, "<$file" || do {
        warn "Cannot read-open $file";
        return [];
    };
    
    my $data = '';
    while (<FP>) { $data .= $_ }
    close FP;
    
    return $class->process_data ($data);
}


sub _preserve_encode
{
    my $text = shift;
    my @list = ();
    for my $tag (@Preserve)
    {
        my @tags = $text =~ /(<$tag\s.*?<\/$tag>)/gs;
        for my $tag (@tags) { while ($text =~ s/\Q$tag\E/_compute_unique_string ($text, $tag, \@list)/e) {} }
    }
    
    return $text, @list;
}


sub _preserve_decode
{
    my $text = shift; 
    my @tsil = reverse (@_);
    
    while (@tsil)
    {
        my $val = shift (@tsil);
        my $id  = shift (@tsil);
        $text =~ s/$id/$val/; 
    }
    
    return $text;
}


sub _compute_unique_string
{
    my $text = shift;
    my $str  = shift;
    my $list = shift;
    my $id   = join '', map { chr (ord ('a') + int (rand (26))) } 1..10;
    while ($text =~ /\Q$id\E/)
    {
        $id = join '', map { chr (ord ('a') + int (rand (26))) } 1..10;
    }
    
    push @{$list}, $id => $str;
    return $id;
}


1;


__END__
