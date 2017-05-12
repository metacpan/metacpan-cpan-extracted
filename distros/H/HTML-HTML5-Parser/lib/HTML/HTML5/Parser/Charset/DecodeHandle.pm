package HTML::HTML5::Parser::Charset::DecodeHandle;
## skip Test::Tabs
use strict;

our $VERSION = '0.301';

## NOTE: |Message::Charset::Info| uses this module without calling
## the constructor.
use HTML::HTML5::Parser::Charset::Info;

my $XML_AUTO_CHARSET = q<http://suika.fam.cx/www/2006/03/xml-entity/>;
my $IANA_CHARSET = q<urn:x-suika-fam-cx:charset:>;
my $PERL_CHARSET = q<http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.>;
my $XML_CHARSET = q<http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.>;

## ->create_decode_handle ($charset_uri, $byte_stream, $onerror)
sub create_decode_handle ($$$;$) {
  my $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$_[1]};
  my $obj = {
             category => 0,
             char_buffer => \(my $s = ''),
             char_buffer_pos => 0,
             character_queue => [],
             filehandle => $_[2],
             charset => $_[1],
             byte_buffer => '',
             onerror => $_[3] || sub {},
             #onerror_set
            };
  if ($csdef->{uri}->{$XML_AUTO_CHARSET} or
      $obj->{charset} eq $XML_AUTO_CHARSET) {
    my $b = ''; # UTF-8 w/o BOM
    $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
    $obj->{input_encoding} = 'UTF-8';
    if (read $obj->{filehandle}, $b, 256) {
      no warnings "substr";
      no warnings "uninitialized";
      if (substr ($b, 0, 1) eq "<") {
        if (substr ($b, 1, 1) eq "?") { # ASCII8
          if ($b =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii8} or $csdef->{bom_required}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
            $obj->{input_encoding} = 'UTF-8';
          }
          if (defined $csdef->{no_bom_variant}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant}};
          }
        } elsif (substr ($b, 1, 1) eq "\x00") {
          if (substr ($b, 2, 2) eq "?\x00") { # ASCII16LE
            my $c = $b; $c =~ tr/\x00//d;
            if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
                encoding\s*=\s*["']([^"']*)/x) {
              $obj->{input_encoding} = $1;
              my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
              $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
              if (not $csdef->{ascii16} or $csdef->{ascii16be} or
                  $csdef->{bom_required}) {
                $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                  charset_uri => $uri,
                                  charset_name => $obj->{input_encoding});
              }
            } else {
              $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
              $obj->{input_encoding} = 'UTF-8';
            }
            if (defined $csdef->{no_bom_variant16le}) {
              $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant16le}};
            }
          } elsif (substr ($b, 2, 2) eq "\x00\x00") { # ASCII32Endian4321
            my $c = $b; $c =~ tr/\x00//d;
            if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
                encoding\s*=\s*["']([^"']*)/x) {
              $obj->{input_encoding} = $1;
              my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
              $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
              if (not $csdef->{ascii32} or 
                  $csdef->{ascii32endian1234} or
                  $csdef->{ascii32endian2143} or
                  $csdef->{ascii32endian3412} or
                  $csdef->{bom_required}) {
                $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                  charset_uri => $uri,
                                  charset_name => $obj->{input_encoding});
              }
            } else {
              $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
              $obj->{input_encoding} = 'UTF-8';
            }
            if (defined $csdef->{no_bom_variant32endian4321}) {
              $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant32endian4321}};
            }
          }
        }
      } elsif (substr ($b, 0, 3) eq "\xEF\xBB\xBF") { # UTF8
        $obj->{has_bom} = 1;
        substr ($b, 0, 3) = '';
        my $c = $b;
        if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
            encoding\s*=\s*["']([^"']*)/x) {
          $obj->{input_encoding} = $1;
          my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
          $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
          if (not $csdef->{utf8_encoding_scheme} or
              not $csdef->{bom_allowed}) {
            $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                              charset_uri => $uri,
                              charset_name => $obj->{input_encoding});
          }
        } else {
          $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
          $obj->{input_encoding} = 'UTF-8';
        }
        if (defined $csdef->{no_bom_variant}) {
          $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant}};
        }
      } elsif (substr ($b, 0, 2) eq "\x00<") {
        if (substr ($b, 2, 2) eq "\x00?") { # ASCII16BE
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii16} or $csdef->{ascii16le} or
                $csdef->{bom_required}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
            $obj->{input_encoding} = 'UTF-8';
          }
          if (defined $csdef->{no_bom_variant16be}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant16be}};
          }
        } elsif (substr ($b, 2, 2) eq "\x00\x00") { # ASCII32Endian3412
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii32} or 
                $csdef->{ascii32endian1234} or
                $csdef->{ascii32endian2143} or
                $csdef->{ascii32endian4321} or
                $csdef->{bom_required}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
            $obj->{input_encoding} = 'UTF-8';
          }
          if (defined $csdef->{no_bom_variant32endian3412}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant32endian3412}};
          }
        }
      } elsif (substr ($b, 0, 2) eq "\xFE\xFF") {
        if (substr ($b, 2, 2) eq "\x00<") { # ASCII16BE
          $obj->{has_bom} = 1;
          substr ($b, 0, 2) = '';
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii16} or
                $csdef->{ascii16le} or
                not $csdef->{bom_allowed}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16be'};
            $obj->{input_encoding} = 'UTF-16';
          }
          if (defined $csdef->{no_bom_variant16be}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant16be}};
          }
        } elsif (substr ($b, 2, 2) eq "\x00\x00") { # ASCII32Endian3412
          $obj->{has_bom} = 1;
          substr ($b, 0, 4) = '';
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii32} or
                $csdef->{ascii32endian1234} or
                $csdef->{ascii32endian2143} or
                $csdef->{ascii32endian4321} or
                not $csdef->{bom_allowed}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16be'};
            $obj->{input_encoding} = 'UTF-16';
            $obj->{byte_buffer} .= "\x00\x00";
          }
          if (defined $csdef->{no_bom_variant32endian3412}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant32endian3412}};
          }
        } else {
          $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16be'};
          $obj->{input_encoding} = 'UTF-16';
          substr ($b, 0, 2) = '';
          $obj->{has_bom} = 1;
        }
      } elsif (substr ($b, 0, 2) eq "\xFF\xFE") {
        if (substr ($b, 2, 2) eq "<\x00") { # ASCII16LE
          $obj->{has_bom} = 1;
          substr ($b, 0, 2) = '';
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii16} or
                $csdef->{ascii16be} or
                not $csdef->{bom_allowed}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16le'};
            $obj->{input_encoding} = 'UTF-16';
          }
          if (defined $csdef->{no_bom_variant16le}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant16le}};
          }
        } elsif (substr ($b, 2, 2) eq "\x00\x00") { # ASCII32Endian4321
          $obj->{has_bom} = 1;
          substr ($b, 0, 4) = '';
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii32} or
                $csdef->{ascii32endian1234} or
                $csdef->{ascii32endian2143} or
                $csdef->{ascii32endian3412} or
                not $csdef->{bom_allowed}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16le'};
            $obj->{input_encoding} = 'UTF-16';
            $obj->{byte_buffer} .= "\x00\x00";
          }
          if (defined $csdef->{no_bom_variant32endian4321}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant32endian4321}};
          }
        } else {
          $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16le'};
          $obj->{input_encoding} = 'UTF-16';
          substr ($b, 0, 2) = '';
          $obj->{has_bom} = 1;
        }
      } elsif (substr ($b, 0, 2) eq "\x00\x00") {
        if (substr ($b, 2, 2) eq "\x00<") { # ASCII32Endian1234
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii32} or
                $csdef->{ascii32endian2143} or
                $csdef->{ascii32endian3412} or
                $csdef->{ascii32endian4321} or
                $csdef->{bom_required}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
            $obj->{input_encoding} = 'UTF-8';
          }
          if (defined $csdef->{no_bom_variant32endian1234}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant32endian1234}};
          }
        } elsif (substr ($b, 2, 2) eq "<\x00") { # ASCII32Endian2143
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii32} or
                $csdef->{ascii32endian1234} or
                $csdef->{ascii32endian3412} or
                $csdef->{ascii32endian4321} or
                $csdef->{bom_required}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
            $obj->{input_encoding} = 'UTF-8';
          }
          if (defined $csdef->{no_bom_variant32endian2143}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant32endian2143}};
          }
        } elsif (substr ($b, 2, 2) eq "\xFE\xFF") { # ASCII32Endian1234
          $obj->{has_bom} = 1;
          substr ($b, 0, 4) = '';
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii32} or
                $csdef->{ascii32endian2143} or
                $csdef->{ascii32endian3412} or
                $csdef->{ascii32endian4321} or
                $csdef->{bom_required}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
            $obj->{input_encoding} = 'UTF-8';
            $obj->{has_bom} = 0;
            $obj->{byte_buffer} .= "\x00\x00\xFE\xFF";
         }
          if (defined $csdef->{no_bom_variant32endian1234}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant32endian1234}};
          }
        } elsif (substr ($b, 2, 2) eq "\xFF\xFE") { # ASCII32Endian2143
          $obj->{has_bom} = 1;
          substr ($b, 0, 4) = '';
          my $c = $b; $c =~ tr/\x00//d;
          if ($c =~ /^<\?xml\s+(?:version\s*=\s*["'][^"']*["']\s*)?
              encoding\s*=\s*["']([^"']*)/x) {
            $obj->{input_encoding} = $1;
            my $uri = name_to_uri (undef, 'xml', $obj->{input_encoding});
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};
            if (not $csdef->{ascii32} or
                $csdef->{ascii32endian1234} or
                $csdef->{ascii32endian3412} or
                $csdef->{ascii32endian4321} or
                $csdef->{bom_required}) {
              $obj->{onerror}->(undef, 'charset-name-mismatch-error',
                                charset_uri => $uri,
                                charset_name => $obj->{input_encoding});
            }
          } else {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'};
            $obj->{input_encoding} = 'UTF-8';
            $obj->{has_bom} = 0;
            $obj->{byte_buffer} .= "\x00\x00\xFF\xFE";
          }
          if (defined $csdef->{no_bom_variant32endian2143}) {
            $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$csdef->{no_bom_variant32endian2143}};
          }
        }
        # \x4C\x6F\xA7\x94 EBCDIC
      } # buffer
      $obj->{byte_buffer} .= $b;
    } # read
  } elsif ($csdef->{uri}->{$XML_CHARSET.'utf-8'}) {
    ## BOM is optional.
    my $b = '';
    if (read $obj->{filehandle}, $b, 3) {
      if ($b eq "\xEF\xBB\xBF") {
        $obj->{has_bom} = 1;
      } else {
        $obj->{byte_buffer} .= $b;
      }
    }
    $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-8'}; # UTF-8 w/o BOM
  } elsif ($csdef->{uri}->{$XML_CHARSET.'utf-16'}) {
    ## BOM is mandated.
    my $b = '';
    if (read $obj->{filehandle}, $b, 2) {
      if ($b eq "\xFE\xFF") {
        $obj->{has_bom} = 1; # UTF-16BE w/o BOM
        $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16be'};
      } elsif ($b eq "\xFF\xFE") {
        $obj->{has_bom} = 1; # UTF-16LE w/o BOM
        $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16le'};
      } else {
        $obj->{onerror}->(undef, 'no-bom-error', charset_uri => $obj->{charset});
        $obj->{has_bom} = 0;
        $obj->{byte_buffer} .= $b; # UTF-16BE w/o BOM
        $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16be'};
      }
    } else {
      $obj->{onerror}->(undef, 'no-bom-error', charset_uri => $obj->{charset});
      $obj->{has_bom} = 0; # UTF-16BE w/o BOM
      $csdef = $HTML::HTML5::Parser::Charset::CharsetDef->{$PERL_CHARSET.'utf-16be'};
    }
  }

  if ($csdef->{uri}->{$XML_CHARSET.'iso-2022-jp'}) {
    $obj->{state_2440} = 'gl-jis-1997-swapped';
    $obj->{state_2442} = 'gl-jis-1997';
    $obj->{state} = 'state_2842';
    require Encode::GLJIS1997Swapped;
    require Encode::GLJIS1997;
    if (Encode::find_encoding ($obj->{state_2440}) and
        Encode::find_encoding ($obj->{state_2442})) {
      return bless $obj, 'HTML::HTML5::Parser::Charset::DecodeHandle::ISO2022JP';
    }
  } elsif ($csdef->{uri}->{$IANA_CHARSET.'iso-2022-jp'}) {
    $obj->{state_2440} = 'gl-jis-1978';
    $obj->{state_2442} = 'gl-jis-1983';
    $obj->{state} = 'state_2842';
    require Encode::GLJIS1978;
    require Encode::GLJIS1983;
    if (Encode::find_encoding ($obj->{state_2440}) and
        Encode::find_encoding ($obj->{state_2442})) {
      return bless $obj, 'HTML::HTML5::Parser::Charset::DecodeHandle::ISO2022JP';
    }
  } elsif (defined $csdef->{perl_name}->[0]) {
    if ($csdef->{uri}->{$XML_CHARSET.'euc-jp'} or
        $csdef->{uri}->{$IANA_CHARSET.'euc-jp'}) {
      $obj->{perl_encoding_name} = $csdef->{perl_name}->[0];
      require Encode::EUCJP1997;
      if (Encode::find_encoding ($obj->{perl_encoding_name})) {
        $obj->{category} |= HTML::HTML5::Parser::Charset::Info::CHARSET_CATEGORY_EUCJP;
        return bless $obj, 'HTML::HTML5::Parser::Charset::DecodeHandle::Encode';
      }
    } elsif ($csdef->{uri}->{$XML_CHARSET.'shift_jis'} or
             $csdef->{uri}->{$IANA_CHARSET.'shift_jis'}) {
      $obj->{perl_encoding_name} = $csdef->{perl_name}->[0];
      require Encode::ShiftJIS1997;
      if (Encode::find_encoding ($obj->{perl_encoding_name})) {
        return bless $obj, 'HTML::HTML5::Parser::Charset::DecodeHandle::Encode';
      }
    } elsif ($csdef->{is_block_safe}) {
      $obj->{perl_encoding_name} = $csdef->{perl_name}->[0];
      require Encode;
      if (Encode::find_encoding ($obj->{perl_encoding_name})) {
        return bless $obj, 'HTML::HTML5::Parser::Charset::DecodeHandle::Encode';
      }
    }
  }
  
  $obj->{onerror}->(undef, 'charset-not-supported-error',
                    charset_uri => $obj->{charset});
  return undef;
} # create_decode_handle

