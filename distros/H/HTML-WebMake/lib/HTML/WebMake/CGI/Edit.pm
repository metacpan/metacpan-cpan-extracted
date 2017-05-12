
package HTML::WebMake::CGI::Edit;

use strict;
use HTML::WebMake::CGI::CGIBase;
use HTML::WebMake::CGI::Site;

use vars	qw{
  	@ISA $HTML
};

@ISA = qw(HTML::WebMake::CGI::CGIBase);

###########################################################################

$HTML = q{

<html><head>
<title>WebMake: Edit File "__FNAME__"</title>
</head>
<body bgcolor="#ffffff" text="#000000" link="#3300cc" vlink="#665066">

<h1>WebMake: Edit File "__FNAME__"</h1><hr />

__ERRORS__

__FORM__
};

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new (@_);

  $self->{html} = $HTML;
  $self->{read_metas} = '';

  bless ($self, $class);
  $self;
}

###########################################################################

sub subrun {
  my ($self, $q) = @_;
  my $form;

  if ($q->param ('fileless')) {
    $self->{fileless} = 1;
  }

  if ($q->param ('dump')) {
    $form = $self->write_dump_page ();
  } elsif ($q->param ('Save')) {
    $form = $self->write_save_page ();
  # } elsif ($q->param ('Preview')) {
    # $form = $self->write_preview_page ();
  } else {
    $form = $self->write_edit_page ();
  }

  $form;
}


