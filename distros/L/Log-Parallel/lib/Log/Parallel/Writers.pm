
package Log::Parallel::Writers;

use strict;
use warnings;
use Exporter;

require Log::Parallel::TSV;
require Log::Parallel::Raw;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_writer);
our @EXPORT_OK = (@EXPORT, qw(register_writer));

my %writers;

sub register_writer
{
	my ($name, $callback) = @_;
	$writers{$name} = $callback;
}

sub get_writer
{
	my ($name, %info) = @_;
	unless (defined $writers{$name}) {
		return undef;
	}
	if ($info{lazy_open_filename}) {
		return Log::Parallel::Writers::LazyOpen->new($name, %info);
	} else {
		my $writer = $writers{$name}->($name, %info);
		return $writer;
	}
}

package Log::Parallel::Writers::LazyOpen;

use strict;
use warnings;

our @ISA = qw(Log::Parallel::Writers::BaseClass);

sub new
{
	my ($pkg, $name, %info) = @_;
	my $self = bless { name => $name, info => \%info }, $pkg;
	return $self;
}


sub write
{
	my $self = shift;
	my $name = $self->{name};
	my %info = %{$self->{info}};
	my $pointer = delete $self->{pointer} || die;  # otherwise circular
	my $ofn = delete $info{lazy_open_filename};

	local($0) = $0;
	$0 =~ s/(: RUNNING).*/$1 opening output to $ofn/;

	my $pid = open my $fh, $ofn
		or die "open $ofn: $!";
	if ($ofn =~ /\|/ && $pid) {
		# $remote_killer->note(undef, $pid);   XXXX
	}

	$info{fh} = $fh;

	$$pointer = Log::Parallel::Writers::get_writer($name, %info);
	$0 =~ s/(: RUNNING).*/$1 writing first output to $ofn/;
	$$pointer->write(@_);
}

sub register_pointer
{
	my ($self, $pointer) = @_;
	$self->{pointer} = $pointer;
}

sub done {};
sub header { return {} };
sub md5_hex { return "" }
sub metadata { return { items => 0 } }
sub sort_arguments { return '' }

sub host { return '' }
sub fh { return undef }
sub bucket { return undef }
sub filename { return "" }
sub items { return 0 }

	
package Log::Parallel::Writers::BaseClass;

use strict;
use warnings;

use Digest::MD5 qw();

sub done
{
	my ($self) = @_;

	$self->{'size'} = 0;
	$self->{'timestamp'} = time;
	my $fh = $self->{fh};
	unless (close($fh)) { 
		my $e = $!;
		$e = "non-zero exit" if $! == 0;
		die "close $self->{filename}: $e";
	}
}

sub header
{
	my ($self) = @_;
	
	if (not defined $self->{'name'}) {
		return undef;
	}

	return {
		name		=> $self->{name},
		format		=> $self->{format},
		columns		=> $self->{columns},
		sort_by		=> $self->{sort_by},
		sort_types	=> $self->{sort_types},
	};
}

sub md5_hex {
	my $self = shift;
	return Digest::MD5::md5_hex(@_);
}

sub metadata
{
	my ($self) = @_;
	
	if (not defined $self->{'name'}) {
		return undef;
	}

	return { 
		header			=> $self->header(),
		sort_args		=> $self->sort_arguments(),
		post_sort_transform	=> $self->post_sort_transform(),
		map { $_ => $self->{$_} } @{$self->{return_data}},
	}
}

sub new
{
	my ($pkg, $format, %info) = @_;
	die unless $info{fh};
	my $self = bless { 
		return_data	=> [qw(bucket filename format size timestamp host items sort_types)],
		sort_types	=> {},
		%info, 
		format		=> $format,
	}, $pkg;
	$self->{columns} ||= [];
	$self->{discover_types} = 1
		unless defined $self->{discover_types};
	if ($self->{sort_by}) {
		for my $c (@{$self->{sort_by}}) {
			if ($c =~ /(.*)\((\w*)\)/) {
				push(@{$self->{columns}}, $1);
				$self->{sort_types}{$1} = $2;
				$self->{discover_types} = 0;
			} else {
				push(@{$self->{columns}}, $c);
			}
		}
		$self->{sort_by} = [ @{$self->{columns}} ];
	}
	return $self;
}

sub sort_arguments { return '' }

sub post_sort_transform { return '' }

sub register_writer
{
	my $self = shift;
	my $pkg = ref($self) ? ref($self) : $self;
	my $name = $pkg;
	$name =~ s/.*:://;
	Log::Parallel::Writers::register_writer( $name => sub { $pkg->new(@_) } );
}

