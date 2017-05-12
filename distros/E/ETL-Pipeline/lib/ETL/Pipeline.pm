=pod

=head1 NAME

ETL::Pipeline - Extract-Transform-Load pattern for data file conversions

=head1 SYNOPSIS

  use ETL::Pipeline;

  # The object oriented interface...
  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', find => qr/\.xlsx?$/              ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'     },
    constants => {Type => 1, Information => 'Demographic'    },
    output    => ['SQL', table => 'NewData'                  ],
  } )->process;

  # Or using method calls...
  my $pipeline = ETL::Pipeline->new;
  $pipeline->work_in  ( search => 'C:\Data', find => qr/Ficticious/ );
  $pipeline->input    ( 'Excel', find => qr/\.xlsx?$/i              );
  $pipeline->mapping  ( Name => 'A', Address => 'B', ID => 'C'      );
  $pipeline->constants( Type => 1, Information => 'Demographic'     );
  $pipeline->output   ( 'SQL', table => 'NewData'                   );
  $pipeline->process;

=cut

package ETL::Pipeline;

use 5.014000;
use Carp;
use Moose;
use MooseX::Types::Path::Class qw/Dir File/;
use Path::Class::Rule;
use Scalar::Util qw/blessed/;
use String::Util qw/hascontent nocontent/;


our $VERSION = '2.02';


=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. ETL isn't just for Data
Warehousing. ETL works on almost any type of data conversion. You read the
source, translate the data for your target, and store the result.

By dividing a conversion into 3 steps, we isolate the input from the output...

=over

=item * Centralizes data formatting and validation.

=item * Makes new input formats a breeze.

=item * Makes new outputs just as easy.

=back

B<ETL::Pipeline> takes your data files from extract to load. It reads an input
source, translates the data, and writes it to an output destination. For
example, I use the these pipelines for reading an Excel spread sheet (input)
and saving the information in an SQL database (output).

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', find => qr/\.xlsx?$/],
    mapping   => {Name => 'A', Complaint => 'B', ID => 'C'},
    constants => {Client => 1, Type => 'Complaint'}
    output    => ['SQL', table => 'NewData']
  } )->process;

Or like this, calling the methods instead of through the constructor...

  use ETL::Pipeline;
  my $etl = ETL::Pipeline->new;
  $etl->work_in  ( search => 'C:\Data', find => qr/Ficticious/ );
  $etl->input    ( 'Excel', find => qr/\.xlsx?$/               );
  $etl->mapping  ( Name => 'A', Complaint => 'B', ID => 'C'    );
  $etl->constants( Client => 1, Type => 'Complaint'            );
  $etl->output   ( 'SQL', table => 'NewData'                   );
  $etl->process;

=head2 What is a pipeline?

The term I<pipeline> describes a complete ETL process - extract, transform,
and load. Or more accurately - input, mapping, output. Raw data enters one end
of the pipe (input) and useful information comes out the other (output). An
B<ETL::Pipeline> object represents a complete pipeline.

=head1 METHODS & ATTRIBUTES

=head3 new

Create a new ETL pipeline. The constructor accepts these values...

=over

=item chain

This optional attribute copies L</work_in>, L</data_in>, and L</session> from 
another object. B<chain> accepts an B<ETL::Pipeline> object. The constructor 
copies L</work_in>, L</data_in>, and L</session> from that object. It helps 
scripts process multiple files from the same place.

See the section L</Multiple input sources> for an example.

=item constants

Assigns constant values to output fields. Since B<mapping> accepts input
field names, B<constants> assigns literal strings or numbers to fields. The
constructor calls the L</constants> method. Assign a hash reference to this
attribute.

  constants => {Type => 1, Information => 'Demographic'},

=item input

Setup the L<ETL::Pipeline::Input> object for retrieving the raw data. The
constructor calls the L</input> method. Assign an array reference to this
attribute. The array is passed directly to L</input> as parameters.

  input => ['Excel', find => qr/\.xlsx?$/],

=item output