sub name_to_uri ($$$) {
  my $domain = $_[1];
  my $name = lc $_[2];

  if ($domain eq 'ietf') {
    return $IANA_CHARSET . $name;
  } elsif ($domain eq 'xml') {
    if ({
      'utf-8' => 1,
      'utf-16' => 1,
      'iso-10646-ucs-2' => 1,
      'iso-10646-ucs-4' => 1,
      'iso-8859-1' => 1,
      'iso-8859-2' => 1,
      'iso-8859-3' => 1,
      'iso-8859-4' => 1,
      'iso-8859-5' => 1,
      'iso-8859-6' => 1,
      'iso-8859-7' => 1,
      'iso-8859-8' => 1,
      'iso-8859-9' => 1,
      'iso-8859-10' => 1,
      'iso-8859-11' => 1,
      'iso-8859-13' => 1,
      'iso-8859-14' => 1,
      'iso-8859-15' => 1,
      'iso-8859-16' => 1,
      'iso-2022-jp' => 1,
      'shift_jis' => 1,
      'euc-jp' => 1,
    }->{$name}) {
      return $XML_CHARSET . $name;
    }

    my $uri = $IANA_CHARSET . $name;
    return $uri if $HTML::HTML5::Parser::Charset::CharsetDef->{$uri};

    return $XML_CHARSET . $name;
  } else {
    return undef;
  }
} # name_to_uri

