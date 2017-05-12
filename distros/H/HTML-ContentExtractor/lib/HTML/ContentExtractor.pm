package HTML::ContentExtractor;

=head1 NAME

HTML::ContentExtractor - extract the main content from a web page by analysising the DOM tree!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use HTML::ContentExtractor;
    my $extractor = HTML::ContentExtractor->new();
    my $agent=LWP::UserAgent->new;

    my $url='http://sports.sina.com.cn/g/2007-03-23/16572821174.shtml';
    my $res=$agent->get($url);
    my $HTML = $res->decoded_content();

    $extractor->extract($url,$HTML);
    print $extractor->as_html();
    print $extractor->as_text();

=head1 DESCRIPTION

Web pages often contain clutter (such as ads, unnecessary images and
extraneous links) around the body of an article that distracts a user
from actual content. This module is used to reduce the noise content
in web pages and thus identify the content rich regions.


A web page is first parsed by an HTML parser, which corrects the
markup and creates a DOM (Document Object Model) tree. By using a
depth-first traversal to navigate the DOM tree, noise nodes are
identified and removed, thus the main content is extracted. Some
useless nodes (script, style, etc.) are removed; the container nodes
(table, div, etc.) which have high link/text ratio (higher than
threshold) are removed; (link/text ratio is the ratio of the number of
links and non-linked words.) The nodes contain any string in the
predefined spam string list are removed.


Please notice the input HTML should be encoded in utf-8 format( so do
the spam words), thus the module can handle web pages in any language
(I've used it to process English, Chinese, and Japanese web pages).

=over 4

=item $e = HTML::ContentExtractor->new(%options);

Constructs a new C<HTML::ContentExtractor> object. The optional
%options hash can be used to set the options list below.

=item $e->table_tags();

=item $e->table_tags(@tags);

=item $e->table_tags(\@tags);

This is used to get/set the table tags array. The tags are used as the
container tags.

=item $e->ignore_tags();

=item $e->ignore_tags(@tags);

=item $e->ignore_tags(\@tags);

This is used to get/set the ignore tags array. The elements of such
tags will be removed.

=item $e->spam_words();

=item $e->spam_words(@strings);

=item $e->spam_words(\@strings);

This is used to get/set the spam words list. The elements have such
string will be removed.

=item $e->link_text_ratio();

=item $e->link_text_ratio($ratio);

This is used to get/set the link/text ratio, default is 0.05.

=item $e->min_text_len();

=item $e->min_text_len($len);

This is used to get/set the min text length, default is 20. If length
of the text of an elment is less than this value, this element will be
removed.

=item $e->extract($url,$HTML);

This is used to perform the extraction process. Please notice the
input $HTML must be encoded in UTF-8. 

=item $e->as_html();

Return the extraction result in HTML format.

=item $e->as_text();

Return the extraction result in text format.

=back


=head1 AUTHOR

Zhang Jun, C<< <jzhang533 at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Zhang Jun, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use strict;
use warnings;
use HTML::TreeBuilder;

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;

    my $self = {};
    bless($self, $class);

    return $self->_init(@_);
}

sub _init{
    my $self = shift;

    $self->{table_tags} = [qw(table form div td tr tbody thead tfoot th col colgroup span iframe center ul h1 h2 h3 p)];
    $self->{ignore_tags} = [qw(script noscript style form button meta input select iframe embed hr img)];
    $self->{spam_words} = ['All rights reserved'];
    $self->{link_text_ratio} = 0.05;
    $self->{min_text_len} = 20;
    
    if (@_ != 0) {
        if (ref $_[0] eq 'HASH') {
            my $hash=$_[0];
            foreach my $key (keys %$hash) {
                $self->{lc($key)}=$hash->{$key};
            }
        }else{ 
            my %args = @_;
            foreach my $key (keys %args) {
                $self->{lc($key)}=$args{$key};
            }
        }
    }

    $self->table_tags($self->{table_tags});
    $self->ignore_tags($self->{ignore_tags});
    return $self;
}

sub min_text_len{
    my $self=shift;
    return $self->{min_text_len} if (@_ == 0);

    $self->{min_text_len}=shift;
}

sub link_text_ratio{
    my $self=shift;
    return $self->{link_text_ratio} if (@_ == 0);

    $self->{link_text_ratio}=shift;
}

sub spam_words{
    my $self = shift;

    if(@_ == 0){
        return @{$self->{spam_words}};
    }

    if(ref $_[0] eq 'ARRAY'){
        $self->{spam_words} = $_[0];
    }else{
        my @array = @_;
        $self->{spam_words} = \@array;
    }
}

sub ignore_tags{
    my $self = shift;

    if(@_ == 0){
        return keys %{$self->{ignore_tags}};
    }

    my $array;
    if(ref $_[0] eq 'ARRAY'){
        $array = $_[0];
    }else{
        $array = \@_;
    }

    my $h={};
    grep {$h->{$_}=1;} @$array;
    $self->{ignore_tags} = $h;
}

sub table_tags{
    my $self = shift;
    if(@_ == 0){
        return keys %{$self->{table_tags}};
    }
    
    my $array;
    if(ref $_[0] eq 'ARRAY'){
        $array = $_[0];
    }else{
        $array = \@_;
    }

    my $h={};
    grep {$h->{$_}=1;} @$array;
    $self->{table_tags} = $h;
}

#the input should be utf8 encoded html content
sub extract{
    my $self=shift;
    my $url=shift;
    my $HTML=shift;

    $self->{tree}->delete if($self->{tree});
    
    $HTML=_PreprocessForFragmentIdentifiedPage($url,$HTML);             
    _remove_crap($HTML);
    
    $self->{url}=$url;
    $self->{tree} = HTML::TreeBuilder->new();
    $self->{tree} ->parse($HTML);
    $self->{link_count} = _how_many_links($self->{tree});
    $self->{is_index}= _check_if_index($self->{tree});
    $self->_Heuristic_Remove($self->{tree});
    $self->_Table_Remove($self->{tree});
}

