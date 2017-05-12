package Graph::Undirected::Components::External;
use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir tempfile);
use Sort::External;
use Text::CSV;
use Log::Log4perl;
use Graph::Undirected::Components;
use Time::HiRes;
#use Data::Dump qw(dump);

BEGIN
{
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '0.31';
	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = ();
}

my $el = "\n";

#01234567890123456789012345678901234567891234
#Computes components of an undirected graph.

=head1 NAME

C<Graph::Undirected::Components::External> - Computes components of an undirected graph.

=head1 SYNOPSIS

  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  use Graph::Undirected::Components::External;
  Log::Log4perl->easy_init ($WARN);
  my $componenter = Graph::Undirected::Components::External->new(outputFile => 'vertexCompId.txt', purgeSizeBytes => 5000);
  my $vertices = 10000;
  for (my $i = 0; $i < $vertices; $i++)
  {
    $componenter->add_edge (int rand $vertices, int rand $vertices);
  }
  dump $componenter->finish ();

=head1 DESCRIPTION

C<Graph::Undirected::Components::External> computes the components of an undirected
graph limited only by the amount of free disk space. All errors, warnings, and
informational messages are logged using L<Log::Log4perl>.

=head1 CONSTRUCTOR

=head2 C<new>

The method C<new> creates an instance of C<Graph::Undirected::Components::External>
with the following parameters.

=over

=item C<workingDirectory>

  workingDirectory => File::Temp::tempdir()

C<workingDirectory> is an optional parameter specifying the path
to a directory that all temporary files are written to; the default
is set using L<File::Temp::tempdir()|File::Temp/FUNCTIONS>.


=item C<purgeSizeBytes>

  purgeSizeBytes => 1000000

C<purgeSizeBytes> is an optional parameter specifying the aggregate byte size
that all the vertices added to the internal instance of
L<Graph::Undirected::Components> must exceed before its content is purged
to disk. The optimal value depends on the total internal memory
available.

=item C<purgeSizeVertices>

  purgeSizeVertices => undef

C<purgeSizeVertices> is an optional parameter specifying the total
vertices added to the internal instance of
L<Graph::Undirected::Components> that must be exceed before its content is purged
to disk. If C<purgeSizeBytes> and C<purgeSizeVertices> are both defined, then a purge
occurs when either threshold is exceeded.

=item C<retainPercentage>

  retainPercentage => 0.10

C<retainPercentage> is an optional parameter specifying the percentage of
the most recently used vertices to be retained in the internal instance of
L<Graph::Undirected::Components> when it is purged. If the edges of the
graph are not added in a random order, caching some of the vertices can
speedup the computation of the components.

=item C<outputFile>

  outputFile => ...

C<outputFile> is the path to the file that the C<(vertex,component-id)> pairs
are written to separated by the C<delimiter>; the directory of the file should exist. An exception is
thrown if C<outputFile> is undefined or the file cannot be written to.

=item C<delimiter>

  delimiter => ','

C<delimiter> is the delimiter used to separate the vertices of an edge when
they are written to temporary files. All vertices should be encoded so that
they do not contain the delimiter, that is, it should be true that
C<index($vertex,$delimiter)==-1> for all vertices.

=back

=cut

