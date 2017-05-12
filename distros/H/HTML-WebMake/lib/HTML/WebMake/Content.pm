#

=head1 NAME

Content - a content item.

=head1 SYNOPSIS

  <{perl

    $cont = get_content_object ("foo.txt");
    [... etc.]

  }>

=head1 DESCRIPTION

This object allows manipulation of WebMake content items directly.

=head1 METHODS

=over 4

=cut

package HTML::WebMake::Content;


use Carp;
use strict;
use locale;

use vars	qw{
  	@ISA
	%SORT_SUBS
};

@ISA = qw();


%SORT_SUBS = ();

###########################################################################

sub new ($$$$$$$) {
  my $class = shift;
  $class = ref($class) || $class;

  my ($name, $file, $attrs, $text, $datasource, $ismetadata) = @_;
  my $attrval;

  my $self = { %$attrs };	# copy the attrs
  bless ($self, $class);

  $self->{name}			= $name;
  $self->{main}			= $file->{main};

  if (defined $text) {
    $self->{text}		= $text;
  }

  my $metadata = $self->{main}->{metadata};

  # check this content item's format. text/html is the default, so
  # if it's set to that, delete it to save space; otherwise, convert
  # it to a compressed representation to save space.
  $attrval = $attrs->{'format'};
  $attrval ||= $metadata->get_attrdefault ('format');
  if (defined $attrval) {
    if ($attrval eq 'text/html') {
      delete $self->{format};
    } else {
      $self->{format} =
	  HTML::WebMake::FormatConvert::format_name_to_zname($attrval);
    }
  }

  $self->{location}		= \$file->{filename};
  $self->{deps}			= $self->mk_deps ($file->get_deps());

  # sitemap support.
  $attrval = $attrs->{'up'};
  $attrval ||= $metadata->get_attrdefault ('up');
  if (defined $attrval) {
    $self->{up_name} = $attrval;
    delete $self->{'up'};	# in case it was set as an attr
  }

  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }
sub vrb { HTML::WebMake::Main::vrb (@_); }

# -------------------------------------------------------------------------

=item $text = $cont->get_name();

Return the content item's name.

=cut

sub get_name {
  my ($self) = @_;
  $self->{name};
}

=item $text = $cont->as_string();

A textual description of the object for debugging purposes; currently it's
name.

=cut

