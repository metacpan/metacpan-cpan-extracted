
package HTML::WebMake::CGI::FindWmkf;

use strict;
use File::Find;
use locale;
use HTML::WebMake::CGI::CGIBase;

use vars	qw{
  	@ISA $HTML @FOUND
};

@ISA = qw(HTML::WebMake::CGI::CGIBase);

###########################################################################

$HTML = q{

<html><head>
<title>Webmake: Choose Site</title>
</head>
<body bgcolor="#ffffff" text="#000000" link="#3300cc" vlink="#660066">

<h1>WebMake: Choose Site</h1><hr />

__ERRORS__

__FORM__
};

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new (@_);
  $self->{html} = $HTML;

  $self->{no_wmkf_needed} = 1;
  $self->{no_filename_needed} = 1;

  bless ($self, $class);
  $self;
}

###########################################################################

sub subrun {
  my $self = shift;
  my $q = $self->{q};

  $self->write_find_page ();
}

sub wanted {
  return unless (/\.wmk$/i);
  push (@FOUND, $File::Find::name);
}

sub write_find_page
{
  my $self = shift;
  my $q = $self->{q};

  my $form = qq{
    <ul>
  };

  my $filebase = $self->{file_base};

  # argh, File::Find needs this temporary global var
  @FOUND = ();
  find (\&wanted, $filebase);
  my @files = sort @FOUND; @FOUND = ();

  foreach my $file (@files) {
    $file =~ s/^.{0,3}\Q${filebase}\E\/?//gs;

    my $partpath = HTML::WebMake::CGI::Lib::mksafepath ($file);
    my $path = $self->{file_base}."/".$partpath;
    {
      $form .= qq{ <li>Site: };
      $form .= qq{
	<strong>$file</strong>
	<a href="__REINVOKE__wmkf=${partpath}\&site=1__">[Edit]</a>
      };#"
      $form .= qq{ </li> };
    }
  }

  $form .= q( </ul> <hr /> );

  $form;
}

###########################################################################

1;