sub new
{

	# get the object type and parameters.
	my ($Class, %Parameters) = @_;
	my $Self = bless({}, ref($Class) || $Class);

	# set the flag when finished is called so no more edges are added.
	$Self->{finishedCalled} = 0;

	# set the start time.
	$Self->{startTime} = $Self->getCpuTime();

	# flag if temporary files and directories should be deleted;
	# used for debugging.
	$Self->{cleanup} = 1;

	# set the default delimiter for the input and output files.
	$Self->{delimiter} = ',';
	$Self->{delimiter} = $Parameters{delimiter} if exists $Parameters{delimiter};

	# set the recursion level
	$Self->{level} = 0;
	$Self->{level} = $Parameters{level} if (exists($Parameters{level}) && defined($Parameters{level}));

	# set the workingDirectory and create it if needed.
	if (exists($Parameters{baseDirectory}))
	{
		$Self->{baseDirectory} = $Parameters{baseDirectory};
	}
	else
	{
		my $workingDirectory;
		if (exists($Parameters{workingDirectory}) && defined($Parameters{workingDirectory}))
		{

			# if the directory does not exist created it.
			unless (-d $Parameters{workingDirectory})
			{
				make_path($Parameters{workingDirectory}, { verbose => 0, mode => 0700 });
				$Self->{unlinkWorkingDirectory} = 1;
			}

			$workingDirectory = $Parameters{workingDirectory};
		}
		else
		{

			# none given as a parameters, so create a temporary one.
			$workingDirectory = tempdir(CLEANUP => $Self->{cleanup}) unless defined $workingDirectory;
		}

		# if the directory does not exist log an error and die.
		unless (-e $workingDirectory)
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie("error: could not create directory '$workingDirectory'.\n");
		}

		# if workingDirectory is not a directory log an error and die.
		unless (-d $workingDirectory)
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie("error: '$workingDirectory' is not a directory.\n");
		}

		# now create the base directory in the working directory.
		my $baseDirectory = tempdir(DIR => $workingDirectory, CLEANUP => $Self->{cleanup});

		# if $baseDirectory is not a directory log an error and die.
		unless (-d $baseDirectory)
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie("error: $baseDirectory is not a directory.\n");
		}
		$Self->{baseDirectory} = $baseDirectory;
	}

	# create the object to compute the components using internal memory.
	$Self->{componenter} = Graph::Undirected::Components->new();

	# set the purge size of the componenter.
	my $purgeSizeBytes = 1000000;
	$purgeSizeBytes = int abs $Parameters{purgeSizeBytes} if exists($Parameters{purgeSizeBytes}) && defined($Parameters{purgeSizeBytes});
	$Self->{purgeSizeBytes}                = $purgeSizeBytes;
	$Self->{purgeSizeVertices} = int abs $Parameters{purgeSizeVertices} if exists($Parameters{purgeSizeVertices}) && defined($Parameters{purgeSizeVertices});
	$Self->{totalEdgesAddedSinceLastPurge} = 0;
  $Self->{totalEdges}                    = 0;
  $Self->{totalVertices}                 = 0;

	# set the percentage of vertices to retain in the componenter when purging.
	my $retainPercentage = 0.10;
	$retainPercentage = abs $Parameters{retainPercentage}
		if (exists($Parameters{retainPercentage}) && defined($Parameters{retainPercentage}));
	$retainPercentage = 1 if $retainPercentage > 1;
	$Self->{retainPercentage} = $retainPercentage;

	# set the file that the "vertex,compId" pairs will be written to.
	unless (exists($Parameters{outputFile}) && defined($Parameters{outputFile}))
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->logdie("error: parameter outputFile was not defined.\n");
	}
	$Self->{outputFile} = $Parameters{outputFile};

	# make sure we can write to the output file before devoting time to
	# computing the connected components.
	{
		my $outputFileHandle;
		unless (open($outputFileHandle, '>', $Self->{outputFile}))
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie("error: could not open file '$Self->{outputFile}' for writing.\n");
		}
		close $outputFileHandle;
	}
	unlink $Self->{outputFile};

	return $Self;
}

=head1 METHODS

=head2 C<add_edge (vertexA, vertexB)>

The method C<add_edge> updates the components of the graph using the edge
C<(vertexA, vertexB)>.

=over

=item vertexA, vertexB

The vertices of the edge C<(vertexA, vertexB)> are Perl strings. If only C<vertexA>
is defined, then the edge C<(vertexA, vertexA)> is added to the graph. The method always returns
undef.

=back

=cut

sub add_edge
{
	my ($Self, @Edge) = @_;

	# if nothing to add return now.
	return undef unless @Edge;

	if ($Self->{finishedCalled})
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->logdie("error: cannot add more edges after call to finish().\n");
	}

	$Self->{componenter}->add_edge(@Edge);
	++$Self->{totalEdgesAddedSinceLastPurge};
	++$Self->{totalEdges};

	# if componenter is too large, purge it to disk.
	if
	(
    ($Self->{componenter}->getSizeBytes() > $Self->{purgeSizeBytes}) ||
    ((exists $Self->{purgeSizeVertices}) && ($Self->{componenter}->getSizeVertices() > $Self->{purgeSizeVertices}))
	)
	{
    # add the root node pairs to the external component finder.
    $Self->purge($Self->{retainPercentage});
	}

	return undef;
}

