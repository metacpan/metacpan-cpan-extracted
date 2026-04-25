##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/MIME.pm
## Version v0.3.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/07
## Modified 2026/04/04
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::MIME;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'HTTP::Promise' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $TYPES );
    use Module::Generic::File::Magic qw( :flags );
    # use File::MMagic::XS;
    # eval( "use File::MMagic::XS 0.09008" );
    # our $HAS_FILE_MMAGIC_XS = $@ ? 0 : 1;                               
    # use Nice::Try;
    our $VERSION = 'v0.3.0';
    our $TYPES = {};
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $file;
    $file = shift( @_ ) if( @_ % 2 );
    $self->{types}  = {};
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    # my $json_file = $self->new_file( __FILE__ )->parent->child( 'mime.json' );
    my $types;
    if( defined( $file ) )
    {
        $types = $self->_parse_file( $file );
    }
    elsif( scalar( keys( %$TYPES ) ) )
    {
        $types = $TYPES;
    }
    else
    {
        my $ref = $self->_data;
        my $j = $self->new_json;
        $types = $TYPES = $j->decode( $$ref );
    }
    $self->types( $types );
    return( $self );
}

sub dump
{
    my $self = shift( @_ );
    my $types = $self->types;
    my $str  = '';
    my $max = 0;
    unless( $max = $self->{_dump_max_width} )
    {
        foreach my $t ( keys( %$types ) )
        {
            $max = length( $t ) if( length( $t ) > $max );
        }
        $self->{_dump_max_width} = $max;
    }
    my $format = ' @' . ( '<' x $max ) . ' @*' . "\n";
    foreach my $type ( sort( keys( %$types ) ) )
    {
        $^A = '';
        formline( $format, $type, join( ' ', @{$types->{ $type }} ) );
        $str .= $^A;
    }
    return( $str );
}

sub mime_type
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file was provided." ) );
    require Module::Generic::File::Magic;
    my $magic = Module::Generic::File::Magic->new( flags => MAGIC_MIME_TYPE ) ||
        return( Module::Generic::File::Magic->error );
    my $mime = $magic->from_file( "$file" ) ||
        return( $self->pass_error( $magic->error ) );
    return( $mime );
}

sub mime_type_from_suffix
{
    my $self = shift( @_ );
    my $suff = shift( @_ ) || return( $self->error( "No suffix was provided." ) );
    $suff = lc( $suff );
    my $types = $self->types;
    foreach my $m ( keys( %$types ) )
    {
        my $ar = $types->{ $m };
        if( scalar( grep( $_ eq $suff, @$ar ) ) )
        {
            return( $m );
        }
    }
    # Empty, but not undef, because undef is reserved for errors
    return( '' );
}

sub suffix
{
    my $self = shift( @_ );
    my $mime = shift( @_ ) ||
        return( $self->error( "No mime type was provided to get its corresponding suffixes." ) );
    my $types = $self->types;
    return( wantarray() ? [@{$types->{ $mime }}] : $types->{ $mime }->[0] );
}

sub types { return( shift->_set_get_hash_as_mix_object( 'types', @_ ) ); }

sub _parse_file
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return;
    my $f = $self->new_file( $file ) || return( $self->pass_error );
    $f->open;
    my $types = {};
    $f->line(sub
    {
        return(1) if( /^[[:blank:]\h]*\#/ || /^[[:blank:]\h]*$/ );
        s/^[[:blank:]\h]+//g;
        my( $type, $exts ) = split( /[[:blank:]\h]+/, $_, 2 );
        $types->{ $type } = [split( /[[:blank:]]+/, $exts )];
    }, chomp => 1 );
    return( $types );
}