sub write_edit_page
{
  my $self = shift;
  my $q = $self->{q};

  my $form;
  if ($q->param ('upload')) {
    $form = $q->start_multipart_form();
  } else {
    $form = $q->startform();
  }

  $form .= q{
    <table>
  };

  $self->{read_metas} = { };
  {
    my $allmetas = $self->{metatable}->read_metatable_file ($self->{file_base});
    if (defined $allmetas) {
      $self->{read_metas} = $allmetas->{$self->{filename}};
    }
  }

  # read the text from the file, or from the CGI parameters for fileless
  # edits.
  my $text = $self->get_item_text ($q);

  $form .= "<tr><td width=120>"
	. "Title:"
	. "</td><td>"
	. $q->textfield (-name => 'm_title',
		-size => 65,
		-default => $self->{read_metas}->{title})
	. "</td></tr>";

  if ($q->param ('allmetadata')) {
    $form .=

        "<tr><td>&nbsp;</td><td>&nbsp;</td></tr>"
      . "<tr><td></td><td><h2>Other Metadata:</h2></td></tr>"

      . $q->Tr ($q->td ($q->p ("Section:"))
	      . $q->td ( $q->textfield (-name => 'm_section',
		      -default => $self->{read_metas}->{section})))

      . $q->Tr ( $q->td ("Score:")
      	      . $q->td ( $q->textfield (-name => 'm_score',
	      	      -default => $self->{read_metas}->{score})))

      . $q->Tr ( $q->td ({'-valign' => 'top'}, "Abstract:")
      	      . $q->td ( $q->textarea (-name => 'm_abstract',
	      	      -default => $self->{read_metas}->{abstract},
	      	      -rows => 5,
	      	      -columns => 80)))
      . $q->Tr ( $q->td ("Up:")
      	      . $q->td ( $q->textfield (-name => 'm_up',
	      	      -default => $self->{read_metas}->{up})))
      . $q->Tr ( $q->td ("Author:")
      	      . $q->td ( $q->textfield (-name => 'm_author',
	      	      -size => 65,
	      	      -default => $self->{read_metas}->{author})));

    $form .= q{

	<tr><td>
	</td><td>
	<p>
	<a href="__REINVOKEALL__allmetadata=0__">
	[Less Metadata...]</a>
	</p>
    };

  } else {
    $form .= q{

	<tr><td>
	</td><td>
	<p>
	<a href="__REINVOKEALL__allmetadata=1__">
	[More Metadata...]</a>
	</p>

    };
  }

  if ($self->is_media($self->{filename})) {
    $form .= q{

	<p>

	(Note: since this is a non-text item, this metadata cannot be stored in
	the content file itself.  Instead, it will be stored in a <a
	href=http://webmake.taint.org/doc/metatable.html>metatable</a> called
	<em>metadata.xml</em> in the top-level directory.  You may need to modify
	the WebMake file for this site to read this file.)

      </p>
      </td></tr>
    };
  }

  $form .= "<tr><td>&nbsp;</td><td>&nbsp;</td></tr>\n\n";

  if ($q->param ('upload')) {
    $form .= $q->hidden(-name=>'upload',-value=>'1');

    $form .= $q->Tr ("<td> Upload file: </td>"
    	. $q->td ( $q->filefield (-name => 'upload_file',
		-default => '',
		-size => 50,
		-maxlength => 256)));

    $form .= q{
        <tr><td></td><td> <p>

	<a href="__REINVOKEALL__upload=0__">[Edit file in-page]</a>

	</p> </td></tr>
    };

  } else {
    my @txtfrom;

    if ($self->is_media($self->{filename})) {
      $form .= $q->hidden(-name=>'upload',-value=>'0');
      @txtfrom = $q->radio_group (-name => 'text_from',
		  -values => [
			  'Load from URL',
			  ],
		  -default => 'Load from URL');

    } else {
      $form .= $q->hidden(-name=>'upload',-value=>'0');
      @txtfrom = $q->radio_group (-name => 'text_from',
		  -values => [
			  'Load from URL',
			  'Textbox'
			  ], -default => 'Textbox');
    }

    if (!$self->is_media($self->{filename})) {
      $form .= $q->Tr ($q->td ({'-valign'=>'top'}, $txtfrom[1] . ":")
	. $q->td ( $q->textarea (-name => 'upload_text',
		-default => $text,
		-rows => 20,
		-columns => 80)));
    }

    $form .= "<tr><td>&nbsp;</td><td>&nbsp;</td></tr>\n\n";

    $form .= $q->Tr ($q->td ({'-valign'=>'top'}, $txtfrom[0] . ":")
	. $q->td ( $q->textfield (-name => 'upload_url',
		-size => 65, -default => '')
	.  "<p><em>
	  (Note: \"load from URL\" has not been implemented yet.
	  Do not use it. TODO)
	  </em></p>"
	));

    $form .= "<tr><td>&nbsp;</td><td>&nbsp;</td></tr>\n\n";

    $form .= q{
        <tr><td><p>Upload from disk:</p></td><td><p>

	<a href="__REINVOKEALL__dump=1__" target=dumper>[Display raw file]</a>

	&nbsp;
	&nbsp;
	&nbsp;
	<a href="__REINVOKEALL__upload=1__">[Upload new file]</a>

	</p> </td></tr>
    };
  }

  $form .= "<tr><td>&nbsp;</td><td>&nbsp;</td></tr>\n\n";

  # $form .= $q->Tr ($q->td ("Link text:")
      # . $q->td ( $q->textfield (-name => 'link_text',
	      # -size => 65,
	      # -default => '')));
    
  $form .= "<tr><td></td><td>";

  $form .= $q->hidden(-name=>'step',-value=>'editing')
      # . $q->submit(-name=>'Preview',-value=>'Preview')
      # . "&nbsp;"
      . $q->submit(-name=>'Save',-value=>'Save')
      . "&nbsp;"
      . $q->hidden(-name=>'edit',-value=>'1')
      . $q->hidden(-name=>'f', -value=>$self->{filename});

  if ($self->{fileless}) {
    $form .=
        $q->hidden(-name=>'fileless',-value=>'1')
      . $q->hidden(-name=>'saveasid',-value=>$q->param ('saveasid'));
  }

  $form .= $self->std_cgi_hidden_items($q);
  $form .= $q->endform();

  $form .= "</td></tr></table> ";

  $form;
}

