package File::Shuffle;

use strict;
use warnings;
use File::Temp qw(tempdir);
use Sort::External;
use Data::Dump qw(dump);

BEGIN
{
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '0.10';
	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	@EXPORT_OK   = qw(fileShuffle);
	%EXPORT_TAGS = ();
}

#01234567890123456789012345678901234567891234
#Randomly shuffle the lines in a file.

=head1 NAME

C<File::Shuffle> - Randomly shuffle the lines in a file.

=head1 SYNOPSIS

  use File::Temp qw(tempfile);
  use File::Shuffle qw(fileShuffle);
  use Data::Dump qw(dump);
  my ($handle, $inputFile) = tempfile();
  print $handle join("\n", 0..9, '');
  close $handle;
  fileShuffle (inputFile => $inputFile);
  open ($handle, '<', $inputFile);
  my @lines = <$handle>;
  close $handle;
  print @lines;

=head1 DESCRIPTION

C<File::Shuffle> provides the routine C<fileShuffle> to randomly shuffle the lines
in a file.

=head1 SUBROUTINES

=head2 C<fileShuffle>

The subroutine C<fileShuffle> randomly shuffles the lines in a file with
the following parameters:

=over

=item C<inputFile>

  inputFile => '...'

C<inputFile> holds the path to the file whose lines are to be shuffled; if it does
not exist or if it is not a file an exception is thrown.

=item C<outputFile>

  outputFile => '...'

C<outputFile> is the file the shuffled lines are to be written to, it may equal
C<inputFile>; the default is C<inputFile>.

=item C<tempDirectory>

  tempDirectory => File::Temp::tempdir()

C<tempDirectory> is a temporary directory that intermediate files are written to if the C<inputFile>
is too large to shuffle using only internal memory; the default
is set using L<File::Temp::tempdir()|File::Temp/FUNCTIONS>.

=item C<encoding>

  encoding => ''

C<encoding> is the encoding to used when openning the input and output files; the default is the
the system default of the Perl C<open> function.

=item C<fileSizeBound>

  fileSizeBound => 1000000

If the input file contains less than C<fileSizeBound> bytes, the file will be shuffled entirely using
internal memory, otherwise L<Sort::External> is used to shuffle the lines in the file.

=back

=cut

sub fileShuffle
{
	my (%Parameters) = @_;

	# make sure the input file was defined.
	unless (exists($Parameters{inputFile}) && defined($Parameters{inputFile}))
	{
		die("error: inputFile parameter is undefined.\n");
	}
	my $InputFile = $Parameters{inputFile};

	# make sure the input files was defined.
	unless (defined $InputFile)
	{
		die("error: input file undefined.\n");
	}

	# make sure the input file exists.
	unless (-e $InputFile)
	{
		die("error: input file '$InputFile' does not exist.\n");
	}

	# make sure the input file is a file.
	unless (-f $InputFile)
	{
		die("error: input file '$InputFile' is not a file.\n");
	}

	# set the default encoding to utf8.
	my $Encoding = '';
	$Encoding = $Parameters{encoding} if (exists($Parameters{encoding}) && defined($Parameters{encoding}));

	# ensure the encoding is prefixed with a colon.
	$Encoding = ':' . $Encoding if (length($Encoding) && (substr($Encoding, 0, 1) ne ':'));

	# set the default file size bound.
	my $FileSizeBound = 1000000;
	$FileSizeBound = int abs $Parameters{fileSizeBound} if (exists($Parameters{fileSizeBound}) && defined($Parameters{fileSizeBound}));

	# set the temp directory if defined.
	my $TempDirectory;
	$TempDirectory = $Parameters{tempDirectory} if (exists($Parameters{tempDirectory}) && defined($Parameters{tempDirectory}));

	# set the temp directory if defined.
	my $OutputFile = $InputFile;
	$OutputFile = $Parameters{outputFile} if (exists($Parameters{outputFile}) && defined($Parameters{outputFile}));

	# open the input file for reading only.
	my $inputFileHandle;
	unless (open($inputFileHandle, "<$Encoding", $InputFile))
	{
		die("could not open file '$InputFile' for reading: $!\n");
	}

	# get the size of the file.
	my $inputFileBytes = -s $InputFile;

	# small files are shuffled like an internal array.
	if ($inputFileBytes <= $FileSizeBound)
	{

		# the file is small enough to read into memory and shuffle.
		shuffleInternal($inputFileHandle, $OutputFile, $Encoding);
	}
	else
	{
		# the file is too large to read in, so shuffle via a random prefix and sort.

		# create and set the temporary directory if needed.
		$TempDirectory = tempdir(CLEANUP => 1) unless defined $TempDirectory;

		# shuffle the file via sorting.
		shuffleExternal($inputFileHandle, $OutputFile, $Encoding, $TempDirectory, $inputFileBytes);
	}

	return undef;
}

