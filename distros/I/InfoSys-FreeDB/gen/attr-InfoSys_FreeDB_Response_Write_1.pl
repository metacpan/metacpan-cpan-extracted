use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::Write::1";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB write first pass response',
        abstract => 'FreeDB write first pass response',
        synopsis => <<'EOF',
This class is used internally by the C<InfoSys::FreeDB::Connection::CDDBP> class.
EOF
        description => <<EOF,
C<${pkg}> contains information about FreeDB write first pass responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'categ',
             short_description => 'the CD category',
        },
        {
             method_factory_name => 'discid',
             short_description => 'the CD disk ID number',
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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Write::1::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 320) {
        my @tail = split(/\s+/, $tail, 2);
        %opt = (
            categ => $tail[0],
            code => $code,
            discid => $tail[1],
            result => 'OK, input CDDB data',
        );
    }
    elsif ($code == 401) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Permission denied',
        );
    }
    elsif ($code == 402) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Server file system full/file access failed',
        );
    }
    elsif ($code == 409) {
        %opt = (
            code => $code,
            error => 1,
            result => 'No handshake',
        );
    }
    elsif ($code == 501) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Entry rejected: ' . $tail,
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Write::1::new_from_content_ref, unknown code '$code' returned. Allowed codes are 320, 401, 402, 409 and 501.");
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
