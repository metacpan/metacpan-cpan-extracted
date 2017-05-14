# ZObject: z-code Object, containing "attributes" (flags)
# and "properties" (values).
package Games::Rezrov::ZObject;

use strict;
use Games::Rezrov::ZProperty;
use Games::Rezrov::ZText;
use Games::Rezrov::Inliner;
use Games::Rezrov::InlinedPrivateMethod;

my $code = Games::Rezrov::InlinedPrivateMethod->new("-manual" => 1,
						    "-names" =>
						    [ qw(
							 _object_id
							 _pointer_size
							 _attrib_offset
							 _property_start_index
							 _prop_addr
							 _parent_offset
							 _child_offset
							 _sibling_offset
							 _property_cache
							)
						    ],
						   );
Games::Rezrov::Inliner::inline($code);

#print $$code; die;
eval $$code;
die $@ if $@;

1;

__DATA__

sub object_id {
  # public, read-only
  return $_[0]->_object_id();
}

sub get_ptr {
  # get a value, depending on pointer size
  # args: offset.
  # - This seems slightly faster than using a different class
  #   for each type size and inheriting back to ZObject.
  return ($_[0]->_pointer_size() == 1) ?
     GET_BYTE_AT($_[1]) : GET_WORD_AT($_[1]);
}

sub test_attr {
  my ($self, $attribute) = @_;
  # return true of specified attribute of this object is set,
  # false otherwise.
  # spec 12.3.1.
  # attributes are numbered from 0 to 31, and stored in 4 bytes,
  # bits starting at "most significant" and ending at "least".
  # ie attrib 0 is high bit of first byte, attrib 31 is low bit of 
  # last byte.
  
  my $byte_offset = $attribute / 8;
  # which of the 4 bytes the attribute is in
  my $bit_position = ($attribute % 8);
  # which bit in the byte (starting at high bit, counted as #0)
  my $bit_shift = 7 - $bit_position;
  my $the_byte = GET_BYTE_AT($self->_attrib_offset() + $byte_offset);
  my $the_bit = ($the_byte >> $bit_shift) & 0x01;
  # move target bit into least significant byte

  if (Games::Rezrov::ZOptions::SNOOP_ATTR_TEST()) {
    write_message(sprintf "[Test attribute %d of %s (%s) = %d]",
		  $attribute,
		  $self->_object_id(),
		  ${$self->print()},
                  $the_bit == 1);
  }

  return ($the_bit == 1);
}

sub set_attr {
  # set an attribute for an object; spec 12.3.1
  my ($self, $attribute) = @_;
  my $byte_offset = $attribute / 8;
  my $bit_position = $attribute % 8;
  my $bit_shift = 7 - $bit_position;
  my $mask = 1 << $bit_shift;
  my $where = $self->_attrib_offset() + $byte_offset;
  my $the_byte = GET_BYTE_AT($where);
  $the_byte |= $mask;
  Games::Rezrov::StoryFile::set_byte_at($where, $the_byte);
  if (Games::Rezrov::ZOptions::SNOOP_ATTR_SET()) {
    write_message(sprintf "[Set attribute %d of %s (%s)]",
		  $attribute,
		  $self->_object_id(),
		  ${$self->print()});
  }
}

sub clear_attr {
  # clear an attribute for an object; spec 12.3.1
  my ($self, $attribute) = @_;
  my $byte_offset = $attribute / 8;
  my $bit_position = ($attribute % 8);
  my $bit_shift = 7 - $bit_position;
  my $mask = ~(1 << $bit_shift);
  my $where = $self->_attrib_offset() + $byte_offset;
  my $the_byte = GET_BYTE_AT($where);
  $the_byte &= $mask;
  Games::Rezrov::StoryFile::set_byte_at($where, $the_byte);
  if (Games::Rezrov::ZOptions::SNOOP_ATTR_CLEAR()) {
    write_message(sprintf "[Clear attribute %d of %s (%s)]",
		  $attribute,
		  $self->_object_id(),
		  ${$self->print()}
                  );
  }
}