=head2 C<add_file>

The method C<add_file> adds all the edges in a file to the graph.

=over

=item fileOfEdges => ...

C<fileOfEdges> specifies the path to the file containing the edges to
add. An exception is thrown if there are problems openning or reading the file.

=item delimiter

The edges are read from C<fileOfEdges> using L<Text::CSV>; C<delimiter>
must be to the delimiter used to separate the vertices of an edge in the file. The default
is the value set with the L</new> constructor.

=back

=cut

sub add_file
{
	my ($Self, %Parameters) = @_;

	# if no fileOfEdges, return now.
	if (!exists ($Parameters{fileOfEdges}) || !defined ($Parameters{fileOfEdges}))
	{
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie("error: parameter 'fileOfEdges' was not defined.\n");
	}
	my $fileOfEdges = $Parameters{fileOfEdges};

	# set the default delimiter.
	my $delimiter = $Self->{delimiter};
	$delimiter = $Parameters{delimiter} if exists $Parameters{delimiter};

	# make sure the file exists.
	my $fileOfEdgesHandle;
	unless (open($fileOfEdgesHandle, '<:encoding(utf8)', $fileOfEdges))
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->logdie("error: could not open file '$fileOfEdges' for reading: $!\n");
	}

	# create the CSV parser.
	my $csvParser = Text::CSV->new({ binary => 1, sep_char => $delimiter });
	unless ($csvParser)
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->logdie("error: could not open CSV parser; " . Text::CSV->error_diag() . "\n");
	}

	# add each edge in the file to the graph.
	while (my $edge = $csvParser->getline($fileOfEdgesHandle))
	{

		# if no edge, skip it.
		next unless defined $edge;

		# if the first column is empty, skip it.
		next unless exists($edge->[0]) && defined($edge->[0]);

		# if the second column is emtpy, set it to the first.
		$edge->[1] = $edge->[0] if (!exists($edge->[1]) || !defined($edge->[1]));

		# add the edge.
		$Self->add_edge($edge->[0], $edge->[1]);
	}
	close $fileOfEdgesHandle;

	return undef;
}

sub purge
{
	my ($Self, $RetainPercentage) = @_;

	# set the default for the percentage of vertices retained in vertexCompIdSorter.
	$RetainPercentage = 0 unless defined $RetainPercentage;

	# create the vertexCompIdSorter if it does not exist.
	unless (exists $Self->{vertexCompIdSorter})
	{
		$Self->{vertexCompIdSorter} = Sort::External->new(mem_threshold => 64 * 1024 * 1024, working_dir => $Self->{baseDirectory});
	}

	# get the list of vertexCompIds.
	$RetainPercentage = 0 if $Self->{totalEdgesAddedSinceLastPurge} < 2;
	my $listOfVertexCompIds = $Self->{componenter}->get_vertexCompIdPairs($RetainPercentage);
	my $totalVertexCompIds  = scalar(@$listOfVertexCompIds);

	# add each vertexCompId to the external sorter.
	for (my $i = 0 ; $i < $totalVertexCompIds ; $i++)
	{
		my $vertexCompIdString = $listOfVertexCompIds->[$i][0] . $Self->{delimiter} . $listOfVertexCompIds->[$i][1];
		$Self->{vertexCompIdSorter}->feed($vertexCompIdString);
	}
	$listOfVertexCompIds = undef;

	# keep track of the number of edges added between purges.
	$Self->{totalEdgesAddedSinceLastPurge} = 0;

	# log the purge as an info message.
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->info("purged $totalVertexCompIds vertex,component-id pairs.\n");
	}

	return undef;
}

=head2 C<finish>

The method C<finish> completes the computation of the connected components
and writes the pairs C<(vertex,component-id)> to the L</outputFile>. For 
each component C<component-id> is the lexographical minimum of all the
vertices in the component.

