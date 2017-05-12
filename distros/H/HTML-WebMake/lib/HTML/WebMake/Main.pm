#

=head1 NAME

HTML::WebMake - a simple web site management system, allowing an entire site to
be created from a set of text and markup files and one WebMake file.

=head1 SYNOPSIS

  my $f = new HTML::WebMake::Main ();
  $f->readfile ($filename);
  $f->make();
  my $failures = $f->finish();
  exit $failures;

=head1 DESCRIPTION

WebMake is a simple web site management system, allowing an entire site to be
created from a set of text and markup files and one WebMake file.

It requires no dynamic scripting capabilities on the server; WebMake sites can
be deployed to a plain old FTP site without any problems.

It allows the separation of responsibilities between the content editors, the
HTML page designers, and the site architect; only the site architect needs to
edit the WebMake file itself, or know perl or WebMake code.

A multi-level website can be generated entirely from 1 or more WebMake files
containing content, links to content files, perl code (if needed), and output
instructions.  Since the file-to-page mapping no longer applies, and since
elements of pages can be loaded from different files, this means that standard
file access permissions can be used to restrict editing by role.

Since WebMake is written in perl, it is not limited to command-line invocation;
using the C<HTML::WebMake::Main> module directly allows WebMake to be run from
other Perl scripts, or even mod_perl (WebMake uses C<use strict> throughout,
and temporary globals are used only where strictly necessary).

=head1 METHODS

=over 4

=cut

package HTML::WebMake::Main;


use Carp;
use File::Basename;
use File::Path;
use File::Spec;
use Cwd;
use strict;
use locale;
use POSIX qw(strftime);

use HTML::WebMake;
use HTML::WebMake::Util;
use HTML::WebMake::File;
use HTML::WebMake::WmkFile;
use HTML::WebMake::Content;
use HTML::WebMake::NormalContent;
use HTML::WebMake::MetadataContent;
use HTML::WebMake::MediaContent;
use HTML::WebMake::Out;
use HTML::WebMake::SiteCache;
use HTML::WebMake::SubstCtx;
use HTML::WebMake::Metadata;
use HTML::WebMake::PerlCode;
use HTML::WebMake::FormatConvert;
use HTML::WebMake::DataSource;
use HTML::WebMake::SiteMap;
use HTML::WebMake::UserTags;
use HTML::WebMake::WMLinkGlossary;

use vars	qw{
  	@ISA $VERSION
	$VERBOSE $DEBUG $DEFAULT_CLEAN_FEATURES $HTML_LOGGING
	$SUBST_EVAL $SUBST_DEP_IGNORE $SUBST_META
};

@ISA = qw();

$VERSION = $HTML::WebMake::VERSION;
sub Version { $VERSION; }

###########################################################################

$DEFAULT_CLEAN_FEATURES = "pack addimgsizes cleanattrs indent ".
				"addxmlslashes fixcolors fixhrefs";

$SUBST_EVAL		= '(!E)';
$SUBST_DEP_IGNORE	= '(!D)';
$SUBST_META		= '(!M)';

###########################################################################

=item $f = new HTML::WebMake::Main

Constructs a new C<HTML::WebMake::Main> object.  You may pass the following
attribute-value pairs to the constructor.

=over 4

=item force_output

Force output. Normally if a file is already up to date, it is not modified.
This will force the file to be re-made.

=item force_cache_rebuild

Force the cached metadata and dependency data for the site to be rebuilt.
Normally this is used to speed up partial rebuilds of the site. This
option implies C<force_output>.

=item risky_fast_rebuild

Run more quickly, but take more risks.  Normally, dynamic content, such as Perl
sections, sitemaps, or navigation links, are always considered to be in need of
rebuilding, as mapping their dependencies is often very difficult or
impossible.  This switch forces them to be ignored for dependency-tracking
purposes, and so an output file that depends on them will not be rebuilt unless
a normal content item on that page changes.

=item base_href

Rewrite links to be absolute URLs based at this URL.  By default, links are
specified as relative wherever possible.

=item base_dir

Generate output, and look for support files (images etc.), relative to this
directory.

=item paranoid

Paranoid mode; do not allow perl code evaluation or accesses to directories
above the WebMake file.

=item debug

Debug mode; more output.

=back

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = shift;
  $self->{paranoid}		||= 0;
  $self->{debug}		||= 0;
  if (!defined $self->{verbose}) { $self->{verbose} = 1; }
  $self->{base_href}		||= "";
  $self->{base_dir}		||= "";
  $self->{risky_fast_rebuild}	||= 0;
  $self->{force_output}		||= 0;
  $self->{force_cache_rebuild}	||= 0;

  if ($self->{force_cache_rebuild}) { $self->{force_output} = 1; }

  $self->{files}	= { };
  $self->{file_modtimes} = { };

  $self->{source_files} = [ ];

  $self->{outs}		= { };
  $self->{out_order}	= [ ];

  $self->{contents}	= { };
  $self->{content_order} = [ ];

  $self->{metadatas}	= { };
  $self->{this_metas_added} = [ ];

  $self->{locations}	= { };
  $self->{location_order} = [ ];

  # increase the size of these hashes in anticipation of big filesets
  keys %{$self->{outs}} = 300;
  keys %{$self->{locations}} = 300;
  keys %{$self->{metadatas}} = 500;
  keys %{$self->{contents}} = 500;

  $self->{imgsizes}	= { };
  $self->{options}	= { };

  $self->{failures}	= 0;

  $self->{cache}	= undef;
  $self->{cachefname}	= undef;
  $self->{tmpdir}	= undef;

  $self->{et_glossary}	= undef;

  $self->{perl_interp}	= undef;
  $self->{htmlcleaner}	= undef;
  $self->{mapper}	= undef;
  $self->{usertags}	= undef;
  $self->{util}		= new HTML::WebMake::Util();
  $self->{have_image_size_module} = undef;

  $self->{subst_stack} = [ ];
  $self->{current_subst} = undef;
  $self->{dep_datasources} = { };
  $self->{current_webmake_fname} = undef;

  bless ($self, $class);

  $DEBUG = $self->{debug};
  $VERBOSE = $self->{verbose};
  $HTML_LOGGING = $self->{html_logging};

  $self->{perl_lib_dir} = $self->find_perl_lib_dir();
  $self->init_for_making();

  $self;
}

sub init_for_making {
  my ($self) = @_;

  if ($^O !~ /(win|os2|mac)/i) {
    # which genius decided the mere sniff of getpwuid() should cause
    # a crash on win32? Cheers mate.
    eval ' $self->{current_user} = getpwuid ($>); ';
  } else {
    $self->{current_user} = "unknown";
  }

  $self->{format_conv} = new HTML::WebMake::FormatConvert ($self);
  $self->{metadata} = new HTML::WebMake::Metadata ($self);

  $self->{ignore_for_dependencies} =
  			new HTML::WebMake::File ($self, $SUBST_DEP_IGNORE);
  $self->{meta_ignore_for_dependencies} =
  			new HTML::WebMake::File ($self, $SUBST_META);

  # define some builtin magic content items now.
  $self->set_unmapped_content ("WebMake.GeneratorString",
  					"WebMake/$VERSION");
  $self->set_unmapped_content ("WebMake.Version", $VERSION);
  $self->set_unmapped_content ("WebMake.Who", $self->{current_user});
  # others in get_deferred_builtin_content() method below.
  # these are a little more computationally intensive.

  $self->{now} = time();
  $self->{current_tick} = 0;
}

# -------------------------------------------------------------------------

sub sed_fname {
  my ($self, $fname) = @_;

  # Interpolated variables:
  #    ~  = $HOME
  #    %f = .wmk file name, non-alphanums replaced with _
  #    %F = .wmk full path, non-alphanums replaced with _
  #    %l = perl lib dir for plugins
  #    %u = username
  #
  my $home = $ENV{'HOME'};
  $home ||= '/';

  $fname =~ s/\~/${home}/g;
  $fname =~ s/%u/$self->{current_user}/g;

  $fname =~ s{%f}{
    my $val = basename ($self->{current_webmake_fname});
    $val =~ s/\.wmk$//i; $val =~ s,[^A-Za-z0-9],_,g;
    $val;
  }ge;

  $fname =~ s{%F}{
    my $val = $self->{current_webmake_fname};
    if (!File::Spec->file_name_is_absolute ($val)) {
      $val = File::Spec->catfile (getcwd, $val);
    }
    $val =~ s/\.wmk$//i; $val =~ s,[^A-Za-z0-9],_,g; $val =~ s/^_+//;
    $val;
  }ge;

  $fname =~ s{%l}{$self->{perl_lib_dir}}g;

  if ($^O eq 'MacOS') {
    $fname =~ s/\//:/g;
  }

  $fname;
}

