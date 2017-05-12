package Iterator::Simple::Util::CSV;
{
  $Iterator::Simple::Util::CSV::VERSION = '0.002';
}

# ABSTRACT: Utility to iterate over CSV data

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ 'icsv' ]
};

use Text::CSV_XS;
use IO::Handle;
use IO::File;
use Iterator::Simple qw( iterator );
use Carp qw( croak );

sub icsv {
    my $input = shift;
    my $opts = @_ == 1 ? shift @_ : +{ @_ };

    my $use_header   = delete $opts->{use_header};
    my $skip_header  = delete $opts->{skip_header};
    my $column_names = delete $opts->{column_names};    
    
    my $io;
    if ( ref( $input ) ) {
        $io = $input;
    }
    elsif ( $input eq '-' ) {
        $io = IO::Handle->new->fdopen( fileno(STDIN), 'r' );
    }   
    else {
        $io = IO::File->new( $input, O_RDONLY )
            or croak "Open $input: $!";
    }
    
    my $csv = Text::CSV_XS->new( $opts );

    my $fetch_row_method = 'getline';
    
    if ( $skip_header ) {
        $io->getline;
    }
    elsif ( $use_header ) {
        $column_names = $csv->getline( $io );
    }

    if ( $column_names ) {                
        $csv->column_names( $column_names );
        $fetch_row_method = 'getline_hr';
    }

    return iterator {
        return if $io->eof;
        $csv->$fetch_row_method( $io )
            or croak "CSV parse error: " . $csv->error_diag;
    };
}

1;



=pod

=head1 NAME

Iterator::Simple::Util::CSV - Utility to iterate over CSV data

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Iterator::Simple::Util::CSV qw( icsv );

  # Iterate over a CSV file one line at a time
  my $it = icsv( $some_csv_file );
  my $r= $it->next; # returns an array ref

  # Same, but skip the header
  my $it = icsv( $some_csv_file, skip_header => 1 );

  # Parse the header, return each row as a hash ref keyed on the
  # header columns
  my $it = icsv( $some_csv_file, use_header => 1 );
  my $r = $it->next; # returns a hash ref

  # Skip the header, specify the column keys
  my $it = icsv( $some_csv_file, skip_header => 1, column_name => [ qw( col1 col2 col3 ) ] );
  my $r = $it->next; returns a hash ref, keys col1, col2, col3

=head1 DESCRIPTION

This module combines L<Iterator::Simple> and L<Text::CSV_XS> to
provide a simple way of iterating over CSV files. It exports a single
function, C<icsv> that constructs an iterator:

=over 4

=item icsv( I<$input>, [I<opt> => I<value> ...] )

I<$input> can be a filename or an C<IO::Handle> object. If the
filename is C<->, the iterator will read from STDIN. Options may be
specified as a list or a hash reference. The options I<use_header>,
I<skip_header> and I<column_names> control the behaviour of this
module (see the synopsis for details); any other options are passed
unchanged to the L<Text::CSV_XS> constructor.

=back

=head2 SEE ALSO

L<Iterator::Simple>, L<Text::CSV_XS>.

=head1 AUTHOR

Ray Miller <raym@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ray Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

