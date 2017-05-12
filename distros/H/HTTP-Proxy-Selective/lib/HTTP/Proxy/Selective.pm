package HTTP::Proxy::Selective;

use base qw( HTTP::Proxy::HeaderFilter );
use strict;
use warnings;
use Carp ();

use Path::Class::File;
use File::Slurp;
use File::stat;

use HTTP::Response;

our $VERSION   = '0.004';

sub new {
    my ($class, $filter, $debug) = @_;
    my $self = $class->SUPER::new();
    my $overrides = delete $filter->{mime_overrides};
    $overrides ||= {};
    my %mime_types = (_initial_mime_types(), %$overrides);
    $self->{_mime_types} = \%mime_types;
    $self->{_myfilter} = _generate_matches_from_config(%$filter);
    if ($debug) {
        $self->{_debug} = 1;
        warn("Debugging mode ON\nPaths this proxy will divert:\n");
        foreach my $host (keys %{ $self->{_myfilter} }) {
            foreach my $array ( @{ $self->{_myfilter}{$host} } ) {
                warn($host . $array->[0] . "\n");
            }
        }
        warn("\n");
    }
    
    return $self;
}

sub _generate_matches_from_config {
    my (%filter) = @_;

    foreach my $site (keys %filter) {
        # Ensure all filter paths have a leading /
        foreach my $key (keys %{$filter{$site}}) {
            next if ($key =~ m|^/|);
            my $path = delete $filter{$site}->{$key};
            $filter{$site}->{"/$key"} = $path; 
        }
        # Re-shuffle into an array, with the longest (most specific) paths first.
        my @keys = sort { length $b <=> length $a } keys %{$filter{$site}};
        my $new_filter = [ map { [$_, $filter{$site}->{$_} ] } @keys ];
        $filter{$site} = $new_filter;
    }
    return \%filter;
}

sub filter {
    my ( $self, $headers, $message ) = @_;
    my $uri = $message->uri;
    unless ($self->{_myfilter}{$uri->host}) {
        return;
        warn("Did not match host " . $uri->host . " from config.\n") if $self->{_debug};
    }
    my $path = $uri->path;
    warn("Trying to match request path: $path\n") if $self->{_debug};
    foreach my $myfilter (@{ $self->{_myfilter}{$uri->host} }) {
        my ($match_path, $on_disk) = @$myfilter;
        if ($self->_filter_applies($myfilter, $path)) {
            warn("Matched $match_path with path $path\n");
            my $path_remainder = substr($path, length($match_path));
            my $fn = Path::Class::File->new($on_disk, $path_remainder)->stringify;
            $fn =~ s/[\\\/]$//;
            my $res = $self->_serve_local($headers, $fn);
            $self->proxy->response($res);
            return;
        }
        else {
            warn("Did not match $match_path with path $path\n") if $self->{_debug};
        }
    }
    warn("No paths matched - sending request to original server.\n") if $self->{_debug};
    return;
}

sub __file_exists {
    my $fn = shift;
    return -f $fn;
}

sub _serve_local {
    my ($self, $req_headers, $fn) = @_;
    my $res = HTTP::Response->new();
    if ( __file_exists($fn) ) {
        warn("File exists at $fn, serving from local disk\n") if $self->{_debug};
        my $stat = stat($fn);
        if ($req_headers->header('If-Modified-Since') ) {
            if ( $req_headers->if_modified_since == $stat->mtime ) {
                $res->code(304); # Not modified
                return $res;
            }
        }
        $res->code(200);
        $res->headers->content_type($self->_mimetype($fn));
        $res->headers->content_length( $stat->size );
        $res->headers->last_modified( $stat->mtime );
        my $content = read_file($fn, binmode => ':raw');
        $res->content($content);
    }
    else {
        warn("File $fn does not exist on local disk\n") if $self->{_debug};
        $res->code(404);
        $res->headers->content_type('text/html');
        $res->content('<html><head><title>Not found</title></head><body><h1>Not found at ' . $fn . '</h1></body></html>');
    }
    return $res;
}

sub _filter_applies {
    my ($self, $myfilter, $path) = @_;
    my $match_path = @$myfilter[0];
    return 1 if (index($path, $match_path) == 0); # Match at the beginning only
    return;
}