# -------------------------------------------------------------------------

sub opencache {
  my ($self) = @_;

  my $fname = $self->{cachefname};
  # default: a file called {webmakefname}/cache.db in a
  # .webmake subdirectory of the user's home. Each user needs
  # their own cache file for privacy and security reasons, BTW.
  $fname ||= "~/.webmake/%F/cache.db";
  $fname = $self->sed_fname ($fname);

  dbg ("using site cache: $fname");
  my $dir = dirname ($fname);
  (-d $dir) or mkpath ($dir);

  if ($self->{force_cache_rebuild}) {
    # if -F, always recreate the cache
    unlink ($fname);
  }

  $self->{cache} = new HTML::WebMake::SiteCache ($self, $fname);
  $self->{cache}->tie();
}

# -------------------------------------------------------------------------

sub tmpdir {
  my ($self) = @_;

  if (defined $self->{seddedtmpdir}) {
    return $self->{seddedtmpdir};
  }

  my $fname = $self->{tmpdir};
  $fname ||= "~/.webmake";
  $fname = $self->sed_fname ($fname);
  dbg ("using temp dir: $fname");
  (-d $fname) or mkpath ($fname);
  $self->{seddedtmpdir} = $fname;
}

# -------------------------------------------------------------------------

sub cachedir {
  my ($self) = @_;

  if (defined $self->{seddedcachedir}) {
    return $self->{seddedcachedir};
  }

  my $fname = $self->{cachedir};
  $fname ||= "~/.webmake/%F";
  $fname = $self->sed_fname ($fname);
  dbg ("using cache dir: $fname");
  (-d $fname) or mkpath ($fname);
  $self->{seddedcachedir} = $fname;
}

# -------------------------------------------------------------------------

sub getcache {
  my ($self) = @_;
  if (defined $self->{cache}) {
    return $self->{cache};
  }

  $self->opencache();
  return $self->{cache};
}

# -------------------------------------------------------------------------

sub getglossary {
  my ($self) = @_;
  if (defined $self->{et_glossary}) {
    return $self->{et_glossary};
  }

  $self->{et_glossary} =
  	new HTML::WebMake::WMLinkGlossary ($self, $self->getcache());
  return $self->{et_glossary};
}

# -------------------------------------------------------------------------

sub setcachefile {
  my ($self, $fname) = @_;
  $self->{cachedir} = $fname;
  $self->{cachefname} = $fname."/cache.db";
}

# -------------------------------------------------------------------------

=item $f->set_option ($optname, $optval);

Set a WebMake option.  Currently supported options are:

=over 4

=back

=cut

sub set_option {
  my ($self, $optname, $optval) = @_;
  $self->{options}->{$optname} = $optval;
}

# -------------------------------------------------------------------------

=item $f->readfile ($filename)

Read and parse the given WebMake file.

=cut

sub readfile {
  my ($self, $fname, $opts) = @_;
  local ($_);

  $self->{current_webmake_fname} = $fname;

  open (IN, "<$fname") or croak "cannot open WebMake file $fname";
  $_ = join ('', <IN>);
  my @s = stat IN;
  $self->set_file_modtime ($fname, $s[9]);
  close IN;

  my $wmkf = new HTML::WebMake::WmkFile ($self, $fname);

  if (defined $opts && $opts->{parse_for_cgi}) {
    $wmkf->{parse_for_cgi} = 1;
  }

  $wmkf->parse ($_);
  $self->{files}->{$fname} = $wmkf;

  $self->add_source_files ($fname);
  1;
}

# -------------------------------------------------------------------------

=item $f->readstring ($string)

Read and parse the given WebMake configuration (as a string).

=cut

sub readstring {
  my ($self, $str, $opts) = @_;
  local ($_);

  my $fname = '(readstring)';
  $self->{current_webmake_fname} = $fname;
  $self->set_file_modtime ($fname, $self->{now});

  my $wmkf = new HTML::WebMake::WmkFile ($self, $fname);
  $wmkf->parse ($str);
  $self->{files}->{$fname} = $wmkf;
  1;
}

# -------------------------------------------------------------------------

# Internal API, used by HTML::WebMake::CGI modules.  This parses the
# .wmk file (quickly) and generates a list of the editable items therein.
#
sub cgi_parse_file {
  my ($self, $fname, $opts) = @_;

  if ($self->readfile ($fname, { 'parse_for_cgi' => 1 })) {
    return $self->{files}->{$fname}->{cgi};
  } else {
    return undef;
  }
}

# -------------------------------------------------------------------------

sub getmapper {
  my ($self) = @_;
  if (defined $self->{mapper}) {
    return $self->{mapper};
  }

  $self->{mapper} = new HTML::WebMake::SiteMap ($self);
  return $self->{mapper};
}

# -------------------------------------------------------------------------

sub getusertags {
  my ($self) = @_;
  if (defined $self->{usertags}) {
    return $self->{usertags};
  }

  $self->{usertags} = new HTML::WebMake::UserTags ($self);
  return $self->{usertags};
}

# -------------------------------------------------------------------------

sub add_out {
  my ($self, $file, $wmkf, $name, $attrs, $text) = @_;

  # here's the trick: create a content item for the text, then the out
  # itself is just a reference to that. This makes sitemapping much easier.
  my $contname = "OUT:".$name;
  my $contattrs = {
    'name'		=> $contname,
    'map'		=> 'false'
  };
  if (defined $attrs->{'format'}) {
    $contattrs->{'format'} = $attrs->{'format'};
  }
  $self->add_content ($contname, $wmkf, $contattrs, $text);

  push (@{$self->{out_order}}, $file);
  $self->{outs}->{$file} = new HTML::WebMake::Out ($wmkf, $name, $attrs);
}

# -------------------------------------------------------------------------

sub set_metadata_content_item ($$$$$) {
  my ($self, $name, $file, $attrs, $text) = @_;

  if (!defined $self->{metadatas}->{$name}) {
    push (@{$self->{content_order}}, $name);
  }
  my $cont = new HTML::WebMake::MetadataContent ($name,
  			$file, $attrs, $text);
  $cont->set_declared (scalar @{$self->{content_order}});
  $self->{metadatas}->{$name} = $cont;
  $cont;
}

# -------------------------------------------------------------------------

sub add_new_content_to_map {
  my ($self, $name, $cont) = @_;

  if (!defined $self->{contents}->{$name}) {
    push (@{$self->{content_order}}, $name);
  }
  $cont->set_declared (scalar @{$self->{content_order}});
  $self->{contents}->{$name} = $cont;
}

sub add_content ($$$$$) {
  my ($self, $name, $file, $attrs, $text) = @_;
  dbg2 ("adding content \"$name\"");

  return new HTML::WebMake::NormalContent ($name,
  			$file, $attrs, $text, undef);
}

sub add_content_defer_opening ($$$$$) {
  my ($self, $name, $file, $attrs, $datasource) = @_;
  dbg ("adding content \"$name\" (deferred opening)");

  return new HTML::WebMake::NormalContent ($name,
  			$file, $attrs, undef, $datasource);
}

# -------------------------------------------------------------------------

sub set_unmapped_content ($$$) {
  my ($self, $key, $val) = @_;
  dbg2 ("set \"$key\" (unmapped)");

  return new HTML::WebMake::NormalContent ($key,
  	$self->{ignore_for_dependencies},
	  {
	    'format'		=> 'text/html',
	    'map'		=> 'false',
	    'up'		=> $HTML::WebMake::SiteMap::ROOTNAME,
	  },
	$val, undef);
}

# -------------------------------------------------------------------------

sub set_transient_content ($$$) {
  my ($self, $key, $val) = @_;
  dbg2 ("set \"$key\" (transient)");

  return new HTML::WebMake::NormalContent ($key,
  	$self->{ignore_for_dependencies},
	  {
	    'format'		=> 'text/html',
	    'map'		=> 'false',
	    'up'		=> $HTML::WebMake::SiteMap::ROOTNAME,
	  },
	$val, undef);
}

# -------------------------------------------------------------------------

