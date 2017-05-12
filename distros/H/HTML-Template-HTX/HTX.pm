package HTML::Template::HTX;

$VERSION = '0.07';


# FOR PERL VERSIONS PRIOR TO 5.6
#
# The next two lines should be disabled for Perl versions prior to 5.6. As
# far as I know there is no (simple) way to do this automatically at compile
# time, so you will have to do it yourself.
require 5.006;
use utf8;


=head1 NAME

HTML::Template::HTX - Handle HTML Extension template (F<.htx>) files

=head1 SYNOPSIS

  use HTML::Template::HTX;

  $htx = HTML::Template::HTX->new('template.htx') or die "Oops!";

  $htx->param('counter' => 0);
  $htx->print_header(1);

  foreach(qw(I used to care but Things Have Changed)) {
    $htx->param(
      'counter' => $htx->param('counter')+1,
      'Name'    => $_,
    );
    $htx->print_detail;
  }

  $htx->print_footer;
  $htx->close;

=head2 template.htx

  <HTML><HEAD><TITLE>Sample results</TITLE>

  </HEAD><BODY>

   <H2>Sample results:</H2>

  <%begindetail%>
   <%counter%>. <%Name%><BR>
  <%enddetail%>

  </BODY></HTML>

=head1 ABSTRACT

Reads and outputs HTML Extension template (F<.htx>) files, which enable you
to seperate your Perl code from HTML code.

The F<.htx> file format was originally used by Microsoft's Index Server and
their Internet Database Connector, but may be useful for any server side
program that outputs HTML (or even some other ASCII file format), and
especially for scripts generating sequential data, such as search engines.

Note that this module and its template format are not directly related nor
compatible with the popular HTML::Template module.

=cut


use strict;
#use warnings; # Enable warnings only during development

use FileHandle;
use HTML::Entities qw(encode_entities);
use URI::Escape qw(uri_escape);


=head1 DESCRIPTION

To use a F<.htx> template file in your Perl script, basically follow these
steps:

=over 4

=item 1

Create a L<new> HTML::Template::HTX object.

=item 2

Optionally define some L<parameters|param>, and output the
L<header|print_header> of the template.

=item 3

Optionally change or define some L<parameters|param>, and output the
L<detail section|print_detail>. This step is optionally repeated a number of
times, depending on the data you're processing.

=item 4

Optionally change or define some L<parameters|param>, and output the
L<footer|print_footer> of the template.

=item 5

L<Close|close> the template file, or destroy the HTML::Template::HTX object.

=back

If you don't have any repeated data, then you can skip steps 2 and 3, and
just use C<print_footer> to output the whole template file at once. If you
have multiple sets of repeated data, then you should probably follow a
slightly altered schema (see the C<detail_section> method).

=head2 Basic methods

=over 4

=item C<$htx = HTML::Template::HTX-E<gt>new($template,> [C<$output>]C<,>
[C<-utf8>]C<,> [I<common parameters>]C<)>

=item C<$htx = HTML::Template::HTX-E<gt>new(template =E<gt> $template,>
[C<output =E<gt> $output>]C<,> [C<-utf8>]C<,> [I<common parameters>]C<)>

Opens the specified F<.htx> template file. If an open file handle is
specified instead of a file name, then the template is read from this file
handle. If a scalar reference is specified, then the contents of the scalar
will be used as the template.

If no output file is specified, then the STDOUT is used for output. If an
open file handle is specified, then this file handle is used for output. If
a scalar reference is specified instead of an output file, then all output
will be B<appended> to the specified scalar.

By default UTF-8 coding will be disabled, but you can specify C<-utf8> to
enable it. For more on UTF-8 coding and this module see the C<utf8> method.

When any common parameters are specified, certain frequently used parameters
are automatically defined and maintained. For more information see the
C<common_params> method.

When using the named parameters interface, you can also use
C<filename =E<gt> $template> instead of C<template =E<gt> $template> (for
backward compatibility).

=cut

sub new {
  my $class = shift;
  my $self = {};

  # Parse the arguments.
  my($template_file, $output_file, $utf8, @common, $arg);
  while(@_) {
    $arg = shift;
    if($arg =~ /^(template|filename)$/o) {
      $template_file = shift;
    } elsif($arg eq 'output') {
      $output_file = shift;
    } elsif($arg eq '-utf8') {
      $utf8 = 1;
    } elsif($arg =~ /^-/o) {
      push @common, $arg, @_;
      last;
    } elsif(!defined($template_file)) {
      $template_file = $arg;
    } elsif(!defined($output_file)) {
      $output_file = $arg;
    }
  }
  return undef unless(defined($template_file));
  $output_file = '-' unless(defined($output_file));

  # Open the .htx file.
  my($file, $close_file);
  if(!ref($template_file)) {
    $file = new FileHandle "<$template_file";
    return undef unless(defined($file));
    $close_file = 1;
  } else {
    $file = $template_file;
    $close_file = '';
  }
  # Disable UTF-8 coding for Perl 5.8+.
  binmode($file, ':bytes') if(($] >= 5.008) and (ref($file) ne 'SCALAR'));

  # Open the file used for output (usually STDOUT).
  my($output, $close_output);
  if(!ref($output_file)) {
    $output = new FileHandle ">$output_file";
    if(!defined($output)) {
      CORE::close($file);
      return undef;
    }
    $close_output = 1;
  } else {
    $$output_file = '' if((ref($output_file) eq 'SCALAR') and (!defined($$output_file)));
    $output = $output_file;
    $close_output = '';
  }
  # Disable UTF-8 coding for Perl 5.8+.
  binmode($output, ':bytes') if(($] >= 5.008) and (ref($output) ne 'SCALAR'));

  # Save and initialize some values for later.
  $self->{_file} = $file;
  $self->{_close_file} = $close_file;
  $self->{_output} = $output;
  $self->{_close_output} = $close_output;
  $self->{_closed} = '';
  $self->{_section} = '';
  $self->{_detail} = undef;
  $self->{_rest} = undef;
  $self->{_condition} = 1;
  $self->{_if_count} = 0;
  $self->{_utf8} = $utf8 ? 1 : '';
  $self->{_stats} = '';
  $self->{_param} = {};

  # Bless me, father.
  bless $self, $class;

  # Optionally init the common parameters.
  $self->common_params(@common) if(@common);

  return $self;
}