# ---------------------------------------------------------------------------

sub write_dump_page
{
  my $self = shift;
  my $q = $self->{q};

  # print a header
  if ($self->is_media($self->{filename})) {
    print "Content-Type: application/octet-stream\r\n\r\n";
  } else {
    print "Content-Type: text/plain\r\n\r\n";
  }

  print $self->get_item_text ($q);
  return '';
}

sub get_item_text {
  my ($self, $q) = @_;

  # read the text from the file, or from the CGI parameters for fileless
  # edits.
  my $text = '';
  if (!$self->{fileless}) {
    if (open (IN, "<".$self->{file_base}."/".$self->{filename})) {
      $text = join ('', <IN>); close IN;
      $text =~ s/\r//gs;
    }
  } else {
    $text = $q->param ('filetext');
  }

  # strip metadata from the text
  return $self->strip_wmmetas ($text);
}

# ---------------------------------------------------------------------------

sub write_preview_page
{
  my $self = shift;
  my $q = $self->{q};

  "TODO";
}

# ---------------------------------------------------------------------------

sub write_save_page
{
  local ($_);
  my $self = shift;
  my $q = $self->{q};
  my $form = '';

  if ($self->is_media($self->{filename}))
  {
    return unless $self->update_metatable ();
  } else {
    return unless $self->create_wmmetas ();
  }

  my $textfrom = $q->param ('text_from');
  my $filename;

  if (!$self->{fileless}) {
    if (!open (FILE, ">".$self->{file_base}."/".$self->{filename})) {
      $self->warn ("cannot write to {WMROOT}/".$self->{filename}."!");
      goto failed;
    }
  }

  $_ = undef;
  if ($q->param('upload')) {
    my $infile = $q->upload ("upload_file");
    if (!defined $infile) {
      $self->warn ("Incomplete upload, didn't receive the new text!");
      goto failed;
    }

    if (!$self->{fileless} && $self->is_media($self->{filename})) {
      binmode FILE;
      my $bytesread;
      while ($bytesread=read($infile,$_,1024)) { print FILE $_; }

    } else {
      $_ = join ('', <$infile>);
    }

  } elsif ($textfrom eq 'Load from URL') {
    my $url = $q->param ('upload_url');
    $self->warn ("TODO: load from url");

  } else {
    $_ = $q->param ('upload_text');
  }

  if ($self->{fileless}) {
    return $self->handle_fileless_save ($q, $self->{wmmetas}.$_);

  } elsif (!$self->is_media ($self->{filename})) {
    s/\r//gs;			# clean MS-DOSisms
    print FILE $self->{wmmetas}.$_;

    if (!close FILE) {
      $self->warn ("cannot write to {WMROOT}/".$self->{filename}."!");
      goto failed;
    }

    if ($self->{cvs_supported} && !$self->{cvs}->file_in_cvs ($self->{filename}))
    {
      $self->cvs_add ($self->{filename});
      $form .= qq{
	<p>
	(Added "$self->{filename}" to the list of files to be added
	at the next CVS commit.)
	</p>
      };#"
    }
  }

  # TODO -- handle link_text

failed:
  my $dirurl = $self->mydirname();

  if ($self->{msgs} ne '') {
    $form .= qq{ <p>

	Some errors were encountered.  Either go back and re-edit to fix them,
	or abandon the changes that could not be committed and return to <a
	href="__REINVOKE__dir=${dirurl}__">the directory listing</a>.

    </p> }; #"

  } else {
    $form .= qq{ <p>

	Your changes have been submitted.  Thanks!  Now return to <a
	href="__REINVOKE__dir=${dirurl}__">the directory listing</a>.

    </p> }; #"
  }

  $form;
}

###########################################################################

