package IO::EPP::Test::VerisignCore;

=encoding utf8

=head1 NAME

IO::EPP::Test::VerisignCore

=head1 SYNOPSIS

Call IO::EPP::Verisign with parameter "test_mode=1"

=head1 DESCRIPTION

Module for testing IO::EPP::Verisign,
emulates answers of Verisign Core Server

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use Digest::MD5 qw(md5 md5_hex);

use IO::EPP::Verisign;
use IO::EPP::Test::Server;

use strict;
use warnings;

no utf8; # !!!

sub req {
    my ( $obj, $out_data, $info ) = @_;

    my $in_data;

    if ( !$out_data  or  $out_data =~ m|<hello[^<>]+/>| ) {
        $in_data = hello( $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<login>| ) {
        $in_data = login( $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<contact:| ) {
        $in_data = contacts();
    }
    elsif ( $out_data  and  $out_data =~ m|<host:check| ) {
        $in_data = host_check( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<host:create| ) {
        $in_data = host_create( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<host:info| ) {
        $in_data = host_info( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<host:update| ) {
        $in_data = host_update( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<host:delete| ) {
        $in_data = host_delete( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<domain:check| ) {
        $in_data = domain_check( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<domain:create| ) {
        $in_data = domain_create( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<domain:info| ) {
        $in_data = domain_info( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<domain:renew| ) {
        $in_data = domain_renew( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<domain:update| ) {
        $in_data = domain_update( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<domain:delete| ) {
        $in_data = domain_delete( $obj, $out_data );
    }
    elsif ( $out_data  and  $out_data =~ m|<logout/>| ) {
        $in_data = logout( $out_data );
    }
    else {
        print "FAIL $info!\n";
        die $out_data;
    }

    return $in_data;
}


our %statuses = (
    clientHold => '+',
    clientRenewProhibited => 'renewed',
    clientDeleteProhibited => 'deleted',
    clientUpdateProhibited => 'updated',
    clientTransferProhibited => 'transfered',
    serverHold => '+',
    serverRenewProhibited => 'renewed',
    serverDeleteProhibited => 'deleted',
    serverUpdateProhibited => 'updated',
    serverTransferProhibited => 'transfered',
);


sub get_date {
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);

    $year += 1900;
    $mon  += 1;

    my $dt1 = sprintf( '%0004d-%02d-%02dT%02d:%02d:%02d.0Z', $year,  $mon, $mday, $hour, $min, $sec );

    return $dt1;
}

sub add_5d {
    my ( $dt ) = @_;

    my ( $y, $m, $d ) = $dt =~ /^(\d{4})-(\d{2})-(\d{2})/;

    $d += 5;
    $m += 0;

    if ( $m == 1 || $m == 3 || $m == 5 || $m == 7 || $m == 8 || $m == 10 || $m == 12  and  $d > 31 ) {
        $d -= 31;
        $m++;
    }

    if ( $m == 4 || $m == 6 || $m == 9 || $m == 11  and  $d > 30 ) {
        $d -= 30;
        $m++;
    }

    if ( $m == 2  &&  $y % 4 == 0  and  $d > 29 ) {
        $d -= 29;
        $m++;
    }

    if ( $m == 2 &&  $y % 4 != 0  and  $d > 28 ) {
        $d -= 28;
        $m++;
    }

    if ( $m == 13 ) {
        $m = 1;
        $y++;
    }

    $d = '0'.$d if $d < 10;
    $m = '0'.$m if $m < 10;

    $dt =~ s/^(\d{4}-\d{2}-\d{2})/$y-$m-$d/;

    return $dt;
}

sub add_y {
    my ( $dt, $y ) = @_;

    my ( $y0 ) = $dt =~ /^(\d{4})/;

    $y0 += $y;

    $dt =~ s/^(\d{4})/$y0/;

    if ( $dt =~ /^\d{4}-02-29/  and  $y % 4 != 0 ) {
        $dt =~ s/-02-29/-03-01/;
    }

    return $dt;
}


sub get_svtrid {
    my $i = int( rand( 9999999999 ) );
    my $j = int( rand( 9999999 ) );
    my $k = int( rand( 999999 ) );

    return $i . '-' . $j . $k;
}


sub _fail_schema {
    my ( $err ) = @_;

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="2001"><msg>Command syntax error</msg><extValue><value xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:undef/></value><reason>XML Schema Validation Error: [SAXException] org.xml.sax.SAXException: EPPXMLErrorHandler.error() :
$err</reason></extValue></result><trID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}

sub _fail_schema2 {
    my ( $err ) = @_;

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="2001"><msg>Command syntax error</msg><extValue><value xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:undef/></value><reason>XML Schema Validation Error: $err</reason></extValue></result><trID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}


sub _fail_namestore {
    my ( $cltrid ) = @_;

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="2306"><msg>Parameter value policy error</msg><extValue><value xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:undef/></value><reason>NameStore Extension not provided</reason></extValue></result><extension><namestoreExt:nsExtErrData xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-1.1 namestoreExt-1.1.xsd"><namestoreExt:msg code="1">Specified sub-product does not exist</namestoreExt:msg></namestoreExt:nsExtErrData></extension><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|
}

sub _fail_answ {
    my ( $cltrid, $code, $msg ) = @_;

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="$code"><msg>$msg</msg></result><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}

sub _fail_answ_with_reason {
    my ( $cltrid, $code, $msg, $reason ) = @_;

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="$code"><msg>$msg</msg><extValue><value xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:undef/></value><reason>$reason</reason></extValue></result><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}


sub _ok_answ {
    my ( $cltrid, $answ, $ext ) = @_;

    if ( $ext ) {
        $ext = "<extension>$ext</extension>";
    }
    else {
        $ext = '';
    }

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><resData>$answ</resData>$ext<trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}

sub _ok_answ2 {
    my ( $cltrid, $answ, $ext ) = @_;

    if ( $ext ) {
$ext = qq|
    <extension>
$ext
    </extension>|;
    }
    else {
        $ext = '';
    }

    my $svtrid = get_svtrid();

    return qq|<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <response>
    <result code="1000">
      <msg>Command completed successfully</msg>
    </result>
    <resData>
     $answ
    </resData>$ext
    <trID>
      <clTRID>$cltrid</clTRID>
      <svTRID>$svtrid</svTRID>
    </trID>
  </response>
</epp>
|;
}

sub _min_answ {
    my ( $cltrid ) = @_;;

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}


sub _check_dom_dates {
    my ( $s, $dname ) = @_;

    my $dom = $s->data->{doms}{$dname};

    my $now = get_date();

    if ( $now gt $dom->{exp_date}  and  not $dom->{statuses}{pendingDelete} ) {
        # check on autoRenew
        my $end_auto_renew = add_5d( $dom->{exp_date} );

        if ( $end_auto_renew gt $now ) {
            $dom->{exp_date} = add_y( $dom->{exp_date} );
            print "updated exp_date\n";
        }
    }

    if ( $dom->{statuses}{pendingDelete} ) {
        # check on redemption time
        my $end_del_date = add_5d( add_5d( $dom->{del_date} ) );

        if ( $now gt $end_del_date ) {
            delete $s->{doms}{$dname};
        }

        if ( $dom->{statuses}{pendingRestore} ) {
            my $end_rest_date = add_5d( $dom->{upd_date} );

            if ( $now gt $end_rest_date ) {
                delete $dom->{statuses}{pendingRestore};
            }
        }
    }
}


sub hello {
    my $dt = get_date();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns="urn:ietf:params:xml:ns:epp-1.0"><greeting><svID>VeriSign Com/Net EPP Registration Server</svID><svDate>$dt</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>http://www.verisign.com/epp/registry-1.0</objURI><objURI>http://www.verisign.com/epp/lowbalance-poll-1.0</objURI><objURI>http://www.verisign.com/epp/rgp-poll-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.verisign.com/epp/whoisInf-1.0</extURI><extURI>http://www.verisign.com/epp/idnLang-1.0</extURI><extURI>urn:ietf:params:xml:ns:coa-1.0</extURI><extURI>http://www.verisign-grs.com/epp/namestoreExt-1.1</extURI><extURI>http://www.verisign.com/epp/sync-1.0</extURI><extURI>http://www.verisign.com/epp/relatedDomain-1.0</extURI><extURI>urn:ietf:params:xml:ns:verificationCode-1.0</extURI><extURI>urn:ietf:params:xml:ns:launch-1.0</extURI><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:changePoll-1.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><other/><prov/></purpose><recipient><ours/><public/><unrelated/></recipient><retention><indefinite/></retention></statement></dcp></greeting></epp>|;
}


sub login {
    my ( $body ) = @_;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_schema( q|Line....: 1
Column..: 2
Message.: : The markup in the document preceding the root element must be well-formed.| );
    }

    unless ( $body =~ s|^<epp xmlns="[^"]+" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_schema( q|Line....: 2
Column..: 173
Message.: : cvc-complex-type.3.2.2: Attribute 'xxx' is not allowed to appear in element 'epp'.| );
    }

    unless ( $body =~ s|\s*</epp>\s*||s ) {
        return _fail_schema( q|Line....: 11111
Column..: 6
Message.: : The end-tag for element type "epp" must end with a '&gt;' delimiter.| );
    }

    unless ( $body =~ s|<command>\s*||s ) {
        return _fail_schema( q|Line....: 3
Column..: 12
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'xxxxxx'. One of '{"urn:ietf:params:xml:ns:epp-1.0":greeting, "urn:ietf:params:xml:ns:epp-1.0":hello, "urn:ietf:params:xml:ns:epp-1.0":command, "urn:ietf:params:xml:ns:epp-1.0":response, "urn:ietf:params:xml:ns:epp-1.0":extension}' is expected.| );
    }

    unless ( $body =~ s|\s*</command>||s ) {
        return _fail_schema( q|Line....: 22222
Column..: 11
Message.: : The end-tag for element type "command" must end with a '&gt;' delimiter.| );
    }

    unless ( $body =~ s|<login>\s*||s ) {
        return _fail_schema( q|Line....: 4
Column..: 11
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'xxxxxx'. One of '{"urn:ietf:params:xml:ns:epp-1.0":check, "urn:ietf:params:xml:ns:epp-1.0":create, "urn:ietf:params:xml:ns:epp-1.0":delete, "urn:ietf:params:xml:ns:epp-1.0":info, "urn:ietf:params:xml:ns:epp-1.0":login, "urn:ietf:params:xml:ns:epp-1.0":logout, "urn:ietf:params:xml:ns:epp-1.0":poll, "urn:ietf:params:xml:ns:epp-1.0":renew, "urn:ietf:params:xml:ns:epp-1.0":transfer, "urn:ietf:params:xml:ns:epp-1.0":update}' is expected.| );
    }

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|;

    unless ( $cltrid ) {
        return _fail_schema( q|Line....: 11111
Column..: 22222
Message.: : cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '3' for type 'trIDStringType'.| );
    }

    unless ( $body =~ s|\s*</login>.+$||s ) {
        return _fail_schema( q|Line....: 27
Column..: 10
Message.: : The end-tag for element type "login" must end with a '&gt;' delimiter.| );
    }

    my ( $login ) = $body =~ m|<clID>([0-9A-Za-z_\-]+)</clID>|;

    return q|Line....: 5
Column..: 17
Message.: : cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '3' for type 'clIDType'.|
        unless $login;

    my ( $pass ) = $body =~ m|<pw>([0-9A-Za-z!\@\$\%*_.:=+?#,"'\-{}\[\]\(\)]+)</pw>|;

    if ( !$pass  ||  length( $pass ) < 6 ) {
        return q|Line....: 6
Column..: 13
Message.: : cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '6' for type 'pwType'.|;
    }

    my $svtrid = get_svtrid();

    if ( $pass eq 'fail-pass' ) {
        return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="2200"><msg>Authentication error</msg></result><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
    }

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Welcome user.</msg></result><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}


sub contacts {
    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="2306"><msg>Parameter value policy error</msg><extValue><value xmlns:epp="urn:ietf:params:xml:ns:epp-1.0"><epp:undef/></value><reason>Sub product dotCOM does NOT support contact</reason></extValue></result><trID><clTRID>11111</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}


sub _check_body {
    my ( $body_ref ) = @_;

    unless ( $$body_ref =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_schema( q|Line....: 1
Column..: 2
Message.: : The markup in the document preceding the root element must be well-formed.| );
    }

    unless ( $$body_ref =~ s|^<epp xmlns="[^"]+" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_schema( q|Line....: 2
Column..: 173
Message.: : cvc-complex-type.3.2.2: Attribute 'xxx' is not allowed to appear in element 'epp'.| );
    }

    unless ( $$body_ref =~ s|\s*</epp>\s*||s ) {
        return _fail_schema( q|Line....: 11111
Column..: 6
Message.: : The end-tag for element type "epp" must end with a '&gt;' delimiter.| );
    }

    unless ( $$body_ref =~ s|<command>\s*||s ) {
        return _fail_schema( q|Line....: 3
Column..: 12
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'xxxxxx'. One of '{"urn:ietf:params:xml:ns:epp-1.0":greeting, "urn:ietf:params:xml:ns:epp-1.0":hello, "urn:ietf:params:xml:ns:epp-1.0":command, "urn:ietf:params:xml:ns:epp-1.0":response, "urn:ietf:params:xml:ns:epp-1.0":extension}' is expected.| );
    }

    unless ( $$body_ref =~ s|\s*</command>||s ) {
        return _fail_schema( q|Line....: 22222
Column..: 11
Message.: : The end-tag for element type "command" must end with a '&gt;' delimiter.| );
    }

    my ( $cltrid ) = $$body_ref =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|;

    if ( $cltrid ) {
        $$body_ref =~ s|\s*<clTRID>[^<>]+</clTRID>\s*||s
    }
    else {
        return _fail_schema( q|Line....: 11111
Column..: 22222
Message.: : cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '3' for type 'trIDStringType'.| );
    }

    unless ( $$body_ref =~ m{<namestoreExt:subProduct>dot(COM|NET|EDU)</namestoreExt:subProduct>} ) {
        return _fail_namestore( $cltrid );
    }

    unless ( $$body_ref =~ s|\s*<namestoreExt:namestoreExt[^<>]+>.+</namestoreExt:namestoreExt>||s ) {
        return _fail_namestore( $cltrid );
    }

    my $cmd;
    if ( $$body_ref =~ s/<(check|create|info|renew|update|delete)>\s*//s ) {
        $cmd = $1;
    }
    else {
        return _fail_schema( q|Line....: 4
Column..: 11
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'xxxxxx'. One of '{"urn:ietf:params:xml:ns:epp-1.0":check, "urn:ietf:params:xml:ns:epp-1.0":create, "urn:ietf:params:xml:ns:epp-1.0":delete, "urn:ietf:params:xml:ns:epp-1.0":info, "urn:ietf:params:xml:ns:epp-1.0":login, "urn:ietf:params:xml:ns:epp-1.0":logout, "urn:ietf:params:xml:ns:epp-1.0":poll, "urn:ietf:params:xml:ns:epp-1.0":renew, "urn:ietf:params:xml:ns:epp-1.0":transfer, "urn:ietf:params:xml:ns:epp-1.0":update}' is expected.| );
    }

    unless ( $$body_ref =~ s|\s*</$cmd>.+$||s ) {
        return _fail_schema( qq|Line....: 22222
Column..: 10
Message.: : The end-tag for element type "$cmd" must end with a '&gt;' delimiter.| );
    }

    my $type;
    if ( $$body_ref =~ s/\s*<(host|domain):$cmd[^<>]+>\s*//s ) {
        $type = $1;
    }
    else {
        return _fail_schema( q|Line....: 5
Column..: 128
Message.: : cvc-complex-type.2.4.c: The matching wildcard is strict, but no declaration can be found for element 'xxxxxx'.| );
    }

    unless ( $$body_ref =~ s|\s*</$type:$cmd>\s*||s ) {
        return _fail_schema( qq|Line....: 7
Column..: 16
Message.: : The end-tag for element type "$type:$cmd" must end with a '&gt;' delimiter.| );
    }

    return ( 0, $cltrid );
}


sub host_check {
    my ( $obj, $body ) = @_;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my ( @hosts ) = $body =~ m|(<host:name>[^<>]+</host:name>)|g;

    unless ( scalar @hosts ) {
        _fail_schema( q|Line....: 7
Column..: 17
Message.: : cvc-complex-type.2.4.b: The content of element 'host:check' is not complete. One of '{"urn:ietf:params:xml:ns:host-1.0":name}' is expected.| );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $answ_list = '';
    foreach my $row ( @hosts ) {
        my ( $ns ) = $row =~ m|<host:name>([^<>]+)</host:name>|;
        $ns = lc $ns;

        my $avail = 1;

        if ( $s->data->{nss}{$ns} ) {
            $avail = 0;
        }
        elsif ( $ns !~ /^[0-9a-z\.\-]+\.[0-9a-z\-]+$/ ) {
            $avail = 0;
        }

        $answ_list .= qq|<host:cd><host:name avail="$avail">$ns</host:name></host:cd>|;
    }

    return _ok_answ( $cltrid, qq|<host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd">$answ_list</host:chkData>| );
}


sub host_create {
    my ( $obj, $body ) = @_;

    my ( $subProduct ) = $body =~ m|<namestoreExt:subProduct>dot([A-Z]+)</namestoreExt:subProduct>|;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my ( $ns, $dname );

    if ( $body =~ m|<host:name>([^<>]+)</host:name>| ) {
        $ns = lc $1;
    }
    else {
        return _fail_schema( q|Line....: 6
Column..: 17
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'host:name'. One of '{"urn:ietf:params:xml:ns:host-1.0":name}' is expected.| );
    }

    unless ( $ns =~ /^[0-9a-z][0-9a-z\-\.]*[0-9a-z]\.[0-9a-z][0-9a-z\-]*[0-9a-z]$/ ) {
        return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
    }

    # need error for unknown tld: _fail_answ( $cltrid, '2305', 'Object association prohibits operation' )

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    my $nss  = $s->data->{nss};
    my $doms = $s->data->{doms};

    if ( $nss->{$ns} ) {
        if ( $nss->{$ns}{owner} eq $obj->{user} ) {
            return _fail_answ( $cltrid, '2302', 'Object exists' );
        }
        else {
            return _fail_answ( $cltrid, '2201', 'Authorization error' );
        }
    }

    my ( $tld ) = $ns =~ /\.([0-9a-z\-]+)$/;

    my @v4;
    my @v6;

    if ( $tld =~ /^(com|net|edu)$/ ) {
        # need ip & Co
        ( $dname ) = $ns =~ /\.([0-9a-z\-]+\.[a-z]+)$/;

        unless ( $doms->{$dname} ) {
            return _fail_answ( $cltrid, '2305', 'Object association prohibits operation' );
        }

        if ( $doms->{$dname}{owner} ne $obj->{user} ) {
            return _fail_answ( $cltrid, '2201', 'Authorization error' );
        }

        @v4 = $body =~ m|<host:addr ip="v4">([^<>]+)</host:addr>|g;
        @v6 = $body =~ m|<host:addr ip="v6">([^<>]+)</host:addr>|g;

        if ( scalar( @v4 ) + scalar( @v6 ) == 0 ) {
            return _fail_answ( $cltrid, '2003', 'Required parameter missing' );
        }

        foreach my $v ( @v4 ) {
            unless ( $v =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
            }
        }
        foreach my $v ( @v6 ) {
            unless ( $v =~ /^[0-9a-z:]{1,29}$/ ) {
                return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
            }
        }
    }

    my $cre_date = get_date();

    my $roid = md5_hex($ns.$cre_date);
    $roid =~ s/[a-f]//ig;

    my %v4;
    $v4{$_} = '+' for @v4;
    my %v6;
    $v6{$_} = '+' for @v6;

    $nss->{$ns} = { avail => 0, reason => 'in use', statuses => { ok => '+' }, creater => $obj->{user}, owner => $obj->{user}, cre_date => $cre_date, addr_v4 => \%v4, addr_v6 => \%v6, roid => $roid . '_HOST_CNE-VRSN' };

    if ( $dname ) {
        $doms->{$dname}{hosts}{$ns} = '+';
    }

    return _ok_answ( $cltrid, qq|<host:creData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>$ns</host:name><host:crDate>$cre_date</host:crDate></host:creData>| );
}



sub host_info {
    my ( $obj, $body ) = @_;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my $ns;

    if ( $body =~ m|<host:name>([^<>]+)</host:name>| ) {
        $ns = lc $1;
    }
    else {
        return _fail_schema( q|Line....: 6
Column..: 17
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'host:name'. One of '{"urn:ietf:params:xml:ns:host-1.0":name}' is expected.| );
    }

    unless ( $ns =~ /^[0-9a-z][0-9a-z\-\.]*[0-9a-z]\.[0-9a-z][0-9a-z\-]*[0-9a-z]$/ ) {
        return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
    }

    # need error for unknown tld: _fail_answ( $cltrid, '2305', 'Object association prohibits operation' )

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    unless ( $s->data->{nss}{$ns} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    my $host  = $s->data->{nss}{$ns};

    if ( $host->{owner} ne $obj->{user} ) {
        return _fail_answ( $cltrid, '2201', 'Authorization error' );
    }

    my $answ = '<host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0">';
    $answ .= "<host:name>$ns</host:name>";
    $answ .= "<host:roid>" . $host->{roid} . "</host:roid>";
    for my $st ( keys %{$host->{statuses}} ) {
        $answ .= qq|<host:status s="$st"/>|;
    }
    for my $ip4 ( sort keys %{$host->{addr_v4}} ) {
        $answ .= qq|<host:addr ip="v4">$ip4</host:addr>|;
    }
    for my $ip6 ( sort keys %{$host->{addr_v6}} ) {
        $answ .= qq|<host:addr ip="v4">$ip6</host:addr>|;
    }
    $answ .= "<host:clID>$$host{owner}</host:clID>";
    $answ .= "<host:crID>$$host{creater}</host:crID>";
    $answ .= "<host:crDate>$$host{cre_date}</host:crDate>";
    if ( $host->{updater} ) {
        $answ .= "<host:upID>$$host{updater}</host:upID>";
    }
    else {
        $answ .= "<host:upID>$$host{creater}</host:upID>";
    }
    if ( $host->{upd_date} ) {
        $answ .= "<host:upDate>$$host{upd_date}</host:upDate>";
    }
    else {
        $answ .= "<host:upDate>$$host{cre_date}</host:upDate>";
    }
    $answ .= '</host:infData>';

    return _ok_answ( $cltrid, $answ );
}



sub host_update {
    my ( $obj, $body ) = @_;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my $ns;

    if ( $body =~ m|<host:name>([^<>]+)</host:name>| ) {
        $ns = lc $1;
    }
    else {
        return _fail_schema( q|Line....: 6
Column..: 17
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'host:name'. One of '{"urn:ietf:params:xml:ns:host-1.0":name}' is expected.| );
    }

    unless ( $ns =~ /^[0-9a-z][0-9a-z\-\.]*[0-9a-z]\.[0-9a-z][0-9a-z\-]*[0-9a-z]$/ ) {
        return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
    }

    # need error for unknown tld: _fail_answ( $cltrid, '2305', 'Object association prohibits operation' )

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    unless ( $s->data->{nss}{$ns} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    my $host  = $s->data->{nss}{$ns};

    if ( $host->{owner} ne $obj->{user} ) {
        return _fail_answ( $cltrid, '2201', 'Authorization error' );
    }

    # first check data
    my ( @a4, @a6, @d4, @d6, @ast, @dst );

    for my $act ( 'add', 'rem' ) {
        if ( $body =~ m|<host:$act>(.+?)</host:$act>|s ) {
            my $ab = $1;

            my @v4 = $ab =~ m|<host:addr ip="v4">([^<>]+)</host:addr>|g;
            my @v6 = $ab =~ m|<host:addr ip="v6">([^<>]+)</host:addr>|g;

            foreach my $v ( @v4 ) {
                unless ( $v =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                    return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
                }

                if ( $act eq 'add' ) {
                    if ( $host->{addr_v4}{$v} ) {
                        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$v addr is already associated" );
                    }

                    push @a4, $v;
                }
                else {
                    unless ( $host->{addr_v4}{$v} ) {
                        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$v addr not found" );
                    }

                    push @d4, $v;
                }
            }

            foreach my $v ( @v6 ) {
                unless ( $v =~ /^[0-9a-f:]{1,29}$/ ) {
                    return _fail_answ( $cltrid,  '2005', 'Parameter value syntax error'  );
                }

                if ( $act eq 'add' ) {
                    if ( $host->{addr_v6}{$v} ) {
                        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$v addr is already associated" );
                    }

                    push @a6, $v;
                }
                else {
                    unless ( $host->{addr_v6}{$v} ) {
                        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$v addr not found" );
                    }

                    push @d6, $v;
                }
            }

            my @st = $ab =~ m|<host:status s="([^"]+)"/>|g;

            foreach my $st ( @st ) {
                if ( $st !~ /^(clientDeleteProhibited|clientUpdateProhibited|linked|ok|pendingCreate|pendingDelete|pendingTransfer|pendingUpdate| serverDeleteProhibited|serverUpdateProhibited)$/ ) {
                    return _fail_schema2( qq|Line: 8, Column: 46, Message: cvc-enumeration-valid: Value '$st' is not facet-valid with respect to enumeration '[clientDeleteProhibited, clientUpdateProhibited, linked, ok, pendingCreate, pendingDelete, pendingTransfer, pendingUpdate, serverDeleteProhibited, serverUpdateProhibited]'. It must be a value from the enumeration.| );
                }

                if ( $st !~ /^(clientDeleteProhibited|clientUpdateProhibited)$/ ) {
                    return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "request contains no actual object updates" );
                }

                if ( $act eq 'add' ) {
                    if ( $host->{statuses}{$st} ) {
                        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$st status is already associated" );
                    }

                    push @ast, $st;
                }
                else {
                    unless ( $host->{statuses}{$st} ) {
                        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$st status not found" );
                    }

                    push @dst, $st;
                }
            }
        }
    }

    if ( ( scalar( @a4 ) + scalar( @a6 ) ) == 0  and  ( scalar( @d4 ) + scalar( @d6 ) > 0 ) ) {
        if ( ( scalar( @d4 ) + scalar( @d6 ) ) == ( scalar( keys %{$host->{addr_v4}} ) + scalar( keys %{$host->{addr_v6}} ) ) ) {
            return _fail_answ( $cltrid, '2003', 'Required parameter missing' );
        }
    }

    if ( $body =~ m|<host:chg/>|  or  $body =~ m|<host:chg></host:chg>| ) {
        return _fail_schema2( qq|Line: 13, Column: 16, Message: cvc-complex-type.2.4.b: The content of element 'host:chg' is not complete. One of '{"urn:ietf:params:xml:ns:host-1.0":name}' is expected.| )
    }

    # TODO: chg name
=rem
2019-12-29 05:01:50 SRS::Comm::Provider::EPP::Base::epp_log:95
pid: 2559
update_ns request:
<?xml version="1.0" encoding="UTF-8"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">
 <command>
  <update>
   <host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd">
    <host:name>ns2.medinavai.com</host:name>
      <host:chg><host:name>ns2.medinavai.com.deletednss.com</host:name></host:chg>
   </host:update>
  </update>
  <extension>
   <namestoreExt:namestoreExt xmlns:namestoreExt="http://www.verisign-grs.com/epp/namestoreExt-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.verisign-grs.com/epp/namestoreExt-
1.1 namestoreExt-1.1.xsd">
    <namestoreExt:subProduct>dotCOM</namestoreExt:subProduct>
   </namestoreExt:namestoreExt>
  </extension>
  <clTRID>25d436e52c40ae318b831e52350d8352</clTRID>
 </command>
</epp>

2019-12-29 05:01:50 SRS::Comm::Provider::EPP::Base::epp_log:95
pid: 2559
req_time: 0.1559
update_ns answer:
<?xml version="1.0" encoding="UTF-8"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully</msg></result><trID><clTRID>25d436e52c40ae318b831e52350d8352</clTRID><s
vTRID>4521195083-1577584910758-20475271877</svTRID></trID></response></epp>
=cut
    # after update

    # only first add, after delete: so the registy works
    $host->{addr_v4}{$_} = '+' for @a4;

    $host->{addr_v6}{$_} = '+' for @a6;

    $host->{statuses}{$_} = '+' for @ast;

    delete $host->{addr_v4}{$_} for @d4;

    delete $host->{addr_v6}{$_} for @d6;

    delete $host->{statuses}{$_} for @dst;

    return _min_answ( $cltrid );
}


sub host_delete {
    my ( $obj, $body ) = @_;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my $ns;

    if ( $body =~ m|<host:name>([^<>]+)</host:name>| ) {
        $ns = lc $1;
    }
    else {
        return _fail_schema( q|Line....: 6
Column..: 17
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'host:name'. One of '{"urn:ietf:params:xml:ns:host-1.0":name}' is expected.| );
    }

    unless ( $ns =~ /^[0-9a-z][0-9a-z\-\.]*[0-9a-z]\.[0-9a-z][0-9a-z\-]*[0-9a-z]$/ ) {
        return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
    }

    # need error for unknown tld: _fail_answ( $cltrid, '2305', 'Object association prohibits operation' )

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    unless ( $s->data->{nss}{$ns} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    my $host  = $s->data->{nss}{$ns};

    if ( $host->{owner} ne $obj->{user} ) {
        return _fail_answ( $cltrid, '2201', 'Authorization error' );
    }

    if ( $host->{statuses}{linked} ) {
        return _fail_answ( $cltrid, '2305', 'Object association prohibits operation' );
    }

    my $dname;

    if ( $ns =~ /\b(com|net|edu)$/ ) {
        ( $dname ) = $ns =~ /\.([0-9a-z\-]+\.[a-z]+)$/;

        my $doms = $s->data->{doms};

        delete $doms->{$dname}{hosts}{$ns};
    }

    delete $s->data->{nss}{$ns};

    my $svtrid = get_svtrid();

    return _min_answ( $cltrid );
}


sub domain_check {
    my ( $obj, $body ) = @_;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my ( @domains ) = $body =~ m|(<domain:name>[^<>]+</domain:name>)|g;

    unless ( scalar @domains ) {
        return _fail_body( 'domain:name' );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $doms  = $s->data->{doms};

    my $answ_list = '';
    foreach my $row ( @domains ) {
        my ( $dm ) = $row =~ m|<domain:name>([^<>]+)</domain:name>|;

        my ( $avail, $reason );

        if ( $doms->{$dm} ) {
            $avail  = $doms->{$dm}{avail};
            $reason = $doms->{$dm}{reason};
        }
        elsif ( $dm !~ /^[0-9-a-z\-]+\.[a-z]+$/ ) {
            $avail = 0;
            $reason =  '<domain:reason>Invalid Domain Name</domain:reason>';
        }
        elsif ( $dm =~ /^reg*\.(com|net|edu)$/ ) { # reged
            $avail = 0;
            $reason = '<domain:reason>Domain exists</domain:reason>';
        }
        elsif ( $dm =~ /\.(com|net|edu)$/ ) {
            $avail = int( rand( 10 ) ) > 1 ? 1 : 0; # 10% are not avail

            if ( $avail ) {
                $reason = '';
            }
            else {
                $reason = '<domain:reason>Domain exists</domain:reason>';

                $doms->{$dm}{avail}  = 0;
                $doms->{$dm}{reason} = 'Domain exists';
            }
        }
        else {
            $avail = 0;
            $reason = '<domain:reason>Not an authoritative TLD</domain:reason>';
        }

        $answ_list .= qq|<domain:cd><domain:name avail="$avail">$dm</domain:name>$reason</domain:cd>|;
    }

    return _ok_answ( $cltrid, qq|<domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd">$answ_list</domain:chkData>| );
}


sub domain_create {
    my ( $obj, $body ) = @_;

    my ( $subProduct ) = $body =~ m|<namestoreExt:subProduct>dot([A-Z]+)</namestoreExt:subProduct>|;
    my ( $lang )       = $body =~ m|<idnLang:tag xmlns:idnLang="http://www\.verisign\.com/epp/idnLang-1\.0">([A-Z]{3})</idnLang:tag>|;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]*)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_schema2( q|Line: 8, Column: 21, Message: cvc-complex-type.2.4.a: Invalid content was found starting with element '{"urn:ietf:params:xml:ns:domain-1.0":names}'. One of '{"urn:ietf:params:xml:ns:domain-1.0":name}' is expected.| );
    }

    unless ( $dname ) {
        return _fail_schema2( q|Line: 8, Column: 34, Message: cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '1' for type 'labelType'.| );
    }

    unless ( $dname =~ /^[0-9a-z][0-9a-z\-]*[0-9a-z]\.[0-9a-z][0-9a-z\-]+[0-9a-z]$/ ) {
        return _fail_answ_with_reason( $cltrid, '2005', 'Parameter value syntax error', 'Domain name contains an invalid DNS character' );
    }

    my ( $tld ) = $dname =~ /\.([0-9a-z\-]+)$/;

    if ( $tld ne lc( $subProduct )  ) {
        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value syntax error', 'Subproduct ID does not match the domain TLD' );
    }

    my $period;
    if ( $body =~ m|<domain:period unit="y">([^<>]*)</domain:period>| ) {
        $period = $1;
    }
    else {
        return _fail_schema2( q|Line: 9, Column: 32, Message: cvc-complex-type.2.4.a: Invalid content was found starting with element '{"urn:ietf:params:xml:ns:domain-1.0":xxxxxx}'. One of '{"urn:ietf:params:xml:ns:domain-1.0":period, "urn:ietf:params:xml:ns:domain-1.0":ns, "urn:ietf:params:xml:ns:domain-1.0":registrant, "urn:ietf:params:xml:ns:domain-1.0":contact, "urn:ietf:params:xml:ns:domain-1.0":authInfo}' is expected.| );
    }

    unless ( $period  and  $period =~ /^[0-9]+$/) {
        return _fail_schema2( qq|Line: 9, Column: 47, Message: cvc-datatype-valid.1.2.1: '$period' is not a valid value for 'integer'.| );
    }

    if ( $period < 1 ) {
        return _fail_schema2( qq|Line: 9, Column: 48, Message: cvc-minInclusive-valid: Value '$period' is not facet-valid with respect to minInclusive '1' for type 'pLimitType'.| );
    }

    if ( $period > 99 ) {
        return _fail_schema2( qq|Line: 9, Column: 50, Message: cvc-maxInclusive-valid: Value '$period' is not facet-valid with respect to maxInclusive '99' for type 'pLimitType'.| );
    }

    if ( $period > 10 ) {
        return _fail_answ( $cltrid, '2306', 'Parameter value policy error' );
    }

    my @nss;
    if ( $body =~ m|<domain:ns>(.+)</domain:ns>|s ) {
        my $nss = $1;

        my @rows = $body =~ m|<domain:hostObj>(.*)</domain:hostObj>|g;

        foreach my $row ( @rows ) {
            unless ( $row ) {
                return _fail_schema2( q|12, Column: 42, Message: cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '1' for type 'labelType'.| ) ;
            }

            if ( $row !~ /^([0-9a-z][0-9a-z\-]*[0-9a-z]\.)+[0-9a-z][0-9a-z\-]*[0-9a-z]$/ ) {
                return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
            }

            push @nss, $row;
        }
    }

    my $authinfo;
    if ( $body =~ m|<domain:authInfo>(.*)</domain:authInfo>|s ) {
        my $row = $1;

        if ( $row  &&  $row =~ m|<domain:pw>(.*)</domain:pw>|s ) {
            $authinfo = $1;

            unless ( $authinfo ) {
                return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', 'Auth Info not provided' );
            }

            unless ( $authinfo =~ /[A-Z]/  &&  $authinfo =~ /[a-z]/  &&  $authinfo =~ /[0-9]/  &&  $authinfo =~ /[!\@\$\%*_.:\-=+?#,"'\\\/<>\[\]\{\}]/ ) {
                return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', 'Invalid Auth Info' );
            }
        }
        else {
            return _fail_schema2( q|Line: 15, Column: 25, Message: cvc-complex-type.2.4.b: The content of element 'domain:authInfo' is not complete. One of '{"urn:ietf:params:xml:ns:domain-1.0":pw, "urn:ietf:params:xml:ns:domain-1.0":ext}' is expected.| );
        }
    }
    else {
        return _fail_schema2( q|Line: 14, Column: 21, Message: cvc-complex-type.2.4.b: The content of element 'domain:create' is not complete. One of '{"urn:ietf:params:xml:ns:domain-1.0":registrant, "urn:ietf:params:xml:ns:domain-1.0":contact, "urn:ietf:params:xml:ns:domain-1.0":authInfo}' is expected.| );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $hosts = $s->data->{nss};
    my $doms  = $s->data->{doms};

    if ( $dname =~ /^xn--/  and  !$lang ) {
        return _fail_answ_with_reason( $cltrid, '2003', 'Required parameter missing', 'Language Extension required for IDN label domain names.' );
    }

    if ( $doms->{$dname}  ||  $dname =~ /^reg/ ) {
        return _fail_answ( $cltrid, '2302', 'Object exists' );
    }

    my %nss;
    foreach my $ns ( @nss ) {
        unless ( $hosts->{$ns} ) {
            return _fail_answ_with_reason( $cltrid, '2303', 'Object does not exist', "ns $ns does not exist" );
        }

        $nss{$ns} = '+';
    }

    my $cre_date = get_date();
    my $exp_date = add_y( $cre_date, 1 );

    my $roid = uc( md5_hex($dname.$cre_date) );

    $doms->{$dname} = {
        nss => \%nss,
        hosts => {},
        cre_date => $cre_date,
        upd_date => $cre_date,
        exp_date => $exp_date,
        authInfo => $authinfo,
        roid => $roid.'_DOMAIN_'.$subProduct.'-VRSN',
        statuses => { 'ok' => '+' },
        creater => $obj->{user},
        owner => $obj->{user},
        updater => $obj->{user},
        avail => 0,
        reason => 'Domain exists',
    };

    foreach my $ns ( keys %nss ) {
        $hosts->{$ns}{statuses}{linked}++;
    }

    return _ok_answ2( $cltrid, qq|
      <domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>$dname</domain:name>
        <domain:crDate>$cre_date</domain:crDate>
        <domain:exDate>$exp_date</domain:exDate>
      </domain:creData>
    | );
}


sub domain_info  {
    my ( $obj, $body ) = @_;

    my ( $subProduct ) = $body =~ m|<namestoreExt:subProduct>dot([A-Z]+)</namestoreExt:subProduct>|;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my ( $show_hosts, $dname );
    if ( $body =~ m|<domain:name(\s+host="([A-Za-z]+)")?>([^<>]*)</domain:name>| ) {
        $show_hosts = lc $2 if $2;
        $dname = lc $3;
    }
    else {
        return _fail_schema2( q|Line: 8, Column: 21, Message: cvc-complex-type.2.4.a: Invalid content was found starting with element '{"urn:ietf:params:xml:ns:domain-1.0":names}'. One of '{"urn:ietf:params:xml:ns:domain-1.0":name}' is expected.| );
    }

    unless ( $dname ) {
        return _fail_schema2( q|Line: 8, Column: 34, Message: cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '1' for type 'labelType'.| );
    }

    unless ( $dname =~ /^[0-9a-z][0-9a-z\-]*[0-9a-z]\.[0-9a-z][0-9a-z\-]+[0-9a-z]$/ ) {
        return _fail_answ_with_reason( $cltrid, '2005', 'Parameter value syntax error', 'Domain name contains an invalid DNS character' );
    }

    my ( $tld ) = $dname =~ /\.([0-9a-z\-]+)$/;

    if ( $tld ne lc( $subProduct )  ) {
        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value syntax error', 'Incorrect NameStore Extension' );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    _check_dom_dates( $s, $dname );

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }


    my $dm = $s->data->{doms}{$dname};

    if ( $dm->{owner} ne $obj->{user} ) {
        return _fail_answ_with_reason( $cltrid, '2201', 'Authorization error', 'Subordinate host info not available with partial info' );
    }

    my $answ = '<domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">';
    $answ .= "<domain:name>" . uc( $dname ) . "</domain:name>";
    $answ .= '<domain:roid>'.$dm->{roid}.'</domain:roid>';
    $answ .= qq|<domain:status s="$_"/>| for ( sort keys %{$dm->{statuses}} );
    if ( scalar( keys %{$dm->{nss}} ) ) {
        $answ .= '<domain:ns>';

        foreach my $ns ( sort keys %{$dm->{nss}} ) {
            $answ .= "<domain:hostObj>$ns</domain:hostObj>";
        }

        $answ .= '</domain:ns>';
    }
    if ( !$show_hosts  or  $show_hosts ne 'none' ) {
        foreach my $host ( sort keys %{$dm->{hosts}} ) {
            $answ .= "<domain:host>$host</domain:host>";
        }
    }
    $answ .= "<domain:clID>$$dm{owner}</domain:clID>";
    $answ .= "<domain:crID>$$dm{creater}</domain:crID>";
    $answ .= "<domain:crDate>$$dm{cre_date}</domain:crDate>";
    $answ .= "<domain:upID>$$dm{updater}</domain:upID>";
    $answ .= "<domain:upDate>$$dm{upd_date}</domain:upDate>";
    $answ .= "<domain:exDate>$$dm{exp_date}</domain:exDate>";
    $answ .= "<domain:trDate>$$dm{tr_date}</domain:trDate>" if $dm->{tr_date};
    $answ .= "<domain:authInfo><domain:pw>$$dm{authInfo}</domain:pw></domain:authInfo>";
    $answ .= '</domain:infData>';

    my $rgp = '';
    my $now = get_date();

    my $c5d = add_5d( $$dm{cre_date} );
    if ( $now lt $c5d ) {
        $rgp .= '<rgp:rgpStatus s="addPeriod">endDate=' . $c5d . '</rgp:rgpStatus>';
    }

    my $r5d = $$dm{ren_date} ? add_5d( $$dm{ren_date} ) : '';
    if ( $r5d  and  $now lt $r5d ) {
        $rgp .= '<rgp:rgpStatus s="renewPeriod">endDate=' . $r5d . '</rgp:rgpStatus>';
    }

    my $t5d = $$dm{tr_date} ? add_5d( $$dm{tr_date} ) : '';
    if ( $t5d  and  $now lt $t5d ) {
        $rgp .= '<rgp:rgpStatus s="transferPeriod">endDate=' . $t5d . '</rgp:rgpStatus>';
    }

    if ( $now gt $dm->{exp_date} ) {
        my $ar5d = add_5d( $dm->{exp_date} );
        $rgp .= '<rgp:rgpStatus s="autoRenewPeriod">endDate=' . $ar5d . '</rgp:rgpStatus>';
    }

    if ( $dm->{statuses}{pendingDelete} ) {
        my $d5d = add_5d( $dm->{del_date} );

        if ( $now lt $d5d ) {
            $rgp .= '<rgp:rgpStatus s="redemptionPeriod">endDate=' . $d5d . '</rgp:rgpStatus>';
        }
        else {
            # after redemption
            $d5d = add_5d( $d5d );

            $rgp .= '<rgp:rgpStatus s="pendingDelete">endDate=' . $d5d . '</rgp:rgpStatus>';
        }
    }

    if ( $rgp ) {
        $rgp = qq|<rgp:infData xmlns:rgp="urn:ietf:params:xml:ns:rgp-1.0">$rgp</rgp:infData>|;
    }

    return _ok_answ( $cltrid, $answ, $rgp );
}



sub domain_renew  {
    my ( $obj, $body ) = @_;

    my ( $subProduct ) = $body =~ m|<namestoreExt:subProduct>dot([A-Z]+)</namestoreExt:subProduct>|;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]*)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_schema2( q|Line: 8, Column: 21, Message: cvc-complex-type.2.4.a: Invalid content was found starting with element '{"urn:ietf:params:xml:ns:domain-1.0":names}'. One of '{"urn:ietf:params:xml:ns:domain-1.0":name}' is expected.| );
    }

    unless ( $dname ) {
        return _fail_schema2( q|Line: 8, Column: 34, Message: cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '1' for type 'labelType'.| );
    }

    unless ( $dname =~ /^[0-9a-z][0-9a-z\-]*[0-9a-z]\.[0-9a-z][0-9a-z\-]+[0-9a-z]$/ ) {
        return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
    }

    my ( $tld ) = $dname =~ /\.([0-9a-z\-]+)$/;

    if ( $tld ne lc( $subProduct )  ) {
        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value syntax error', 'Incorrect NameStore Extension' );
    }

    my $user_edt;
    if ( $body =~ m|<domain:curExpDate>(.+)</domain:curExpDate>| ) {
        $user_edt = $1;
    }
    else {
        return _fail_schema2( q|Line: 9, Column: 31, Message: cvc-complex-type.2.4.a: Invalid content was found starting with element '{"urn:ietf:params:xml:ns:domain-1.0":period}'. One of '{"urn:ietf:params:xml:ns:domain-1.0":curExpDate}' is expected.| );
    }

    my ( $yy, $mm, $dd );
    if ( $user_edt =~ /(\d{4})-(\d{2})-(\d{2})/ ) {
        ( $yy, $mm, $dd ) = ( $1, $2, $3 );
    }

    unless ( $yy  &&  $yy >= 1000  &&  $yy <= 9999  and  $mm  &&  $mm <= 13   and  $dd  &&  $dd  <=  31 ) {
        return _fail_schema2( qq|Line: 7, Column: 54, Message: cvc-datatype-valid.1.2.1: '$user_edt' is not a valid value for 'date'.| );
    }

    my $period;
    if ( $body =~ m|<domain:period unit="y">(\d+)</domain:period>| ) {
        $period = $1;
    }
    else {
        $period = 1;
    }

    if ( $period < 1  ||  $period > 10 ) {
        return _fail_answ( $cltrid, '2306', 'Parameter value policy error' );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    _check_dom_dates( $s, $dname );

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    my $dm = $s->data->{doms}{$dname};

    if ( $dm->{owner} ne $obj->{user} ) {
        return _fail_answ( $cltrid, '2201', 'Authorization error' );
    }

    if ( $dm->{statuses}{serverRenewProhibited}  or  $dm->{statuses}{clientRenewProhibited}  or  $dm->{statuses}{pendingDelete} ) {
        return _fail_answ( $cltrid, '2304', 'Object status prohibits operation' );
    }

    if ( $$dm{ren_date}  and  add_5d( $$dm{ren_date} ) gt get_date() ) {
        return _fail_answ( $cltrid, '2004', 'Domain in renewPeriod' );
    }

    my ( $edt ) = $dm->{exp_date} =~ /^(\d{4}-\d{2}-\d{2})/;

    if ( $user_edt ne $edt ) {
        return _fail_answ( $cltrid, '2004', 'Wrong curExpDate provided' );
    }

    my $now = get_date();

    my ( $y0 ) = $now =~ /^(\d{4})/;
    my ( $y1 ) = $dm->{exp_date} =~ /^(\d{4})/;

    if ( $y1 - $y0 + $period > 10 ) {
        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', 'Max RegistrationPeriod exceeded' );
    }

    $dm->{ren_date} = $now;
    $dm->{exp_date} = add_y( $dm->{exp_date}, $period );

    my $answ = qq|      <domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
|;
    $answ .= "        <domain:name>" . uc( $dname ) . "</domain:name>\n";
    $answ .= "        <domain:exDate>" . $dm->{exp_date} . "</domain:exDate>\n";
    $answ .= "      </domain:renData>\n";

    return _ok_answ2( $cltrid, $answ );
}


sub domain_update  {
    my ( $obj, $body ) = @_;

    my ( $subProduct ) = $body =~ m|<namestoreExt:subProduct>dot([A-Z]+)</namestoreExt:subProduct>|;

    my $rgp = '';
    if ( $body =~ m|<rgp:update[^>]+>\s*(.+)\s*</rgp:update>|s ) { $rgp = $1; }

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]*)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_schema2( q|Line: 8, Column: 21, Message: cvc-complex-type.2.4.a: Invalid content was found starting with element '{"urn:ietf:params:xml:ns:domain-1.0":names}'. One of '{"urn:ietf:params:xml:ns:domain-1.0":name}' is expected.| );
    }

    unless ( $dname ) {
        return _fail_schema2( q|Line: 8, Column: 34, Message: cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '1' for type 'labelType'.| );
    }

    unless ( $dname =~ /^[0-9a-z][0-9a-z\-]*[0-9a-z]\.[0-9a-z][0-9a-z\-]+[0-9a-z]$/ ) {
        return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
    }

    my ( $tld ) = $dname =~ /\.([0-9a-z\-]+)$/;

    if ( $tld ne lc( $subProduct )  ) {
        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value syntax error', 'Domainname is invalid' );
    }

    my %add;
    my %rem;
    my %chg;

    if ( $body =~ m|<domain:add>\s*(.+)\s*</domain:add>|s ) {
        my $add = $1;

        if ( $add =~ /domain:contact/ ) {
            return _fail_answ_with_reason( $cltrid, '2102', 'Unimplemented option', "Subproduct dot".$subProduct." does NOT support contacts." );
        }

        my @sts = $add =~ m|(<domain:status s="[^"]+"/>)|s;

        for my $row ( @sts ) {
            my ( $st, $reason );

            if ( $row =~ m|<domain:status s="([^"]+)"/>| ) {
                $st = $1;
                $reason = '+';
            }

            unless ( $statuses{$st} ) {
                return _fail_schema2( qq|Line: 8, Column: 52, Message: cvc-enumeration-valid: Value '$st' is not facet-valid with respect to enumeration '[clientDeleteProhibited, clientHold, clientRenewProhibited, clientTransferProhibited, clientUpdateProhibited, inactive, ok, pendingCreate, pendingDelete, pendingRenew, pendingTransfer, pendingUpdate, serverDeleteProhibited, serverHold, serverRenewProhibited, serverTransferProhibited, serverUpdateProhibited]'. It must be a value from the enumeration.| );
            }

            $add{statuses}{$st} = $reason;
        }

        undef @sts;

        @sts = $add =~ m|(<domain:status s="[^"]+">[^<>]*</domain:status>)|s;

        for my $row ( @sts ) {
            my ( $st, $reason );

            if ( $row =~ m|<domain:status s="([^"]+)">([^<>]*)</domain:status>| ) {
                $st = $1;
                $reason = $2 || '+';
            }

            unless ( $statuses{$st} ) {
                return _fail_schema2( qq|Line: 8, Column: 52, Message: cvc-enumeration-valid: Value '$st' is not facet-valid with respect to enumeration '[clientDeleteProhibited, clientHold, clientRenewProhibited, clientTransferProhibited, clientUpdateProhibited, inactive, ok, pendingCreate, pendingDelete, pendingRenew, pendingTransfer, pendingUpdate, serverDeleteProhibited, serverHold, serverRenewProhibited, serverTransferProhibited, serverUpdateProhibited]'. It must be a value from the enumeration.| );
            }

            $add{statuses}{$st} = $reason;
        }

        if ( $add =~ m|<domain:ns>(.+)</domain:ns>|s ) {
            my $nss = $1;

            my @nss = $nss =~ m|(<domain:hostObj>[^<>]*</domain:hostObj>)|s;

            my @hosts;
            for my $row ( @nss ) {
                if ( $row =~ m|<domain:hostObj>([^<>]+)</domain:hostObj>| ) {
                    push @hosts, lc $1;
                }
                else {
                    return _fail_schema2( q|Line: 9, Column: 40, Message: cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '1' for type 'labelType'.| )
                }
            }

            for my $ns ( @hosts ) {
                if ( $ns =~ /^[0-9a-z.\-]+$/ ) {
                    $add{nss}{$ns} = '+';
                }
                else {
                    return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
                }
            }
        }
    }

    if ( $body =~ m|<domain:rem>\s*(.+)\s*</domain:rem>|s ) {
        my $rem = $1;

        if ( $rem =~ /domain:contact/ ) {
            return _fail_answ_with_reason( $cltrid, '2102', 'Unimplemented option', "Subproduct dot".$subProduct." does NOT support contacts." );
        }

        my @sts = $rem =~ m|(<domain:status s="[^"]+"[^>]*>)|s;

        for my $row ( @sts ) {
            my $st;

            if ( $row =~ m|<domain:status s="([^"]+)"/?>| ) {
                $st = $1;
            }

            unless ( $statuses{$st} ) {
                return _fail_schema2( qq|Line: 9, Column: 52, Message: cvc-enumeration-valid: Value '$st' is not facet-valid with respect to enumeration '[clientDeleteProhibited, clientHold, clientRenewProhibited, clientTransferProhibited, clientUpdateProhibited, inactive, ok, pendingCreate, pendingDelete, pendingRenew, pendingTransfer, pendingUpdate, serverDeleteProhibited, serverHold, serverRenewProhibited, serverTransferProhibited, serverUpdateProhibited]'. It must be a value from the enumeration.| );
            }

            $rem{statuses}{$st} = '+';
        }

        if ( $rem =~ m|<domain:ns>(.+)</domain:ns>|s ) {
            my $nss = $1;

            my @nss = $nss =~ m|(<domain:hostObj>[^<>]*</domain:hostObj>)|s;

            my @hosts;
            for my $row ( @nss ) {
                if ( $row =~ m|<domain:hostObj>([^<>]+)</domain:hostObj>| ) {
                    push @hosts, lc $1;
                }
                else {
                    return _fail_schema2( q|Line: 9, Column: 40, Message: cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '1' for type 'labelType'.| )
                }
            }

            for my $ns ( @hosts ) {
                if ( $ns =~ /^[0-9a-z.\-]+$/ ) {
                    $rem{nss}{$ns} = '+';
                }
                else {
                    return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
                }
            }
        }
    }

    if ( $body =~ m|<domain:chg>\s*(.+)\s*</domain:chg>|s ) {
        my $chg = $1;

        if ( $chg =~ /domain:registrant/ ) {
            return _fail_answ_with_reason( $cltrid, '2102', 'Unimplemented option', "Subproduct dot".$subProduct." does NOT support contacts." );
        }

        if ( $chg =~ m|<domain:pw>([^<>]*)</domain:pw>|s ) {
            my $key = $1;

            unless ( $key  and  length( $key ) >= 16  and  length( $key ) <= 48 ) {
                return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', 'Invalid Auth Info' );
            }

            unless ( $key =~ /[a-z]/  and  $key =~ /[A-Z]/  and  $key =~ /[0-9]/  and  $key =~ /["'.,\-\[\]\\|\/!?\$\%\@*()+=_{}:;]/ ) {
                return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', 'Invalid Auth Info' );
            }

            $chg{authInfo} = $key;
        }
    }

    unless ( scalar( keys %add ) + scalar( keys %rem ) + scalar( keys %chg )  or  $rgp ) {
        return _fail_answ_with_reason( $cltrid, '2003', 'Required parameter missing', 'empty non-extended update is not allowed' );
    }

    my $s = new IO::EPP::Test::Server( $obj->{sock} );

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    _check_dom_dates( $s, $dname );

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    my $dom = $s->data->{doms}{$dname};
    my $nss = $s->data->{nss};

    if ( $dom->{owner} ne $obj->{user} ) {
        return _fail_answ( $cltrid, '2201', 'Authorization error' );
    }

    if ( $rgp ) {
        unless ( $rgp =~ /restore op="[a-z]+"/ ) {
            return _fail_schema2( q|Line: 17, Column: 33, Message: cvc-complex-type.2.4.a: Invalid content was found starting with element '{"urn:ietf:params:xml:ns:rgp-1.0":xxxxxx}'. One of '{"urn:ietf:params:xml:ns:rgp-1.0":restore}' is expected.| );
        }

        if ( $rgp =~ /restore op="request"/ ) {
            unless ( $dom->{statuses}{pendingDelete} ) {
                return _fail_answ( $cltrid, '2304', 'Object status prohibits operation' );
            }

            my $now = get_date();
            my $last_redem_date = add_5d( $dom->{del_date} );

            if ( $now gt $last_redem_date ) {
                return _fail_answ( $cltrid, '2304', 'Object status prohibits operation' );
            }

            $dom->{statuses}{pendingRestore} = '+';
            $dom->{upd_date} = get_date();

            return _min_answ( $cltrid );
        }

        if ( $rgp =~ /restore op="report"/ ) {
            unless ( $dom->{statuses}{pendingRestore} ) {
                return _fail_answ( $cltrid, '2304', 'Object status prohibits operation' );
            }

            delete $dom->{statuses}{pendingDelete};
            delete $dom->{statuses}{pendingRestore};

            for my $ns ( keys %{$dom->{nss}} ) {
                if ( $nss->{$ns} ) {
                    $nss->{$ns}{statuses}{linked}++;
                }
                else {
                    delete $dom->{nss}{$ns};
                }
            }

            return _min_answ( $cltrid );
        }

        return _fail_schema2( q|Line: 17, Column: 33, Message: cvc-enumeration-valid: Value 'xxxxxx' is not facet-valid with respect to enumeration '[request, report]'. It must be a value from the enumeration.| );
    }

    if ( $dom->{statuses}{serverUpdateProhibited}  or  $dom->{statuses}{clientUpdateProhibited}  and  not $rem{statuses}{clientUpdateProhibited} ) {
        return _fail_answ( $cltrid, '2304', 'Object status prohibits operation' );
    }

    foreach my $st ( keys %{$add{statuses}} ) {
        if ( $dom->{statuses}{$st} ) {
            return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$st status is already associated" );
        }
    }

    foreach my $st ( keys %{$rem{statuses}} ) {
        unless ( $dom->{statuses}{$st} ) {
            return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$st status not found" );
        }
    }

    foreach my $ns ( keys %{$add{nss}} ) {
        unless ( $nss->{$ns} ) {
            return _fail_answ_with_reason( $cltrid, '2303', 'Object does not exist', "host $ns not found." );
        }

        if ( $dom->{nss}{$ns} ) {
            return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$ns ns is already linked" );
        }
    }

    foreach my $ns ( keys %{$rem{nss}} ) {
        unless ( $dom->{nss}{$ns} ) {
            return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value policy error', "$ns ns not found" );
        }
    }

    # order not change!
    $dom->{statuses}{$_} = $add{statuses}{$_} foreach keys %{$add{statuses}};

    delete $dom->{statuses}{$_} foreach keys %{$rem{statuses}};

    if ( $dom->{statuses}{ok}  and  scalar( %{$dom->{statuses}} ) > 1 ) {
        delete $dom->{statuses}{ok};
    }

    unless ( scalar( %{$dom->{statuses}} ) ) {
        $dom->{statuses}{ok} = '+';
    }

    foreach my $ns ( keys %{$add{nss}} ) {
        $dom->{nss}{$ns} = '+';

        $nss->{$ns}{statuses}{linked}++;
    }

    foreach my $ns ( keys %{$rem{nss}} ) {
        delete $dom->{nss}{$ns};

        $nss->{$ns}{statuses}{linked}--;

        delete $nss->{$ns}{statuses}{linked} if $nss->{$ns}{statuses}{linked} == 0;
    }

    $dom->{authInfo} = $chg{authInfo} if $chg{authInfo};

    $dom->{upd_date} = get_date();
    $dom->{updater}  = $obj->{user};

    return _min_answ( $cltrid );
}


sub domain_delete {
    my ( $obj, $body ) = @_;

    my ( $subProduct ) = $body =~ m|<namestoreExt:subProduct>dot([A-Z]+)</namestoreExt:subProduct>|;

    my @chb = _check_body( \$body );

    my $cltrid;

    if ( $chb[0] ) {
        return @chb;
    }
    else {
        $cltrid = $chb[1];
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]*)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_schema2( q|Line: 8, Column: 21, Message: cvc-complex-type.2.4.a: Invalid content was found starting with element '{"urn:ietf:params:xml:ns:domain-1.0":names}'. One of '{"urn:ietf:params:xml:ns:domain-1.0":name}' is expected.| );
    }

    unless ( $dname ) {
        return _fail_schema2( q|Line: 8, Column: 34, Message: cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '1' for type 'labelType'.| );
    }

    unless ( $dname =~ /^[0-9a-z][0-9a-z\-]*[0-9a-z]\.[0-9a-z][0-9a-z\-]+[0-9a-z]$/ ) {
        return _fail_answ( $cltrid, '2005', 'Parameter value syntax error' );
    }

    my ( $tld ) = $dname =~ /\.([0-9a-z\-]+)$/;

    if ( $tld ne lc( $subProduct )  ) {
        return _fail_answ_with_reason( $cltrid, '2306', 'Parameter value syntax error', 'Domainname is invalid' );
    }

    my $s = new IO::EPP::Test::Server( $obj->{sock} );

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    _check_dom_dates( $s, $dname );

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_answ( $cltrid, '2303', 'Object does not exist' );
    }

    my $dom = $s->data->{doms}{$dname};
    my $nss = $s->data->{nss};

    if ( $dom->{owner} ne $obj->{user} ) {
        return _fail_answ( $cltrid, '2201', 'Authorization error' );
    }

    if ( $dom->{hosts} ) {

        for my $h ( keys %{$dom->{hosts}} ) {

            if ( $nss->{$h}{statuses}{linked} ) {
                return _fail_answ_with_reason( $cltrid, '2305', 'Object association prohibits operation', 'domain has an active child host' );
            }
        }
    }

    if ( $dom->{statuses}{serverUpdateProhibited}  or  $dom->{statuses}{clientUpdateProhibited}  or  $dom->{statuses}{serverDeleteProhibited}  or  $dom->{statuses}{clientDeleteProhibited}  or  $dom->{statuses}{pendingDelete} ) {
        return _fail_answ( $cltrid, '2304', 'Object status prohibits operation' );
    }

    for my $ns ( keys %{$dom->{hosts}} ) {
        if ( $nss->{$ns}{statuses}{linked} ) {
            $nss->{$ns}{statuses}{linked}--;

            if ( $nss->{$ns}{statuses}{linked} == 0 ) {
                delete $nss->{$ns}{statuses}{linked};
            }
        }
    }

    $dom->{statuses}{pendingDelete} = '+';
    $dom->{del_date} = $dom->{upd_date} = get_date();
    $dom->{updater}  = $obj->{user};

    return _min_answ( $cltrid );
}


