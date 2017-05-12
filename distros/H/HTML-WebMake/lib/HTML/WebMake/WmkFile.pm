#

package HTML::WebMake::WmkFile;


use HTML::WebMake::File;
use HTML::WebMake::MetaTable;
use Carp;
use strict;

use vars	qw{
  	@ISA
	$CGI_EDIT_AS_WMKFILE
	$CGI_EDIT_AS_DIR
	$CGI_EDIT_AS_TEXT
	$CGI_NON_EDITABLE
};

@ISA = qw(HTML::WebMake::File);

$CGI_EDIT_AS_WMKFILE		= 1;
$CGI_EDIT_AS_DIR		= 2;
$CGI_EDIT_AS_TEXT		= 3;
$CGI_NON_EDITABLE		= 4;

###########################################################################

sub new ($$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main, $filename) = @_;
  my $self = $class->SUPER::new ($main, $filename);

  $self->{cgi} = {
    'fulltext'		=> undef,
    'items'		=> [ ],
  };

  bless ($self, $class);
  $self;
}

# -------------------------------------------------------------------------

sub dbg { HTML::WebMake::Main::dbg (@_); }
sub dbg2 { HTML::WebMake::Main::dbg2 (@_); }

# -------------------------------------------------------------------------

sub parse {
  my ($self, $str) = @_;
  local ($_) = $str;

  if (!defined $self->{main}) { carp "no main defined in WmkFile::parse"; }

  if ($self->{parse_for_cgi}) {
    $self->{cgi}->{fulltext} = $_;
  }

  # We don't use a proper XML parser, because:
  # (a) content blocks etc. can contain HTML tags which will not be
  # scoped correctly;
  # (b) we use <{perl }> blocks which are invalid XML;
  # (c) we allow attributes without "quotes".
  # So kludge it where required.  We're probably faster this way
  # anyway ;)

  # trim off text before/after <webmake> chunk
  s/^.*?<webmake\b[^>]*?>//gis;
  s/<\/\s*webmake\s*>.*$//gis;

  # handle scoped tags.  Since we don't use a proper XML parser, we have to
  # rewrite them here.  We convert them to single-character markers (\001 or
  # \002) indicating a start tag or end tag, then loop until all appearances of
  # the tag have been converted. We then convert them back to text, with a
  # scope number attached.  Until Perl can do a regexp like this:
  #
  # /<tag[^>]*>[^<tag]+<\/tag>/
  #
  # we're probably stuck doing it this way.  Hey, don't knock it, it works ;)

  s/\001/<<001>>/gs;
  s/\002/<<002>>/gs;
  $self->{scopings} = { };
  for my $tag (qw(for metadefault attrdefault)) {
    if (!/<\/$tag>/) {
      $self->{scopings}->{$tag} = 0; next;
    }

    s/<$tag(\b[^>]*[^\/]>)/\001$1/gs;
    s/<\/$tag>/\002/gs;

    my $count = 0;
    while (s{\001([^>]+)>([^\001\002]+)\002}
    		{<$tag$count$1>$2<\/$tag$count>}gis)
    {
      $count++;
    }
    $self->{scopings}->{$tag} = $count;
  }
  s/<<001>>/\001/gs;
  s/<<002>>/\002/gs;

  my $util = $self->{main}->{util};
  if (!defined $util) { carp "no util defined in WmkFile::parse"; }

  $util->set_filename ($self->{filename});

  # if we are parsing for the CGI scripts, make sure that the XML
  # parser also notes regular expressions which match each item, so that the
  # CGI code can rewrite the file easily later.
  if ($self->{parse_for_cgi}) {
    $util->{generate_tag_regexps} = 1;
  }

  my $prevpass;
  my ($lasttag, $lasteval);
  for (my $evalpass = 0; 1; $evalpass++) {
    last if (defined $prevpass && $_ eq $prevpass);
    $prevpass = $_;

    s/^\s+//gs;
    last if ($_ !~ /^</);

    1 while s/<\{!--.*?--\}>//gs;	# WebMake comments.
    1 while s/^<!--.*?-->//gs;		# XML-style comments.

    # Preprocessing.
    $util->strip_first_lone_tag (\$_, "include",
				  $self, \&tag_include, qw(file));
    $util->strip_first_lone_tag (\$_, "use",
				  $self, \&tag_use, qw(plugin));

    if (!$self->{parse_for_cgi}) {
      $self->{main}->eval_code_at_parse (\$_);
    } else {
      1 while s/^<{.*?}>//gs;		# trim code, CGI mode doesn't need it
    }

    $self->{main}->getusertags()->subst_wmk_tags
				      ($self->{filename}, \$_);
     
    {
      # if we got some eval code, store the text for error messages
      my $text = $self->{main}->{last_perl_code_text};
      if (defined $text) { $lasteval = $text; $lasttag = undef; }
    }

    # Declarations.
    $util->strip_first_tag_block (\$_, "content",
				  $self, \&tag_content, qw(name));
    $util->strip_first_lone_tag (\$_, "contents",
				  $self, \&tag_contents, qw(src name));
    $util->strip_first_tag_block (\$_, "template",
				  $self, \&tag_template, qw(name));
    $util->strip_first_lone_tag (\$_, "templates",
				  $self, \&tag_templates, qw(src name));
    $util->strip_first_tag_block (\$_, "contenttable",
				  $self, \&tag_contenttable, qw());
    $util->strip_first_lone_tag (\$_, "media",
				  $self, \&tag_media, qw(src name));

    if (/^<metadefault/i) {
      $util->strip_first_lone_tag (\$_, "metadefault",
				    $self, \&tag_metadefault, qw(name));
      my $i;
      for ($i = 0; $i < $self->{scopings}->{"metadefault"}; $i++) {
	$util->strip_first_tag_block (\$_, "metadefault".$i,
				    $self, \&tag_metadefault, qw(name));
      }
    }
    if (/^<attrdefault/i) {
      $util->strip_first_lone_tag (\$_, "attrdefault",
				    $self, \&tag_attrdefault, qw(name));
      my $i;
      for ($i = 0; $i < $self->{scopings}->{"attrdefault"}; $i++) {
	$util->strip_first_tag_block (\$_, "attrdefault".$i,
				    $self, \&tag_attrdefault, qw(name));
      }
    }

    $util->strip_first_tag (\$_, "metatable",
				  $self, \&tag_metatable, qw());
    $util->strip_first_tag (\$_, "sitemap",
				  $self, \&tag_sitemap, qw(name node leaf));
    $util->strip_first_tag (\$_, "navlinks",
				  $self, \&tag_navlinks,
				  qw(name map up prev next));
    $util->strip_first_lone_tag (\$_, "breadcrumbs",
				  $self, \&tag_breadcrumbs,
				  qw(name map level));

    # Loops
    if (/^<for/i) {
      my $i;
      for ($i = 0; $i < $self->{scopings}->{"for"}; $i++) {
	$util->strip_first_tag_block (\$_, "for".$i,
				      $self, \&tag_for, qw(name values));
      }
    }

    # Outputs.
    $util->strip_first_tag_block (\$_, "out",
				  $self, \&tag_out, qw(file));

    # Misc.
    $util->strip_first_lone_tag (\$_, "cache",
				  $self, \&tag_cache, qw(dir));
    $util->strip_first_lone_tag (\$_, "option",
				  $self, \&tag_option, qw(name value));

    # CGIs and hrefs
    $util->strip_first_lone_tag (\$_, "editcgi",
				  $self, \&tag_editcgi, qw(href));
    $util->strip_first_lone_tag (\$_, "viewcgi",
				  $self, \&tag_viewcgi, qw(href));
    $util->strip_first_lone_tag (\$_, "site",
				  $self, \&tag_site, qw(href));

    # if we got some tags, store the text for error messages
    my $text = $util->{last_tag_text};
    if (defined $text) { $lasttag = $text; $lasteval = undef; }
  }

  # if there's any text left in the file that we couldn't parse,
  # it's an error, so warn about it.
  #
  if (/\S/) {
    my $failuretext = $lasttag;

    if (defined $lasteval) {
      if ($_ !~ /^</) {
	# easy to spot; the Perl code returned '1' or something.
	# flag it clearly.

	s/\n.*$//gs;
	$self->{main}->fail ("Perl code didn't return valid WebMake code:\n".
		"\t$lasteval\n\t=> \"$_\"\n");
	return 0;
      }
      $failuretext = $lasteval;
    }

    /^(.*?>.{40,40})/s; $_ = $1; $_ =~ s/\s+/ /gs;
    $lasttag ||= '';
    $self->{main}->fail ("WMK file contains unparseable data at or after:\n".
	      "\t$lasttag\n\t$_ ...\"\n");
    return 0;
  }

  return 1;
}

