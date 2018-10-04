#!perl -T
use 5.014;
use strict;
use warnings;

use File::Temp;
use Test::More;
use IO::ReadHandle::Chain;

my $skipped = 0;

# read when there are no sources

my $cfh = IO::ReadHandle::Chain->new();
is( $cfh->input_line_number, undef, 'no data, no line number' );
is( $cfh->current_source,    undef, 'no data, no current source' );
is( not( defined <$cfh> ),   1,     'no data' );
is( eof($cfh),               1,     'end of data' );
is( $cfh->eof,               1,     'end of data (OO)' );
$cfh->close;

# reading from scalars

my $source1 = "foo is better\nthan bar is\nby far!";
my $source2 = "text3\ntext4";
my $source3 = "text5\ntext6";

$cfh = IO::ReadHandle::Chain->new( \$source1 );

# foo is better\n
# than bar is\n
# by far!

is( $cfh->get_field('mykey'), undef, 'private key not defined' );
is( $cfh->get_field( 'mykey', 'DEFAULT' ),
  'DEFAULT', 'get private key with default' );
is( $cfh->get_field('mykey'), 'DEFAULT', 'private key now defined' );
is( $cfh->get_field( 'mykey', 'BAD!' ),
  'DEFAULT', 'private key default ignored if already defined' );
is( $cfh->set_field( 'key2', 'some value' ),
  $cfh, 'set private key returns self' );
is( $cfh->get_field('key2'), 'some value', 'private key set OK' );

my $state = [];
while (<$cfh>) {
  push @$state,
    {
    line            => $_,
    dot_line_number => $.,
    line_number     => $cfh->input_line_number,
    current_source  => $cfh->current_source,
    end_of_data     => eof($cfh),
    end_of_data_OO  => $cfh->eof,
    };
}

is( $cfh->get_field( 'mykey', 'DEFAULT' ), 'DEFAULT', 'private key unchanged' );
is( $cfh->get_field('key2'), 'some value', 'private key 2 unchanged' );
is( $cfh->remove_field('mykey'), $cfh,  'remove private key returns self' );
is( $cfh->get_field('mykey'),    undef, 'private key removal succeeded' );

$cfh->close;

is( $cfh->get_field('key2'), undef, 'close deletes private keys' );

my $title = 'source 1, separated by newline';
is_deeply(
  $state,
  [
    {
      line            => "foo is better\n",
      dot_line_number => 1,
      line_number     => 1,
      current_source  => 'SCALAR(foo is bet)',
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "than bar is\n",
      dot_line_number => 2,
      line_number     => 2,
      current_source  => 'SCALAR(foo is bet)',
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "by far!",
      dot_line_number => 3,
      line_number     => 3,
      current_source  => 'SCALAR(foo is bet)',
      end_of_data     => 1,
      end_of_data_OO  => 1,
    }
  ],
  $title
);

is( eof($cfh), 1, 'end of data' );
is( $cfh->eof, 1, 'end of data (OO)' );

# in list context

$cfh = IO::ReadHandle::Chain->new( \$source1 );
my @lines = <$cfh>;
$cfh->close;

is_deeply( \@lines, [ "foo is better\n", "than bar is\n", "by far!" ],
  'list context' );

# change record separator to 'is'
$/ = 'is';

$cfh   = IO::ReadHandle::Chain->new( \$source1 );
@lines = <$cfh>;
$cfh->close;

is_deeply(
  \@lines,
  [ "foo is", " better\nthan bar is", "\nby far!" ],
  'source 1, separated by "is"'
);

# change record separator to back to newline
$/ = "\n";

$cfh = IO::ReadHandle::Chain->new( \$source1, \$source2, \$source3 );

# [source1]foo is better\n
# [source1]than bar is\n
# [source1]by far![source2]text3\n
# [source2]text4[source3]text5\n
# [source3]text6

@lines = $cfh->getlines;
$cfh->close;

is_deeply(
  \@lines,
  [
    "foo is better\n",
    "than bar is\n",
    "by far!text3\n",
    "text4text5\n",
    "text6"
  ],
  'source 1, 2, 3'
);

# reading from files

my $tmp = File::Temp->new();
print $tmp $source1;
$tmp->flush;
$tmp->seek( 0, 0 );    # rewind

# read from a file through a file handle

