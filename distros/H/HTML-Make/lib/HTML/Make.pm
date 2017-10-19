package HTML::Make;
use warnings;
use strict;
our $VERSION = '0.10';
use Carp;
use HTML::Valid::Tagset ':all';

# This is a list of valid tags.

my %tags = %HTML::Valid::Tagset::isKnown;
my %noCloseTags = %HTML::Valid::Tagset::emptyElement;
my %isBlock = %HTML::Valid::Tagset::isBlock;

our $texttype = 'text';
our $blanktype = 'blank';

# This is for checking %options for stray stuff.

my %validoptions = (qw/text 1 nocheck 1 attr 1/);

sub new
{
    my ($class, $type, %options) = @_;
    my $obj = {};
    bless $obj;
    if (! $type) {
	$type = $blanktype;
    }
    $obj->{type} = lc ($type);
    # User is not allowed to use 'text' type.
    if ($type eq $texttype) {
	my ($package, undef, undef) = caller ();
	if ($package ne __PACKAGE__) {
	    die "Illegal use of text type";
	}
	if (! defined $options{text}) {
	    croak "Text type object with empty text";
	}
	if (ref $options{text}) {
	    croak "text field must be a scalar";
	}
	$obj->{text} = $options{text};
    }
    else {
	if (! $options{nocheck} && $type ne $blanktype && ! $tags{lc $type}) {
	    carp "Unknown tag type '$type'";
	}
	elsif (! $options{nocheck} && ! $isHTML5{lc $type}) {
	    carp "<$type> is not HTML5";
	}
	if ($options{text}) {
            $obj->add_text ($options{text});
        }
	if ($options{attr}) {
	    $obj->add_attr (%{$options{attr}});
	}
	for my $k (keys %options) {
	    if (! $validoptions{$k}) {
		carp "Unknown option '$k'";
	    }
	}
    }
    return $obj;
}

sub check_attributes
{
    my ($obj, %attr) = @_;
    if ($attr{id}) {
	# This is a bit of a bug since \s matches more things than the
	# 5 characters disallowed in HTML IDs.
	if ($attr{id} =~ /\s/) {
	    carp "ID attributes cannot contain spaces";
	}
    }
    for my $k (keys %attr) {
	my $type = lc $obj->{type};
	if (! tag_attr_ok (lc $type, $k)) {
	    carp "attribute $k is not allowed for <$type> in HTML5";
	}
    }
}

sub add_attr
{
    my ($obj, %attr) = @_;
    if (! $obj->{nocheck}) {
	check_attributes ($obj, %attr);
    }
    for my $k (sort keys %attr) {
	if ($obj->{attr}->{$k}) {
	    carp "Overwriting attribute '$k' for '$obj->{type}' tag";
	}
        $obj->{attr}->{$k} = $attr{$k};
    }
}

sub add_text
{
    my ($obj, $text) = @_;
    my $x = __PACKAGE__->new ($texttype, text => $text);
    CORE::push @{$obj->{children}}, $x;
    return $x;
}

sub check_mismatched_tags
{
    my ($obj, $el) = @_;
    my $ptype = $obj->{type};
    my $is_table_el = ($el =~ /^(th|td)$/i);
    if ($ptype eq 'tr' && ! $is_table_el) {
	carp "Pushing non-table element <$el> to a table row";
	return;
    }
    if ($is_table_el && $ptype ne 'tr') {
	carp "Pushing <$el> to a non-tr element <$ptype>";
	return;
    }
    my $is_list_parent = ($ptype =~ /^(ol|ul)$/);
    if (lc ($el) eq 'li' && ! $is_list_parent) {
	carp "Pushing <li> to a non-list parent <$ptype>";
	return;
    }
}

sub HTML::Make::push
{
    my ($obj, $el, %options) = @_;
    my $x;
    if (ref $el eq __PACKAGE__) {
	$x = $el;
    }
    else {
	check_mismatched_tags ($obj, $el);
	$x = __PACKAGE__->new ($el, %options);
    }
    CORE::push @{$obj->{children}}, $x;
    return $x;
}

sub opening_tag
{
    my ($obj) = @_;
    my $text = "<$obj->{type}";
    if ($obj->{attr}) {
	my @attr;
	my %attr = %{$obj->{attr}};
	for my $k (sort keys %attr) {
	    my $v = $attr{$k};
	    $v =~ s/"/\\"/g;
	    CORE::push @attr, "$k=\"$v\"";
	}
	my $attr = join (' ', @attr);
	$text .= " $attr";
    }
    $text .= ">";
    return $text;
}

sub text
{
    my ($obj) = @_;
    my $type = $obj->{type};
    if (! $type) {
        croak "No type";
    }
    my $text;
    if ($type eq $texttype) {
        $text = $obj->{text};
    }
    else {
	if ($type ne $blanktype) {
	    $text = $obj->opening_tag ();
	    if ($isBlock{$type} || $type eq 'tr') {
		$text .= "\n";
	    }
	}
	# Recursively add text
        for my $child (@{$obj->{children}}) {
            $text .= $child->text ();
        }
	if ($type ne $blanktype && ! $noCloseTags{$type}) {
	    $text .= "</$type>\n";
	}
    }
    return $text;
}

sub multiply
{
    my ($parent, $element, $contents) = @_;
    my @elements;
    if (! defined $element) {
        croak "No element given";
    }
    if (! defined $contents || ref $contents ne 'ARRAY') {
        croak 'contents not array or not defined';
    }
    for my $content (@$contents) {
        my $x = $parent->push ($element, text => $content);
        CORE::push @elements, $x;
    }
    if (@elements != @$contents) {
	die "Mismatch of number of elements";
    }
    return @elements;
}

1;