# -------------------------------------------------------------------------

sub subst_attrs {
  my ($self, $tagname, $attrs) = @_;
  return if ($self->{parse_for_cgi});

  if (defined ($attrs->{name})) {
    $tagname .= " \"".$attrs->{name}."\"";	# for errors
  }

  my ($k, $v);
  while (($k, $v) = each %{$attrs}) {
    next unless (defined $k && defined $v);
    $attrs->{$k} = $self->{main}->fileless_subst ($tagname, $v);
  }
}

# -------------------------------------------------------------------------

sub tag_include {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_WMKFILE, $attrs->{file}, $attrs) and return '';
  $self->subst_attrs ("<include>", $attrs);

  my $file = $attrs->{file};

  if (!open (INC, "< $file")) {
    die "Cannot open include file: $file\n";
  }
  my @s = stat INC;
  my $inc = join ('', <INC>);
  close INC;

  dbg ("included file: \"$file\"");
  $self->{main}->set_file_modtime ($file, $s[9]);
  $self->add_dep ($file);
  $inc;
}

# -------------------------------------------------------------------------

sub tag_use {
  my ($self, $tag, $attrs, $text) = @_;

  $self->subst_attrs ("<use>", $attrs);

  my $plugin = $attrs->{plugin};
  my $file;
  my @s;

  $file = '~/.webmake/plugins/'.$plugin.'.wmk';
  $file = $self->{main}->sed_fname ($file);
  @s = stat $file;

  if (!defined $s[9]) {
    $file = '%l/'.$plugin.'.wmk';
    $file = $self->{main}->sed_fname ($file);
    @s = stat $file;
  }

  if (!defined $s[9]) {
    die "Cannot open 'use' plugin: $plugin\n";
  }

foundit:

  if (!open (INC, "<$file")) {
    die "Cannot open 'use' file: $file\n";
  }
  my $inc = join ('', <INC>);
  close INC;

  dbg ("used file: \"$file\"");
  $self->{main}->set_file_modtime ($file, $s[9]);
  $self->add_dep ($file);
  $inc;
}