=item C<$htx-E<gt>param($name =E<gt> $value,>
[C<$name =E<gt> $value>...]C<)>

=item C<$value = $htx-E<gt>param($name)>

=item C<@names = $htx-E<gt>param()>

Sets or retrieves a user defined variable, or a list of variables. If one or
more name and value pairs are specified, then these variables will be set to
the specified values.

If only one argument is specified, than the value of that variable is
returned. Without arguments the C<param> method returns a list of names of
all defined variables.

I<See also L<The .htx file format|"THE .HTX FILE FORMAT">, and the>
I<C<common_params> method.>

=cut

sub param {
  # If there are no arguments, then return a list of variable names.
  return (keys %{$_[0]->{_param}}) if($#_ == 0);

  # If there's only one argument, then return the value of that variable.
  return $_[0]->{_param}{$_[1]} if($#_ == 1);

  # If there's two arguments, then one name/value pair is specified.
  if($#_ == 2) {
    $_[0]->{_param}{$_[1]} = $_[2];
    return;
  }

  # Apparently two or more name/value pairs are specified.
  my $n = 1;
  while($n <= $#_) {
    # Set the variable to the specified value.
    $_[0]->{_param}{$_[$n]} = $_[$n+1];
    $n += 2;
  }
}


=item C<$htx-E<gt>print_header(>[C<$http_header>] [C<-nph>]C<)>

Reads, parses and outputs the template file up to
C<E<lt>%begindetail%E<gt>>, and only reads what's between
C<E<lt>%begindetail%E<gt>> and C<E<lt>%enddetail%E<gt>>, but does not parse
and output this section yet. If no C<E<lt>%begindetail%E<gt>> was found,
then simply reads, parses and outputs the entire file. In this last case
C<print_header> returns a false value, else it returns a true value. If a
section name was specified inside the template file, then this true value is
actually the specified section name. This make life very easy for F<.htx>
files with multiple detail sections (see also the C<detail_section> method).

If this is the very first call to C<print_header> and only a content type is
specified in C<$http_header> (usually this should be C<'text/html'>), then
the following simplified HTTP header is printed before anything else:

    Content-Type: $http_header

If C<$http_header> is not a valid content type (i.e. there's no '/' in it)
but its value is true, then the default content type of C<'text/html'> is
used. This is very useful, because you can thus simply do
C<$htx-E<gt>print_header(1)> to get a valid HTTP header with the
C<'text/html'> content type. If you don't want any header, then simply do a
C<print_header> with a false value, e.g. C<$htx-E<gt>print_header('')> (or
even just C<$htx-E<gt>print_header>).

If a full HTTP header is specified in C<$http_header> (i.e. if
C<$http_header> contains one or more "\n" characters), then that header
printed before anything else. Beware that a valid HTTP header should include
a trailing empty line.

The C<-nph> option is ignored, but still included for backward(s) ;-)
compatibility. If you need to print a full HTTP header, you could simply
pass the C<header> function of the CGI module, e.g.
C<$htx-E<gt>print_header(header(-nph =E<gt> 1))>.

=cut

sub print_header {
  my $self = $_[0];
  local $_;

  # Is this the first ever call to print_header?
  my $first_time;
  if(!defined($self->{_rest})) {
    $first_time = 1;
    # Output the specified HTTP header.
    if(defined($_[1]) and ($_[1] =~ /\n/o)) {
      _print($self, \$_[1]);
    # Construct and output a (partial) HTTP header.
    } elsif($_[1]) {
      my $content_type = $_[1];
      if($content_type !~ m#/#o) {
        $content_type = 'text/html';
        $content_type .= '; charset=utf-8' if($self->{_utf8});
      }
      $content_type = "Content-Type: $content_type\n\n";
      _print($self, \$content_type);
    }
    $self->{_rest} = '';
  } else {
    $first_time = '';
  }

  # Optionally update the automated counters (NUMBER).
  _stats($self, -1) if((!$first_time) and $self->{_stats});

  # Read, parse and output everything up to <%begindetail%>.
  $self->{_section} = '';
  my $found;
  my $file = $self->{_file};
  my $is_scalar = ref($file) eq 'SCALAR';
  # Start with whatever is left of that which followed <%enddetail%> last
  # time.
  if($self->{_rest} ne '') {
    $_ = $self->{_rest};
    $self->{_rest} = '';
  } elsif(!$is_scalar) {
    $_ = <$file>;
  } else {
    $_ = $first_time ? $$file : undef;
  }
  while(defined($_)) {
    # Check for <%begindetail%>.
    if($found = /<%begindetail%>/io) {
      # Output and parse only that which came before <%begindetail%>.
      _print($self, $`) if($` ne '');
      # Start the detail section with whatever followed <%begindetail%>.
      $self->{_rest} = $';
      last;
    } else {
      # Simply parse and output the entire line.
      _print($self, $_);
    }
    # Next, please!
    last if($is_scalar);
    $_ = <$file>;
  }
  $found or return '';

  # Optionally init the automated counters (NUMBER and COUNT).
  _stats($self, 0, 0) if($self->{_stats});

  # Read and store everything between <%begindetail%> and <%enddetail%>.
  $self->{_detail} = '';
  # Start with the remainder of the last line that was read...
  if($self->{_rest} ne '') {
    $_ = $self->{_rest};
    $self->{_rest} = '';
  # ... or read a line.
  } else {
    $_ = $is_scalar ? undef : <$file>;
  }
  while(defined($_)) {
    # Check for <%enddetail%>.
    if($found = /<%enddetail%>/io) {
      # Store only that which came before <%enddetail%>.
      $self->{_detail} .= $` if($` ne '');
      # Save whatever followed <%enddetail%> for later.
      $self->{_rest} = $';
      last;
    } else {
      # Simply store the entire line.
      $self->{_detail} .= $_;
    }
    # Next, please!
    last if($is_scalar);
    $_ = <$file>;
  }

  # Return whether a (valid) detail section was found.
  return '' unless($found);
  $found = $self->{_section};;
  $found = 1 unless($found);
  return $found;
}


=item C<$htx-E<gt>print_detail>

Parses and outputs the detail section that was read by the C<print_header>
method. The method C<print_detail> method is usually called from a loop to
output each subsequent record.

=cut

sub print_detail {
  # Optionally update the automated counters (COUNT and TOTAL).
  _stats($_[0], undef, 1, 1) if($_[0]->{_stats});

  # Parse and output the detail section.
  if(_print($_[0], $_[0]->{_detail})) {
    _stats($_[0], 1) if($_[0]->{_stats}); # (NUMBER)
  }
}


=item C<$htx-E<gt>print_footer(>[C<$http_header>] [C<-nph>]C<)>

Reads, parses and outputs the rest of the template file, skipping any
C<E<lt>%begindetail%E<gt>>..C<E<lt>%enddetail%E<gt>> sections it might
encounter. For the optional arguments, see the C<print_header> method.

A script that uses a template file without a detail section could call this
method immediately after C<HTML::Template::HTX-E<gt>new> (without calling
C<print_header>). This is because this method actually does subsequent calls
to the C<print_header> method until the end of the file is reached.

=cut

sub print_footer {
  my $self = shift;
  while($self->print_header(@_)) {}
  return '';
}


=item C<$htx-E<gt>close>

Closes the template and output files. This is usually done directly after
the C<print_footer> method. When a HTML::Template::HTX object is destroyed
the files will be closed automatically, so you don't I<need> to call
C<close> (but I think it's very rude not to call C<close>!). ;-)

=cut

sub close {
  my $self = $_[0];

  # Close the file used for output.
  my($closed_output, $output);
  $output = $self->{_output};
  if(defined($output) and $self->{_close_output}) {
    $closed_output = CORE::close($output);
  } else {
    $closed_output = 1;
  }

  # Close the .htx template file.
  my($closed_file, $file);
  $file = $self->{_file};
  if(defined($file) and $self->{_close_file}) {
    $closed_file = CORE::close($file);
  } else {
    $closed_file = 1;
  }

  return '' unless($closed_output and $closed_file);
  return $self->{_closed} = 1;
}


=back

=head2 Common parameters

Common parameters are a sets of parameters that are automatically defined
and maintained so you won't have to worry about them, but which can be used
inside a template just like any parameters you've defined yourself. You can
specify common parameters while L<creating|new> the HTML::Template::HTX
object, or you can use the C<common_params> method to define them later on.

=over 4

=item C<$htx-E<gt>common_params(>[I<options>]C<)>

Automatically defines and sets certain frequently used parameters. You can
specify one or more options, or nothing if you want to use the default set
of options (which is C<-count> and C<-date>).

The following options are currently supported:

=over 4

=item C<-count> [C<=E<gt> $enable>]

Enables or disables the use of automated counters. When called with no
argument or a true value, automated counters will be enabled. When called
with a false value, automated counters will be disabled.

The following HTX counter parameters are defined and maintained:

=over 4

=item *

C<E<lt>%COUNT%E<gt>> - The number of times C<print_detail> was called within
the current detail section.

=item *

C<E<lt>%NUMBER%E<gt>> - The number of times C<print_detail> was called within
the current detail section, I<and actually produced data> (thus not an empty
string).

=item *

C<E<lt>%TOTAL%E<gt>> - The number of times C<print_detail> was called
within I<all> detail section.

=item *

C<E<lt>%SECTION%E<gt>> - The name of the current detail section.

=back

C<E<lt>%NUMBER%E<gt>>, C<E<lt>%COUNT%E<gt>> and C<E<lt>%TOTAL%E<gt>> can be
followed by a question mark to get its value modules 2, e.g.
C<E<lt>%NUMBER?%E<gt>>.

You should always enable automated counters when L<creating|new> the
HTML::Template::HTX object or right after. You can disable them again
whenever you feel like it.

The automated counters only change when calling C<print_detail>, and
I<after> calling C<print_header>. This means you can still query them in
C<print_footer> (or the next C<print_header>, if you're using
L<multiple detail sections|detail_section>).

=item C<-date> [C<=E<gt> $epoch_time>]

Defines a set of date and time parameters for the given epoch date/time, or
the current date and time if no epoch date/time is specified.

The following HTX date and time parameters are defined and set:

=over 4

=item *

C<E<lt>%YEAR%E<gt>> - The year as a 4-digit number.

=item *

C<E<lt>%MONTH%E<gt>> - The month as a 2-digit number (01..12).

=item *

C<E<lt>%MONTH$%E<gt>> - The month as a 3-character string (in English).

=item *

C<E<lt>%DAY%E<gt>> - The day as a 2-digit number (01..31).

=item *

C<E<lt>%DATE%E<gt>> - The date ("dd mmm yyyy").

=item *

C<E<lt>%WEEKDAY%E<gt>> - The weekday as a 1-digit number (1..7; 1 = Sun, 2 =
Mon ... 7 = Sat).

=item *

C<E<lt>%WEEKDAY$%E<gt>> - The weekday as a 3-character string (in English).

=item *

C<E<lt>%HOUR%E<gt>> - The hour of the day as a 2-digit number (00..23).

=item *

C<E<lt>%MINUTE%E<gt>> - The minutes part of time time as a 2-digit number
(00..59).

=item *

C<E<lt>%TIME%E<gt>> - The time ("hh:mm").

=item *

C<E<lt>%SECOND%E<gt>> - The seconds part of time time a 2-digit number
(00..59).

=item *

C<E<lt>%TIME_ZONE%E<gt>> - The timezone (e.g. "+0100" or "GMT").

=item *

C<E<lt>%DATE_TIME%E<gt>> - The date and time (e.g. "Thu, 30 Oct 1975
17:10:00 +0100").

=back

Each of these variables is also available in GMT, e.g.
C<E<lt>%GMT_DATE_TIME%E<gt>>, C<E<lt>%GMT_TIME_ZONE%E<gt>> (which naturally
always is "GMT") etc.

=back

=cut

sub common_params {
  my $self = shift;
  @_ = (-count, -date) unless(@_);

  # Parse the options one by one.
  my($option, $arg);
  while(@_) {
    $option = shift;
    $arg = (defined($_[0]) and ($_[0] !~ /^-/o)) ? shift : undef;

    # Enable or disable the automated counters.
    if($option eq '-count') {
      $arg = 1 unless(defined($arg));
      if($arg) {
        if(!$self->{_stats}) {
          $self->{_stats} = 1;
          _stats($self, 0, 0, 0, $self->{_section});
        }
      } else {
        $self->{_stats} = '';
      }
      next;
    }

    # Set date and time variables.
    if($option eq '-date') {
      $arg = time unless(defined($arg));
      _date($self, $arg);
    }
  }

}


=back

=head2 Multiple detail sections

If you have multiple sets of repeated data which you want to pass to a
single F<.htx> template, you could simply do:

=over 4

=item 1

C<print_header> (header of 1st detail section)

=item 2

C<print_detail>C< foreach(0..>I<n>C<)> (1st detail section)

=item 3

C<print_header> (footer of 1st and header of 2nd detail section)

=item 4

C<print_detail>C< foreach(0..>I<n>C<)> (2nd detail section)

=item 5

C<print_footer> (footer of 2nd detail section)

=back

Steps 3 and 4 could be repeated a number of times before continuing to step
5, depending on the number of detail sections in both your Perl script and
your F<.htx> template.

But what if you'd change the order in which the detail sections appear
inside the template? You would also have to change the order in which the
data is processed inside your Perl script. :-( This is where the
C<detail_section> method and the C<E<lt>%detailsection >I<name>C<%E<gt>>
F<.htx> command come in. :-)

=over 4

=item C<$name = $htx-E<gt>detail_section>

=item C<$htx-E<gt>detail_section($name)>

Retrieves (or sets) the name of the current detail section. You can define a
logical name for the next detail section inside a template file (which sort
of announces the next detail section), and your Perl script that passes data
to the template can check this section name and pass the data belonging to
that specific section. This comes in handy if your template contains
multiple detail sections.

Normally you should never set the section name from your Perl script, but
rather use the C<E<lt>%detailsection >I<name>C<%E<gt>> command in your
template file. Normally you do not even have to retrieve the section name
using this method, because the C<print_header> method already returns the
current section name.

Consider this Perl example:

  $htx = HTML::Template::HTX->new('template.htx');
  ...
  while($section = $htx->print_header(1)) {
    if($section eq 'LINKS') {
      foreach(@url) {
        ...
        print_detail;
      }
      next;
    }
    if($section eq 'ADS') {
      while(<$ads>) {
        ...
        print_detail;
      }
      next;
    }
  }
  $htx->close;

And the corresponding C<template.htx> example file:

  <HTML><HEAD><TITLE>Sample results</TITLE></HEAD><BODY>

  <%detailsection ADS%>
  <%begindetail%>
   <A HREF="<%EscapeRaw URL%><IMG SRC="<%EscapeURL Image%>></A>
  <%enddetail%>

  <%detailsection LINKS%>
  <H2>Links to Perly websites</H2>
  <%begindetail%>
   <A HREF="<%EscapeRaw URL%><%URL%></A><BR>
  <%enddetail%>

  </BODY></HTML>

=cut

sub detail_section {
  # Return the current section name.
  return $_[0]->{_section} if(!defined($_[1]));

  # Set the current section name.
  $_[0]->{_section} = $_[1];
}


=back

=head2 UTF-8 support

The transparent UTF-8 support in Perl is very useful when reading data from
different sources, but it's not very useful when returning data to client
software (e.g. an internet browser) that almost certainly won't have
transparent UTP-8 support. That's why the C<utf8> method lets you control
whether your output will be UTF-8 coded or not.

=over 4

=item C<$htx-E<gt>utf8(>[C<$enable>]C<)>

Enables or disables UTF-8 coding for the output of user defined or
"environmental" :-) variables. When called with no argument (thus undef) or
a true value, UTF-8 coding will be enabled. When called with a false value,
UTF-8 coding will be disabled. For UTF-8 coding Perl 5.6 or newer is
required. You may also need versions of the HTML::Entities and URI::Escape
modules that understand UTF-8.

You should always enable or disable UTF-8 coding when L<creating|new> the
HTML::Template::HTX object or right after. You should B<never> change the
UTF-8 flag later on.

You can always use UTF-8 characters inside user defined variables,
I<regardless of the state of the UTF-8 flag>. With UTF-8 coding disabled,
all UTF-8 characters that are found inside variable values will be converted
to their 8-bit counterparts (where possible). With UTF-8 coding enabled, all
8-bit non-UTF-8 characters will be converted to their UTF-8 counterparts.

Note that enabling the UTF-8 flag will only UTF-8 code variables, not the
rest of the template file, which is parsed "as is". So when enabling UTF-8,
make sure your template is also UTF-8 coded.

=cut

sub utf8 {
  my($self, $enable) = @_;

  # Enable or disable UTF-8 encoding.
  if(defined($enable)) {
    $enable = $enable ? 1 : '';
  } else {
    $enable = 1;
  }
  return unless($self->{_utf8} ne $enable);
  $self->{_utf8} = $enable;
}


# Here ends the "documented" part of this module, and so "things should
# start to get interesting right about now"("Mississippi", Bob Dylan).

=back

=cut

use vars qw(%_operator $_is_number);

sub BEGIN {
  # The operators that can be used in an <%if%> statement, and their
  # numerical counterparts.
  %_operator = (
    'eq' => '==',
    'ne' => '!=',
    'lt' => '<',
    'le' => '<=',
    'gt' => '>',
    'ge' => '>=',
  );

  # The regular expression that matches a (simple) numerical value.
  $_is_number = '-?\d*[.]?\d*';
}


# Closes the file handles before destroying the object.

sub DESTROY {
  # Call the close method to close the template and output files.
  $_[0]->close unless($_[0]->{_closed});
}


# Reads an include file.
#
# _include($self, 'include.htx', \$htx_code_fragment, \$prematch,
#   \$postmatch) or die;

sub _include {
  my($self, $include_file, $htx, $prematch, $postmatch) = @_;

  # Open the include file.
  my $file = new FileHandle "<$include_file";
  if(defined($file)) {
    # Disable UTF-8 coding for Perl 5.8+.
    binmode($file, ':bytes') if($] >= 5.008);
    # Read and insert the entire include file at once.
    $$htx = $$prematch.join('', <$file>).$$postmatch;
    CORE::close($file);
    return 1;
  }

  # Reading the file failed, so simply remove the <%include%> tag.
  $$htx = $$prematch.$$postmatch;
  return '';
}


# Parse an expression by retrieving the value of a variable, or by leaving
# it almost unchanged if it's a literal expression (that may be unclosed by
# "").
#
# $string = _express($self, '"Text"');
# $value = _express($self, 'HtxVariableName');
# $host = _express($self, 'HTTP_HOST');
# $number = _express($self, '123.45');

sub _express {
  # Check if the expresion is enclosed by "".
  if($_[1] =~ /^"(.*)"$/o) {
    # Treat it as a literal, but remove the "".
    return $1;
  }

  # Check if the expression could be a user defined variable.
  my $value;
  if(exists $_[0]->{_param}{$_[1]}) {
    # Return the value of the variable.
    $value = $_[0]->{_param}{$_[1]};
  # Check if the expression is a (CGI) environment variable.
  } elsif(exists $ENV{$_[1]}) {
    # Return the value of the environment variable.
    $value = $ENV{$_[1]};
  }
  if(defined($value)) {
    # Make sure Perl 5.6+ does UTF-8 coding.
    if($] >= 5.006) {
      if($] < 5.008) {
        # Make sure it's UTF-8.
        $value .= "\x{A9}";
        chop($value);
        # Optionally convert UTF-8 back to octets.
        $value = pack("U0C*", unpack("U*", $value)) unless($_[0]->{_utf8});
      } else {
        # With Perl 5.8+ in :bytes mode we'll need UTF-8 code ourselves.
        utf8::encode($value) if($_[0]->{_utf8});
      }
    }
    return $value;
  }

  # Check if the expression is a numerical expression.
  if(($_[1] ne '') and ($_[1] =~ /^$_is_number$/o)) {
    # Return the numerical value.
    #no warnings 'numeric'; # Warnings are enabled only during development
    return 1*$_[1];
  }

  # None of the above, so return an empty string.
  return '';
}


