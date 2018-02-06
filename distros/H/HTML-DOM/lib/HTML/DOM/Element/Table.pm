package HTML::DOM::Element::Table;

use strict;
use warnings;

use HTML::DOM::Exception qw 'HIERARCHY_REQUEST_ERR INDEX_SIZE_ERR';

require HTML::DOM::Collection;
require HTML::DOM::Element;
#require HTML::DOM::NodeList::Magic;

our @ISA = qw'HTML::DOM::Element';
our $VERSION = '0.058';

sub caption {
	my $old = ((my $self = shift)->content_list)[0];
	undef $old unless $old and $old->tag eq 'caption';
	if(@_) {
		my $new = shift;
		my $tag = (eval{$new->tag}||'');
		$tag eq 'caption' or die new HTML'DOM'Exception
			HIERARCHY_REQUEST_ERR,
			$tag ? "A $tag element cannot be a table caption"
			     : "Not a valid table caption";
		if ($old) {
			$self->replaceChild($new, $old);
		} else {
			$self->unshift_content($new)
		}
	}
	return $old || ();
}
sub tHead {
	my $self = shift;
	for($self->content_list) {
		(my $tag  = tag $_);
		if($tag =~ /^t(?:head|body|foot)\z/) {
		  if(@_) {
		    my $new = shift;
		    my $new_tag = (eval{$new->tag}||'');
		    $new_tag eq 'thead' or die
		      new HTML'DOM'Exception
		        HIERARCHY_REQUEST_ERR,
		        $tag
		        ? "A $new_tag element cannot be a table header"
		        : "Not a valid table header";
		    $_->${\qw[preinsert replace_with][$tag eq 'thead']}(
		      $new
		    );
		    $self->ownerDocument->_modified;
		  }
		  return $tag eq 'thead' ? $_:();
		}
	}
	@_ and $self->appendChild(shift);
	return;
}
sub tFoot {
	my $self = shift;
	for($self->content_list) {
		(my $tag  = tag $_);
		if($tag =~ /^t(?:body|foot)\z/) {
		  if(@_) {
		    my $new = shift;
		    my $new_tag = (eval{$new->tag}||'');
		    $new_tag eq 'tfoot' or die
		      new HTML'DOM'Exception
		        HIERARCHY_REQUEST_ERR,
		        $tag
		        ? "A $new_tag element cannot be a table footer"
		        : "Not a valid table footer";
		    $_->${\qw[preinsert replace_with][$tag eq 'tfoot']}(
		      $new
		    );
		    $self->ownerDocument->_modified;
		  }
		  return $tag eq 'tfoot' ? $_ : ();
		}
	}
	@_ and $self->appendChild(shift);
	return;
}
sub rows { # ~~~ I need to make this cache the resulting collection obj
	my $self = shift;
	if (wantarray) {
		# I need a grep in order to exclude text nodes.
		return grep tag $_ eq 'tr', map $_->content_list,
		       map $self->$_, qw/ tHead tBodies tFoot /;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'tr', map $_->content_list,
		          map $self->$_, qw/ tHead tBodies tFoot /; }
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}
sub tBodies { # ~~~ I need to make this cache the resulting collection obj
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'tbody', $self->content_list;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'tbody', $self->content_list }
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}
sub align       { lc shift->_attr('align'       => @_) }
sub bgColor     { shift->_attr('bgcolor'     => @_) }
sub border      { shift->_attr( border       => @_) }
sub cellPadding { shift->_attr('cellpadding' => @_) }
sub cellSpacing { shift->_attr('cellspacing' => @_) }
sub frame       { shift->_attr('frame'       => @_) }
sub rules       { lc shift->_attr('rules'       => @_) }
sub summary     { shift->_attr('summary'     => @_) }
sub width       { shift->_attr('width'       => @_) }

sub createTHead {
	my $self = shift;
	my $th = $self->tHead;
	$th and return $th;

	my $inserted;
	$th = $self->ownerDocument->createElement('thead');
	for($self->content_list) {
		next if tag $_ =~ /^c(?:aption|ol(?:group)?)\z/;
		$_->preinsert($th), ++$inserted,
		$self->ownerDocument->_modified, last
	}
	$self->appendChild($th) unless $inserted;

	$th
}

sub deleteTHead {
	my $self = shift;
	($self->tHead||return)->delete; # ~~~ once I weaken upward refs, should I make this less destructive?
	$self->ownerDocument->_modified;
	return;
}

sub createTFoot {
	my $self = shift;
	my $tf = $self->tFoot;
	$tf and return $tf;

	my $inserted;
	$tf = $self->ownerDocument->createElement('tfoot');
	for($self->content_list) {
		next if tag $_ =~ /^(?:c(?:aption|ol(?:group)?)|thead)\z/;
		$_->preinsert($tf), ++$inserted, 			
		$self->ownerDocument->_modified, last
	}
	$self->appendChild($tf) unless $inserted;

	$tf
}