Setup the L<ETL::Pipeline::Output> object for retrieving the raw data. The
constructor calls the L</output> method. Assign an array reference to this
attribute. The array is passed directly to L</output> as parameters.

  output => ['SQL', table => 'NewData'],

=item mapping

Move data from the input to the output. This attribute maps the input to the
output. The constructor calls the L</mapping> method. Assign a hash
reference to the attribute.

  mapping => {Name => 'A', Address => 'B', ID => 'C'},

=item work_in

Sets the working directory. All files - input, output, or temporary - reside
in this directory. The constructor accepts the same value as the parameters
to the L</work_in> method. As a matter of fact, the constructor just calls the
L</work_in> method.

=back

When creating the pipeline, B<ETL::Pipeline> sets up arguments in this order...

=over

=item 1. work_in

=item 2. data_in

=item 3. input

=item 4. constants

=item 5. mapping

=item 6. output

=back

Later parts (e.g. output) can depend on earlier parts (e.g. input). For 
example, the B<input> will use B<data_in> in its constructor.

=cut

sub BUILD {
	my $self = shift;
	my $arguments = shift;

	# The order of these blocks is important. ETL::Pipeline::Input and
	# ETL::Pipeline::Output objects depend on work_in and data_in being set. 
	# And I want parameters to override chained values.

	# Copy information from an existing object. This allows objects to share
	# settings or information.
	# 
	# NOTE: Always copy "work_in" before "data_in". The trigger on "work_in"
	#       will change "data_in" if you don't.
	if (defined $arguments->{chain}) {
		my $object = $arguments->{chain};
		croak '"link" requires an ETL::Pipeline object' unless defined blessed( $object );
		croak '"link" requires an ETL::Pipeline object' unless $object->isa( 'ETL::Pipeline' );
		$self->_set_work_in( $object->work_in ) if defined $object->work_in;
		$self->_set_data_in( $object->data_in ) if defined $object->data_in;
		$self->_set_session( $object->_get_session );
	}

	# The order of these two is important. "work_in" resets "data_in" with a
	# trigger. "work_in" must be set first so that we don't lose the value
	# from "data_in".
	if (defined $arguments->{work_in}) {
		my $values = $arguments->{work_in};
		$self->work_in( ref( $values ) eq '' ? $values : @$values );
	}
	if (defined $arguments->{data_in}) {
		my $values = $arguments->{data_in};
		$self->data_in( ref( $values ) eq '' ? $values : @$values );
	}

	# Configure the object in one fell swoop. This always happen AFTER copying
	# the linked object. Normal setup overrides the linked object.
	# 
	# The order of the object creation matches the order of execution - 
	# Extract, Transform, Load. Later parts on the pipeline can depend on
	# the configuration of earlier parts.
	if (defined $arguments->{input}) {
		my $values = $arguments->{input};
		$self->input( ref( $values ) eq '' ? $values : @$values );
	}
	if (defined $arguments->{constants}) {
		my $values = $arguments->{constants};
		$self->constants( %$values );
	}
	if (defined $arguments->{mapping}) {
		my $values = $arguments->{mapping};
		$self->mapping( %$values );
	}
	if (defined $arguments->{output}) {
		my $values = $arguments->{output};
		$self->output( ref( $values ) eq '' ? $values : @$values );
	}
}


=head3 chain

This method creates a new pipeline using the same L</work_in> and L</data_in>
directories. It accepts the same arguments as L</new>. Use B<chain> when
linking multiple pipelines together. See the section L</Multiple input sources>
for more details.

=cut

sub chain {
	my ($self, %arguments) = @_;
	$arguments{chain} = $self unless exists $arguments{chain};
	return __PACKAGE__->new( \%arguments );
}


=head2 Reading the input

=head3 input

B<input> sets and returns the L<ETL::Pipeline::Input> object. The pipeline uses
this object for reading the input records.

With no parameters, B<input> returns the current L<ETL::Pipeline::Input> object.

You tie in a new input source by calling B<input> with parameters...

  $pipeline->input( 'Excel', find => qr/\.xlsx/i );

