#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013, 2015 Kevin Ryde

# HTML-FormatExternal is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# HTML-FormatExternal is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with HTML-FormatExternal.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Load;
use Data::Dumper;
$Data::Dumper::Useqq = 1;
use FindBin qw($Bin);

# uncomment this to run the ### lines
use Smart::Comments;

my $class;
$class = 'HTML::FormatText::WithLinks';
$class = 'HTML::FormatText::WithLinks::AndTables';
$class = 'HTML::FormatText';
$class = 'HTML::FormatText::Netrik';
$class = 'HTML::FormatText::Elinks';
$class = 'HTML::FormatText::Html2text';
$class = 'HTML::FormatText::Lynx';
$class = 'HTML::FormatText::Links';
$class = 'HTML::FormatText::W3m';
$class = 'HTML::FormatText::Vilistextum';
Module::Load::load ($class);

#  <base href="file:///tmp/">

{
  foreach my $class ('File::Spec::Cygwin',
                     'File::Spec::Epoc',
                     'File::Spec::Mac',
                     'File::Spec::OS2',
                     'File::Spec::Unix',
                     'File::Spec::VMS',
                     'File::Spec::Win32',
                    ) {
    if (! eval "require $class; 1") {
      print "$@\n";
      next;
    }
    my $filename = 'C:FOO';
    my $is_absolute = $class->file_name_is_absolute($filename) ? 1 : 0;
    my ($volume,$directories,$file) = $class->splitpath($filename);
    my $colon_is_ordinary = ($volume eq '' && $directories eq ''
                             && ! $class->file_name_is_absolute($filename) ? 1 : 0);

    ### $class
    ### $is_absolute
    ### $volume
    ### $directories
    ### $file
    ### $colon_is_ordinary

    # my ($volume,$directories,$file) = File::Spec::Win32->splitpath('h:/x/y/foo');
  }
  exit 0;
}
{
  my $input_filename = '/tmp/foo/http:';
  require URI::file;
  my $str = URI::file->new_abs($input_filename)->as_string;
  print $str,"\n";
  exit 0;
}


{
  # HTML::Tree

  require HTML::Element;

  my $a = HTML::Element->new('a', href=>'blah="=blah=\'=');
  $a->push_content("Hello \x{263A} world");

  my $p = HTML::Element->new('p');
  $p->push_content("Hello \x{263A} world");
  $p->push_content($a);

  my $body = HTML::Element->new('body');
  $body->insert_element($p);

  my $html = HTML::Element->new('body');
  $html->insert_element($body);

  my $html_str = $html->as_HTML(
                                '<>&'
                               );
  $Data::Dumper::Useqq=1;
  print Dumper(\$html_str);
  print "utf8 flag ",(utf8::is_utf8($html_str) ? 'yes' : 'no'), "\n";
  print $html->as_HTML;

  require HTML::FormatText::Vilistextum;
  my $formatter = HTML::FormatText::Vilistextum->new;
  my $str = $formatter->format ($html);
  print Dumper(\$str);
  print "utf8 flag ",(utf8::is_utf8($str) ? 'yes' : 'no'), "\n";
  require Scalar::Util;
  print "tainted ",(Scalar::Util::tainted($str) ? 'yes' : 'no'), "\n";
  exit 0;
}

{
  # format_string() with wide chars
  #  $ENV{PATH} = '/bin:/usr/bin';
  my $html = "<html><body><p>Hello \x{263A} \x{2641} world &#65; &#255;
              blah blah blah blah blah blah blah blah blah blah blah
              blah blah blah blah blah blah blah blah blah blah blah
              blah blah blah blah blah blah blah blah blah blah blah
              </p></body></html>\n";

  require HTML::FormatText::Zen;
  my $str = HTML::FormatText::Zen->format_string ($html,
                                                     # output_wide => 'as_input',
                                                  leftmargin => 10,
                                                    );

  $Data::Dumper::Useqq=1;
  print Dumper(\$str);
  print "utf8 flag ",(utf8::is_utf8($str) ? 'yes' : 'no'), "\n";
  require Scalar::Util;
  print "tainted ",(Scalar::Util::tainted($str) ? 'yes' : 'no'), "\n";

  print $str;
  exit 0;
}

{
  # duplicated links formatting

  foreach my $class ('HTML::FormatText::Netrik',
                     'HTML::FormatText::Links',
                     'HTML::FormatText::Html2text',
                     'HTML::FormatText::Lynx',
                     'HTML::FormatText::Elinks',
                     'HTML::FormatText::W3m',
                     'HTML::FormatText::Vilistextum',
                    ) {
    print "\n$class\n";
    Module::Load::load ($class);

    my $html = "<html><body><p><a href='http://example.com'>One</a>
                          <p><a href='http://example.com'>Two</a>
                          <p><u>underline</u>
                          </p></body></html>\n";
    my $str = $class->format_string ($html,
                                     output_wide => 'as_input',
                                     # lynx_options => ['-underscore'],
                                     unique_links => 1,
                                    );
    print $str;
  }
  exit 0;
}



