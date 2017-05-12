package HTML::Content::Extractor;

use utf8;
use strict;
use vars qw($AUTOLOAD $VERSION $ABSTRACT @ISA @EXPORT);

BEGIN {
	$VERSION = 0.17;
	$ABSTRACT = "Recieving main text of publication from HTML page and main media content that is bound to the text";
	
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		AI_NULL AI_TEXT AI_LINK AI_IMG
		TYPE_TAG_NORMAL TYPE_TAG_BLOCK TYPE_TAG_INLINE TYPE_TAG_SIMPLE TYPE_TAG_SIMPLE_TREE TYPE_TAG_ONE TYPE_TAG_TEXT TYPE_TAG_SYS
		DEFAULT_TAG_ID
		EXTRA_TAG_CLOSE_IF_BLOCK EXTRA_TAG_CLOSE_IF_SELF EXTRA_TAG_CLOSE_IF_SELF_FAMILY EXTRA_TAG_CLOSE_NOW EXTRA_TAG_SIMPLE EXTRA_TAG_SIMPLE_TREE EXTRA_TAG_CLOSE_PRIORITY EXTRA_TAG_CLOSE_FAMILY_LIST EXTRA_TAG_CLOSE_PRIORITY_FAMILY
		FAMILY_H FAMILY_TABLE FAMILY_LIST FAMILY_RUBY FAMILY_SELECT FAMILY_HTML
		OPTION_NULL OPTION_CLEAN_TAGS OPTION_CLEAN_TAGS_SAVE
	);
};

bootstrap HTML::Content::Extractor $VERSION;

use DynaLoader ();
use Exporter ();



1;

__END__

=head1 NAME

HTML::Content::Extractor - Recieving a main text of publication from HTML page and main media content that is bound to the text

=head1 SYNOPSIS

 my $obj = HTML::Content::Extractor->new();
 $obj->analyze($html, {class => ["comment", "tags", "blog", "theme", "footer", "head"]});
 
 my $main_text    = $obj->get_main_text();
 my $main_images  = $obj->get_main_images(1, {src => "logo", alt => ["logo", "crazy"]}, 150);
 
 my $raw_text     = $obj->get_raw_text();
 my $main_text_we = $obj->get_main_text_with_elements(1, ["a", "b", "br", "strike", ...]);
 
 print $main_text, "\n\n";
 
 print "Images:\n";
 foreach my $elem (@$main_images) {
	print $elem->{prop}->{src}, "\n";
 }
 
 # html elements
 my $obj = HTML::Content::Extractor->new();
 
 $obj->build_tree($html);
 my $tree = $obj->get_tree();
 
 my $i = -1;
 while( my $element = $obj->get_element_by_name("div", ++$i) ) {
	print "<", $element->{name};
	
	foreach my $key (keys %{$element->{prop}}) {
		print " ", $key, '="', $element->{prop}->{$key}, '"';
	}
	
	print ">\n";
 }

=head1 DESCRIPTION

This module analyzes an HTML document and extracts the main text (for example front page article contents on the news site) and all related images.

=head1 METHODS

=head2 new

 my $obj = HTML::Content::Extractor->new();

Creates and prepares the structure for the subsequent analysis and parsing HTML.

=head2 analyze

 $obj->analyze($html, [hashref]);
    
Creates an HTML document tree and analyzes it.
[hashref] - optional parameter which may (or may not) contain key-value pairs, where key is name of html tag attribute and its value is stop word, which will be ignored with all child tags. Useful for common tags for header/footer/logo etc.

=head2 get_main_text

 # UTF-8
 my $main_text = $obj->get_main_text(1);
 # or not
 my $main_text = $obj->get_main_text(0);
 # default UTF-8 is on

Return plain text.

=head2 get_raw_text

 # UTF-8
 my $raw_text = $obj->get_raw_text(1);
 # or not
 my $raw_text = $obj->get_raw_text(0);
 # default UTF-8 is on

Return the main text without post-processing (saving all html tags)

=head2 get_main_text_with_elements

 # UTF-8
 my $main_text_we = $obj->get_main_text_with_elements(1, ["span", ...]);
 # or not
 my $main_text_we = $obj->get_main_text_with_elements(0, ["span", ...]);
 # default UTF-8 is on

Returns the main text while saving selected html tags. Post-processing is skipped

=head2 get_main_images

 # UTF-8
 my $main_images = $obj->get_main_images(1, [hashref], [min_width]);
 # or not
 my $main_images = $obj->get_main_images(0, [hashref], [min_width]);
 # default UTF-8 is on

[hashref] - optional parameter which may (or may not) contain key-value pairs, where key is name of html tag attribute and its value is stop word, which will be ignored with all child tags. Useful for common tags for header/footer/logo etc.
[min_width] - optional parameter

=head2 build_tree

 my $res = $obj->build_tree($html);

Build flat html tree and returns 1

=head2 get_tree

 my $res  = $obj->build_tree($html);
 my $tree = $obj->get_tree(1);

Returns ARRAY with flat html tree

=head2 get_tree_by_element_id

 my $element_tree = $obj->get_tree_by_element_id($element->{id}, 1);

Returns ARRAY with flat html tree by element id

=head2 get_element_by_name

 my $element = $obj->get_element_by_name("div", 0);

Returns HASH or undef with element by tag name.
ARGS:
1) tag name
2) offset

Structure of this element:

 $element = {
	id     => <number>,
	name   => <text>,
	tag_id => <number>,
	prop   => <HASH>,
	level  => <number>,
	start  => <number>,
	stop   => <number>,
	bstart => <number>,
	bstop  => <number>
 };

=head2 get_stat_by_element_id

 my $element = $obj->get_stat_by_element_id($element->{id});

Returns HASH with element stats by element id. HASH included: count, all, words, AI_TEXT, AI_LINK, AI_IMG, all_AI_LINK, all_AI_LINK, all_AI_IMG

=head2 get_child

 my $element = $obj->get_child(0);

=head2 get_parent

 my $element = $obj->get_parent();

=head2 get_curr_element

 my $element = $obj->get_curr_element();

=head2 get_prev_element

 my $element = $obj->get_prev_element();

=head2 get_next_element_curr_level

 my $element = $obj->get_next_element_curr_level();

=head2 get_prev_element_curr_level

 my $element = $obj->get_prev_element_curr_level();

=head2 set_position

 my $element = $obj->set_position($element);

Set position by element. Returns this element or undef if something is wrong

=head1 DESTROY

 undef $obj;

Cleaning of all internal structures (HTML tree and other)

=head1 AUTHOR

Alexander Borisov <lex.borisov@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexander Borisov.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