The first parameter is a class name. B<input> looks for a Perl module matching
this name in the C<ETL::Pipeline::Input> namespace. In this example, the actual
class name becomes C<ETL::Pipeline::Input::Excel>.

The rest of the parameters are passed directly to the C<new> method of that
class.

B<Technical Note:> Want to use a custom class from B<Local> instead of
B<ETL::Pipeline::Input>? Put a B<+> (plus sign) in front of the class name.
For example, this command uses the input class B<Local::CustomExtract>.

  $pipeline->input( '+Local::CustomExtract' );

=head3 get

The B<get> method returns the value of a single field from the input. It maps
directly to the L<get method from ETL::Pipeline::Input|ETL::Pipeline::Input/get>.
See L<ETL::Pipeline::Input/get> for more information.

  $pipeline->get( 'A' );
  # -or-
  $pipeline->mapping( Name => sub { lc $_->get( 'A' ) } );

When you use a code reference, B<ETL::Pipeline> passes itself in C<$_>. B<get>
provides a convenient shortcut. Instead of writing C<< $_->input->get >>, you
can write C<< $_->get >>.

=head3 record_number

The B<record_number> method returns current record number. It maps directly
to the L<record_number method from ETL::Pipeline::Input|ETL::Pipeline::Input/record_number>.
See L<ETL::Pipeline::Input/record_number> for more information.

  $pipeline->record_number;
  # -or-
  $pipeline->mapping( Row => sub { $_->record_number } );

=cut

has 'input' => (
	does     => 'ETL::Pipeline::Input',
	handles  => {get => 'get', record_number => 'record_number'},
	init_arg => undef,
	is       => 'bare',
	reader   => '_get_input',
	writer   => '_set_input',
);


sub input {
	my $self = shift;

	$self->_set_input( $self->_object_of_class( 'Input', @_ ) ) if (scalar @_);
	return $self->_get_input;
}


=head2 Translating the data

=head3 mapping

B<mapping> ties the input fields with the output fields. If you call
B<mapping> with no parameters, it returns the hash reference. Call B<mapping>
with a hash or hash reference and it replaces the entire mapping with the new
one.

Hash keys are output field names. The L</output> class defines acceptable field
names. The hash values can be...

=over

=item A string

=item A regular expression reference (with C<qr/.../>)

=item A code reference

=back

Strings and regular expressions are passed to L<ETL::Pipeline::Input/get>.
They must refer to an input field.

A code reference is executed in a scalar context. It's return value goes into
the output field. The subroutine receives this B<ETL::Pipeline> object as its
first parameter B<and> in the C<$_> variable.

  # Get the current mapping...
  my $transformation = $pipeline->mapping;

  # Set the output field "Name" to the input column "A"...
  $pipeline->mapping( Name => 'A' );

  # Set "Name" from "Full Name" or "FullName"...
  $pipeline->mapping( Name => qr/Full\s*Name/i );

  # Use the lower case of input column "A"...
  $pipeline->mapping( Name => sub { lc $_->get( 'A' ) } );

Want to save a literal value? Use L</constants> instead.

=head3 add_mapping

B<add_mapping> adds new fields to the current mapping. L</mapping> replaces
the entire mapping. B<add_mapping> modifies it, leaving all of your old
transformations in place.

B<add_mapping> accepts key/value pairs as parameters.

  $pipeline->add_mapping( Address => 'B' );

=cut

has 'mapping' => (
	handles  => {add_mapping => 'set', has_mapping => 'count'},
	init_arg => undef,
	is       => 'bare',
	isa      => 'HashRef',
	reader   => '_get_mapping',
	traits   => [qw/Hash/],
	writer   => '_set_mapping',
);


sub mapping {
	my $self = shift;
	my @pairs = @_;

	if (scalar( @pairs ) == 1 && ref( $pairs[0] ) eq 'HASH') {
		$self->_set_mapping( $pairs[0] );
	} elsif (scalar @pairs) {
		my %new = @_;
		$self->_set_mapping( \%new );
	}
	return $self->_get_mapping;
}