sub uri_to_name ($$$) {
  my (undef, $domain, $uri) = @_;
  
  if ($domain eq 'xml') {
    my $v = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri}->{xml_name};
    return $v if defined $v;

    if (substr ($uri, 0, length $XML_CHARSET) eq $XML_CHARSET) {
      return substr ($uri, length $XML_CHARSET);
    }

    $domain = 'ietf'; ## TODO: XML encoding name has smaller range
  }

  if ($domain eq 'ietf') {
    my $v = $HTML::HTML5::Parser::Charset::CharsetDef->{$uri}->{iana_name};
    return $v->[0] if defined $v;

    if (substr ($uri, 0, length $IANA_CHARSET) eq $IANA_CHARSET) {
      return substr ($uri, length $IANA_CHARSET);
    }
  }

  return undef;
} # uri_to_name

require IO::Handle;

package HTML::HTML5::Parser::Charset::DecodeHandle::ByteBuffer;

## NOTE: Provides a byte buffer wrapper object.

sub new ($$) {
  my $self = bless {
    buffer => '',
  }, shift;
  $self->{filehandle} = shift;
  return $self;
} # new

sub read {
  my $self = shift;
  my $pos = length $self->{buffer};
  my $r = $self->{filehandle}->read ($self->{buffer}, $_[1], $pos);
  substr ($_[0], $_[2]) = substr ($self->{buffer}, $pos);
      ## NOTE: This would do different behavior from Perl's standard
      ## |read| when $pos points beyond the end of the string.
  return $r;
} # read