$state = [];
$cfh = IO::ReadHandle::Chain->new( \$source2, $tmp, \$source3 );

# [source2]text3\n
# [source2]text4[tmp]foo is better\n
# [tmp]than bar is\n
# [tmp]by far![source3]text5\n
# [source3]text6

while (<$cfh>) {
  push @$state,
    {
    line            => $_,
    dot_line_number => $.,
    line_number     => $cfh->input_line_number,
    current_source  => $cfh->current_source,
    end_of_data     => eof($cfh),
    end_of_data_OO  => $cfh->eof,
    };
}
$cfh->close;

$title = 'file handle';
is_deeply(
  $state,
  [
    {
      line            => "text3\n",
      dot_line_number => 1,
      line_number     => 1,
      current_source  => 'SCALAR(text3 text)',
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "text4foo is better\n",
      dot_line_number => 2,
      line_number     => 2,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "than bar is\n",
      dot_line_number => 3,
      line_number     => 3,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "by far!text5\n",
      dot_line_number => 4,
      line_number     => 4,
      current_source  => 'SCALAR(text5 text)',
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "text6",
      dot_line_number => 5,
      line_number     => 5,
      current_source  => 'SCALAR(text5 text)',
      end_of_data     => 1,
      end_of_data_OO  => 1,
    },
  ],
  "text for $title"
);

$tmp->seek( 0, 0 );    # rewind

# read from file handle that isn't at the beginning

<$tmp>;

$cfh = IO::ReadHandle::Chain->new($tmp);

# than bar is\n
# by far!

@lines = <$cfh>;
$cfh->close;

is_deeply(
  \@lines,
  [ "than bar is\n", "by far!" ],
  'file handle in the middle'
);

# read from the file through the file name

my $filename = "$tmp";
$cfh = IO::ReadHandle::Chain->new( \$source2, $filename, \$source3 );

# [source2]text3\n
# [source2]text4[tmp]foo is better\n
# [tmp]than bar is\n
# [tmp]by far![source3]text5\n
# [source3]text6

$state = [];
while ( my $line = $cfh->getline ) {
  push @$state,
    {
    line            => $line,
    dot_line_number => $.,
    line_number     => $cfh->input_line_number,
    current_source  => $cfh->current_source,
    end_of_data     => eof($cfh),
    end_of_data_OO  => $cfh->eof,
    };
}
$cfh->close;

is_deeply(
  $state,
  [
    {
      line            => "text3\n",
      dot_line_number => 1,
      line_number     => 1,
      current_source  => 'SCALAR(text3 text)',
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "text4foo is better\n",
      dot_line_number => 2,
      line_number     => 2,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "than bar is\n",
      dot_line_number => 3,
      line_number     => 3,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "by far!text5\n",
      dot_line_number => 4,
      line_number     => 4,
      current_source  => 'SCALAR(text5 text)',
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => 'text6',
      dot_line_number => 5,
      line_number     => 5,
      current_source  => 'SCALAR(text5 text)',
      end_of_data     => 1,
      end_of_data_OO  => 1,
    },
  ],
  'file name'
);

# read from the file twice through the file name

$cfh = IO::ReadHandle::Chain->new( $filename, \$source2, $filename );

# [tmp]foo is better\n
# [tmp]than bar is\n
# [tmp]by far![source2]text3\n
# [source2]text4[tmp]foo is better\n
# [tmp]than bar is\n
# [tmp]by far!

$state = [];
while ( my $line = $cfh->getline ) {
  push @$state,
    {
    line            => $line,
    dot_line_number => $.,
    line_number     => $cfh->input_line_number,
    current_source  => $cfh->current_source,
    end_of_data     => eof($cfh),
    end_of_data_OO  => $cfh->eof,
    };
}
$cfh->close;

is_deeply(
  $state,
  [
    {
      line            => "foo is better\n",
      dot_line_number => 1,
      line_number     => 1,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "than bar is\n",
      dot_line_number => 2,
      line_number     => 2,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "by far!text3\n",
      dot_line_number => 3,
      line_number     => 3,
      current_source  => 'SCALAR(text3 text)',
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "text4foo is better\n",
      dot_line_number => 4,
      line_number     => 4,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "than bar is\n",
      dot_line_number => 5,
      line_number     => 5,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "by far!",
      dot_line_number => 6,
      line_number     => 6,
      current_source  => "$tmp",
      end_of_data     => 1,
      end_of_data_OO  => 1,
    }
  ],
  'file name twice'
);

