package Microarray::GEO::SOFT;

use List::Vectorize qw(!table);

use Microarray::ExprSet;
use File::Basename;
use LWP::UserAgent;
use Time::HiRes qw(usleep gettimeofday);
use Carp;
use Cwd;
use strict;

require Microarray::GEO::SOFT::GPL;
require Microarray::GEO::SOFT::GSM;
require Microarray::GEO::SOFT::GDS;
require Microarray::GEO::SOFT::GSE;

our $VERSION = "0.20";
our $wd = getcwd();

$| = 1;

# download geo files
our $ua;
our $response;
our $download_start_time;
our $fh_out;

1;

sub new {

	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = { "file" => "",
	             "tmp_dir" => ".tmp_soft",
				 "verbose" => 1,
				 "sample_value_column" => "VALUE",
	             @_ };
	bless($self, $class);
	
	opendir DIR, $self->{tmp_dir} and closedir DIR
		or mkdir $self->{tmp_dir};

	return $self;
	
}

sub _set_to_null_fh {

	my $null = $^O eq "MSWin32" ? "NUL" : "/dev/null";
	open my $fh_out, ">", $null;
	$| = 1;
	select($fh_out);
}

sub _set_to_std_fh {
	$| = 1;
	select(STDOUT);
}

sub _set_fh {
	my $verbose = shift;
	
	$verbose ? _set_to_std_fh() : _set_to_null_fh();
}

BEGIN {
	
	no strict 'refs';
	
	for my $accessor (qw(meta table)) {
		*{$accessor} = sub {
			my $self = shift;
			return defined($self->{$accessor}) ? $self->{$accessor}
			                                   : undef;
		}
	}
	
	for my $accessor (qw(accession title platform)) {
		*{$accessor} = sub {
			my $self = shift;
			return defined($self->{meta}->{$accessor}) ? $self->{meta}->{$accessor}
			                                           : undef;
		}
	}
	
	for my $accessor (qw(rownames colnames colnames_explain matrix)) {
		*{$accessor} = sub {
			my $self = shift;
			return defined($self->{table}->{$accessor}) ? $self->{table}->{$accessor}
			                                            : undef;
		}
	}
	
}

sub soft_dir {

	my $self = shift;
	return $self->{tmp_dir};
}

sub parse {

	my $self = shift;
	
	_set_fh($self->{verbose});
	
	# decompress file
	if( -e $self->{file} and (! -T $self->{file}) ) {
		$self->{file} = _decompress($self->{file});
	}

	my $type = _check_type($self->{file});
	
	my $obj;
	if($type eq "SERIES") {
	
		$obj = Microarray::GEO::SOFT::GSE->new(file => $self->{file}, 
		                                       verbose => $self->{verbose},
											   sample_value_column => $self->{sample_value_column},
											   @_);
		$obj->parse;
		
	}
	elsif($type eq "DATASET") {
		
		$obj = Microarray::GEO::SOFT::GDS->new(file => $self->{file}, 
		                                       verbose => $self->{verbose},
											   @_);
		$obj->parse;
		
	}
	elsif($type eq "PLATFORM") {
		
		$obj = Microarray::GEO::SOFT::GPL->new(file => $self->{file}, 
		                                       verbose => $self->{verbose},
											   @_);
		$obj->parse;
	}
	else {
	
		croak "ERROR: Format not supported. Only GSExxx, GDSxxx and GPLxxx are valid\n";
		
	}
	
	_set_to_std_fh();
	
	return $obj;
}

# determine what type is the input file by reading first few lines
sub _check_type {

	my $file = shift;
		
	open F, $file or croak "Cannot open $file.\n";
	
	while(my $line = <F>) {
	
		if($line =~/^\^SERIES /) {
			return "SERIES";
		}
		
		elsif($line =~/^\^DATASET /) {
			return "DATASET";
		}
		
		elsif($line =~/^\^PLATFORM /) {
			return "PLATFORM";
		}
		
		elsif($line =~/^\^Annotation/) {
			return "PLATFORM";
		}
	}
	
	return undef;
}


