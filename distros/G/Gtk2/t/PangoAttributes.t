#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 202;

# $Id$

#
# pango_color_parse(), pango_color_to_string()
#

my $color = Gtk2::Pango::Color->parse ('white');
isa_ok ($color, 'Gtk2::Pango::Color');
isa_ok ($color, 'ARRAY');
is_deeply ($color, [0xffff, 0xffff, 0xffff]);

SKIP: {
	skip 'new 1.16 stuff', 2
		unless Gtk2::Pango->CHECK_VERSION (1, 16, 0);

	is (Gtk2::Pango::Color->to_string ($color), '#ffffffffffff');
	is ($color->to_string, '#ffffffffffff');
}

#
# PangoAttrLanguage
#

my $lang = Gtk2::Pango::Language->from_string ('de-de');
my $attr = Gtk2::Pango::AttrLanguage->new ($lang);
isa_ok ($attr, 'Gtk2::Pango::AttrLanguage');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value->to_string, 'de-de');

$lang = Gtk2::Pango::Language->from_string ('en-us');
$attr->value ($lang);
is ($attr->value->to_string, 'en-us');

$attr = Gtk2::Pango::AttrLanguage->new ($lang, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrFamily
#

$attr = Gtk2::Pango::AttrFamily->new ('sans');
isa_ok ($attr, 'Gtk2::Pango::AttrFamily');
isa_ok ($attr, 'Gtk2::Pango::AttrString');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 'sans');

is ($attr->value ('sans-serif'), 'sans');
is ($attr->value, 'sans-serif');