sub _mimetype {
    my ($self, $fn) = @_;
    if ($fn) {
        if ($fn =~ /\.([^.]+)$/) {
            my $ext = lc($1);
            if ($self->{_mime_types}->{$ext}) {
                return $self->{_mime_types}->{$ext}
            }
        }
    }
    return 'application/octet-stream';
}

sub _initial_mime_types {(
    ez => "application/andrew-inset",
    atom => "application/atom",
    atomcat => "application/atomcat+xml",
    atomsrv => "application/atomserv+xml",
    cap => "application/cap",
    pcap => "application/cap",
    cu => "application/cu-seeme",
    tsp => "application/dsptype",
    spl => "application/futuresplash",
    hta => "application/hta",
    jar => "application/java-archive",
    ser => "application/java-serialized-object",
    class => "application/java-vm",
    hqx => "application/mac-binhex40",
    cpt => "application/mac-compactpro",
    nb => "application/mathematica",
    mdb => "application/msaccess",
    doc => "application/msword",
    dot => "application/msword",
    bin => "application/octet-stream",
    oda => "application/oda",
    ogg => "application/ogg",
    ogx => "application/ogg",
    pdf => "application/pdf",
    key => "application/pgp-keys",
    pgp => "application/pgp-signature",
    prf => "application/pics-rules",
    ps => "application/postscript",
    ai => "application/postscript",
    eps => "application/postscript",
    rar => "application/rar",
    rdf => "application/rdf+xml",
    rss => "application/rss+xml",
    rtf => "application/rtf",
    smi => "application/smil",
    smil => "application/smil",
    wpd => "application/wordperfect",
    wp5 => "application/wordperfect5.1",
    xhtml => "application/xhtml+xml",
    xht => "application/xhtml+xml",
    xml => "application/xml",
    xsl => "application/xml",
    zip => "application/zip",
    cdy => "application/vnd.cinderella",
    kml => "application/vnd.google-earth.kml+xml",
    kmz => "application/vnd.google-earth.kmz",
    xul => "application/vnd.mozilla.xul+xml",
    xls => "application/vnd.ms-excel",
    xlb => "application/vnd.ms-excel",
    xlt => "application/vnd.ms-excel",
    cat => "application/vnd.ms-pki.seccat",
    stl => "application/vnd.ms-pki.stl",
    ppt => "application/vnd.ms-powerpoint",
    pps => "application/vnd.ms-powerpoint",
    odc => "application/vnd.oasis.opendocument.chart",
    odb => "application/vnd.oasis.opendocument.databas",
    odf => "application/vnd.oasis.opendocument.formula",
    odg => "application/vnd.oasis.opendocument.graphics",
    otg => "application/vnd.oasis.opendocument.graphics-template",
    odi => "application/vnd.oasis.opendocument.image",
    odp => "application/vnd.oasis.opendocument.presentation",
    otp => "application/vnd.oasis.opendocument.presentation-template",
    ods => "application/vnd.oasis.opendocument.spreadsheet",
    ots => "application/vnd.oasis.opendocument.spreadsheet-template",
    odt => "application/vnd.oasis.opendocument.text",
    odm => "application/vnd.oasis.opendocument.text-master",
    ott => "application/vnd.oasis.opendocument.text-template",
    oth => "application/vnd.oasis.opendocument.text-web",
    cod => "application/vnd.rim.cod",
    mmf => "application/vnd.smaf",
    sdc => "application/vnd.stardivision.calc",
    sds => "application/vnd.stardivision.chart",
    sda => "application/vnd.stardivision.draw",
    sdd => "application/vnd.stardivision.impress",
    sdf => "application/vnd.stardivision.math",
    sdw => "application/vnd.stardivision.writer",
    sgl => "application/vnd.stardivision.writer-global",
    sxc => "application/vnd.sun.xml.calc",
    stc => "application/vnd.sun.xml.calc.template",
    sxd => "application/vnd.sun.xml.draw",
    std => "application/vnd.sun.xml.draw.template",
    sxi => "application/vnd.sun.xml.impress",
    sti => "application/vnd.sun.xml.impress.template",
    sxm => "application/vnd.sun.xml.math",
    sxw => "application/vnd.sun.xml.writer",
    sxg => "application/vnd.sun.xml.writer.global",
    stw => "application/vnd.sun.xml.writer.template",
    sis => "application/vnd.symbian.install",
    vsd => "application/vnd.visio",
    wbxml => "application/vnd.wap.wbxml",
    wmlc => "application/vnd.wap.wmlc",
    wmlsc => "application/vnd.wap.wmlscriptc",
    wk => "application/x-123",
    '7z' => "application/x-7z-compressed",
    abw => "application/x-abiword",
    dmg => "application/x-apple-diskimage",
    bcpio => "application/x-bcpio",
    torrent => "application/x-bittorrent",
    cab => "application/x-cab",
    cbr => "application/x-cbr",
    cbz => "application/x-cbz",
    cdf => "application/x-cdf",
    vcd => "application/x-cdlink",
    pgn => "application/x-chess-pgn",
    cpio => "application/x-cpio",
    csh => "application/x-csh",
    deb => "application/x-debian-package",
    udeb => "application/x-debian-package",
    dcr => "application/x-director",
    dir => "application/x-director",
    dxr => "application/x-director",
    dms => "application/x-dms",
    wad => "application/x-doom",
    dvi => "application/x-dvi",
    rhtml => "application/x-httpd-eruby",
    flac => "application/x-flac",
    pfa => "application/x-font",
    pfb => "application/x-font",
    gsf => "application/x-font",
    pcf => "application/x-font",
    'pcf.Z' => "application/x-font",
    mm => "application/x-freemind",
    spl => "application/x-futuresplash",
    gnumeric => "application/x-gnumeric",
    sgf => "application/x-go-sgf",
    gcf => "application/x-graphing-calculator",
    gtar => "application/x-gtar",
    tgz => "application/x-gtar",
    taz => "application/x-gtar",
    hdf => "application/x-hdf",
    phtml => "application/x-httpd-php",
    pht => "application/x-httpd-php",
    php => "application/x-httpd-php",
    phps => "application/x-httpd-php-source",
    php3 => "application/x-httpd-php3",
    php3p => "application/x-httpd-php3-preprocessed",
    php4 => "application/x-httpd-php4",
    ica => "application/x-ica",
    ins => "application/x-internet-signup",
    isp => "application/x-internet-signup",
    iii => "application/x-iphone",
    iso => "application/x-iso9660-image",
    jnlp => "application/x-java-jnlp-file",
    js => "application/x-javascript",
    jmz => "application/x-jmol",
    chrt => "application/x-kchart",
    kil => "application/x-killustrator",
    skp => "application/x-koan",
    skd => "application/x-koan",
    skt => "application/x-koan",
    skm => "application/x-koan",
    kpr => "application/x-kpresenter",
    kpt => "application/x-kpresenter",
    ksp => "application/x-kspread",
    kwd => "application/x-kword",
    kwt => "application/x-kword",
    latex => "application/x-latex",
    lha => "application/x-lha",
    lyx => "application/x-lyx",
    lzh => "application/x-lzh",
    lzx => "application/x-lzx",
    frm => "application/x-maker",
    maker => "application/x-maker",
    frame => "application/x-maker",
    fm => "application/x-maker",
    fb => "application/x-maker",
    book => "application/x-maker",
    fbdoc => "application/x-maker",
    mif => "application/x-mif",
    wmd => "application/x-ms-wmd",
    wmz => "application/x-ms-wmz",
    com => "application/x-msdos-program",
    exe => "application/x-msdos-program",
    bat => "application/x-msdos-program",
    dll => "application/x-msdos-program",
    msi => "application/x-msi",
    nc => "application/x-netcdf",
    pac => "application/x-ns-proxy-autoconfig",
    nwc => "application/x-nwc",
    o => "application/x-object",
    oza => "application/x-oz-application",
    p7r => "application/x-pkcs7-certreqresp",
    crl => "application/x-pkcs7-crl",
    pyc => "application/x-python-code",
    pyo => "application/x-python-code",
    qtl => "application/x-quicktimeplayer",
    rpm => "application/x-redhat-package-manager",
    sh => "application/x-sh",
    shar => "application/x-shar",
    swf => "application/x-shockwave-flash",
    swfl => "application/x-shockwave-flash",
    sit => "application/x-stuffit",
    sitx => "application/x-stuffit",
    sv4cpio => "application/x-sv4cpio",
    sv4crc => "application/x-sv4crc",
    tar => "application/x-tar",
    tcl => "application/x-tcl",
    gf => "application/x-tex-gf",
    pk => "application/x-tex-pk",
    texinfo => "application/x-texinfo",
    texi => "application/x-texinfo",
    bak => "application/x-trash",
    old => "application/x-trash",
    sik => "application/x-trash",
    t => "application/x-troff",
    tr => "application/x-troff",
    roff => "application/x-troff",
    man => "application/x-troff-man",
    me => "application/x-troff-me",
    ms => "application/x-troff-ms",
    ustar => "application/x-ustar",
    src => "application/x-wais-source",
    wz => "application/x-wingz",
    crt => "application/x-x509-ca-cert",
    xcf => "application/x-xcf",
    fig => "application/x-xfig",
    xpi => "application/x-xpinstall",
    au => "audio/basic",
    snd => "audio/basic",
    mid => "audio/midi",
    midi => "audio/midi",
    kar => "audio/midi",
    mpga => "audio/mpeg",
    mpega => "audio/mpeg",
    mp2 => "audio/mpeg",
    mp3 => "audio/mpeg",
    m4a => "audio/mpeg",
    m3u => "audio/mpegurl",
    oga => "audio/ogg",
    spx => "audio/ogg",
    sid => "audio/prs.sid",
    aif => "audio/x-aiff",
    aiff => "audio/x-aiff",
    aifc => "audio/x-aiff",
    gsm => "audio/x-gsm",
    m3u => "audio/x-mpegurl",
    wma => "audio/x-ms-wma",
    wax => "audio/x-ms-wax",
    ra => "audio/x-pn-realaudio",
    rm => "audio/x-pn-realaudio",
    ram => "audio/x-pn-realaudio",
    ra => "audio/x-realaudio",
    pls => "audio/x-scpls",
    sd2 => "audio/x-sd2",
    wav => "audio/x-wav",
    alc => "chemical/x-alchemy",
    cac => "chemical/x-cache",
    cache => "chemical/x-cache",
    csf => "chemical/x-cache-csf",
    cbin => "chemical/x-cactvs-binary",
    cascii => "chemical/x-cactvs-binary",
    ctab => "chemical/x-cactvs-binary",
    cdx => "chemical/x-cdx",
    cer => "chemical/x-cerius",
    c3d => "chemical/x-chem3d",
    chm => "chemical/x-chemdraw",
    cif => "chemical/x-cif",
    cmdf => "chemical/x-cmdf",
    cml => "chemical/x-cml",
    cpa => "chemical/x-compass",
    bsd => "chemical/x-crossfire",
    csml => "chemical/x-csml",
    csm => "chemical/x-csml",
    ctx => "chemical/x-ctx",
    cxf => "chemical/x-cxf",
    cef => "chemical/x-cxf",
    emb => "chemical/x-embl-dl-nucleotide",
    embl => "chemical/x-embl-dl-nucleotide",
    spc => "chemical/x-galactic-spc",
    inp => "chemical/x-gamess-input",
    gam => "chemical/x-gamess-input",
    gamin => "chemical/x-gamess-input",
    fch => "chemical/x-gaussian-checkpoint",
    fchk => "chemical/x-gaussian-checkpoint",
    cub => "chemical/x-gaussian-cube",
    gau => "chemical/x-gaussian-input",
    gjc => "chemical/x-gaussian-input",
    gjf => "chemical/x-gaussian-input",
    gal => "chemical/x-gaussian-log",
    gcg => "chemical/x-gcg8-sequence",
    gen => "chemical/x-genbank",
    hin => "chemical/x-hin",
    istr => "chemical/x-isostar",
    ist => "chemical/x-isostar",
    jdx => "chemical/x-jcamp-dx",
    dx => "chemical/x-jcamp-dx",
    kin => "chemical/x-kinemage",
    mcm => "chemical/x-macmolecule",
    mmd => "chemical/x-macromodel-input",
    mmod => "chemical/x-macromodel-input",
    mol => "chemical/x-mdl-molfile",
    rd => "chemical/x-mdl-rdfile",
    rxn => "chemical/x-mdl-rxnfile",
    sd => "chemical/x-mdl-sdfile",
    sdf => "chemical/x-mdl-sdfile",
    tgf => "chemical/x-mdl-tgf",
    mcif => "chemical/x-mmcif",
    mol2 => "chemical/x-mol2",
    b => "chemical/x-molconn-Z",
    gpt => "chemical/x-mopac-graph",
    mop => "chemical/x-mopac-input",
    mopcrt => "chemical/x-mopac-input",
    mpc => "chemical/x-mopac-input",
    dat => "chemical/x-mopac-input",
    zmt => "chemical/x-mopac-input",
    moo => "chemical/x-mopac-out",
    mvb => "chemical/x-mopac-vib",
    asn => "chemical/x-ncbi-asn1",
    prt => "chemical/x-ncbi-asn1-ascii",
    ent => "chemical/x-ncbi-asn1-ascii",
    val => "chemical/x-ncbi-asn1-binary",
    aso => "chemical/x-ncbi-asn1-binary",
    asn => "chemical/x-ncbi-asn1-spec",
    pdb => "chemical/x-pdb",
    ent => "chemical/x-pdb",
    ros => "chemical/x-rosdal",
    sw => "chemical/x-swissprot",
    vms => "chemical/x-vamas-iso14976",
    vmd => "chemical/x-vmd",
    xtel => "chemical/x-xtel",
    xyz => "chemical/x-xyz",
    gif => "image/gif",
    ief => "image/ief",
    jpeg => "image/jpeg",
    jpg => "image/jpeg",
    jpe => "image/jpeg",
    pcx => "image/pcx",
    png => "image/png",
    svg => "image/svg+xml",
    svgz => "image/svg+xml",
    tiff => "image/tiff",
    tif => "image/tiff",
    djvu => "image/vnd.djvu",
    djv => "image/vnd.djvu",
    wbmp => "image/vnd.wap.wbmp",
    ras => "image/x-cmu-raster",
    cdr => "image/x-coreldraw",
    pat => "image/x-coreldrawpattern",
    cdt => "image/x-coreldrawtemplate",
    cpt => "image/x-corelphotopaint",
    ico => "image/x-icon",
    art => "image/x-jg",
    jng => "image/x-jng",
    bmp => "image/x-ms-bmp",
    psd => "image/x-photoshop",
    pnm => "image/x-portable-anymap",
    pbm => "image/x-portable-bitmap",
    pgm => "image/x-portable-graymap",
    ppm => "image/x-portable-pixmap",
    rgb => "image/x-rgb",
    xbm => "image/x-xbitmap",
    xpm => "image/x-xpixmap",
    xwd => "image/x-xwindowdump",
    eml => "message/rfc822",
    igs => "model/iges",
    iges => "model/iges",
    msh => "model/mesh",
    mesh => "model/mesh",
    silo => "model/mesh",
    wrl => "model/vrml",
    vrml => "model/vrml",
    ics => "text/calendar",
    icz => "text/calendar",
    css => "text/css",
    csv => "text/csv",
    323 => "text/h323",
    html => "text/html",
    htm => "text/html",
    shtml => "text/html",
    uls => "text/iuls",
    mml => "text/mathml",
    asc => "text/plain",
    txt => "text/plain",
    text => "text/plain",
    pot => "text/plain",
    rtx => "text/richtext",
    sct => "text/scriptlet",
    wsc => "text/scriptlet",
    tm => "text/texmacs",
    ts => "text/texmacs",
    tsv => "text/tab-separated-values",
    jad => "text/vnd.sun.j2me.app-descriptor",
    wml => "text/vnd.wap.wml",
    wmls => "text/vnd.wap.wmlscript",
    bib => "text/x-bibtex",
    boo => "text/x-boo",
    'h++' => "text/x-c++hdr",
    hpp => "text/x-c++hdr",
    hxx => "text/x-c++hdr",
    hh => "text/x-c++hdr",
    'c++' => "text/x-c++src",
    cpp => "text/x-c++src",
    cxx => "text/x-c++src",
    cc => "text/x-c++src",
    h => "text/x-chdr",
    htc => "text/x-component",
    csh => "text/x-csh",
    c => "text/x-csrc",
    d => "text/x-dsrc",
    diff => "text/x-diff",
    patch => "text/x-diff",
    hs => "text/x-haskell",
    java => "text/x-java",
    lhs => "text/x-literate-haskell",
    moc => "text/x-moc",
    p => "text/x-pascal",
    pas => "text/x-pascal",
    gcd => "text/x-pcs-gcd",
    pl => "text/x-perl",
    pm => "text/x-perl",
    py => "text/x-python",
    etx => "text/x-setext",
    sh => "text/x-sh",
    tcl => "text/x-tcl",
    tk => "text/x-tcl",
    tex => "text/x-tex",
    ltx => "text/x-tex",
    sty => "text/x-tex",
    cls => "text/x-tex",
    vcs => "text/x-vcalendar",
    vcf => "text/x-vcard",
    '3gp' => "video/3gpp",
    dl => "video/dl",
    dif => "video/dv",
    dv => "video/dv",
    fli => "video/fli",
    gl => "video/gl",
    mpeg => "video/mpeg",
    mpg => "video/mpeg",
    mpe => "video/mpeg",
    mp4 => "video/mp4",
    ogv => "video/ogg",
    qt => "video/quicktime",
    mov => "video/quicktime",
    mxu => "video/vnd.mpegurl",
    lsf => "video/x-la-asf",
    lsx => "video/x-la-asf",
    mng => "video/x-mng",
    asf => "video/x-ms-asf",
    asx => "video/x-ms-asf",
    wm => "video/x-ms-wm",
    wmv => "video/x-ms-wmv",
    wmx => "video/x-ms-wmx",
    wvx => "video/x-ms-wvx",
    avi => "video/x-msvideo",
    movie => "video/x-sgi-movie",
    ice => "x-conference/x-cooltalk",
    sisx => "x-epoc/x-sisx-app",
    vrm => "x-world/x-vrml",
    vrml => "x-world/x-vrml",
    wrl => "x-world/x-vrml",
)}