sub logout {
    my ( $body ) = @_;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_schema( q|Line....: 1
Column..: 2
Message.: : The markup in the document preceding the root element must be well-formed.| );
    }

    unless ( $body =~ s|^<epp xmlns="[^"]+" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_schema( q|Line....: 2
Column..: 173
Message.: : cvc-complex-type.3.2.2: Attribute 'xxx' is not allowed to appear in element 'epp'.| );
    }

    unless ( $body =~ s|\s*</epp>\s*||s ) {
        return _fail_schema( q|Line....: 11111
Column..: 6
Message.: : The end-tag for element type "epp" must end with a '&gt;' delimiter.| );
    }

    unless ( $body =~ s|<command>\s*||s ) {
        return _fail_schema( q|Line....: 3
Column..: 12
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'xxxxxx'. One of '{"urn:ietf:params:xml:ns:epp-1.0":greeting, "urn:ietf:params:xml:ns:epp-1.0":hello, "urn:ietf:params:xml:ns:epp-1.0":command, "urn:ietf:params:xml:ns:epp-1.0":response, "urn:ietf:params:xml:ns:epp-1.0":extension}' is expected.| );
    }

    unless ( $body =~ s|\s*</command>||s ) {
        return _fail_schema( q|Line....: 22222
Column..: 11
Message.: : The end-tag for element type "command" must end with a '&gt;' delimiter.| );
    }

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|;

    unless ( $cltrid ) {
        return _fail_schema( q|Line....: 11111
Column..: 22222
Message.: : cvc-minLength-valid: Value '' with length = '0' is not facet-valid with respect to minLength '3' for type 'trIDStringType'.| );
    }

    unless ( $body =~ s|<logout/>\s*||s ) {
        return _fail_schema( q|Line....: 4
Column..: 13
Message.: : cvc-complex-type.2.4.a: Invalid content was found starting with element 'xxxxxx'. One of '{"urn:ietf:params:xml:ns:epp-1.0":check, "urn:ietf:params:xml:ns:epp-1.0":create, "urn:ietf:params:xml:ns:epp-1.0":delete, "urn:ietf:params:xml:ns:epp-1.0":info, "urn:ietf:params:xml:ns:epp-1.0":login, "urn:ietf:params:xml:ns:epp-1.0":logout, "urn:ietf:params:xml:ns:epp-1.0":poll, "urn:ietf:params:xml:ns:epp-1.0":renew, "urn:ietf:params:xml:ns:epp-1.0":transfer, "urn:ietf:params:xml:ns:epp-1.0":update}' is expected.| );
    }

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8"?><epp xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1500"><msg>Command completed successfully; ending session</msg></result><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}

1;
