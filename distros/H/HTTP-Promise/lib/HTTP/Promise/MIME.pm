##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/MIME.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/07
## Modified 2023/09/08
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
    use vars qw( $VERSION $TYPES $HAS_FILE_MMAGIC_XS );
    # use File::MMagic::XS;
    eval( "use File::MMagic::XS 0.09008" );
    our $HAS_FILE_MMAGIC_XS = $@ ? 0 : 1;                               
    # use Nice::Try;
    our $VERSION = 'v0.2.0';
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
    my $mime;
    # try-catch
    local $@;
    eval
    {
        if( $HAS_FILE_MMAGIC_XS )
        {
            my $m = File::MMagic::XS->new;
            $mime = $m->get_mime( "$file" );
        }
        else
        {
            require File::MMagic;
            my $m = File::MMagic->new;
            $mime = $m->checktype_filename( "$file" );
        }
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to get the mime type for file \"${file}\": $@" ) );
    }
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

sub _data
{
    my $data = <<'EOT';
{"application/vnd.is-xpr":["xpr"],"application/vnd.groove-help":["ghf"],"application/vnd.curl.pcurl":["pcurl"],"application/onenote":["onetoc","onetoc2","onetmp","onepkg"],"application/x-authorware-map":["aam"],"application/x-texinfo":["texinfo","texi"],"text/html":["html","htm"],"text/vnd.sun.j2me.app-descriptor":["jad"],"video/vnd.dvb.file":["dvb"],"application/x-subrip":["srt"],"application/vnd.accpac.simply.imp":["imp"],"image/g3fax":["g3"],"application/vnd.pocketlearn":["plf"],"application/vnd.yamaha.openscoreformat.osfpvg+xml":["osfpvg"],"application/vnd.immervision-ivu":["ivu"],"application/resource-lists-diff+xml":["rld"],"application/vnd.vsf":["vsf"],"application/vnd.ufdl":["ufd","ufdl"],"application/xaml+xml":["xaml"],"application/x-iso9660-image":["iso"],"application/vnd.unity":["unityweb"],"application/x-msbinder":["obd"],"application/vnd.realvnc.bed":["bed"],"image/x-portable-bitmap":["pbm"],"application/vnd.3gpp.pic-bw-small":["psb"],"application/octet-stream":["bin","dms","lrf","mar","so","dist","distz","pkg","bpk","dump","elc","deploy"],"application/vnd.mobius.txf":["txf"],"application/sparql-query":["rq"],"application/vnd.oasis.opendocument.database":["odb"],"application/vnd.openxmlformats-officedocument.spreadsheetml.template":["xltx"],"application/vnd.ecowin.chart":["mag"],"application/vnd.aristanetworks.swi":["swi"],"application/vnd.dreamfactory":["dfac"],"application/vnd.geoplan":["g2w"],"image/vnd.fastbidsheet":["fbs"],"application/vnd.groove-account":["gac"],"application/mp21":["m21","mp21"],"application/vnd.openxmlformats-officedocument.presentationml.slide":["sldx"],"application/vnd.kahootz":["ktz","ktr"],"application/vnd.groove-tool-message":["gtm"],"application/vnd.route66.link66+xml":["link66"],"audio/x-pn-realaudio":["ram","ra"],"application/vnd.mfer":["mwf"],"application/vnd.3m.post-it-notes":["pwn"],"application/vnd.mophun.certificate":["mpc"],"application/gxf":["gxf"],"application/smil+xml":["smi","smil"],"text/vnd.in3d.3dml":["3dml"],"application/vnd.airzip.filesecure.azs":["azs"],"application/vnd.geogebra.tool":["ggt"],"application/vnd.openxmlformats-officedocument.presentationml.template":["potx"],"application/vnd.sus-calendar":["sus","susp"],"audio/ogg":["oga","ogg","spx","opus"],"application/vnd.uiq.theme":["utz"],"application/vnd.criticaltools.wbs+xml":["wbs"],"application/vnd.ahead.space":["ahead"],"application/xenc+xml":["xenc"],"application/vnd.sailingtracker.track":["st"],"application/vnd.ms-artgalry":["cil"],"application/vnd.immervision-ivp":["ivp"],"model/vnd.gtw":["gtw"],"application/vnd.pg.format":["str"],"application/vnd.oasis.opendocument.spreadsheet-template":["ots"],"application/jsonml+json":["jsonml"],"application/vnd.ms-cab-compressed":["cab"],"application/vnd.dvb.ait":["ait"],"application/x-xpinstall":["xpi"],"application/vnd.triscape.mxs":["mxs"],"application/x-eva":["eva"],"application/vnd.crick.clicker.palette":["clkp"],"text/uri-list":["uri","uris","urls"],"application/vnd.intu.qfx":["qfx"],"application/vnd.fujitsu.oasysgp":["fg5"],"image/vnd.adobe.photoshop":["psd"],"application/pkix-crl":["crl"],"application/vnd.ms-pki.stl":["stl"],"audio/webm":["weba"],"application/x-ms-xbap":["xbap"],"audio/midi":["mid","midi","kar","rmi"],"image/x-portable-graymap":["pgm"],"application/x-bzip":["bz"],"application/vnd.osgi.subsystem":["esa"],"model/vnd.mts":["mts"],"image/x-freehand":["fh","fhc","fh4","fh5","fh7"],"application/rls-services+xml":["rs"],"application/vnd.antix.game-component":["atx"],"application/vnd.rn-realmedia":["rm"],"application/vnd.hp-hpid":["hpid"],"application/vnd.ms-excel.template.macroenabled.12":["xltm"],"text/vnd.curl.dcurl":["dcurl"],"application/vnd.ms-fontobject":["eot"],"application/vnd.nokia.radio-preset":["rpst"],"text/vnd.fly":["fly"],"image/prs.btif":["btif"],"application/cdmi-container":["cdmic"],"application/vnd.wolfram.player":["nbp"],"audio/x-ms-wax":["wax"],"application/vnd.mobius.plc":["plc"],"application/vnd.curl.car":["car"],"application/vnd.ms-powerpoint.addin.macroenabled.12":["ppam"],"application/pkcs7-mime":["p7m","p7c"],"image/vnd.dxf":["dxf"],"application/vnd.geospace":["g3w"],"application/vnd.cluetrust.cartomobile-config":["c11amc"],"application/x-cbr":["cbr","cba","cbt","cbz","cb7"],"application/pls+xml":["pls"],"text/x-asm":["s","asm"],"application/xhtml+xml":["xhtml","xht"],"application/vnd.stardivision.impress":["sdd"],"application/mads+xml":["mads"],"application/vnd.wap.wmlscriptc":["wmlsc"],"application/relax-ng-compact-syntax":["rnc"],"application/vnd.yamaha.hv-voice":["hvp"],"application/x-zmachine":["z1","z2","z3","z4","z5","z6","z7","z8"],"application/x-gtar":["gtar"],"application/x-chess-pgn":["pgn"],"application/vnd.google-earth.kml+xml":["kml"],"application/vnd.epson.salt":["slt"],"application/x-msmetafile":["wmf","wmz","emf","emz"],"application/x-msaccess":["mdb"],"application/vnd.amiga.ami":["ami"],"application/vnd.isac.fcs":["fcs"],"application/vnd.oasis.opendocument.text":["odt"],"video/h264":["h264"],"application/x-xz":["xz"],"application/x-font-type1":["pfa","pfb","pfm","afm"],"application/vnd.denovo.fcselayout-link":["fe_launch"],"audio/x-mpegurl":["m3u"],"application/vnd.dece.unspecified":["uvx","uvvx"],"application/vnd.stepmania.package":["smzip"],"text/turtle":["ttl"],"application/rdf+xml":["rdf"],"application/vnd.wqd":["wqd"],"application/pgp-encrypted":["pgp"],"application/javascript":["js"],"application/rpki-ghostbusters":["gbr"],"application/cdmi-queue":["cdmiq"],"application/vnd.ms-excel.sheet.binary.macroenabled.12":["xlsb"],"application/vnd.micrografx.igx":["igx"],"application/vnd.crick.clicker.keyboard":["clkk"],"model/vnd.collada+xml":["dae"],"application/vnd.groove-vcard":["vcg"],"application/vnd.ms-lrm":["lrm"],"application/x-director":["dir","dcr","dxr","cst","cct","cxt","w3d","fgd","swa"],"application/pkcs10":["p10"],"application/vnd.geometry-explorer":["gex","gre"],"application/patch-ops-error+xml":["xer"],"application/xml-dtd":["dtd"],"application/vnd.crick.clicker":["clkx"],"audio/mpeg":["mpga","mp2","mp2a","mp3","m2a","m3a"],"application/vnd.hydrostatix.sof-data":["sfd-hdstx"],"x-conference/x-cooltalk":["ice"],"audio/silk":["sil"],"application/vnd.openxmlformats-officedocument.presentationml.slideshow":["ppsx"],"text/vnd.wap.wmlscript":["wmls"],"chemical/x-cmdf":["cmdf"],"application/vnd.stardivision.writer":["sdw","vor"],"application/vnd.wordperfect":["wpd"],"image/x-xpixmap":["xpm"],"audio/x-ms-wma":["wma"],"application/scvp-cv-response":["scs"],"application/xop+xml":["xop"],"model/vrml":["wrl","vrml"],"application/wspolicy+xml":["wspolicy"],"application/set-payment-initiation":["setpay"],"application/vnd.yamaha.openscoreformat":["osf"],"text/tab-separated-values":["tsv"],"application/vnd.solent.sdkm+xml":["sdkm","sdkd"],"application/vnd.lotus-notes":["nsf"],"application/x-dtbresource+xml":["res"],"application/vnd.wap.wbxml":["wbxml"],"chemical/x-cdx":["cdx"],"application/vnd.sun.xml.impress":["sxi"],"text/cache-manifest":["appcache"],"application/x-doom":["wad"],"chemical/x-xyz":["xyz"],"application/vnd.stardivision.writer-global":["sgl"],"image/x-portable-anymap":["pnm"],"application/vnd.fujitsu.oasys":["oas"],"application/vnd.hp-jlyt":["jlt"],"application/x-envoy":["evy"],"application/vnd.wap.wmlc":["wmlc"],"application/mac-binhex40":["hqx"],"application/gpx+xml":["gpx"],"application/rpki-manifest":["mft"],"application/vnd.oasis.opendocument.chart":["odc"],"application/x-gca-compressed":["gca"],"application/x-hdf":["hdf"],"application/vnd.ezpix-package":["ez3"],"model/iges":["igs","iges"],"application/vnd.kinar":["kne","knp"],"application/vnd.muvee.style":["msty"],"application/java-serialized-object":["ser"],"application/pskc+xml":["pskcxml"],"application/xspf+xml":["xspf"],"application/vnd.openxmlformats-officedocument.wordprocessingml.document":["docx"],"text/vnd.curl.scurl":["scurl"],"image/x-tga":["tga"],"application/ipfix":["ipfix"],"video/vnd.dece.video":["uvv","uvvv"],"audio/x-flac":["flac"],"application/vnd.groove-identity-message":["gim"],"application/vnd.rn-realmedia-vbr":["rmvb"],"application/vnd.framemaker":["fm","frame","maker","book"],"application/yin+xml":["yin"],"application/x-font-snf":["snf"],"audio/s3m":["s3m"],"application/vnd.dpgraph":["dpg"],"application/vnd.enliven":["nml"],"application/vnd.apple.installer+xml":["mpkg"],"application/vnd.oasis.opendocument.presentation":["odp"],"application/x-font-ghostscript":["gsf"],"application/sdp":["sdp"],"application/vnd.oasis.opendocument.graphics-template":["otg"],"text/x-uuencode":["uu"],"video/mpeg":["mpeg","mpg","mpe","m1v","m2v"],"application/vnd.osgeo.mapguide.package":["mgp"],"application/vnd.gmx":["gmx"],"application/x-pkcs7-certreqresp":["p7r"],"application/x-shockwave-flash":["swf"],"text/x-vcalendar":["vcs"],"application/vnd.fujixerox.ddd":["ddd"],"application/inkml+xml":["ink","inkml"],"application/ogg":["ogx"],"application/vnd.lotus-organizer":["org"],"audio/vnd.dts.hd":["dtshd"],"image/x-mrsid-image":["sid"],"application/vnd.fujitsu.oasys3":["oa3"],"image/vnd.dvb.subtitle":["sub"],"application/vnd.sun.xml.calc.template":["stc"],"application/x-java-jnlp-file":["jnlp"],"application/vnd.dna":["dna"],"application/vnd.smart.teacher":["teacher"],"application/x-dtbook+xml":["dtb"],"application/pkcs8":["p8"],"application/vnd.seemail":["see"],"text/vnd.dvb.subtitle":["sub"],"application/sbml+xml":["sbml"],"video/x-fli":["fli"],"video/h263":["h263"],"video/x-ms-wvx":["wvx"],"application/vnd.adobe.air-application-installer-package+zip":["air"],"application/ssdl+xml":["ssdl"],"image/x-pcx":["pcx"],"image/vnd.wap.wbmp":["wbmp"],"application/vnd.oasis.opendocument.presentation-template":["otp"],"application/shf+xml":["shf"],"application/vnd.lotus-1-2-3":["123"],"application/vnd.epson.msf":["msf"],"application/x-cdlink":["vcd"],"application/vnd.sun.xml.calc":["sxc"],"application/vnd.crick.clicker.wordbank":["clkw"],"application/x-tar":["tar"],"text/x-pascal":["p","pas"],"application/reginfo+xml":["rif"],"application/x-ms-application":["application"],"video/3gpp2":["3g2"],"text/x-sfv":["sfv"],"application/vnd.spotfire.dxp":["dxp"],"application/vnd.flographit":["gph"],"application/vnd.stardivision.math":["smf"],"application/xproc+xml":["xpl"],"application/vnd.ms-word.document.macroenabled.12":["docm"],"application/cdmi-object":["cdmio"],"application/vnd.mobius.mbk":["mbk"],"application/mac-compactpro":["cpt"],"application/vnd.ms-xpsdocument":["xps"],"audio/vnd.lucent.voice":["lvp"],"application/docbook+xml":["dbk"],"application/vnd.musician":["mus"],"application/vnd.android.package-archive":["apk"],"application/vnd.hp-pclxl":["pclxl"],"application/prs.cww":["cww"],"application/vnd.groove-tool-template":["tpl"],"application/x-dgc-compressed":["dgc"],"application/xv+xml":["mxml","xhvml","xvml","xvm"],"application/vnd.3gpp.pic-bw-var":["pvb"],"audio/x-wav":["wav"],"application/vnd.fujitsu.oasysprs":["bh2"],"application/vnd.stepmania.stepchart":["sm"],"application/vnd.hbci":["hbci"],"application/x-xliff+xml":["xlf"],"application/vnd.openofficeorg.extension":["oxt"],"application/vnd.dece.ttml+xml":["uvt","uvvt"],"video/vnd.dece.pd":["uvp","uvvp"],"application/vnd.hp-hpgl":["hpgl"],"application/vnd.fsc.weblaunch":["fsc"],"application/tei+xml":["tei","teicorpus"],"application/vnd.adobe.xfdf":["xfdf"],"application/x-bcpio":["bcpio"],"application/x-cpio":["cpio"],"application/vnd.accpac.simply.aso":["aso"],"application/vnd.kodak-descriptor":["sse"],"application/x-tex-tfm":["tfm"],"application/vnd.oasis.opendocument.graphics":["odg"],"text/x-setext":["etx"],"application/x-mspublisher":["pub"],"application/thraud+xml":["tfi"],"video/webm":["webm"],"text/csv":["csv"],"application/vnd.handheld-entertainment+xml":["zmm"],"application/vnd.mcd":["mcd"],"application/vnd.oma.dd2+xml":["dd2"],"text/vnd.graphviz":["gv"],"audio/adpcm":["adp"],"application/msword":["doc","dot"],"application/cdmi-domain":["cdmid"],"application/vnd.trid.tpt":["tpt"],"application/vnd.contact.cmsg":["cdbcmsg"],"text/css":["css"],"application/andrew-inset":["ez"],"application/pkix-pkipath":["pkipath"],"application/mods+xml":["mods"],"video/ogg":["ogv"],"audio/vnd.dra":["dra"],"application/vnd.umajin":["umj"],"application/vnd.ms-project":["mpp","mpt"],"application/vnd.crick.clicker.template":["clkt"],"image/x-rgb":["rgb"],"application/hyperstudio":["stk"],"application/vnd.fujitsu.oasys2":["oa2"],"application/vnd.recordare.musicxml":["mxl"],"audio/vnd.dece.audio":["uva","uvva"],"application/x-msschedule":["scd"],"application/x-conference":["nsc"],"application/vnd.intercon.formnet":["xpw","xpx"],"video/3gpp":["3gp"],"application/vnd.dart":["dart"],"application/vnd.xara":["xar"],"application/vnd.fdsn.mseed":["mseed"],"video/x-ms-asf":["asf","asx"],"application/vnd.kde.kontour":["kon"],"application/rpki-roa":["roa"],"application/davmount+xml":["davmount"],"application/vnd.eszigno3+xml":["es3","et3"],"application/mathematica":["ma","nb","mb"],"application/vnd.airzip.filesecure.azf":["azf"],"application/vnd.lotus-screencam":["scm"],"application/vnd.rim.cod":["cod"],"text/x-nfo":["nfo"],"application/vnd.chipnuts.karaoke-mmd":["mmd"],"model/x3d+vrml":["x3dv","x3dvz"],"application/vnd.palm":["pdb","pqa","oprc"],"application/json":["json"],"application/winhlp":["hlp"],"application/vnd.llamagraphics.life-balance.desktop":["lbd"],"application/vnd.cups-ppd":["ppd"],"application/vnd.proteus.magazine":["mgz"],"application/vnd.pawaafile":["paw"],"application/oxps":["oxps"],"image/x-icon":["ico"],"application/vnd.trueapp":["tra"],"image/png":["png"],"application/vnd.neurolanguage.nlu":["nlu"],"application/mp4":["mp4s"],"application/vnd.nokia.radio-presets":["rpss"],"image/vnd.xiff":["xif"],"application/vnd.ms-powerpoint.presentation.macroenabled.12":["pptm"],"application/vnd.las.las+xml":["lasxml"],"application/wsdl+xml":["wsdl"],"video/x-m4v":["m4v"],"application/vnd.epson.ssf":["ssf"],"image/vnd.dwg":["dwg"],"application/mets+xml":["mets"],"application/vnd.simtech-mindmapper":["twd","twds"],"application/cu-seeme":["cu"],"application/vnd.intu.qbo":["qbo"],"audio/xm":["xm"],"application/vnd.cosmocaller":["cmc"],"font/ttf":["ttf"],"application/x-msterminal":["trm"],"application/vnd.ibm.modcap":["afp","listafp","list3820"],"application/vnd.medcalcdata":["mc1"],"video/x-ms-wmv":["wmv"],"application/vnd.recordare.musicxml+xml":["musicxml"],"audio/vnd.dts":["dts"],"application/x-msmediaview":["mvb","m13","m14"],"image/ief":["ief"],"application/vnd.blueice.multipass":["mpm"],"application/vnd.hp-hps":["hps"],"application/atomsvc+xml":["atomsvc"],"application/vnd.cloanto.rp9":["rp9"],"video/x-mng":["mng"],"image/gif":["gif"],"application/vnd.astraea-software.iota":["iota"],"application/x-sql":["sql"],"video/x-ms-vob":["vob"],"application/vnd.kde.kchart":["chrt"],"video/vnd.dece.hd":["uvh","uvvh"],"application/srgs":["gram"],"audio/x-matroska":["mka"],"application/vnd.fujixerox.docuworks.binder":["xbd"],"application/vnd.zzazz.deck+xml":["zaz"],"image/ktx":["ktx"],"application/vnd.ds-keypoint":["kpxx"],"application/vnd.sema":["sema"],"application/x-ustar":["ustar"],"application/x-nzb":["nzb"],"application/vnd.ms-excel":["xls","xlm","xla","xlc","xlt","xlw"],"application/vnd.google-earth.kmz":["kmz"],"application/vnd.commonspace":["csp"],"application/vnd.data-vision.rdz":["rdz"],"application/vnd.fdf":["fdf"],"text/x-c":["c","cc","cxx","cpp","h","hh","dic"],"audio/x-aiff":["aif","aiff","aifc"],"model/vnd.dwf":["dwf"],"application/metalink+xml":["metalink"],"application/vnd.mobius.msl":["msl"],"application/vnd.ms-htmlhelp":["chm"],"image/vnd.ms-photo":["wdp"],"application/vnd.noblenet-directory":["nnd"],"application/x-pkcs12":["p12","pfx"],"video/vnd.fvt":["fvt"],"application/vnd.adobe.fxp":["fxp","fxpl"],"application/x-sh":["sh"],"application/java-archive":["jar"],"application/vnd.svd":["svd"],"application/vnd.businessobjects":["rep"],"application/vnd.hhe.lesson-player":["les"],"application/x-ms-shortcut":["lnk"],"application/pdf":["pdf"],"video/x-ms-wmx":["wmx"],"application/x-authorware-seg":["aas"],"application/vnd.llamagraphics.life-balance.exchange+xml":["lbe"],"image/bmp":["bmp"],"video/h261":["h261"],"application/vnd.osgi.dp":["dp"],"application/scvp-vp-request":["spq"],"application/vnd.openxmlformats-officedocument.wordprocessingml.template":["dotx"],"audio/basic":["au","snd"],"application/vnd.jcp.javame.midlet-rms":["rms"],"application/vnd.mfmp":["mfm"],"application/vnd.mobius.daf":["daf"],"text/vnd.curl.mcurl":["mcurl"],"application/vnd.audiograph":["aep"],"application/vnd.ezpix-album":["ez2"],"application/omdoc+xml":["omdoc"],"application/vnd.geonext":["gxt"],"application/vnd.ms-pki.seccat":["cat"],"application/dssc+der":["dssc"],"application/vnd.pvi.ptid1":["ptid"],"image/x-cmx":["cmx"],"application/cdmi-capability":["cdmia"],"image/x-cmu-raster":["ras"],"application/vnd.tao.intent-module-archive":["tao"],"application/vnd.dvb.service":["svc"],"application/vnd.grafeq":["gqf","gqs"],"application/x-tcl":["tcl"],"application/x-research-info-systems":["ris"],"application/x-sv4cpio":["sv4cpio"],"application/vnd.fluxtime.clip":["ftc"],"audio/vnd.digital-winds":["eol"],"application/vnd.oasis.opendocument.image-template":["oti"],"message/rfc822":["eml","mime"],"application/vnd.kidspiration":["kia"],"application/epub+zip":["epub"],"application/x-glulx":["ulx"],"application/vnd.dynageo":["geo"],"application/yang":["yang"],"video/x-ms-wm":["wm"],"application/vnd.cinderella":["cdy"],"text/x-opml":["opml"],"application/vnd.ms-ims":["ims"],"application/vnd.rig.cryptonote":["cryptonote"],"application/vnd.pg.osasli":["ei6"],"application/xslt+xml":["xslt"],"text/vnd.fmi.flexstor":["flx"],"text/calendar":["ics","ifb"],"image/vnd.djvu":["djvu","djv"],"application/vnd.syncml+xml":["xsm"],"text/troff":["t","tr","roff","man","me","ms"],"application/x-chat":["chat"],"chemical/x-csml":["csml"],"application/vnd.semf":["semf"],"application/x-csh":["csh"],"application/vnd.stardivision.calc":["sdc"],"video/jpm":["jpm","jpgm"],"image/vnd.dece.graphic":["uvi","uvvi","uvg","uvvg"],"application/vnd.visionary":["vis"],"application/scvp-cv-request":["scq"],"application/vnd.fuzzysheet":["fzs"],"font/woff":["woff"],"application/zip":["zip"],"application/vnd.joost.joda-archive":["joda"],"application/x-stuffitx":["sitx"],"application/x-blorb":["blb","blorb"],"application/vnd.mobius.mqy":["mqy"],"application/x-xfig":["fig"],"application/x-cfs-compressed":["cfs"],"application/vnd.claymore":["cla"],"text/n3":["n3"],"image/x-xbitmap":["xbm"],"application/vnd.ms-word.template.macroenabled.12":["dotm"],"application/rsd+xml":["rsd"],"text/x-fortran":["f","for","f77","f90"],"application/x-font-linux-psf":["psf"],"font/otf":["otf"],"image/svg+xml":["svg","svgz"],"application/srgs+xml":["grxml"],"application/vnd.macports.portpkg":["portpkg"],"application/vnd.oasis.opendocument.formula":["odf"],"video/jpeg":["jpgv"],"application/emma+xml":["emma"],"application/vnd.dece.zip":["uvz","uvvz"],"video/vnd.vivo":["viv"],"video/vnd.mpegurl":["mxu","m4u"],"image/vnd.net-fpx":["npx"],"application/marc":["mrc"],"video/quicktime":["qt","mov"],"application/x-dvi":["dvi"],"application/vnd.ms-officetheme":["thmx"],"application/rtf":["rtf"],"application/metalink4+xml":["meta4"],"text/sgml":["sgml","sgm"],"application/vnd.zul":["zir","zirz"],"application/vnd.3gpp.pic-bw-large":["plb"],"application/vnd.3gpp2.tcap":["tcap"],"application/vnd.shana.informed.interchange":["iif"],"application/vnd.igloader":["igl"],"audio/x-aac":["aac"],"application/x-dtbncx+xml":["ncx"],"application/vnd.novadigm.ext":["ext"],"application/x-mswrite":["wri"],"application/vnd.ibm.minipay":["mpy"],"image/webp":["webp"],"application/vnd.epson.esf":["esf"],"application/vnd.syncml.dm+xml":["xdm"],"application/vnd.genomatix.tuxedo":["txd"],"application/atomcat+xml":["atomcat"],"text/vnd.wap.wml":["wml"],"font/collection":["ttc"],"application/vnd.smaf":["mmf"],"model/x3d+binary":["x3db","x3dbz"],"application/vnd.ibm.secure-container":["sc"],"audio/vnd.ms-playready.media.pya":["pya"],"text/vcard":["vcard"],"application/vnd.hp-pcl":["pcl"],"video/x-smv":["smv"],"application/x-silverlight-app":["xap"],"application/vnd.kde.kivio":["flw"],"application/x-mobipocket-ebook":["prc","mobi"],"application/vnd.picsel":["efif"],"audio/vnd.nuera.ecelp7470":["ecelp7470"],"audio/vnd.nuera.ecelp9600":["ecelp9600"],"chemical/x-cml":["cml"],"application/pkixcmp":["pki"],"application/ccxml+xml":["ccxml"],"text/x-vcard":["vcf"],"application/vnd.shana.informed.package":["ipk"],"application/java-vm":["class"],"image/tiff":["tiff","tif"],"application/x-bittorrent":["torrent"],"application/vnd.vcx":["vcx"],"application/vnd.lotus-wordpro":["lwp"],"image/vnd.fujixerox.edmics-rlc":["rlc"],"application/vnd.nitf":["ntf","nitf"],"application/x-authorware-bin":["aab","x32","u32","vox"],"audio/mp4":["m4a","mp4a"],"text/plain":["txt","text","conf","def","list","log","in"],"application/vnd.fdsn.seed":["seed","dataless"],"application/vnd.adobe.formscentral.fcdt":["fcdt"],"application/sru+xml":["sru"],"application/vnd.oasis.opendocument.formula-template":["odft"],"application/ecmascript":["ecma"],"application/vnd.acucobol":["acu"],"application/voicexml+xml":["vxml"],"application/x-font-pcf":["pcf"],"application/x-tex":["tex"],"application/x-t3vm-image":["t3"],"video/x-flv":["flv"],"application/x-font-bdf":["bdf"],"video/vnd.ms-playready.media.pyv":["pyv"],"application/vnd.yamaha.smaf-audio":["saf"],"video/mp4":["mp4","mp4v","mpg4"],"application/x-mscardfile":["crd"],"application/vnd.iccprofile":["icc","icm"],"application/vnd.clonk.c4group":["c4g","c4d","c4f","c4p","c4u"],"application/resource-lists+xml":["rl"],"image/vnd.fst":["fst"],"application/x-gnumeric":["gnumeric"],"application/vnd.yamaha.smaf-phrase":["spf"],"application/vnd.sun.xml.math":["sxm"],"application/vnd.hal+xml":["hal"],"image/jpeg":["jpeg","jpg","jpe"],"application/vnd.powerbuilder6":["pbd"],"video/vnd.dece.mobile":["uvm","uvvm"],"application/x-tads":["gam"],"application/vnd.novadigm.edx":["edx"],"application/vnd.koan":["skp","skd","skt","skm"],"application/vnd.kde.kformula":["kfo"],"application/oebps-package+xml":["opf"],"application/x-ms-wmd":["wmd"],"application/vnd.ms-powerpoint.slideshow.macroenabled.12":["ppsm"],"application/vnd.yamaha.hv-dic":["hvd"],"application/vnd.oasis.opendocument.image":["odi"],"model/vnd.vtu":["vtu"],"application/vnd.ms-excel.addin.macroenabled.12":["xlam"],"application/applixware":["aw"],"application/xcap-diff+xml":["xdf"],"application/vnd.mozilla.xul+xml":["xul"],"application/vnd.apple.mpegurl":["m3u8"],"application/vnd.ctc-posml":["pml"],"application/set-registration-initiation":["setreg"],"application/x-pkcs7-certificates":["p7b","spc"],"application/dssc+xml":["xdssc"],"application/pkcs7-signature":["p7s"],"text/x-java-source":["java"],"application/x-tgif":["obj"],"application/vnd.ms-wpl":["wpl"],"application/vnd.openxmlformats-officedocument.presentationml.presentation":["pptx"],"application/oda":["oda"],"application/vnd.adobe.xdp+xml":["xdp"],"application/vnd.oasis.opendocument.chart-template":["otc"],"image/sgi":["sgi"],"application/vnd.ms-powerpoint.slide.macroenabled.12":["sldm"],"application/vnd.visio":["vsd","vst","vss","vsw"],"application/vnd.kenameaapp":["htke"],"application/vnd.cluetrust.cartomobile-config-pkg":["c11amz"],"application/vnd.frogans.fnc":["fnc"],"application/x-apple-diskimage":["dmg"],"application/timestamped-data":["tsd"],"application/vnd.mynfc":["taglet"],"video/vnd.dece.sd":["uvs","uvvs"],"application/vnd.novadigm.edm":["edm"],"application/vnd.sun.xml.writer.global":["sxg"],"text/vnd.curl":["curl"],"application/ssml+xml":["ssml"],"application/vnd.yamaha.hv-script":["hvs"],"application/x-netcdf":["nc","cdf"],"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":["xlsx"],"application/x-install-instructions":["install"],"application/x-msmoney":["mny"],"application/vnd.nokia.n-gage.data":["ngdat"],"application/x-debian-package":["deb","udeb"],"application/vnd.noblenet-sealer":["nns"],"application/vnd.quark.quarkxpress":["qxd","qxt","qwd","qwt","qxl","qxb"],"application/vnd.oasis.opendocument.spreadsheet":["ods"],"application/mxf":["mxf"],"application/atom+xml":["atom"],"application/x-gramps-xml":["gramps"],"video/x-f4v":["f4v"],"application/vnd.ms-works":["wps","wks","wcm","wdb"],"application/mediaservercontrol+xml":["mscml"],"application/vnd.irepository.package+xml":["irp"],"application/x-futuresplash":["spl"],"application/vnd.kde.karbon":["karbon"],"application/vnd.groove-injector":["grv"],"application/vnd.mophun.application":["mpn"],"image/vnd.ms-modi":["mdi"],"application/vnd.yellowriver-custom-menu":["cmp"],"audio/vnd.rip":["rip"],"application/vnd.oasis.opendocument.text-web":["oth"],"application/x-ms-wmz":["wmz"],"application/vnd.wt.stf":["stf"],"application/vnd.insors.igm":["igm"],"application/vnd.oasis.opendocument.text-template":["ott"],"application/vnd.mif":["mif"],"application/vnd.spotfire.sfs":["sfs"],"application/vnd.mediastation.cdkey":["cdkey"],"application/exi":["exi"],"application/vnd.micrografx.flo":["flo"],"application/vnd.fujixerox.docuworks":["xdw"],"audio/x-pn-realaudio-plugin":["rmp"],"application/vnd.mseq":["mseq"],"application/vnd.ipunplugged.rcprofile":["rcprofile"],"image/x-3ds":["3ds"],"image/vnd.fpx":["fpx"],"application/pics-rules":["prf"],"application/vnd.uoml+xml":["uoml"],"application/vnd.previewsystems.box":["box"],"application/x-mie":["mie"],"text/prs.lines.tag":["dsc"],"application/vnd.geogebra.file":["ggb"],"image/vnd.fujixerox.edmics-mmr":["mmr"],"model/x3d+xml":["x3d","x3dz"],"application/mathml+xml":["mathml"],"audio/vnd.nuera.ecelp4800":["ecelp4800"],"application/vnd.kde.kspread":["ksp"],"application/vnd.epson.quickanime":["qam"],"application/vnd.noblenet-web":["nnw"],"application/vnd.anser-web-certificate-issue-initiation":["cii"],"application/vnd.sun.xml.writer":["sxw"],"application/font-tdpfr":["pfr"],"application/vnd.dece.data":["uvf","uvvf","uvd","uvvd"],"application/vnd.bmi":["bmi"],"application/x-freearc":["arc"],"application/postscript":["ai","eps","ps"],"image/cgm":["cgm"],"text/vnd.in3d.spot":["spot"],"application/vnd.jisp":["jisp"],"application/vnd.semd":["semd"],"application/vnd.sun.xml.draw":["sxd"],"application/x-x509-ca-cert":["der","crt"],"application/marcxml+xml":["mrcx"],"application/vnd.nokia.n-gage.symbian.install":["n-gage"],"application/vnd.dolby.mlp":["mlp"],"application/x-7z-compressed":["7z"],"application/vnd.oasis.opendocument.text-master":["odm"],"application/scvp-vp-response":["spp"],"application/vnd.frogans.ltf":["ltf"],"application/x-lzh-compressed":["lzh","lha"],"application/mbox":["mbox"],"application/vnd.ms-excel.sheet.macroenabled.12":["xlsm"],"application/vnd.pmi.widget":["wg"],"video/x-msvideo":["avi"],"application/vnd.sun.xml.draw.template":["std"],"application/x-msclip":["clp"],"application/pkix-cert":["cer"],"chemical/x-cif":["cif"],"application/vnd.ms-powerpoint":["ppt","pps","pot"],"application/vnd.kde.kpresenter":["kpr","kpt"],"application/x-sv4crc":["sv4crc"],"application/vnd.shana.informed.formdata":["ifm"],"application/pgp-signature":["asc","sig"],"application/vnd.symbian.install":["sis","sisx"],"application/vnd.ms-powerpoint.template.macroenabled.12":["potm"],"application/widget":["wgt"],"application/sparql-results+xml":["srx"],"application/x-stuffit":["sit"],"audio/x-caf":["caf"],"application/vnd.ibm.rights-management":["irm"],"application/x-rar-compressed":["rar"],"application/vnd.tcpdump.pcap":["pcap","cap","dmp"],"application/vnd.jam":["jam"],"text/richtext":["rtx"],"application/vnd.mobius.dis":["dis"],"application/x-shar":["shar"],"video/vnd.uvvu.mp4":["uvu","uvvu"],"model/mesh":["msh","mesh","silo"],"application/vnd.shana.informed.formtemplate":["itp"],"application/x-wais-source":["src"],"application/vnd.tmobile-livetv":["tmo"],"application/vnd.intergeo":["i2g"],"model/vnd.gdl":["gdl"],"application/rss+xml":["rss"],"application/x-abiword":["abw"],"application/x-bzip2":["bz2","boz"],"application/vnd.sun.xml.writer.template":["stw"],"application/vnd.lotus-freelance":["pre"],"application/pkix-attr-cert":["ac"],"video/x-matroska":["mkv","mk3d","mks"],"video/x-sgi-movie":["movie"],"application/vnd.publishare-delta-tree":["qps"],"image/x-pict":["pic","pct"],"application/vnd.lotus-approach":["apr"],"application/vnd.acucorp":["atc","acutc"],"application/vnd.americandynamics.acc":["acc"],"application/x-ace-compressed":["ace"],"application/x-latex":["latex"],"application/vnd.kde.kword":["kwd","kwt"],"image/x-portable-pixmap":["ppm"],"video/mj2":["mj2","mjp2"],"application/vnd.stardivision.draw":["sda"],"application/vnd.anser-web-funds-transfer-initiation":["fti"],"application/vnd.syncml.dm+wbxml":["bdm"],"application/vnd.olpc-sugar":["xo"],"application/xml":["xml","xsl"],"application/gml+xml":["gml"],"application/vnd.webturbo":["wtb"],"application/vnd.xfdl":["xfdl"],"application/lost+xml":["lostxml"],"font/woff2":["woff2"],"application/x-msdownload":["exe","dll","com","bat","msi"],"application/vnd.sun.xml.impress.template":["sti"],"application/vnd.chemdraw+xml":["cdxml"],"application/vnd.amazon.ebook":["azw"],"image/x-xwindowdump":["xwd"]}
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

    v0.2.0

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
