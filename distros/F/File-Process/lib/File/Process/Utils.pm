package File::Process::Utils;

use strict;
use warnings;

use File::Process qw(pre process_file :booleans);
use Text::CSV_XS;

use parent qw(Exporter);

our @EXPORT_OK = qw(process_csv);

our $VERSION = '0.09';

########################################################################
sub process_csv {
########################################################################
  my ( $file, %options ) = @_;

  my $csv_options = $options{csv_options} // {};

  my $csv = Text::CSV_XS->new($csv_options);

  $options{chomp} //= $TRUE;

  my ($csv_lines) = process_file(
    $file,
    csv         => $csv,
    chomp       => $options{chomp},
    has_headers => $options{has_headers},
    pre         => sub {
      my ( $file, $args ) = @_;

      my ( $fh, $all_lines ) = pre( $file, $args );

      if ( $args->{'has_headers'} ) {
        my @column_names = $args->{csv}->getline($fh);
        $args->{csv}->column_names(@column_names);
      }

      return ( $fh, $all_lines );
    },
    next_line => sub {
      my ( $fh, $all_lines, $args ) = @_;
      my $ref = $args->{csv}->getline_hr($fh);
      return $ref;
    }
  );

  return $csv_lines;
}

1;

__END__

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

File::Process::Utils - commonly used recipes for File::Process

=head1 SYNOPSIS

 use File::Process::Utils qw(process_csv);

 my $obj = process_csv('foo.csv', has_headers => 1);

=head1 DESCRIPTION

Set of utilities that represent some common use cases for L<File::Process>.

=head1 METHODS AND SUBROUTINES

=head2 process_csv

 process_csv(file, options)

Reads a CSV files using L<Text::CSV_XS> and returns an array of hashes.

Example:

 my $obj = process_file(
   'foo.csv',
   has_header  => 1,
   csv_options => { sep_char "\t" },
   );

=over

=item file

Filename or file handle of an open CSV file.

=item options

List of options described below.

=over 5

=item has_header

Boolean that indicates whether or not the first line of the CSV file
is should be considred the column titles.  These will be used as the
hash keys.

=item csv_options

Hash of options that will be passed through to L<Text::CSV_XS>

=back

=back

=head1 SEE ALSO

L<File::Process>, L<Text::ASCIITable::EasyTable>

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut
