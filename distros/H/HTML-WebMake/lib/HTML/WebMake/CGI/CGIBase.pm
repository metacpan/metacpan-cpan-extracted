
package HTML::WebMake::CGI::CGIBase;

use Carp;
use CGI qw/:standard/;
use strict;
use HTML::WebMake::Main;
use HTML::WebMake::CGI::Lib;
use HTML::WebMake::CGI::RWMetaTable;
use File::Basename;

use vars	qw{
  	@ISA $VERSION $HTML
};

@ISA = qw();
$VERSION = "0.1";

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    'q',		shift,
    'file_base',	undef,
    'msgs',		''
  };

  $self->{metatable} = new HTML::WebMake::CGI::RWMetaTable ();

  $self->{cvs_supported} = 0;
  if (defined $ENV{'CVSROOT'}) {
    $self->{cvs_supported} = 1;
  }
  $self->{cvs} = new HTML::WebMake::CGI::CVS ($self);

  bless ($self, $class);
  $self;
}

sub set_file_base {
  my ($self, $base) = @_;
  $self->{file_base} = $base;
  
  if (!-d $base) {
    die ("WebMakeCGI: FILE_BASE setting is invalid: ".
    		"\"$base\" is not a directory.\n");
  }

  # if we have a CVS dir in the file_base, the user has set this
  # area up with a "cvs login" and "cvs checkout". Good call.
  if (-f $base."/CVS/Root") {
    $self->{cvs_supported} = 1;
  }
}

###########################################################################

sub mksafe { return HTML::WebMake::CGI::Lib::mksafe (@_); }
sub mksafepath { return HTML::WebMake::CGI::Lib::mksafepath (@_); }
sub mksafepathlist { return HTML::WebMake::CGI::Lib::mksafepathlist (@_); }

sub txt2html {
  my $self = shift;
  my $txt = join ('',@_);
  $txt =~ s/&/&amp;/gs;
  $txt =~ s/</&lt;/gs;
  $txt =~ s/>/&gt;/gs;
  $txt =~ s/\n/<br \/>\n/gs;
  $txt;
}

sub warn {
  my ($self, $err) = @_;
  
  chomp $err; warn "WebMakeCGI: $err\n";
  $self->{msgs} .= "<font color=\"#ff0000\">Warning: $err</font><br />\n";
}

sub is_media {
  my ($self, $filename) = @_;

  if ($filename =~ /\.(?:gif|jp[eg]+|png|mov|avi|qt|mp[eg]+|ra|ram|gz|Z|zip)$/i
    || $filename =~ /\.(?:class|jar|cab|db|hist|sys|exe|com|mp3|prc|pdb|dat)$/i)
  {
    return 1;

  } else {
    return 0;
  }
}


# ---------------------------------------------------------------------------

sub run {
  my ($self) = @_;
  my $q = $self->{q};

  $|++;

  if (!$q->param ('dump')) {
    print "Content-Type: text/html\r\n\r\n";
  }

  $self->{msgs} = '';
  my $form = '';
  $self->{filename} = '';

  if (!HTML::WebMake::CGI::Lib::is_authorised ($q)) {
    $self->warn ("This site can only be edited by authenticated users.");
    goto end;
  }

  $self->{wmkfile} = &mksafepath($q->param('wmkf'));
  # this may be overridden in Site.pm, the module for editing .wmk files

  # check to see if CVS is available in this subdir
  my $base = File::Basename::dirname ($self->{wmkfile});
  if (-d $self->{file_base}."/".$base."/CVS") {
    $self->{cvs_supported} = 1;
  }

  $self->{cvsadd} = &mksafepathlist($q->param('cvsadd'));
  $self->{cvsaddbin} = &mksafepathlist($q->param('cvsaddbin'));
  $self->{cvsrm} = &mksafepathlist($q->param('cvsrm'));
  $self->{cvsrmdir} = &mksafepathlist($q->param('cvsrmdir'));

  # if we have a dirprefix parameter, add it to the filename.
  if ($q->param('dirprefix')) {
    $self->{filename} =
    		$self->makepath ($q->param('dirprefix'), $q->param('f'));
    $q->param('dirprefix', '');
    $q->param('f', $self->{filename});

  } else {
    $self->{filename} = &mksafepath($q->param('f'));
  }

  if (!defined $self->{wmkfile} && !$self->{no_wmkf_needed}) {
    $self->warn ("No .wmk file specified! Please use the 'wmkf' parameter.");
    goto end;
  }

  if (!$self->{no_filename_needed}
  	&& (!defined $self->{filename} || $self->{filename} eq ''))
  {
    $self->warn ("No filename provided.\n");
  } else {
    $form = $self->subrun ($q);
  }

end:
  if (!$q->param ('dump')) {
    $self->write_html_main ($form);
    $self->write_html_footer ();
  }
}

# ---------------------------------------------------------------------------

sub std_cgi_hidden_items {
  my ($self, $q) = @_;
  return $q->hidden(-name=>'wmkf',-value=>$self->{wmkfile})
  	. $q->hidden(-name=>'cvsadd',-value=>$self->{cvsadd})
  	. $q->hidden(-name=>'cvsaddbin',-value=>$self->{cvsaddbin})
  	. $q->hidden(-name=>'cvsrm',-value=>$self->{cvsrm})
  	. $q->hidden(-name=>'cvsrmdir',-value=>$self->{cvsrmdir});
}