# -------------------------------------------------------------------------

sub tag_cache {
  my ($self, $tag, $attrs, $text) = @_;

  $self->subst_attrs ("<cache>", $attrs);
  my $dir = $attrs->{dir};
  $self->{main}->setcachefile ($dir);
  "";
}

# -------------------------------------------------------------------------

sub tag_option {
  my ($self, $tag, $attrs, $text) = @_;

  $self->subst_attrs ("<option>", $attrs);
  $self->{main}->set_option ($attrs->{name}, $attrs->{value});
  "";
}

# -------------------------------------------------------------------------

sub tag_editcgi {
  my ($self, $tag, $attrs, $text) = @_;

  $self->subst_attrs ("<editcgi>", $attrs);
  $self->{main}->add_url ("WebMake.EditCGI", $attrs->{href});
  "";
}

# -------------------------------------------------------------------------

sub tag_viewcgi {
  my ($self, $tag, $attrs, $text) = @_;

  $self->subst_attrs ("<viewcgi>", $attrs);
  $self->{main}->add_url ("WebMake.ViewCGI", $attrs->{href});
  "";
}

# -------------------------------------------------------------------------

sub tag_site {
  my ($self, $tag, $attrs, $text) = @_;

  $self->subst_attrs ("<site>", $attrs);
  $self->{main}->add_url ("WebMake.SiteHref", $attrs->{href});
  "";
}