sub set_mapped_content ($$$$) {
  my ($self, $key, $val, $upname) = @_;
  dbg2 ("set \"$key\" (up = \"$upname\")");

  return new HTML::WebMake::NormalContent ($key,
  	$self->{ignore_for_dependencies},
	  {
	    'format'		=> 'text/html',
	    'map'		=> 'true',
	    'up'		=> $upname,
	  },
	$val, undef);
}

# -------------------------------------------------------------------------

# convert some metadata into a content item, ie. set it in
# the contents hash. Return the value of the meta (subst'ed).
#
sub metadata_to_content {
  my ($self, $from, $key, $val, $basecont) = @_;

  if (!defined $basecont) { croak "No base content defined"; }
  my $base = $basecont->{name};
  my $wmkf = new HTML::WebMake::File ($self, $basecont->get_filename());

  dbg2 ("created metadata content \$\[$key\]: base content=\"$base\"");
  my $attrs = {
    'map'		=> 'false',
    'up'		=> $base,
  };
  $self->set_metadata_content_item ($key, $wmkf, $attrs, $val);
  return $self->_curly_subst ($from, $key, 0);
}

sub add_metadata {
  my ($self, $from, $key, $val, $attrs, $setthisdotmetas) = @_;

  my $thiskey = "this.".$key;
  my $fullkey = $from.".".$key;

  if ($setthisdotmetas) {
    dbg2 ("set metadata $key == \"$thiskey\", \"$fullkey\"");
  } else {
    dbg2 ("set metadata $key == \"$fullkey\"");
  }

  my $cont = $self->{contents}->{$from};
  my $wmkf;
  if (!defined $cont) {
    # the metadata was set from an <out> block.
    $wmkf = $self->{meta_ignore_for_dependencies};
  } else {
    $wmkf = new HTML::WebMake::File ($self,
  				$cont->get_filename());
  }

  $attrs->{up} = $from;

  if ($setthisdotmetas) {
    $self->set_metadata_content_item ($thiskey, $wmkf, $attrs, $val);
    push (@{$self->{this_metas_added}}, $thiskey);
  }

  $self->set_metadata_content_item ($fullkey, $wmkf, $attrs, $val);
  $self->getcache()->put_metadata ($fullkey, $val);
}

# -------------------------------------------------------------------------

sub del_content {
  my ($self, $name) = @_;
  dbg2 ("deleting content \"$name\"");
  delete $self->{contents}->{$name};
  delete $self->{metadatas}->{$name};
}

sub get_content_obj {
  my ($self, $name) = @_;

  my $obj = $self->{contents}->{$name};
  if (!defined $obj) { $obj = $self->{metadatas}->{$name}; }
  $obj;
}

sub get_all_content_names {
  my ($self) = @_;

  # garbage-collect the list in case del_content() has been called.
  # now seems as good a time as any to do this...
  my @list = ();
  my %already_seen = ();

  foreach my $name (@{$self->{content_order}}) {
    next unless (defined $self->{contents}->{$name} ||
		defined $self->{metadatas}->{$name});

    next if defined $already_seen{$name};
    $already_seen{$name} = 1;

    push (@list, $name);
  }

  @{$self->{content_order}} = @list;
  @list;
}

# -------------------------------------------------------------------------
# garbage-collect the contents list periodically, unloading the content
# text for items that have not been used recently.

sub gc_contents {
  my ($self) = @_;

  my @conts = grep {
    $_->is_from_datasource() && defined ($_->{last_used})
  } values %{$self->{contents}};

  # halve the amount of dynamically-loadable content text loaded
  my $shrinkby = $#conts / 2;
  my $i = 0;
  foreach my $cobj (sort { $a->{last_used} <=> $b->{last_used} } @conts)
  {
    last if ($i++ > $shrinkby);
    $cobj->unload_text();
  }
}

# -------------------------------------------------------------------------

sub add_url {
  my ($self, $name, $location) = @_;
  dbg2 ("adding URL \"$name\" = $location");
  if (!defined $self->{locations}->{$name}) {
    push (@{$self->{location_order}}, $name);
  }
  $self->{locations}->{$name} = $location;
}

sub del_url {
  my ($self, $name) = @_;
  dbg2 ("deleting URL \"$name\"");
  delete $self->{locations}->{$name};
}

sub get_all_url_names {
  my ($self) = @_;

  # garbage-collect the list in case del_url() has been called
  my @list = ();
  foreach my $name (@{$self->{location_order}}) {
    next unless defined $self->{locations}->{$name};
    push (@list, $name);
  }
  @{$self->{location_order}} = @list;
  @list;
}

# -------------------------------------------------------------------------

sub add_sitemap {
  my ($self, $name, $root, $file, $attrs, $text) = @_;

  my $fn;
  if (defined $attrs->{all} && $self->{util}->parse_boolean ($attrs->{all}))
  {
    $fn = 'make_contentmap';
  } else {
    $fn = 'make_sitemap';
  }

  if (defined $root) { $root = 'q{'.$root.'}'; }
  else { $root = 'undef'; }

  # use a perl code call to generate the sitemap. cool eh?
  $text .= '<{perl $self->'.$fn.' ('.$root.', q{'.$name.'}); }>';

  $attrs->{is_sitemap} = 1;
  $self->add_content ($name, $file, $attrs, $text);
}

# -------------------------------------------------------------------------

sub add_navlinks {
  my ($self, $name, $map, $file, $attrs, $text) = @_;

  # evaluate the map so the next, prev etc. links will work
  # from now on.  Tell the sitemapper to generate the link
  # metadata on this run.
  $self->getmapper()->{set_navlinks} = 1;
  $self->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, $map);
  $self->getmapper()->{set_navlinks} = 0;


  $attrs->{nav_up} = $attrs->{up};
  $attrs->{nav_next} = $attrs->{next};
  $attrs->{nav_prev} = $attrs->{prev};
  $attrs->{nav_no_up} = $attrs->{noup};
  $attrs->{nav_no_next} = $attrs->{nonext};
  $attrs->{nav_no_prev} = $attrs->{noprev};

  $attrs->{is_navlinks} = 1;
  delete ($attrs->{up});

  $self->add_content ($name, $file, $attrs, $text);
}

# -------------------------------------------------------------------------

sub add_breadcrumbs {
  my ($self, $name, $map, $file, $attrs, $text) = @_;

  # load the map so the "up" links will be present
  $self->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, $map);

  $attrs->{is_breadcrumbs} = 1;
  $attrs->{breadcrumb_level_name} = $attrs->{level};

  $attrs->{breadcrumb_top_name} = $attrs->{top};
  $attrs->{breadcrumb_top_name} ||= $attrs->{level};

  $attrs->{breadcrumb_tail_name} = $attrs->{tail};
  $attrs->{breadcrumb_tail_name} ||= $attrs->{level};

  delete $attrs->{level};		# now effectively renamed
  delete $attrs->{top};
  delete $attrs->{tail};

  $self->add_content ($name, $file, $attrs, "");
}

# -------------------------------------------------------------------------