# ---------------------------------------------------------------------------

sub std_cgi_hidden_items_as_str {
  my ($self, $q) = @_;
  return 'wmkf='.$q->escape ($self->{wmkfile}) . '&'
    	. 'cvsadd='.$q->escape ($self->{cvsadd}) . '&'
    	. 'cvsaddbin='.$q->escape ($self->{cvsaddbin}) . '&'
    	. 'cvsrm='.$q->escape ($self->{cvsrm}) . '&'
    	. 'cvsrmdir='.$q->escape ($self->{cvsrmdir});
}

# ---------------------------------------------------------------------------

sub write_html_main {
  my ($self, $form) = @_;
  my $q = $self->{q};

  my $txt = $self->{html};

  $txt =~ s/__ERRORS__/$self->{msgs}/gs;
  $txt =~ s/__FORM__/${form}/gs;
  $txt =~ s/__FNAME__/$self->{filename}/gs;
  $txt =~ s{__REINVOKE__(\S+?)__}{
    $self->reinvoke_with_param(0,$1);
  }ge;
  $txt =~ s{__REINVOKEALL__(\S+?)__}{
    $self->reinvoke_with_param(1,$1);
  }ge;

  print $txt;
}

# ---------------------------------------------------------------------------

sub write_html_footer {
  my ($self) = @_;
  my $q = $self->{q};

  return if ($self->{written_html_footer});
  $self->{written_html_footer} = 1;

  my $txt = qq{

    <hr />
    <p>
    <a href="__REINVOKE__build=1__">[Build Site]</a>
    &nbsp;
    <a href="__REINVOKE__build=1&full=1__">[Build Fully]</a>

  }; #"

  if ($self->{cvs_supported}) {
    $txt .= qq{
    &nbsp;
    <a href="__REINVOKE__Update=1__">[Update From CVS]</a>
    &nbsp;
    <a href="__REINVOKE__Commit=1__">[Commit Changes To CVS]</a>
    }; #"
  }

  $txt .= qq{
    </p>
    <hr />

<p>
<em><smaller>

  You are logged in as __USERNAME__, editing the site \"__WMKF__\",
  with webmake.cgi from WebMake __WMVER__.

</smaller></em>
</p>
</body></html>

  };#"

  my $user = $q->remote_user();
  my $wmkf = $self->{wmkfile}; $wmkf ||= '(none)';

  $txt =~ s/__FNAME__/$self->{filename}/gs;
  $txt =~ s/__USERNAME__/${user}/gs;
  $txt =~ s/__WMKF__/${wmkf}/gs;
  $txt =~ s/__WMVER__/${HTML::WebMake::Main::VERSION}/gs;
  $txt =~ s{__REINVOKE__(\S+?)__}{
    $self->reinvoke_with_param(0,$1);
  }ge;

  print $txt;
}

# ---------------------------------------------------------------------------

sub reinvoke_with_param {
  my ($self, $keepexisting, $params) = @_;
  my $q = $self->{q};

  my $href = $q->url (-relative=>1, -path=>1) . '?' . $params;
  my $str;
  if ($keepexisting)
  {
    # keep all CGI parameters (except the ones overridden by new settings)
    $str = $q->query_string ();
  } else {
    # just keep the essentials. namely: the name of the .wmk file,
    # and cvs operations pending
    $str = $self->std_cgi_hidden_items_as_str ($q);

  }

  my %pkeys = ();
  foreach my $pkey (split (/[\&\;]/, $params)) {
    $pkey =~ s/=.*$//; $pkeys{$pkey} = 1;
  }

  foreach my $elem (split (/\&/, $str)) {
    if ($elem =~ /^(.*?)=/) {
      if (defined $pkeys{$1}) { next; }
    }

    $href .= '&'.$elem;
  }

  $href;
}

# ---------------------------------------------------------------------------

sub mydirname {
  my ($self) = @_;
  return File::Basename::dirname ($self->{filename});
}

# ---------------------------------------------------------------------------

sub makepath {
  my ($self, $dir, $path) = @_;

  if (!defined($dir) || $dir eq '' || $dir eq '.') {
    # ignore it
  } else {
    $path = $dir.'/'.$path;
  }

  return HTML::WebMake::CGI::Lib::mksafepath ($path);
}

###########################################################################

sub cvs_add {
  my ($self, $fname) = @_;

  return if (!$self->{cvs_supported});

  if ($self->is_media ($fname)) {
    if ($self->{cvsaddbin}) {
      $self->{cvsaddbin} .= "|".$fname;
    } else {
      $self->{cvsaddbin} = $fname;
    }
  } else {
    if ($self->{cvsadd}) {
      $self->{cvsadd} .= "|".$fname;
    } else {
      $self->{cvsadd} = $fname;
    }
  }
}

sub cvs_delete {
  my ($self, $fname) = @_;

  return if (!$self->{cvs_supported});

  if (-d $self->{file_base}.$fname) {
    if ($self->{cvsrmdir}) {
      $self->{cvsrmdir} .= "|".$fname;
    } else {
      $self->{cvsrmdir} = $fname;
    }
  } else {
    if ($self->{cvsrm}) {
      $self->{cvsrm} .= "|".$fname;
    } else {
      $self->{cvsrm} = $fname;
    }
  }
}

###########################################################################

1;
