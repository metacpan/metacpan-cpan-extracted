use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg_site = "${pkg_base}::Site";
my $pkg = "${pkg_response}::Sites";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB sites response',
        abstract => 'FreeDB sites response',
        synopsis => &::read_synopsis( 'syn-http-sites.pl', '.' ),
        description => <<EOF,
C<${pkg}> contains information about FreeDB sites responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'site',
             type => 'MULTI',
             short_description => 'the site list',
             allow_isa => [ $pkg_site ],
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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Sites::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 210) {
        pop(@content_ref);
        my @site = ();
        foreach my $line (@content_ref) {
            my ($site, $port_proto, $tail) = split(/\s+/, $line, 3);
            require InfoSys::FreeDB::Site;
            if ( $port_proto =~ /^\d+$/ ) {
                my @line = split(/\s+/, $tail, 3);
                push( @site, InfoSys::FreeDB::Site->new( {
                    site => $site,
                    protocol => 'cddbp',
                    port => $port_proto,
                    latitude => $line[0],
                    longitude => $line[1],
                    description => $line[2],
                } ) );
            }
            else {
                my @line = split(/\s+/, $tail, 5);
                push( @site, InfoSys::FreeDB::Site->new( {
                    site => $site,
                    protocol => $port_proto,
                    port => $line[0],
                    address => $line[1],
                    latitude => $line[2],
                    longitude => $line[3],
                    description => $line[4],
                } ) );
            }
        }
        %opt = (
            code => $code,
            result => 'Ok',
            site => \@site,
        );
    }
    elsif ($code == 401) {
        %opt = (
            code => $code,
            result => 'No site information available',
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Sites::new_from_content_ref, unknown code '$code' returned. Allowed codes are 210 and 401.");
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
