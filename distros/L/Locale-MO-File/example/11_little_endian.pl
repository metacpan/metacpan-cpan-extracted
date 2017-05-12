#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

require Data::Dumper; # to visualize output only
require Locale::MO::File;

my $filename = '11_little_endian.mo';

# The content of the "messages" array reference is first sorted and then written.
# The transferred "messages" array reference remains unchanged.
# The example 13_... shows you how to handle encoding and newline.
Locale::MO::File->new(
    filename => $filename,
    messages => [
        {
            msgid  => q{},
            # More complex header build easy using
            # module Locale::PO::Utils, method build_header_msgstr.
            msgstr => <<'EOT',
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
EOT
        },
        {
            msgid  => 'original',
            msgstr => 'translated',
        },
        {
            msgctxt => 'context',
            msgid   => 'c_original',
            msgstr  => 'c_translated',
        },
        {
            msgid         => 'o_singular',
            msgid_plural  => 'o_plural',
            msgstr_plural => [ qw(t_singular t_plural) ],
        },
        {
            msgctxt       => 'c_context',
            msgid         => 'c_o_singular',
            msgid_plural  => 'c_o_plural',
            msgstr_plural => [ qw(c_t_singular c_t_plural) ],
       },
    ],
)->write_file();

my $messages_result = Locale::MO::File->new(
    filename => $filename,
)->read_file()->get_messages();

() = print Data::Dumper->new([$messages_result], [qw(messages_result)])->Indent(1)->Dump();

# $Id: 12_build_header.pl 513 2010-07-29 15:16:57Z steffenw $

__END__

Output:

$messages_result = [
  {
    'msgid' => '',
    'msgstr' => 'MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Plural-Forms: nplurals=2; plural=n != 1;
'
  },
  {
    'msgctxt' => 'c_context',
    'msgid' => 'c_o_singular',
    'msgstr_plural' => [
      'c_t_singular',
      'c_t_plural'
    ],
    'msgid_plural' => 'c_o_plural'
  },
  {
    'msgctxt' => 'context',
    'msgid' => 'c_original',
    'msgstr' => 'c_translated'
  },
  {
    'msgid' => 'o_singular',
    'msgstr_plural' => [
      't_singular',
      't_plural'
    ],
    'msgid_plural' => 'o_plural'
  },
  {
    'msgid' => 'original',
    'msgstr' => 'translated'
  }
];
