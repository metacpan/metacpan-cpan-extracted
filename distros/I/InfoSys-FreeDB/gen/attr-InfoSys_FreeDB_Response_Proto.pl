use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::Proto";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB proto response',
        abstract => 'FreeDB proto response',
        synopsis => &::read_synopsis( 'syn-cddbp-proto.pl', '.' ),
        description => <<EOF,
C<${pkg}> contains information about FreeDB proto responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'cur_level',
             short_description => 'the current protocol level',
             default_value => 0,
        },
        {
             method_factory_name => 'supported_level',
             short_description => 'the supported protocol level',
             default_value => 0,
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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Proto::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    my @tail = split(/[,\s]+/, $tail, 7);
    if ($code == 200) {
        pop(@content_ref);
        %opt = (
            code => $code,
            result => 'CDDB protocol level',
            cur_level => $tail[4],
            supported_level => $tail[6],
        );
    }
    elsif ($code == 201) {
        %opt = (
            code => $code,
            result => 'OK, protocol version',
            cur_level => $tail[5],
        );
    }
    elsif ($code == 501) {
        %opt = (
            code => $code,
            result => 'Illegal protocol level',
        );
    }
    elsif ($code == 502) {
        %opt = (
            code => $code,
            result => 'Protocol level already cur_level',
            cur_level => $tail[3],
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Proto::new_from_content_ref, unknown code '$code' returned. Allowed codes are 200, 201, 501 and 502.");
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
