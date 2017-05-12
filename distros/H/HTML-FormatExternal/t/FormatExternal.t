#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013, 2015 Kevin Ryde

# This file is part of HTML-FormatExternal.
#
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

use 5.006;
use strict;
use warnings;
use FindBin;
use HTML::FormatExternal;
use Test::More tests => 284;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

if (defined $ENV{PATH}) {
  ($ENV{PATH}) = ($ENV{PATH} =~ /(.*)/);  # untaint so programs can run
}

{
  my $want_version = 26;
  is ($HTML::FormatExternal::VERSION, $want_version,
      'VERSION variable');
  is (HTML::FormatExternal->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { HTML::FormatExternal->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { HTML::FormatExternal->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}


# Cribs:
#
# Test::More::like() ends up spinning a qr// through a further /$re/ which
# loses any /m modifier, prior to perl 5.10.0 at least.  So /m is avoided in
# favour of some (^|\n) and ($|{\r\n]) forms.


sub is_undef_or_string {
  my ($obj) = @_;
  if (! defined $obj) { return 1; }
  if (ref $obj) { return 0; }
  if ($obj eq '') { return 0; } # disallow empty
  return 1;
}

sub is_undef_or_one_line_string {
  my ($obj) = @_;
  if (! defined $obj) { return 1; }
  if (ref $obj) { return 0; }
  if ($obj eq '') { return 0; } # disallow empty
  if ($obj =~ /\n/) { return 0; }
  return 1;
}

my $colon_is_ordinary;

foreach my $class ('HTML::FormatText::Elinks',
                   'HTML::FormatText::Html2text',
                   'HTML::FormatText::Links',
                   'HTML::FormatText::Lynx',
                   'HTML::FormatText::Netrik',
                   'HTML::FormatText::W3m',
                   'HTML::FormatText::Zen',
                  ) {
  diag $class;
  use_ok ($class);

  is ($class->VERSION,
      $HTML::FormatExternal::VERSION,
      "$class VERSION method");
  is (do { no strict 'refs'; ${"${class}::VERSION"} },
      $HTML::FormatExternal::VERSION,
      "$class VERSION variable");

  #
  # program_full_version()
  #
  { my $version = $class->program_full_version;
    require Data::Dumper;
    diag ("$class program_full_version ", Data::Dumper::Dumper($version));
    ok (is_undef_or_string($version),
        'program_full_version() from class');
  }
  { my $formatter = $class->new;
    my $version = $formatter->program_full_version;
    ok (is_undef_or_string($version),
        'program_full_version() from obj');
  }

  #
  # program_version()
  #
  { my $version = $class->program_version();
    require Data::Dumper;
    diag ("$class program_version ", Data::Dumper::Dumper($version));
    ok (is_undef_or_one_line_string($version),
        "$class program_version() from class");
  }
  { my $formatter = $class->new;
    my $version = $formatter->program_version();
    ok (is_undef_or_one_line_string($version),
        "$class program_version() from obj");
  }

  foreach my $method ('_have_nomargins',
                      '_have_html_margin',
                      '_have_ascii') {
    if ($class->can($method)) {
      diag "$class $method() ",($class->$method ? "yes" : "no");
    }
  }


 SKIP: {
    if (! defined $class->program_full_version) {
      skip "$class program not available", 33;
    }

    { my $str = $class->format_string ('<html><body>Hello</body><html>');
      like ($str, qr/Hello/,
            "$class through class");
    }
    { my $formatter = $class->new;
      my $str = $formatter->format ('<html><body>Hello</body><html>');
      like ($str, qr/Hello/,
            "$class through formatter object");
    }

  SKIP: {
      eval { require HTML::TreeBuilder }
        or skip 'HTML::TreeBuilder not available', 1;

      my $tree = HTML::TreeBuilder->new_from_content
        ('<html><body>Hello</body><html>');
      my $formatter = $class->new;
      my $str = $formatter->format ($tree);
      like ($str, qr/Hello/,
            "$class through formatter object on TreeBuilder");
    }

  SKIP: {
      if ($class =~ /Lynx/ && ! $class->_have_nomargins()) {
        skip "this Lynx doesn't have -nomargins", 1;
      }
      if ($class =~ /Links/ && ! $class->_have_html_margin()) {
        skip "this links doesn't have -html-margin", 1;
      }

      my $str = $class->format_string ('<html><body>Hello</body><html>',
                                       leftmargin => 0);
      like ($str, qr/(^|\n)Hello/,  # allowing for leading blank lines
            "$class through class, with leftmargin 0");
    }

  SKIP: {
      if ($class =~ /Zen/) {
        skip "$class doesn't support rightmargin", 1;
      }
      if ($class =~ /Lynx/ && ! $class->_have_nomargins()) {
        skip "this Lynx doesn't have -nomargins", 1;
      }
      if ($class =~ /Links/ && ! $class->_have_html_margin()) {
        skip "this links doesn't have -html-margin", 1;
      }

      my $html = '<html><body>123 567 9012 abc def ghij</body><html>';
      my $str = $class->format_string ($html,
                                       leftmargin => 0,
                                       rightmargin => 12);
      {
        require Data::Dumper;
        my $dumper = Data::Dumper->new([$str],['output']);
        $dumper->Useqq (1);
        diag ($dumper->Dump);
      }
      like ($str, qr/(^|\n)123 567 9012($|[\r\n])/,
            "$class through class, with leftmargin 0 rightmargin 12");
    }

    foreach my $data
      ([ 'ascii',
         '',
         '<html><body><a href="page.html">Foo</a></body></html>',
         'http://foo.org/page.html' ],

       [ 'utf16le',
         "\377\376",
         "<\0h\0t\0m\0l\0>\0<\0b\0o\0d\0y\0>\0<\0a\0 \0h\0r\0e\0f\0=\0\"\0p\0a\0g\0e\0.\0h\0t\0m\0l\0\"\0>\0F\0o\0o\0<\0/\0a\0>\0<\0/\0b\0o\0d\0y\0>\0<\0/\0h\0t\0m\0l\0>\0",
         'http://foo.org/page.html' ],

       [ 'utf16be',
         "\376\377",
         "\0<\0h\0t\0m\0l\0>\0<\0b\0o\0d\0y\0>\0<\0a\0 \0h\0r\0e\0f\0=\0\"\0p\0a\0g\0e\0.\0h\0t\0m\0l\0\"\0>\0F\0o\0o\0<\0/\0a\0>\0<\0/\0b\0o\0d\0y\0>\0<\0/\0h\0t\0m\0l\0>",
         'http://foo.org/page.html' ],

       ['utf32le',
        "\377\376\0\0",
        "<\0\0\0h\0\0\0t\0\0\0m\0\0\0l\0\0\0>\0\0\0<\0\0\0b\0\0\0o\0\0\0d\0\0\0y\0\0\0>\0\0\0<\0\0\0a\0\0\0 \0\0\0h\0\0\0r\0\0\0e\0\0\0f\0\0\0=\0\0\0\"\0\0\0p\0\0\0a\0\0\0g\0\0\0e\0\0\0.\0\0\0h\0\0\0t\0\0\0m\0\0\0l\0\0\0\"\0\0\0>\0\0\0F\0\0\0o\0\0\0o\0\0\0<\0\0\0/\0\0\0a\0\0\0>\0\0\0<\0\0\0/\0\0\0b\0\0\0o\0\0\0d\0\0\0y\0\0\0>\0\0\0<\0\0\0/\0\0\0h\0\0\0t\0\0\0m\0\0\0l\0\0\0>\0\0\0",
        'http://foo.org/page.html' ],

       [ 'utf32be',
         "\0\0\376\377",
         "\0\0\0<\0\0\0h\0\0\0t\0\0\0m\0\0\0l\0\0\0>\0\0\0<\0\0\0b\0\0\0o\0\0\0d\0\0\0y\0\0\0>\0\0\0<\0\0\0a\0\0\0 \0\0\0h\0\0\0r\0\0\0e\0\0\0f\0\0\0=\0\0\0\"\0\0\0p\0\0\0a\0\0\0g\0\0\0e\0\0\0.\0\0\0h\0\0\0t\0\0\0m\0\0\0l\0\0\0\"\0\0\0>\0\0\0F\0\0\0o\0\0\0o\0\0\0<\0\0\0/\0\0\0a\0\0\0>\0\0\0<\0\0\0/\0\0\0b\0\0\0o\0\0\0d\0\0\0y\0\0\0>\0\0\0<\0\0\0/\0\0\0h\0\0\0t\0\0\0m\0\0\0l\0\0\0>",
         'http://foo.org/page.html' ],
      ) {
      my ($charset, $charset_bom, $html, $want_str) = @$data;
      my $want_re = qr/\Q$want_str/;

      foreach my $bom ('',
                       ($charset_bom ? ($charset_bom) : ())) {
      SKIP: {
          # html2text -- doesn't show link targets
          # links     -- doesn't show link targets
          # w3m       -- doesn't show link targets
          # zen       -- shows only the plain href part, doesn't expand
          if ($class !~ /Elinks|Lynx/) {
            skip "$class doesn't display absolutized links", 2;
          }
          if ($charset ne 'ascii' && $class =~ /Elinks/) {
            skip "$class only takes 8-bit input (as of 0.12pre5)", 2;
          }

          $html = "$bom$html";
          my @input_charset = ($bom ? (input_charset => $charset) : ());
          my $desc = "$class base, $charset, ".($bom?'bom':'input_charset');
          {
            my $str = $class->format_string ($html,
                                             base => 'http://foo.org',
                                             output_charset => 'us-ascii',
                                             @input_charset);
            # require Data::Dumper;
            # diag "$charset ", Data::Dumper->new([\$str],['str'])->Dump;

            like ($str, $want_re, "format_string() $desc");
          }
          {
            require File::Temp;
            my $fh = File::Temp->new (SUFFIX => '.html');
            $fh->autoflush(1);
            binmode($fh) or die 'Cannot set binmode on temp file for test';
            print $fh $html or die 'Cannot write temp file for test';
            my $filename = $fh->filename;
            my $str = $class->format_file ($filename,
                                           base => 'http://foo.org',
                                           output_charset => 'us-ascii',
                                           @input_charset);
            like ($str, $want_re, "format_string() $desc");
          }
        }
      }
    }

    # Exercise some strange filenames which might provoke the formatter
    # programs.
    #
    {
      require File::Spec;
      my $testfilename = File::Spec->catfile($FindBin::Bin,'test.html');

      if (! defined $colon_is_ordinary) {
        my $is_absolute = File::Spec->splitpath('C:/FOO');
        my ($volume,$directories,$file) = File::Spec->splitpath('C:FOO');
        $colon_is_ordinary = ($volume eq ''
                              && $directories eq ''
                              && ! $is_absolute
                              ? 1 : 0);
      };
      diag "Colon character is ordinary in filenames: ", $colon_is_ordinary;

      require File::Temp;
      require File::Copy;
      my $tempdir_object = File::Temp->newdir;
      my $tempdir_name = $tempdir_object->dirname;
      diag "Temporary directory ",$tempdir_name;

      foreach my $filename ('http:',
                            '-',
                            '-###',
                            '%57',
                            'a/b',    # filename with "/" probably uncreatable
                           ) {
        my $fullname = File::Spec->catfile($tempdir_name,$filename);

      SKIP: {
          # Don't attempt colon on Mac, MS-DOS, OS/2 etc where it's a volume
          # or directory separator.
          #
          # Cygwin translates ":" and other characters special to windows to
          # some unicode private chars, allowing them to be used
          # https://cygwin.com/cygwin-ug-net/using-specialnames.html
          # But that depends on the external program being a cygwin build
          # too, which is likely but not certain.
          #
          if ($filename =~ /:/ && ! $colon_is_ordinary) {
            skip "Cannot copy test file to $fullname: $!", 2;
          }
          # might be impossible to create a file with a slash like "a/b"
          File::Copy::copy($testfilename, $fullname)
              or skip "Cannot copy test file to $fullname: $!", 2;

          {
            my $str = $class->format_file ($fullname);
            like ($str, qr/body.*text/,
                  "$class format_file() filename \"$fullname\"");
          }

          require Cwd;
          my $old_dir = Cwd::getcwd();
          ($old_dir) = ($old_dir =~ /(.*)/);  # untaint
          chdir $tempdir_name or die "Oops, cannot chdir to $tempdir_name";

          {
            my $str = $class->format_file ($filename);
            like ($str, qr/body.*text/,
                  "$class format_file() filename \"$filename\"");
          }

          chdir $old_dir or die "Oops, cannot chdir back to $old_dir";
        }

        # actually File::Temp removes files in its temporary directory anyway
        unlink $fullname;
      }
    }
  }
}

exit 0;
