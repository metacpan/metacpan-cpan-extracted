#
# content items used to store "normal", non-metadata content.

package HTML::WebMake::NormalContent;

use HTML::WebMake::Content;
use Carp;
use strict;
use locale;

use vars	qw{
  	@ISA
	$WM_META_PAT $MIN_FMT_CACHE_LEN
};

@ISA = qw(HTML::WebMake::Content);


$WM_META_PAT = qr{<wm meta}x;
$MIN_FMT_CACHE_LEN = 1024;

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my ($name, $file, $attrs, $text, $datasource) = @_;
  my $self = $class->SUPER::new (@_);

  bless ($self, $class);

  # do some references now to avoid doing them later, minor speedup
  my $main = $self->{main};
  my $util = $main->{util};
  my $metadata = $main->{metadata};
  my $attrval;

  # used for Content items defined from Contents sections
  if (defined $datasource) {
    $self->{datasource}		= $datasource;
  }

  # see if we have 'map=false' as an attribute
  $attrval = $attrs->{'map'};
  $attrval ||= $metadata->get_attrdefault ('map');
  if (defined $attrval) {
    if (!$util->parse_boolean ($attrval)) {
      $self->{no_map} = 1;
    }
    delete $self->{'map'};      # in case it was set as an attr
  }

  # is this content item formatted as-is, no content refs to be expanded
  # etc.?
  $attrval = $attrs->{'asis'};
  $attrval ||= $metadata->get_attrdefault ('asis');
  if (defined $attrval) {
    $self->{keep_as_is} = $util->parse_boolean ($attrval);
    delete $self->{'asis'};	# in case it was set as an attr
  }

  $attrval = $attrs->{'isroot'};
  $attrval ||= $metadata->get_attrdefault ('isroot');
  if (defined $attrval) {
    $self->{is_root} = $util->parse_boolean ($attrval);
    delete $self->{'isroot'};	# in case it was set as an attr
  }

  if (defined $attrs->{is_sitemap}) {
    $self->{is_sitemap}	=
  	$util->parse_boolean ($attrs->{is_sitemap});
  }

  $attrval = $attrs->{'preproc'};
  $attrval ||= $metadata->get_attrdefault ('preproc');
  if (defined $attrval) {
    $self->{preproc} = $attrval;
  }

  if ($self->{is_sitemap}) {
    $self->{sitemap_node_name}	= $attrs->{node};
    $self->{sitemap_leaf_name}	= $attrs->{leaf};
    $self->{sitemap_dynamic_name} = $attrs->{dynamic};
  }

  if ($self->{is_root}) {
    $main->getmapper()->set_root ($self);
  }

  # is_navlinks is an attribute set by Main::add_navlinks().
  if ($self->{is_navlinks}) {
    $self->{cannot_have_metadata} = 1;
    $self->{only_usable_from_def_refs} = 1;
    $self->{no_map}		= 1;
  }

  # is_breadcrumbs: set by Main::add_breadcrumbs().
  if ($self->{is_breadcrumbs}) {
    $self->{cannot_have_metadata} = 1;
    $self->{only_usable_from_def_refs} = 1;
    $self->{no_map}		= 1;
  }

  if (!$self->{no_map}) {
    $metadata->add_metadefaults ($self);
  }

  if ($self->{is_root} && $self->{no_map}) {
    warn ($self->as_string().": root content cannot have \"map=false\"!\n");
    undef $self->{no_map};
  }

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
    $val = $main->quiet_curly_meta_subst
    		($HTML::WebMake::Main::SUBST_META, $self->{name}.".".$key);
    if (!defined $val) {
      $val ||= $main->{metadata}->get_default_value ($key);
    }

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
  my ($self, $name, $key) = @_;

  # a different method is used to load metadata from the current content
  # item, so this should not happen:
  if ($key =~ /^this\./i) {
    warn "oops! wasn't expecting a this. metaref in load_metadata: $key";
  }

  # unmapped content can't have metadata
  if ($self->{no_map}) { return; }

  if (defined $self->{extra_metas}->{$key}) {
    $self->add_extra_metas ($name);
    return;		# we don't need to parse the text for this metadatum
  }

  if (!defined ($self->{parsed_metadata_tags})) {
    dbg ("loading content \"$name\" for meta ref \$\[$key\]");
    $self->load_text_if_needed();

    $self->{set_thisdot_metadata_items} = 0;
    $self->parse_metadata_tags ($name, $self->{text});

    $self->add_extra_metas ($name);
    $self->infer_implicit_metas();

    $self->{parsed_metadata_tags} = 1;
  }
}