sub close { $_[0]->{filehandle}->close }

package HTML::HTML5::Parser::Charset::DecodeHandle::CharString;

## NOTE: Same as Perl's standard |open $handle, '<', \$char_string|,
## but supports |ungetc| and other extensions.

sub new ($$) {
  my $self = bless {pos => 0}, shift;
  $self->{string} = shift; # must be a scalar ref
  return $self;
} # new

sub getc ($) {
  my $self = shift;
  if ($self->{pos} < length ${$self->{string}}) {
    return substr ${$self->{string}}, $self->{pos}++, 1;
  } else {
    return undef;
  }
} # getc

sub read ($$$$) {
  #my ($self, $scalar, $length, $offset) = @_;
  my $self = $_[0];
  my $length = $_[2] || 0;
  my $offset = $_[3] || 0;
  ## NOTE: We don't support standard Perl semantics if $offset is
  ## greater than the length of $scalar.
  substr ($_[1], $offset) = substr (${$self->{string}}, $self->{pos}, $length);
  my $count = (length $_[1]) - $offset;
  $self->{pos} += $count;
  return $count;
} # read

sub manakai_read_until ($$$;$) {
  #my ($self, $scalar, $pattern, $offset) = @_;
  my $self = $_[0];
  pos (${$self->{string}}) = $self->{pos};
  if (${$self->{string}} =~ /\G(?>$_[2])+/) {
    substr ($_[1], $_[3]) = substr (${$self->{string}}, $-[0], $+[0] - $-[0]);
    $self->{pos} += $+[0] - $-[0];
    return $+[0] - $-[0];
  } else {
    return 0;
  }
} # manakai_read_until

sub ungetc ($$) {
  my $self = shift;
  ## Ignore second parameter.
  $self->{pos}-- if $self->{pos} > 0;
} # ungetc

sub close ($) { }

sub onerror ($;$) { }

package HTML::HTML5::Parser::Charset::DecodeHandle::Encode;

## NOTE: Provides a Perl |Encode| module wrapper object.

sub charset ($) { $_[0]->{charset} }

sub close ($) { $_[0]->{filehandle}->close }

sub getc ($) {
  my $c = '';
  my $l = $_[0]->read ($c, 1);
  if ($l) {
    return $c;
  } else {
    return undef;
  }
} # getc