No edges can be added to the graph after C<finish> is called.

=cut

sub finish
{
	my ($Self) = @_;

	# once finish is called no more edges can be added.
	$Self->{finishedCalled} = 1;

	if (exists $Self->{vertexCompIdSorter})
	{
		# purge the last of the internal vertexCompIds and do not retain any vertices.
		$Self->purge(0);

		# finish sorting the vertexCompId pairs.
		$Self->{vertexCompIdSorter}->finish();

		# get the sorter for the oldCompId-to-oldCompId file of pairs.
		my $oldCompIdToOldSorter = Sort::External->new(mem_threshold => 64 * 1024 * 1024, working_dir => $Self->{baseDirectory});

		# get the temporay file for the oldCompId-to-vertex file of pairs.
		my ($oldCompIdToVertexFileFh, $oldCompIdToVertexFile) =
			tempfile("OV_XXXXXXXXXX", DIR => $Self->{baseDirectory}, UNLINK => $Self->{cleanup});
		close $oldCompIdToVertexFileFh;

		# compute the subgraph based on the oldCompId-to-oldCompId pairs and
		# write the oldCompId-to-vertex pairs.
		$Self->writeSubgraphInfoToFiles($oldCompIdToOldSorter, $oldCompIdToVertexFile);
		
		# finish the sort.
		$oldCompIdToOldSorter->finish();

		# get the temporay file for the oldCompId-to-newCompId file of pairs.
		my ($oldCompIdToNewCompIdFileFh, $oldCompIdToNewCompIdFile) =
			tempfile("ON_XXXXXXXXXX", DIR => $Self->{baseDirectory}, UNLINK => $Self->{cleanup});
		close $oldCompIdToNewCompIdFileFh;

		# compute the components of the subgraph from the oldCompId-to-oldCompId pairs.
		{
			my $externalComponenter =
				Graph::Undirected::Components::External->new(
																										 baseDirectory => $Self->{baseDirectory},
																										 outputFile    => $oldCompIdToNewCompIdFile,
																										 level         => 1 + $Self->{level},
																										 delimiter     => $Self->{delimiter},
                                                     purgeSizeBytes     => $Self->{purgeSizeBytes},
                                                     purgeSizeVertices     => $Self->{purgeSizeVertices},
																										 retainPercentage => $Self->{retainPercentage}
				);
			
			# add the edges in sorted order.
			my $previousEdgeStr = '';
			while (defined (my $edgeStr = $oldCompIdToOldSorter->fetch()))
			{
			  # skip the edge if a duplicate.
			  next if $previousEdgeStr eq $edgeStr;
			  $previousEdgeStr = $edgeStr;
			  
			  # split the edge.
			  my @edge = split (/$Self->{delimiter}/, $edgeStr);
			  
			  # add the edge to the graph.
        $externalComponenter->add_edge (@edge);
			}
			
			# purge the edge sorted.
			$oldCompIdToOldSorter = undef;
			
			# finish computing the components of the graph.
			my $processingStats = $externalComponenter->finish();
			$Self->{processingStats} = [] unless exists $Self->{processingStats};
			push @{ $Self->{processingStats} }, @$processingStats;
		}

		# map the components of the subgraph to the original nodes.
		$Self->mapComponentsOfSubgraphToNodes($oldCompIdToNewCompIdFile, $oldCompIdToVertexFile, $Self->{outputFile}, $Self->{baseDirectory});

		unlink $oldCompIdToNewCompIdFile if $Self->{cleanup};
		unlink $oldCompIdToVertexFile    if $Self->{cleanup};
	}
	else
	{

		# the edges fit in memory, so just compute the components and write the results to the file.
		$Self->outputVertexCompId();
	}

	# store the processing stats.
	$Self->{processingStats} = [] unless exists $Self->{processingStats};
	my $totalTime = $Self->getCpuTime($Self->{startTime});
	push @{ $Self->{processingStats} }, { level => $Self->{level}, time => $totalTime, edges => $Self->{totalEdges} };

	# log the stats as an info message.
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->info("processed $Self->{totalEdges} edges in $totalTime seconds; recusion level is $Self->{level}.\n");
	}

	return $Self->{processingStats};
}