sub host { my $self = shift; return $self->{host}; }
sub fh { my $self = shift; return $self->{fh}; }
sub bucket { my $self = shift; return $self->{bucket}; }
sub filename { my $self = shift; return $self->{filename}; }
sub items { my $self = shift; return $self->{items}; }

sub write { die }

1;

__END__

=head1 SYNOPSIS 

 use Log::Parallel::Writers;

 __PACKAGE__->register_writer();

 my $writer = get_writer('TSV', 
	lazy_open_filename	=> $filename_or_program_to_open_when_there_is_output,
	fh			=> $filehandle,
	columns			=> \@list_of_all_columns,
	sort_by			=> \@list_of_columns_to_sort_by,
	host			=> $hostname_where_fh_ends_up,
	filename		=> $path_where_fh_ends_up,
	bucket			=> $the_bucket_number_for_this_file,
	new_fields_cb		=> \&code_to_handle_new_fields,
 );

 $writer->write($log);

 $writer->done(); 

 $writer->sort_arguments();
 $writer->post_sort_transform();

 $writer->metadata();	# return the medadata for the files written
 $writer->header();	# return the data format record 

 $writer->host;		# accessor methods
 $writer->filename;
 $writer->fh;
 $writer->bucket;

=head1 DESCRIPTION

A writer formats a C<$log> record for output.  Since the output from a single
job may be streamed to multiple hosts and into multiple buckets there may
be multiple writer objects active at the same time.

The actual open is performed elsewhere because the output may be sent
somewhere else before it ends up where the Writer thinks it is going.
For example, it may need to be sorted.

This module, Log::Parallel::Writers, dispatches the call to get a writer
to the named writer.  The writer modules, like L<Log::Parallel::Raw> and
L<Log::Parallel::TSV> must register themselves with Log::Parallel::Writers
so that they can be found by name.

=head1 WRITING A WRITER

To create a writer, you need to subclass C<Log::Parallel::Writers::BaseClass> and 
register yourself:

 our @ISA = qw(Log::Parallel::Writers::BaseClass);

 __PACKAGE__->register_writer();

Writes must override the C<write()> method.   They may also want to override
other methods like C<new()>, C<done()>, C<post_sort_transform()>, 
C<sort_arguments()>

=head1 METHODS FOR WRITERS

With the exception of C<write()> all of these methods are defined in the
base class and overriding them is opitonal.

=head2 header()

This must return a header object for the log written.   The header has all
the information required to use the log file.

The header object is an anonymous hash.  It must have the following keys:

=over

=item name

The name must uniquely identify a particular format.   For
formats that don't have a predefined set of columns, the name should include
an md5 of the column names.

=item format

The name of the parser as registered by a parser.  See L<Log::Parallel::Parsers>.

=item columns

An ordered list of the column names.  

=item sort_by

An ordered list of column names by which the output file is sorted (if any)

=item sort_tyes

Sort_types
is a hash of the sort_by column names to their unix sort(1) flags,
eg: C<n>, C<r>, C<rn>, C<g> etc.

=item 

=back

It can have additional keys in the hash.   
It cannot have anything that isn't uniquely specified by the name field:
The header structures for two different headers
with the same name field must be identical.

=header2 metadata()

The metadata is very simple: the full path to the file, the hostname, and a 
file header object (as returned by header()).

=over

=item filename

Return the filename (not including host) for the output file.

=item header

As per the C<header()> method

=item bucket

Which output bucket this file is in.  Buckets are integers,
starting from zero.

=item items

The entries in this file.   Usually the number of lines.

=back

=head2 post_sort_transform()

If the output needs to be sorted by the unix sort program,
perhaps it needs to be in a temporary format so that sort can
handle it.  

If so, then Writer should output the temporary format and 
post_sort_transform() should return a function
that takes a line of input and provides one or more lines
of output that transform the Writer's output in the the format
it actually needs to be in.

The function returned by post_sort_transform() must be a string
that is eval'ed to create the sort transformation function.

This is done in L<Log::Task::PostSort>

=head2 sort_arguments()

If the output needs to be sorted by the unix sort program,
this method provides the arguments to unix sort so that it 
performs the correct sort.

Note that the merge-sort used to combine multiple buckets wil
do a numeric comparison before it does a string comparison
so the unix sort aguments should reflect a number sort preference.

This method returns a string.  It does not include the filename.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

