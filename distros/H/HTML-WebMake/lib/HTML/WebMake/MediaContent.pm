#
# content items used for media items. In reality this is just
# used as a placeholder for metadata.

package HTML::WebMake::MediaContent;

use HTML::WebMake::Content;
use Carp;
use strict;
use locale;

use vars	qw{
  	@ISA
	$MIN_FMT_CACHE_LEN
};

@ISA = qw(HTML::WebMake::Content);

$MIN_FMT_CACHE_LEN = 1024;

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my ($main, $name, $attrs) = @_;

  my $self = $class->SUPER::new ($name,
  		$main->{ignore_for_dependencies},
		$attrs, '', undef);

  bless ($self, $class);

  # do some references now to avoid doing them later, minor speedup
  my $util = $main->{util};
  my $metadata = $main->{metadata};
  my $attrval;

  # see if we have 'map=false' as an attribute
  $attrval = $attrs->{'map'};
  $attrval ||= $metadata->get_attrdefault ('map');
  if (defined $attrval) {
    if (!$util->parse_boolean ($attrval)) {
      $self->{no_map} = 1;
    }
    delete $self->{'map'};      # in case it was set as an attr
  }

  $self->{keep_as_is} = 1;
  $metadata->add_metadefaults ($self);

  $main->add_new_content_to_map ($name, $self);

  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }
sub dbg2 { HTML::WebMake::Main::dbg2 (@_); }
sub vrb { HTML::WebMake::Main::vrb (@_); }

# -------------------------------------------------------------------------

sub as_string {
  my ($self) = @_;
  "\$\{".$self->{name}."\}";
}

# -------------------------------------------------------------------------

sub is_generated_content {
  0;
}

# -------------------------------------------------------------------------

sub expand {
  my ($self) = @_;
  return $self->{main}->curly_subst ($self->{name}, $self->{name});
}

sub expand_no_ref {
  my ($self) = @_;
  return $self->{main}->fileless_subst ($self->{name}, '${'.$self->{name}.'}');
}

# -------------------------------------------------------------------------

sub get_metadata {
  my ($self, $key) = @_;

  if (!defined $self->{cached_metas}) {
    $self->{cached_metas} = { };
  }

  my $val = $self->{cached_metas}->{$key};
  my $main = $self->{main};

  if (!defined $val) {
    $val = $main->quiet_curly_meta_subst ($HTML::WebMake::Main::SUBST_META, $self->{name}.".".$key);
    $val ||= $main->{metadata}->get_default_value ($key);

    $val = $main->{metadata}->convert_to_type ($key, $val);
    $self->{cached_metas}->{$key} = $val;
  }

  return $val;
}

# -------------------------------------------------------------------------

sub create_extra_metas_if_needed {
  my ($self) = @_;
  if (!defined $self->{extra_metas}) {
    $self->{extra_metas} = { };
  }
}

# -------------------------------------------------------------------------

sub load_metadata {
  my ($self) = @_;

  if (!defined ($self->{parsed_metadata_tags})) {
    $self->add_extra_metas ($self->{name});
    $self->infer_implicit_metas();
    $self->{parsed_metadata_tags} = 1;
  }
}

# -------------------------------------------------------------------------

sub parse_metadata_tags {
  return;
}

# -------------------------------------------------------------------------

sub infer_implicit_metas {
  my ($self) = @_;

  if (defined $self->{main}->{metadatas}->{"this.title"}
        && defined $self->{main}->{metadatas}->{$self->{name}.".title"})
  {
    return;             # no need to infer it, it's already defined
  }

  # TODO? read titles from GIF comments etc?

  my $val = $self->{name};
  $val =~ s,^.*[/\\],,g;
  $val =~ s,\.(?:gif|jp[eg]+|mp[eg3]+|xpm|bmp|tif+|mov|ra|ram|png|mng)$,,ig;
  $val =~ s/_/ /gs;
  $self->add_inferred_metadata ("title", $val);
}

# -------------------------------------------------------------------------

sub add_inferred_metadata {
  my ($self, $name, $val) = @_;

  my $attrs = { };

  $val =~ s/<[^>]+>//g;         # trim wayward HTML tags
  $val =~ s/^\s+//;
  $val =~ s/\s+$//;

  dbg ("inferring $name metadata from image: \"$val\"");
  $self->{main}->add_metadata ($self->{name}, $name, $val, $attrs, 0);
}

# -------------------------------------------------------------------------

sub add_extra_metas {
  my ($self, $from) = @_;
  # also add our own extra metadata from nav links, <defaultmeta> tags
  # etc.
  my ($metaname, $val);
  while (($metaname, $val) = each %{$self->{extra_metas}}) {
    $self->{main}->add_metadata ($from, $metaname, $val, { }, 1);
  }
}

# -------------------------------------------------------------------------

sub get_score {
  my ($self) = @_;
  return $self->get_metadata ("score");
}

sub get_title {
  my ($self) = @_;
  return $self->get_metadata ("title");
}

# -------------------------------------------------------------------------

sub get_modtime {
  my ($self) = @_;
  return $self->{main}->cached_get_modtime ($self->get_filename());
}

# -------------------------------------------------------------------------

sub get_text_as {
  my ($self, $format) = @_;

  # TODO -- return an <img> tag for images etc.?
  return '';
}

# -------------------------------------------------------------------------

sub load_text_if_needed {
  return;
}

sub unload_text {
  return;
}

sub is_from_datasource {
  return 0;
}

sub touch_last_used {
  return;
}

# -------------------------------------------------------------------------

sub add_ref_from_url {
  my ($self, $filename) = @_;

  return if ($filename =~ /^\(/);       # (eval), (dep_ignore) etc.

  if (!defined $self->{reffed_in_url}) {
    $self->{reffed_in_url} = $filename;
  }
}

sub get_url {
  my ($self) = @_;

  my $url = $self->{reffed_in_url};
  if (defined $url) { return $url; }
  
  $url = $self->{main}->getcache()->get_metadata ($self->{name}.".url");
  
  if (defined $url) {
    $self->{reffed_in_url} = $url;
    return $url;
  }
  
  $url = $self->{main}->make_deferred_url ($self->{name});
  return $url;
}

# -------------------------------------------------------------------------

sub add_navigation_metadata {
  my ($self) = @_;

  return if ($self->{no_map} || $self->is_generated_content());
  return if ($self->{added_nav_metas_flag});
  $self->{added_nav_metas_flag} = 1;

  $self->create_extra_metas_if_needed();
  if (defined ($self->{up_content})) {
    $self->{extra_metas}->{'nav_up'} = $self->{up_content}->get_name();
  }
  if (defined ($self->{next_content})) {
    $self->{extra_metas}->{'nav_next'} = $self->{next_content}->get_name();
  }
  if (defined ($self->{prev_content})) {
    $self->{extra_metas}->{'nav_prev'} = $self->{prev_content}->get_name();
  }
}

sub invalidate_cached_nav_metadata {
  my ($self) = @_;
  $self->{added_nav_metas_flag} = 0;
}

# -------------------------------------------------------------------------

sub is_only_usable_from_deferred_refs {
  0;
}

# -------------------------------------------------------------------------

1;