sub shuffleInternal
{
	my ($InputHandle, $OutputFile, $Encoding) = @_;

	# read in all the lines of the file.
	my @linesInFile = <$InputHandle>;

	# close the input file.
	close $InputHandle;

	# shuffle the lines.
	my $totalLines = @linesInFile;
	for (my $i = 0 ; $i < $totalLines ; $i++)
	{

		# select a random line to swap $i with.
		my $j = int rand $totalLines;

		# save the line at $j.
		my $lineAtj = $linesInFile[$j];

		# replace line at $j with $i.
		$linesInFile[$j] = $linesInFile[$i];

		# replace line at $i with $j.
		$linesInFile[$i] = $lineAtj;
	}

	# open the output file for writing only.
	my $outputFileHandle;
	unless (open($outputFileHandle, ">$Encoding", $OutputFile))
	{
		die("could not open file '$OutputFile' for writing: $!\n");
	}

	# output the shuffled lines.
	for (my $i = 0 ; $i < $totalLines ; $i++)
	{
		print $outputFileHandle $linesInFile[$i];
		$linesInFile[$i] = undef;
	}

	# close the output file.
	close $outputFileHandle;

	return undef;
}

sub shuffleExternal
{
	use bytes;

	my ($InputHandle, $OutputFile, $Encoding, $TempDirectory, $InputFileBytes) = @_;

	# set the prefix size.
	my $prefixByteSize = getPrefixByteSize($InputFileBytes);

	# create the sorter.
	my $sorter = Sort::External->new(mem_threshold => 64 * 1024 * 1024, working_dir => $TempDirectory);

	# add each line to the sorter prefixed with a random string of $prefixByteSize bytes.
	while (defined(my $line = <$InputHandle>))
	{

		# feed the prefix and line to the sorter.
		$sorter->feed(getRandomString($prefixByteSize) . $line);
	}

	# close the input file.
	close $InputHandle;

	# finish the sorting.
	$sorter->finish();

	# open the output file for writing only.
	my $outputFileHandle;
	unless (open($outputFileHandle, ">$Encoding", $OutputFile))
	{
		die("could not open file '$OutputFile' for writing: $!\n");
	}

	while (defined(my $prefixedLine = $sorter->fetch))
	{

		# write the original line to the output file.
		print $outputFileHandle substr($prefixedLine, $prefixByteSize);
	}
	$sorter = undef;

	# close the output file.
	close $outputFileHandle;

	return undef;
}

sub getPrefixByteSize
{
	my ($BytesInFile) = @_;

	# make sure the total bytes is a non-negative integer.
	$BytesInFile = int abs $BytesInFile;

	# if less than two, return zero.
	return 0 if $BytesInFile < 2;

	# assume each line in the file is at least two bytes;
	# compute the number of bits needed to represent the
	# maximum possible number of lines.
	my $maxPrefixBits = log(abs($BytesInFile) + 1) / log(2) - 1;
	$maxPrefixBits = 1 if $maxPrefixBits < 1;
	$maxPrefixBits = int $maxPrefixBits;

	# compute the number of bytes needed for the prefixes.
	my $bytesInPrefix = int(($maxPrefixBits + 7) / 8);

	return $bytesInPrefix;
}

sub getRandomString
{

	# get the number of bytes in the string.
	my $totalBytes = $_[0];

	# get the number of shorts in the string.
	my $totalShorts = $totalBytes >> 1;

	# generate the shorts.
	my @listOfShorts;
	while ($totalShorts > 0)
	{
		push @listOfShorts, pack('S', int rand(1 << 16));
		--$totalShorts;
	}

	# if totalBytes is odd, add one more random byte.
	push @listOfShorts, pack('C', int rand(1 << 8)) if $totalBytes & 1;

	# return the string.
	return join('', @listOfShorts);
}

=head1 INSTALLATION

Use L<CPAN> to install the module and all its prerequisites:

  perl -MCPAN -e shell
  cpan[1]> install File::Shuffle

=head1 BUGS

Please email bugs reports or feature requests to C<bug-file-shuffle@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Shuffle>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

file, permute, randomize, shuffle

=head1 SEE ALSO

L<Sort::External>

=cut

1;

# The preceding line will help the module return a true value