sub deleteTFoot {
	my $self = shift;
	($self->tFoot||return)->delete; # ~~~ once I weaken upward refs, should I make this less destructive?
	$self->ownerDocument->_modified;
	return;
}

sub createCaption {
	my $self = shift; my $th;
	$self->caption or
		$self->unshift_content($th =
			$self->ownerDocument->createElement('caption')),
		$self->ownerDocument->_modified,
		$th;
}

sub deleteCaption {
	my $self = shift;
	($self->caption||return)->delete; # ~~~ once I weaken upward refs, should I make this less destructive?
	$self->ownerDocument->_modified;
	return;
}

sub insertRow {
	my $self = shift;
	my $ix = shift;
	my $len = (my $rows = $self->rows)->length;
	my $row = $self->ownerDocument->createElement('tr');
	if(!$len) { # worst case
		if(my $tb = $self->tBodies->item(0)) {
			$tb->appendChild($row);
		}
		else {
			(my $tb = $self->ownerDocument
			 ->createElement('tbody'))
				->appendChild($row);
			$self->appendChild($tb);
		}
	}
	elsif($ix == -1 || $ix == $len) {
		$rows->item(-1)->postinsert(
			$row
		);
		$self->ownerDocument->_modified;
	}
	elsif($ix < $len && $ix >= 0) {
		$rows->item($ix)->preinsert($row);
		$self->ownerDocument->_modified
	}
	else {
		die new HTML::DOM::Exception INDEX_SIZE_ERR,
			"Index $ix is out of range"
	}

	return $row;
}

sub deleteRow {
	my $self = shift;
	($self->rows->item(shift)||return)->delete; # ~~~ once I weaken upward refs, should I make this less destructive?
	$self->ownerDocument->_modified;
	return;
}


=head1 NAME

HTML::DOM::Element::Table - A Perl class for representing 'table' elements in an HTML DOM tree

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $elem = $doc->createElement('table');

  $elem->tHead;
  $elem->tBodies->[0];
  $elem->createTFoot;
  # etc

=head1 DESCRIPTION

This class represents 'table' elements in an HTML::DOM tree. It implements the HTMLTableElement DOM interface and inherits from L<HTML::DOM::Element>
(q.v.).

=head1 METHODS

In addition to those inherited from HTML::DOM::Element and its 
superclasses, this class implements the following DOM methods:

=over 4

=item caption

=item tHead

=item tFoot

Each of these returns the table's corresponding element, if it exists, or
an empty list otherwise.

=item rows

Returns a collection of all table row elements, or a list in list context.

=item tBodies

Returns a collection of all 'tbody' elements, or a list in list context.

=item align

=item bgColor

=item border

=item cellPadding

=item cellSpacing

=item frame

=item rules

=item summary

=item width

These get (optionally set) the corresponding HTML attributes.

=item createTHead

Returns the table's 'thead' element, creating it if it doesn't exist.

=item deleteTHead

Deletes the table's 'thead' element.

=item createTFoot

Returns the table's 'tfoot' element, creating it if it doesn't exist.

=item deleteTFoot

Does what you would think.

=item createCaption

Returns the table's 'caption' element, creating it if it doesn't exist.

=item deleteCaption

Deletes the caption.

=item insertRow

Insert a new 'tr' element at the index specified by the first argument, and
returns that new row.

=item deleteRow

Deletes the row at the index specified by the first arg.

=back

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Element>

L<HTML::DOM::Element::Caption>

L<HTML::DOM::Element::TableColumn>

L<HTML::DOM::Element::TableSection>

L<HTML::DOM::Element::TR>

L<HTML::DOM::Element::TableCell>

=cut


# ------- HTMLTableCaptionElement interface ---------- #

package HTML::DOM::Element::Caption;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*align = \&HTML::DOM::Element::Table::align;

# ------- HTMLTableColElement interface ---------- #

package HTML::DOM::Element::TableColumn;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*align = \&HTML::DOM::Element::Table::align;
sub ch     { shift->_attr('char'   => @_) }
sub chOff  { shift->_attr( charoff => @_) }
sub span   { shift->_attr('span'   => @_) }
sub vAlign { lc shift->_attr('valign' => @_) }
sub width  { shift->_attr('width'  => @_) }

# ------- HTMLTableSectionElement interface ---------- #

