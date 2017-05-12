
package Log::Parallel::Parsers;

use strict;
use warnings;
require Exporter;
require Log::Parallel::TSV;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_parser);
our @EXPORT_OK = (@EXPORT, qw(register_parser));

my %parsers;

sub register_parser
{
	my ($name, $callback) = @_;
	$parsers{$name} = $callback;
}

sub get_parser
{
	my ($name, @args) = @_;
	die "no such parser '$name'\n" unless $parsers{$name};
	$parsers{$name}->(@args);
}

package Log::Parallel::Parsers::BaseClass;

use strict;
use warnings;

sub register_parser
{
	my $self = shift;
	my $pkg = ref($self) ? ref($self) : $self;
	my $name = $pkg;
	$name =~ s/.*:://;
	Log::Parallel::Parsers::register_parser( $name => sub { $self->return_parser(@_) } );
}

sub return_parser { die };

1;

__END__

=head1 SYNOPSIS

 my $pfunc = get_parser('JSON', $filehandle, %opts);

 while ($log = &$pfunc()) {
 }

=head1 DESCRIPTION

Each format that we may want to read is specified in the 
logging configuration file by a format name.   Log::Parallel::Parsers
is the API used to turn one of those names into a perl code
to parse the input.

The output from the parser is an anonymous hash, C<$log>. 

Parsers are used to read both raw inputs to the logging system and
files produced by L<Log::Parallel::Writers> as intermediate steps
in the processing of logs.

When processing raw inputs, the output is expected to include a
C<time> column and be in time order.

=head2 C<%opts> keys for intermediate files

When opening an intermediate file created by L<Log::Parallel::Writers>, 
the following C<%opts> keys will be defined:

=over

=item C<header>

A header record as returned by L<Log::Parallel::Writers>.  

=back

=head2 C<%opts> keys for raw inputs

When opening a raw input file, the following C<%opts> keys will
be defined:

=over

=item C<time>

A C<time_t> representing the start time for the file.

=item C<span>

The length of time (in seconds) the file is supposed to cover.
(Not adjusted for daylight savings time.)

=back

=head1 SEE ALSO

L<Log::Parallel::TSV>

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