# The data herein is the result of creating a new instance and dumping its data, like:
# say json_encode( HTTP::Promise::MIME->new( '/some/where/mime.types' )->types );
sub _data
{
    my $data = <<'EOT';
{"application/vnd.sun.xml.impress":["sxi"],"application/vnd.mcd":["mcd"],"application/vnd.spotfire.dxp":["dxp"],"application/vnd.jisp":["jisp"],"image/webp":["webp"],"application/pkcs7-signature":["p7s"],"application/xspf+xml":["xspf"],"audio/vnd.nuera.ecelp7470":["ecelp7470"],"text/x-yaml":["yaml","yml"],"audio/aac":["aac"],"application/mp21":["m21","mp21"],"application/vnd.wordperfect":["wpd"],"application/x-xz":["xz"],"image/heic":["heic"],"application/x-mscardfile":["crd"],"application/x-nzb":["nzb"],"application/vnd.syncml.dm+xml":["xdm"],"application/rpki-ghostbusters":["gbr"],"application/vnd.ms-excel.sheet.binary.macroenabled.12":["xlsb"],"image/vnd.xiff":["xif"],"application/postscript":["ai","eps","ps"],"application/vnd.kde.kword":["kwd","kwt"],"application/vnd.uoml+xml":["uoml"],"application/vnd.stardivision.calc":["sdc"],"application/vnd.oasis.opendocument.text-master":["odm"],"application/vnd.osgi.subsystem":["esa"],"audio/ogg":["oga","ogg","spx","opus"],"video/vnd.dece.pd":["uvp","uvvp"],"application/vnd.ms-htmlhelp":["chm"],"application/hyperstudio":["stk"],"application/resource-lists+xml":["rl"],"application/xenc+xml":["xenc"],"text/x-rust":["rs"],"application/vnd.triscape.mxs":["mxs"],"image/x-mrsid-image":["sid"],"application/vnd.openxmlformats-officedocument.presentationml.template":["potx"],"application/x-httpd-php":["php"],"application/vnd.android.package-archive":["apk"],"application/x-tgif":["obj"],"application/set-registration-initiation":["setreg"],"application/x-blorb":["blb","blorb"],"application/vnd.3gpp.pic-bw-var":["pvb"],"video/mj2":["mj2","mjp2"],"application/vnd.intercon.formnet":["xpw","xpx"],"audio/mpeg":["mpga","mp2","mp2a","mp3","m2a","m3a"],"application/vnd.google-earth.kml+xml":["kml"],"application/vnd.powerbuilder6":["pbd"],"image/prs.btif":["btif"],"image/x-portable-graymap":["pgm"],"audio/wav":["wav"],"text/x-asm":["s","asm"],"video/x-m4v":["m4v"],"application/vnd.lotus-1-2-3":["123"],"application/vnd.ipunplugged.rcprofile":["rcprofile"],"application/vnd.3m.post-it-notes":["pwn"],"application/vnd.frogans.fnc":["fnc"],"application/mac-compactpro":["cpt"],"application/vnd.lotus-wordpro":["lwp"],"application/vnd.hp-pcl":["pcl"],"application/atom+xml":["atom"],"application/vnd.wolfram.player":["nbp"],"application/json":["json"],"application/vnd.oasis.opendocument.chart":["odc"],"application/vnd.stardivision.writer-global":["sgl"],"application/vnd.macports.portpkg":["portpkg"],"application/x-tex":["tex"],"audio/vnd.dra":["dra"],"application/x-pkcs12":["p12","pfx"],"application/x-lzop":["lzo"],"model/mesh":["msh","mesh","silo"],"application/atomcat+xml":["atomcat"],"application/vnd.kinar":["kne","knp"],"application/x-msbinder":["obd"],"image/bmp":["bmp"],"application/srgs+xml":["grxml"],"application/vnd.geometry-explorer":["gex","gre"],"application/vnd.nokia.radio-presets":["rpss"],"application/x-lzma":["lzma"],"model/x3d+xml":["x3d","x3dz"],"application/vnd.fujitsu.oasysgp":["fg5"],"application/msword":["doc","dot"],"application/rsd+xml":["rsd"],"application/vnd.airzip.filesecure.azf":["azf"],"application/vnd.ms-excel.sheet.macroenabled.12":["xlsm"],"application/vnd.ibm.minipay":["mpy"],"application/vnd.fujixerox.ddd":["ddd"],"application/vnd.dart":["dart"],"application/sparql-results+xml":["srx"],"application/x-silverlight-app":["xap"],"audio/xm":["xm"],"application/mathematica":["ma","nb","mb"],"application/vnd.lotus-organizer":["org"],"application/vnd.dynageo":["geo"],"application/pgp-encrypted":["pgp"],"application/vnd.dna":["dna"],"application/vnd.kde.kformula":["kfo"],"image/x-3ds":["3ds"],"audio/x-aiff":["aif","aiff","aifc"],"application/x-hdf":["hdf"],"application/vnd.apple.mpegurl":["m3u8"],"application/vnd.noblenet-sealer":["nns"],"application/vnd.oasis.opendocument.text-web":["oth"],"application/geo+json":["geojson"],"text/markdown":["md","markdown"],"audio/flac":["flac"],"application/java-archive":["jar"],"application/vnd.kde.karbon":["karbon"],"application/yaml":["yaml","yml"],"application/rtf":["rtf"],"application/vnd.mif":["mif"],"application/gml+xml":["gml"],"application/applixware":["aw"],"application/x-dtbook+xml":["dtb"],"application/vnd.pmi.widget":["wg"],"application/vnd.chipnuts.karaoke-mmd":["mmd"],"audio/adpcm":["adp"],"application/vnd.fujixerox.docuworks.binder":["xbd"],"application/x-tads":["gam"],"application/vnd.rar":["rar"],"application/x-font-snf":["snf"],"application/lost+xml":["lostxml"],"text/x-python":["py"],"application/vnd.astraea-software.iota":["iota"],"text/x-sfv":["sfv"],"application/x-futuresplash":["spl"],"application/x-font-pcf":["pcf"],"application/vnd.oasis.opendocument.formula-template":["odft"],"application/vnd.fujixerox.docuworks":["xdw"],"application/vnd.groove-vcard":["vcg"],"application/vnd.geoplan":["g2w"],"application/vnd.ms-word.template.macroenabled.12":["dotm"],"application/vnd.tmobile-livetv":["tmo"],"application/scvp-cv-response":["scs"],"application/vnd.mseq":["mseq"],"text/turtle":["ttl"],"text/vnd.curl.dcurl":["dcurl"],"application/vnd.zul":["zir","zirz"],"audio/x-mpegurl":["m3u"],"application/resource-lists-diff+xml":["rld"],"audio/silk":["sil"],"application/cdmi-object":["cdmio"],"text/x-ruby":["rb"],"application/vnd.ms-works":["wps","wks","wcm","wdb"],"image/vnd.fastbidsheet":["fbs"],"application/vnd.grafeq":["gqf","gqs"],"application/vnd.recordare.musicxml":["mxl"],"application/vnd.ms-artgalry":["cil"],"application/x-director":["dir","dcr","dxr","cst","cct","cxt","w3d","fgd","swa"],"text/html":["html","htm"],"audio/x-pn-realaudio-plugin":["rmp"],"application/vnd.oasis.opendocument.spreadsheet":["ods"],"application/vnd.jcp.javame.midlet-rms":["rms"],"application/vnd.route66.link66+xml":["link66"],"application/pkcs10":["p10"],"application/vnd.ds-keypoint":["kpxx"],"application/vnd.trid.tpt":["tpt"],"application/vnd.cinderella":["cdy"],"model/x3d+binary":["x3db","x3dbz"],"chemical/x-csml":["csml"],"image/sgi":["sgi"],"application/pkixcmp":["pki"],"application/ogg":["ogx"],"application/vnd.adobe.air-application-installer-package+zip":["air"],"application/x-wais-source":["src"],"application/x-sv4cpio":["sv4cpio"],"application/vnd.data-vision.rdz":["rdz"],"application/x-pkcs7-certreqresp":["p7r"],"application/vnd.simtech-mindmapper":["twd","twds"],"application/mac-binhex40":["hqx"],"application/font-tdpfr":["pfr"],"application/pics-rules":["prf"],"video/h263":["h263"],"application/scvp-cv-request":["scq"],"application/vnd.llamagraphics.life-balance.desktop":["lbd"],"application/vnd.dvb.ait":["ait"],"application/x-java-jnlp-file":["jnlp"],"application/emma+xml":["emma"],"application/vnd.hp-hps":["hps"],"text/troff":["t","tr","roff","man","me","ms"],"application/vnd.dece.data":["uvf","uvvf","uvd","uvvd"],"application/vnd.anser-web-certificate-issue-initiation":["cii"],"application/shf+xml":["shf"],"application/relax-ng-compact-syntax":["rnc"],"application/vnd.xara":["xar"],"application/vnd.oasis.opendocument.presentation-template":["otp"],"image/jxl":["jxl"],"audio/x-ms-wma":["wma"],"video/x-ms-vob":["vob"],"application/vnd.stardivision.writer":["sdw","vor"],"application/jsonml+json":["jsonml"],"application/x-sharedlib":["so"],"text/vnd.in3d.spot":["spot"],"application/vnd.yamaha.hv-voice":["hvp"],"application/vnd.solent.sdkm+xml":["sdkm","sdkd"],"audio/vnd.digital-winds":["eol"],"application/marcxml+xml":["mrcx"],"application/vnd.novadigm.edm":["edm"],"text/x-opml":["opml"],"application/x-font-ghostscript":["gsf"],"application/vnd.immervision-ivu":["ivu"],"application/rdf+xml":["rdf"],"application/vnd.hbci":["hbci"],"image/vnd.dwg":["dwg"],"application/vnd.sun.xml.impress.template":["sti"],"application/mbox":["mbox"],"audio/vnd.rip":["rip"],"application/vnd.seemail":["see"],"model/vnd.dwf":["dwf"],"application/vnd.llamagraphics.life-balance.exchange+xml":["lbe"],"application/cdmi-domain":["cdmid"],"application/x-lzip":["lz"],"text/vnd.in3d.3dml":["3dml"],"application/vnd.jam":["jam"],"application/vnd.fdsn.mseed":["mseed"],"model/x3d+vrml":["x3dv","x3dvz"],"application/vnd.hp-hpgl":["hpgl"],"application/vnd.anser-web-funds-transfer-initiation":["fti"],"text/tab-separated-values":["tsv"],"application/vnd.stardivision.draw":["sda"],"application/vnd.musician":["mus"],"image/x-portable-anymap":["pnm"],"application/sru+xml":["sru"],"application/vnd.groove-account":["gac"],"application/vnd.epson.msf":["msf"],"application/vnd.kidspiration":["kia"],"application/java-vm":["class"],"application/vnd.ms-powerpoint.template.macroenabled.12":["potm"],"application/vnd.google-earth.kmz":["kmz"],"application/vnd.adobe.xdp+xml":["xdp"],"application/vnd.symbian.install":["sis","sisx"],"application/x-texinfo":["texinfo","texi"],"application/vnd.iccprofile":["icc","icm"],"application/prs.cww":["cww"],"application/ipfix":["ipfix"],"video/av1":["av1"],"text/css":["css"],"video/h264":["h264"],"application/vnd.antix.game-component":["atx"],"video/vnd.uvvu.mp4":["uvu","uvvu"],"text/x-pascal":["p","pas"],"application/xml-dtd":["dtd"],"application/vnd.intu.qfx":["qfx"],"model/vnd.gtw":["gtw"],"text/richtext":["rtx"],"video/mp4":["mp4","mp4v","mpg4"],"application/ssdl+xml":["ssdl"],"application/rpki-roa":["roa"],"application/vnd.novadigm.edx":["edx"],"application/vnd.dece.unspecified":["uvx","uvvx"],"application/vnd.oma.dd2+xml":["dd2"],"text/x-setext":["etx"],"application/ld+json":["jsonld"],"text/vnd.sun.j2me.app-descriptor":["jad"],"application/timestamped-data":["tsd"],"application/vnd.oasis.opendocument.image-template":["oti"],"application/vnd.koan":["skp","skd","skt","skm"],"application/x-gtar":["gtar"],"application/x-bzip2":["bz2","boz"],"application/vnd.sema":["sema"],"image/x-pcx":["pcx"],"text/x-perl":["pl","pm"],"application/vnd.vsf":["vsf"],"image/x-exr":["exr"],"application/vnd.svd":["svd"],"image/x-cmx":["cmx"],"application/vnd.micrografx.igx":["igx"],"application/mets+xml":["mets"],"image/x-xbitmap":["xbm"],"application/metalink+xml":["metalink"],"application/vnd.shana.informed.interchange":["iif"],"application/xhtml+xml":["xhtml","xht"],"application/vnd.pg.format":["str"],"application/x-sql":["sql"],"application/x-authorware-seg":["aas"],"application/yang":["yang"],"application/x-ms-wmd":["wmd"],"application/vnd.neurolanguage.nlu":["nlu"],"application/vnd.oasis.opendocument.graphics-template":["otg"],"application/vnd.spotfire.sfs":["sfs"],"application/x-msmediaview":["mvb","m13","m14"],"application/x-perl":["pl","pm"],"application/vnd.ezpix-package":["ez3"],"application/vnd.trueapp":["tra"],"application/vnd.intergeo":["i2g"],"application/mathml+xml":["mathml"],"application/vnd.intu.qbo":["qbo"],"text/x-java-source":["java"],"application/inkml+xml":["ink","inkml"],"application/vnd.cosmocaller":["cmc"],"application/vnd.yamaha.openscoreformat":["osf"],"application/vnd.criticaltools.wbs+xml":["wbs"],"video/vnd.dvb.file":["dvb"],"application/vnd.joost.joda-archive":["joda"],"application/vnd.3gpp2.tcap":["tcap"],"application/vnd.yamaha.openscoreformat.osfpvg+xml":["osfpvg"],"image/x-rgb":["rgb"],"application/vnd.kde.kivio":["flw"],"application/gpx+xml":["gpx"],"application/vnd.openxmlformats-officedocument.presentationml.slideshow":["ppsx"],"application/vnd.groove-tool-template":["tpl"],"application/atomsvc+xml":["atomsvc"],"audio/opus":["opus"],"application/x-t3vm-image":["t3"],"application/javascript":["js"],"video/vnd.ms-playready.media.pyv":["pyv"],"application/vnd.shana.informed.package":["ipk"],"image/gif":["gif"],"application/vnd.cloanto.rp9":["rp9"],"application/mods+xml":["mods"],"application/vnd.acucorp":["atc","acutc"],"application/x-glulx":["ulx"],"application/vnd.openofficeorg.extension":["oxt"],"image/x-xwindowdump":["xwd"],"image/vnd.wap.wbmp":["wbmp"],"application/vnd.openxmlformats-officedocument.wordprocessingml.template":["dotx"],"application/vnd.ms-powerpoint.slide.macroenabled.12":["sldm"],"application/cdmi-container":["cdmic"],"chemical/x-xyz":["xyz"],"application/vnd.kde.kspread":["ksp"],"application/vnd.fuzzysheet":["fzs"],"application/x-mswrite":["wri"],"application/vnd.ms-lrm":["lrm"],"application/vnd.semf":["semf"],"audio/vnd.nuera.ecelp4800":["ecelp4800"],"application/vnd.sun.xml.draw.template":["std"],"audio/x-aac":["aac"],"application/vnd.crick.clicker.keyboard":["clkk"],"application/x-gca-compressed":["gca"],"video/vnd.fvt":["fvt"],"application/msgpack":["msgpack"],"text/vcard":["vcard"],"application/x-cfs-compressed":["cfs"],"application/epub+zip":["epub"],"application/x-ace-compressed":["ace"],"application/mxf":["mxf"],"application/x-bittorrent":["torrent"],"application/pkix-pkipath":["pkipath"],"application/vnd.flographit":["gph"],"application/x-ustar":["ustar"],"application/x-ms-xbap":["xbap"],"application/x-bcpio":["bcpio"],"application/pskc+xml":["pskcxml"],"message/rfc822":["eml","mime"],"application/vnd.semd":["semd"],"application/thraud+xml":["tfi"],"application/vnd.webturbo":["wtb"],"application/x-msclip":["clp"],"font/woff2":["woff2"],"image/vnd.fst":["fst"],"application/vnd.insors.igm":["igm"],"application/vnd.ms-powerpoint.addin.macroenabled.12":["ppam"],"application/vnd.ctc-posml":["pml"],"video/vnd.dece.sd":["uvs","uvvs"],"application/x-chat":["chat"],"application/vnd.uiq.theme":["utz"],"application/x-cbr":["cbr","cba","cbt","cbz","cb7"],"application/sbml+xml":["sbml"],"application/xcap-diff+xml":["xdf"],"application/vnd.kahootz":["ktz","ktr"],"application/wasm":["wasm"],"application/vnd.stepmania.package":["smzip"],"application/davmount+xml":["davmount"],"application/vnd.ms-excel":["xls","xlm","xla","xlc","xlt","xlw"],"application/scvp-vp-response":["spp"],"application/x-zmachine":["z1","z2","z3","z4","z5","z6","z7","z8"],"application/vnd.genomatix.tuxedo":["txd"],"application/vnd.las.las+xml":["lasxml"],"text/n3":["n3"],"application/vnd.airzip.filesecure.azs":["azs"],"text/vnd.dvb.subtitle":["sub"],"image/vnd.fpx":["fpx"],"audio/webm":["weba"],"model/vnd.collada+xml":["dae"],"application/vnd.mobius.mbk":["mbk"],"application/vnd.ibm.modcap":["afp","listafp","list3820"],"application/vnd.kde.kontour":["kon"],"application/vnd.adobe.formscentral.fcdt":["fcdt"],"application/vnd.ms-cab-compressed":["cab"],"application/vnd.smaf":["mmf"],"application/onenote":["onetoc","onetoc2","onetmp","onepkg"],"video/x-matroska":["mkv","mk3d","mks"],"application/vnd.wt.stf":["stf"],"application/vnd.framemaker":["fm","frame","maker","book"],"application/pls+xml":["pls"],"application/vnd.openxmlformats-officedocument.presentationml.slide":["sldx"],"application/vnd.ms-xpsdocument":["xps"],"application/vnd.ms-pki.seccat":["cat"],"application/x-mie":["mie"],"application/vnd.denovo.fcselayout-link":["fe_launch"],"application/vnd.hydrostatix.sof-data":["sfd-hdstx"],"text/x-c":["c","cc","cxx","cpp","h","hh","dic"],"application/cu-seeme":["cu"],"application/vnd.osgeo.mapguide.package":["mgp"],"application/zstd":["zst"],"application/vnd.recordare.musicxml+xml":["musicxml"],"application/vnd.lotus-notes":["nsf"],"application/vnd.dolby.mlp":["mlp"],"text/cache-manifest":["appcache"],"video/x-flv":["flv"],"application/vnd.mobius.dis":["dis"],"application/patch-ops-error+xml":["xer"],"application/cdmi-capability":["cdmia"],"text/x-uuencode":["uu"],"video/x-ms-wvx":["wvx"],"image/x-cmu-raster":["ras"],"application/vnd.3gpp.pic-bw-small":["psb"],"application/vnd.yamaha.smaf-audio":["saf"],"application/x-freearc":["arc"],"application/x-msterminal":["trm"],"application/vnd.tao.intent-module-archive":["tao"],"application/vnd.3gpp.pic-bw-large":["plb"],"application/vnd.ezpix-album":["ez2"],"application/vnd.blueice.multipass":["mpm"],"application/x-netcdf":["nc","cdf"],"application/vnd.ms-ims":["ims"],"application/vnd.ms-word.document.macroenabled.12":["docm"],"application/x-ms-shortcut":["lnk"],"application/vnd.visio":["vsd","vst","vss","vsw"],"application/tei+xml":["tei","teicorpus"],"application/vnd.nokia.radio-preset":["rpst"],"image/vnd.dece.graphic":["uvi","uvvi","uvg","uvvg"],"text/x-vcalendar":["vcs"],"video/x-ms-wmv":["wmv"],"application/vnd.nokia.n-gage.symbian.install":["n-gage"],"application/vnd.nokia.n-gage.data":["ngdat"],"application/x-sv4crc":["sv4crc"],"application/wsdl+xml":["wsdl"],"application/omdoc+xml":["omdoc"],"image/vnd.fujixerox.edmics-mmr":["mmr"],"application/x-deb":["deb"],"application/x-lzh-compressed":["lzh","lha"],"text/x-fortran":["f","for","f77","f90"],"application/x-xar":["xar"],"video/x-ms-wm":["wm"],"image/g3fax":["g3"],"application/vnd.rn-realmedia-vbr":["rmvb"],"application/x-tex-tfm":["tfm"],"application/vnd.yellowriver-custom-menu":["cmp"],"image/vnd.ms-modi":["mdi"],"chemical/x-cdx":["cdx"],"video/x-smv":["smv"],"application/x-stuffitx":["sitx"],"application/vnd.groove-help":["ghf"],"application/vnd.mfmp":["mfm"],"application/vnd.frogans.ltf":["ltf"],"text/uri-list":["uri","uris","urls"],"application/vnd.xfdl":["xfdl"],"application/vnd.bmi":["bmi"],"application/vnd.geogebra.file":["ggb"],"font/otf":["otf"],"application/vnd.ufdl":["ufd","ufdl"],"application/x-subrip":["srt"],"video/x-mng":["mng"],"application/vnd.rim.cod":["cod"],"text/x-vcard":["vcf"],"application/java-serialized-object":["ser"],"image/ief":["ief"],"application/vnd.shana.informed.formdata":["ifm"],"application/sdp":["sdp"],"application/vnd.ms-excel.template.macroenabled.12":["xltm"],"video/webm":["webm"],"application/wspolicy+xml":["wspolicy"],"video/jpm":["jpm","jpgm"],"application/mp4":["mp4s"],"application/vnd.wap.wmlc":["wmlc"],"application/vnd.wap.wbxml":["wbxml"],"application/vnd.micrografx.flo":["flo"],"application/vnd.ms-wpl":["wpl"],"application/x-doom":["wad"],"application/vnd.kenameaapp":["htke"],"audio/x-matroska":["mka"],"application/vnd.dreamfactory":["dfac"],"application/vnd.hhe.lesson-player":["les"],"application/yin+xml":["yin"],"application/x-msschedule":["scd"],"application/vnd.eszigno3+xml":["es3","et3"],"application/pgp-signature":["asc","sig"],"application/x-tcl":["tcl"],"application/vnd.sus-calendar":["sus","susp"],"application/vnd.previewsystems.box":["box"],"image/jpeg":["jpeg","jpg","jpe"],"application/vnd.mobius.msl":["msl"],"application/andrew-inset":["ez"],"application/vnd.sun.xml.calc.template":["stc"],"application/vnd.amazon.ebook":["azw"],"application/vnd.mophun.certificate":["mpc"],"application/x-bzip":["bz"],"application/vnd.muvee.style":["msty"],"application/x-msaccess":["mdb"],"application/x-gnumeric":["gnumeric"],"application/vnd.irepository.package+xml":["irp"],"application/sparql-query":["rq"],"application/vnd.dece.ttml+xml":["uvt","uvvt"],"application/vnd.wap.wmlscriptc":["wmlsc"],"application/x-sh":["sh"],"audio/x-wav":["wav"],"application/vnd.pocketlearn":["plf"],"application/vnd.oasis.opendocument.database":["odb"],"application/vnd.mediastation.cdkey":["cdkey"],"application/x-authorware-bin":["aab","x32","u32","vox"],"application/x-compress":["z"],"application/x-gzip":["gz","tgz"],"application/x-font-type1":["pfa","pfb","pfm","afm"],"text/tsx":["tsx"],"video/vnd.dece.hd":["uvh","uvvh"],"application/vnd.stardivision.math":["smf"],"image/vnd.djvu":["djvu","djv"],"application/x-conference":["nsc"],"application/x-font-bdf":["bdf"],"application/vnd.fluxtime.clip":["ftc"],"application/vnd.sun.xml.writer":["sxw"],"application/vnd.mozilla.xul+xml":["xul"],"application/reginfo+xml":["rif"],"video/3gpp":["3gp"],"video/vnd.vivo":["viv"],"application/widget":["wgt"],"application/x-font-linux-psf":["psf"],"application/vnd.geogebra.tool":["ggt"],"application/xml":["xml","xsl"],"application/vnd.dpgraph":["dpg"],"text/x-go":["go"],"application/zip":["zip"],"application/x-rpm":["rpm"],"application/xaml+xml":["xaml"],"application/vnd.contact.cmsg":["cdbcmsg"],"application/pkix-attr-cert":["ac"],"application/vnd.clonk.c4group":["c4g","c4d","c4f","c4p","c4u"],"application/vnd.handheld-entertainment+xml":["zmm"],"application/vnd.ms-project":["mpp","mpt"],"application/x-authorware-map":["aam"],"application/x-yaml":["yaml","yml"],"application/vnd.fujitsu.oasys3":["oa3"],"application/vnd.audiograph":["aep"],"application/vnd.openxmlformats-officedocument.wordprocessingml.document":["docx"],"application/vnd.oasis.opendocument.text":["odt"],"text/typescript":["ts"],"application/vnd.amiga.ami":["ami"],"application/vnd.epson.esf":["esf"],"application/cbor":["cbor"],"application/oxps":["oxps"],"video/vnd.mpegurl":["mxu","m4u"],"video/h261":["h261"],"application/vnd.yamaha.smaf-phrase":["spf"],"application/vnd.ms-fontobject":["eot"],"application/vnd.groove-injector":["grv"],"application/vnd.realvnc.bed":["bed"],"image/cgm":["cgm"],"model/vnd.mts":["mts"],"application/vnd.ms-powerpoint":["ppt","pps","pot"],"application/vnd.ms-pki.stl":["stl"],"application/vnd.ahead.space":["ahead"],"application/x-dtbresource+xml":["res"],"text/x-nfo":["nfo"],"application/pkix-crl":["crl"],"chemical/x-cif":["cif"],"application/x-cdlink":["vcd"],"application/x-latex":["latex"],"text/vnd.fly":["fly"],"application/vnd.smart.teacher":["teacher"],"audio/vnd.ms-playready.media.pya":["pya"],"font/woff":["woff"],"application/cdmi-queue":["cdmiq"],"application/vnd.ms-powerpoint.slideshow.macroenabled.12":["ppsm"],"audio/vnd.dece.audio":["uva","uvva"],"application/vnd.kde.kchart":["chrt"],"image/vnd.dxf":["dxf"],"application/x-elf":["elf"],"application/vnd.hp-pclxl":["pclxl"],"application/vnd.osgi.dp":["dp"],"application/vnd.noblenet-web":["nnw"],"image/vnd.dvb.subtitle":["sub"],"application/x-ms-wmz":["wmz"],"application/x-shar":["shar"],"application/x-shockwave-flash":["swf"],"font/collection":["ttc"],"video/x-msvideo":["avi"],"application/vnd.rn-realmedia":["rm"],"application/vnd.dvb.service":["svc"],"text/plain":["txt","text","conf","def","list","log","in"],"audio/vnd.lucent.voice":["lvp"],"application/x-tar":["tar"],"application/smil+xml":["smi","smil"],"font/ttf":["ttf"],"application/vnd.americandynamics.acc":["acc"],"application/ssml+xml":["ssml"],"application/vnd.ibm.rights-management":["irm"],"image/x-tga":["tga"],"application/x-compressed":["tgz"],"application/x-msgpack":["msgpack"],"application/x-mach-binary":["dylib"],"audio/mp4":["m4a","mp4a"],"application/vnd.publishare-delta-tree":["qps"],"application/x-gramps-xml":["gramps"],"application/vnd.aristanetworks.swi":["swi"],"audio/basic":["au","snd"],"application/vnd.pawaafile":["paw"],"image/ktx":["ktx"],"application/vnd.cups-ppd":["ppd"],"application/xproc+xml":["xpl"],"model/stl":["stl"],"application/x-iso9660-image":["iso"],"video/x-sgi-movie":["movie"],"audio/x-ms-wax":["wax"],"application/x-dvi":["dvi"],"application/vnd.is-xpr":["xpr"],"application/x-msdownload":["exe","dll","com","bat","msi"],"application/vnd.mobius.plc":["plc"],"model/gltf+json":["gltf"],"application/docbook+xml":["dbk"],"application/vnd.ms-powerpoint.presentation.macroenabled.12":["pptm"],"application/vnd.medcalcdata":["mc1"],"application/vnd.tcpdump.pcap":["pcap","cap","dmp"],"application/x-xfig":["fig"],"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":["xlsx"],"application/vnd.groove-tool-message":["gtm"],"application/pkcs8":["p8"],"application/vnd.sun.xml.calc":["sxc"],"application/pdf":["pdf"],"model/iges":["igs","iges"],"text/x-php":["php"],"video/3gpp2":["3g2"],"application/vnd.fdf":["fdf"],"application/x-x509-ca-cert":["der","crt"],"application/x-ms-application":["application"],"application/vnd.fdsn.seed":["seed","dataless"],"application/vnd.openxmlformats-officedocument.presentationml.presentation":["pptx"],"image/x-xpixmap":["xpm"],"application/ccxml+xml":["ccxml"],"application/vnd.oasis.opendocument.image":["odi"],"application/vnd.sun.xml.writer.global":["sxg"],"application/x-msmoney":["mny"],"application/vnd.sun.xml.draw":["sxd"],"application/x-ndjson":["ndjson"],"application/vnd.epson.salt":["slt"],"application/rls-services+xml":["rs"],"application/xop+xml":["xop"],"application/vnd.kodak-descriptor":["sse"],"text/calendar":["ics","ifb"],"application/x-mspublisher":["pub"],"application/vnd.oasis.opendocument.presentation":["odp"],"application/dssc+der":["dssc"],"application/vnd.hal+xml":["hal"],"text/vnd.wap.wml":["wml"],"application/vnd.fujitsu.oasys":["oas"],"application/vnd.lotus-screencam":["scm"],"application/vnd.mobius.mqy":["mqy"],"x-conference/x-cooltalk":["ice"],"application/vnd.immervision-ivp":["ivp"],"text/vnd.curl.mcurl":["mcurl"],"application/vnd.mfer":["mwf"],"application/vnd.visionary":["vis"],"application/vnd.accpac.simply.imp":["imp"],"application/vnd.businessobjects":["rep"],"application/vnd.oasis.opendocument.chart-template":["otc"],"application/exi":["exi"],"video/x-ms-asf":["asf","asx"],"application/vnd.commonspace":["csp"],"text/vnd.graphviz":["gv"],"image/x-portable-pixmap":["ppm"],"application/oda":["oda"],"application/vnd.groove-identity-message":["gim"],"application/vnd.openxmlformats-officedocument.spreadsheetml.template":["xltx"],"multipart/form-data":[],"application/vnd.fujitsu.oasys2":["oa2"],"application/vnd.adobe.xfdf":["xfdf"],"text/vnd.curl.scurl":["scurl"],"application/gzip":["gz"],"image/tiff":["tiff","tif"],"application/vnd.syncml+xml":["xsm"],"text/vnd.fmi.flexstor":["flx"],"application/vnd.yamaha.hv-dic":["hvd"],"application/vnd.syncml.dm+wbxml":["bdm"],"application/vnd.proteus.magazine":["mgz"],"application/vnd.oasis.opendocument.graphics":["odg"],"application/vnd.crick.clicker":["clkx"],"application/vnd.cluetrust.cartomobile-config":["c11amc"],"application/xv+xml":["mxml","xhvml","xvml","xvm"],"application/vnd.wqd":["wqd"],"application/vnd.hp-hpid":["hpid"],"application/vnd.zzazz.deck+xml":["zaz"],"application/dssc+xml":["xdssc"],"application/vnd.cluetrust.cartomobile-config-pkg":["c11amz"],"video/vnd.dece.video":["uvv","uvvv"],"application/vnd.palm":["pdb","pqa","oprc"],"audio/vnd.nuera.ecelp9600":["ecelp9600"],"application/vnd.oasis.opendocument.text-template":["ott"],"application/mads+xml":["mads"],"application/vnd.mobius.daf":["daf"],"audio/vnd.dts.hd":["dtshd"],"text/prs.lines.tag":["dsc"],"application/vnd.crick.clicker.template":["clkt"],"application/vnd.crick.clicker.palette":["clkp"],"application/vnd.pvi.ptid1":["ptid"],"image/x-portable-bitmap":["pbm"],"application/vnd.lotus-freelance":["pre"],"model/vnd.gdl":["gdl"],"application/vnd.unity":["unityweb"],"application/vnd.picsel":["efif"],"application/vnd.chemdraw+xml":["cdxml"],"application/x-xliff+xml":["xlf"],"application/vnd.yamaha.hv-script":["hvs"],"text/vnd.curl":["curl"],"chemical/x-cmdf":["cmdf"],"application/x-eva":["eva"],"application/winhlp":["hlp"],"application/x-pkcs7-certificates":["p7b","spc"],"application/x-debian-package":["deb","udeb"],"application/vnd.oasis.opendocument.formula":["odf"],"audio/s3m":["s3m"],"application/vnd.geonext":["gxt"],"application/xslt+xml":["xslt"],"application/vnd.claymore":["cla"],"video/x-theora":["ogv"],"application/vnd.sailingtracker.track":["st"],"application/x-install-instructions":["install"],"application/x-apple-diskimage":["dmg"],"image/vnd.ms-photo":["wdp"],"application/vnd.isac.fcs":["fcs"],"application/vnd.pg.osasli":["ei6"],"text/x-markdown":["md","markdown"],"text/vnd.wap.wmlscript":["wmls"],"video/jpeg":["jpgv"],"application/voicexml+xml":["vxml"],"application/vnd.curl.pcurl":["pcurl"],"application/vnd.nitf":["ntf","nitf"],"video/x-f4v":["f4v"],"application/x-mobipocket-ebook":["prc","mobi"],"application/pkix-cert":["cer"],"image/heif":["heif"],"application/vnd.adobe.fxp":["fxp","fxpl"],"video/quicktime":["qt","mov"],"application/vnd.crick.clicker.wordbank":["clkw"],"application/x-zip-compressed":["zip"],"text/sgml":["sgml","sgm"],"application/vnd.oasis.opendocument.spreadsheet-template":["ots"],"chemical/x-cml":["cml"],"text/csv":["csv"],"application/vnd.dece.zip":["uvz","uvvz"],"image/vnd.net-fpx":["npx"],"model/vrml":["wrl","vrml"],"application/gxf":["gxf"],"image/vnd.fujixerox.edmics-rlc":["rlc"],"application/vnd.fujitsu.oasysprs":["bh2"],"application/vnd.stardivision.impress":["sdd"],"application/x-xpinstall":["xpi"],"image/avif":["avif"],"application/scvp-vp-request":["spq"],"application/vnd.mophun.application":["mpn"],"application/x-csh":["csh"],"application/vnd.sun.xml.writer.template":["stw"],"application/vnd.ecowin.chart":["mag"],"application/vnd.lotus-approach":["apr"],"application/x-rar-compressed":["rar"],"application/vnd.mynfc":["taglet"],"application/pkcs7-mime":["p7m","p7c"],"application/x-envoy":["evy"],"application/vnd.umajin":["umj"],"application/mediaservercontrol+xml":["mscml"],"video/mpeg":["mpeg","mpg","mpe","m1v","m2v"],"application/vnd.geospace":["g3w"],"audio/x-flac":["flac"],"image/png":["png"],"application/srgs":["gram"],"audio/x-caf":["caf"],"model/vnd.vtu":["vtu"],"application/vnd.ms-excel.addin.macroenabled.12":["xlam"],"application/vnd.epson.ssf":["ssf"],"application/x-research-info-systems":["ris"],"application/vnd.igloader":["igl"],"application/vnd.curl.car":["car"],"image/x-freehand":["fh","fhc","fh4","fh5","fh7"],"application/x-msmetafile":["wmf","wmz","emf","emz"],"model/gltf-binary":["glb"],"application/x-7z-compressed":["7z"],"application/vnd.quark.quarkxpress":["qxd","qxt","qwd","qwt","qxl","qxb"],"application/vnd.acucobol":["acu"],"application/vnd.rig.cryptonote":["cryptonote"],"application/vnd.novadigm.ext":["ext"],"application/set-payment-initiation":["setpay"],"application/vnd.noblenet-directory":["nnd"],"image/svg+xml":["svg","svgz"],"video/vnd.dece.mobile":["uvm","uvvm"],"application/vnd.mobius.txf":["txf"],"application/x-chess-pgn":["pgn"],"application/vnd.fsc.weblaunch":["fsc"],"application/ecmascript":["ecma"],"application/vnd.vcx":["vcx"],"application/vnd.kde.kpresenter":["kpr","kpt"],"video/ogg":["ogv"],"application/vnd.ibm.secure-container":["sc"],"application/vnd.epson.quickanime":["qam"],"application/vnd.stepmania.stepchart":["sm"],"application/x-abiword":["abw"],"image/x-icon":["ico"],"text/yaml":["yaml","yml"],"application/vnd.gmx":["gmx"],"audio/vnd.dts":["dts"],"application/vnd.sun.xml.math":["sxm"],"video/x-fli":["fli"],"image/x-pict":["pic","pct"],"video/x-ogm":["ogm"],"application/x-dgc-compressed":["dgc"],"application/rss+xml":["rss"],"application/toml":["toml"],"application/vnd.apple.installer+xml":["mpkg"],"application/rpki-manifest":["mft"],"application/vnd.shana.informed.formtemplate":["itp"],"application/x-dtbncx+xml":["ncx"],"model/obj":["obj"],"application/oebps-package+xml":["opf"],"application/x-cpio":["cpio"],"application/marc":["mrc"],"application/vnd.ms-officetheme":["thmx"],"application/vnd.olpc-sugar":["xo"],"text/jsx":["jsx"],"application/x-stuffit":["sit"],"application/vnd.hp-jlyt":["jlt"],"audio/x-pn-realaudio":["ram","ra"],"application/vnd.accpac.simply.aso":["aso"],"application/metalink4+xml":["meta4"],"audio/midi":["mid","midi","kar","rmi"],"image/vnd.adobe.photoshop":["psd"],"application/vnd.enliven":["nml"],"application/octet-stream":["bin","dms","lrf","mar","so","dist","distz","pkg","bpk","dump","elc","deploy"],"video/x-ms-wmx":["wmx"]}
EOT
    return( \$data );
}

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::MIME - MIME Types and File Extension Class

