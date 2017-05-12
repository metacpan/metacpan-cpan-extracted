#

package HTML::WebMake::Metadata;

###########################################################################


use Carp;
use strict;

use HTML::WebMake::Main;

use vars	qw{
  	@ISA %BUILTIN_TYPES $NUM $STR
};

# -------------------------------------------------------------------------

$NUM = 1;
$STR = 2;

%BUILTIN_TYPES = (
  'score'	=> { type => $NUM, default => 50 },
  'title'	=> { type => $STR, default => '(Untitled)' },
  'abstract'	=> { type => $STR, default => '' },
  'section'	=> { type => $STR, default => '' },
  'declared'	=> { type => $NUM, default => 0 },

# some pseudo-metadata types. These are not strictly metadata, but
# they are available through Content::get_metadata().
  'url'		=> { type => $STR, default => '' },
  'is_generated' => { type => $NUM, default => 0 },
  'mtime'	=> { type => $NUM, default => 0 },
);

# -------------------------------------------------------------------------




###########################################################################

sub new ($$$$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main) = @_;

  my $self = {
    'main'		=> $main,
    'metadefaults'	=> { },
    'attrdefaults'	=> { },
  };
  bless ($self, $class);

  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }

# -------------------------------------------------------------------------

sub get_type {
  my ($self, $meta) = @_;

  croak "no meta defined in get_type" unless defined($meta);

  my $info = $BUILTIN_TYPES{$meta};
  if (!defined $info) { return undef; }
  
  return $info->{type};
}

sub get_default_value {
  my ($self, $meta) = @_;

  croak "no meta defined in get_default_value" unless defined($meta);

  my $info = $BUILTIN_TYPES{$meta};
  if (!defined $info) { return undef; }
  
  return $info->{default};
}

# -------------------------------------------------------------------------

sub convert_to_type {
  my ($self, $meta, $val) = @_;

  croak "no meta defined in get_type" unless defined($meta);
  croak "no val defined in get_type" unless defined($val);

  my $info = $BUILTIN_TYPES{$meta};
  if (!defined $info) { return undef; }
  
  if ($info->{type} == $NUM) {
    $val+0;		# convert to numeric
  } else {
    $val;
  }
}

# -------------------------------------------------------------------------

sub string_to_sort_sub {
  my ($self, $sortstring) = @_;

  my @substrs = ();
  foreach my $item (split (' ', $sortstring)) {
    my $aname = '$a';
    my $bname = '$b';

    # !value means reverse-sort by that value, ie. swap $a and $b.
    if ($item =~ s/^!//) { $aname = '$b'; $bname = '$a'; }

    my $type = $self->get_type ($item);
    if (!defined $type) {
      carp "no type defined for metadatum \"$item\"\n";
      next;
    }

    my $cmpstr = '';
    if ($type eq $NUM) {
      $cmpstr = " <=> ";
    } elsif ($type eq $STR) {
      $cmpstr = " cmp ";
    } else {
      die "oops? unknown type $type for $item";
    }
    
    push (@substrs , '('.	#)
	  $aname.'->get_metadata(q{'.$item.'})'.$cmpstr.
	  $bname.'->get_metadata(q{'.$item.'}))');
  }

  if ($#substrs < 0) {
    croak "no usable sort items defined\n";
  }

  my $substr = 'sub {'.join (' || ', @substrs).'}';	#}
  dbg ("string to sort-sub: \"$sortstring\": $substr");

  $substr;
}

# -------------------------------------------------------------------------

sub set_metadefault {
  my ($self, $name, $value) = @_;
  
  $name = lc $name;

  if (defined $value && $value eq '[POP]') {
    shift (@{$self->{metadefaults}->{$name}});

  } elsif (defined $value) {
    if (!defined $self->{metadefaults}->{$name}) {
      $self->{metadefaults}->{$name} = [ ];
    }
    unshift (@{$self->{metadefaults}->{$name}}, $value);
  } else {

    unshift (@{$self->{metadefaults}->{$name}}, undef);
  }
}

# -------------------------------------------------------------------------

sub add_metadefaults {
  my ($self, $contobj) = @_;
  my ($metaname, $val);

  while (($metaname, $val) = each %{$self->{metadefaults}}) {
    # dbg ("adding metadefault: \"$metaname\" => \"$val\"");
    if (defined $val && defined $val->[0]) {
      $contobj->create_extra_metas_if_needed();
      $contobj->{extra_metas}->{$metaname} = $val->[0];
    }
  }
}

# -------------------------------------------------------------------------

sub set_attrdefault {
  my ($self, $name, $value) = @_;
  
  $name = lc $name;

  if (defined $value && $value eq '[POP]') {
    shift (@{$self->{attrdefaults}->{$name}});

  } elsif (defined $value) {
    if (!defined $self->{attrdefaults}->{$name}) {
      $self->{attrdefaults}->{$name} = [ ];
    }
    unshift (@{$self->{attrdefaults}->{$name}}, $value);

  } else {
    unshift (@{$self->{attrdefaults}->{$name}}, undef);
  }
}

sub get_attrdefault {
  my ($self, $name) = @_;

  my $ary = $self->{attrdefaults}->{$name};
  if (!defined $ary) { return undef; }
  $ary->[0];
}

# -------------------------------------------------------------------------

1;
