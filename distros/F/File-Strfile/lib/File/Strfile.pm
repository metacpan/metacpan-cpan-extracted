package File::Strfile;
our $VERSION = '0.03';
use 5.016;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%STRFLAGS);

use Carp;
use File::Spec;
use List::Util qw(shuffle sum);

our %STRFLAGS = (
	RANDOM  => 0x1,
	ORDERED => 0x2,
	ROTATED => 0x4,
);

my @VERSIONS = (1, 2);

my $STRFILE_HDR_LEN = 24;

# Strfile header format:
#   uint32   version;
#   uint32   strnum;
#   uint32   longest str len;
#   uint32   shortest str len;
#   uint32   flags; (see %STRFLAGS)
#   uint8[4] long-aligned space
#            [0] is delimit char
# Header is Big-Endian.

sub new {

	my $class = shift;
	my $src   = shift;
	my $param = shift;
	my $self = {
		SrcFile  => File::Spec->rel2abs($src),
		_srcfh   => undef,
		Version  => 1,
		StrNum   => 0,
		LongLen  => 0,
		ShortLen => 0xffffffff,
		Flags    => 0,
		Delimit  => '%',
		Offsets  => [],
	};

	bless $self, $class;

	open $self->{_srcfh}, '<', $self->{SrcFile}
		or croak "Failed to open $self->{SrcFile} for reading: $!";

	if ($param->{DataFile}) {

		$self->read_strfile($param->{DataFile});

	} else {

		$self->_create_strfile_data();

		if ($param->{Delimit}) {
			$self->{Delimit} = unpack "a", $param->{Delimit};
		}

	}

	if (defined $param->{Version}) {
		croak "$param->{Version} is an invalid strfile version"
			unless _version_check($param->{Version});
		$self->{Version} = $param->{Version};
	}

	# Order flag gets priority over Random
	if ($param->{FcOrder}) {
		$self->order(1);
	} elsif ($param->{Order}) {
		$self->order();
	} elsif ($param->{Random}) {
		$self->random();
	}

	$self->{Flags} |= $STRFLAGS{ROTATED} if $param->{Rotate};

	return $self;

}

sub _version_check {

	my $ver = shift;

	return (grep { $ver == $_ } @VERSIONS) ? 1 : 0;

}