sub mapComponentsOfSubgraphToNodes
{
	my ($Self, $OldCompIdToNewCompIdFile, $OldCompIdToVertexFile, $VertexToNewCompIdFile, $WorkingDirectory) = @_;

	# get the delimiter to use for the records.
	my $delimiter = $Self->{delimiter};

	# create the sorter to merge the OldCompId-NewCompId and OldCompId-Vertex edges.
	my $mergeSorter = Sort::External->new(mem_threshold => 64 * 1024 * 1024, working_dir => $WorkingDirectory);

	{

		# open the file $OldCompIdToNewCompIdFile to read each of the compComp edges.
		my $oldCompIdToNewCompIdFileHandle;
		unless (open($oldCompIdToNewCompIdFileHandle, '<', $OldCompIdToNewCompIdFile))
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie("could not open file '$OldCompIdToNewCompIdFile' for reading: $!\n");
		}

		# set the delimiter for the oldCompId-NewCompId so the pairs are first when sorted.
		my $oldCompIdToNewCompIdDelimiter = $delimiter . 'cc' . $delimiter;

		# cache the previous string to test for skipping of duplicates.
		my $previousOldCompIdToNewCompIdString = '';
		while (defined(my $oldCompIdToNewCompIdString = <$oldCompIdToNewCompIdFileHandle>))
		{

			# remove the line feed from the string.
			chop $oldCompIdToNewCompIdString;

			# convert the string to its pair of records.
			my @oldCompIdToNewCompIdRecord = split(/$delimiter/, $oldCompIdToNewCompIdString);

			# make sure the strings parses into only two items.
			if (@oldCompIdToNewCompIdRecord != 2)
			{
				my $logger = Log::Log4perl->get_logger();
				$logger->logdie("error: oldCompId to newCompId string record does not have two values.\n");
			}

			# feed the oldCompId-NewCompId pairs to the sorter.
			$mergeSorter->feed($oldCompIdToNewCompIdRecord[0] . $oldCompIdToNewCompIdDelimiter . $oldCompIdToNewCompIdRecord[1])
				if (   ($previousOldCompIdToNewCompIdString ne $oldCompIdToNewCompIdString)
						&& ($oldCompIdToNewCompIdRecord[0] ne $oldCompIdToNewCompIdRecord[1]));

			# store the string.
			$previousOldCompIdToNewCompIdString = $oldCompIdToNewCompIdString;
		}
		close $oldCompIdToNewCompIdFileHandle;
	}

	{

		# open the file $OldCompIdToVertexFile to read each of the pairs.
		my $oldCompIdToVertexFileHandle;
		unless (open($oldCompIdToVertexFileHandle, '<', $OldCompIdToVertexFile))
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie("could not open file '$OldCompIdToVertexFile' for reading: $!\n");
		}

		# set the delimiter for the oldCompId-Vertex so the pairs are second when sorted.
		my $oldCompIdToVertexDelimiter = $delimiter . 'cn' . $delimiter;

		# cache the previous string to test for skipping of duplicates.
		my $previousOldCompIdToVertexString = '';
		while (defined(my $oldCompIdToVertexString = <$oldCompIdToVertexFileHandle>))
		{
			chop $oldCompIdToVertexString;
			my @oldCompIdToVertexRecord = split(/$delimiter/, $oldCompIdToVertexString);
			if (@oldCompIdToVertexRecord != 2)
			{
				my $logger = Log::Log4perl->get_logger();
				$logger->logdie("error: oldCompId to vertex string record does not have two values.\n");
			}
			$mergeSorter->feed($oldCompIdToVertexRecord[0] . $oldCompIdToVertexDelimiter . $oldCompIdToVertexRecord[1])
				if $previousOldCompIdToVertexString ne $oldCompIdToVertexString;
			$previousOldCompIdToVertexString = $oldCompIdToVertexString;
		}
		close $oldCompIdToVertexFileHandle;
	}

	# sort the edges.
	$mergeSorter->finish;

	{

		# open the file to write the Vertex to NewCompId pairs.
		my $vertexToNewCompIdFileHandle;
		unless (open($vertexToNewCompIdFileHandle, '>', $VertexToNewCompIdFile))
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie("error: could not open file '$VertexToNewCompIdFile' for writing.\n");
		}

		# get first record pair from the sorter.
		my $previousOldToNewOrOldVertexString = '';
		my $oldToNewOrOldVertexString         = $mergeSorter->fetch;

		# split the string into a record.
		my $oldToNewOrOldVertexRecord;
		my @listOfOldToNewOrOldVertexRecords;
		if (defined $oldToNewOrOldVertexString)
		{
			$oldToNewOrOldVertexRecord = [ split(/$delimiter/, $oldToNewOrOldVertexString) ];
			@listOfOldToNewOrOldVertexRecords = ($oldToNewOrOldVertexRecord);
		}

		while (defined($oldToNewOrOldVertexString = $mergeSorter->fetch))
		{

			# convert the string to a record.
			my $oldToNewOrOldVertexRecord = [ split(/$delimiter/, $oldToNewOrOldVertexString) ];

			# when the compId changes, process the records in the list.
			if ($listOfOldToNewOrOldVertexRecords[-1]->[0] ne $oldToNewOrOldVertexRecord->[0])
			{

				# remap the oldCompId of each vertex to the newCompId and write it to the file.
				$Self->mapComponentsOfSubgraphToVerticesInList(\@listOfOldToNewOrOldVertexRecords, $vertexToNewCompIdFileHandle);

				# empty the cache of records.
				@listOfOldToNewOrOldVertexRecords = ();
			}

			# cache the record if unique.
			if ($oldToNewOrOldVertexString ne $previousOldToNewOrOldVertexString)
			{
				push @listOfOldToNewOrOldVertexRecords, $oldToNewOrOldVertexRecord;
				$previousOldToNewOrOldVertexString = $oldToNewOrOldVertexString;
			}

		}

		# remap the oldCompId of each vertex to the newCompId and write it to the file.
		$Self->mapComponentsOfSubgraphToVerticesInList(\@listOfOldToNewOrOldVertexRecords, $vertexToNewCompIdFileHandle);
		@listOfOldToNewOrOldVertexRecords = ();

		# close the file.
		close $vertexToNewCompIdFileHandle;
	}

	return undef;
}

