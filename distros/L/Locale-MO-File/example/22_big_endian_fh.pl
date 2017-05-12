#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(confess);
require Data::Dumper; # to visualize output only
use English qw(-no_match_vars $OS_ERROR);
use IO::File qw(SEEK_SET);
require Locale::MO::File;

my $filename = '22_big_endian_fh.mo';

my $file_handle = IO::File->new($filename, '+> :raw')
    or confess "Can not open $filename\n$OS_ERROR";

# The content of the "messages" array reference is first sorted and then written.
# The transferred "messages" array reference remains unchanged.
# A given file handle is used but not closed.
# The example 24_... shows you how to handle encoding and newline.
Locale::MO::File->new(
    filename      => $filename,
    file_handle   => $file_handle,
    is_big_endian => 1,
    messages      => [
        {
            msgid  => q{},
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

$file_handle->seek(0, SEEK_SET)
    or confess "Can not seek $filename\n$OS_ERROR";

my $messages_result = Locale::MO::File->new(
    filename    => $filename,
    file_handle => $file_handle,
)->read_file()->get_messages();

$file_handle->close()
    or confess "Can not close $filename\n$OS_ERROR";

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