sub subst {
  my ($self, $from, $str, $evaluatingtags) = @_;

  my $current_subst = $self->{current_subst};
  if (!defined $str) { return undef; }
  if (!defined $from) { croak "No from defined in subst"; }
  if (!defined $current_subst) {
    croak "cannot subst outside _subst_open and _subst_close";
  }

  if ($current_subst->{level} > 30) {
    $self->infinite_subst_loop_error ($from, $$str);
    return "";
  }

  {
    $current_subst->{level}++;
    $self->eval_code_at_ref ($from, $str);

    if ($evaluatingtags) {
      $self->getusertags()->subst_tags ($from, $str);
    }

    # profiling optimisation, quicker to check for one char than do
    # all the matches and subs below
    goto done_substs if ($$str !~ /\$[\{\(\[]/s);

    if ($$str =~ /\$\{IMGSIZE\}/is) {
      # magic tag: <img src=foo.gif ${IMGSIZE}>
      $$str =~ s/<img\s+([^>]*?)\s*\$\{IMGSIZE\}\s*([^>]*?)\s*>/
		  $self->add_image_size ($from, $1, $2);
	  /gies;
    }

    # references to content chunks: ${content}
    $$str =~ s/\$\{([^\<\{\}]+)\}/ $self->_curly_subst ($from, $1, 1) /ges;
    #}

    # references to out URLs: $(foo)
    $$str =~ s/\$\(([^\<\(\)]+)\)/ $self->_round_subst ($from, $1); /ges;

    # references to metadata: $[this.foo] used within the chunk they're
    # defined in.
    $$str =~ s/\$\[this(\.[^\[\]]+)\]/ $self->_this_subst ($from, $1); /gies;

done_substs:

    $current_subst->{level}--;
  }

  if ($current_subst->{inf_loop}) { $$str = ""; }
}

sub subst_deferred_refs {
  my ($self, $from, $str) = @_;

  if (!defined $from) { croak "No from defined in subst"; }
  my $tries = 0;

  if ($$str !~ /(?:\$|\<\{)/) { return; }	#}

  do {
    if ($tries++ > 20) {
      $self->infinite_subst_loop_error ($from, $$str); return;
    }

    # deferred refs to content chunks: $[content]
    $$str =~ s/\$\[([^\[\]]+)\]/ $self->_curly_subst ($from, $1, 0); /ges;

    # do a subst in case the deferred ref contained normal refs
    $self->subst ($from, $str);

  } while ($$str =~ /\$\{.*?\}/ ||
	  $$str =~ /\$\[.*?\]/ ||
	  $$str =~ /\$\(.*?\)/ ||
	  $$str =~ /<\{.*?\>\}/);
}

# -------------------------------------------------------------------------

sub infinite_subst_loop_error {
  my ($self, $from, $str) = @_;

  $self->{current_subst}->{inf_loop} = 1;

  # try to trim it down to the troublesome bit if possible;
  # include a bit of context to make its position clear
  my $err = $str; $err =~ s/\s+/ /gs;
  if (length $err > 60) {
    $err =~ s/^.{6,}?(.{0,16}\$\{.*?\}.{0,16}).*?$/\[...\]$1\[...\]/gs;
    $err =~ s/^.{6,}?(.{0,16}\$\[.*?\].{0,16}).*?$/\[...\]$1\[...\]/gs;
    $err =~ s/^.{6,}?(.{0,16}\$\(.*?\).{0,16}).*?$/\[...\]$1\[...\]/gs;
    $err =~ s/^.{6,}?(.{0,16}\<\{.*?\>\}.{0,16}).*?$/\[...\]$1\[...\]/gs;
    # $err =~ s/^.{6,}?(.{0,16}(?:\$[\{\(\[]|\<\{).{0,16}).*?$/\[...\]$1\[...\]/gs;
  }

  my $msg;
  if ($str =~ /\$\[\]/) {
    $msg = "empty deferred reference \$[]";
  } elsif ($str =~ /\$\{\}/) {
    $msg = "empty content reference \${}";
  } elsif ($str =~ /\$\(/) {
    $msg = "failed to parse URL reference";
  } else {
    $msg = "failed to parse content reference";
  }

  $self->fail ($msg." in \"$from\"!\nOffending code: \"$err\"");
}

# -------------------------------------------------------------------------

sub fileless_subst {
  my ($self, $from, $txt) = @_;
  $self->_subst_open(undef, undef, undef, "text/html", 0);	#{
  $self->subst($from, \$txt);
  $self->strip_metadata ($from, \$txt);
  $self->_subst_close();				#}
  $txt;
}

sub curly_subst {
  my ($self, $from, $txt) = @_;
  $self->_subst_open (undef, undef, undef, "text/html", undef);	#{
  $txt = $self->_curly_subst ($from, $txt, 1);
  # then do a normal subst to handle <{set}>, metadata, etc.
  $self->subst ($from, \$txt);
  $self->strip_metadata ($from, \$txt);
  $self->_subst_close();				#}
  $txt;
}

sub curly_meta_subst {
  my ($self, $from, $txt) = @_;
  $self->_subst_open (undef, undef, undef, "text/html", undef);	#{
  $txt = $self->_curly_subst ($from, $txt, 0);
  $self->_subst_close();				#}
  $txt;
}

sub curly_or_meta_subst {
  my ($self, $from, $txt) = @_;
  $self->_subst_open (undef, undef, undef, "text/html", undef);	#{
  $txt = $self->_curly_subst ($from, $txt, 2);
  # then do a normal subst to handle <{set}>, metadata, etc.
  $self->subst ($from, \$txt);
  $self->strip_metadata ($from, \$txt);
  $self->_subst_close();				#}
  $txt;
}

sub quiet_curly_meta_subst {
  my ($self, $from, $txt) = @_;
  $self->_subst_open(undef, undef, undef, "text/html", undef);	#{
  $self->{current_subst}->{quiet} = 1;
  $txt = $self->_curly_subst($from, $txt, 0);
  $self->{current_subst}->{quiet} = 0;
  $self->_subst_close();				#}
  $txt;
}

sub round_subst {
  my ($self, $from, $txt) = @_;
  $self->_subst_open(undef, undef, undef, "text/html", undef);	#{
  $txt = $self->_round_subst($from, $txt);
  $self->_subst_close();				#}
  $txt;
}

sub _this_subst {
  my ($self, $from, $origkey) = @_;

  # trim off the default value from our working copy of the key
  my $key = $origkey;
  $key =~ s/\?([^\?]+)$//;

  # see if the current content chunk has this.$key defined
  my $thiskey = $from.$key;
  my $thiscont = $self->{metadatas}->{$thiskey};

  if (defined $thiscont) {
    my $meta = $self->_curly_subst ($from, $thiskey, 0);
    $meta;		# it does? use it now
  } else {
    "\$\[this$origkey\]";	# nope, leave it for later
  }
}

# -------------------------------------------------------------------------

sub _subst_open {
  my ($self, $filename, $outname, $dotdots, $fmt, $useurls) = @_;

  my $current_subst = $self->{current_subst};
  if (defined $current_subst) {
    push (@{$self->{subst_stack}}, $current_subst);

    # inherit the dotdots and filename from the previous subst, if
    # there is one.
    if (!defined $dotdots) {
      $dotdots = $current_subst->{dotdots};
    }
    if (!defined $filename) {
      $filename = $current_subst->{filename};
    }
    if (!defined $outname) {
      $outname = $current_subst->{outname};
    }
    if (!defined $useurls) {
      $useurls = $current_subst->{useurls};
    }
  }

  # if (!defined $dotdots) { $dotdots = ""; }
  if (!defined $filename) { $filename = $SUBST_EVAL; }
  if (!defined $outname) { $outname = $SUBST_EVAL; }
  if (!defined $useurls) { $useurls = 1; }

  $self->{current_subst} = new HTML::WebMake::SubstCtx
	    ($self, $filename, $outname, $dotdots, $fmt, $useurls);
}

sub _subst_close {
  my ($self) = @_;

  $self->{current_subst} = pop (@{$self->{subst_stack}});
}

# -------------------------------------------------------------------------

sub _curly_subst {
  my ($self, $from, $key, $contents_only) = @_;
  # if (!defined $from) { croak "No from defined in subst"; }
  # if (!defined $key) { croak "No key defined in subst"; }

  # warn "JMD CURLY $key";

  my $str;
  my $current_subst = $self->{current_subst};
  if ($current_subst->{inf_loop}) { $str = ""; goto ret; }

  # default values: ${foo?Untitled}
  my $defval = undef;
  if ($key =~ s/\?([^\?]*)$//) { $defval = $1; }

  # support ${templateName: parameter="foo"}
  if ($key =~ s/: (.*)$//) {
    my $attrs = $self->{util}->parse_xml_tag_attributes
    		("\${$key}", $1, $from, qw());

    foreach my $var (keys %{$attrs}) {
      $self->_eval_set ($from, $var, $attrs->{$var});
    }
  }

  my $cont;

  if ($contents_only) {			# expanding a ${foo} ref
    $cont = $self->{contents}->{$key};
    if (!defined $cont) {
      $cont = $self->{metadatas}->{$key};
    }

  } else {				# expanding a $[foo] ref
    $cont = $self->{metadatas}->{$key};

    # it's also possible to refer to content items using the metadata reference
    # type $[..], as in fact that reference type simply means a reference whose
    # loading is deferred until other references have been expanded.  In
    # addition, navlinks and breadcrumbs do this too.  To support this, check
    # the contents hash as well as the metadata one, if there's no hit in the
    # metadata hash.
    if (!defined $cont) {
      $cont = $self->{contents}->{$key};
    }
  }

  if (defined $cont) {
    $self->add_content_dependency ($cont);

    if ($contents_only == 1) {
      if ($cont->is_only_usable_from_deferred_refs()) {
	$self->fail ("content \$\{$key\} should only be used ".
		"as \$\[$key\] in \"$from\".");
      }
    }

    if ($current_subst->{useurls}) {
      $cont->add_ref_from_url ($current_subst->{filename});
    }

    my $fmt = $current_subst->{format};
    $str = $cont->get_text_as($fmt);
    if (!defined $str) {
      $self->fail ("unable to get text in format \"$fmt\" for ".
		"content \${$key} in \"$from\".");
      $str = ""; goto ret;
    }
    $self->subst ($key, \$str);
    goto ret;
  }

  # then, webmake magic vars
  $str = $self->get_deferred_builtin_content ($from, $key);
  if (defined $str) { goto ret; }

  # finally, metadata that hasn't been used yet as a content item
  # (quite expensive to look up)
  my $meta = $self->subst_metadata ($from, $key, $defval);
  if (defined $meta) { $str = $meta; goto ret; }

  # agh, I give up
  if (defined $defval) {
    $str = $defval;
  } else {
    vrb ("no value defined for content \${$key} in \"$from\".");
  }

ret:
  $str;
}

# -------------------------------------------------------------------------

sub _round_subst {
  my ($self, $from, $key) = @_;

  # warn "JMD ROUND $key";

  if (!defined $from) { croak "No from defined in subst"; }
  if ($self->{current_subst}->{inf_loop}) { return ""; }

  my $defval = undef;
  if ($key =~ s/\?([^\?]+)$//) { $defval = $1; }

  my $str;
  if ($key eq 'TOP/') { $str = ''; }
  
  if (!defined $str) {
    if ($key =~ /\$/) {
      # the key contains a content ref, either ${normal} or $[deferred].
      # subst for both of them.
      $self->subst ($from, \$key);
      $self->subst_deferred_refs ($from, \$key);
    }

    $str = $self->{locations}->{$key};
  }

  if ((!defined $str || $str eq '') && $key ne 'TOP/') {
    if (defined $defval) { return $defval; }
    vrb ("no value defined for output URL \$($key) in \"$from\".");
    return "";
  }

  $self->add_url_dependency ($key);

  # make it a valid relative URL
  if ($str !~ /^\// && $str !~ /^[-_a-zA-Z0-9]:/) {
    if (!defined $self->{current_subst}->{dotdots}) {
      # carp "oops? need to defer URL ref here: \"$str\"";
    } else {
      $str = $self->{current_subst}->{dotdots} . $str;
    }
  }

  if ($self->{base_href} ne '') {
    $str = $self->{base_href}.'/'.$str;
  }

  # trim out foo/bar/../../
  if ($str =~ m,/$,) {
    $str = HTML::WebMake::Main::canon_path ($str).'/';
  } else {
    $str = HTML::WebMake::Main::canon_path ($str);
  }
  $str =~ s,\\,/,gs;		# urls always have / instead of \
  $str;
}

# -------------------------------------------------------------------------

sub subst_metadata {
  my ($self, $from, $key, $defval) = @_;

  # out files cannot have metadata
  return "" if ($key =~ /^OUT:/);

  # metadata must have the format "blah.type"
  return "" unless ($key =~ /^(.*)\.([^\.]+?)$/);
  my ($base, $subkey) = ($1, $2);

  if ($from eq $base) { goto failed_to_find; }

  # see if it's a magic metadatum
  my $magicmeta = $self->get_magic_metadata ($from, $key, $base, $subkey);
  if (defined $magicmeta) { return $magicmeta; }

  # if it's an external (ie. not on "this") metadatum, try to
  # (a) get it from cache or (b) load the content to get it
  if ($base ne 'this') {
    my $meta;
    my $cont = $self->{contents}->{$base};
    goto failed_to_find if (!defined $cont);

    # just check the cache, if the datasource location has not
    # been modified.
    if ($self->check_content_dep ($cont->get_filename(),
      		$self->{current_subst}->{filename}, undef)
      		&& !$self->{force_output})
    {
      $meta = $self->getcache()->get_metadata ($key);
      if (defined $meta) {
	return $self->metadata_to_content ($from, $key, $meta, $cont);
      }
      goto use_default_or_blank;
    }

    # if the content is generated, it can't have metadata
    if ($cont->is_generated_content()) {
      goto use_default_or_blank;
    }

    # load the content it may be defined in; that may cause it
    # to be loaded.
    $cont->load_metadata ($base, $key);
    $self->add_content_dependency ($cont);

    $meta = $self->getcache()->get_metadata ($key);
    if (defined $meta) {
      return $self->metadata_to_content ($from, $key, $meta, $cont);
    }
  }

failed_to_find:
  $defval = $self->use_default_metadata($subkey, $defval);
  if (defined $defval) { return $defval; }

  if (!$self->{current_subst}->{quiet}) {
    vrb ("no value defined for metadata or content \$[$key] in \"$from\".");
  }
  return "";

use_default_or_blank:
  $defval = $self->use_default_metadata($subkey, $defval);
  if (defined $defval) { return $defval; }
  return "";
}

sub use_default_metadata {
  my ($self, $subkey, $defval) = @_;

  if (!defined $defval) {
    # handle metadata that has generic builtin defaults
    $defval = $self->{metadata}->get_default_value ($subkey);
  }

  return $defval;
}

# -------------------------------------------------------------------------

sub get_magic_metadata {
  my ($self, $from, $key, $base, $metaname) = @_;

  my $cont = $self->get_content_obj ($base);
  if (!defined $cont) { return undef; }

  my $val = $cont->get_magic_metadata ($from, $metaname);
  if (!defined $val) { return undef; }

  # write it to the cache so later invocations, that don't read or
  # parse the metadata-tagged file, will be able to use the value
  $self->getcache()->put_metadata ($key, $val);
  return $val;
}

# -------------------------------------------------------------------------

sub get_deferred_builtin_content {
  my ($self, $from, $key) = @_;

  if ($key eq "WebMake.Time") {
    return strftime "%a %b %e %H:%M:%S %Y", localtime();
  }
  if ($key eq "WebMake.OutFile") {
    return $self->{current_subst}->{filename};
  }
  if ($key eq "WebMake.OutName") {
    return $self->{current_subst}->{outname};
  }
  if ($key eq "WebMake.PerlLib") {
    return $self->{perl_lib_dir};
  }
  if ($key eq "WebMake.SourceFiles") {
    return join (' ', $self->source_file_list());
  }
  if ($key eq "WebMake.GeneratedFiles") {
    return join (' ', $self->generated_file_list());
  }
  undef;
}

# -------------------------------------------------------------------------

sub source_file_list {
  my ($self) = @_;
  return @{$self->{source_files}};
}

sub generated_file_list {
  my ($self) = @_;
  return sort keys %{$self->{outs}};
}

sub add_source_files {
  my $self = shift;
  push (@{$self->{source_files}}, @_);
}

# -------------------------------------------------------------------------

sub find_perl_lib_dir {
  my ($self) = @_;

  my $append;
  if ($^O eq 'MacOS') {
    $append = ":HTML:WebMake:PerlLib";
  } else {
    $append = "/HTML/WebMake/PerlLib";
  }

  foreach my $dir (@INC) {
    if (-d $dir.$append) { return $dir.$append; }
  }

  $self->fail ("cannot find \$\{WebMake.PerlLib\} directory");
  return "";
}

# -------------------------------------------------------------------------

# evaluate perl code from the WebMake file. We support perlpreproc and
# perlpostdecl as tag names for backwards compat.
# perlprint uses stdout from the code block.
sub eval_code_at_parse {
  my ($self, $str) = @_;

  if ($$str !~ /\<\{/s)	#}
  {
    return undef;
  }

  $self->{last_perl_code_text} = undef;
  $$str =~ s/^\s*\<\{(perlpreproc|perlpostdecl|perlout|perl)\s+(.+?)\s*\}\>/
	    $self->_p_interpret($1, $2, '');
	  /gies;
  $self->{last_perl_code_text};
}

# evaluate perl code at reference time.
sub eval_code_at_ref {
  my ($self, $from, $str) = @_;

  if ($$str !~ /\<\{/s)	#}
  {
    return undef;
  }

  $self->{last_perl_code_text} = undef;
  $$str =~ s/\<\{set\s*name\s*=\s*(.+?)\s+value\s*=\s*(.+?)\s*\}\>/
    $self->_eval_set ($from, $1, $2);
  /gies;

  $$str =~ s/\<\{set\s*(.+?)\s*=\s*\"(.+?)\"\s*\}\>/
    $self->_eval_set ($from, $1, $2);
  /gies;

  $$str =~ s/\<\{set\s*(.+?)\s*=\s*(.+?)\s*\}\>/
    $self->_eval_set ($from, $1, $2);
  /gies;

  $$str =~ s/\<\{(perlout|perl)\s*(.+?)\s*\}\>/
    $self->_p_interpret($1, $2, '');
  /gies;
  $self->{last_perl_code_text};
}

sub _eval_set {
  my ($self, $from, $name, $val) = @_;
  $name =~ s/^\"(.*)\"$/$1/g;		# trim quotes
  $name =~ s/^\'(.*)\'$/$1/g;
  $val =~ s/^\"(.*)\"$/$1/g;
  $val =~ s/^\'(.*)\'$/$1/g;
  $self->set_unmapped_content ($name, $val);
  "";
}

# -------------------------------------------------------------------------

# strip wayward metadata.
sub strip_metadata ($$$) {
  my ($self, $from, $str) = @_;

  if (!defined $$str) { return; }
  if ($$str !~ /<wmmeta/i) { return; }

  my $util = $self->{util};
  $$str = $util->strip_tags ($$str, "wmmeta",
			    $self, \&tag_strip_wmmeta, qw(name));
}

sub tag_strip_wmmeta { ""; }

# -------------------------------------------------------------------------

sub _p_interpret ($$$$) {
  my ($self, $type, $txt, $defunderscoreval) = @_;

  $self->{last_perl_code_text} = '<{'.$type.' '.$txt.'}>';
  $self->getperlinterp()->interpret ($type, $txt, $defunderscoreval);
}

# -------------------------------------------------------------------------

sub getperlinterp {
  my ($self) = @_;
  if (defined $self->{perlinterp}) {
    return $self->{perlinterp};
  }

  $self->{perlinterp} = new HTML::WebMake::PerlCode ($self);
  return $self->{perlinterp};
}

# -------------------------------------------------------------------------

sub add_image_size {
  my ($self, $from, $before, $after) = @_;
  my $origdir = undef;

  if (!defined $from) { croak "No from defined in subst"; }
  if ($self->{current_subst}->{inf_loop}) { return ""; }

  my $attrtext = $before." ".$after;
  $attrtext =~ s/\s*\/\s*$//g;		# trim /> tag ending

  if (!defined $self->{have_image_size_module}) {
    if (eval 'require Image::Size;') {
      $self->{have_image_size_module} = 1;
    } else {
      vrb ("\${IMGSIZE} tag: cannot load Image::Size module, not supported");
      $self->{have_image_size_module} = 0;
    }
  }

  my $attrs = $self->{util}->parse_xml_tag_attributes
		 		("img", $attrtext, "\${IMGSIZE}", qw{src});

  if (!$self->{have_image_size_module} || !defined $attrs) {
    goto failed;
  }

  my $fname = $attrs->{src};
  $self->subst ($from, \$fname);

  if ($fname =~ /^!!/) {		# magic string indicating CGI use
    goto failed;
  }

  if ($self->{base_dir} ne '') {
    $fname = File::Spec->catfile ($self->{base_dir}, $fname);
  }

  # check the caches
  my $sizestr = $self->{imgsizes}->{$fname};
  if (defined $sizestr) {
    return '<img '.$attrtext.' '.$sizestr.' />';
  }

  $sizestr = $self->getcache()->get_metadata ($fname.".sizevalues");
  if (defined $sizestr) {
    return '<img '.$attrtext.' '.$sizestr.' />';
  }

  my $origfname = $fname;
  my ($realfname, $relfname) = $self->expand_relative_filename ($fname);

  if (!defined ($realfname)) {
    warn "\${IMGSIZE}: cannot find image file \"$origfname\" in \"$from\"\n";
    goto failed;
  }

  if (!-r $realfname) {
    warn "\${IMGSIZE}: cannot read image file \"$realfname\" in \"$from\"\n";
    goto failed;
  }

  $sizestr = '';
  if (!eval '
    use Image::Size qw(html_imgsize);
    $sizestr = html_imgsize($realfname);
    1;')
  {
    warn "\${IMGSIZE}: Image::Size failed: $! in \"$from\"\n";
    goto failed;
  }

  # write it to the caches
  $self->getcache()->put_metadata ($fname.".sizevalues", $sizestr);
  $self->{imgsizes}->{$fname} = $sizestr;

  # chdir $origdir;
  $attrtext ||= '';
  $sizestr ||= '';
  return '<img '.$attrtext.' '.$sizestr.' />';

failed:
  # if (defined $origdir) { chdir $origdir; }
  return "<img ".$attrtext." />";
}

# -------------------------------------------------------------------------

sub erfcatdir {
  return $_[1] if (File::Spec->file_name_is_absolute ($_[1]));
  return $_[1] if ($_[0] eq '');
  return File::Spec->catdir ($_[0], $_[1]);
}

sub erfcatfile {
  return $_[1] if (File::Spec->file_name_is_absolute ($_[1]));
  return $_[1] if ($_[0] eq '');
  return File::Spec->catfile ($_[0], $_[1]);
}

sub canon_path {
  my ($fname, $reldir) = @_;
  # return $fname if ($fname =~ /^\//);	# absolute path

  $fname = File::Spec->canonpath ($fname);
  1 while $fname =~ s,/\./,/,g;
  1 while $fname =~ s,^\./,,g;

  if (defined($reldir) && $reldir ne '') {
    # next, try trimming "../../d1/d2/foo" down to "foo" for links
    # in the "d1/d2" directory. tricky!  I should really have gone
    # for previous code that does this.

    my $dotdots = '../';
    $dotdots .= '../' while ($reldir =~ m,[\/\\],g);
    $dotdots .= $reldir;		# "../../d1/d2"

    my $rhs = '';
    while ($dotdots ne '') {
      last if ($fname =~ s,^\Q${dotdots}\E[\/\\],${rhs},);
      last unless ($dotdots =~ s,[\/\\]([^\/\\]+)$,,);
      $rhs .= '../';
    }
  }

  # and now trim off useless dir navigation like "foo/bar/../../baz"
  # down to "baz".

  # first, deal with "foo/bar/../../[whatever]"
  1 while $fname =~ s,^[^/][^\./]*?/+\.\./,,g;

  # then "[whatever]/foo/bar/../../[whatever]"
  1 while $fname =~ s,/[^/][^\./]*?/+\.\./,/,g;

  # then "[whatever]/foo/bar/../.."
  1 while $fname =~ s,/[^/][^\./]*?/+\.\.$,,g;

  # and finally tidy up bonus slashes
  $fname =~ s,//+,/,gs;

  return $fname;
}

sub expand_relative_filename {
  my ($self, $fname) = @_;

  if (File::Spec->file_name_is_absolute ($fname)) {
    return ($fname, $fname);
  }

  my $curdir = File::Spec->curdir();
  my $topdir;
  if (defined $self->{current_subst}->{filename}) {
    if ($self->{base_dir} ne '') {
      $topdir = $self->{base_dir};
    } else {
      $topdir = $curdir;
    }

    my $dotdots = $self->{current_subst}->{dotdots};
    my $outdir = dirname ($self->{current_subst}->{filename});

    my @searchpath = ($curdir, $outdir);
    if (defined $self->{options}->{FileSearchPath}) {
      push (@searchpath, split (/:/, $self->{options}->{FileSearchPath}));
    }

    my @relsearchpath = map { erfcatdir($dotdots, $_) } @searchpath;

    foreach my $dir (@searchpath) {
      my $reldir = shift @relsearchpath;
      my $realfname = erfcatfile ($topdir, erfcatfile ($dir, $fname));
      my $relfname = erfcatfile ($topdir, erfcatfile ($reldir, $fname));

      # canonicalise the path BEFORE checking for its existence. This
      # is necessary, because a file path that contains "data/foo/../../blah"
      # will fail if "data/foo" dirs do not exist, but will pass if
      # it's canon'ed down to just "blah".
      #
      # warn "JMD searching $reldir $realfname $relfname";
      $realfname = canon_path ($realfname, $outdir);
      $relfname = canon_path ($relfname, $outdir);
      # warn "JMD post-searching $realfname $realfname";

      if (-e $realfname) {
	return ($realfname, $relfname);
      }
    }

  } else {
    warn "oops? don't know my current filename for expand_relative_filename";
  }

  return undef;
}

# -------------------------------------------------------------------------

sub add_content_dependency {
  my ($self, $cont) = @_;

  my $fname = $cont->get_filename();

  if ($fname eq $SUBST_EVAL) {
    if ($self->{risky_fast_rebuild}) {
      dbg2 ("dependency: ". $cont->{name}.": [perl code, ignored]");
    } else {
      dbg2 ("dependency: ". $cont->{name}.": [perl code, always refreshed]");
      $self->{cont_dependencies}->{$fname} = 1;
    }
    return;
  }
  elsif ($fname eq $SUBST_DEP_IGNORE) {
    # dbg2 ("dependency: ". $cont->{name}.": [ignored as a dependency]");
    return;
  }
  elsif ($fname eq $SUBST_META) {
    # dbg2 ("dependency: ". $cont->{name}.": [metadata, not tracked]");
    return;
  }

  foreach my $fname ($cont->get_deps()) {
    if (!defined $self->{file_modtimes}->{$fname}) {
      die "$fname has no modtime recorded for dependencies";
    }
    if ($fname =~ m{\Q$self->{perl_lib_dir}\E}o) {
      # dbg2 ("dependency: ". $cont->{name}.": [perl lib, not tracked]");
      return;
    }
    dbg2 ("dependency: ". $cont->{name}.": $fname");
    $self->{cont_dependencies}->{$fname} = $self->{file_modtimes}->{$fname};
  }
}

sub add_url_dependency {
  my ($self, $url) = @_;
  
  # TODO: deal with URL dependencies
}

sub clear_dependencies {
  my ($self, $url) = @_;

  $self->{cont_dependencies} = { };
}

# -------------------------------------------------------------------------

sub set_file_modtime {
  my ($self, $file, $mod) = @_;
  $self->{file_modtimes}->{$file} = $mod;
}

sub cached_get_modtime {
  my ($self, $file) = @_;

  my $nowmod = $self->{file_modtimes}->{$file};
  if (defined ($nowmod)) { return $nowmod; }

  my @s = stat $file; $self->set_file_modtime ($file, $s[9]);
  $s[9];
}

# similar to the above, but it can handle <contents> and <media>
# datasources too.
sub cached_get_location_modtime {
  my ($self, $file) = @_;
  if ($file =~ /^([a-zA-Z0-9]+):/) {
    my $proto = $1;
    if (!defined $self->{dep_datasources}->{$proto}) {
      $self->{dep_datasources}->{$proto} = new
	  HTML::WebMake::DataSource ($self, $file, "(depend)", { });
    }
    return $self->{dep_datasources}->{$proto}->get_location_mod_time ($file);
  } else {
    return $self->cached_get_modtime ($file);
  }
}

# -------------------------------------------------------------------------

=item $f->make (@fnames)

Make either the files named by $fnames (or all outputs if $fname is not
supplied), based on the WebMake files read earlier.

=cut

sub make {
  my ($self, @fnames) = @_;

  $self->{renames_required} = [ ];
  $self->{content_deps_required} = [ ];

  if ($#fnames < 0) {
    @fnames = @{$self->{out_order}};
  }

  foreach my $outf (@fnames) {
    $self->make_file ($outf);

    $self->{current_tick}++;
    if ($self->{current_tick} % 50 == 0) { $self->gc_contents(); }
  }

  my $tries = 0;
  while ($self->finish_deferred_files(0)) {
    if ($tries++ > 3) {
      $self->fail ("loop or unreffed content item in deferred URLs, ".
      			"cannot complete");
      $self->finish_deferred_files(1);
      last;
    }
  }

  my %done = ();
  foreach my $pair (@{$self->{renames_required}}) {
    my ($from, $to) = @{$pair};
    my $bak = $to.".bak";

    next if (defined $done{$from});
    dbg ("Renaming new file: $from -> $to");

    unlink ($bak);
    if (-f $to && !rename ($to, $bak)) {
      $self->fail ("Failed to rename \"$to\" to \"$bak\"!");
      next;
    }
    if (!rename ($from, $to)) {
      $self->fail ("Failed to rename \"$from\" to \"$to\"!");
      next;
    }
    unlink ($bak);	# new version is in-place, backup no longer reqd
    $done{$from} = 1;
  }

  foreach my $pair (@{$self->{content_deps_required}}) {
    my ($fname, $deps) = @{$pair};
    $self->getcache()->set_content_deps ($fname, %{$deps});
  }
}

# -------------------------------------------------------------------------

=item $pagetext = $f->make_to_string ($fname)

Make the file named by $fname, and output its text to STDOUT, based on the
WebMake files read earlier.

=cut

sub make_to_string {
  my ($self, $fname) = @_;

  $self->{making_to_string} = 1;
  $self->{making_to_string_output} = '';

  $self->make_file ($fname);

  my $out = $self->{making_to_string_output};
  delete $self->{making_to_string_output};
  return $out;
}

# -------------------------------------------------------------------------

sub make_file ($$) {
  my ($self, $fname) = @_;

  my $outfname;
  if ($self->{base_dir} ne '') {
    $outfname = File::Spec->catfile ($self->{base_dir}, $fname);
  } else {
    $outfname = $fname;
  }

  if ($self->{force_output} == 0) {
    if ($self->depend_check ($fname, $outfname)) {
      dbg ("not making (dependencies unchanged): $outfname");
      return;
    }
  }

  my $out = $self->{outs}->{$fname};
  if (!defined $out) {
    $self->fail ("No target \"$fname\" found!"); return;
  }

  my $fmt = $out->get_format();
  if (!defined $fmt) {
    croak ("no format defined for $fname");
  }

  my $dotdots = '';
  ($dotdots .= '../') while ($fname =~ m,[/\\],g);

  my $useurls = 1;
  if (!$out->use_for_content_urls()) { $useurls = 0; }

  $self->clear_dependencies();
  delete $self->{contents}->{"__MainContentName"};

  # clear out any "this.blah" content items from the previous file
  dbg2 ("clearing \"this.*\" metadata for $fname");
  foreach my $name (@{$self->{this_metas_added}}) {
    delete $self->{metadatas}->{$name};
  }
  $self->{this_metas_added} = [ ];

  $self->_subst_open($fname, $out->{name}, $dotdots, $fmt, $useurls);	#{
  my $txt = $out->get_text();
  $self->strip_metadata ($fname, \$txt);
  $self->subst_deferred_refs ($fname, \$txt);

  if ($txt =~ /{!!WMDEFER/) {
    $self->make_file_defer ($fname, $out, $outfname, $txt);
  } else {
    $self->make_file_finish ($fname, $out, $outfname, $txt);
  }

  $self->_subst_close();				#}

  1;
}

# -------------------------------------------------------------------------

sub make_file_finish ($$$) {
  my ($self, $fname, $out, $outfname, $txt) = @_;

  my $dotdots = '';
  ($dotdots .= '../') while ($fname =~ m,[/\\],g);

  # unescape escaped references to our entities.
  $txt =~ s/\&wmdollar;/\$/gis;

  # clean HTML output.
  if ($out->get_format() =~ /^text\/html$/i) {
    my $cleanparams = !defined($out->{clean}) ? $DEFAULT_CLEAN_FEATURES : $out->{clean};
    $txt = $self->clean_html (\$txt, $fname, $cleanparams);

    # always trim the very first and last bits of whitespace in the
    # file anyway, for HTML output. Leave in 1 \n at EOF to look nice.
    $txt =~ s/^\s+//gs;
    $txt =~ s/\s+$/\n/gs;

    # convert EOLs to native format. Note that we don't have to
    # worry about \r\n, \r, or others; Perl will convert incoming
    # eols to \n while reading since we don't use "binmode".
    my $eol = $self->{util}->text_eol();
    $txt =~ s/\n/${eol}/gs;
  }

  # protection against var references that got through
  if ($outfname =~ /\$/) {
    $self->fail ("bad filename: $outfname"); return;
  }

  if (!$self->{making_to_string} && $self->{force_output} == 0 && -f $outfname)
  {
    my $curtxt;
    if ((-s $outfname == length($txt))
      	&& (open (IN, "<$outfname"))
	&& ($curtxt = join ('', <IN>))
	&& (close IN)
	&& ($curtxt eq $txt)
	)
    {
      dbg ("not making (text has not changed): $outfname");
      return;
    }
  }

  vrb ("making: $outfname");
  my $newfname = $outfname.".new";

  if ($self->{making_to_string}) {
    $self->{making_to_string_output} = $txt;

  } else {
    if (!open (OUT, ">$newfname")) {
      # make the dir, just in case that was the problem
      (-f $newfname) or mkpath (dirname ($newfname));
      # and try again...
      if (!open (OUT, ">$newfname")) {
	$self->fail ("Cannot write: $newfname"); return;
      }
    }
    print OUT $txt;
    if (!close (OUT)) {
      $self->fail ("Cannot write: $newfname"); return;
    }

    push (@{$self->{renames_required}}, [ $newfname, $outfname ]);
    push (@{$self->{content_deps_required}}, [ $fname,
				      $self->{cont_dependencies} ]);
  }
  1;
}

# -------------------------------------------------------------------------

sub make_file_defer {
  my ($self, $fname, $out, $outfname, $txt) = @_;

  if ($self->{making_to_string}) {
    die "cannot defer writes when making to string!";
  }

  dbg ("making (deferring write, some URLs are still unknown): $outfname");
  $self->{need_rewrite_for_deferred_urls}->{$fname} = $txt;
  $self->{need_rewrite_subst_context}->{$fname} = $self->{current_subst};
}

sub finish_deferred_files {
  my ($self, $give_up_if_still_deferred) = @_;

  my %new_deferred_list = ();
  my $still_have_deferreds = 0;

  foreach my $fname (keys %{$self->{need_rewrite_for_deferred_urls}})
  {
    dbg ("fixing URLs in deferred out file: $fname");
    my $txt = $self->{need_rewrite_for_deferred_urls}->{$fname};
    my $ctx = $self->{need_rewrite_subst_context}->{$fname};

    $self->_subst_open($ctx->{filename}, $ctx->{outname},
    		$ctx->{dotdots}, $ctx->{format}, $ctx->{useurls});

    #{
    $txt =~ s/{!!WMDEFER_dotdots}/$ctx->{dotdots}/gs;
    $txt =~ s/{!!WMDEFER_content_url:([^}]+)}/
      $self->rewrite_a_deferred_url($1, $give_up_if_still_deferred);
    /ges;

    $self->_subst_close();

    #{
    if ($txt =~ /{!!WMDEFER_content_url:[^}]+}/) {
      # still have some left, keep it deferred
      $new_deferred_list{$fname} = $txt;
      $still_have_deferreds = 1;
      next;
    }

    dbg ("writing deferred out file: $fname");
    my $outfname;
    if ($self->{base_dir} ne '') {
      $outfname = File::Spec->catfile ($self->{base_dir}, $fname);
    } else {
      $outfname = $fname;
    }

    my $out = $self->{outs}->{$fname};

    $self->make_file_finish ($fname, $out, $outfname, $txt);
  }

  if ($still_have_deferreds) {
    %{$self->{need_rewrite_for_deferred_urls}} = %new_deferred_list;
    return 1;
  } else {
    return 0;
  }
}

sub rewrite_a_deferred_url {
  my ($self, $contname, $give_up_if_still_deferred) = @_;

  my $obj = $self->get_content_obj ($contname);

  my $url;
  if (!defined $obj || !defined ($url = $obj->get_url())) {
    $self->fail ("unable to get URL for content item: \${$contname}");
    return '';
  }

  if ($give_up_if_still_deferred && $url =~ /^\{!!WMDEFER_content_url:/)
  {
    $self->fail ("unable to get URL for content item: \${$contname}");
    return '';
  }
  return $url;
}

sub make_deferred_url {
  my ($self, $contname) = @_;
  return '{!!WMDEFER_content_url:'.$contname.'}';
}

# -------------------------------------------------------------------------

sub depend_check ($$$) {
  my ($self, $fname, $outfname) = @_;

  my @deps = $self->getcache()->get_content_deps($fname);
  my $foundadep = 0;
  my $needrebuild = 0;

  my @s = stat $outfname;
  if ($#deps >= 0 && -f _) {
    my $outmod = $s[9];
    foreach my $dep (@deps) {
      next unless (defined $dep && $dep ne '');
      $foundadep = 1;
      if (!$self->check_content_dep ($dep, $fname, $outmod)) {
	$needrebuild = 1;
      }
    }
  }

  if ($foundadep && !$needrebuild) {
    return 1;		# dependencies found, and we're OK for all of them
  } else {
    return 0;		# no prior dependencies recorded, must rebuild
  }
}

sub check_content_dep ($$$$) {
  my ($self, $dep, $fname, $outmod) = @_;

  if ($fname eq $SUBST_EVAL) {
    dbg ("subst from eval code (always rebuilt)");
    return 0;
  }
  if ($fname eq $SUBST_DEP_IGNORE) { return 1; }

  if ($dep eq $SUBST_EVAL) {
    dbg ("$fname depends on eval code (always rebuilt)");
    return 0;
  }
  if ($dep eq $SUBST_DEP_IGNORE) { return 1; }

  my $prevmod = $self->getcache()->get_modtime ($dep);
  if (!defined $prevmod) { return 0; }
  $prevmod ||= 0;

  my $nowmod = $self->cached_get_location_modtime ($dep);
  if (!defined $nowmod) { return 0; }

  if ($DEBUG > 1 && $dep ne $SUBST_DEP_IGNORE) {
    my $prevsecs = $self->{now} - $prevmod;
    my $nowsecs = $self->{now} - $nowmod;
    dbg ("$fname depends on $dep ($nowsecs secs old, previous: $prevsecs)");
  }

  if ($nowmod > $prevmod) { return 0; }

  # if the dependency file is newer than the output file,
  # we always need to rebuild. This is really a sanity check
  if (defined $outmod && $nowmod > $outmod) { return 0; }
  return 1;
}

# -------------------------------------------------------------------------

sub clean_html {
  my ($self, $txtptr, $fname, $features) = @_;

  if ($features !~ /\S/) { return $$txtptr; }

  if (!defined $self->{htmlcleaner}) {
    if (!eval '
	use HTML::WebMake::HTMLCleaner;
	$self->{htmlcleaner} = new HTML::WebMake::HTMLCleaner($self);
      1;')
    {
      warn "HTMLCleaner load failed: $@\n";
      warn "HTMLCleaner load failed -- not cleaning HTML.\n";
      $self->{htmlcleaner} = { 'loadfailed' => 1 };
      return $$txtptr;
    }
  }
  if ($self->{htmlcleaner}->{loadfailed}) { return $$txtptr; }

  $self->{htmlcleaner}->select_features ($features);
  $self->{htmlcleaner}->clean ($txtptr, $fname);
}

# -------------------------------------------------------------------------

=item $ok = $f->can_build($fname);

Returns 1 if WebMake can build the named file, 0 otherwise.

=cut

sub can_build {
  my ($self, $fname) = @_;

  return (defined $self->{outs}->{$fname});
}

# -------------------------------------------------------------------------

=item $num_failures = $f->finish();

Finish with a WebMake object and dispose of its internal open files etc.
Returns the number of serious failure conditions that occurred (files that
could not be created, etc.).

=cut

sub finish {
  my ($self) = @_;

  if (defined $self->{cache}) {
    $self->{cache}->untie();
  }
  $self->{failures};
}

# -------------------------------------------------------------------------

sub quicktxt2html {
  my $txt = join ('',@_);

  if ($HTML_LOGGING) {
    $txt =~ s/&/&amp;/gs;
    $txt =~ s/</&lt;/gs;
    $txt =~ s/>/&gt;/gs;
    $txt =~ s/\n/<br \/>\n/gs;
  }

  return $txt;
}

sub dbg {
  if ($DEBUG > 0) {
    my @now = localtime(time);
    if ($DEBUG > 1) {
      printf STDOUT ("%02d:%02d:%02d debug: %s\n",
		  $now[2], $now[1], $now[0], quicktxt2html(@_));
    } else {
      printf STDOUT ("debug: %s\n", quicktxt2html(@_));
    }
  }
}

sub dbg2 {
  if ($DEBUG > 1) { dbg(@_); }
}

sub vrb {
  if ($VERBOSE) {
    print STDOUT "webmake: ".quicktxt2html(@_, "\n");
  }
}

sub fail {
  my $self = shift;
  warn "webmake: error: ".quicktxt2html(@_, "\n");
  $self->{failures}++;
}

# intended for use with -MCarp=verbose
sub stacktrace {
  carp join ("\n", @_);
}

1;

__END__

=back

=head1 MORE DOCUMENTATION

See also http://webmake.taint.org/ for more information.

=head1 SEE ALSO

C<webmake>
C<ettext2html>
C<ethtml2text>
C<HTML::WebMake>
C<Text::EtText::EtText2HTML>
C<Text::EtText::EtHTML2Text>

=head1 AUTHOR

Justin Mason E<lt>jm /at/ jmason.orgE<gt>

=head1 COPYRIGHT

WebMake is distributed under the terms of the GNU Public License.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN
as well as:

  http://webmake.taint.org/

=cut

