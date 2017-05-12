
package HTML::WebMake::CGI::Dir;

use strict;
use HTML::WebMake::CGI::CGIBase;

use vars	qw{
  	@ISA $HTML
};

@ISA = qw(HTML::WebMake::CGI::CGIBase);

###########################################################################

$HTML = q{

<html><head>
<title>Webmake: Edit Directory</title>
</head>
<body bgcolor="#ffffff" text="#000000" link="#3300cc" vlink="#660066">

<h1>WebMake: Edit Directory</h1><hr />

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

  my $dir = HTML::WebMake::CGI::Lib::mksafepath ($q->param('dir'));
  $self->{dir} = $dir;
  $self->write_list_page ();
}

sub write_list_page
{
  my $self = shift;
  my $q = $self->{q};

  my $form = '';
  # $form = $q->startform();

  if (!defined ($self->{dir})) {
    $self->{dir} = '.';
    # $self->warn ("No directory defined."); return '';
  }

  $form .= "
    <p>Files in <strong>$self->{dir}</strong>:</p>
    <ul>
  ";

  if (!opendir (DIR, $self->{file_base}."/".$self->{dir})) {
    $self->warn ("can't opendir {WMROOT}/$self->{dir}: $!");
  }
  my @files = sort readdir (DIR);
  closedir DIR;

  foreach my $file (@files) {
    my $partpath = $self->makepath ($self->{dir}, $file);
    my $path = $self->{file_base}."/".$partpath;

    if ($file eq '.') { next; }
    if ($file eq '..') { $file = 'Up to higher level directory'; }

    if (-d $path) {
      $form .= qq{
	<li>Dir: <strong>$file</strong>
	<a href="__REINVOKE__dir=${partpath}__">[Go]</a>
	</li>
      };#"

    } else {
      $form .= qq{ <li>File: };

      if ($path =~ /${HTML::WebMake::CGI::RWMetaTable::METATABLEFNAME}$/) {
	$form .= qq{
	  <em>$file</em> (used by WebMake for metadata storage)
	  <a href="__REINVOKE__edit=1\&f=${partpath}__">[Edit XML As Text]</a>
	};#"

      } elsif ($path =~ /\.wmk$/i) {
	$form .= qq{
	  <strong>$file</strong>
	  <a href="__REINVOKE__site=1\&wmkf=${partpath}__">[Edit WebMake file]</a>
	};#"

      } else {
	$form .= qq{
	  <strong>$file</strong>
	  <a href="__REINVOKE__edit=1\&f=${partpath}__">[Edit]</a>
	};#"
      }

      # if (!$self->{cvs}->file_in_cvs ($path)) {
      # provide a way to add it? TODO
      # }

      $form .= qq{ <a href="__REINVOKE__del=1\&f=${partpath}__">[Delete]</a> };
      #"
      $form .= qq{ </li> };
    }
  }

  $form .= q( </ul> <hr /> );

  $form .= $q->startform(-method => 'GET')
	  . $q->p ("Create New File:  "
            . $q->hidden (-name=>'edit', -value=>'1')
            . $q->hidden (-name=>'dirprefix', -value=>$self->{dir})
	    . $q->textfield (-name => 'f', -default => '')
	    . $self->std_cgi_hidden_items ($q)
	    ." "
	    . $q->submit (-name=>'Create', -value=>'Create')
	  )
	  . $q->endform();

  $form .= q{
    (Both text and image files can be created this way. They
    will be differentiated by their file extension.)
  };

  $form;
}

###########################################################################

1;