sub _create_strfile_data {

	my $self = shift;

	seek $self->{_srcfh}, 0, 0;

	# Each offset table must start with 0x00
	push @{$self->{Offsets}}, tell $self->{_srcfh};

	my $coff = 0;
	my $loff = 0;

	my $curlen = 0;

	my $l = '';

	while (defined $l) {

		$l = readline $self->{_srcfh};

		if (not defined $l or $l eq "$self->{Delimit}\n") {

			$coff = tell $self->{_srcfh};
			$curlen = $coff - $loff - (length $l // 0);
			$loff = $coff;

			next unless $curlen;

			push @{$self->{Offsets}}, $coff;
			$self->{StrNum}++;

			if ($curlen < $self->{ShortLen}) {
				$self->{ShortLen} = $curlen;
			}
			
			if ($curlen > $self->{LongLen}) {
				$self->{LongLen} = $curlen;
			}
		}

	}

	$self->{Version} = 1;

}

sub read_strfile {

	my $self = shift;
	my $file = shift;

	open my $fh, '<', $file or croak "Failed to open $file for reading: $!";
	binmode $fh;

	read $fh, my ($buf), $STRFILE_HDR_LEN;

	(
		$self->{Version},
		$self->{StrNum},
		$self->{LongLen},
		$self->{ShortLen},
		$self->{Flags},
		$self->{Delimit},
		# We're ignoring 3 padding bytes
	) = unpack "N N N N N a", $buf;

	unless (_version_check($self->{Version})) {
		croak "$file bogus strfile";
	}

	if ($self->{LongLen} < $self->{ShortLen}) {
		croak "$file bogus strfile";
	}

	if ($self->{Flags} > sum values %STRFLAGS) {
		croak "$file bogus strfile";
	}

	$self->{DataFile} = $file;

	$self->{Offsets} = [];

	foreach my $i (0 .. $self->{StrNum}) {
		my $off;
		# v1 strfiles use 64-bit offsets
		if ($self->{Version} == 1) {
			read $fh, $off, 8;
			(my ($u), $self->{Offsets}->[$i]) = unpack "N N", $off;
			croak "Offset $i exceeds 4GB" if $u;
		# v2 strfiles use 32-bit offsets
		} elsif ($self->{Version} == 2) {
			read $fh, $off, 4;
			$self->{Offsets}->[$i] = unpack "N", $off;
		}

	}

	close $fh;

}

sub order {

	my $self = shift;
	my $fc   = shift;

	# Ignore leading non-alphanumeric characters.
	my @strings = map { s/^[\W_]+//r } $self->strings();
	@strings = map { fc } @strings if $fc;

	my @offsets =
		map  { $self->{Offsets}->[$_] }
		sort { $strings[$a] cmp $strings[$b] } (0 .. $self->{StrNum} - 1);

	push @offsets, $self->{Offsets}->[$self->{StrNum}];

	$self->{Offsets} = \@offsets;

	$self->{Flags} |= $STRFLAGS{ORDERED};

}

sub random {

	my $self = shift;

	my @offsets = map {
		$self->{Offsets}->[$_]
	} shuffle(0 .. $self->{StrNum} - 1);

	push @offsets, $self->{Offsets}->[$self->{StrNum}];

	$self->{Offsets} = \@offsets;

	$self->{Flags} |= $STRFLAGS{RANDOM};

	# Unset Ordered flag, as it takes priority over Random
	if ($self->{Flags} & $STRFLAGS{ORDERED}) {
		$self->{Flags} -= $STRFLAGS{ORDERED};
	}

}

sub string {

	my $self = shift;
	my $n    = shift;

	return undef if $n >= $self->{StrNum};

	seek $self->{_srcfh}, $self->{Offsets}->[$n], 0;

	my $string = '';
	my $l = '';
	while (defined $l) {

		$l = readline $self->{_srcfh};

		last if not defined $l or $l eq "$self->{Delimit}\n";

		$string .= $l;

	}

	# ROT13
	$string =~ tr/A-Za-z/N-ZA-Mn-za-m/ if $self->{Flags} & $STRFLAGS{ROTATED};

	return $string;

}

sub strings {

	my $self = shift;

	return map { $self->string($_) } (0 .. $self->{StrNum} - 1);

}

sub strings_like {

	my $self = shift;
	my $re   = shift;

	return grep { /$re/m } $self->strings();

}

sub get {

	my $self = shift;
	my $get  = shift;

	return undef if $get =~ /^_/ or not defined $self->{$get};

	return $self->{$get};

}

sub write_strfile {

	my $self = shift;
	my $file = shift // "$self->{SrcFile}.dat";

	open my $fh, '>', $file or croak "Failed to open $file for writing: $!";
	binmode $fh;

	my $hdr = pack "N N N N N c x x x", (
		$self->{Version},
		$self->{StrNum},
		$self->{LongLen},
		$self->{ShortLen},
		$self->{Flags},
		ord $self->{Delimit},
	);

	print { $fh } $hdr;

	foreach my $i (0 .. $self->{StrNum}) {

		my $off;
		if ($self->{Version} == 1) {
			$off = pack "N N", (0, $self->{Offsets}->[$i]);
		} elsif ($self->{Version} == 2) {
			$off = pack "N", $self->{Offsets}->[$i];
		}

		print { $fh } $off;

	}

	close $fh;

}

DESTROY {

	my $self = shift;

	close $self->{_srcfh};

}

1;



=head1 NAME

File::Strfile - OO strfile interface

=head1 SYNOPSIS

  use File::Strfile;

  $strfile = File::Strfile->new($src);

  $strfile->read_strfile($datafile);

  $strfile->random();

  $strfile->order();

  $str0 = $strfile->string(0);

  foreach my $str ($strfile->strings()) {
    ...
  }

  $strfile->write_strfile($datafile);

=head1 DESCRIPTION

File::Strfile provides an object oriented interface for reading and writing
strfiles, a file format often associated with the classic UNIX program
L<fortune(6)>. Strfiles are used to provide random access to strings stored in
another file, called the strfile source. The source files
consists of a collection of strings seperated by delimiting lines, which are
lines containing only a single delimiting character, typically a percentage (%)
sign. The strfile data
files are usually stored in the same directory as the source files, with the
same name but with the ".dat" suffix added. They contain a header that describes
the strfile database and a table of offsets pointing to each string in the
source file.

This module only provides an interface for manipulating strfile data files, not
the source text files themselves.

=head1 Object Methods

=head2 File::Strfile->new($srcpath, [{opt => 'val'}])

Returns a new File::Strfile object. $srcpath is the path to the source strfile.

new() can be given a hash reference of options. Note that all options are
case-sensitive.

=over 4

=item DataFile

Path to the strfile-generated data file. Instead of new() creating strfile data
from scratch, it will read data the from the given data file by calling
read_strfile(). Some fields can be overrided by passing additional options.

=item Version

Set version for outputted strfile. The following are acceptable version numbers:

=over 4

=item 1

Original strfile version. Stores string offsets as unsigned 64-bit integars.
Most common. Default.

=item 2

Newer strfile version. Stores string offsets as unsigned 32-bit integars.

=back

=item Random

Randomize the order of string offsets.

=item Order

Order string offsets alphabetically.

=item FcOrder

Order string offsets alphabetically, case-insensitive.

=item Rotate

Mark the source file as being ROT-13 ciphered.

=item Delimit

Set delimitting character. Default is a percentage sign (%). This option does
not work with the DataFile option.

=back

new() dies upon failure.

=head2 $strfile->read_strfile($file)

Read strfile data from $file.

=head2 $strfile->order([$fc])

Order strings alphabetically. If $fc is true, sort is done insensitive to case.

=head2 $strfile->random()

Randomize the order of strings.

=head2 $strfile->string($n)

Get $n-th string from string file. Returns undef if $n-th string does not exist.

=head2 $strfile->strings()

Returns list of all strings in strfile, in the order specified by the offset
table.

=head2 $strfile->strings_like($re)

Return list of strings that evaluate true given the qr regex $re.

For example, to get every string that starts with 'YOW!':

  my @yows = $strfile->strings_like(qr/^YOW!/)

Note that the 'm' (multiline) option is automatically used and does not need
to be specified.

=head2 $strfile->get($member)

Return value of $member in $strfile object. Note $member is case-sensitive. 
The following are valid members:

=over 4

=item SrcFile

Absolute path to strfile source file.

=item Version

Version of $strfile.

=item StrNum

Number of strings in $strfile.

=item LongLen

Length (in bytes) of the longest string in $strfile.

=item ShortLen

Length (in bytes) of the shortest string in $strfile.

=item Flags

Flag bitfield for $strfile. See documentation for %STRFLAGS for what each
bitmask means.

=item Delimit

Delimitting character.

=item Offsets

Array ref of strfile offsets. The last offset will not be a string offset but
the EOF offset. 

=back

On failure, get() returns undef.

=head2 $strfile->write_strfile([$file])

Write $strfile data file to either $file. If $file is not supplied, write to
source file path + '.dat' suffix.

=head1 Global Variables

=over 4

=item $File::Strfile::VERSION

File::Strfile version.

=item %File::Strfile::STRFLAGS

Hash of strfile flags and their bitmasks.

=over 4

=item RANDOM => 0x1

Strings were randomly sorted.

=item ORDERED => 0x2

Strings were sorted alphabetically. Takes priority over Random.

=item ROTATED => 0x4

Strings are ROT-13 ciphered.

=back

Able to be exported.

  use File::Strfile qw(%STRFLAGS);

=back

=head1 EXAMPLES

Here is an example of a typical source strfile:

  A can of ASPARAGUS, 73 pigeons, some LIVE ammo, and a FROZEN DAIQUIRI!!
  %
  A dwarf is passing out somewhere in Detroit!
  %
  A wide-eyed, innocent UNICORN, poised delicately in a MEADOW filled
  with LILACS, LOLLIPOPS & small CHILDREN at the HUSH of twilight??
  %
  Actually, what I'd like is a little toy spaceship!!

=head1 RESTRICTIONS

Despite version 1 strfiles storing string offsets as unsigned 64-bit integars,
they are still read as 32-bit. This means that File::Strfile will not be
able to read strfile sources
larger than 4GB (about the size of 1,000 plaintext KJV Bibles).

File::Strfile tries to emulate the original BSD strfile's behavior as close as
possible, which means it will also inherit some of its quirks.

=head1 AUTHOR

Written by Samuel Young E<lt>L<samyoung12788@gmail.com>E<gt>.

=head1 COPYRIGHT

Copyright 2024, Samuel Young

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<fortune(6)>, L<strfile(8)>

=cut
