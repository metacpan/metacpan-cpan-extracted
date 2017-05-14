package Games::Rezrov::ZProperty;
# object properties

use strict;

use constant FIRST_PROPERTY => -1;
# used to find the first property in the object

use Games::Rezrov::Inliner;
use Games::Rezrov::InlinedPrivateMethod;

my $code = new Games::Rezrov::InlinedPrivateMethod("-manual" => 1,
						   "-names" =>
						   [ qw (
							 _property_exists
							 _property_number
							 _property_len
							 _property_offset
							 _size_byte
							 _pointer
							 _pre_v4
							 _zobj
							 _search_id
							)
						   ],
						  );
Games::Rezrov::Inliner::inline($code);

#print $$code; die;

eval $$code; die $@ if $@;

1;

__DATA__

sub property_exists {
  # public, read-only
  return $_[0]->_property_exists();
}

sub property_number {
  # public, read-only
  return $_[0]->_property_number();
}

sub get_value {
  # return this value for this property
  if ($_[0]->_property_exists()) {
    # this object provides this property
    my $len = $_[0]->_property_len();
    my $v;
    if ($len == 2) {
      $v = GET_WORD_AT($_[0]->_property_offset());
    } elsif ($len == 1) {
      $v = GET_BYTE_AT($_[0]->_property_offset());
    } else {
      die "get_value() called on long property";
    }

    if (Games::Rezrov::ZOptions::SNOOP_PROPERTIES()) {
      printf STDERR "[get property %s of %s (%s) = %s (size=%d)\n",
	$_[0]->property_number(),
	  $_[0]->_zobj()->object_id(),
	    ${$_[0]->_zobj()->print()},
	      $v,
		$len;
  }

    return $v;
  } else {
    # object does not provide this property: get default value
    return $_[0]->get_default_value();
  }
}

sub next {
  # search for a specific property, or move to the next one
  my ($self, $search_id) = @_;
  die("attempt to read past end of property list")
    if ($self->_size_byte() == 0);
  my $pointer = $self->_pointer();

  my $property_number;
  my $exists = 0;
  my $size_byte;
  my $property_len;
  my $last_id;
  my $property_offset = 0;
  my $pre_v4 = $self->_pre_v4();
  while (1) {
#    print STDERR "search\n";
    $size_byte = GET_BYTE_AT($pointer);
    if ($size_byte == 0) {
      $property_number = 0;
      last;
    } else {
      my $size_bytes = 1;
      if ($pre_v4) {
	# spec 12.4.1:
	$property_number = $size_byte & 0x1f;
	# property number is in bottom 5 bytes
	$property_len = ($size_byte >> 5) + 1;
	# 12.4.1: shifted value is # of bytes minus 1
      } else {
	# spec 12.4.2:
	$property_number = $size_byte & 0x3f;
	# property number in bottom 6 bits
	if (($size_byte & 0x80) > 0) {
	  # top bit is set, there is a second size byte
	  $property_len = GET_BYTE_AT($pointer + 1) & 0x3f;
	  # length in bottom 6 bits
	  $size_bytes = 2;
	  if ($property_len == 0) {
	    # 12.4.2.1.1
#	    print STDERR "wacky inform compiler size; test this!";
	    $property_len = 64;
	  }
	} else {
	  # 14.2.2.2
	  $property_len = ($size_byte & 0x40) > 0 ? 2 : 1;
	}
      }
      $property_offset = $pointer + $size_bytes;
      $pointer += $size_bytes + $property_len;
    }

    if (!(defined $search_id) or $search_id == FIRST_PROPERTY) {
      # move to next/first property
      $exists = 1;
      last;
    } else {
      if ($last_id and $property_number > $last_id) {
	# 12.4: properties are stored in descending numerical order
	# this means we are past the end
	# ...need example case here!
	last;
      } elsif ($search_id > $property_number) {
	# went past where it would have been had it existed
	last;
      } else {
	$last_id = $property_number;
	if ($property_number == $search_id) {
	  #      print STDERR "got it\n";
	  $exists = 1;
	  last;
	  # 12.4.1
	}
      }
    }
  }
  $self->_property_exists($exists);
#  print STDERR "exists: $exists\n";
  $self->_property_len($property_len);
  $self->_property_number($property_number);
  $self->_size_byte($size_byte);
  $self->_property_offset($property_offset);
  $self->_pointer($pointer);
}

sub get_default_value {
  # get the default value for this property ID
  # spec 12.2
  my $offset = Games::Rezrov::StoryFile::header()->object_table_address() +
    (($_[0]->_search_id() - 1) * 2);
  # FIX ME
  return(GET_WORD_AT($offset));
}

sub new {
  my ($type, $search_id, $zobj, $psi) = @_;

#  printf STDERR "new zprop %s for obj %s\n", $search_id, $zobj->object_id();

  my $self = [];
  bless $self, $type;

  $self->_zobj($zobj);
  $self->_pre_v4(Games::Rezrov::StoryFile::version() <= 3);
  $self->_search_id($search_id);

  $self->_size_byte(-1);
  $self->_pointer($psi);
  $self->_property_offset(-1);
  $self->next($search_id);
  return $self;
}

sub set_value {
  # set this property to specified value
  my ($self, $value) = @_;
  if ($self->_property_exists()) {
#    print STDERR "set_value to $value\n";
    my $len = $self->_property_len();
    my $offset = $self->_property_offset();
    if (Games::Rezrov::ZOptions::SNOOP_PROPERTIES()) {
      Games::Rezrov::StoryFile::write_text(sprintf("[set property %d of %s (%s) = %d]",
					   $self->_property_number(),
					   $self->_zobj()->object_id(),
					   ${$self->_zobj()->print()},
                                           $value), 1);
    }
    if ($len == 1) {
      Games::Rezrov::StoryFile::set_byte_at($offset, $value);
    } elsif ($len == 2) {
      Games::Rezrov::StoryFile::set_word_at($offset, $value);
    } else {
      die("set_value called on long property");
    }
  } else {
    die("attempt to set nonexistent property") unless $Games::Rezrov::IGNORE_PROPERTY_ERRORS;
    # cheating
  }
}

sub get_data_address {
  return $_[0]->_property_offset();
}

sub get_next {
  # return a new ZProperty object representing the property 
  # after this one.  total hack!
  my $self = shift;
  my $next = [];
  bless $next, ref $self;
  @{$next} = @{$self};
  # make a copy of of $self
  $next->next();
  # make new property point to the next one in the list
  return $next;
}

1;
