=pod

=head1 NAME

ETL::Pipeline::Input::File - Role for file based input sources

=head1 SYNOPSIS

  # In the input source...
  use Moose;
  with 'ETL::Pipeline::Input';
  with 'ETL::Pipeline::Input::File';
  ...

  # In the ETL::Pipeline script...
  ETL::Pipeline->new( {
    work_in   => {root => 'C:\Data', iname => qr/Ficticious/},
    input     => ['Excel', iname => qr/\.xlsx?$/            ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'    },
    constants => {Type => 1, Information => 'Demographic'   },
    output    => ['SQL', table => 'NewData'                 ],
  } )->process;

  # Or with a specific file...
  ETL::Pipeline->new( {
    work_in   => {root => 'C:\Data', iname => qr/Ficticious/},
    input     => ['Excel', iname => 'ExportedData.xlsx'     ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'    },
    constants => {Type => 1, Information => 'Demographic'   },
    output    => ['SQL', table => 'NewData'                 ],
  } )->process;

=head1 DESCRIPTION

This role adds functionality and attributes common to all file based input
sources. It is a quick and easy way to create new sources with the ability
to search directories. Useful when the file name changes.

B<ETL::Pipeline::Input::File> works with a single source file. To process an
entire directory of files, use L<ETL::Pipeline::Input::FileListing> instead.

=cut

package ETL::Pipeline::Input::File;

use 5.014000;

use Carp;
use Moose::Role;
use MooseX::Types::Path::Class qw/File/;
use Path::Class::Rule;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::File> accepts any of the tests provided by
L<Path::Iterator::Rule>. The value of the argument is passed directly into the
test. For boolean tests (e.g. readable, exists, etc.), pass an C<undef> value.

B<ETL::Pipeline::Input::File> automatically applies the C<file> filter. Do not
pass C<file> through L<ETL::Pipeline/input>.

C<iname> is the most common one that I use. It matches the file name, supports
wildcards and regular expressions, and is case insensitive.

  # Search using a regular expression...
  $etl->input( 'Excel', iname => qr/\.xlsx$/ );

  # Search using a file glob...
  $etl->input( 'Excel', iname => '*.xlsx' );

The code throws an error if no files match the criteria. Only the first match
is used. If you want to match more than one file, use
L<ETL::Pipeline::Input::File::List> instead.

=cut

# BUILD in the consuming class will override this one. I add a fake BUILD in
# case the class doesn't have one. The method modifier then runs the code to
# extract search criteria from the constructor arguments. The modifier will
# run even if the consuming class has its own BUILD.
# https://www.perlmonks.org/?node_id=837369
sub BUILD {}

after 'BUILD' => sub {
	my $self = shift;
	my $arguments = shift;

	while (my ($name, $value) = each %$arguments) {
		$self->_add_criteria( $name, $value )
			if $name ne 'file' && Path::Class::Rule->can( $name );
	}
};


# Execute the actual search AFTER everything is set in stone. This lets a script
# create the input source before it calls "work_in".
before 'run' => sub {
	my ($self, $etl) = @_;

	if (defined $self->path) {
		$self->_set_path( $self->path->absolute( $etl->data_in ) )
			if $self->path->is_relative;
	} else {
		# Build the search rule from the criteria passed to the constructor.
		my $rule = Path::Class::Rule->new->file;
		foreach my $pair ($self->_search_criteria) {
			my $name  = $pair->[0];
			my $value = $pair->[1];

			eval "\$rule = \$rule->$name( \$value )";
			croak $@ unless $@ eq '';
		}
		my @matches = $rule->all( $etl->data_in );

		# Find the first file that matches all of the criteria.
		if (scalar( @matches ) < 1) {
			croak 'No files matched the search criteria';
		} elsif (!-r $matches[0]) {
			croak "You do not have permission to read '$matches[0]'";
		} else {
			$self->_set_path( $matches[0] );
			$self->source( $matches[0]->relative( $etl->work_in )->stringify );
			$etl->status( 'INFO', 'File name' );
		}
	}
};


=head3 path

Optional. When passed to L<ETL::Pipeline/input>, this file becomes the input
source. No search or matching is performed. If you specify a relative path, it
is relative to L</data_in>.

Once the object has been created, this attribute holds the file that matched
search criteria. It should be used by your input source class as the file name.

  # File inside of "data_in"...
  $etl->input( 'Excel', path => 'Data.xlsx' );

  # Absolute path name...
  $etl->input( 'Excel', path => 'C:\Data.xlsx' );

  # Inside the input source class...
  open my $io, '<', $self->path;

=cut

has 'path' => (
	coerce => 1,
	is     => 'ro',
	isa    => File,
	writer => '_set_path',
);


=head3 skipping

Optional. B<skipping> jumps over a certain number of rows/lines in the beginning
of the file. Report formats often contain extra headers - even before the column
names. B<skipping> ignores those and starts processing at the data.

B<Note:> B<skipping> is applied I<before> reading column names.

B<skipping> accepts either an integer or code reference. An integer represents
the number of rows/records to ignore. For a code reference, the code discards
records until the subroutine returns a I<true> value.

  # Bypass the first three rows.
  $etl->input( 'Excel', skipping => 3 );

  # Bypass until we find something in column 'C'.
  $etl->input( 'Excel', skipping => sub { hascontent( $_->get( 'C' ) ) } );

The exact nature of the I<record> depends on the input file. For example files,
Excel files will send a data row as a hash. But a CSV file would send a single
line of plain text with no parsing. See the input source to find out exactly
what it sends.

If your input source implements B<skipping>, you can pass whatever parameters
you want. For consistency, I recommend passing the raw data. If you are jumping
over report headers, they may not be formatted.

=cut

has 'skipping' => (
	default => 0,
	is      => 'ro',
	isa     => 'CodeRef|Int',
);


#-------------------------------------------------------------------------------
# Internal methods and attributes

# Search criteria for the file list. I capture the criteria from the constructor
# but don't build the iterator until the loop kicks off. Since the search
# depends on "data_in", this allows the user to setup the pipeline in whatever
# order they want and it will do the right thing.
has '_criteria' => (
	default => sub { {} },
	handles => {_add_criteria => 'set', _search_criteria => 'kv'},
	is      => 'ro',
	isa     => 'HashRef[Any]',
	traits  => [qw/Hash/],
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File::List>,
L<Path::Iterator::Rule>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