# -------------------------------------------------------------------------

sub tag_content {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_TEXT, $text, $attrs) and return '';
  $self->subst_attrs ("<content>", $attrs);
  my $name = $attrs->{name};
  if (!defined $name) {
    carp ("Unnamed content found in ".$self->{filename}.": $text\n");
    return;
  }

  if (defined $attrs->{root}) {
    warn "warning: \${$name}: 'root' attribute is deprecated, ".
    		"use 'isroot' instead\n";
    $attrs->{isroot} = $attrs->{root};	# backwards compat
  }

  $self->{main}->add_content ($name, $self, $attrs, $text);
  "";
}

sub tag_contents {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add_datasource ($tag, $attrs) and return '';
  $self->subst_attrs ("<contents>", $attrs);
  my $lister = new HTML::WebMake::Contents ($self->{main},
  			$attrs->{src}, $attrs->{name}, $attrs);
  $lister->add();
  "";
}

sub tag_template {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_TEXT, $text, $attrs) and return '';
  $self->subst_attrs ("<template>", $attrs);
  my $name = $attrs->{name};
  if (!defined $name) {
    carp ("Unnamed template found in ".$self->{filename}.": $text\n");
    return;
  }
  $attrs->{map} = 'false';

  $self->{main}->add_content ($name, $self, $attrs, $text);
  "";
}

sub tag_templates {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add_datasource ($tag, $attrs) and return '';
  $self->subst_attrs ("<templates>", $attrs);
  $attrs->{map} = 'false';
  my $lister = new HTML::WebMake::Contents ($self->{main},
  			$attrs->{src}, $attrs->{name}, $attrs);
  $lister->add();
  "";
}

sub tag_media {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add_datasource ($tag, $attrs) and return '';
  $self->subst_attrs ("<media>", $attrs);
  my $lister = new HTML::WebMake::Media ($self->{main},
  			$attrs->{src}, $attrs->{name}, $attrs);
  $lister->add();
  "";
}

sub tag_contenttable {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_TEXT, $text, $attrs) and return '';
  $self->subst_attrs ("<contenttable>", $attrs);

  # we actually use a Contents object, reading from the .wmk file
  # to do this.
  $attrs->{src} = 'svfile:';
  if (!defined $attrs->{name})		{ $attrs->{name} = '*'; }
  if (!defined $attrs->{namefield})	{ $attrs->{namefield} = '1'; }
  if (!defined $attrs->{valuefield})	{ $attrs->{valuefield} = '2'; }

  my $lister = new HTML::WebMake::Contents ($self->{main},
  			$attrs->{src}, $attrs->{name}, $attrs);

  $lister->{ctable_wmkfile} = $self;
  $lister->{ctable_text} = $text;

  $lister->add();
  "";
}

sub tag_metadefault {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_NON_EDITABLE, undef, $attrs) and return $text;
  $self->subst_attrs ("<metadefault>", $attrs);
  $self->{main}->{metadata}->set_metadefault ($attrs->{name}, $attrs->{value});

  return '' if (!defined $text || $text eq '');
  $text . '<metadefault name="'.$attrs->{name}.'" value="[POP]" />';
}

sub tag_attrdefault {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_NON_EDITABLE, undef, $attrs) and return $text;
  $self->subst_attrs ("<attrdefault>", $attrs);
  $self->{main}->{metadata}->set_attrdefault ($attrs->{name}, $attrs->{value});

  return '' if (!defined $text || $text eq '');
  $text . '<attrdefault name="'.$attrs->{name}.'" value="[POP]" />';
}

sub tag_metatable {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_TEXT, $text, $attrs) and return '';
  $self->subst_attrs ("<metatable>", $attrs);

  if (defined $attrs->{src}) {
    my $fname = $attrs->{src};
    if (open (IN, "<".$fname)) {
      $text = join ('', <IN>);
      close IN;

    } else {
      warn ("<metatable src=\"$attrs->{src}\"> could not be read: $@\n");
    }
  }

  my $tbl = new HTML::WebMake::MetaTable ($self->{main});
  $tbl->parse_metatable ($attrs, $text);
  "";
}

