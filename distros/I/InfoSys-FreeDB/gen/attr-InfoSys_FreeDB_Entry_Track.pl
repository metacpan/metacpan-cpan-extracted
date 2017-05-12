use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_entry = "${pkg_base}::Entry";
my $pkg = "${pkg_entry}::Track";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        short_description => 'FreeDB entry track',
        abstract => 'FreeDB entry track',
        synopsis => &::read_synopsis( 'syn-http-track.pl', '.' ),
        description => <<EOF,
C<${pkg}> contains information on FreeDB entry tracks.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'offset',
             short_description => 'the track offset',
        },
        {
             method_factory_name => 'title',
             short_description => 'the track title',
        },
        {
             method_factory_name => 'extt',
             short_description => 'the track extt',
        },
    ],
    constr_opt => [
    ],
    meth_opt => [
        {
            method_name => 'write_fh',
            parameter_description => 'FILE_HANDLE',
            description => <<EOF,
Writes the entry to the specified file handle. C<FILE_HANDLE> is a C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
EOF
        },
    ],
    use_opt => [
    ],
} );
