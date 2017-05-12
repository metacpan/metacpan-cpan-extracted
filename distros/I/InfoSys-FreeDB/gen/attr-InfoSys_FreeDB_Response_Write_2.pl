use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::Write::2";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB write second pass response',
        abstract => 'FreeDB write second pass response',
        synopsis => <<'EOF',
This class is used internally by the C<InfoSys::FreeDB::Connection::CDDBP> class.
EOF
        description => <<EOF,
C<${pkg}> contains information about FreeDB write second pass responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'message',
             short_description => 'the returned message',
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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Write::2::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 200) {
        my @tail = split(/\s+/, $tail, 2);
        %opt = (
            code => $code,
            message => $tail,
            result => 'CDDB entry accepted',
        );
    }
    elsif ($code == 401) {
        %opt = (
            code => $code,
            error => 1,
            message => $tail,
            result => 'CDDB entry rejected',
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Write::2::new_from_content_ref, unknown code '$code' returned. Allowed codes are 200 and 401.");
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