# Evaluate a condition from an <%if%> statement.
#
# _evaluate($self, 'Count gt 10') and print "More than 10!";

sub _evaluate {
  local $_;

  # Break up the condition into three parts (value1, operator, value2).
  my($value1, $value2, $operator);
  $_[1] =~ /^(.+?)\s+(.+?)(\s+(.+?))?$/o or return '';
  $value1 = $1;
  $operator = lc($2);
  $value2 = $4;

  # Is this the istypeeq operator?
  if($operator eq 'istypeeq') {
    # Return true (just included for compatibility).
    return 1;
  }

  # Parse both expressions.
  my $string_compare = '';
  foreach(\$value1, \$value2) {
    if(defined($$_)) {
      $$_ = _express($_[0], $$_);
      $string_compare = 1 unless(($$_ ne '') and ($$_ =~ /^$_is_number$/o));
    } else {
      $$_ = '';
      $string_compare = 1;
    }
  }

  # Is this the isempty operator?
  if($operator eq 'isempty') {
    # Return whether the string value1 is empty.
    return $value1 eq '';
  }

  # Compare the strings case-insensitive.
  if($string_compare) {
    $value1 = lc($value1);
    $value2 = lc($value2);
  }

  # Is this the contains operator?
  if($operator eq 'contains') {
    # Return whether the string value1 contains the string value2.
    return $value1 =~ /$value2/;
  }

  # If it's not one of the comparison operators, then return false.
  return '' unless(exists $_operator{$operator});

  # Construct a Perl eval expression.
  my $eval;
  if($string_compare) {
    $value1 =~ s/'/\\'/go;
    $value2 =~ s/'/\\'/go;
    $eval = "'$value1' $operator '$value2'";
  } else {
    $eval = "$value1 $_operator{$operator} $value2";
  }
  # Let Perl evaluate the expression.
  $eval = eval($eval);
  return '' if($@);
  return $eval;
}


