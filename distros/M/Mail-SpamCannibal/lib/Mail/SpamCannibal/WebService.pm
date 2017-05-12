#!/usr/bin/perl
package Mail::SpamCannibal::WebService;

use strict;
#use diagnostics;
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.05 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	sendhtml
	load
	html_cat
	make_jsPOP_win
	http_date
	cookie_date
	unescape
	get_query
);

=head1 NAME

Mail::SpamCannibal::WebService - web utilities

=head1 SYNOPSIS

  use Mail::SpamCannibal::WebService qw(
        sendhtml
        load
        html_cat
        make_jsPOP_win
	http_date
	cookie_date
	unescape
	get_query
  );

  sendhtml(\$htmltext,\%extraheaders);
  $htmltext = load($filename);
  $hc = html_cat(\$htmltext,$name,\%filehash,\%texthash);
  $html=make_jsPOP_win($name,$width,$height);
  $time_string = http_date($time);
  $time_string = cookie_date($time);
  $string = unescape($escape_string);
  $query || %query = get_query();

=head1 DESCRIPTION

B<Mail::SpamCannibal::WebService> provides utilities to facilitate web page
generation and delivery.

=over 4

=item * sendhtml(\$htmltext,\%extraheaders);

Send html via Apache::mod-perl if present, else using a print statement.

  input:	html text reference.
		extra header reference
  returns:	<nothing>

Extra headers are of the form:

  $extra_headers = {
	header	=> value,
	... etc...
  };

=cut

sub sendhtml {
  my ($hp,$xp) = @_;
  my $size = length($$hp);
  my $r;
  eval { require Apache;
         $r = Apache->request;
  };

  unless ($@) {           # unless error, it's Apache
    $r->status(200);
    $r->content_type('text/html');
    $r->header_out("Content-length","$size");
    if ($xp && keys %$xp) {
      foreach(keys %$xp) {
	$r->header_out($_, $xp->{"$_"});
      }
    }
    $r->send_http_header;
    $r->print($$hp);
    return 200;                   # HTTP_OK

  } else {        # sigh... no mod_perl

    print q
|Content-type: text/html
Content-length: |, $size, q|
Connection: close
|;
    if ($xp && keys %$xp) {
      foreach(keys %$xp) {
	print $_,': ',$xp->{"$_"};
      }
    }
print q|

|, $$hp;
  }
}

=item * $htmltext = load($filename);

Return the contents of $filename;

=cut

sub load {
  my($file) = @_;
  my $protohtml = '';
  if (  $file &&
	-e $file &&
	-r $file &&
  	open(F,$file)) {
    undef local $/;
    $protohtml = <F>;
    close F;
  }
  return $protohtml;
}

=item * html_cat(\$htmltext,$name,\%filehash,\%texthash);

This function loads text from a file pointed to by a hash of the form:

  $file = {
	name1	=> './path/to/filename1.ext',
	name2	=> './path/to/filename2.ext',
	name3	=> '....etc...',
  }

B<html_cat> retrieves the contents of the file and places it in the storage
hash for later use.

  $ftext = {
	name1	=> 'text contents 1',
	name2	=> '...etc...',
  }

If the text exists in the storage hash, it is not retrieved from the file
system. The text requested by $name is concatenated to the scalar referenced
by the pointer to $htmltext.

  input:	$html out pointer,
		$name -- hash key,
		$file hash pointer,
		$text cache hash pointer
  returns:	true on success, else false

=cut

sub html_cat {
  my ($hp,$name,$fp,$tp) = @_;
  return undef unless $tp;
  $tp->{$name} = load($fp->{$name})
	unless (exists $tp->{$name} && defined $tp->{$name});
  return undef unless $tp->{$name};
  $$hp .= $tp->{$name};
  return 1;
}

=item * $html=make_jsPOP_win($name,$width,$height);

This function makes the javascript code to generate a pop-up window. The
function name created is 'popwin', the name and size
are arguments to the function call.

  input:        window name,
                width [optional - 500 def]
                height [optional - 400 def]
  returns:      html text