=head3 constants

B<constants> sets output fields to literal values. L</mapping> accepts input
field names as strings. Instead of obtuse Perl tricks for marking literals,
B<constants> explicitly handles them.

If you call B<constants> with no parameters, it returns the hash reference.
Call B<constants> with a hash or hash reference and it replaces the entire
hash with the new one.

Hash keys are output field names. The L</output> class defines acceptable
field names. The hash values are literals.

  # Get the current mapping...
  my $transformation = $pipeline->constants;

  # Set the output field "Name" to the string "John Doe"...
  $pipeline->constants( Name => 'John Doe' );

=head3 add_constant

=head3 add_constants

B<add_constant> adds new fields to the current hash of literal values.
L</constants> replaces the entire hash. B<add_constant> and B<add_constants>
modify the hash, leaving all of your old literals in place.

B<add_constant> accepts key/value pairs as parameters.

  $pipeline->add_constant( Address => 'B' );

=cut

has 'constants' => (
	handles  => {add_constant => 'set', add_constants => 'set', has_constants => 'count'},
	init_arg => undef,
	is       => 'bare',
	isa      => 'HashRef',
	reader   => '_get_constants',
	traits   => [qw/Hash/],
	writer   => '_set_constants',
);


sub constants {
	my $self = shift;
	my @pairs = @_;

	if (scalar( @pairs ) == 1 && ref( $pairs[0] ) eq 'HASH') {
		$self->_set_constants( $pairs[0] );
	} elsif (scalar @pairs) {
		my %new = @_;
		$self->_set_constants( \%new );
	}
	return $self->_get_constants;
}


=head2 Saving the output

=head3 output

B<output> sets and returns the L<ETL::Pipeline::Output> object. The pipeline
uses this object for creating output records.

With no parameters, B<output> returns the current L<ETL::Pipeline::Output>
object.

You tie in a new output destination by calling B<output> with parameters...

  $pipeline->output( 'SQL', table => 'NewData' );

The first parameter is a class name. B<output> looks for a Perl module
matching this name in the C<ETL::Pipeline::Output> namespace. In this example,
the actual class name becomes C<ETL::Pipeline::Output::SQL>.

The rest of the parameters are passed directly to the C<new> method of that
class.

B<Technical Note:> Want to use a custom class from B<Local> instead of
B<ETL::Pipeline::Output>? Put a B<+> (plus sign) in front of the class name.
For example, this command uses the input class B<Local::CustomLoad>.

  $pipeline->output( '+Local::CustomLoad' );

=head3 set

B<set> assigns a value to an output field. The L<ETL::Pipeline::Output> class
defines the valid field names.

B<set> accepts two parameters...

=over

=item field

=item value

=back

B<set> places I<value> into the output I<field>.

=head3 write_record

B<write_record> outputs the current record. It is normally called by
L</process>. The pipeline makes it available in case you need to do something
special. B<write_record> takes no parameters.

=cut

has 'output' => (
	does     => 'ETL::Pipeline::Output',
	handles  => {set => 'set', write_record => 'write_record'},
	init_arg => undef,
	is       => 'bare',
	reader   => '_get_output',
	writer   => '_set_output',
);


sub output {
	my $self = shift;

	$self->_set_output( $self->_object_of_class( 'Output', @_ ) ) if (scalar @_);
	return $self->_get_output;
}


=head2 The rest of the pipeline

=head3 process

B<process> kicks off the entire data conversion process. It takes no
parameters. All of the setup is done by the other methods.

B<process> returns the B<ETL::Pipeline> object so you can do things like 
this...

  ETL::Pipeline->new( {...} )->process->chain( ... )->process;

=cut

