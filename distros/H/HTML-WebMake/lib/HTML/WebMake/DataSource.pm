#

package HTML::WebMake::DataSource;

###########################################################################

# To extend the protocols supported, implement a subclass of DataSourceBase and
# add a line of code to get_handler() below.  Note that you can get the values
# of any tag attributes using the $self->{attrs} hash on this object, so you
# can add your own required attributes without modifying this code; just
# read them from the hash in your own module.

use HTML::WebMake::DataSources::DirOfFiles;
use HTML::WebMake::DataSources::SVFile;

sub get_handler {
  my ($self, $proto) = @_;

  ($proto eq 'file') and
	return new HTML::WebMake::DataSources::DirOfFiles ($self);

  ($proto eq 'svfile') and
	return new HTML::WebMake::DataSources::SVFile ($self);

  # ...
}

###########################################################################


use Carp;
use strict;

use vars	qw{
  	@ISA 
};

@ISA = qw();


###########################################################################

sub new ($$$$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main, $src, $name, $attrs) = @_;
  local ($_);

  my $self = { %$attrs };
  bless ($self, $class);
  $self->{main} = $main;

  $_ = $name;
  if (!defined $_) {
    $_ = $self->{main}->{metadata}->get_attrdefault ('name');
  }
  $self->{name} = $_;

  $_ = $src;
  if (!defined $_) {
    $_ = $self->{main}->{metadata}->get_attrdefault ('src');
  }
  $self->{src} = $_;

  $self->{attrs} = $attrs;
  for my $attr (qw(prefix suffix namesubst nametr listname)) {
    next if (defined $self->{attrs}->{$attr});
    $self->{attrs}->{$attr} =
		  $self->{main}->{metadata}->get_attrdefault ($attr);
  }

  $self->{proto} = 'file';
  $self->{file_list} = [ ];

  # try to strip the proto from the src URL.
  if ($self->{src} =~ s/^([A-Za-z0-9]+)://) {
    $self->{proto} = $1;
    $self->{proto} =~ tr/A-Z/a-z/;
  }

  $self->{hdlr} = $self->get_handler ($self->{proto});

  if (!defined $self->{hdlr}) {
    warn "Unsupported ".$self->as_string()." protocol: ".$self->{proto}."\n";
  }
  $self;
}

# -------------------------------------------------------------------------

sub fixname {
  my ($self, $name) = @_;

  if (defined $self->{attrs}->{prefix}) {
    $name = $self->{attrs}->{prefix}.$name;
  }
  if (defined $self->{attrs}->{suffix}) {
    $name .= $self->{attrs}->{suffix};
  }

  if (defined $self->{attrs}->{namesubst}) {
    if ($self->{main}->{paranoid}) { goto para_on; }
    eval '$name =~ '.$self->{attrs}->{namesubst}.';1;'
    	or warn "namesubst failed: $!\n";
  }
  if (defined $self->{attrs}->{nametr}) {
    if ($self->{main}->{paranoid}) { goto para_on; }
    eval '$name =~ '.$self->{attrs}->{nametr}.';1;'
    	or warn "nametr failed: $!\n";
  }
  return $name;

para_on:
  warn "Paranoid mode on: not processing namesubst\n";
  return $name;
}

sub add_file_to_list {
  my ($self, $name) = @_;

  push (@{$self->{file_list}}, $name);
}

# -------------------------------------------------------------------------

sub add {
  my $self = shift;

  HTML::WebMake::Main::dbg ($self->as_string().
  			": src=$self->{proto}:$self->{src}");

  if (!defined $self->{hdlr}) { return; }
  $self->{hdlr}->add ();

  my $lname = $self->{attrs}->{listname};
  if (defined $lname) {
    # add onto any existing values already there.
    # the ? at the end means "return '' if not defined"
    my $val = $self->{main}->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, $lname.'?');
    if ($val ne '') { $val .= ' '; }
    $val .= join (' ', @{$self->{file_list}});

    $self->{main}->set_unmapped_content ($lname, $val);
  }
}

# -------------------------------------------------------------------------

sub get_location_contents {
  my ($self, $fname) = @_;
  if (!defined $self->{hdlr}) { return; }
  $self->{hdlr}->get_location_contents ($fname);
}

# -------------------------------------------------------------------------

sub get_location_mod_time {
  my ($self, $fname) = @_;
  if (!defined $self->{hdlr}) { return; }
  $self->{hdlr}->get_location_mod_time ($fname);
}

1;