sub mapComponentsOfSubgraphToVerticesInList    # (\@listOfOldToNewOrOldVertexRecords, $vertexToNewCompIdFileHandle);
{
	my ($Self, $ListOfOldToNewOrOldVertexRecords, $VertexToNewCompIdFileHandle) = @_;

	# get the string record delimiter.
	my $delimiter = $Self->{delimiter};

	# separate the Cc and Cn records.
	my $totalRecords         = @$ListOfOldToNewOrOldVertexRecords;
	my $indexOfFirstCnRecord = 0;
	for ($indexOfFirstCnRecord = 0 ; $indexOfFirstCnRecord < @$ListOfOldToNewOrOldVertexRecords ; $indexOfFirstCnRecord++)
	{
		last if ($ListOfOldToNewOrOldVertexRecords->[$indexOfFirstCnRecord][1] eq 'cn');
	}
	my $totalCcRecords = $indexOfFirstCnRecord;
	my $totalCnRecords = $totalRecords - $totalCcRecords;

	# if there are no oldCompIdToVertex records in the list, there is nothing to do.
	if ($totalCnRecords == 0)
	{

		#my $logger = Log::Log4perl->get_logger();
		#$logger->info ("info: no oldCompId to vertex records in list.\n");
		return undef;
	}

	# if there is more than one oldCompIdToNewCompId record in the list, log the info.
	if ($totalCcRecords > 1)
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->info("info: there were $totalCcRecords oldCompId-newCompId records in the list.\n");
	}

	# if $totalCcRecords is zero, there are no oldCompIdToNewCompId mapping records,
	# so then just add the oldCompIdToVertex records to the file.
	if ($totalCcRecords == 0)
	{

		# write each node,comp record to $VertexToNewCompIdFileHandle.
		my $previousRecord = '';
		for (my $i = $indexOfFirstCnRecord ; $i < $totalRecords ; $i++)
		{

			# convert the record to a string.
			my $recordString = $ListOfOldToNewOrOldVertexRecords->[$i][2] . $delimiter . $ListOfOldToNewOrOldVertexRecords->[$i][0];

			# skip duplicate records.
			next if $previousRecord eq $recordString;

			# print the record.
			print $VertexToNewCompIdFileHandle $recordString . $el;

			# store a copy of the record to remove duplicates.
			$previousRecord = $recordString;
		}
	}
	else
	{

		# get the newCompId.
		my $newCompId      = $ListOfOldToNewOrOldVertexRecords->[0][2];
		my $previousRecord = '';

		for (my $i = $indexOfFirstCnRecord ; $i < $totalRecords ; $i++)
		{

			# convert the record to a string.
			my $recordString = $ListOfOldToNewOrOldVertexRecords->[$i][2] . $delimiter . $newCompId;

			# skip duplicate records.
			next if $previousRecord eq $recordString;

			# print the record.
			print $VertexToNewCompIdFileHandle $recordString . $el;

			# store a copy of the record to remove duplicates.
			$previousRecord = $recordString;
		}
	}

	return undef;
}