sub process {
	my $self = shift;

	my ($success, $error) = $self->is_valid;
	croak $error unless $success;

	# Configure the input and output objects. I expect them to "die" if they
	# encounter errors. Always configure the input first. The output may use
	# information from it.
	$self->input->configure;
	$self->output->configure;

	# The actual ETL process...
	my $constants = $self->constants;
	my $mapping   = $self->mapping  ;

	$self->progress( 'start' );
	while ($self->input->next_record) {
		# User defined, record level logic...
		        $self->execute_code_ref( $self->input->debug   );
		last if $self->execute_code_ref( $self->input->stop_if );
		next if $self->execute_code_ref( $self->input->skip_if );

		# "constants" values...
		while (my ($field, $value) = each %$constants) {
			$value = $self->execute_code_ref( $value ) if ref( $value ) eq 'CODE';
			$self->output->set( $field, $value );
		}

		# "mapping" values...
		while (my ($to, $from) = each %$mapping) {
			if (ref( $from ) eq 'CODE') {
				$self->output->set( $to, $self->execute_code_ref( $from ) );
			} elsif (ref( $from ) eq 'ARRAY') {
				$self->output->set( $to, $self->input->get( @$from ) );
			} else {
				$self->output->set( $to, $self->input->get( $from ) );
			}
		}

		# "output"...
		$self->output->write_record;
	} continue { $self->progress( '' ); }
	$self->progress( 'end' );

	# Close the input and output in the opposite order we created them. This
	# safely unwinds any dependencies.
	$self->output->finish;
	$self->input->finish;

	# Return the pipeline object so that we can chain calls. Useful shorthand
	# when running multiple pipelines.
	return $self;
}


=head3 work_in

The working directory sets the default place for finding files. All searches
start here and only descend subdirectories. Temporary or output files go into
this directory as well.

B<work_in> has two forms: C<work_in( 'C:\Data' );> or
C<< work_in( search => 'C:\Data', matching => 'Ficticious' ); >>.

The first form specifies the exact directory path. In our example, the working
directory is F<C:\Data>.

The second form searches the file system for a matching directory. Take this
example...

  $etl->work_in( search => 'C:\Data', matching => 'Ficticious' );

It scans the F<C:\Data> directory for a subdirectory named F<Fictious>, like
this: F<C:\Data\Ficticious>. The search is B<not> recursive. It locates files
in the B<search> folder.

=over

=item search

Search inside this directory for a matching subdirectory. The search is not
recursive.

=item matching

Look for a subdirectory that matches this name. Wildcards and regular
expressions are supported. Searches are case insensitive.

=back

B<work_in> automatically resets L</data_in>.

=cut

has 'work_in' => (
	coerce   => 1,
	init_arg => undef,
	is       => 'bare',
	isa      => Dir,
	reader   => '_get_work_in',
	trigger  => \&_trigger_work_in,
	writer   => '_set_work_in',
);


sub work_in {
	my $self = shift;

	if (scalar( @_ ) == 1) {
		$self->_set_work_in( shift );
	} elsif(scalar( @_ ) > 1) {
		my %options = @_;

		if (defined $options{matching}) {
			my $search = hascontent( $options{search} )
				? $options{search}
				: $self->_default_search
			;
			my $next = Path::Class::Rule
				->new
				->max_depth( 1 )
				->min_depth( 1 )
				->iname( $options{matching} )
				->directory
				->iter( $search )
			;
			my $match = $next->();
			croak 'No matching directories' unless defined $match;
			$self->_set_work_in( $match );
		} else { $self->_set_work_in( $options{search} ); }
	}
	return $self->_get_work_in;
}


sub _trigger_work_in {
	my $self = shift;
	my $new  = shift;
	$self->_set_data_in( $new );
}


=head3 data_in

The working directory (L</work_in>) usually contains the raw data files. In
some cases, though, the actual data sits in a subdirectory underneath
L</work_in>. B<data_in> tells the pipeline where to find the input file.

B<data_in> accepts a search pattern - name, glob, or regular expression. It
searches L</work_in> for the first matching directory. The search is case
insensitive.

If you pass an empty string to B<data_in>, the pipeline resets B<data_in> to
the L</work_in> directory. This is useful when chaining pipelines. If one
changes the data directory, the next in line can change back.

=cut

has 'data_in' => (
	coerce   => 1,
	init_arg => undef,
	is       => 'bare',
	isa      => Dir,
	reader   => '_get_data_in',
	writer   => '_set_data_in',
);