sub create_wmmetas {
  my ($self) = @_;
  my $q = $self->{q};

  $self->{wmmetas} = '';

  foreach my $name ($q->param()) {
    next unless ($name =~ /^m_(\S+)/);
    my $metaname = $1; $metaname =~ s/\"/_/gs;

    my $val = $q->param ($name);
    next if ($val =~ /^\s*$/);
    $val =~ s/<(\/\s*wmmeta\s*>)/\&lt;$1/gs; # escape end-of-metadata tags

    $self->{wmmetas} .= "<wmmeta name=\"$metaname\">$val</wmmeta>\n";
  }

  1;
}

sub strip_wmmetas {
  my ($self, $t) = @_;

  $t =~ s/\s*<wmmeta\s*name=\"([^\"]+)\"\s*>(.*?)<\/\s*wmmeta\s*>\s*/
  	$self->_strip_wmmeta_item ($1, $2); /gies;

  $t =~ s/\s*<wmmeta\s*name=([^\s>]+)\s*>(.*?)<\/\s*wmmeta\s*>\s*/
  	$self->_strip_wmmeta_item ($1, $2); /gies;

  $t =~ s/\s*<wmmeta\s*name=\"?([^\">]+?)\"?\s+value=\"?([^\">]+?)\"?\s*\/>\s*/
  	$self->_strip_wmmeta_item ($1, $2); /gies;

  $t;
}

sub _strip_wmmeta_item {
  my ($self, $name, $val) = @_;
  $name =~ tr!A-Z!a-z!;
  $self->{read_metas}->{$name} = $val;
  return '';
}

sub update_metatable {
  my ($self) = @_;
  my $q = $self->{q};
  if (!$self->{metatable}->lock_metatable_file ($self->{file_base})) {
    $self->warn ("failed to lock metadata table: ".
    	"someone else may be updating content here, in which case try again".
	"later -- or you may not have write permissions to the filesystem.");
    return 0;		# TODO
  }

  my $res = $self->rewrite_metatable ($q);
  $self->{metatable}->unlock_metatable_file ($self->{file_base});

  if (!$res) {
    $self->warn ("write/unlink/rename of metadata table failed!");
    return 0;
  }
  1;
}

sub rewrite_metatable {
  my ($self, $q) = @_;

  my $tbl = $self->{metatable}->read_metatable_file ($self->{file_base});

  my $fname = $self->{filename};
  if (!defined $tbl->{$fname}) { $tbl->{$fname} = { }; }

  foreach my $name ($q->param()) {
    next unless ($name =~ /^m_(\S+)/);
    my $metaname = $1; $metaname =~ s/\"/_/gs;

    my $val = $q->param ($name);
    next if ($val =~ /^\s*$/);
    $val =~ s/<(\/\s*meta\s*>)/\&lt;$1/gs; # escape end-of-metadata tags

    $tbl->{$fname}->{$metaname} = $val;
  }

  $self->{metatable}->rewrite_metatable_file ($self->{file_base});
}

###########################################################################

sub handle_fileless_save {
  my ($self, $q, $newtext) = @_;

  my $form;
  my $wmkf = $q->param ('wmkf');
  $q->param ('f', $wmkf);

  my $handler = new HTML::WebMake::CGI::Site($q);
  $handler->set_file_base ($self->{file_base});
  $form = $handler->modify_text_item ($newtext);
  $self->{msgs} .= $handler->{msgs};

  if ($self->{msgs} ne '') {
    $form = qq{ <p>

	Some errors were encountered.  Either go back and re-edit to fix them,
	or abandon the changes that could not be committed and return to <a
	href="__REINVOKE__site=1__">the WebMake file</a>.

    </p> }; #"

  } else {
    $form = qq{ <p>

	Your changes have been submitted.  Thanks!  Now return to <a
	href="__REINVOKE__site=1__">the WebMake file</a>.

    </p> }; #"
  }

  $form;
}

###########################################################################

1;