sub read ($$$;$) {
  my $self = $_[0];
  #my $scalar = $_[1];
  my $length = $_[2];
  my $offset = $_[3] || 0;
  my $count = 0;
  my $eof;
  ## NOTE: It is incompatible with the standard Perl semantics
  ## if $offset is greater than the length of $scalar.

  A: {
    return $count if $length < 1;

    if (my $l = (length ${$self->{char_buffer}}) - $self->{char_buffer_pos}) {
      if ($l >= $length) {
        substr ($_[1], $offset)
            = substr (${$self->{char_buffer}}, $self->{char_buffer_pos},
                      $length);
        $count += $length;
        $self->{char_buffer_pos} += $length;
        $length = 0;
        return $count;
      } else {
        substr ($_[1], $offset)
            = substr (${$self->{char_buffer}}, $self->{char_buffer_pos});
        $count += $l;
        $length -= $l;
        ${$self->{char_buffer}} = '';
        $self->{char_buffer_pos} = 0;
      }
      $offset = length $_[1];
    }

    if ($eof) {
      return $count;
    }

    my $error;
    if ($self->{continue}) {
      if ($self->{filehandle}->read ($self->{byte_buffer}, 256,
                                     length $self->{byte_buffer})) {
        # 
      } else {
        $error = 1;
      }
      $self->{continue} = 0;
    } elsif (512 > length $self->{byte_buffer}) {
      if ($self->{filehandle}->read ($self->{byte_buffer}, 256,
                                     length $self->{byte_buffer})) {
        #
      } else {
        $eof = 1;
      }
    }

    unless ($error) {
      if (not $self->{bom_checked}) {
        if (defined $self->{bom_pattern}) {
          if ($self->{byte_buffer} =~ s/^$self->{bom_pattern}//) {
            $self->{has_bom} = 1;
          }
        }
        $self->{bom_checked} = 1;
      }
      my $string = do {
			BEGIN { $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /^Code point/ } }
			Encode::decode ($self->{perl_encoding_name},
                         $self->{byte_buffer},
                         Encode::FB_QUIET ());
		};
      if (length $string) {
        $self->{char_buffer} = \$string;
        $self->{char_buffer_pos} = 0;
        if (length $self->{byte_buffer}) {
          $self->{continue} = 1;
        }
      } else {
        if (length $self->{byte_buffer}) {
          $error = 1;
        } else {
          ## NOTE: No further input.
          redo A;
        }
      }
    }

    if ($error) {
      my $r = substr $self->{byte_buffer}, 0, 1, '';
      my $fallback;
      my $etype = 'illegal-octets-error';
      my %earg;
      if ($self->{category}
              & HTML::HTML5::Parser::Charset::Info::CHARSET_CATEGORY_SJIS) {
        if ($r =~ /^[\x81-\x9F\xE0-\xFC]/) {
          if ($self->{byte_buffer} =~ s/(.)//s) {
            $r .= $1;                     # not limited to \x40-\xFC - \x7F
            $etype = 'unassigned-code-point-error';
          }
          ## NOTE: Range [\xF0-\xFC] is unassigned and may be used as a
          ## single-byte character or as the first-byte of a double-byte
          ## character, according to JIS X 0208:1997 Appendix 1.  However, the
          ## current practice is using the range as first-bytes of double-byte
          ## characters.
        } elsif ($r =~ /^[\x80\xA0\xFD-\xFF]/) {
          $etype = 'unassigned-code-point-error';
        }
      } elsif ($self->{category}
                   & HTML::HTML5::Parser::Charset::Info::CHARSET_CATEGORY_EUCJP) {
        if ($r =~ /^[\xA1-\xFE]/) {
          if ($self->{byte_buffer} =~ s/^([\xA1-\xFE])//) {
            $r .= $1;
            $etype = 'unassigned-code-point-error';
          }
        } elsif ($r eq "\x8F") {
          if ($self->{byte_buffer} =~ s/^([\xA1-\xFE][\xA1-\xFE]?)//) {
            $r .= $1;
            $etype = 'unassigned-code-point-error' if length $1 == 2;
          }
        } elsif ($r eq "\x8E") {
          if ($self->{byte_buffer} =~ s/^([\xA1-\xFE])//) {
            $r .= $1;
            $etype = 'unassigned-code-point-error';
          }
        } elsif ($r eq "\xA0" or $r eq "\xFF") {
          $etype = 'unassigned-code-point-error';
        }
      } else {
        $fallback = $self->{fallback}->{$r};
        if (defined $fallback) {
          ## NOTE: This is an HTML5 parse error.
          $etype = 'fallback-char-error';
          $earg{char} = \$fallback;
        } elsif (exists $self->{fallback}->{$r}) {
          ## NOTE: This is an HTML5 parse error.  In addition, the octet
          ## is not assigned with a character.
          $etype = 'fallback-unassigned-error';
        }
      }

      ## NOTE: Fixup line/column number by counting the number of 
      ## lines/columns in the string that is to be retuend by this
      ## method call.
      my $line_diff = 0;
      my $col_diff = 0;
      my $set_col;
      for (my $i = 0; $i < $count; $i++) {
        my $s = substr $_[1], $i - $count, 1;
        if ($s eq "\x0D") {
          $line_diff++;
          $col_diff = 0;
          $set_col = 1;
          $i++ if substr ($_[1], $i - $count + 1, 1) eq "\x0A";
        } elsif ($s eq "\x0A") {
          $line_diff++;
          $col_diff = 0;
          $set_col = 1;
        } else {
          $col_diff++;
        }
      }
      my $i = $self->{char_buffer_pos};
      if ($count and substr (${$self->{char_buffer}}, -1, 1) eq "\x0D") {
        if (substr (${$self->{char_buffer}}, $i, 1) eq "\x0A") {
          $i++;
        }
      }
      my $cb_length = length ${$self->{char_buffer}};
      for (; $i < $cb_length; $i++) {
        my $s = substr $_[1], $i, 1;
        if ($s eq "\x0D") {
          $line_diff++;
          $col_diff = 0;
          $set_col = 1;
          $i++ if substr ($_[1], $i + 1, 1) eq "\x0A";
        } elsif ($s eq "\x0A") {
          $line_diff++;
          $col_diff = 0;
          $set_col = 1;
        } else {
          $col_diff++;
        }
      }
      $self->{onerror}->($self, $etype, octets => \$r, %earg,
                         level => $self->{level}->{$self->{error_level}->{$etype}},
                         line_diff => $line_diff,
                         ($set_col ? (column => 1) : ()),
                         column_diff => $col_diff);
          ## NOTE: Error handler may modify |octets| parameter, which
          ## would be returned as part of the output.  Note that what
          ## is returned would affect what |manakai_read_until| returns.
      ${$self->{char_buffer}} .= defined $fallback ? $fallback : $r;
    }

    redo A;
  } # A
} # read

sub manakai_read_until ($$$;$) {
  #my ($self, $scalar, $pattern, $offset) = @_;
  my $self = $_[0];
  my $s = '';
  $self->read ($s, 255);
  if ($s =~ /^(?>$_[2])+/) {
    my $rem_length = (length $s) - $+[0];
    if ($rem_length) {
      if ($self->{char_buffer_pos} > $rem_length) {
        $self->{char_buffer_pos} -= $rem_length;
      } else {
        substr (${$self->{char_buffer}}, 0, $self->{char_buffer_pos})
            = substr ($s, $+[0]);
        $self->{char_buffer_pos} = 0;
      }
    }
    substr ($_[1], $_[3]) = substr ($s, $-[0], $+[0] - $-[0]);
    return $+[0];
  } elsif (length $s) {
    if ($self->{char_buffer_pos} > length $s) {
      $self->{char_buffer_pos} -= length $s;
    } else {
      substr (${$self->{char_buffer}}, 0, $self->{char_buffer_pos}) = $s;
      $self->{char_buffer_pos} = 0;
    }
  }
  return 0;
} # manakai_read_until

