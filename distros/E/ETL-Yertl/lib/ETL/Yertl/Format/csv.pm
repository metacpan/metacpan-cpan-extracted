package ETL::Yertl::Format::csv;
our $VERSION = '0.029';
# ABSTRACT: CSV read/write support for Yertl

use ETL::Yertl 'Class';
use Module::Runtime qw( use_module );
use List::Util qw( pairs pairkeys pairfirst );

#pod =attr input
#pod
#pod The filehandle to read from for input.
#pod
#pod =cut

has input => (
    is => 'ro',
    isa => FileHandle,
);

#pod =attr delimiter
#pod
#pod The delimited to use. Defaults to C<,>. Other common values include C<:>.
#pod
#pod =cut

has delimiter => (
    is => 'ro',
    isa => Str,
    default => ',',
);

#pod =attr format_module
#pod
#pod The module being used for this format. Possible modules, in order of importance:
#pod
#pod =over 4
#pod
#pod =item L<Text::CSV_XS> (any version)
#pod
#pod =item L<Text::CSV> (any version)
#pod
#pod =back
#pod
#pod =cut

# Pairs of module => supported version
our @FORMAT_MODULES = (
    'Text::CSV_XS' => 0,
    'Text::CSV' => 0,
);

has format_module => (
    is => 'rw',
    isa => sub {
        my ( $format_module ) = @_;
        die "format_module must be one of: " . join( " ", pairkeys @FORMAT_MODULES ) . "\n"
            unless pairfirst { $a eq $format_module } @FORMAT_MODULES;
        eval {
            use_module( $format_module );
        };
        if ( $@ ) {
            die "Could not load format module '$format_module': $@";
        }
    },
    lazy => 1,
    default => sub {
        for my $format_module ( pairs @FORMAT_MODULES ) {
            eval {
                # Prototypes on use_module() make @$format_module not work correctly
                use_module( $format_module->[0], $format_module->[1] );
            };
            if ( !$@ ) {
                return $format_module->[0];
            }
        }
        die "Could not load a formatter for CSV. Please install one of the following modules:\n"
            . join( "",
                map { sprintf "\t%s (%s)", $_->[0], $_->[1] ? "version $_->[1]" : "Any version" }
                pairs @FORMAT_MODULES
            )
            . "\n";
    },
);

has _field_names => (
    is => 'rw',
    isa => ArrayRef[Str],
    default => sub { [] },
);

has _csv => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        $self->format_module->new({
            binary => 1, eol => $\,
            sep_char => $self->delimiter,
        });
    },
);

#pod =method write( DOCUMENTS )
#pod
#pod Convert the given C<DOCUMENTS> to CSV. Returns a CSV string.
#pod
#pod =cut

sub write {
    my ( $self, @docs ) = @_;
    my $csv = $self->_csv;
    my $str = '';
    my @names = @{ $self->_field_names };

    if ( !@names ) {
        @names = sort keys %{ $docs[0] };
        $csv->combine( @names );
        $str .= $csv->string . $/;
        $self->_field_names( \@names );
    }

    for my $doc ( @docs ) {
        $csv->combine( map { $doc->{ $_ } } @names );
        $str .= $csv->string . $/;
    }

    return $str;
}

#pod =method read()
#pod
#pod Read a CSV string from L<input> and return all the documents.
#pod
#pod =cut

sub read {
    my ( $self ) = @_;
    my $fh = $self->input || die "No input filehandle";
    my $csv = $self->_csv;
    my @names = @{ $self->_field_names };

    if ( !@names ) {
        @names = @{ $csv->getline( $fh ) };
        $self->_field_names( \@names );
    }

    my @docs;
    while ( my $row = $csv->getline( $fh ) ) {
        push @docs, { map {; $names[ $_ ] => $row->[ $_ ] } 0..$#{ $row } };
    }

    return @docs;
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Format::csv - CSV read/write support for Yertl

=head1 VERSION

version 0.029

=head1 ATTRIBUTES

=head2 input

The filehandle to read from for input.

=head2 delimiter

The delimited to use. Defaults to C<,>. Other common values include C<:>.

=head2 format_module

The module being used for this format. Possible modules, in order of importance:

=over 4

=item L<Text::CSV_XS> (any version)

=item L<Text::CSV> (any version)

=back

=head1 METHODS

=head2 write( DOCUMENTS )

Convert the given C<DOCUMENTS> to CSV. Returns a CSV string.

=head2 read()

Read a CSV string from L<input> and return all the documents.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