$attr = Gtk2::Pango::AttrFamily->new ('sans', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrForeground
#

$attr = Gtk2::Pango::AttrForeground->new (0, 0, 0);
isa_ok ($attr, 'Gtk2::Pango::AttrForeground');
isa_ok ($attr, 'Gtk2::Pango::AttrColor');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is_deeply ($attr->value, [0, 0, 0]);

is_deeply ($attr->value ([0xffff, 0xffff, 0xffff]), [0, 0, 0]);
is_deeply ($attr->value, [0xffff, 0xffff, 0xffff]);

$attr = Gtk2::Pango::AttrForeground->new (0, 0, 0, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrBackground
#

$attr = Gtk2::Pango::AttrBackground->new (0, 0, 0);
isa_ok ($attr, 'Gtk2::Pango::AttrBackground');
isa_ok ($attr, 'Gtk2::Pango::AttrColor');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is_deeply ($attr->value, [0, 0, 0]);

$attr->value ([0xffff, 0xffff, 0xffff]);
is_deeply ($attr->value, [0xffff, 0xffff, 0xffff]);

$attr = Gtk2::Pango::AttrBackground->new (0, 0, 0, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrSize
#

$attr = Gtk2::Pango::AttrSize->new (23);
isa_ok ($attr, 'Gtk2::Pango::AttrSize');
isa_ok ($attr, 'Gtk2::Pango::AttrInt');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 23);

$attr->value (42);
is ($attr->value, 42);

$attr = Gtk2::Pango::AttrSize->new (23, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

SKIP: {
	skip 'Gtk2::Pango::AttrSize->new_absolute', 7
		unless Gtk2::Pango->CHECK_VERSION (1, 8, 0);

	$attr = Gtk2::Pango::AttrSize->new_absolute (23);
	isa_ok ($attr, 'Gtk2::Pango::AttrSize');
	isa_ok ($attr, 'Gtk2::Pango::AttrInt');
	isa_ok ($attr, 'Gtk2::Pango::Attribute');
	is ($attr->value, 23);

	$attr->value (42);
	is ($attr->value, 42);

	$attr = Gtk2::Pango::AttrSize->new_absolute (23, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrStyle
#

$attr = Gtk2::Pango::AttrStyle->new ('normal');
isa_ok ($attr, 'Gtk2::Pango::AttrStyle');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 'normal');

$attr->value ('italic');
is ($attr->value, 'italic');

$attr = Gtk2::Pango::AttrStyle->new ('normal', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrWeight
#

$attr = Gtk2::Pango::AttrWeight->new ('bold');
isa_ok ($attr, 'Gtk2::Pango::AttrWeight');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 'bold');

$attr->value ('heavy');
is ($attr->value, 'heavy');

$attr = Gtk2::Pango::AttrWeight->new ('bold', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrVariant
#

$attr = Gtk2::Pango::AttrVariant->new ('normal');
isa_ok ($attr, 'Gtk2::Pango::AttrVariant');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 'normal');

$attr->value ('small-caps');
is ($attr->value, 'small-caps');

$attr = Gtk2::Pango::AttrVariant->new ('normal', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrStretch
#

$attr = Gtk2::Pango::AttrStretch->new ('normal');
isa_ok ($attr, 'Gtk2::Pango::AttrStretch');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 'normal');

$attr->value ('condensed');
is ($attr->value, 'condensed');

$attr = Gtk2::Pango::AttrStretch->new ('normal', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrUnderline
#

$attr = Gtk2::Pango::AttrUnderline->new ('none');
isa_ok ($attr, 'Gtk2::Pango::AttrUnderline');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 'none');

$attr->value ('double');
is ($attr->value, 'double');

$attr = Gtk2::Pango::AttrUnderline->new ('none', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrStrikethrough
#

$attr = Gtk2::Pango::AttrStrikethrough->new (FALSE);
isa_ok ($attr, 'Gtk2::Pango::AttrStrikethrough');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
ok (!$attr->value);

$attr->value (TRUE);
ok ($attr->value);

$attr = Gtk2::Pango::AttrStrikethrough->new (FALSE, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrFontDesc
#

my $desc = Gtk2::Pango::FontDescription->from_string ('Sans 12');
$attr = Gtk2::Pango::AttrFontDesc->new ($desc);
isa_ok ($attr, 'Gtk2::Pango::AttrFontDesc');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->desc->to_string, 'Sans 12');

$desc = Gtk2::Pango::FontDescription->from_string ('Sans 14');
is ($attr->desc ($desc)->to_string, 'Sans 12');
is ($attr->desc->to_string, 'Sans 14');

$attr = Gtk2::Pango::AttrFontDesc->new ($desc, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrScale
#

$attr = Gtk2::Pango::AttrScale->new (2.0);
isa_ok ($attr, 'Gtk2::Pango::AttrScale');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 2.0);

$attr->value (4.0);
is ($attr->value, 4.0);

$attr = Gtk2::Pango::AttrScale->new (2.0, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrRise
#

$attr = Gtk2::Pango::AttrRise->new (23);
isa_ok ($attr, 'Gtk2::Pango::AttrRise');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is ($attr->value, 23);

$attr->value (42);
is ($attr->value, 42);

$attr = Gtk2::Pango::AttrRise->new (23, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrShape
#

my $ink     = { x => 23, y => 42, width => 10, height => 15 };
my $logical = { x => 42, y => 23, width => 15, height => 10 };

$attr = Gtk2::Pango::AttrShape->new ($ink, $logical);
isa_ok ($attr, 'Gtk2::Pango::AttrShape');
isa_ok ($attr, 'Gtk2::Pango::Attribute');
is_deeply ($attr->ink_rect, $ink);
is_deeply ($attr->logical_rect, $logical);

$attr->ink_rect ($logical);
is_deeply ($attr->ink_rect, $logical);
$attr->logical_rect ($ink);
is_deeply ($attr->logical_rect, $ink);

$attr = Gtk2::Pango::AttrShape->new ($ink, $logical, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrFallback
#

SKIP: {
	skip 'Gtk2::Pango::AttrFallback', 6
		unless Gtk2::Pango->CHECK_VERSION (1, 4, 0);

	$attr = Gtk2::Pango::AttrFallback->new (FALSE);
	isa_ok ($attr, 'Gtk2::Pango::AttrFallback');
	isa_ok ($attr, 'Gtk2::Pango::Attribute');
	ok (!$attr->value);

	$attr->value (TRUE);
	ok ($attr->value);

	$attr = Gtk2::Pango::AttrFallback->new (FALSE, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrLetterSpacing
#

SKIP: {
	skip 'Gtk2::Pango::AttrLetterSpacing', 7
		unless Gtk2::Pango->CHECK_VERSION (1, 6, 0);

	$attr = Gtk2::Pango::AttrLetterSpacing->new (23);
	isa_ok ($attr, 'Gtk2::Pango::AttrLetterSpacing');
	isa_ok ($attr, 'Gtk2::Pango::AttrInt');
	isa_ok ($attr, 'Gtk2::Pango::Attribute');
	is ($attr->value, 23);

	$attr->value (42);
	is ($attr->value, 42);

	$attr = Gtk2::Pango::AttrLetterSpacing->new (23, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrUnderlineColor
#

SKIP: {
	skip 'Gtk2::Pango::AttrUnderlineColor', 8
		unless Gtk2::Pango->CHECK_VERSION (1, 8, 0);

	$attr = Gtk2::Pango::AttrUnderlineColor->new (0, 0, 0);
	isa_ok ($attr, 'Gtk2::Pango::AttrUnderlineColor');
	isa_ok ($attr, 'Gtk2::Pango::AttrColor');
	isa_ok ($attr, 'Gtk2::Pango::Attribute');
	is_deeply ($attr->value, [0, 0, 0]);

	is_deeply ($attr->value ([0xffff, 0xffff, 0xffff]), [0, 0, 0]);
	is_deeply ($attr->value, [0xffff, 0xffff, 0xffff]);

	$attr = Gtk2::Pango::AttrUnderlineColor->new (0, 0, 0, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrStrikethroughColor
#

SKIP: {
	skip 'Gtk2::Pango::AttrStrikethroughColor', 8
		unless Gtk2::Pango->CHECK_VERSION (1, 8, 0);

	$attr = Gtk2::Pango::AttrStrikethroughColor->new (0, 0, 0);
	isa_ok ($attr, 'Gtk2::Pango::AttrStrikethroughColor');
	isa_ok ($attr, 'Gtk2::Pango::AttrColor');
	isa_ok ($attr, 'Gtk2::Pango::Attribute');
	is_deeply ($attr->value, [0, 0, 0]);

	is_deeply ($attr->value ([0xffff, 0xffff, 0xffff]), [0, 0, 0]);
	is_deeply ($attr->value, [0xffff, 0xffff, 0xffff]);

	$attr = Gtk2::Pango::AttrStrikethroughColor->new (0, 0, 0, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrGravity, PangoAttrGravityHint
#

SKIP: {
	skip 'PangoAttrGravity, PangoAttrGravityHint', 14
		unless Gtk2::Pango->CHECK_VERSION (1, 16, 0);

	$attr = Gtk2::Pango::AttrGravity->new ('south');
	isa_ok ($attr, 'Gtk2::Pango::AttrGravity');
	isa_ok ($attr, 'Gtk2::Pango::Attribute');
	is ($attr->value, 'south');

	is ($attr->value ('north'), 'south');
	is ($attr->value, 'north');

	$attr = Gtk2::Pango::AttrGravity->new ('south', 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);

	$attr = Gtk2::Pango::AttrGravityHint->new ('strong');
	isa_ok ($attr, 'Gtk2::Pango::AttrGravityHint');
	isa_ok ($attr, 'Gtk2::Pango::Attribute');
	is ($attr->value, 'strong');

	is ($attr->value ('line'), 'strong');
	is ($attr->value, 'line');

	$attr = Gtk2::Pango::AttrGravityHint->new ('strong', 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrList
#

my $attr_one = Gtk2::Pango::AttrWeight->new ('light', 23, 42);
my $attr_two = Gtk2::Pango::AttrWeight->new ('normal', 23, 42);
my $attr_three = Gtk2::Pango::AttrWeight->new ('bold', 23, 42);

my $list_one = Gtk2::Pango::AttrList->new;
$list_one->insert ($attr_one);
$list_one->insert_before ($attr_two);
$list_one->change ($attr_three);

my $list_two = Gtk2::Pango::AttrList->new;
$list_one->insert ($attr_three);
$list_one->insert_before ($attr_two);
$list_one->change ($attr_one);

$list_one->splice ($list_two, 0, 2);

#
# PangoAttrIterator
#

my $list = Gtk2::Pango::AttrList->new;

my $attr_weight = Gtk2::Pango::AttrWeight->new ('normal', 0, 23);
$list->insert ($attr_weight);

my $attr_variant = Gtk2::Pango::AttrVariant->new ('normal', 0, 42);
$list->insert ($attr_variant);

my $iter = $list->get_iterator;
isa_ok ($iter, 'Gtk2::Pango::AttrIterator');

is_deeply ([$iter->range], [0, 23]);
ok ($iter->get ('weight')->equal ($attr_weight));

my @attrs = $iter->get_attrs;
is (scalar @attrs, 2);
ok ($attrs[1]->equal ($attr_variant));

ok ($iter->next);
ok ($iter->next);

@attrs = $iter->get_attrs;
is (scalar @attrs, 0);

is ($iter->get ('weight'), undef);

# get_font
$list = Gtk2::Pango::AttrList->new;

$lang = Gtk2::Pango::Language->from_string ('de-de');
$attr = Gtk2::Pango::AttrLanguage->new ($lang, 0, 23);
$list->insert($attr);

$attr = Gtk2::Pango::AttrWeight->new ('bold', 0, 23);
$list->insert($attr);

$iter = $list->get_iterator;
my ($desc_new, $lang_new, @extra) = $iter->get_font;
is ($desc_new->get_weight, 'bold');
is ($lang_new->to_string, 'de-de');
is (scalar @extra, 0);

$attr = Gtk2::Pango::AttrBackground->new (0, 0, 0, 0, 23);
$list->insert($attr);

$attr = Gtk2::Pango::AttrForeground->new (0, 0, 0, 0, 23);
$list->insert($attr);

$iter = $list->get_iterator;
($desc_new, $lang_new, @extra) = $iter->get_font;
is ($desc_new->get_weight, 'bold');
is ($lang_new->to_string, 'de-de');
is (scalar @extra, 2);
isa_ok ($extra[0], 'Gtk2::Pango::AttrBackground');
isa_ok ($extra[1], 'Gtk2::Pango::AttrForeground');

# filter
SKIP: {
	skip 'filter', 12
		unless Gtk2::Pango->CHECK_VERSION (1, 2, 0);

	# run four times -> 8 tests
	my $callback = sub {
	  my ($attr, $data) = @_;
	  isa_ok ($attr, 'Gtk2::Pango::Attribute');
	  is ($data, 'urgs');
	  return $attr->isa ('Gtk2::Pango::AttrWeight');
	};

	my $list_new = $list->filter ($callback, 'urgs');
	$iter = $list_new->get_iterator;
	@attrs = $iter->get_attrs;
	is (scalar @attrs, 1);
	isa_ok ($attrs[0], 'Gtk2::Pango::AttrWeight');
	ok ($iter->next);
	ok (!$iter->next);
}

#
# pango_parse_markup()
#

my ($attr_list, $text, $accel_char) =
	Gtk2::Pango->parse_markup
		('<big>this text is <i>really</i> cool</big> (no lie)');
isa_ok ($attr_list, 'Gtk2::Pango::AttrList');
is ($text, 'this text is really cool (no lie)', 'text is stripped of tags');
ok ((not defined $accel_char), 'no accel_char if no accel_marker');

{
	# first, only <big>
	my $iter = $attr_list->get_iterator;
	my @attrs = $iter->get_attrs;
	is (scalar @attrs, 1);
	isa_ok ($attrs[0], 'Gtk2::Pango::AttrScale');

	# then, <big> and <i>
	$iter->next;
	@attrs = $iter->get_attrs;
	is (scalar @attrs, 2);
	isa_ok ($attrs[0], 'Gtk2::Pango::AttrScale');
	isa_ok ($attrs[1], 'Gtk2::Pango::AttrStyle');

	# finally, only <big> again
	$iter->next;
	@attrs = $iter->get_attrs;
	is (scalar @attrs, 1);
	isa_ok ($attrs[0], 'Gtk2::Pango::AttrScale');
}

($attr_list, $text) = Gtk2::Pango->parse_markup ('no markup here');
isa_ok ($attr_list, 'Gtk2::Pango::AttrList');
is ($text, 'no markup here', 'no tags, nothing stripped');

($attr_list, $text, $accel_char) =
	Gtk2::Pango->parse_markup ('Text with _accel__chars', '_');
isa_ok ($attr_list, 'Gtk2::Pango::AttrList');
is ($text, 'Text with accel_chars');
is ($accel_char, 'a');

# invalid markup causes an exception...
eval { Gtk2::Pango->parse_markup ('<bad>invalid markup') };
isa_ok ($@, 'Glib::Error');
isa_ok ($@, 'Glib::Markup::Error');
is ($@->domain, 'g-markup-error-quark');
ok ($@->matches ('Glib::Markup::Error', 'unknown-element'),
    'invalid markup causes exceptions');
$@ = undef;

__END__

Copyright (C) 2005-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
