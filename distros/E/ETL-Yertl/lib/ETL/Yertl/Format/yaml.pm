package ETL::Yertl::Format::yaml;
our $VERSION = '0.033';
# ABSTRACT: YAML read/write support for Yertl

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

#pod =attr format_module
#pod
#pod The module being used for this format. Possible modules, in order of importance:
#pod
#pod =over 4
#pod
#pod =item L<YAML::XS> (any version)
#pod
#pod =item L<YAML::Syck> (any version)
#pod
#pod =item L<YAML> (any version)
#pod
#pod =item L<YAML::Tiny> (any version)
#pod
#pod =back
#pod
#pod =cut

# Pairs of module => supported version
our @FORMAT_MODULES = (
    'YAML::XS' => 0,
    'YAML::Syck' => 0,
    'YAML' => 0,
    'YAML::Tiny' => 0,
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
        die "Could not load a formatter for YAML. Please install one of the following modules:\n"
            . join( "",
                map { sprintf "\t%s (%s)", $_->[0], $_->[1] ? "version $_->[1]" : "Any version" }
                pairs @FORMAT_MODULES
            )
            . "\n";
    },
);


# Hash of MODULE => formatter sub
my %FORMAT_SUB = (

    'YAML::XS' => {
        decode => sub {
            my ( $self, $msg ) = @_;
            return YAML::XS::Load( $msg );
        },

        write => sub {
            my $self = shift;
            return YAML::XS::Dump( @_ );
        },

        read => sub {
            my $self = shift;
            my $yaml = do { local $/; readline $self->input };
            return $yaml ? YAML::XS::Load( $yaml ) : ();
        },

    },

    'YAML::Syck' => {
        decode => sub {
            my ( $self, $msg ) = @_;
            return YAML::Syck::Load( $msg );
        },

        write => sub {
            my $self = shift;
            return YAML::Syck::Dump( @_ );
        },

        read => sub {
            my $self = shift;
            my $yaml = do { local $/; readline $self->input };
            return $yaml ? YAML::Syck::Load( $yaml ) : ();
        },

    },

    'YAML' => {
        decode => sub {
            my ( $self, $msg ) = @_;
            return YAML::Load( $msg );
        },

        write => sub {
            my $self = shift;
            return YAML::Dump( @_ );
        },

        read => sub {
            my $self = shift;
            my $yaml = do { local $/; readline $self->input };
            return $yaml ? YAML::Load( $yaml ) : ();
        },

    },

    'YAML::Tiny' => {
        decode => sub {
            my ( $self, $msg ) = @_;
            return YAML::Tiny::Load( $msg );
        },

        write => sub {
            my $self = shift;
            return YAML::Tiny::Dump( @_ );
        },

        read => sub {
            my $self = shift;
            my $yaml = do { local $/; readline $self->input };
            return $yaml ? YAML::Tiny::Load( $yaml ) : ();
        },

    },

);

#pod =method write( DOCUMENTS )
#pod
#pod Convert the given C<DOCUMENTS> to YAML. Returns a YAML string.
#pod
#pod =cut

sub write {
    my $self = shift;
    return $FORMAT_SUB{ $self->format_module }{write}->( $self, @_ );
}

#pod =method read()
#pod
#pod Read a YAML string from L<input> and return all the documents.
#pod
#pod =cut

sub read {
    my $self = shift;
    return $FORMAT_SUB{ $self->format_module }{read}->( $self );
}

#pod =method decode
#pod
#pod     my $msg = $yaml->decode( $bytes );
#pod
#pod Decode the given bytes into a single data structure. C<$bytes> must be
#pod a single YAML document.
#pod
#pod =cut

sub decode {
    my ( $self, $msg ) = @_;
    return $FORMAT_SUB{ $self->format_module }{decode}->( $self, $msg );
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Format::yaml - YAML read/write support for Yertl

=head1 VERSION

version 0.033

=head1 ATTRIBUTES

=head2 input

The filehandle to read from for input.

=head2 format_module

The module being used for this format. Possible modules, in order of importance:

=over 4

=item L<YAML::XS> (any version)

=item L<YAML::Syck> (any version)

=item L<YAML> (any version)

=item L<YAML::Tiny> (any version)

=back

=head1 METHODS

=head2 write( DOCUMENTS )

Convert the given C<DOCUMENTS> to YAML. Returns a YAML string.

=head2 read()

Read a YAML string from L<input> and return all the documents.

=head2 decode

    my $msg = $yaml->decode( $bytes );

Decode the given bytes into a single data structure. C<$bytes> must be
a single YAML document.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