sub has_bom ($) { $_[0]->{has_bom} }

sub input_encoding ($) {
  my $v = $_[0]->{input_encoding};
  return $v if defined $v;

  my $uri = $_[0]->{charset};
  if (defined $uri) {
    return HTML::HTML5::Parser::Charset::DecodeHandle->uri_to_name (xml => $uri);
  }

  return undef;
} # input_encoding

sub onerror ($;$) {
  if (@_ > 1) {
    if ($_[1]) {
      $_[0]->{onerror} = $_[1];
      $_[0]->{onerror_set} = 1;
    } else {
      $_[0]->{onerror} = sub { };
      delete $_[0]->{onerror_set};
    }
  }

  return $_[0]->{onerror_set} ? $_[0]->{onerror} : undef;
} # onerror

sub ungetc ($$) {
  unshift @{$_[0]->{character_queue}}, chr int ($_[1] or 0);
} # ungetc

package HTML::HTML5::Parser::Charset::DecodeHandle::ISO2022JP;
push our @ISA, 'HTML::HTML5::Parser::Charset::DecodeHandle::Encode';

sub getc ($) {
  my $self = $_[0];
  return shift @{$self->{character_queue}} if @{$self->{character_queue}};

  my $r;
  A: {
    my $error;
    if ($self->{continue}) {
      if ($self->{filehandle}->read ($self->{byte_buffer}, 256,
                                     length $self->{byte_buffer})) {
        # 
      } else {
        $error = 1;
      }
      $self->{continue} = 0;
    } elsif (512 > length $self->{byte_buffer}) {
      $self->{filehandle}->read ($self->{byte_buffer}, 256,
                                 length $self->{byte_buffer});
    }
    
    unless ($error) {
      if ($self->{byte_buffer} =~ s/^\x1B(\x24[\x40\x42]|\x28[\x42\x4A])//) {
        $self->{state} = {
                          "\x24\x40" => 'state_2440',
                          "\x24\x42" => 'state_2442',
                          "\x28\x42" => 'state_2842',
                          "\x28\x4A" => 'state_284A',
                         }->{$1};
        redo A;
      } elsif ($self->{state} eq 'state_2842') { # IRV
        if ($self->{byte_buffer} =~ s/^([\x00-\x0D\x10-\x1A\x1C-\x7F]+)//) {
          push @{$self->{character_queue}}, split //, $1;
          $r = shift @{$self->{character_queue}};
        } else {
          if (length $self->{byte_buffer}) {
            $error = 1;
          } else {
            $r = undef;
          }
        }
      } elsif ($self->{state} eq 'state_284A') { # 0201
        if ($self->{byte_buffer} =~ s/^([\x00-\x0D\x10-\x1A\x1C-\x7F]+)//) {
          my $v = $1;
          $v =~ tr/\x5C\x7E/\xA5\x{203E}/;
          push @{$self->{character_queue}}, split //, $v;
          $r = shift @{$self->{character_queue}};
        } else {
          if (length $self->{byte_buffer}) {
            $error = 1;
          } else {
            $r = undef;
            $self->{onerror}->($self, 'invalid-state-error',
                               state => $self->{state},
                               level => $self->{level}->{$self->{error_level}->{'invalid-state-error'}});
          }
        }
      } elsif ($self->{state} eq 'state_2442') { # 1983
        my $v = Encode::decode ($self->{state_2442},
                                $self->{byte_buffer},
                                Encode::FB_QUIET ());
        if (length $v) {
          push @{$self->{character_queue}}, split //, $v;
          $r = shift @{$self->{character_queue}};
        } else {
          if (length $self->{byte_buffer}) {
            $error = 1;
          } else {
            $r = undef;
            $self->{onerror}->($self, 'invalid-state-error',
                               state => $self->{state},
                               level => $self->{level}->{$self->{error_level}->{'invalid-state-error'}});
          }
        }
      } elsif ($self->{state} eq 'state_2440') { # 1978
        my $v = Encode::decode ($self->{state_2440},
                                $self->{byte_buffer},
                                Encode::FB_QUIET ());
        if (length $v) {
          push @{$self->{character_queue}}, split //, $v;
          $r = shift @{$self->{character_queue}};
        } else {
          if (length $self->{byte_buffer}) {
            $error = 1;
          } else {
            $r = undef;
            $self->{onerror}->($self, 'invalid-state-error',
                               state => $self->{state},
                               level => $self->{level}->{$self->{error_level}->{'invalid-state-error'}});
          }
        }
      } else {
        $error = 1;
      }
    }
    
    if ($error) {
      $r = substr $self->{byte_buffer}, 0, 1, '';
      my $etype = 'illegal-octets-error';
      if (($self->{state} eq 'state_2442' or
           $self->{state} eq 'state_2440') and
          $r =~ /^[\x21-\x7E]/ and
          $self->{byte_buffer} =~ s/^([\x21-\x7E])//) {
        $r .= $1;
        $etype = 'unassigned-code-point-error';
      } elsif ($r eq "\x1B" and
               $self->{byte_buffer} =~ s/^\(H//) { # Old 0201
        $r .= "(H";
        $self->{state} = 'state_284A';
      }
      $self->{onerror}->($self, $etype, octets => \$r,
                         level => $self->{level}->{$self->{error_level}->{$etype}});
    }
  } # A
  
  return $r;
} # getc

## TODO: This is not good for performance.  Should be replaced
## by read-centric implementation.
sub read ($$$;$) {
  #my ($self, $scalar, $length, $offset) = @_;
  my $length = $_[2];
  my $r = '';
  while ($length > 0) {
    my $c = $_[0]->getc;
    last unless defined $c;
    $r .= $c;
    $length--;
  }
  substr ($_[1], $_[3]) = $r;
      ## NOTE: This would do different thing from what Perl's |read| do
      ## if $offset points beyond the end of the $scalar.
  return length $r;
} # read

sub manakai_read_until ($$$;$) {
  #my ($self, $scalar, $pattern, $offset) = @_;
  my $self = $_[0];
  my $c = $self->getc;
  if ($c =~ /^$_[2]/) {
    substr ($_[1], $_[3]) = $c;
    return 1;
  } elsif (defined $c) {
    $self->ungetc (ord $c);
    return 0;
  } else {
    return 0;
  }
} # manakai_read_until

$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:us-ascii'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:us'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:iso646-us'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:cp367'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:ibm367'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:ansi_x3.4-1986'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:ansi_x3.4-1968'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:iso-ir-6'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:csascii'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:iso_646.irv:1991'} = 
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:ascii'} = {ascii8 =>
'1',
is_block_safe =>
'1',
ietf_name =>
['ansi_x3.4-1968',
'ansi_x3.4-1986',
'ascii',
'cp367',
'csascii',
'ibm367',
'iso-ir-6',
'iso646-us',
'iso_646.irv:1991',
'us',
'us-ascii',
'us-ascii'],
mime_name =>
'us-ascii',
perl_name =>
['ascii',
'iso-646-us',
'us-ascii'],
utf8_encoding_scheme =>
'1',
'uri',
{'urn:x-suika-fam-cx:charset:ansi_x3.4-1968',
'1',
'urn:x-suika-fam-cx:charset:ansi_x3.4-1986',
'1',
'urn:x-suika-fam-cx:charset:ascii',
'1',
'urn:x-suika-fam-cx:charset:cp367',
'1',
'urn:x-suika-fam-cx:charset:csascii',
'1',
'urn:x-suika-fam-cx:charset:ibm367',
'1',
'urn:x-suika-fam-cx:charset:iso-ir-6',
'1',
'urn:x-suika-fam-cx:charset:iso646-us',
'1',
'urn:x-suika-fam-cx:charset:iso_646.irv:1991',
'1',
'urn:x-suika-fam-cx:charset:us',
'1',
'urn:x-suika-fam-cx:charset:us-ascii',
'1'},
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ascii-ctrl'} = {perl_name =>
['ascii-ctrl'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ascii-ctrl',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.null'} = {perl_name =>
['null'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.null',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.utf-8'} = {ascii8 =>
'1',
bom_allowed =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf8',
utf8_encoding_scheme =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.utf-8',
'1'},
  xml_name => 'UTF-8',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/UTF-8.RFC2279'} = {ascii8 =>
'1',
bom_allowed =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf8',
utf8_encoding_scheme =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/UTF-8.RFC2279',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-8'} = {
  ascii8 => 1,
is_block_safe =>
'1',
perl_name =>
['utf-8'],
utf8_encoding_scheme =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-8',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:utf-8'} = {
  ascii8 => 1,
bom_allowed =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-8',
ietf_name =>
['utf-8'],
mime_name =>
'utf-8',
utf8_encoding_scheme =>
'1',
'uri',
{'urn:x-suika-fam-cx:charset:utf-8',
'1'},
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf8'} = {ascii8 =>
'1',
is_block_safe =>
'1',
perl_name =>
['utf8'],
utf8_encoding_scheme =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf8',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.utf-16'} = {
  ascii16 => 1,
bom_allowed =>
'1',
bom_required =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16le',
no_bom_variant16be =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16be',
no_bom_variant16le =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16le',
perl_name =>
['utf-16'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.utf-16',
'1'},
  xml_name => 'UTF-16',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:utf-16'} = {
  ascii16 => 1,
bom_allowed =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16le',
no_bom_variant16be =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16be',
no_bom_variant16le =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16le',
ietf_name =>
['utf-16'],
mime_name =>
'utf-16',
'uri',
{'urn:x-suika-fam-cx:charset:utf-16',
'1'},
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:utf-16be'} = {
  ascii16 => 1,
  ascii16be => 1,
bom_allowed =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16be',
no_bom_variant16be =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16be',
ietf_name =>
['utf-16be'],
mime_name =>
'utf-16be',
'uri',
{'urn:x-suika-fam-cx:charset:utf-16be',
'1'},
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:utf-16le'} = {
  ascii16 => 1,
  ascii16le => 1,
bom_allowed =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16le',
no_bom_variant16le =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16le',
ietf_name =>
['utf-16le'],
mime_name =>
'utf-16le',
'uri',
{'urn:x-suika-fam-cx:charset:utf-16le',
'1'},
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16be'} = {
  ascii16 => 1,
  ascii16be => 1,
is_block_safe =>
'1',
perl_name =>
['utf-16be'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16be',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16le'} = {
  ascii16 => 1,
  ascii16le => 1,
is_block_safe =>
'1',
perl_name =>
['utf-16le'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-16le',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-10646-ucs-2'} = $HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:iso-10646-ucs-2'} = {
  ascii16 => 1,
bom_allowed =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ucs-2le',
no_bom_variant16be =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ucs-2be',
no_bom_variant16le =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ucs-2le',
ietf_name =>
['csunicode',
'iso-10646-ucs-2'],
mime_name =>
'iso-10646-ucs-2',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-10646-ucs-2',
'1',
'urn:x-suika-fam-cx:charset:iso-10646-ucs-2',
'1'},
  xml_name => 'ISO-10646-UCS-2',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ucs-2be'} = {
  ascii16 => 1,
  ascii16be => 1,
is_block_safe =>
'1',
perl_name =>
['ucs-2be'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ucs-2be',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ucs-2le'} = {
  ascii16 => 1,
  ascii16le => 1,
is_block_safe =>
'1',
perl_name =>
['ucs-2le'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.ucs-2le',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-10646-ucs-4'} = $HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:iso-10646-ucs-4'} = {
  ascii32 => 1,
bom_allowed =>
'1',
no_bom_variant =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-32le',
no_bom_variant32endian1234 =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-32be',
no_bom_variant32endian4321 =>
'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-32le',
ietf_name =>
['csucs4',
'iso-10646-ucs-4'],
mime_name =>
'iso-10646-ucs-4',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-10646-ucs-4',
'1',
'urn:x-suika-fam-cx:charset:iso-10646-ucs-4',
'1'},
  xml_name => 'ISO-10646-UCS-4',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-32be'} = {
  ascii32 => 1,
  ascii32endian1234 => 1,
is_block_safe =>
'1',
perl_name =>
['ucs-4be',
'utf-32be'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-32be',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-32le'} = {
  ascii32 => 1,
  ascii32endian4321 => 1,
is_block_safe =>
'1',
perl_name =>
['ucs-4le',
'utf-32le'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.utf-32le',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:iso_8859-1:1987'} = $HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-1'} = {ascii8 =>
'1',
is_block_safe =>
'1',
ietf_name =>
['cp819',
'csisolatin1',
'ibm819',
'iso-8859-1',
'iso-8859-1',
'iso-ir-100',
'iso_8859-1',
'iso_8859-1:1987',
'l1',
'latin1'],
mime_name =>
'iso-8859-1',
perl_name =>
['iso-8859-1',
'latin1'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-1',
'1',
'urn:x-suika-fam-cx:charset:iso_8859-1:1987',
'1'},
  xml_name => 'ISO-8859-1',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-2'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-2',
'1'},
  xml_name => 'ISO-8859-2',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-3'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-3',
'1'},
  xml_name => 'ISO-8859-3',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-4'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-4',