sub new {
  my ($type, $object_id) = @_;

#  cluck "new zobj $object_id!\n" if $object_id == 0;
  return undef if $object_id == 0;
  # no such object
  
  my $self = [];
#  my $self = {};
  bless $self, $type;

  $self->_object_id($object_id);
  my $header = Games::Rezrov::StoryFile::header();

  my $attrib_offset = $header->attribute_starter() +
    $header->object_bytes() * ($object_id - 1);
  
  my $pointer_size = $header->pointer_size();
  $self->_pointer_size($pointer_size);

  my $parent_offset = $attrib_offset + $header->attribute_bytes();
  my $sibling_offset = $parent_offset + $pointer_size;
  my $child_offset = $sibling_offset + $pointer_size;
  my $properties_offset = $child_offset + $pointer_size;

  my $prop_addr = GET_WORD_AT($properties_offset);
  my $text_words = GET_BYTE_AT($prop_addr);
  # INLINE ME

  # spec section 12.4: property table header,
  # first byte is length of "short name" text
  $self->_property_start_index($prop_addr + 1 + ($text_words * 2));
  $self->_prop_addr($prop_addr);
  $self->_attrib_offset($attrib_offset);
  $self->_parent_offset($parent_offset);
  $self->_sibling_offset($sibling_offset);
  $self->_child_offset($child_offset);
  $self->_property_cache({});

  return $self;
}

sub get_property {
  # arg: property number
  my $zp;
  my $pc = $_[0]->_property_cache();
  if ($zp = $pc->{$_[1]}) {
#    printf STDERR "cache hit\n";
  } else {
    $zp = new Games::Rezrov::ZProperty($_[1], $_[0], $_[0]->_property_start_index());
    $pc->{$_[1]} = $zp;
#    print STDERR "\n";
  }

  return $zp;
}

sub remove {
    # remove this object from its parent/sibling chain.
  my ($self) = @_;
  my $parent = $self->get_parent();
  unless ($parent) {
    # no parent, quit
    return;
  } else {
    my $object_id = $self->_object_id();
    my $child = $parent->get_child();
    # get child of old parent
    if ($parent->get_child_id() == $object_id) {
      # first child matches: set child of old parent to first sibling
      # of the object being removed
      $parent->set_child_id($self->get_sibling_id());
    } else {
      my $prev_sib = $child;
      my $this_sib;
      for ($this_sib = $child->get_sibling(); defined($this_sib);
	   $prev_sib = $this_sib, $this_sib = $this_sib->get_sibling()) {
	if ($this_sib->_object_id() == $object_id) {
	  # found it
	  $prev_sib->set_sibling_id($this_sib->get_sibling_id());
	  last;
	  # set the "next sibling" pointer of the previous
	  # sibling in the chain to the next sibling of this
	  # object (the one we're removing).
	}
      }
      if (not defined($this_sib)) {
	# sanity check
	die("attempt to delete object " + $object_id + " failed!");
      }
    }
  }
  $self->set_parent_id(0);
  $self->set_sibling_id(0);
}

sub get_parent {
  return $_[0]->get_object($_[0]->_parent_offset());
}

sub get_sibling {
  return $_[0]->get_object($_[0]->_sibling_offset());
}

sub get_child {
  return $_[0]->get_object($_[0]->_child_offset());
}

sub get_object {
  # fetch ZObject with address at specified story byte
  my ($self, $offset) = @_;
  my $header = Games::Rezrov::StoryFile::header();

  my $id = $self->get_ptr($offset);
  if ($id >= 1 && $id <= $header->max_objects()) {
    return new Games::Rezrov::ZObject($id);
  } elsif ($id == 0) {
    # object id 0 means "nothing", return null
    return undef;
  } else {
    print STDERR "object id $id is out of range";
    return undef;
  } 
}

sub set_ptr {
  # args: offset value
  # set a value, depending on pointer size
  if ($_[0]->_pointer_size() == 1) {
    Games::Rezrov::StoryFile::set_byte_at($_[1], $_[2]);
  } else {
    Games::Rezrov::StoryFile::set_word_at($_[1], $_[2]);
  }
}

sub get_child_id {
  return $_[0]->get_ptr($_[0]->_child_offset());
}

sub get_parent_id {
  return $_[0]->get_ptr($_[0]->_parent_offset());
}

sub get_sibling_id {
  return $_[0]->get_ptr($_[0]->_sibling_offset());
}

sub set_parent_id {
  # set parent object id of this object to specified id
  $_[0]->set_ptr($_[0]->_parent_offset(), $_[1]);
}

sub set_child_id {
  $_[0]->set_ptr($_[0]->_child_offset(), $_[1]);
}

sub set_sibling_id {
  $_[0]->set_ptr($_[0]->_sibling_offset(), $_[1]);
}

sub print {
  my ($self, $text) = @_;
  $text = new Games::Rezrov::ZText() unless $text;
  # eek
  return scalar $text->decode_text($self->_prop_addr() + 1);
}

sub write_message {
  Games::Rezrov::StoryFile::write_text(shift, 1);
}

1;