{
  # program_version() of each module

  foreach my $class ('HTML::FormatText::Netrik',
                     'HTML::FormatText::Links',
                     'HTML::FormatText::Html2text',
                     'HTML::FormatText::Lynx',
                     'HTML::FormatText::Elinks',
                     'HTML::FormatText::W3m',
                     'HTML::FormatText::Vilistextum',
                    ) {
    Module::Load::load ($class);
    my $version = $class->program_version;
    my $full = $class->program_full_version;
    ### $class
    ### $full
    ### $version
  }
  exit 0;
}



{
#  $ENV{PATH} = '/bin:/usr/bin';
  require HTML::FormatText::Lynx;
  print "Lynx _have_nomargins(): ",
    (HTML::FormatText::Lynx->_have_nomargins() ? "yes" : "no"),"\n";

  require HTML::FormatText::Links;
  print "Links _have_html_margin(): ",
    (HTML::FormatText::Links->_have_html_margin() ? "yes" : "no"),"\n";

  require HTML::FormatText::Vilistextum;
  print "Vilistextum _have_multibyte(): ",
    (HTML::FormatText::Vilistextum->_have_multibyte() ? "yes" : "no"),"\n";
  exit 0;
}


{
  # IPC::Run in taint mode
  # $ENV{PATH} = '/bin:/usr/bin';
  my $str;
  require IPC::Run;
   IPC::Run::run(['echo','hello'], '>',\$str);
  # IPC::Run::run(['cat'], '<', \'hello', '>', \$str);
  ### $str
  exit 0;
}



{
  # taintedness of program_version()
  $ENV{PATH} = '/bin:/usr/bin';
  require HTML::FormatText::W3m;
  my $str = HTML::FormatText::W3m->program_full_version;
  require Scalar::Util;
  print "tainted ",(Scalar::Util::tainted($str) ? 'yes' : 'no'), "\n";
  exit 0;  
}




{
  # format_file() with output_wide

  require HTML::FormatText::W3m;
  my $str = HTML::FormatText::W3m->format_file
    ('devel/base.html', output_wide => 1);

  $Data::Dumper::Useqq=1;
  print Dumper(\$str);
  print "utf8 flag ",(utf8::is_utf8($str) ? 'yes' : 'no'), "\n";
  exit 0;
}


{
  # format_file() with base

  require HTML::FormatText::Elinks;
  my $str = HTML::FormatText::Elinks->format_file
    ('devel/base.html', base => 'http://localhost');
  exit 0;
}
{
  # BOM on input
  # lynx recognises automatically

  my $html = "<html><body><p>Hello world</p></body></html>\n";
  require Encode;

   $html = Encode::encode('utf-32',$html); # with BOM
  # $html = "\xFF\xFE\x00\x00" . Encode::encode('utf-32le',$html); # with BOM
  $html = ("\x20\x00\x00\x00" x 8) . $html;  # BE spaces

  print "HTML input string:\n";
  IPC::Run::run(['hd'],'<',\$html, '>','/tmp/hd.txt');
  IPC::Run::run(['cat'],'<','/tmp/hd.txt');

  require HTML::FormatText::Lynx;
  my $text = HTML::FormatText::Lynx->format_string ($html,
                                                    input_charset=>'UTF-32',
                                                    # output_charset=>'UTF-8',
                                                    output_wide => 1,
                                                    # base => 'http://localhost',
                                                   );
  print "Text output:\n";
  print $text;
  IPC::Run::run(['hd'],'<',\$text, '>','/tmp/hd.txt');
  IPC::Run::run(['cat'],'<','/tmp/hd.txt');
  for my $i (0 .. length($text)-1) {
    my $c = substr($text,$i,1);
    if (ord($c) >= 128) {
      printf "0x%X\n", ord($c);
    }
  }
  exit 0;
}




{
  # entities

  POSIX::setlocale (POSIX::LC_CTYPE(), "C");

  foreach my $class ('HTML::FormatText::Netrik',
                     'HTML::FormatText::Links',
                     'HTML::FormatText::Html2text',
                     'HTML::FormatText::Lynx',
                     'HTML::FormatText::Elinks',
                     'HTML::FormatText::W3m',
                     'HTML::FormatText::Vilistextum',
                    ) {
    print "--------------------\n$class\n";
    Module::Load::load ($class);
    my $html = "
<html>
<head>
  <meta http-equiv=Content-Type content='text/html; charset=iso-8859-1'>
</head>
<body>
<p>
  \xA2 &#9786; &#9686;
</p>
</body>
</html>";
    my $str = $class->format_string
      ($html
       # input_charset  => $input_charset,
       # output_charset => $output_charset,
      );
    print $str;
    $Data::Dumper::Useqq=1;
    print Dumper(\$str);
    print "utf8 flag ",(utf8::is_utf8($str) ? 'yes' : 'no'), "\n";
  }
  exit 0;
}