sub set_meta {

	my $self = shift;
	my $arg = {'accession' => $self->accession,
	           'title'     => $self->title,
			   'platform'  => $self->platform,
			   @_};
	
	$self->{meta}->{"accession"} = $arg->{'accession'};
	$self->{meta}->{"title"} = $arg->{'title'};
	$self->{meta}->{"platform"} = $arg->{'platform'};
	
	return $self;
}


sub set_table {

	my $self = shift;
	my $arg = {'rownames'         => $self->rownames,
	           'colnames'         => $self->colnames,
			   'colnames_explain' => $self->colnames_explain,
			   'matrix'           => $self->matrix,
			   @_};
	
	$self->{table}->{"rownames"} = $arg->{'rownames'};
	$self->{table}->{"colnames"} = $arg->{'colnames'};
	$self->{table}->{"colnames_explain"} = $arg->{'colnames_explain'};
	$self->{table}->{"matrix"} = $arg->{'matrix'};
	
	return $self;
}

# download data from GEO ftp
# returns a list of filenames (array reference)
# in most circumstance, there is only one file at each series/platform/gds directory
# but still there is probability that multiple files locate in directory (especially for series matrix format)
# we only deal with one file situation
# for multiple files situation, users can downloaded manually
# and initial this object with file argument
sub download {

	my $self = shift;
	
	my $id = shift;
	
	_set_fh($self->{verbose});
	
	my %option = ( "proxy" => "",        # proxy setting, only http, should be like "http://username:password@127.0.0.1:808/"
				   "timeout" => 30,
	               @_ );
	
	my $remote_file_list;
	my $remote_file_name;
	my $remote_file_size;
	my $local_file;
	
	#$fh_out = _open_out_handle($self->{verbose});
	
	$ua = LWP::UserAgent->new;
	$ua->timeout($option{timeout});
	
	if($option{proxy}) {
		$ua->proxy(["http"], $option{proxy});
	}
	
	my $url;
	
	# different geo data type
	my $url_format = { "gse" => "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/by_series",
					   "gpl" => "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/annotation/platforms",
					   "gds" => "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/GDS" };

	# format url based on different GEO id type
	if($id =~/^gse\d+$/i) {
		$url = "$url_format->{gse}/$id";
	}
	elsif($id =~/^gpl\d+$/i) {
		$url = "$url_format->{gpl}";
	}
	elsif($id =~/^gds\d+$/i) {
		$url = "$url_format->{gds}";
	}
	else {
		croak "ERROR: GEO ID should look like 'GSE123', 'GPL123' and 'GDS123'";
	}
	
	# if GSE or GPL
	if($id =~/^gse\d+$/i) {
		
		# first get the file list in the directory
		# because some GSE or GPL term would have more than one file
		print "Reading dir from GEO FTP site:\n";
		print "  $url\n\n";
		$response = $ua->get($url);
		
		unless($response->is_success) {
			croak $response->status_line;
		}
		
		my $content = $response->content;
		@$remote_file_list = split "\n", $content;
		
		print "found ", scalar(@$remote_file_list), " file.\n";
		
		if(scalar(@$remote_file_list) > 1) {
			croak "ERROR: There are more than one files in the remote directory and this ".
			      "situation has not been supported by ". __PACKAGE__." by this version. ".
				  "But still you can download them by hand.";
		}
		if(! scalar(@$remote_file_list)) {
			croak "Can not find any file.";
		}
		
		my @tmp = split " ", $remote_file_list->[0];
		$remote_file_name = $tmp[$#tmp];
		$remote_file_size = $tmp[4];
		$local_file = $self->soft_dir."/$tmp[$#tmp]";
		
		print "remote file is: $remote_file_name\n";
		print "\n";
		
	}
	elsif($id =~/gpl\d+$/i) {
	
		print "Validating link from GEO FTP site:\n";
		print "  $url/$id.annot.gz\n";
		$response = $ua->head("$url/$id.annot.gz");
		
		unless($response->is_success) {
			croak $response->status_line;
		}
		
		print "found $id.annot.gz on the server.\n\n";
		$remote_file_name = "$id.annot.gz";
		$remote_file_size = $response->header("content-length");
		$local_file = $self->soft_dir."/$id.annot.gz";
		
	}
	# if GDS
	elsif($id =~/gds\d+$/i) {
	
		print "Validating link from GEO FTP site:\n";
		print "  $url/$id.soft.gz\n\n";
		$response = $ua->head("$url/$id.soft.gz");
		
		unless($response->is_success) {
			croak $response->status_line;
		}
		
		print "found $id.soft.gz on the server.\n\n";
		$remote_file_name = "$id.soft.gz";
		$remote_file_size = $response->header("content-length");
		$local_file = $self->soft_dir."/$id.soft.gz";
		
	}
	
	# whether there already has a file with the same name
	while(-e $local_file) {
		my $r = int(rand(100000));
		if($remote_file_name =~/^(.*?)\.(\S+)$/) {
			my $base = $1;
			my $ext = $2;
			$local_file = $self->soft_dir."/$base.$r.$ext";
		}
		else {
			$local_file = $self->soft_dir."/$remote_file_name.$r";
		}
	}
	
	$url = "$url/$remote_file_name";
	print "downloading $url\n";
	print "file size: $remote_file_size byte.\n";
	print "local file: $wd/$local_file\n\n";
	
	# begin to download
	# if thread supported, progress would be shown
	$response = undef;
	
	eval 'require Thread; require threads::shared';
	
	if($@) {
		_download($url, $local_file);
		
		unless($response->is_success) {
			croak $response->status_line;
		}
		
	} else {
		eval q`
		my $response : shared;
		$download_start_time = gettimeofday();
		my $download_start_time : shared;
		my $f1 = Thread->new(\&_download, $url, $local_file);
		my $f2 = Thread->new(\&_progress, $local_file, $remote_file_size);
		
		$f1->join;
		$f2->join;
		`;
	}
	
	$self->{file} = $local_file;
	
	_set_to_std_fh();
	
	return $self;
}

sub _download {
	my $url = shift;
	my $local_file = shift;
		
	$response = $ua->get($url, ":content_file" => $local_file);	
}

sub _progress {
	my $local_file = shift;
	my $remote_file_size = shift;
	
	# still connecting
	while(! -e $local_file) {
		#print "$local_file does not exist, sleep $s_sleep_ms ms.\n";
		usleep(500000);
		
		if($response) {
			print "\n\n";
			last;
		}
	}
									 
	my $recieved_file_size = -s "$local_file";
	my $i = 0;
	my $bar = ["|", "\\", "-", "/"];
	while($recieved_file_size != $remote_file_size) {
		$recieved_file_size = -s "$local_file";
		my $percentage = $recieved_file_size / $remote_file_size;
		$percentage = sprintf("%.1f", $percentage * 100);
		my $speed = $recieved_file_size / (gettimeofday - $download_start_time);
		$speed = sprintf("%.2f", $speed / 1024);  #KB/s
		my $passed_time = (gettimeofday - $download_start_time);
		$passed_time = int($passed_time);
		print "\b" x 100;

		print "[", $bar->[$i % scalar(@$bar)], "]";
		print " Recieving $recieved_file_size byte.\t$percentage\%\t$speed KB/s\t$passed_time"."s";
		$i ++;
		
		usleep(500000);
		
		# if download is done
		if($response) {
			last;
		}
	}
	
	print "\n\n";

}


sub _decompress {
	
	# 压缩文件
	my $compressed_file = shift;
	
	my $null = $^O eq "MSWin32" ? "NUL" : "/dev/null";
	eval("system('gzip --version > $null')") == 0
		or croak "ERROR: Cannot find 'gzip'\n";

	# 压缩文件的文件名
	my $basename = basename($compressed_file);
	
	print "decompress $compressed_file...\n";
	my $command;
	
	# 获得解压缩文件的文件名
	$command = "gzip -l \"$compressed_file\"";
	my $status = `$command`;
	
	my @foo = split "\n", $status;
	@foo = split " ", $foo[1];
	my $uncompressed_file = $foo[$#foo];
	
	# 解压缩
	$command = "gzip -cd \"$compressed_file\" > \"$uncompressed_file\"";
	
	system($command) == 0
		or croak "ERROR: $!\n";
	
	# 返回解压后的文件名
	return "$uncompressed_file";
}


__END__

=pod

=head1 NAME

Microarray::GEO::SOFT - Reading microarray data in SOFT format from GEO database.

=head1 SYNOPSIS
  
  use Microarray::GEO::SOFT;
  use strict;
  
  # initialize
  my $soft = Microarray::GEO::SOFT->new; 

  # download
  $soft->download("GDS3718");
  $soft->download("GSE10626");
  $soft->download("GPL1261");
  
  # or else you can read local data
  $soft = Microarray::GEO::SOFT->new(file => "GDS3718.soft");
  $soft = Microarray::GEO::SOFT->new(file => "GSE10626_family.soft");
  $soft = Microarray::GEO::SOFT->new(file => "GPL1261.annot");
  
  # parse
  # it returns a  Microarray::GEO::SOFT::GDS,
  # Microarray::GEO::SOFT::GSE or Microarray::GEO::SOFT::GPL object
  # according the the GSE ID type
  my $data = $soft->parse;
  
  # some meta info
  $data->meta;
  $data->title;
  $data->platform;
  
  # for GPL and GDS, you can get the data table
  $data->table;
  $data->colnames;
  $data->rownames;
  $data->matrix;
  
  # sinece GSE can contain more than one GPL
  # we can get the GPL list in a GSE
  my $gpl_list = $data->list("GPL");
  
  # merge samples belonging to a same GPL into a data set
  my $gds_list = $data->merge;
  
  # if the GSE only have one platform
  # then the merged data set is the first one in gds_list
  # and the platform is the first one in gpl_list
  my $g = $gds_list->[0];
  my $gpl = $gpl_list->[0];
  
  # since GPL data contains different mapping of genes or probes
  # we can transform from probe id to gene symbol
  # it returns a Microarray::ExprSet object
  my $e = $g->id_convert($gpl, "Gene Symbol");
  my $e = $g->id_convert($gpl, qr/gene[-_\s]?symbol/i);
  
  
  # if you pased a GDS data
  # you can first find the platform
  my $platform_id = $data->platform;
  # downloaded or parse the local file
  my $gpl = Microarray::GEO::SOFT->new->download($platform_id);
  # and do the id convert thing
  my $e = $data->id_convert($gpl, qr/gene[-_\s]?symbol/i);
  
  # or just transform into Microarray::ExprSet direct from GDS
  my $e = $g->soft2exprset;
  
  # then you can do some simple processing thing
  # eliminate the blank lines
  $e->remove_empty_features;
  
  # make all symbols unique
  $e->unify_features;
  
  # obtain the expression matrix
  $e->save('some-file');	

Also, you can use the module under command line

  getgeo --id=GDS3718
  getgeo --file=GDS3718.soft --verbose

=head1 DESCRIPTION

GEO (Gene Expression Omnibus) is the biggest database providing gene expression
profile data. This module provides method to download and parse files in GEO database
and transform them into simple format for common usage.

There are always four type of data in GEO which are GSE, GPL, GSM and GDS.

GPL: Platform of the microarray, like Affymetrix U133A, see L<Microarray::GEO::SOFT::GPL>

GSM: A single microarray, see L<Microarray::GEO::SOFT::GSM>

GSE: A complete microarray experiment, always contains multiple samples and multiple platforms
see L<Microarray::GEO::SOFT::GSE>

GDS: manually collected data sets from GSE, with only 1 platform. see L<Microarray::GEO::SOFT::GDS>

Data stored in GEO database has several formats. We provide method to parse the most
used format: SOFT formatted family files. The origin data is downloaded from GEO ftp site.

=head2 Subroutines

=over 4

=item C<new("file" =E<gt> $file, HASH )>

Initial a Microarray::GEO::SOFT class object. The argument is file path for 
the microarray data in SOFT format or a file handle that has been openned. Other
arguments are.

  'tmp_dir'             => '.tmp_soft'
  'verbose'             => 1
  'sample_value_column' => 'VALUE'

'tmp_dir' is the name for the temporary directory. 'verbose' determines whether
print the message when analysis. 'sample_value_column' is the column name for
table data when parsing GSM data.
  
=item C<$soft-E<gt>download(ACC, %options)>

Download GEO record from NCBI website. The first argument is the accession number
such as (GSExxx, GPLxxx or GDSxxx). Your can set the timeout and proxy via C<%options>.
the proxy should be set as http://username:password@server-addr:port/.

GSE data is downloaded from ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/by_series/GSExxx/GSExxx_family.tar.gz

GDS data is downloaded from ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/GDS/GDSxxx.soft.gz

GPL data is downloaded from ftp://ftp.ncbi.nih.gov/pub/geo/DATA/annotation/platforms/GPLxxx.annot.gz

=item C<$soft-E<gt>soft_dir>

Temp dir for storing downloaded GEO data. It is ".tmp_soft".

=item C<$soft-E<gt>parse>

Proper parsing method is selected according to the accession number of GEO record.
E.g. if a GSExxx record is required, then the parsing function would choose method
to parse GSExxx part and return a L<Microarray::GEO::SOFT::GSE> class object. The
return value is one of L<Microarray::GEO::SOFT::GSE>, L<Microarray::GEO::SOFT::GPL>
or L<Microarray::GEO::SOFT::GDS> object.

=item C<$data-E<gt>meta>

Get meta information, more detailed meta information can be get via C<platform>, 
C<title>, C<accession>.

=item C<$data-E<gt>set_meta(HASH)>

Set meta information, arguments are 'platform', 'title' and 'accession'

=item C<$data-E<gt>platform>

Get accession number of the platform. If a record has multiple platforms, the function
return a reference of array (only for GSE).

=item C<$data-E<gt>title>

Title of the record

=item C<$data-E<gt>accession>

Accession number for the record

=item C<$gds-E<gt>table>

Get the table part in the object. Note it is not work for L<Microarray::GEO::SOFT::GSE> object.

=item C<$gds-E<gt>set_table>

Set the table part in the object. Note it is not work for L<Microarray::GEO::SOFT::GSE> object.

=item C<$gds-E<gt>rownames>

Row names for the table part in the object. Note it is not work for L<Microarray::GEO::SOFT::GSE> object.

=item C<$gds-E<gt>colnames>

Column names for the table part in the object. Note it is not work for L<Microarray::GEO::SOFT::GSE> object.

=item C<$gds-E<gt>colnames_explain>

A little more detailed explain for column names. Note it is not work for L<Microarray::GEO::SOFT::GSE> object.

=item C<$gds-E<gt>matrix>

Expression value matrix or ID mapping matrix.  Note it is not work for L<Microarray::GEO::SOFT::GSE> object.

=item C<getgeo>

C<getgeo> is a simple command line tool to download or parse the GEO data.
Options are as follows:

  --id=[GEOID]

    GEO ID. such as GSE123, GDS123 or GPL123. If this is set, the script would
    download data from GEO FTP site.

  --proxy=[PROXY]

    Proxy to connect to GEO FTP site. Format should look like
    http://username:password@host:port/.

  --file=[FILE]

    Filename for local GEO file. If --id is set, this option is ignored.

  --tmp-dir=[DIR]

    Temporary directory name for processing of GEO data. By default it is
    '.tmp_soft' in your working directory.

  --verbose

    Whether print message while processing.

  --sample-value-column=[FIELD]

    Since there may be multiple columns in GSM record, users may specify which
    column is the expression value they want. By default it is 'VALUE'. Ignored
        when analyzing GPL and GDS data.

  --output-file=[FILE]

    Filename for the output file. By default it is 'GEOID.table' in your current

    working directory.

  --help

    Help message.

=back

=head1 AUTHOR

Zuguang Gu E<lt>jokergoo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Zuguang Gu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Microarray::ExprSet>

=cut
