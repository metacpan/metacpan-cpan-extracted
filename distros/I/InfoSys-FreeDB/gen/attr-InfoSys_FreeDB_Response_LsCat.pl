use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::LsCat";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB lscat response',
        abstract => 'FreeDB lscat response',
        synopsis => &::read_synopsis( 'syn-http-lscat.pl', '.' ),
        description => <<EOF,
C<${pkg}> contains information about FreeDB lscat responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'category',
             type => 'MULTI',
             short_description => 'the category list',
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
    my ($code) = $line =~ /^\s*(\d{3})\s+/;
    defined ($code) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::LsCat::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 210) {
        pop(@content_ref);
        %opt = (
            code => $code,
            result => 'Okay',
            category => [ @content_ref ],
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::LsCat::new_from_content_ref, unknown code '$code' returned. Allowed code is 210.");
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
