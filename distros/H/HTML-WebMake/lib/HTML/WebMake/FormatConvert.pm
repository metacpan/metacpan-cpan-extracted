#

package HTML::WebMake::FormatConvert;

use Pod::Html;

###########################################################################
# Define the converters we support here.
# The method used is as follows:
#
# 1. add a handler method at bottom; see et_to_html() for an example.
# 2. add an add_converter() call to this method. The arguments are as
#    follows:
#
#      arg1: The "source" format, what's found in the <content> tag.
#            Use MIME format. These are treated as case-insensitive.
#      arg2: The "target" format, typically 'text/html'.
#      arg3: A module required to use this converter.  The best practice
#            is to define the complicated conversion logic, if there is
#            any, in a Perl module and call into that from this object.
#            Again, see et_to_html() for an example.  If no module is
#            required, leave this as undef.
#      arg4: the FormatConvert method used to perform the conversion.

sub set_converters {
  my $self = shift;

  $self->add_converter ('text/et', 'text/html',
  			'Text::EtText::EtText2HTML', \&et_to_html);

  $self->add_converter ('text/pod', 'text/html',
  			'Pod::Html', \&pod_to_html);

  $self->add_converter ('text/html', 'text/plain',
  			undef, \&html_to_plain);
}

###########################################################################


use Carp;
use strict;

use HTML::WebMake::Main;

use vars	qw{
  	@ISA 
	@OPTIMISED_FORMATS $SETUP_FMTS_LOOKUP
	%FMT_TO_ZNAME %ZNAME_TO_FMT
};




# these are optimised into integers instead of strings, to save
# memory
@OPTIMISED_FORMATS = qw(
	text/plain text/html text/et text/pod
);

%FMT_TO_ZNAME = ();
%ZNAME_TO_FMT = ();
$SETUP_FMTS_LOOKUP = 0;

###########################################################################

sub new ($$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main) = @_;

  my $self = {
    'main'		=> $main,
    'module_table'	=> { },
    'callback_table'	=> { }
  };
  bless ($self, $class);

  $self->set_converters();
  $self;
}

sub dbg { HTML::WebMake::Main::dbg (@_); }

# -------------------------------------------------------------------------

sub format_name_to_zname {		# STATIC
  my ($name) = @_;

  if (!$SETUP_FMTS_LOOKUP) {
    $SETUP_FMTS_LOOKUP = 1;
    my $i = 0;
    foreach my $fmt (@OPTIMISED_FORMATS) {
      $FMT_TO_ZNAME{$fmt} = $i;
      $ZNAME_TO_FMT{$i} = $fmt;
      $i++;
    }
  }

  if (!defined $name) { return undef; }
  my $zname = $FMT_TO_ZNAME{$name};
  if (defined $zname) { return $zname; }
  return $name;
}

sub format_zname_to_name {		# STATIC
  my ($zname) = @_;

  if (!defined $zname) { return undef; }
  my $name = $ZNAME_TO_FMT{$zname};
  if (defined $name) { return $name; }
  return $zname;
}

# -------------------------------------------------------------------------

sub add_converter {
  my ($self, $infmt, $outfmt, $module, $callback) = @_;
  my $key = $infmt." > ".$outfmt;
  $key =~ tr/A-Z/a-z/;
  $self->{module_table}->{$key} = $module;
  $self->{callback_table}->{$key} = $callback;
}

# -------------------------------------------------------------------------

sub convert {
  my ($self, $contobj, $infmt, $outfmt, $txt, $ignore_cache) = @_;

  if ($infmt eq $outfmt) { return $txt; }
  my $key = $infmt." > ".$outfmt;
  $key =~ tr/A-Z/a-z/;

  if (!$ignore_cache) {
    my $cached = $self->{main}->getcache()->get_format_conversion
    		($contobj, $key, $txt);

    if (defined $cached) { return $cached; }
  }

  my $meth = $self->{callback_table}->{$key};
  if (!defined $meth) {
    croak ("Do not know how to convert from \"$infmt\" to \"$outfmt\"!\n");
  }

  my $mod = $self->{module_table}->{$key};
  if (defined $mod && !eval 'require '.$mod.';1;') {
    die "FormatConvert: cannot load $mod module: $!\n";
  }

  $txt = &$meth ($self, $contobj, $txt);

  if (!$ignore_cache) {
    $self->{main}->getcache()->store_format_conversion
		  ($contobj, $key, $txt);
  }
  $txt;
}

# -------------------------------------------------------------------------

# for prospective format implementors: note the three args:
# $self = this object, as usual
# $contobj = the content object; you can read attributes from this.
#   See the example in pod_to_html() below.
# $txt = the text to convert.

sub et_to_html {
  my ($self, $contobj, $txt) = @_;

  if (!defined $self->{ettext}) {
    eval '
      use Text::EtText::EtText2HTML;
      $self->{ettext} = new Text::EtText::EtText2HTML;
    1;' or
    die "FormatConvert: cannot create Text::EtText::EtText2HTML object: $!";

    $self->{ettext}->{glossary} = $self->{main}->getglossary();
    $self->{ettext}->set_option ('EtTextHrefsRelativeToTop', '1');
    $self->{ettext}->set_options (%{$self->{main}->{options}});
  }

  $self->{ettext}->text2html ($txt);
}

# -------------------------------------------------------------------------

sub pod_to_html {
  my ($self, $contobj, $txt) = @_;
  local ($_);

  my @args = ();
  if (defined $contobj->{podargs}) {
    @args = split (' ', $contobj->{podargs});
  }

  # tut! Pod::Html can only handle file input
  my $tmpin = $self->{main}->tmpdir().'.tmp_wm_pod_i.'.$$;
  my $tmpout = $self->{main}->tmpdir().'.tmp.wm_pod_o.'.$$;

  open (POD_IN, ">$tmpin") or die "Cannot write to $tmpin";
  print POD_IN $txt; undef $txt;
  close POD_IN;

  open (POD_OUT, "+>$tmpout") or die "Cannot write to $tmpout";
  my $start = tell(POD_OUT);

  pod2html ('--infile='.$tmpin, '--outfile='.$tmpout, '--title=x', @args);

  seek (POD_OUT, $start, 0);
  $_ = join ('', <POD_OUT>);
  close POD_OUT;

  unlink ($tmpin, $tmpout);
  unlink ("pod2htmd.x~~");	# more pod spoor
  unlink ("pod2html.x~~");

  # And now, some POD cleaning; the POD HTML isn't great unfortunately.

  # strip anything not inside the body from POD output, for
  # our purposes.
  s/^<HTML>.*?<BODY>//gs;
  s/<\/BODY>.*?$//gs;

  # remove stray <p> start tags with no end tags.
  s/<p>\s+(<h1>|<hr>)/$1/gis;

  # clean up method lists
  s/(<dt>.*?)<dd>/$1<\/dt><dd>/gis;
  s/(<dd>.*?)<dt>/$1<\/dd><dt>/gis;
  s/(<dd>.*?)<\/dl>/$1<\/dd><\/dl>/gis;

  # remove empty paras
  s/<p>\s*<\/p>//gis;

  $_;
}

# -------------------------------------------------------------------------

sub html_to_plain {
  my ($self, $contobj, $txt) = @_;

  # keep it (very) simple
  $txt =~ s/<p>/\n/gis;
  $txt =~ s/<[^>]+>//gs;
  $txt;
}

# -------------------------------------------------------------------------

1;