sub data_in {
	my $self = shift;

	if (scalar @_) {
		croak 'The working folder was not set' unless defined $self->work_in;

		my $name = shift;
		if (hascontent( $name )) {
			my $next = Path::Class::Rule
				->new
				->min_depth( 1 )
				->iname( $name )
				->directory
				->iter( $self->work_in )
			;
			my $match = $next->();
			croak 'No matching directories' unless defined $match;
			$self->_set_data_in( $match );
		} else {
			$self->_set_data_in( $self->work_in );
		}
	}
	return $self->_get_data_in;
}


=head3 session

B<ETL::Pipeline> supports sessions. A session allows input and output objects 
to share information along a chain. For example, imagine 3 Excel files being
loaded into an Access database. All 3 files go into the same Access database.
The first pipeline creates the database and saves its path in the session. That
pipeline chains with a second pipeline. The second pipeline retrieves the 
Access filename from the session.

The B<session> method provides access to session level variables. As you write
your own L<ETL::Pipeline::Output> classes, they can use session variables for
sharing information.

The first parameter is the variable name. If you pass only the variable name,
B<session> returns the value.

  my $database = $etl->session( 'access_file' );
  my $identifier = $etl->session( 'session_identifier' );

A second parameter is the value. 

  $etl->session( access_file => 'C:\ExcelData.accdb' );

You can set multiple variables in one call.
  
  $etl->session( access_file => 'C:\ExcelData.accdb', name => 'Abe' );

When retrieving an array or hash reference, B<session> automatically 
derefernces it if called in a list context. In a scalar context, B<session>
returns the reference.

  # Returns the list of names as a list.
  foreach my $name ($etl->session( 'name_list' )) { ... }
  
  # Returns a list reference instead of a list.
  my $reference = $etl->session( 'name_list' );

=head3 session_has

B<session_has> checks for a specific session variable. It returns I<true> if
the variable exists and I<false> if it doesn't. 

B<session_has> only checks existence. It does not tell you if the value is 
defined.

  if ($etl->session_has( 'access_file' )) { ... }

=cut

has 'session' => (
	default => sub { {} },
	handles => {
		_get_variable => 'get', 
		session_has   => 'exists', 
		_set_variable => 'set',
	},
	init_arg => undef,
	is       => 'bare',
	isa      => 'HashRef[Any]',
	reader   => '_get_session',
	traits   => [qw/Hash/],
	writer   => '_set_session',
);


sub session {
	my $self = shift;
	
	if (scalar( @_ ) > 1) {
		my %parameters = @_;
		while (my ($key, $value) = each %parameters) {
			$self->_set_variable( $key, $value );
		}
	}
	
	my $key = shift;
	if (wantarray) {
		my $result = $self->_get_variable( $key );
		if    (ref( $result ) eq 'ARRAY') { return @$result; }
		elsif (ref( $result ) eq 'HASH' ) { return %$result; }
		else                              { return  $result; }
	} else { return $self->_get_variable( $key ); }
}


# Alternate design: Use attributes for session level information.
# Result: Discarded
# 
# Instead of keeping session variables in a hash, the class would have an 
# attribute corresponding to the session data it can keep. Since 
# ETL::Pipeline::Input and ETL::Pipeline::Output objects have access to the
# the pipeline, they can share data through the attributes.
# 
# For any session information, the developer must subclass ETL::Pipeline. The
# ETL::Pipeline::Input or ETL::Pipeline::Output classes would be tied to that
# specific subclass. And if you needed to combine two sets of session 
# variables, well that just means another class type. That's very confusing.
# 
# Attributes make development of new input and output classes very difficult.
# The hash is simple. It decouples the input/output classes from pipeline.
# That keeps customization simpler.


=head2 Other methods & attributes

=head3 is_valid

This method returns true or false. True means that the pipeline is ready to
go. False, of course, means that there's a problem. In a list context,
B<is_invalid> returns the false value and an error message. On success, the
error message is C<undef>.

