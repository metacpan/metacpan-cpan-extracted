
package HTML::WebMake::CGI::Del;

use strict;
use HTML::WebMake::CGI::CGIBase;

use vars	qw{
  	@ISA $HTML
};

@ISA = qw(HTML::WebMake::CGI::CGIBase);

###########################################################################

$HTML = q{

<html><head>
<title>WebMake: Delete File "__FNAME__"</title>
</head>
<body bgcolor="#ffffff" text="#000000" link="#3300cc" vlink="#665066">

<h1>WebMake: Delete File "__FNAME__"</h1><hr />

__ERRORS__

__FORM__
};

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new (@_);
  $self->{html} = $HTML;
  bless ($self, $class);
  $self;
}

###########################################################################

sub subrun {
  my ($self, $q) = @_;
  my $form;

  if ($q->param ('Yes')) {
    $form = $self->write_yes_page ();
  } elsif ($q->param ('No')) {
    $form = $self->write_no_page ();
  } else {
    $form = $self->write_del_page ();
  }

  $form;
}


sub write_del_page
{
  my $self = shift;
  my $q = $self->{q};

  my $form = $q->startform();
  $form .= q{

	<p>
	Are you sure you wish to delete this file?
	</p>

  };

  $form .= $q->submit(-name=>'Yes',-value=>'Yes')
      . $q->submit(-name=>'No',-value=>'No')
      . $q->hidden(-name=>'del',-value=>'1')
      . $q->hidden(-name=>'f',-value=>$self->{filename})
      . $self->std_cgi_hidden_items ($q)
      . $q->endform();

  $form;
}

# ---------------------------------------------------------------------------

sub write_yes_page
{
  my ($self) = @_;
  my $q = $self->{q};
  local ($_);

  if (!unlink ($self->{file_base}."/".$self->{filename})) {
    $self->warn ("Failed to delete file \"".$self->{filename}."\": $!");
    goto failed;
  }

  if ($self->{cvs_supported}) {
    $self->cvs_delete ($self->{filename});
  }

  if (-f $self->{metatable}->get_metatable_filename ($self->{file_base})) {
    if (!$self->{metatable}->lock_metatable_file ($self->{file_base})) {
      $self->warn ("failed to lock metadata table, ".
	  "may be read only or someone else may be updating content here. ".
	  "Try again later.");
      goto failed;
    }

    my $res = $self->rewrite_metatable ($q);
    $self->{metatable}->unlock_metatable_file ($self->{file_base});

    if (!$res) {
      $self->warn ("write/unlink/rename of metadata table failed!");
      goto failed;
    }
  }

failed:

  my $dirurl = $self->mydirname ();
  my $form;
  if ($self->{msgs} ne '') {
    $form = qq{ <p>

	Some errors were encountered.  Return to <a
	href="__REINVOKE__dir=${dirurl}__">the directory listing</a>.

    </p> }; #"

  } else {
    $form = qq{ <p>

	The file has been deleted.  Now return to <a
	href="__REINVOKE__dir=${dirurl}__">the directory listing</a>.

    </p> }; #"
  }

  $form;
}

sub write_no_page
{
  my $self = shift;
  my $dirurl = $self->mydirname ();
  qq{ <p>

	Keeping this file.  Now return to <a
	href="__REINVOKE__dir=${dirurl}__">the directory listing</a>.

  </p> }; #"
}

###########################################################################

sub rewrite_metatable {
  my ($self, $q) = @_;

  my $tbl = $self->{metatable}->read_metatable_file ($self->{file_base});

  my $fname = $self->{filename};
  delete $tbl->{fname};

  $self->{metatable}->rewrite_metatable_file ($self->{file_base});
}

###########################################################################

1;
