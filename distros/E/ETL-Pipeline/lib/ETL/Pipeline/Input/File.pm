=pod

=head1 NAME

ETL::Pipeline::Input::File - Role for file based input sources

=head1 SYNOPSIS

  # In the input source...
  use Moose;
  with 'ETL::Pipeline::Input::File';
  ...

  # In the ETL::Pipeline script...
  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', matching => qr/\.xlsx?$/          ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'     },
    constants => {Type => 1, Information => 'Demographic'    },
    output    => ['SQL', table => 'NewData'                  ],
  } )->process;

  # Or with a specific file...
  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', file => 'ExportedData.xlsx'       ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'     },
    constants => {Type => 1, Information => 'Demographic'    },
    output    => ['SQL', table => 'NewData'                  ],
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::File> provides methods and attributes common to
file based input sources. It makes file searches available for any file
format. With B<ETL::Pipeline::Input::File>, you can...

=over

=item Specify the exact path to the file.

=item Or search the file system for a matching name.

=back

For setting an exact path, see the L</path> attribute. For searches, see the
L</find> attribute.

=head2 File vs. DataFile

L<ETL::Pipeline::Input::DataFile> extends B<ETL::Pipeline::Input::File>. 
This role, B<ETL::Pipeline::Input::File> makes no assumptions about the file
format. It works CSV text files, MS Access databases, spread sheets, XML, or
any other format found on disk.

L<ETL::Pipeline::Input::DataFile> assumes that each record is stored on one
row. And the data is divided into fields (columns). Basically, 

=cut

package ETL::Pipeline::Input::File;
use Moose::Role;

use 5.014000;
use Carp;
use MooseX::Types::Path::Class qw/Dir File/;
use Path::Class::Rule;
use String::Util qw/hascontent/;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 matching

B<matching> locates the first file that matches the given pattern. The 
pattern can be a glob or regular expression. B<matching> sets L</file> 
to the first file that matches. Search patterns are case insensitive.

  # Search using a regular expression...
  $etl->input( 'Excel', matching => qr/\.xlsx$/i );
  
  # Search using a file glob...
  $etl->input( 'Excel', matching => '*.xlsx' );

For very weird cases, B<matching> also accepts a code reference. 
B<matching> executes the subroutine against the file names. B<matching> 
sets L</file> to the first file where the subroutine returns a true 
value.

B<matching> passes two parameters into the subroutine...

=over

=item The L<ETL::Pipeline> object

=item The L<Path::Class::File> object

=back

  # File larger than 2K...
  $etl->input( 'Excel', matching => sub {
    my ($etl, $file) = @_;
    return (!$file->is_dir && $file->size > 2048 ? 1 : 0);
  } );

B<matching> searches inside the L<ETL::Pipeline/data_in> directory.

=cut

has 'matching' => (
	is  => 'ro',
	isa => 'Maybe[CodeRef|RegexpRef|Str]',
);


=head3 file

B<file> holds a L<Path::Class::File> object pointing to the input file. 
If L<ETL::Pipeline/input> does not set B<file>, then the L</matching> 
attribute searches the file system for a match. If 
L<ETL::Pipeline/input> sets B<file>, then L</matching> is ignored.

B<file> is relative to L<ETL::Pipeline/data_in>, unless you set it to an
absolute path name. With L</matching>, the search is always limited to
L<ETL::Pipeline/data_in>.

  # File inside of "data_in"...
  $etl->input( 'Excel', file => 'Data.xlsx' );
  
  # Absolute path name...
  $etl->input( 'Excel', file => 'C:\Data.xlsx' );

=cut

has 'file' => (
	builder => '_build_file',
	coerce  => 1,
	is      => 'ro',
	isa     => File,
	lazy    => 1,
	trigger => \&_trigger_file,
	writer  => '_set_file',
);


sub _build_file {
	my $self = shift;

	my $rule     = Path::Class::Rule->new;
	my $pattern  = $self->matching;
	my $pipeline = $self->pipeline;

	if (ref( $pattern ) eq 'CODE') {
		my $search = $rule->iter( $pipeline->data_in );
		while (my $file = $search->()) {
			return $file if $pipeline->execute_code_ref( $pattern, $file );
		}
		croak 'No file matched for "input"';
		return undef;
	} else {
		$rule->file;
		$rule->iname( $pattern ) if defined $pattern;
		my $search = $rule->iter( $pipeline->data_in );

		my $file = $search->();
		croak 'No file matched for "input"' unless defined $file;
		return $file;
	}
}


sub _trigger_file {
	my ($self, $old, $new) = @_;
	$self->_set_file( $new->absolute( $self->pipeline->data_in ) )
		if defined( $new ) && $new->is_relative;
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::TabularFile>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
