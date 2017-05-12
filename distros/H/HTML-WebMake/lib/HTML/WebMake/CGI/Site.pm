
package HTML::WebMake::CGI::Site;

use strict;
use HTML::WebMake::CGI::CGIBase;
use HTML::WebMake::CGI::CVS;
use HTML::WebMake::Main;
use File::Basename;

use vars	qw{
  	@ISA $HTML $POST_BUILD_HTML
};

@ISA = qw(HTML::WebMake::CGI::CGIBase);

###########################################################################

$HTML = q{

<html><head>
<title>Webmake: Edit Site ("__FNAME__")</title>
</head>
<body bgcolor="#ffffff" text="#000000" link="#3300cc" vlink="#660066">

<h1>WebMake: Edit Site ("__FNAME__")</h1><hr />

__ERRORS__

__FORM__
};

$POST_BUILD_HTML = q{
__ERRORS__

__FORM__
};

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new (@_);
  $self->{html} = $HTML;

  $self->{no_filename_needed} = 1;

  bless ($self, $class);
  $self;
}

###########################################################################

sub subrun {
  my $self = shift;
  my $q = $self->{q};

  $self->{filename} = $self->{wmkfile};
  if ($q->param ('Commit')) {
    $self->write_commit_page ();
  } elsif ($q->param ('Update')) {
    $self->write_update_page ();
  } elsif ($q->param ('build')) {
    $self->write_build_page ();
  } else {
    $self->write_list_page ();
  }
}

sub read_wmk_file
{
  my ($self, $file) = @_;

  my $dir = $self->mydirname();
  $self->{webmake} = new HTML::WebMake::Main ( {
    	'base_dir'	=> $self->{file_base}.'/'.$dir
    } );

  my $cgi = $self->{webmake}->cgi_parse_file
				($self->{file_base}.'/'.$file);

  if (!defined $cgi) {
    $self->warn ("Failed to parse WebMake file \"$file\"");
    return 0;
  }

  $self->{fulltext} = $cgi->{fulltext};
  $self->{items} = $cgi->{items};

  1;
}