sub writeSubgraphInfoToFiles
{
	my ($Self, $OldCompIdToOldSorter, $CompIdVertexFile) = @_;

	# open the oldCompId to vertex file for writing.
	my $oldCompIdToVertexFileHandle;
	unless (open($oldCompIdToVertexFileHandle, '>', $CompIdVertexFile))
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->logdie("could not open file '$CompIdVertexFile' for writing.\n");
	}

	# get the vertex component-id sorter.
	my $vertexCompIdSorter = $Self->{vertexCompIdSorter};

	# counts the number of edges in the subgraph generated ($OldCompIdToOldCompIdFile)
	my $totalSubgraphEdges = 0;

	# used to skip duplicated vertexCompId edges.
	my $previousVertexCompIdString = '';

	# get the first vertexCompId as a string.
	my $vertexCompIdString      = $vertexCompIdSorter->fetch;
	my $vertexCompIdPair        = [ split($Self->{delimiter}, $vertexCompIdString) ] if defined $vertexCompIdString;
	my @listOfVertexCompIdPairs = ($vertexCompIdPair);
	while (defined($vertexCompIdString = $vertexCompIdSorter->fetch))
	{

		# extract the vertex and component id from the string.
		my $vertexCompIdPair = [ split($Self->{delimiter}, $vertexCompIdString) ];

		# when the vertex changes the pairs in @listOfVertexCompIdPairs are used
		# to create part of the subgraph.
		if ($listOfVertexCompIdPairs[-1]->[0] ne $vertexCompIdPair->[0])
		{
			$Self->writeSubgraphInfoToFilesFromList(\@listOfVertexCompIdPairs, $OldCompIdToOldSorter,
																							$oldCompIdToVertexFileHandle, \$totalSubgraphEdges);

			# clear the list of pairs.
			@listOfVertexCompIdPairs = ();
		}

		# only store unique pairs.
		if ($previousVertexCompIdString ne $vertexCompIdString)
		{
			push @listOfVertexCompIdPairs, $vertexCompIdPair;
			$previousVertexCompIdString = $vertexCompIdString;
		}
	}

	# process any remaining pairs in @listOfVertexCompIdPairs.
	$Self->writeSubgraphInfoToFilesFromList(\@listOfVertexCompIdPairs, $OldCompIdToOldSorter,
																					$oldCompIdToVertexFileHandle, \$totalSubgraphEdges);
	@listOfVertexCompIdPairs = ();

	# done with the sorter.
	delete $Self->{vertexCompIdSorter};

	return undef;
}