=cut

sub is_valid {
	my $self = shift;
	my $error = '';

	if (!defined $self->work_in) {
		$error = 'The working folder was not set';
	} elsif (!defined $self->input) {
		$error = 'The "input" object was not set';
	} elsif (!defined $self->output) {
		$error = 'The "output" object was not set';
	} elsif (!$self->has_mapping && !$self->has_constants) {
		$error = 'The mapping was not set';
	}

	if (wantarray) {
		return (($error eq '' ? 1 : 0), $error);
	} else {
		return ($error eq '' ? 1 : 0);
	}
}


=head3 progress

This method displays the current upload progress. It is called automatically
by L</process>.

B<progress> takes one parameter - a status...

=over

=item start

The ETL process is just beginning. B<progress> displays the input file name,
if L</input> supports the L<ETL::Pipeline::Input::File> role. Otherwise,
B<progress> displays the L<ETL::Pipeline::Input> class name.

=item end

The ETL process is complete.

=item (blank)

B<progress> displays a count every 50 records, so you know that it's working.

=back

=cut

sub progress {
	my ($self, $mark) = @_;

	if (nocontent( $mark )) {
		my $count = $self->input->record_number;
		say "Processed record #$count..." unless $count % 50;
	} elsif ($mark eq 'start') {
		my $name;
		if ($self->input->does( 'Data::Pipeline::Input::File' )) {
			$name = $self->input->path->relative( $self->work_in );
		} else {
			$name = ref( $self->input );
			$name =~ s/^ETL::Pipeline::Input:://;
		}
		say "Processing '$name'...";
	} elsif ($mark eq 'end') {
		say 'Finished, cleaning up...';
	} else {
		say $mark;
	}
}


=head3 execute_code_ref

This method runs arbitrary Perl code. B<ETL::Pipeline> itself,
L<input sources|ETL::Pipeline::Input>, and
L<output destinations|ETL::Pipeline::Output> call this method.

The first parameter is the code reference. Any additional parameters are
passed directly to the code reference.

The code reference receives the B<ETL::Pipeline> object as its first parameter,
plus any additional parameters. B<execute_code_ref> also puts the
B<ETL::Pipeline> object into C<$_>;

=cut

sub execute_code_ref {
	my $self = shift;
	my $code = shift;

	if (defined( $code ) && ref( $code ) eq 'CODE') {
		local $_;
		$_ = $self;
		return $code->( $self, @_ );
	} else { return undef; }
}


=head2 For overriding in a subclass

=head3 _default_search

L</work_in> searches inside this directory if you do not specify a B<search>
parameter. It defaults to the current directory. Override this in the subclass
with the correct B<default> for your environment.

=cut

has '_default_search' => (
	default  => '.',
	init_arg => undef,
	is       => 'ro',
	isa      => 'Str',
);


=head3 _object_of_class

This private method creates the L<ETL::Pipeline::Input> and
L<ETL::Pipeline::Output> objects. It allows me to centralize the error
handling. The program dies if there's an error. It means that something is
wrong with the corresponding class. And I don't want to hide those errors.
You can only fix errors if you know about them.

Override or modify this method if you want to perform extra checks.

The first parameter is a string with either I<Input> or I<Output>.
B<_object_of_class> appends this value onto C<ETL::Pipeline>. For example,
I<'Input'> becomes C<ETL::Pipeline::Input>.

The rest of the parameters are passed directly into the constructor for
the class B<_object_of_class> instantiates.

=cut

sub _object_of_class {
	my $self = shift;
	my $action = shift;

	my @arguments = @_;
	@arguments = @{$arguments[0]} if (scalar( @arguments ) == 1 && ref( $arguments[0] ) eq 'ARRAY');

	my $class = shift @arguments;
	if ($class =~ m/^\+/) {
		$class =~ s/^\+//;
	} elsif ($class !~ m/^ETL::Pipeline::$action/) {
		$class = "ETL::Pipeline::$action::$class";
	}

	my %attributes = @arguments;
	$attributes{pipeline} = $self;

	my $object = eval "use $class; $class->new( \%attributes )";
	croak "Error creating $class...\n$@\n" unless defined $object;
	return $object;
}


