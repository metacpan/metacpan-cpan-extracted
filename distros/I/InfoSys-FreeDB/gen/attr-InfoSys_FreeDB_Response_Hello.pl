use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::Hello";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB hello response',
        abstract => 'FreeDB hello response',
        synopsis => <<'EOF',
This class is used internally by the C<InfoSys::FreeDB::Connection::CDDBP> class.
EOF
        description => <<EOF,
C<${pkg}> contains information about FreeDB hello responses.
EOF
    },
    attr_opt => [
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
    my ($code) = $line =~ /^\s*(\d{3})\s+/;
    defined ($code) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Hello::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 200) {
        %opt = (
            code => $code,
            result => 'Handshake successful',
        );
    }
    elsif ($code == 402) {
        %opt = (
            code => $code,
            result => 'Already shook hands',
        );
    }
    elsif ($code == 431) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Handshake not successful, closing connection',
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Hello::new_from_content_ref, unknown code '$code' returned. Allowed codes are 200, 402 and 431.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
EOF
        },
    ],
    meth_opt => [
    ],
    use_opt => [
    ],
    sym_opt => [
    ],
} );
