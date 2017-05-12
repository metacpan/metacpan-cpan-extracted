use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::Quit";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB quit response',
        abstract => 'FreeDB quit response',
        synopsis => <<'EOF',
This class is used internally by the C<InfoSys::FreeDB::Connection::CDDBP> class.
EOF
        description => <<EOF,
C<${pkg}> contains information about FreeDB quit responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'hostname',
             short_description => 'the server host name',
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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Quit::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 230) {
        my @tail = split(/\s+/, $tail);
        %opt = (
            code => $code,
            result => 'OK, goodbye',
            hostname => $tail[0],
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Quit::new_from_content_ref, unknown code '$code' returned. Allowed code is 230.");
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