'1'},
  xml_name => 'ISO-8859-4',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-5'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-5',
'1'},
  xml_name => 'ISO-8859-5',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-6'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-6',
'1'},
  xml_name => 'ISO-8859-6',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-7'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-7',
'1'},
  xml_name => 'ISO-8859-7',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-8'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-8',
'1'},
  xml_name => 'ISO-8859-8',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-9'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-9',
'1'},
  xml_name => 'ISO-8859-9',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-10'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-10',
'1'},
  xml_name => 'ISO-8859-10',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-11'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-11',
'1'},
  xml_name => 'ISO-8859-11',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-13'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-13',
'1'},
  xml_name => 'ISO-8859-13',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-14'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-14',
'1'},
  xml_name => 'ISO-8859-14',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-15'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-15',
'1'},
  xml_name => 'ISO-8859-15',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-16'} = {ascii8 =>
'1',
is_block_safe =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-8859-16',
'1'},
  xml_name => 'ISO-8859-16',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-2022-jp'} = {ascii8 =>
'1',
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.iso-2022-jp',
'1'},
  xml_name => 'ISO-2022-JP',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:iso-2022-jp'} = {ascii8 =>
'1',
ietf_name =>
['csiso2022jp',
'iso-2022-jp',
'iso-2022-jp'],
mime_name =>
'iso-2022-jp',
'uri',
{'urn:x-suika-fam-cx:charset:iso-2022-jp',
'1'},
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.iso-2022-jp'} = {ascii8 =>
'1',
perl_name =>
['iso-2022-jp'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.iso-2022-jp',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:shift_jis'} = $HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.shift_jis'} = {ascii8 =>
'1',
is_block_safe =>
'1',
ietf_name =>
['csshiftjis',
'ms_kanji',
'shift_jis',
'shift_jis'],
mime_name =>
'shift_jis',
perl_name =>
['shift-jis-1997'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.shift_jis',
'1',
'urn:x-suika-fam-cx:charset:shift_jis',
'1'},
  xml_name => 'Shift_JIS',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.shiftjis'} = {ascii8 =>