sub _is_index{
    return $_[0]->{is_index};
}

sub DESTROY{
    my $self = shift;
    $self->{tree}->delete if($self->{tree});
}

#also the output are in utf8 format
sub as_html{
    my $self=shift;
    my $HTML = $self->{tree}->as_HTML('<>&',"\t");
    return $HTML;
}

sub as_text{
    my $self=shift;
    my $output = _to_text($self->{tree});
    $output =~ s/[\n\r] +/\n/sg;
    $output =~ s/[\n\r]+/\n/sg;
    $output =~ s/ +/ /sg;
    $output =~ s/\n /\n/sg;
    $output =~ s/^\s+//;
    return $output;
}

sub _link_count{
    return $_[0]->{link_count};
}

sub _check_if_index{
    my $node=shift;
    
    my $num_links=_how_many_links($node);
    my $txt=_nonlink_words($node);
        
    my $num_words = _count_words_num($txt);
        
    my $ratio=1;
    $ratio = $num_links/$num_words unless $num_words==0;
    if($ratio>0.3 || $num_links>400){
        return 1;
    }else{
        return 0;
    }
}

sub _remove_crap{
    $_[0] =~ s/&nbsp;/ /isg;
}

sub _Table_Remove{
    my $self=shift;
    my $node=shift;
    return if not ref $node;             # not an element node

    my $tag=$node->tag;

    my @nodes = $node->content_list(); # depth first recursive travesel
    foreach my $child (@nodes){
        $self->_Table_Remove( $child );
    }
    
    if($self->{table_tags}->{$tag}){
        
        my $num_links=_how_many_links($node);
        my $txt=_nonlink_words($node);
        
        my $num_words = _count_words_num($txt);
        
        my $ratio=1;
        $ratio = $num_links/$num_words unless $num_words==0;

        if ($num_words < $self->{min_text_len} and 
            $node->tag ne 'h1' and
            $node->tag ne 'h2' and
            $node->tag ne 'h3' and
            $node->tag ne 'p'){
            $node->delete; return;
        }
        
        if ($ratio > $self->{link_text_ratio}){
            $node->delete; return;
        }
        
        $txt = lc $txt;
        
        foreach(@{ $self->{spam_words} }){
            if(index($txt,$_) != -1){
                $node->delete;
                return;
            }
        }
    }
}

sub _how_many_links{
    my $node=shift;
    my $links_r = $node->extract_links();
    my $num_links = scalar(@$links_r);
    return $num_links;
}

sub _nonlink_words{
    my $node=shift;
    if(not ref $node){
        my $text = $node;
        return $text;
    }
    return '' if($node->tag eq 'a'
                 or $node->tag eq 'style'
                 or $node->tag eq 'script'
                 or $node->tag eq 'option'
                 or $node->tag eq 'noscript'
                 or $node->tag eq 'hr'
                 or $node->tag eq 'input'
                 );
                 
    my @nodes = $node->content_list(); # breadth first travesel
    my $sum_text="";
    foreach $node (@nodes){
        $sum_text .= _nonlink_words( $node );
    }
    return $sum_text;
}

sub _Heuristic_Remove{
    my $self=shift;
    my $node=shift;
    return if not ref $node;             # not an element node
    
    my @nodes = $node->content_list();   # depth first recursive travesel
    foreach my $child (@nodes){
        $self->_Heuristic_Remove( $child );
    }
    
    if($self->{ignore_tags}->{$node->tag} ){       # ignore the tags defined in ignore_tags
        $node->delete;
        return;
    }
    
    if($node->tag eq 'a' and $node->parent->tag eq 'body'){
        $node->delete;
    }
}

sub _to_text{
    my $node = shift;
    if(not ref $node){
        return $node;
    }
    return '' if($node->tag eq 'head');
    my @nodes = $node->content_list();  #breadth firth travesel
		my $text = "";
		foreach my $child (@nodes) {
        if ( ref $child and $child->can('tag') and $child->tag() eq 'table' ) {
            my $avail = eval { require HTML::TableExtract };
            unless ($avail) {
                $text .= _to_text($child) . "\n";
                next;
            }
            my $table   = 'HTML::TableExtract'->new();
            my $content = $child->as_HTML;
            $table->parse($content);
            foreach my $ts ( $table->tables ) {
                foreach my $row ( $ts->rows ) {
                    defined and do { s/\s+$//, s/^\s+// }
                    for @$row;
                    $text .= join( ', ', grep { defined } @$row ) . "\n";
                }
            }
        }else {
            $text .= _to_text($child) . "\n";
        }
		}
    return $text;
}

sub _count_words_num{
    my $text = shift;

    $text =~ s/([\x21-\x7e]+)/ $1 /g;
    $text =~ s/([^\x20-\x7e])/ $1 /g;
    $text =~ s/^ +//;
    my @tokens=split(/\s+/,$text);
    
    return scalar(@tokens);
}

# input is the url and HTML
# output is the processed HTML
sub _PreprocessForFragmentIdentifiedPage{
    my $url=shift;
    my $HTML=shift;
    if($url!~/\#/){        
        return $HTML;
    }
    
    my ($fragment_id)= $url=~/\#(.+)$/;
    $fragment_id=~s/\///;
  
    if($HTML=~/(<a id=\"$fragment_id\".*?)<a id/s){
        $HTML=$1;
    }
    return $HTML;
}

1;