sub as_string {
  my ($self) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

=item $fname = $cont->get_filename();

Get the filename or datasource location that this content was loaded from.
Datasource locations look like this:
C<proto>:C<protocol-specific-location-data>, e.g. C<file:blah/foo.txt> or
C<http://webmake.taint.org/index.html>.

=cut

sub get_filename {
  my ($self) = @_;
  return ${$self->{location}};
}

=item @filenames = $cont->get_deps();

Return an array of filenames and locations that this content depends on, i.e.
the filenames or locations that it contains variable references to.

=cut

sub get_deps {
  my ($self) = @_;

  map {
    if ($_ eq "\001") { $self->{location}; }
    else { $_; }
  } split (/\0/, $self->{deps});
}

sub mk_deps {
  my ($self, $deps) = @_;
  my @compressed = ();

  foreach my $dep (@{$deps}) {
    if ($dep eq $HTML::WebMake::Main::SUBST_DEP_IGNORE) { next; }
    elsif ($dep eq $HTML::WebMake::Main::SUBST_META) { next; }
    elsif ($dep eq $self->{location}) { push (@compressed, "\001"); next; }
    push (@compressed, $dep);
  }

  join ("\0", @compressed);
}

=item $flag = $cont->is_generated_content();

Whether or not a content item was generated from Perl code, or is metadata.
Generated content items cannot themselves hold metadata.

=cut

sub is_generated_content {
  my ($self) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

=item $val = $cont->expand()

Expand a content item, as if in a curly-bracket content reference.  If the
content item has not been expanded before, the current output file will be
noted as the content item's ''main'' URL.

=cut

sub expand {
  my ($self) = @_;
  croak "undefined by subclass";
}

=item $val = $cont->expand_no_ref()

Expand a content item, as if in a curly-bracket content reference.  The current
output file will not be used as the content item's ''main'' URL.

=cut

sub expand_no_ref {
  my ($self) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

=item $val = $cont->get_metadata($metaname);

Get an item of this object's metadata, e.g.

	$score = $cont->get_metadata("score");

The metadatum is converted to its native type, e.g. C<score> is return as an
integer, C<title> as a string, etc.  If the metadatum is not provided, the
default value for that item, defined in HTML::WebMake::Metadata, is used.

=cut

sub get_metadata {
  my ($self, $key) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

sub create_extra_metas_if_needed {
  my ($self) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

sub load_metadata {
  my ($self) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

=item $score = $cont->get_score();

Return a content item's score.

=cut

sub get_score {
  my ($self) = @_;
  croak "undefined by subclass";
}

=item $title = $cont->get_title();

Return a content item's title.

=cut

sub get_title {
  my ($self) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

=item $modtime = $cont->get_modtime();

Return a content item's modification date, in UNIX time_t format,
ie. seconds since Jan 1 1970.

=cut

sub get_modtime {
  my ($self) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

sub set_declared {
  my ($self, $order) = @_;
  $self->{decl_order} = $order;
}

=item $order = $cont->get_declared();

Returns the content item's declaration order.  This is a number representing
when the content item was first encountered in the WebMake file; earlier
content items have a lower declaration order. Useful for sorting.

=cut

sub get_declared {
  my ($self) = @_;
  return $self->{decl_order};
}

# -------------------------------------------------------------------------

sub get_magic_metadata {
  my ($self, $from, $key) = @_;
  my $val;

  if ($key eq 'name') {
    return $self->get_name();
  }

  elsif ($key eq 'url') {
    return "" if ($self->is_generated_content());
    $val = $self->get_url();
    if (!defined $val) {
      vrb ("no URL defined for content \${".$self->{name}.
                                ".$key} in \"$from\".");
      return "";
    }
    return $val;
  }

  elsif ($key eq 'mtime') {
    return $self->get_modtime();
  }

  elsif ($key eq 'declared') {
    return $self->get_declared();
  }

  elsif ($key eq 'is_generated') {
    return ($self->is_generated_content()) ? '1' : '0';
  }

  return undef;
}

# -------------------------------------------------------------------------

sub add_kid {
  my ($self, $kid) = @_;

  return if ($kid eq $self);

  if (!defined $self->{kids}) {
    $self->{kids} = [ ];
  }

  push (@{$self->{kids}}, $kid);
}

sub has_any_kids {
  my ($self) = @_;
  if (!defined $self->{kids}) { return 0; }
  if ($#{$self->{kids}} >= 0) { return 1; }
  return 0;
}

=item @kidobjs = $cont->get_kids ($sortstring);

Get the child content items for this item.  The ''child'' content items
are items that use this content as their C<up> metadatum.

Returns a list of content objects in unsorted order.

=cut

sub get_kids {
  my ($self) = @_;
  if (!defined $self->{kids}) { return (); }
  @{$self->{kids}};
}

=item @kidobjs = $cont->get_sorted_kids ($sortstring);

Get the child content items for this item.  The ''child'' content items
are items that use this content as their C<up> metadatum.

Returns a list of content objects sorted by the provided sort string.

=cut

sub get_sorted_kids {
  my ($self, $sortby) = @_;

  my $sortsub;
  if (defined $sortby) {
    $sortsub = $self->get_sort_sub($sortby);
  } elsif (defined $self->{kid_sort_str}) {
    $sortsub = $self->get_sort_sub($self->{kid_sort_str});
  } else {
    $sortsub = $self->get_sort_sub('score title declared');
  }
  sort $sortsub ($self->get_kids());
}

sub set_sort_string {
  my ($self, $str) = @_;
  $self->{kid_sort_str} = $str;
}

# -------------------------------------------------------------------------

# get and eval() a sort subroutine for the given sorting criteria.
# stores cached sort sub { } refs in the %SORT_SUBS global array to
# avoid re-evaluating the same piece of perl code repeatedly.
#
sub get_sort_sub {
  my ($self, $sortstr) = @_;

  if (!defined $SORT_SUBS{$sortstr}) {
    my $sortsubstr = $self->{main}->{metadata}->string_to_sort_sub ($sortstr);
    my $sortsub = eval $sortsubstr;
    $SORT_SUBS{$sortstr} = $sortsub;
  }

  $SORT_SUBS{$sortstr};
}

# -------------------------------------------------------------------------

sub get_format {
  my ($self) = @_;
  if (!defined $self->{format}) { return 'text/html'; }
  return HTML::WebMake::FormatConvert::format_zname_to_name($self->{format});
}

# -------------------------------------------------------------------------

sub get_text_as {
  my ($self, $format) = @_;
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

sub unload_text { }

sub is_from_datasource { 0; }

sub touch_last_used { }

# -------------------------------------------------------------------------

sub get_up_content {
  my ($self) = @_;
  my $cont;

  if (defined $self->{up_obj}) { return $self->{up_obj}; }

  # magic variables do not appear in the tree.
  if ($self->{name} =~ /^WebMake\./) { return undef; }

  # see if we got an "up" attr passed in.
  if (defined $self->{up_name}) {
    $cont = $self->up_name_to_content ($self->{up_name});
    if (defined $cont) { return $cont; }
    # else, it's not valid; clear it.
    undef $self->{up_name};
  }

  # see if we have an "up" metadatum.
  if (!$self->is_generated_content()) {
    my $meta = $self->{main}->quiet_curly_meta_subst
			  ($HTML::WebMake::Main::SUBST_META, $self->{name}.".up");
    if (defined $meta && $meta ne '') {
      $cont = $self->up_name_to_content ($meta);
      if (defined $cont) {
	return $cont;
      }
    }
  }

  # ach, no "up" item. Use the root content.
  return $self->up_name_to_content ($HTML::WebMake::SiteMap::ROOTNAME);
}

sub up_name_to_content {
  my ($self, $name) = @_;

  my $cont;
  if ($name eq $HTML::WebMake::SiteMap::ROOTNAME) {
    $cont = $self->{main}->getmapper()->get_root();
    if (!defined $cont) { return undef; }
  } else {
    $cont = $self->{main}->get_content_obj($name);
  }

  if (defined $cont) {
    $self->{up_name} = $name;
    $self->{up_obj} = $cont;
    return $cont;
  }

  warn $self->as_string().": \"up\" content not found: \$\{".
	      $name."\}\n";
  return undef;
}

# -------------------------------------------------------------------------

sub add_ref_from_url {
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

=item $text = $cont->get_url();

Get a content item's URL.  The URL is defined as the first page listed in the
WebMake file's out tags which refers to that item of content.

Note that, in some cases, the content item may not have been referred to yet by
the time it's get_url() method is called.  In this case, WebMake will insert a
symbolic tag, hold the file in memory, and defer writing the file in question
until all other output files have been processed and the URL has been found.

=cut

sub get_url {
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

sub set_next {
  my ($self, $cont) = @_;
  $self->{next_content} = $cont;
}

sub set_prev {
  my ($self, $cont) = @_;
  $self->{prev_content} = $cont;
}

sub set_up {
  my ($self, $cont) = @_;
  $self->{up_content} = $cont;
}

sub invalidate_cached_nav_metadata { }

# -------------------------------------------------------------------------

sub is_only_usable_from_deferred_refs {
  croak "undefined by subclass";
}

# -------------------------------------------------------------------------

1;