sub writeSubgraphInfoToFilesFromList
{
	my ($Self, $ListOfVertexCompIdPairs, $OldCompIdToOldSorter, $OldCompIdToVertexFileHandle, $TotalSubgraphEdges) = @_;

	# the first record has the minimum component id.
	my $minCompId = $ListOfVertexCompIdPairs->[0]->[1];

	# compute the edges of the subgraph.
	my @listOfSubgraphEdgesA;
	my @listOfSubgraphEdgesB;
	for (my $i = 1 ; $i < @$ListOfVertexCompIdPairs ; $i++)
	{

		# get the component-id for the pair.
		my $compId = $ListOfVertexCompIdPairs->[$i]->[1];

		# add the new edge.
		push @listOfSubgraphEdgesA, join($Self->{delimiter}, $minCompId, $compId);
		++$$TotalSubgraphEdges;

		# we need to add the symmetric edge also to ensure log convergence.
		if ($minCompId ne $compId)
		{
			push @listOfSubgraphEdgesB, join($Self->{delimiter}, $compId, $minCompId);
			++$$TotalSubgraphEdges;
		}
	}

	# write the edges to the file.
	push @listOfSubgraphEdgesA, sort @listOfSubgraphEdgesB;
	@listOfSubgraphEdgesB = ();
  $OldCompIdToOldSorter->feed (@listOfSubgraphEdgesA);
	@listOfSubgraphEdgesA = ();

	# write the compId,vertex to the file.
	my $record = join($Self->{delimiter}, $minCompId, $ListOfVertexCompIdPairs->[0]->[0]) . $el;
	print $OldCompIdToVertexFileHandle $record;

	return undef;
}

sub outputVertexCompId
{
	my ($Self, %Parameters) = @_;

	# set the default delimiter.
	my $delimiter = $Self->{delimiter};
	$delimiter = $Parameters{delimiter} if exists $Parameters{delimiter};

	# get the list of vertices and component ids.
	my $listOfVertexCompIds = $Self->{componenter}->get_vertexCompIdPairs(0);

	# sort the list of vertices and component ids.
	$listOfVertexCompIds = [ sort { ($a->[0] cmp $b->[0]) || $a->[1] cmp $b->[1] } @$listOfVertexCompIds ];

	# open the component file for writing.
	my $outputFh;
	unless (open($outputFh, '>:encoding(utf8)', $Self->{outputFile}))
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->logdie("could not open file '$Self->{outputFile}' for writing.\n");
	}

	# write the vertex compId to the file.
	foreach my $vertexCompId (@$listOfVertexCompIds)
	{
		print $outputFh $vertexCompId->[0] . $delimiter . $vertexCompId->[1] . $el;
	}

	# close the output file of edges.
	close $outputFh;

	return undef;
}

sub printSorter
{
	my ($Self, $Sorter) = @_;

	my $previousRecord = '';
	while (defined(my $recordString = $Sorter->fetch))
	{
		next if $previousRecord eq $recordString;
		$previousRecord = $recordString;
		print $recordString . $el;
	}

	return undef;
}

sub getCpuTime    # ($startTime)
{
	my $startTime = 0;
	$startTime = $_[1] if exists $_[1];
	return Time::HiRes::clock() - $startTime;
}

sub DESTROY
{
	my ($Self) = @_;
	return undef if $Self->{level} > 0;
	return undef unless $Self->{cleanup};
	return undef unless exists $Self->{baseDirectory};
	return undef unless -e $Self->{baseDirectory};
	remove_tree($Self->{baseDirectory});

	return undef unless $Self->{unlinkWorkingDirectory};
	remove_tree($Self->{workingDirectory});
	return undef;
}

=head1 INSTALLATION

Use L<CPAN> to install the module and all its prerequisites:

  perl -MCPAN -e shell
  cpan[1]> install Graph::Undirected::Components

=head1 BUGS

Please email bugs reports or feature requests to C<bug-graph-undirected-components@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Undirected-Components>.  The author
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

connected components, network, undirected graph

=head1 SEE ALSO

L<Graph>, L<Graph::Undirected::Components>, L<Log::Log4perl>, L<Sort::External>

=begin html

<a href="http://en.wikipedia.org/wiki/Connected_component_%28graph_theory%29">connected component</a>,
<a href="http://en.wikipedia.org/wiki/Graph_(mathematics)">graph</a>,
<a href="http://en.wikipedia.org/wiki/Network_theory">network</a>,

=end html

=cut

1;

# The preceding line will help the module return a true value