=head1 SYNOPSIS

    use HTTP::Promise::MIME;
    my $m = HTTP::Promise::MIME->new || 
        die( HTTP::Promise::MIME->error, "\n" );
    # or you can specify your own mime.types data by providing a file
    my $m = HTTP::Promise::MIME->new( '/etc/mime.types' ) || 
        die( HTTP::Promise::MIME->error, "\n" );
    my $mime = $m->mime_type( '/some/where/file.txt' ); # text/plain
    my $mime = $m->mime_type_from_suffix( 'txt' ); # text/plain
    my $ext = $m->suffix( 'application/pgp-signature' ); # asc
    my @ext = $m->suffix( 'application/pgp-signature' ); # asc, sig
    my $hash = $m->types;

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

L<HTTP::Promise::MIME> is a class to find out the mime type of a file or its suffix a.k.a. extension based on its mime type.

The database of mime types is stored internally, so there is no dependence on outside file. You can, however, specify an optional mime database file as the first parameter when instantiating a new object.

=head1 CONSTRUCTOR

=head2 new

Provided with an optional file path to a C<mime.types> database and this will return a new instance of L<HTTP::Promise::MIME>

If an error occurred, it sets an L<error|Module::Generic/error> and returns C<undef>

=head1 METHODS

=head2 dump

    print( $m->dump );

This returns a string containing the mime types and their corresponding extensions in a format similar to that of C<mime.types>

=head2 mime_type

Provided with a file path, and this returns the mime type of that file.

For example:

    my $mime = $m->mime_type( '/some/where/file.txt' );
    # $mime is text/plain

=head2 mime_type_from_suffix

Provided with a suffix, and this will return the equivalent mime type.

Example:

    my $mime = $m->mime_type_from_suffix( 'txt' );
    # $mime is text/plain

=head2 suffix

Provided with a mime type and this return the first suffix in scalar context or the list of sufixes found that mime type.

Example:

    my $ext = $m->suffix( 'application/pgp-signature' );
    # $ext is asc
    my @ext = $m->suffix( 'application/pgp-signature' );
    # @ext contains: asc and sig

=head2 types

Returns an hash L<object|Module::Generic::Hash> containing mime types with their corresponding array reference of suffixes.

There is no mime type without suffix.

The internal data is from L<Apache2 trunk|http://svn.apache.org/viewvc/httpd/httpd/trunk/docs/conf/mime.types?view=markup>

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types>, and L<other Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types>

L<Apache2 trunk|http://svn.apache.org/viewvc/httpd/httpd/trunk/docs/conf/mime.types?view=markup>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