sub write_list_page
{
  my $self = shift;
  my $q = $self->{q};

  return '' unless $self->read_wmk_file ($self->{wmkfile});
  my $dir = File::Basename::dirname ($self->{wmkfile});

  my $form = qq{
    <table>
  };
  my $wmkf = $self->{wmkfile};
  my $path;

  foreach my $item (@{$self->{items}}) {
    $form .= qq{
	<tr><td valign=top width=80%>
	<strong>$item->{name}</strong>
    };

    $form .= q{ <ul> };
    foreach my $attr (sort keys %{$item->{attrs}}) {
      next if ($attr eq 'name');
      my $val = $item->{attrs}->{$attr};
      $form .= qq{
	  <li>
	  $attr = $val
	  </li>
      };
    }
    $form .= q{ </ul> };

    # my $re = $item->{origtagregexp}; $re =~ s/</&lt;/gs; $form .= $re;

    $form .= qq{ </td><td width=20%> };

    my $editui = $item->{editui};
    my $data = $item->{edituidata};
    if ($editui == $HTML::WebMake::WmkFile::CGI_EDIT_AS_DIR)
    {
      $path = $self->makepath ($dir, $data);
      $form .= qq{ <a href="__REINVOKE__wmkf=${wmkf}\&dir=${path}__">[Browse Source Dir]</a> }; #"
    }
    elsif ($editui == $HTML::WebMake::WmkFile::CGI_EDIT_AS_WMKFILE)
    {
      $path = $self->makepath ($dir, $data);
      $form .= qq{ <a href="__REINVOKE__wmkf=${path}\&site=1__">[Edit]</a> }; #"
    }
    elsif ($editui == $HTML::WebMake::WmkFile::CGI_EDIT_AS_TEXT)
    {
      my $id = $item->{id};
      my $name = $q->escape ($item->{name});
      my $nametext = $item->{name}; $nametext =~ s/[\"\']//gs;

      # use a form here, because we may need to pass in the entire text
      # of the data item.  (I prefer links like the [Browse] items above
      # as they're bookmarkable)
      $form .= $q->startform()
	    . $q->submit (-name=>'Edit',-value=>'Edit')
	    . $q->hidden (-name=>'edit', -value=>'1')
	    . $q->hidden (-name=>'fileless', -value=>'1')
	    . $q->hidden (-name=>'filetext', -value=>$data)
	    . $q->hidden (-name=>'saveasid', -value=>$item->{id})
	    . $q->hidden (-name=>'f', -value=>$nametext)
            . $self->std_cgi_hidden_items ($q)
	    . $q->endform();
    }
    elsif ($editui == $HTML::WebMake::WmkFile::CGI_NON_EDITABLE)
    {
      $form .= qq{ <em>[Not editable]</em> };
    }

    $form .= qq{
	</td></tr>
    };
  }

  $path = $self->{wmkfile};
  $form .= qq{
    </table>
    <p>
    <a href="__REINVOKE__wmkf=${wmkf}\&edit=1\&f=${path}__">[Edit This File As Text]</a>
    </p>
  };#"
  $form;
}

###########################################################################

sub modify_text_item {
  my ($self, $newtext) = @_;
  my $q = $self->{q};

  $self->{wmkfile} = $q->param ('wmkf');

  if (!$self->read_wmk_file ($self->{wmkfile})) {
    return "Could not read WebMake file \"$self->{wmkfile}\".";
  }

  my $id = $q->param ('saveasid');
  my $gotit = undef;

  foreach my $item (@{$self->{items}}) {
    next unless ($item->{id} eq $id);

    my $tag = $item->{tag};
    my $block = "<".$tag;
    foreach my $attr (sort keys %{$item->{attrs}}) {
      $block .= " ".$attr."=\"".$item->{attrs}->{$attr}."\"";
    }
    $block .= ">".$newtext."</".$tag.">";

    $self->{fulltext} =~ s/$item->{origtagregexp}/${block}/gs;
    $gotit = $item->{name};

    my $endf = $self->{file_base}."/".$self->{wmkfile};
    my $newf = $endf.".new";
    my $bakf = $endf.".bak";
    if (!open (FILE, ">".$newf)) {
      $self->warn ("cannot write to {WMROOT}/".$self->{wmkfile}.".new!");
      goto failed;
    }
    print FILE $self->{fulltext};
    if (!close FILE) {
      $self->warn ("cannot write to {WMROOT}/".$self->{wmkfile}.".new!");
      unlink $newf;
      goto failed;
    }

    rename ($endf, $bakf) or
	      $self->warn ("failed to rename old {WMROOT}/".$self->{wmkfile});
    rename ($newf, $endf) or
	      $self->warn ("failed to rename to {WMROOT}/".$self->{wmkfile});

    if ($self->{cvs_supported} && !$self->{cvs}->file_in_cvs ($endf)) {
      $self->cvs_add ($endf);
    } 
  }

  if ($gotit) {
    return "Modified $gotit successfully.";
  } else {
    return "Could not find that item in this file!";
  }

failed:
  return "Failed to modify $gotit!";
}

###########################################################################

sub write_build_page
{
  my $self = shift;
  my $q = $self->{q};
  my $form;

  my $file = $self->{wmkfile};
  my $dir = $self->mydirname();

  chdir ($self->{file_base}.'/'.$dir);
  return '' unless $self->read_wmk_file ($file);

  # hack: because WebMake uses stdout, print the std template here first,
  # then change the template.
  $self->write_html_main("");
  $self->{html} = $POST_BUILD_HTML;

  chdir ($self->{file_base}.'/'.$dir);
  my $opts = {
    'html_logging' => 1
  };

  if ($q->param ('full')) {
    $opts->{'force_output'} = 1;
  }

  # make webmake issue warnings into the HTML
  local $SIG{__WARN__} = sub {
    $self->warn ($self->txt2html (@_));
  };

  eval {
    $self->{webmake} = new HTML::WebMake::Main ($opts);
    $self->{webmake}->setcachefile ("/tmp/webmake_cache/%u/%F");
    $self->{webmake}->readfile ($file);
    $self->{webmake}->make ();
  };

  if ($self->{webmake}->finish() == 0) {
    $form .= qq{
      <p>
      Built the site successfully.
      </p>

      <ul>
      <li>
      <a href="__REINVOKE__Commit=1__">Check in</a> the changes you've made
      </li>

      <li>
      <a href="__REINVOKE__site=1__">Carry on editing</a> the WebMake file
      </li>
      </ul>
    }; #"

  } else {
    $form .= qq{
      <p>
      Some errors were encountered!
      </p>

      <li>
      <a href="__REINVOKE__site=1__">Re-edit</a> the WebMake file
      </li>
      </ul>
    };

  }

  $form;
}

###########################################################################

sub write_update_page {
  my $self = shift;
  my $text = $self->{cvs}->cvs_update();

  my $partpath = $self->{wmkfile};
  $text .= qq{
      <p>
      Return to the
      <a href="__REINVOKE__site=1__">WebMake file</a>.
      </p>
  };#"

  $text;
}

###########################################################################

sub write_commit_page {
  my $self = shift;
  my $text = '';

  my $q = $self->{q};
  my $cvsmsg = $q->param ('cvsmsg');

  if (!defined $cvsmsg || $cvsmsg eq '') {
    $text .= $q->startform(-method => 'GET');

    $text .= qq{
      <p>
      A message is required to perform the CVS commit.
      Please enter some text describing your changes here.
      </p>
      <textarea name=cvsmsg rows=5 columns=75>
      </textarea>
      <p>
    };

    $text .= "<p>"
    	. $q->submit(-name=>'Commit',-value=>'Commit')
    	. $q->hidden(-name=>'f',-value=>$self->{wmkfile})
	. "</p>"
    	. $self->std_cgi_hidden_items($q)
	. $q->endform();

    return $text;
  }

  $cvsmsg = HTML::WebMake::CGI::Lib::mksafe ($cvsmsg);
  $cvsmsg .= " (commit by ".$q->remote_user()." using webmake.cgi)";

  my $cvs = $self->{cvs};
  $text .= $cvs->do_cvs_deletes();
  $text .= $cvs->do_cvs_adds();
  $text .= $cvs->cvs_commit($cvsmsg);

  my $partpath = $self->{wmkfile};
  $text .= qq{
      <p>
      If the CVS commit was successful, return to the
      <a href="__REINVOKE__site=1\&cvsadd=\&cvsaddbin=\&cvsrm=\&cvsrmdir=__">
      WebMake file</a> here.
      </p>

      <p>
      If there were errors, and you wish to keep the list
      of files that need to be added and deleted, use
      <a href="__REINVOKE__site=1__">
      this link</a>.
      </p>
  };#"

  $text;
}

###########################################################################

1;