{
  # my $filename = "$FindBin::Bin/x.html";
  # $filename = "/tmp/z.html";
  # my $filename = "$FindBin::Bin/base.html";
  # my $filename = "$FindBin::Bin/margin12.html";
  my $filename = "t/%57";
  # my $filename = "/tmp/rsquo.html";


  # output_charset => 'ascii',
  # output_charset => 'ANSI_X3.4-1968',
  # output_charset => 'utf-8'
  my $output_charset = 'utf-8';

  # input_charset => 'shift-jis',
  # input_charset => 'iso-8859-1',
  # input_charset => 'utf-8',
  my $input_charset;
  $input_charset = 'utf16le';
  $input_charset = 'ascii';
  $input_charset = 'latin-1';

  require File::Copy;
  print "File::Copy ",File::Copy->VERSION, "\n";

  my $str = $class->format_file
    ($filename,
     # rightmargin => 12,
     # # leftmargin => 20,
     # justify => 1,
     #
     # base => "http://foo.org/\x{2022}/foo.html",
     #
     input_charset  => $input_charset,
     output_charset => $output_charset,

     # #      lynx_options => [ '-underscore',
     # #                        '-underline_links',
     # #                        '-with_backspaces',
     # #                      ],
     # justify => 1,
    );
  $Data::Dumper::Purity = 1;
  print "$class on $filename\n";
  print $str;
  print Data::Dumper->new([\$str],['output'])->Useqq(0)->Dump;
  print "utf8 flag ",(utf8::is_utf8($str) ? 'yes' : 'no'), "\n";
  exit 0;
}


{
  require I18N::Langinfo;
  require POSIX;
  POSIX::setlocale (POSIX::LC_CTYPE(), "C");
  my $charset = I18N::Langinfo::langinfo (I18N::Langinfo::CODESET());
  print "charset $charset\n";
  exit 0;
}
{
  foreach my $class (qw(HTML::FormatText::Elinks
                        HTML::FormatText::Html2text
                        HTML::FormatText::Lynx
                        HTML::FormatText::Links
                        HTML::FormatText::Netrik
                        HTML::FormatText::W3m
                        HTML::FormatText::Zen)) {
    system "perl", "-Mblib", "-M$class", "-e", "print 'ok $class\n'";
  }
  exit 0;
}


{
  require HTML::FormatText::Lynx;
  print "Lynx ",
    HTML::FormatText::Lynx->program_version,
        " _have_nomargins ",
          (HTML::FormatText::Lynx->_have_nomargins?"yes":"no"),"\n";

  require HTML::FormatText::Html2text;
  print "Html2text ",
    HTML::FormatText::Html2text->program_version,
        " _have_ascii ",
          (HTML::FormatText::Html2text->_have_ascii?"yes":"no"),"\n";

  require HTML::FormatText::Links;
  print "Links ",
    HTML::FormatText::Links->program_version,
        " _have_html_margin ",
          (HTML::FormatText::Links->_have_html_margin?"yes":"no"),"\n";

  exit 0;
}


{
  my $html_str = <<"HERE";
<html>
<head>
<title>A Page</title>
</head>
<body>
<p> Hello <u>fjkd</u> jfksd jfk \x{263A} sdjkf jsk fjsdk fjskd jfksd jfks djfk sdjfk sdjkf jsdkf jsdk fjksd fjksd jfksd jfksd jfk sdjfk sdjkf sdjkf sdjkbhjhh <a href="world.html">world</a> </p>

<p> \x{263A}\x{263A}\x{263A}\x{263A} \x{263A}\x{263A}\x{263A} \x{263A}\x{263A}\x{263A} \x{263A}\x{263A}\x{263A} \x{263A}\x{263A}\x{263A} \x{263A}\x{263A}\x{263A} \x{263A}\x{263A}\x{263A} \x{263A}\x{263A}\x{263A} </p>
</body>
</html>
HERE
  print "utf8 flag ",(utf8::is_utf8($html_str) ? 'yes' : 'no'), "\n";

  my $str = $class->format_string ($html_str,
                                   # justify => 1,
                                   rightmargin => 40,
                                   leftmargin => 10,
                                  );
  print $str;
  print Dumper($str);
  print "utf8 flag ",(utf8::is_utf8($str) ? 'yes' : 'no'), "\n";
  exit 0;
}




{
  my $str = $class->format_string
    ('<html><body> <p> Hello </body> </html>');
  print $str;
  exit 0;
}



#           if ($class !~ /Lynx/) {
#             # old lynx, eg. 2.8.1, doesn't have -display_charset for output_charset
#             my $help = $class->_run_version ('lynx', '-help');
#             my $have_display_charset = (defined $help
#                                         && $help =~ /-display_charset/);
#             if ($charset ne 'ascii' && ! $have_display_charset) {
#               skip "this lynx doesn't have -display_charset", 2;
#             }
#           }