sub tag_sitemap {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_TEXT, $text, $attrs) and return '';
  $self->subst_attrs ("<sitemap>", $attrs);
  $self->{main}->add_sitemap ($attrs->{name},
  			$attrs->{rootname}, $self, $attrs, $text);
  "";
}

sub tag_navlinks {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_TEXT, $text, $attrs) and return '';
  $self->subst_attrs ("<navlinks>", $attrs);
  $self->{main}->add_navlinks ($attrs->{name}, $attrs->{map},
  			$self, $attrs, $text);
  "";
}

sub tag_breadcrumbs {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_TEXT, $text, $attrs) and return '';
  $self->subst_attrs ("<breadcrumbs>", $attrs);
  $attrs->{top} ||= $attrs->{level};
  $attrs->{tail} ||= $attrs->{level};
  $self->{main}->add_breadcrumbs ($attrs->{name}, $attrs->{map},
  			$self, $attrs, $text);
  "";
}

sub tag_out {
  my ($self, $tag, $attrs, $text) = @_;

  $self->cgi_add ($tag, $CGI_EDIT_AS_TEXT, $text, $attrs) and return '';
  $self->subst_attrs ("<out>", $attrs);
  my $file = $attrs->{file};
  my $name = $attrs->{name}; $name ||= $file;
  $self->{main}->add_out ($file, $self, $name, $attrs, $text);
  $self->{main}->add_url ($name, $file);
  "";
}

sub tag_for ($$$$) {
  my ($self, $tag, $attrs, $text) = @_;
  local ($_);

  $self->cgi_add ($tag, $CGI_NON_EDITABLE, undef, $attrs) and return $text;
  $self->subst_attrs ("<for>", $attrs);

  my $name = $attrs->{name};
  my $namesubst = $attrs->{namesubst};
  my $vals = $attrs->{'values'};

  my @vals = split (' ', $vals);
  if ($#vals >= 0)
  {
    if (!$self->{main}->{paranoid}) {
      if (defined $namesubst) {
	@vals = map { eval $namesubst; $_; } @vals;
      }
      if ($#vals < 0) {
	warn ("<for> tag \"$attrs->{name}\" namesubst failed: $@\n");
      }

    } else {
      warn "Paranoid mode on: not processing namesubst\n";
    }
  }

  my $ret = '';
  foreach my $val (@vals) {
    next if (!defined $val || $val eq '');
    $_ = $text; s/\$\{${name}\}/${val}/gs;
    $ret .= $_;
  }

  dbg2 ("for tag evaluated: \"$ret\"");
  $ret;
}

###########################################################################

sub cgi_add {
  my ($self, $tag, $editui, $edituidata, $attrs) = @_;

  return undef unless ($self->{parse_for_cgi});

  my $name = "$tag";
  if (defined $attrs->{name}) {
    $name = "$tag name=\"".$attrs->{name}."\"";
  }

  my $re = $self->{main}->{util}->{last_tag_regexp};

  my $id = $re;
  $id =~ tr/=/E/;
  $id =~ s/[\\<>\'\"]//gs;
  $id =~ s/[^-_A-Za-z0-9]+/_/gs;
  $id =~ s/^_six-m_//; $id =~ s/_$//;

  my $item = {
    'tag'		=> $tag,
    'name'		=> $name,
    'attrs'		=> $attrs,
    'id'		=> $id,
    'editui'		=> $editui,
    'edituidata'	=> $edituidata,
    'origtagregexp'	=> $re,
  };

  push (@{$self->{cgi}->{items}}, $item);
  return ' ';
}

sub cgi_add_datasource {
  my ($self, $tag, $attrs) = @_;

  return undef unless ($self->{parse_for_cgi});

  my $proto = 'file';
  my $src = $attrs->{src};
  if ($src =~ s/^([A-Za-z0-9]+)://) {
    $proto = $1; $proto =~ tr/A-Z/a-z/;
  }

  if ($proto eq 'file') {
    $self->cgi_add ($tag, $CGI_EDIT_AS_DIR, $src, $attrs);
  }

  return ' ';
}

###########################################################################

1;