# reading bytes

$cfh = IO::ReadHandle::Chain->new( \$source2 );

# text3\n
# text4

my $buffer = '';

is( $cfh->getc, 't', 'getc' );

my $n = read( $cfh, $buffer, 9 );

is( $n,      9,            'read 9 bytes' );
is( $buffer, "ext3\ntext", 'bytes' );

$n = $cfh->read( $buffer, 10, $n );

is( $n,      1,             'read next byte' );
is( $buffer, "ext3\ntext4", 'next bytes' );

$n = $cfh->read( $buffer, 100 );
is( $n,        0,  'nothing read' );
is( $buffer,   '', 'means empty buffer' );
is( $cfh->eof, 1,  'end of data (OO)' );
is( eof($cfh), 1,  'end of data' );

$cfh->close;

$cfh    = IO::ReadHandle::Chain->new( \$source2, "$tmp" );
$buffer = '';
$state  = [];
is( $cfh->input_line_number, undef, 'no line number for reading bytes' );
while ( $n = read( $cfh, $buffer, 10 ) ) {
  push @$state,
    {
    line            => $buffer,
    dot_line_number => $.,
    line_number     => $cfh->input_line_number,
    current_source  => $cfh->current_source,
    end_of_data     => eof($cfh),
    end_of_data_OO  => $cfh->eof,
    };
}
$cfh->close;

is_deeply(
  $state,
  [
    {
      line            => "text3\ntext",
      dot_line_number => 0,
      line_number     => undef,
      current_source  => 'SCALAR(text3 text)',
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => '4foo is be',
      dot_line_number => 0,
      line_number     => undef,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "tter\nthan ",
      dot_line_number => 0,
      line_number     => undef,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => "bar is\nby ",
      dot_line_number => 0,
      line_number     => undef,
      current_source  => "$tmp",
      end_of_data     => '',
      end_of_data_OO  => '',
    },
    {
      line            => 'far!',
      dot_line_number => 0,
      line_number     => undef,
      current_source  => "$tmp",
      end_of_data     => 1,
      end_of_data_OO  => 1,
    },
  ],
  'bytes from scalar and file handle'
);

# sysread

$tmp->seek( 0, 0 );    # back to the beginning

$cfh    = IO::ReadHandle::Chain->new($tmp);
$buffer = '';
$n      = sysread( $cfh, $buffer, 10 );

is( $n,      10,           'sysread 10 bytes' );
is( $buffer, "foo is bet", 'bytes' );

# writing fails

$cfh = IO::ReadHandle::Chain->new($tmp);
$@   = '';
eval { print $cfh "Oh, no!\n"; };
like( $@,
  qr/^Can't locate object method "PRINT" via package "IO::ReadHandle::Chain"/,
  'print fails' );

$@ = '';
eval { printf $cfh '%s', 'foo'; };
like(
  $@,
  qr/^Can't locate object method "PRINTF" via package "IO::ReadHandle::Chain"/,
  'printf fails'
);

$@ = '';
eval { $cfh->syswrite( $buffer, 5 ) };
like(
  $@,
qr/^Can't locate object method "syswrite" via package "IO::ReadHandle::Chain"/,
  'printf fails'
);

# seeking fails

$@ = '';
eval { $cfh->seek( 0, 0 ) };
like( $@,
  qr/^Can't locate object method "seek" via package "IO::ReadHandle::Chain"/,
  'printf fails' );

# reading from hash fails

$@ = '';
eval { $cfh = IO::ReadHandle::Chain->new( {} ) };
like(
  $@,
  qr/^Sources must be scalar, scalar reference, or file handle/,
  'hash ref fails'
);

# reading from a write-only file handle yields nothing

my $fname = 'IO-functionality-temp.txt';
@lines = ();
if ( open my $ofh, '>', $fname ) {
  print $ofh "Some text\n";
  seek( $ofh, 0, 0 );
  $@     = '';
  $cfh   = IO::ReadHandle::Chain->new($ofh);
  @lines = <$cfh>;
  close $ofh;
  unlink $fname;
  is_deeply( \@lines, [], 'read nothing from write-only file handle' );
}
else {
  diag("Cannot open $fname for writing: $!");
  ++$skipped;
}

done_testing( 45 - $skipped );