package HTML::DOM::Element::TableSection;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
*align  = \&HTML::DOM::Element::Table::align;
*ch     = \&HTML::DOM::Element::TableColumn::ch;
*chOff  = \&HTML::DOM::Element::TableColumn::chOff;
*vAlign = \&HTML::DOM::Element::TableColumn::vAlign;
sub rows { # ~~~ I need to make this cache the resulting collection obj
	my $self = shift;
	if (wantarray) {
		# I need a grep in order to exclude text nodes.
		return grep tag $_ eq 'tr', $self->content_list,
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'tr', $self->content_list; }
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}
sub insertRow {
	my $self = shift;
	my $ix = shift||0;
	my $len = (my $rows = $self->rows)->length;
	my $row = $self->ownerDocument->createElement('tr');
	if(!$len) {
		$self->appendChild($row);
	}
	elsif($ix == -1 || $ix == $len) {
		$rows->item(-1)->postinsert(
			$row
		);
		$self->ownerDocument->_modified;
	}
	elsif($ix < $len && $ix >= 0) {
		$rows->item($ix)->preinsert($row);
		$self->ownerDocument->_modified;
	}
	else {
		die new HTML::DOM::Exception
			 HTML::DOM::Exception::INDEX_SIZE_ERR,
			"Index $ix is out of range"
	}

	return $row;
}

*deleteRow = \&HTML::DOM::Element::Table::deleteRow;

# ------- HTMLTableRowElement interface ---------- #

package HTML::DOM::Element::TR;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub rowIndex {
	my $self = shift;
	my $ix = 0;
	for($self->look_up(_tag => 'table')->rows){
		return $ix if $self == $_;
		$ix++
	}
	die "Internal error in HTML::DOM::Element::TR::rowIndex: " .
	    "This table row is not inside the table it is inside. " .
	    "Please report this bug."
}
sub sectionRowIndex {
	my $self = shift;
	my $parent = $self->parent;
	while(!$parent->isa('HTML::DOM::Element::TableSection')) {
		# If we get here, there is probably something wrong, should
		# I just throw an error instead?
		$parent = $parent->parent;
	}
	my $ix = 0;
	for($parent->rows){
		return $ix if $self == $_;
		$ix++
	}
	die "Internal error in HTML::DOM::Element::TR::sectionRowIndex: " .
	    "This table row is not inside the table section it is " .
	    "inside. Please report this bug."
}
sub cells { # ~~~ I need to make this cache the resulting collection obj
	my $self = shift;
	if (wantarray) {
		# I need a grep in order to exclude text nodes.
		return grep tag $_ =~ /^t[hd]\z/, $self->content_list,
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ =~ /^t[hd]\z/, $self->content_list; }
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}
*align   = \&HTML::DOM::Element::Table::align;
*bgColor = \&HTML::DOM::Element::Table::bgColor;
*ch      = \&HTML::DOM::Element::TableColumn::ch;
*chOff   = \&HTML::DOM::Element::TableColumn::chOff;
*vAlign  = \&HTML::DOM::Element::TableColumn::vAlign;
sub insertCell {
	my $self = shift;
	my $ix = shift||0;
	my $len = (my $cels = $self->cells)->length;
	my $cel = $self->ownerDocument->createElement('td');
	if(!$len) {
		$self->appendChild($cel);
	}
	elsif($ix == -1 || $ix == $len) {
		$cels->item(-1)->postinsert(
			$cel
		);
		$self->ownerDocument->_modified;
	}
	elsif($ix < $len && $ix >= 0) {
		$cels->item($ix)->preinsert($cel);
		$self->ownerDocument->_modified;
	}
	else {
		die new HTML::DOM::Exception
			 HTML::DOM::Exception::INDEX_SIZE_ERR,
			"Index $ix is out of range"
	}

	return $cel;
}
sub deleteCell {
	my $self = shift;
	($self->cells->item(shift)||return)->delete; # ~~~ once I weaken upward refs, should I make this less destructive?
	$self->ownerDocument->_modified;
	return;
}

# ------- HTMLTableCellElement interface ---------- #

package HTML::DOM::Element::TableCell;
our $VERSION = '0.058';
our @ISA = 'HTML::DOM::Element';
sub cellIndex {
	my $self = shift;
	my $ix = 0;
	for($self->parent->cells){
		return $ix if $self == $_;
		$ix++
	}
	die "Internal error in HTML::DOM::Element::TR::rowIndex: " .
	    "This table row is not inside the table it is inside. " .
	    "Please report this bug."
}
sub abbr  { shift->_attr('abbr'  => @_) }
*align   = \&HTML::DOM::Element::Table::align;
sub axis  { shift->_attr('axis'  => @_) }
*bgColor = \&HTML::DOM::Element::Table::bgColor;
*ch      = \&HTML::DOM::Element::TableColumn::ch;
*chOff   = \&HTML::DOM::Element::TableColumn::chOff;
sub colSpan  { shift->_attr('colspan'  => @_) }
sub headers  { shift->_attr('headers'  => @_) }
sub height   { shift->_attr('height'   => @_) }
sub noWrap   { shift->_attr(nowrap => @_ ? $_[0] ? 'nowrap' : undef : ()) }
sub rowSpan  { shift->_attr('rowspan'  => @_) }
sub scope    { lc shift->_attr('scope'    => @_) }
*vAlign  = \&HTML::DOM::Element::TableColumn::vAlign;
*width   = \&HTML::DOM::Element::Table::width;