1;

__END__

=head1 NAME

HTTP::Proxy::Selective - Simple HTTP Proxy which serves some paths from locations on local disk.
    
=head1 SYNOPSIS

    use HTTP::Proxy;
    use HTTP::Proxy::Selective;
    my $filter = {
        'www.example.com' => {
            'css/' => '/home/t0m/example/css',
            'js'   => '/home/t0m/example/js',
        },
    };
    my $proxy = HTTP::Proxy->new();
    $proxy->push_filter( 
        method => 'GET, HEAD',
        request => HTTP::Proxy::Selective->new($filter)
    );
    $proxy->start;


See the script shipped in the distribution C<selective_proxy> for a slightly more complex example of use.
    
=head1 DESCRIPTION

HTTP::Proxy::Selective acts as a filter for L<HTTP::Proxy>. You pass it a filter data structure when you create it (as per the example above),
and any URLs requested through the proxy which match the filter are served from the path on local disk specified by the configuration.

Note that if a file is a filtered path is not found on local disk, then a 404 error is generated, it is B<not> sent to the origin server.

=head1 METHODS

=head2 new $filter

Constructs an instance (validating the filter etc as it does so).

=head2 filter $self, $headers, $message

Method which performs the filtering, called by L<HTTP::Proxy>.

=head1 SEE ALSO

=over

=item L<HTTP::Proxy> - Provides the basis for this software.

=item L<Catalyst::Engine::HTTP> - Many parts of the HTTP server were ripped out of this module. 

=back

=head1 BINARY DISTRIBUTION

A binary release of the latest version of this software for Windows may be
found at:

  http://www.venda.com/page/developertools

=head1 AUTHOR

Tomas Doran, <bobtfish@bobtfish.net>

=head1 CREDITS

This software is based upon a number of other open source projects, and builds on software originally implemented by the following people.

=over

=item Philippe (BooK) Bruhat - L<HTTP::Proxy>, the basis for this module.

=item Sebastian Riedel, Andy Grubman, Dan Kubb, Sascha Kiefer - L<Catalyst::Engine::HTTP>, inspiration as a pure perl web server.

=item Jesse Vincent - L<HTTP::Server::Simple>, which L<Catalyst::Engine::HTTP> stole a lot of code from..

=back

=head1 COPYRIGHT

Copyright 2008 Tomas Doran. Some rights reserved.

The development of this software was 100% funded by Venda
(L<http://www.venda.com>).

=head1 LICENSE

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Venda Ltd. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