# Encode a variable or value using a certain encoding.
#
# _encode($self, 'SomeHtxVariable', 'html');
# _encode($self, 'SomeHtxVariable', 'url');
# _encode($self, 'SomeHtxVariable', 'js');
# _encode($self, 'SomeHtxVariable', 'scramble');
# _encode($self, 'SomeHtxVariable'); # Raw ("as is")

sub _encode {
  # Parse the expression.
  my $value = _express(@_[0, 1]);

  # Encode as HTML entities.
  my $encoding = lc($_[2]); # lc converts undef to ''
  return encode_entities($value) if($encoding eq 'html');

  # Encode using URL escape codes.
  return uri_escape($value) if($encoding eq 'url');

  # Encode for use in JavaScript strings (double-quoted).
  if($encoding eq 'js') {
    $value =~ s/[\\"]/\\$&/go; # Backslash, double quote
    $value =~ s/\x08/\\b/go;   # Backspace
    $value =~ s/\f/\\f/go;     # Form feed
    $value =~ s/\n/\\n/go;     # New line
    $value =~ s/\r/\\r/go;     # Carriage return
    $value =~ s/\t/\\t/go;     # Tab
    return $value;
  }

  # Encode and scramble for use in JavaScript strings (double-quoted).
  if($encoding eq 'scramble') {
    my($scramble, $method, $previous, $n, $c);
    $scramble = '';
    $previous = -1;
    foreach $n (0..length($value)-1) {
      # Select a method (raw, octal or hex).
      $c = substr($value, $n, 1);
      $method = -1;
      if($c =~ /^[\x00-\x1F"\\\@\x7F-\xFF]$/o) {
        $method = int(rand(2));
      } elsif($previous == 0) {
        $method = int(rand(2)) if($c =~ /^[0-9A-Za-z]$/o);
      } elsif($previous == 1) {
        $method = int(rand(2)) if($c =~ /^[0-7]$/o);
      }
      $method = int(rand(5)) if($method == -1);
      # Encode scrambled using the selected method.
      if($method == 0) {
        $scramble .= sprintf("\\x%X", ord($c));
      } elsif($method == 1) {
        $scramble .= sprintf("\\%o", ord($c));
      } else {
        $scramble .= $c;
      }
      $previous = $method;
    }
    return $scramble;
  }

  # Do not encode, instead leave the raw data in tact.
  return $value;
}


# Parse (part of) the HTML template file.
#
# _parse($self, \$htx_code_fragment);

sub _parse {
  my($self, $htx) = @_;

  # Fetch our current condition.
  my $condition = $self->{_condition};
  my $if_count = $self->{_if_count};
  my $if_offset = 0;

  # Find the next statement (between "<%" and "%>").
  my($expr, $statement, $arg);
  while($$htx =~ /<%(.+?)(\s+(.+?))?%>/os) {
    $expr = $1;
    $statement = lc($1);
    $arg = $3;

    # Are we currently processing an <%if%> that turned out false?
    if(!$condition) {
      # Cut off everything before the current statement (and also cut off
      # the statement itself).
      $$htx = substr($`, 0, $if_offset).$';
      # Is this a nested <%if%> statement?
      if($statement eq 'if') {
        $if_count++;
      # Is this an <%else%> statement?
      } elsif($statement eq 'else') {
        # Reset the current condition state to true if we're not nested.
        $condition = 1 if($if_count == 0);
      # Is this an <%endif%> statement?
      } elsif($statement eq 'endif') {
        # Reset the current condition state to true if we're not nested.
        if($if_count > 0) {
          $if_count--;
        } else {
          $condition = 1;
        }
      }

    # Is this the <%EscapeRaw%> statement?
    } elsif($statement eq 'escaperaw') {
      # Parse the expression using no encoding.
      $$htx = $`._encode($self, $arg).$';

    # Is this the <%EscapeHTML%> statement?
    } elsif($statement eq 'escapehtml') {
      # Parse the expression using HTML encoding.
      $$htx = $`._encode($self, $arg, 'html').$';

    # Is this the <%EscapeURL%> statement?
    } elsif($statement eq 'escapeurl') {
      # Parse the expression using URL encoding.
      $$htx = $`._encode($self, $arg, 'url').$';

    # Is this the <%EscapeJS%> statement?
    } elsif($statement eq 'escapejs') {
      # Parse the expression using JavaScript encoding.
      $$htx = $`._encode($self, $arg, 'js').$';

    # Is this the <%EscapeScramble%> statement?
    } elsif($statement eq 'escapescramble') {
      # Parse the expression using JavaScript encoding.
      $$htx = $`._encode($self, $arg, 'scramble').$';

    # Is this the <%include%> statement?
    } elsif($statement eq 'include') {
      # Insert the include file.
      _include($self, $arg, $htx, \$`, \$');

    # Is this the <%if%> statement?
    } elsif($statement eq 'if') {
      # Evaluate the condition.
      $condition = _evaluate($self, $arg);
      # Continue after the current statement.
_IF_:
      $$htx = $`.$';
      $if_offset = length($`);

    # Is this the <%else%> statement?
    } elsif($statement eq 'else') {
      # Set the current condition state to false.
      $condition = '';
      goto _IF_;

    # Is this the <%endif%> statement?
    } elsif($statement eq 'endif') {
      # Do the same as you would for an <%if%> that turned out true.
      goto _IF_;

    # Is this the <%detailsection%> statement?
    } elsif($statement eq 'detailsection') {
      # Set the current section name.
      $self->{_section} = $arg;
      _stats($self, undef, undef, undef, $arg) if($self->{_stats});
      $$htx = $`.$';

    # The statement was not recognized, so it must an expression.
    } else {
      # Encode the expression using HTML encoding.
      $$htx = $`._encode($self, $expr, 'html').$';
    }
  }

  # If the condition is false, then keep only everything up to the last
  # point where the condition was true.
  $$htx = substr($$htx, 0, $if_offset) if(!$condition);

  # Save some values for later.
  $self->{_condition} = $condition;
  $self->{_if_count} = $if_count;

  return '' if(!$condition);
  return 1;
}


# Parses (optional) and outputs a scalar.
#
# defined(_print($self, $scalar)) or die;  # Parse and output
# (_print($self, \$scalar) > 0) or print "Void"; # Output only

sub _print {
  my($self, $scalar) = @_;

  # Optionally parse the scalar.
  my $ref;
  if(!ref($scalar)) {
    _parse($self, $ref = \$scalar);
  } else {
    $ref = $scalar;
  }

  # Output the scalar.
  if(ref($self->{_output}) eq 'SCALAR') {
    ${$self->{_output}} .= $$ref if($$ref ne '');
  } elsif($$ref ne '') {
    (print {$self->{_output}} $$ref) or return undef;
  }
  return length($$ref);
}


# Sets the common parameters for automated counters.
#
# _stats($self, 0, 0); # Reset NUMBER and COUNT
# _stats($self, 1); # Add 1 to NUMBER
# _stats($self, 1); # Substract 1 from NUMBER
# _stats($self, undef, 1, 1); # Add 1 to COUNT and to TOTAL
# _stats($self, undef, undef, undef, $section); # Only set SECTION

sub _stats {
  my($self, $number, $count, $total, $section) = @_;
  local $_;

  if(defined($number)) {
    $number ? ($number = $self->{_param}{'NUMBER'}+$number) : ($number = 1);
    $self->{_param}{'NUMBER'} = $number;
    $self->{_param}{'NUMBER?'} = $number%2;
  }

  if(defined($count)) {
    $count ? ($count = $self->{_param}{'COUNT'}+$count) : ($count = 0);
    $self->{_param}{'COUNT'} = $count;
    $self->{_param}{'COUNT?'} = $count%2;
  }

  if(defined($total)) {
    $total ? ($total = $self->{_param}{'TOTAL'}+$total) : ($total = 0);
    $self->{_param}{'TOTAL'} = $total;
    $self->{_param}{'TOTAL?'} = $total%2;
  }

  $self->{_param}{'SECTION'} = $section if(defined($section));
}


# Sets the common date and time parameters.
#
# _date($self, $epoch_time);

sub _date {
  my($self, $epoch_time) = @_;
  $epoch_time = time unless(defined($epoch_time));

  # Calculate the local time zone.
  my @ltm = localtime($epoch_time);
  my @gmt = gmtime($epoch_time);
  my $zone = ($ltm[2]*60+$ltm[1])-($gmt[2]*60+$gmt[1]);
  if(($ltm[5] > $gmt[5]) or (($ltm[5] == $gmt[5]) and ($ltm[7] > $gmt[7]))) {
    $zone += 24*60;
  } elsif(($ltm[5] < $gmt[5]) or (($ltm[5] == $gmt[5]) and ($ltm[7] < $gmt[7]))) {
    $zone -= 24*60;
  }
  my $hour = int($zone/60);
  $zone = sprintf("%+03d%02d", $hour, abs($zone-$hour*60));

  # Set the parameters for both the local time and GMT.
  my($date, $tm, $prefix);
  $date = localtime($epoch_time);
  $tm = \@ltm;
  foreach $prefix ('', 'GMT_') {
    # Construct a full date/time string.
    $date =
      substr($date, 0, 3).      # Weekday, e.g. "Thu"
      ', '.
      sprintf("%02d", $$tm[3]). # Day, e.g. "30"
      substr($date, 3, 5).      # Month, e.g. " Oct "
      substr($date, 20, 4).     # Year, e.g. "1975"
      substr($date, 10, 10).    # Time, e.g. " 17:10:00 "
      $zone;                    # Zone, e.g. "+0100"

    # Set the date/time parameters.
    $self->{_param}{$prefix.'YEAR'} = substr($date, 12, 4);
    $self->{_param}{$prefix.'MONTH'} = sprintf("%02d", $$tm[4]+1);
    $self->{_param}{$prefix.'MONTH$'} = substr($date, 8, 3);
    $self->{_param}{$prefix.'DAY'} = substr($date, 5, 2);
    $self->{_param}{$prefix.'DATE'} = substr($date, 5, 11);
    $self->{_param}{$prefix.'WEEKDAY'} = $$tm[6]+1;
    $self->{_param}{$prefix.'WEEKDAY$'} = substr($date, 0, 3);
    $self->{_param}{$prefix.'HOUR'} = substr($date, 17, 2);
    $self->{_param}{$prefix.'MINUTE'} = substr($date, 20, 2);
    $self->{_param}{$prefix.'TIME'} = substr($date, 17, 5);
    $self->{_param}{$prefix.'SECOND'} = substr($date, 23, 2);
    $self->{_param}{$prefix.'TIME_ZONE'} = $zone;
    $self->{_param}{$prefix.'DATE_TIME'} = $date;

    # Next, please!
    $date = gmtime($epoch_time);
    $tm = \@gmt;
    $zone = 'GMT';
  }
}


=head1 THE .HTX FILE FORMAT

A F<.htx> file is a normal HTML file, but it also contains special tags,
which are handled by this module. These special tags are enclosed by
C<E<lt>%> and C<%E<gt>> (kinda like Microsoft's Active Server Pages), and
may contain variables and simple statements. The following special tags are
supported:

=over 4

=item C<E<lt>%>I<variable>C<%E<gt>>

Outputs the value of the variable in HTML encoding. The variable may be a
user defined variable, but also a CGI environment variable.

User defined variables are defined or modified using the C<param> method.
This is typically done before a call to the C<print_detail> method, but
also before calling the C<print_header> and C<print_footer> methods.

=item C<E<lt>%EscapeRaw >I<expression>C<%E<gt>>

=item C<E<lt>%EscapeHTML >I<expression>C<%E<gt>>

=item C<E<lt>%EscapeURL >I<expression>C<%E<gt>>

=item C<E<lt>%EscapeJS >I<expression>C<%E<gt>>

=item C<E<lt>%EscapeScramble >I<expression>C<%E<gt>>

Outputs the value of a variable or a literal string using HTML, URL,
JavaScript, scrambled JavaScript or "raw" encoding.

JavaScript encoding can be used in JavaScript between double quotes, e.g.
C<document.write("E<lt>%EscapeJS Variable%E<gt>");>. Scrambled JavaScript
encoding comes in handy when you want to "hide" e-mail addresses from
spambots, e.g. C<document.write("E<lt>%EscapeScramble Email%E<gt>");>.

=item C<E<lt>%begindetail%E<gt>>

Repeats what comes next for each record, until C<E<lt>%enddetail%E<gt>> or
the end of the file is reached. This is the section that is printed by the
C<print_detail> method.

=item C<E<lt>%enddetail%E<gt>>

See C<E<lt>%begindetail%E<gt>>.

=item C<E<lt>%detailsection >I<name>C<%E<gt>>

Defines a name for the next detail section, which makes life very easy when
your template file contains multiple detail sections. For more information
see the C<detail_section> method.

=item C<E<lt>%if >I<condition>C<%E<gt>>

Only output what comes next if I<condition> is true. The I<condition> has
the following syntax:

I<expression1> I<operator> [I<expression2>]

I<expression1> and I<expression2> can be any value or variable name. Literal
string values should be enclosed by C<"">. If one of the values is a typical
string value, then both values are treated as strings, otherwise they are
treated as numerical values.

I<operator> can be one of the following operators:

=over 4

=item *

C<eq> - I<expression1> and I<expression2> are identical.

=item *

C<ne> - I<expression1> and I<expression2> are not identical.

=item *

C<lt> - I<expression1> is less than I<expression2>.

=item *

C<le> - I<expression1> is less than or equal to I<expression2>.

=item *

C<gt> - I<expression1> is greater than I<expression2>.

=item *

C<ge> - I<expression1> is greater than or equal to I<expression2>.

=item *

C<contains> - I<expression1> contains I<expression2>.

=item *

C<istypeeq> - This is always true; it's included for compatibility.

=item *

C<isempty>  - I<expression1> equals an empty string (or zero in a numerical
context). I<expression2> should be ommited when you use the C<isempty>
operator.

=back

=item C<E<lt>%else%E<gt>>

Only output what comes next if the I<condition> of an earlier
C<E<lt>%if%E<gt>> was false.

=item C<E<lt>%endif%E<gt>>

Ends a conditional block and returns to its earlier conditional state. Yes,
this means that you can nest
C<E<lt>%if%E<gt>>..C<E<lt>%else%E<gt>>..C<E<lt>%endif%E<gt>> blocks. :-)

=item C<E<lt>%include >I<file>C<%E<gt>>

Includes a file as if it were part of the current F<.htx> file. In this
include file you may also again use the special tags, or even the
C<E<lt>%include%E<gt>> tag for that matter. However, the use of
C<E<lt>%include%E<gt>> inside an include file is not recommended, because it
may lead to recursive inclusion. You should also be careful with using
C<E<lt>%begindetail%E<gt>>..C<E<lt>%enddetail%E<gt>> inside an include file,
because I<detail sections cannot be nested>.

=back

=head1 KNOWN ISSUES

Since no syntax checking is performed on F<.htx> files, any unsupported
statements or non-existing variables will simply be ignored. If you misuse
any of the supported statements, you can't be sure of what might happen.

Also, the C<E<lt>%if%E<gt>>, C<E<lt>%else%E<gt>> and C<E<lt>%endif%E<gt>>
statements are not really block statements, as they are in Perl or most
other programming languages, but they rather just change the state of the
internal condition flag. As a side effect you can disable a portion of a
template file by placing C<E<lt>%else%E<gt>>..C<E<lt>%endif%E<gt>> around it
(without C<E<lt>%if%E<gt>>!).

The use of multiple C<E<lt>%begindetail%E<gt>>..C<E<lt>%enddetail%E<gt>>
sections is not documented for Microsoft's Index Server, but is supported
very elegantly by this module (see the C<detail_section> method).

=head1 MODIFICATION HISTORY

=over 4

=item Version 0.07

[I<May 5 - 15, 2005>] Transparent UTF-8 support for both Perl 5.6 and 5.8
was a little buggy (really?), but now it works (really!). The template file
can now also be an open file handle or a scalar in memory. Templates
containing multiple L<detail sections|detail_section> are now much easier to
handle. Two new encoding types have been added: C<E<lt>%EscapeJS%E<gt>> and
C<E<lt>%EscapeScramble%E<gt>>. The L<common parameters|common_params>
feature has been added. The tests in F<test.pl> now don't do just one simple
"live" test anymore, but rather test most of the module. (The coverage of
these tests is probably not 100%, but it's close.)

=item Version 0.06

[I<April 17/18, 2005>] Added transparent UTF-8 support for both Perl 5.6 and
5.8. Also reviewed and partly rewrote all other code. Output to a scalar
doesn't use tying anymore (which worked, but probably produced warnings, and
probably was a bit slower), but it now simply appends the output to the
specified scalar.

=item Version 0.05

[I<November 21, 2004>] Added the option for output to a scalar instead of a
file.

=item Version 0.04

[I<July 30, 2002>] Fixed a minor bug concerning multi-line
C<E<lt>%if%E<gt>>'s.

=item Version 0.03

[I<July 21, 2002>] Fixed a bug in the C<_evaluate> sub, that resulted in
warnings about uninitialized multiplications when using the C<isempty>
operator.

=item Version 0.02

[I<June 21/24, 2002>] Fixed a few minor bugs concerning nested
C<E<lt>%if%E<gt>>'s, the C<isempty> operator, and the use of HTTP headers.

=item Version 0.01

[I<April, 2002>] Created the module. :-)

=back

=head1 AUTHOR INFORMATION

Theo Niessink <niessink@martinic.nl>, http://www.taletn.com/

I<(The "I used to care but Things Have Changed" used in the
L<Synopsis|"SYNOPSIS"> was written by Bob Dylan.)> :-)

=head1 COPYRIGHT

E<copy> MARTINIC Computers 2002-2005. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

For more information on MARTINIC Computers visit http://www.martinic.nl/

=cut


1;