The javascript function creates a global variable of the name $name and takes the argument "color"

	i.e.	var $name;
		popwin(color);

and always returns "false". The default color is light yellow [#ffffcc] if
no color is specified.


=cut

sub make_jsPOP_win {
  my($name,$width,$height) = @_;
  $width = 500 unless $width;
  $height = 400 unless $height;

  my $html = q|
<script language=javascript1.1>
var |. $name .q|;
function popwin(color) {
  if (!color)
    color = '#ffffcc';
  |. $name .q| = window.open ( "","|. $name .q|",
"toolbar=no,menubar=no,location=no,scrollbars=yes,status=yes,resizable=yes," +
  "width=|. $width .q|,height=|. $height .q|");
  |. $name .q|.document.open();
  |. $name .q|.document.writeln('<html><body bgcolor="' + color + '"></body></html>');
  |. $name .q|.document.close();
  |. $name .q|.focus();
  return false;
}
</script>
|;
}

=item * $time_string = http_date($time);

  Returns time string in HTTP date format, same as...

  Apache::Util::ht_time(time, "%a, %d %b %Y %T %Z",1));

  i.e. Sat, 13 Apr 2002 17:36:42 GMT

=item * $time_string = cookie_date($time);

  Returns time string in Cookie format, similar to
  http_date. HTTP uses space ' ' as a seperator 
  whereas Cookies use a dash '-'.

  i.e. Sat, 13-Apr-2002 17:36:42 GMT

=cut

sub _date {
  my($time,$sep) = @_;
  my($sec,$min,$hr,$mday,$mon,$yr,$wday) = gmtime($time);
  return
    (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday] . ', ' .			# "%a, "
    sprintf("%02d",$mday) . $sep .					# "%d "
    (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon]. $sep .	# "%b "
    ($yr + 1900) . ' ' .						# "%Y "
    sprintf("%02d:%02d:%02d ",$hr,$min,$sec) .				# "%T "
    'GMT';								# "%Z"
}

sub http_date {
  my $time = shift;
  return _date($time,' ');
}

sub cookie_date {
  my $time = shift;
  return _date($time,'-');
}

=item * $string = unescape($escape_string);

Return unescaped string for B<escape_string>. First converts +'s to spaces.

  input:	URL escaped string
  return:	clean string

=cut

sub unescape {
  my ($x) = @_;
  return '' unless $x;
  $x =~ tr/+/ /;	# pluses become spaces
  $x =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
  return $x;
}

=item * $query || %query = get_query();

Return the query string or hash of query key/value pairs. The routine
checks for POST or GET method and reads the query response accordingly.

In scalar mode, returns the query string. In array/hash mode, it returns the
key value pairs.

  input:	none
  returns:	query string or
		array of key/value pairs

Note: in scalar form, the unescaped query string is returned to preserve
possible imbedded '=' characters.

In array form, duplicate keys have their values appended to previous
key/value pair with a null (\0) separator.

=back

=cut

sub get_query {
  my $query = $ENV{QUERY_STRING} || '';
  if ($ENV{REQUEST_METHOD} && (uc $ENV{REQUEST_METHOD}) eq 'POST') {
    local $SIG{ALRM} = sub {die 'timeout'};
    alarm 5;
    eval { read(STDIN,$query,$ENV{CONTENT_LENGTH}) };
    alarm 0;
  }
  return () unless $query;
  return $query unless wantarray;
  @_= split(/&/,$query);
  my %query;
  foreach(@_) {
    my($key,$val) = split(/=/,$_,2);
    $val = '' unless defined $val;
    if (exists $query{$key}) {
      $query{$key} .= "\0". unescape($val);
    } else {
      $query{$key} = unescape($val);
    }
  }
  return %query;
}

=head1 DEPENDENCIES

	none

=head1 EXPORT_OK

	sendhtml
	load
	make_jsPOP_win
	http_date
	cookie_date
	unescape
	get_query

=head1 COPYRIGHT

Copyright 2003, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=cut

1;