# -------------------------------------------------------------------------

sub parse_metadata_tags {
  my ($self, $from, $str) = @_;

  if ($str !~ /${WM_META_PAT}/i) { return; }

  my $util = $self->{main}->{util};

  $self->{meta_from} = $from;
  $str = $util->strip_tags ($str, "wmmeta",
                            $self, \&tag_wmmeta, qw(name));
  $self->{meta_from} = undef;

  if ($str =~ /${WM_META_PAT}.*?>/i) {
    warn "<wm"."meta> tag could not be parsed: \${$from} in ".
              $self->{main}->{current_subst}->{filename}.": $&\n";
  }
}

sub tag_wmmeta {
  my ($self, $tag, $attrs, $text) = @_;

  my $name = lc $attrs->{name};

  # use a "value" attr if available; otherwise use the text
  # inside the tag.
  my $val = $attrs->{value};
  if (!defined $val) { $val = $text; }

  $self->{main}->add_metadata ($self->{meta_from}, $name, $val, $attrs,
    		$self->{set_thisdot_metadata_items});

  "";
}

# -------------------------------------------------------------------------

sub infer_implicit_metas {
  my ($self) = @_;

  if (defined $self->{main}->{metadatas}->{"this.title"}
  	&& defined $self->{main}->{metadatas}->{$self->{name}.".title"})
  {
    return;		# no need to infer it, it's already defined
  }

  # Snarf a default title from the text, if one has not been set.
  $self->find_implicit_title_in_text (\$self->{text});
}

# -------------------------------------------------------------------------

sub find_implicit_title_in_text {
  my ($self, $txt) = @_;

  my $fmt = $self->get_format();

  # POD documentation: the NAME section
  if ($fmt eq 'text/pod') {
    if ($$txt =~ /^\s*=head1\s+[-A-Z0-9_ ]+\n\s+(\S[^\n]*?)\n/s)
      { $self->add_inferred_metadata ("title", $1, 'text/html'); }
  }

  # HTML/XML: the first title tag or heading
  elsif ($fmt eq 'text/html') {
    if ($$txt =~ /<title>(.*?)<\/title>/si)
      { $self->add_inferred_metadata ("title", $1, 'text/html'); }
    # or title tag
    elsif ($$txt =~ /<h\d>(.*?)<\/h\d>/si)
      { $self->add_inferred_metadata ("title", $1, 'text/html'); }
  }

  # EtText: EtText headings
  elsif ($fmt eq 'text/et') {
    if ($$txt =~ /(?:^\n+|\n\n)([^\n]+)[ \t]*\n[-=\~]{3,}\n/s)
      { $self->add_inferred_metadata ("title", $1, 'text/html'); }

    elsif ($$txt =~ /(?:^\n+|\n\n)([0-9A-Z][^a-z]+)[ \t]*\n\n/s)
      { $self->add_inferred_metadata ("title", $1, 'text/html'); }
  }

  # otherwise the first line of non-white chars
  elsif ($$txt =~ /^\s*(\S[^\n]*?)\s*\n/s)
    { $self->add_inferred_metadata ("title", $1, $fmt); }

  undef;
}

# -------------------------------------------------------------------------