'1',
is_block_safe =>
'1',
perl_name =>
['shiftjis',
'sjis'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.shiftjis',
'1'}};
$HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:euc-jp'} = $HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.euc-jp'} = $HTML::HTML5::Parser::Charset::CharsetDef->{'urn:x-suika-fam-cx:charset:extended_unix_code_packed_format_for_japanese'} = {ascii8 =>
'1',
is_block_safe =>
'1',
ietf_name =>
['cseucpkdfmtjapanese',
'euc-jp',
'euc-jp',
'extended_unix_code_packed_format_for_japanese'],
mime_name =>
'euc-jp',
perl_name =>
['euc-jp-1997'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/XML.euc-jp',
'1',
'urn:x-suika-fam-cx:charset:euc-jp',
'1',
'urn:x-suika-fam-cx:charset:extended_unix_code_packed_format_for_japanese',
'1'},
  xml_name => 'EUC-JP',
};

$HTML::HTML5::Parser::Charset::CharsetDef->{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.euc-jp'} = {ascii8 =>
'1',
is_block_safe =>
'1',
perl_name =>
['euc-jp',
'ujis'],
'uri',
{'http://suika.fam.cx/~wakaba/archive/2004/dis/Charset/Perl.euc-jp',
'1'}};

1;
## $Date: 2008/09/15 07:19:03 $