=head1 ADVANCED TOPICS

=head2 Multiple input sources

It is not uncommon to receive your data spread across more than one file. How
do you guarantee that each pipeline pulls files from the same working directory
(L</work_in>)? You L</chain> the pipelines together.

The L</chain> method works like this...

  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', find => 'main.xlsx'               ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'     },
    constants => {Type => 1, Information => 'Demographic'    },
    output    => ['SQL', table => 'NewData'                  ],
  } )->process->chain( {
    input     => ['Excel', find => 'notes.xlsx'         ],
    mapping   => {User => 'A', Text => 'B', Date => 'C' },
    constants => {Type => 2, Information => 'Note'      },
    output    => ['SQL', table => 'NewData'             ],
  } )->process;

When the first pipeline finishes, it creates a new object with the same
L</work_in>. The code then calls L</process> on the new object. You can also
use the B<chain> constructor argument...

  my $pipeline1 = ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', find => 'main.xlsx'               ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'     },
    constants => {Type => 1, Information => 'Demographic'    },
    output    => ['SQL', table => 'NewData'                  ],
  } )->process;
  my $pipeline2 = ETL::Pipeline->new( {
    input     => ['Excel', find => 'notes.xlsx'         ],
    chain     => $pipeline1,
    mapping   => {User => 'A', Text => 'B', Date => 'C' },
    constants => {Type => 2, Information => 'Note'      },
    output    => ['SQL', table => 'NewData'             ],
  } )->process;

In both of these styles, the second pipeline copies L</work_in> from the first
pipeline. There is no difference between the L</chain> method or B<chain>
constructor argument. Pick the one that best suits your programming style.

=head2 Writing an input source

B<ETL::Pipeline> provides some basic, generic input sources. Invariable, you
will come across data that doesn't fit one of these. No problem.
B<ETL::Pipeline> lets you create your own input sources.

An input source is a L<Moose> class that implements the L<ETL::Pipeline::Input>
role. The role requires that you define certain methods. B<ETL::Pipeline> makes
use of those methods. Name your class B<ETL::Pipeline::Input::*> and the
L</input> method can find it automatically.

See L<ETL::Pipeline::Input> for more details.

=head2 Writing an output destination

B<ETL::Pipeline> does not have any default output destinations. Output
destinations are customized. You have something you want done with the data.
And that something intimately ties into your specific business. You will have
to write at least one output destination to do anything useful.

An output destination is a L<Moose> class that implements the
L<ETL::Pipeline::Output> role. The role defines required methods and a simple
hash for storing the new record in memory. B<ETL::Pipeline> makes use of the
methods. Name your class B<ETL::Pipeline::Output::*> and the L</output> method
can find it automatically.

See L<ETL::Pipeline::Output> for more details.

=head2 Why are the inputs and outputs separate?

Wouldn't it make sense to have an input source for Excel and an output
destination for Excel?

Input sources are generic. It takes the same code to read from one Excel file
as another. Output destinations, on the other hand, are customized for your
business - with data validation and business logic.

B<ETL::Pipeline> assumes that you have multiple input sources. Different
feeds use different formats. But output destinations will be much fewer.
You're writing data into a centralized place.

For these reasons, it makes sense to keep the input sources and output
destinations separate. You can easily add more inputs without affecting the
outputs.

=head1 SEE ALSO

L<ETL::Pipeline::Input>, L<ETL::Pipeline::Output>, L<ETL::Pipeline::Mapping>

=head2 Input Source Formats

L<ETL::Pipeline::Input::Excel>, L<ETL::Pipeline::Input::DelimitedText>

=head1 REPOSITORY

L<https://github.com/rbwohlfarth/ETL-Pipeline>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016  Robert Wohlfarth

This module is free software; you can redistribute it and/or modify it 
under the same terms as Perl 5.10.0. For more details, see the full text 
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but 
without any warranty; without even the implied

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