sub add_inferred_metadata {
  my ($self, $name, $val, $fmt) = @_;

  my $existingmeta = $self->{main}->{metadatas}->{$self->{name}.".".$name};
  return if (defined $existingmeta);

  my $attrs = { };

  if ($fmt ne 'text/html') {
    $attrs->{format} = $fmt;
  }

  # If the "title" has a reference to $[this.title], it's not a
  # suitable inference; it uses the genuine title from another
  # content object.
  return if ($val =~ /\$\[this.title\]/i);

  $val =~ s/<[^>]+>//g;		# trim wayward HTML tags
  $val =~ s/^\s+//;
  $val =~ s/\s+$//;

  dbg ("inferring $name metadata from text: \"$val\"");
  $self->{main}->add_metadata ($self->{name}, $name, $val, $attrs,
    		$self->{set_thisdot_metadata_items});

  $self->create_extra_metas_if_needed();
  $self->{extra_metas}->{$name} = $val;
}

# -------------------------------------------------------------------------

sub add_extra_metas {
  my ($self, $from) = @_;
  # also add our own extra metadata from nav links, <defaultmeta> tags
  # etc.
  my ($metaname, $val);
  while (($metaname, $val) = each %{$self->{extra_metas}}) {
    $self->{main}->add_metadata ($from, $metaname, $val, { },
    		$self->{set_thisdot_metadata_items});
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
  if (defined $self->{datasource}) {
    return $self->{datasource}->get_location_mod_time ($self->get_filename());
  } else {
    return $self->{main}->cached_get_modtime ($self->get_filename());
  }
}

# -------------------------------------------------------------------------

sub get_text_as {
  my ($self, $format) = @_;
  my $main = $self->{main};

  if (!defined $format) {
    carp ($self->as_string().": get_text_as with undef arg");
    return "";
  }

  my $fmt = $self->get_format();
  if (!defined $fmt) {
    carp ($self->as_string().": no format defined");
    return "";
  }

  # ensure if we parse any metadata, it's loaded as "this.foo"
  # as well as "name.foo"
  $self->{set_thisdot_metadata_items} = 1;

  $self->load_text_if_needed();

  # we cache format changes, unless (a) the content object is
  # strictly dynamic, such as navlinks or breadcrumbs or a sitemap;
  # (b) the formats are the same (obviously!), or (c) the length
  # of the text to reformat is smaller than a predefined minimum
  # cacheable length (currently $MIN_FMT_CACHE_LEN).
  #
  my $ignore_reformat_cache = 0;
  my $txt;

  if ($self->{is_navlinks}) {
    $txt = $self->get_navlinks_text();
    $ignore_reformat_cache = 1;

  } elsif ($self->{is_breadcrumbs}) {
    $txt = $self->get_breadcrumbs_text();
    $ignore_reformat_cache = 1;

  } elsif ($self->{keep_as_is}) {
    $txt = $self->get_as_is_text();

  } else {
    $txt = $self->get_normal_content_text();
  }

  if (!defined $txt) { die "oops! undefined text for $self->{name}"; }

  if (defined $self->{preproc}) {
    $txt = $main->_p_interpret ('perl', $self->{preproc}, $txt);
    if (!defined $txt) {
      warn "preproc for \${$self->{name}} failed\n";
      $txt = '';
    }
  }

  if (!$ignore_reformat_cache) {
    if ($self->{is_sitemap}) { $ignore_reformat_cache = 1; }
    if ($main->{force_output}) { $ignore_reformat_cache = 1; }
    elsif (length ($txt) < $MIN_FMT_CACHE_LEN) { $ignore_reformat_cache = 1; }
  }

  # preformat user tags
  $main->getusertags()->subst_preformat_tags ($self->{name}, \$txt);

  # reformat before substs; this way we can cache the reformat
  # results for next time.
  if ($fmt ne $format) {
    # strip metadata before conversion
    $main->strip_metadata ($self->{name}, \$txt);

    $txt = $main->{format_conv}->convert
	  ($self, $fmt, $format, $txt, $ignore_reformat_cache);
  }

  # subst refs and perl code
  $main->subst ($self->{name}, \$txt, 1);

  # always remove leading & trailing whitespace from HTML or XML
  # content.
  if ($format eq 'text/html' || $format eq 'text/xml') {
    $txt =~ s/^\s+//s;$txt =~ s/\s+$//s;
  }

  $txt;
}

# -------------------------------------------------------------------------

sub get_navlinks_text {
  my ($self) = @_;

  $self->set_navlinks_vars ();
  return $self->{text};
}

# -------------------------------------------------------------------------

sub get_as_is_text {
  my ($self) = @_;

  if (!$self->{no_map}) {
    $self->add_navigation_metadata();
    $self->add_extra_metas ($self->{name});
    $self->infer_implicit_metas();

    # if this content item is mapped, set a var called "__MainContentName"
    # so it'll be used as the "main" content item for the current page
    # while drawing the breadcrumb trail.
    $self->{main}->set_transient_content ("__MainContentName", $self->{name});
  }

  $self->touch_last_used();
  return $self->{text};
}

# -------------------------------------------------------------------------

sub get_normal_content_text {
  my ($self) = @_;

  if (!$self->{no_map}) {
    $self->add_navigation_metadata();

    my $name = $self->{name};
    dbg ("parsing metadata in \"$name\"");
    $self->parse_metadata_tags ($name, $self->{text});

    $self->add_extra_metas ($name);
    $self->infer_implicit_metas();

    # if this content item is mapped, set a var called "__MainContentName"
    # so it'll be used as the "main" content item for the current page
    # while drawing the breadcrumb trail.
    $self->{main}->set_transient_content ("__MainContentName", $name);
  }

  $self->touch_last_used();
  return $self->{text};
}

# -------------------------------------------------------------------------

sub load_text_if_needed {
  my ($self) = @_;

  if (defined $self->{text}) { return; }
  if (!defined $self->{location}) { return; }
  if (!defined $self->{datasource}) { return; }

  # deferred loading of content text.
  $self->touch_last_used();
  $self->{text} = $self->{datasource}->get_location ($self->get_filename());
}

sub unload_text {
  my ($self) = @_;

  if (defined $self->{datasource}) {
    dbg ($self->as_string().": unloading cached text, ".
    		"last used: ".$self->{last_used});
    delete $self->{text};
  }
}

sub is_from_datasource {
  my ($self) = @_;
  if (!defined $self->{datasource}) { return 0; }
  1;
}

sub touch_last_used {
  my ($self) = @_;

  if (defined $self->{datasource}) {
    $self->{last_used} = $self->{main}->{current_tick};
    dbg2 ("updating last used on ".$self->as_string().": ".$self->{last_used});
  }
}

# -------------------------------------------------------------------------

sub add_ref_from_url {
  my ($self, $filename) = @_;

  return if ($filename =~ /^\(/);       # (eval), (dep_ignore) etc.

  if (!$self->{no_map} && !defined $self->{reffed_in_url}) {
    dbg2 ($self->as_string().": add ref from url $filename");
    $self->{reffed_in_url} = $filename;
    $self->{main}->getcache()->put_metadata ($self->{name}.".url", $filename);
  }
}

sub get_url {
  my ($self) = @_;

  if ($self->{no_map}) {
    warn "cannot get URLs for unmapped content \${$self->{name}}\n";
    return '';
  }

  my $url = $self->{reffed_in_url};
  if (defined $url) { return $url; }
  
  $url = $self->{main}->getcache()->get_metadata ($self->{name}.".url");
  
  if (defined $url) {
    $self->{reffed_in_url} = $url;
    return $url;
  }
  
defer:
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

sub set_navlinks_vars {
  my ($self) = @_;

  foreach my $dir (qw{up prev next}) {
    my $contname = $self->{main}->curly_meta_subst
				  ($HTML::WebMake::Main::SUBST_EVAL, "this.nav_".$dir."?");
    my ($obj, $url);

    if ($contname ne '') {
      $obj = $self->{main}->get_content_obj ($contname);

      # if we haven't got the URL for that content object in our
      # cache, and it hasn't been evaluated, use a symbolic one
      # which the make() mechanism will fix later.
      if (!defined $obj || !defined ($url = $obj->get_url()) || $url eq '')
      {
	$url = $self->{main}->make_deferred_url ($contname);
      }

      # relativise it.
      $url = '$(TOP/)'.$url;

      if (!defined $self->{'nav_'.$dir}) {
	warn $self->as_string().": no name defined for '".$dir."'\n";
	next;
      }

      $self->{main}->set_transient_content ("url", $url);
      $self->{main}->set_transient_content ("name", $contname);
      $self->{main}->set_transient_content ($dir."text",
	      $self->navlinks_subst ($self->{'nav_'.$dir}));

    } elsif (defined $self->{'no_nav_'.$dir}) {		# optional attribute
      $self->{main}->set_transient_content ($dir."text",
	      $self->navlinks_subst ($self->{'no_nav_'.$dir}));

    } else {
      $self->{main}->set_transient_content ($dir."text", '');
    }
  }

  $self->{main}->del_content ("name");
  $self->{main}->del_content ("url");
}

sub navlinks_subst {
  my ($self, $var) = @_;
  $self->{main}->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, $var);
}

# -------------------------------------------------------------------------

sub get_breadcrumbs_text {
  my ($self) = @_;

  my $root = $self->{main}->getmapper()->get_root();
  if (!defined $root) {
    warn ($self->as_string().": need a root content for <breadcrumbs>!\n");
    return "";
  }

  # to illustrate this, let's consider this chain of contents:
  # TOPPAGE -> CONTENTS -> STORY -> TAILPAGE.
  # $self is TAILPAGE at this point.

  my @uplist = ();
  my $contname = $self->{main}->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, "__MainContentName");
  if (!defined $contname) {
    dbg ($self->as_string().": no mapped content on page");
    return "";
  }
  my $obj = $self->{main}->{contents}->{$contname};
  if (!defined $obj) {
    dbg ($self->as_string().": cannot find mapped content \${$contname}");
    return "";
  }

  while (1) {
    push (@uplist, $obj); last if ($obj == $root);
    my $upobj = $obj->get_up_content();
    last unless defined $upobj;
    last if ($upobj == $obj);
    $obj = $upobj;
  }
  # @uplist = (TAILPAGE, STORY, CONTENTS, TOPPAGE)

  @uplist = reverse @uplist;
  # @uplist = (TOPPAGE, STORY, CONTENTS, TAILPAGE)

  my $top = shift @uplist;
  # @uplist = (STORY, CONTENTS, TAILPAGE)

  my $tail = pop @uplist;
  # @uplist = (STORY, CONTENTS)

  my $text = '';
  if (defined $top && defined $self->{breadcrumb_top_name}) {
    $text .= $self->cook_a_breadcrumb ($top, $self->{breadcrumb_top_name});
  }
  foreach $obj (@uplist) {
    $text .= $self->cook_a_breadcrumb ($obj, $self->{breadcrumb_level_name});
  }
  if (defined $tail && defined $self->{breadcrumb_tail_name}) {
    $text .= $self->cook_a_breadcrumb ($tail, $self->{breadcrumb_tail_name});
  }

  $self->{main}->del_content ("name");
  $self->{main}->del_content ("url");
  $text;
}

sub cook_a_breadcrumb {
  my ($self, $obj, $linktmpl) = @_;

  # if we haven't got the URL for that content object in our
  # cache, and it hasn't been evaluated, use a symbolic one
  # which the make() mechanism will fix later.
  my $url;
  my $dotdots = $self->{main}->{current_subst}->{dotdots};
  if (!defined $dotdots
  	|| !defined ($url = $obj->get_url())
	|| $url eq '')
  {
    $url = $self->{main}->make_deferred_url ($obj->{name});
  } else {
    $url = $dotdots.$url;
  }

  $self->{main}->set_transient_content ("url", $url);
  $self->{main}->set_transient_content ("name", $obj->{name});
  return $self->{main}->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, $linktmpl);
}

# -------------------------------------------------------------------------

sub is_only_usable_from_deferred_refs {
  my ($self) = @_;

  if ($self->{is_breadcrumbs} || $self->{is_navlinks}) {
    1;
  } else {
    0;
  }
}

# -------------------------------------------------------------------------

1;
