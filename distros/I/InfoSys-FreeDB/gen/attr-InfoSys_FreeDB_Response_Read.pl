use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::Read";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB read response',
        abstract => 'FreeDB read response',
        synopsis => &::read_synopsis( 'syn-http.pl', '.' ),
        description => <<EOF,
C<${pkg}> contains information about FreeDB read responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'entry',
             allow_isa => [ qw(InfoSys::FreeDB::Entry) ],
             short_description => 'the entry which was read',
        },
    ],
    constr_opt => [
        {
            method_name => 'new_from_content_ref',
            parameter_description => 'CONTENT_REF',
            description => <<EOF,
Creates a new C<$pkg> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
    my $class = shift;
    my $content_ref = shift;

    # Convert $opt->{content_ref} to @content_ref
    my @content_ref = split(/[\n\r]+/, ${$content_ref} );

    # Parse first line
    my $line = shift(@content_ref);
    my ($code, $tail) = $line =~ /$CODE_RX/;
    defined ($code) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Read::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 210) {
        pop( @content_ref);
        require InfoSys::FreeDB::Entry;
        %opt = (
            code => $code,
            result => 'OK',
            entry => InfoSys::FreeDB::Entry->new_from_array_ref( \@content_ref),
        );
    }
    elsif ($code == 211) {
        pop(@content_ref);
        my @match = ();
        require InfoSys::FreeDB::Match;
        foreach my $line (@content_ref) {
            my @line = split(/\s+/, $line, 3);
            push(@match, InfoSys::FreeDB::Match->new( {
                categ => $line[0],
                discid => $line[1],
                dtitle => $line[2],
            } ) );
        }
        %opt = (
            code => $code,
            result => 'Found inexact matches',
            match => \@match,
        );
    }
    elsif ($code == 401) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Specified CDDB entry not found',
        );
    }
    elsif ($code == 402) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Server error',
        );
    }
    elsif ($code == 403) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Database entry is corrupt',
        );
    }
    elsif ($code == 409) {
        %opt = (
            code => $code,
            error => 1,
            result => 'No handshake',
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Read::new_from_content_ref, unknown code '$code' returned. Allowed codes are 210, 211, 401, 402, 403 and 409.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
EOF
        },
    ],
    meth_opt => [
    ],
    use_opt => [
        {
            dependency_name => 'InfoSys::FreeDB::Response',
            import_list => [ 'qw(:line_parse)' ],
        },
    ],
    sym_opt => [
    ],
} );
