package Markdown::Compiler::Source;
use Moo;

has source => (
    is       => 'ro',
    required => 1,
);

has default_metatype => (
    is      => 'ro',
    default => sub { 'YAML' },
);

has body => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    default  => sub { shift->parsed->{body} },
);

has metadata => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    default  => sub { shift->parsed->{metadata} },

);

has metatype => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    default  => sub { shift->parsed->{metatype} },
);

has has_metadata => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_has_metadata',
);

has parsed => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_parsed'
);

sub _build_parsed {
    my ( $self ) = @_;

    # If we do not have any metadata, act as if we have a
    # blank file of the default type.
    if ( ! $self->has_metadata ) {
        return {
            metadata => '',
            metatype => $self->default_metatype,
            body     => $self->source,
        };
    }

    # File spec:
    # Named metadata:
    #       --- [Name]
    #       metadata.....
    #       ---
    #       body......
    # Unamed/Default metadata:
    #       ---
    #       metadata.....
    #       ---
    #       body......

    my @source = split /\n/, $self->source;
    my $is_first_line       = 1;
    my $is_metadata_section = 1;

    my $parsed = {
        metadata => '',
        metatype => $self->default_metatype,
        body     => '',
    };

    foreach my $line ( split( /\n/, $self->source )) {
        $line = "$line\n";

        # First line, see if we have an alternative metatype.
        if ( $is_first_line ) {
            if ( $line =~ /^---\s+(\S+)\s?$/) {
                $parsed->{metatype} = $1;
            } 
            $is_first_line = 0;            
            next;
        }

        # Now each line from the second line, until we close
        # the metadata section.
        if ( $is_metadata_section ) {
            if ( $line =~ /^---\s*$/ ) {
                $is_metadata_section = 0; # No longer processing metadata.
                next;
            }
            # Still processing metadata, add line and then move to the next
            # line.
            $parsed->{metadata} .= $line;
            next;
        }

        # Now we are in the lines after the metadata section of the file.
        $parsed->{body} .= $line;
    }

    return $parsed;
}

sub _build_has_metadata {
    my ( $self ) = @_;

    # Get the first three chars from the source.
    my $marker = substr($self->source,0,3);

    return 0 unless $marker;
    return 0 unless length($marker) == 3;
    return 0 unless $marker eq '---';

    return 1;
}

1;
