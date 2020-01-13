package IO::EPP::Test::Base;

=encoding utf8

=head1 NAME

IO::EPP::Test::Base

=head1 SYNOPSIS

Call IO::EPP::Base with parameter "test_mode=1"

=head1 DESCRIPTION

Module for testing IO::EPP::CNic,
emulates answers of base registry

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use Digest::MD5 qw(md5_hex);

use IO::EPP::Base ();
use IO::EPP::Test::Server;

use strict;
use warnings;

no utf8; # !!!

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

sub req {
    my ( $obj, $out_data, undef ) = @_;

    my $in_data;

    if ( !$out_data  or  $out_data =~ m|<hello[^<>]+/>| ) {
        $in_data = hello( $out_data );
    }
    elsif ( $out_data =~ m|<login>|s ) {
        $in_data = login( $out_data );
    }
    elsif ( $out_data =~ m|<contact:check[^<>]+>| ) {
        $in_data = contact_check( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<contact:create[^<>]+>| ) {
        $in_data = contact_create_update( $obj, $out_data, 'create' );
    }
    elsif ( $out_data =~ m|<contact:update[^<>]+>| ) {
        $in_data = contact_create_update( $obj, $out_data, 'update' );
    }
    elsif ( $out_data =~ m|<contact:info[^<>]+>| ) {
        $in_data = contact_info( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<contact:delete[^<>]+>| ) {
        $in_data = contact_delete( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<host:check[^<>]+>| ) {
        $in_data = host_check( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<host:create[^<>]+>| ) {
        $in_data = host_create( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<host:info[^<>]+>| ) {
        $in_data = host_info( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<host:update[^<>]+>| ) {
        $in_data = host_update( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<host:delete[^<>]+>| ) {
        $in_data = host_delete( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<domain:check[^<>]+>| ) {
        $in_data = domain_check( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<domain:create[^<>]+>| ) {
        $in_data = domain_create( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<domain:info[^<>]+>| ) {
        $in_data = domain_info( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<domain:renew[^<>]+>| ) {
        $in_data = domain_renew( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<domain:update[^<>]+>| ) {
        $in_data = domain_update( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<domain:delete[^<>]+>| ) {
        $in_data = domain_delete( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<domain:transfer[^<>]+>| ) {
        $in_data = domain_transfer( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<poll [^<>]+>| ) {
        $in_data = poll( $obj, $out_data );
    }
    elsif ( $out_data =~ m|<logout/>| ) {
        $in_data = logout( $out_data );
    }
    else {
        die "closed connection\n"; # behavior centralnic
    }

    return $in_data;
}


sub get_svtrid {
    return 'TEST-' . uc( md5_hex( time() . $$ . rand(1000000) ) ); # as CNIC-7E024512B06F1FC202C6E625DE12C69984799AA81D578111813DFF29646
}


sub get_dates {
    my ( $y ) = @_;
    $y ||= 0;
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);

    $year += 1900;
    $mon  += 1;
    my $year2 = $year + $y;

    my $dt1 = sprintf( '%0004d-%02d-%02dT%02d:%02d:%02d.0Z', $year,  $mon, $mday, $hour, $min, $sec );
    my $dt2 = sprintf( '%0004d-%02d-%02dT23:59:59.0Z', $year2, $mon, $mday );

    return $dt1, $dt2;
}


sub hello {
    my ( $dt ) = get_dates();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><greeting><svID>EXAMPLE EPP server EPP.EXAMPLE.COM</svID><svDate>$dt</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:rgp-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>urn:ietf:params:xml:ns:idn-1.0</extURI></svcExtension></svcMenu><dcp><access><all></all></access><statement><purpose><admin></admin><prov></prov></purpose><recipient><ours></ours><public></public></recipient><retention><stated></stated></retention></statement></dcp></greeting></epp>|;
}

sub _fail_cltrid {
    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="2001">
<msg>XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:epp-1.0}clTRID&#039;: The value has a length of &#039;0&#039;;</msg>
</result>
<trID>
<clTRID>xxxx</clTRID>
<svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|;
}

sub _fail_body {
    my ( $err, $code, $cl ) = @_;
    my $svtrid = get_svtrid();
    $cl ||= 'xxxx';

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="$code">
<msg>$err</msg>
</result>
<trID>
<clTRID>$cl</clTRID>
<svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|;
}

sub _ok_answ {
    my ( $res, $cl ) = @_;

    my $svtrid = get_svtrid();

    $cl ||= 'xxxx';

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Command completed successfully.</msg></result><resData>$res</resData><trID><clTRID>$cl</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}

sub _min_answ {
    my ( $code, $cl ) = @_;

    my $svtrid = get_svtrid();

    $cl ||= 'xxxx';

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="$code"><msg>Command completed successfully.</msg></result><trID><clTRID>$cl</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}

sub login {
    my ( $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="[^"]+" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    my $body2;
    if ( $body =~ m|<command>\s*<login>\s*(.+?)</login>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>|s ) {
        $body2 = $1;
    }
    else {
        die "closed connection\n"; # behavior centralnic
    }

    my ( $login ) = $body =~ m|<clID>([0-9A-Za-z_\-]+)</clID>|;

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="2400">
<msg>Cannot authenticate $login: not found in database.</msg>
</result>
<trID>
<clTRID>$cltrid</clTRID>
<svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|
        unless $login;

    my ( $pass ) = $body =~ m|<pw>([0-9A-Za-z!\@\$\%*_.:=+?#,"'\-{}\[\]\(\)]+)</pw>|;

    if ( !$pass  ||  length( $pass ) < 6 ) {
        return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="2001">
<msg>XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:epp-1.0}pw&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;6&#039;.</msg>
</result>
<trID>
<clTRID>$cltrid</clTRID>
<svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|;
    }

    if ( $pass eq 'fail-pass' ) {
        return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="2200">
<msg>Invalid password</msg>
</result>
<trID>
<clTRID>$cltrid</clTRID>
<svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|;
    }

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1000"><msg>Welcome user.</msg></result><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}


sub contact_check {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<check>\s+<contact:check[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: contact:check', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</contact:check>\s+</check>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /contact:check', '2001', $cltrid );
    }

    my ( @contacts ) = $body =~ m|(<contact:id>[^<>]+</contact:id>)|g;

    unless ( scalar @contacts ) {
        return _fail_body( 'XML schema validation failed: contact:cd' );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $answ_list = '';
    foreach my $row ( @contacts ) {
        my ( $cont_id ) = $row =~ m|<contact:id>([^<>]+)</contact:id>|;

        my $reason = '';
        if ( $s->data->{conts}{$cont_id} ) {
            $reason = $s->data->{conts}{$cont_id}{reason};
        }

        my $avail = $reason ? 0 : 1;

        $reason = "<contact:reason>$reason</contact:reason>" if $reason;

        $answ_list .= qq|<contact:id avail="$avail">$cont_id</contact:id>$reason</contact:cd>|;
    }

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="1000">
<msg>Command completed successfully.</msg>
</result>
<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0">$answ_list</contact:chkData></resData><trID>
<clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|;
}


sub contact_create_update {
    my ( $obj, $body, $act ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<$act>\s+<contact:$act[^<>]+>\s+||s ) {
        return _fail_body( "XML schema validation failed: contact:$act", '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</contact:$act>\s+</$act>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( "XML schema validation failed: /contact:$act", '2001', $cltrid );
    }

    my $i = () = $body =~ /<postalInfo type="int">/g;

    if ( $i > 1 ) {
        # text from verisign NameStore server
        _fail_body( 'Parameter value policy error, Only one int postal address information allowed', '2306', $cltrid );
    }

    my $l = () = $body =~ /<postalInfo type="loc">/g;

    if ( $l > 1 ) {
        _fail_body( 'Parameter value policy error, Only one loc postal address information allowed', '2306', $cltrid );
    }

    if ( $i+$l == 0 ) {
        _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}voice&#039;: This element is not expected. Expected is ( {urn:ietf:params:xml:ns:contact-1.0}postalInfo ).', '2001', $cltrid );
    }

    my %cont;
    if ( $body =~ m|<contact:id>([^<>]+)</contact:id>| ) {
        $cont{id} = $1;
    }
    else {
        return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}$act&#039;: Missing child element(s). Expected is one of ( {urn:ietf:params:xml:ns:contact-1.0}id, {urn:ietf:params:xml:ns:contact-1.0}ext ).", '2001', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    my $top;
    if ( $act eq 'create' ) {
        if ( $s->data->{conts}{$cont{id}} ) {
            if ( $s->data->{conts}{$cont{id}}{reason} eq 'in use' ) {
                return _fail_body( "Contact object &#039;$cont{id}&#039; already exists.", '2302', $cltrid );
            }
            else {
                return _fail_body( "Contact object &#039;$cont{id}&#039; $s->data->{conts}{$cont{id}}{reason}.", '2302', $cltrid );
            }
        }

        $top = 'create';
    }
    elsif ( $act eq 'update' ) {
        unless ( $s->data->{conts}{$cont{id}}  and  $s->data->{conts}{$cont{id}}{reason} eq 'in use' ) {
            # contact does not exist, the reason does not
            return _fail_body( 'Cannot find that object.', '2303', $cltrid );
        }

        $top = 'chg';
    }

    for my $t ( 'int', 'loc' ) {
        if ( $body =~ m|<contact:postalInfo type="$t">(.+?)</contact:postalInfo>|s ) {
            $cont{$t} = $1;
        }
    }


    for my $t ( 'int', 'loc' ) {
        my $pi = delete $cont{$t};
        next unless $pi;

        $cont{$t} = {};
        foreach my $f ( 'name', 'org', 'addr' ) {
            if ( $pi =~ m|<contact:$f>(.+?)</contact:$f>|s ) {
                $cont{$t}{$f} = $1;
            }
            elsif ( $pi =~ m|<contact:$f/>| ) {
                if ( $f eq 'org' ) {
                    # $cont{$t}{$f} = undef;
                }
                else {
                    return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}$f&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.", '2001', $cltrid );
                }
            }
            else {
                if ( $f eq 'name'  &&  $act eq 'create' ) {
                    return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}postalInfo&#039;: Missing child element(s). Expected is one of ( {urn:ietf:params:xml:ns:contact-1.0}$f, {urn:ietf:params:xml:ns:contact-1.0}ext ).", '2001', $cltrid );
                }
            }
        }

        my $addr = delete $cont{$t}{addr};
        $cont{$t}{addr} = {};

        my @street = $addr =~ m|(<contact:street>[^<>]+</contact:street>)|g;
        unless ( scalar @street ) {
            return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}addr&#039;: Missing child element(s). Expected is one of ( {urn:ietf:params:xml:ns:contact-1.0}street, {urn:ietf:params:xml:ns:contact-1.0}ext ).", '2001', $cltrid );
        }
        $cont{$t}{addr}{street} = [];
        foreach my $row ( @street ) {
            if ( $row =~ m|<contact:street>([^<>]+)</contact:street>| ) {
                push @{$cont{$t}{addr}{street}}, $1;
            }
        }

        foreach my $f ( 'city', 'sp', 'pc' , 'cc' ) {
            if ( $pi =~ m|<contact:$f>(.+?)</contact:$f>|s ) {
                $cont{$t}{addr}{$f} = $1;
            }
            elsif ( $pi =~ m|<contact:$f/>| ) {
                if ( $f eq 'sp' ) {
                    # $cont{$t}{addr}{$f} = undef;
                }
                else {
                    return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}$f&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.", '2001', $cltrid );
                }
            }
            else {
                return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}addr&#039;: Missing child element(s). Expected is one of ( {urn:ietf:params:xml:ns:contact-1.0}$f, {urn:ietf:params:xml:ns:contact-1.0}ext ).", '2001', $cltrid );
            }
        }

        unless ( $cont{$t}{addr}{cc}  &&  length( $cont{$t}{addr}{cc} ) == 2 ) {
            return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}cc&#039;: [facet &#039;length&#039;] The value has a length of &#039;4&#039;; this differs from the allowed length of &#039;2&#039;.', '2001', $cltrid );
        }

        if ( $cont{$t}{addr}{cc} !~ /^[A-Z]+$/ ) {
            return _fail_body( "The country code &#039;$cont{$t}{addr}{cc}&#039; is not known to us", '2004', $cltrid );
        }
    }

    foreach my $f ( 'voice', 'fax', 'email' ) {
        if ( $body =~ /<contact:$f>/ ) {
            my @cfs = $body =~ m|(<contact:$f>[^<>]*</contact:$f>)|g; # contact fields

            $cont{$f} = [];
            foreach my $cf ( @cfs ) {
                if ( $cf =~ m|<contact:$f>([^<>]*)</contact:$f>| ) {
                    my $c = $1;

                    if ( length( $c ) == 0 ) {
                        return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}$f&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.", '2001', $cltrid );
                    }
                    elsif ( $f eq 'fax'  ||  $f eq 'voice'  and  $c !~ /^\+\d{1,3}\.\d{1,14}$/ ) {
                        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}voice&#039;: [facet &#039;pattern&#039;] The value &#039;A380954272445&#039; is not accepted by the pattern &#039;(\\+[0-9]{1,3}\\.[0-9]{1,14})?&#039;.', '2001', $cltrid );
                    }
                    elsif ( $f eq 'email'  and  $c !~  /^[0-9a-z\.\-]+\@[0-9a-z\.\-]+$/ ) {
                        return _fail_body( 'E-mail address is invalid or missing', '2004', $cltrid );
                    }
                    else {
                        push @{$cont{$f}}, $c;
                    }
                }
            }
        }
        elsif ( $f eq 'fax'  and  $body =~ m|<contact:$f/>|  ) {
            $cont{$f} = [];
        }
        else {
            return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}$top&#039;: Missing child element(s). Expected is one of ( {urn:ietf:params:xml:ns:contact-1.0}$f, {urn:ietf:params:xml:ns:contact-1.0}ext ).", '2001', $cltrid );
        }
    }

    if ( $body =~ m|<contact:authInfo>\s*<contact:pw>([^<>]+)</contact:pw>\s*</contact:authInfo>|s ) {
        $cont{authInfo} = $1;
    }
    elsif ( $body =~ m|<contact:authInfo>\s*<contact:pw/>\s*</contact:authInfo>| ) {
        $cont{authInfo} = '';
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}authInfo&#039;: Missing child element(s). Expected is one of ( {urn:ietf:params:xml:ns:contact-1.0}pw, {urn:ietf:params:xml:ns:contact-1.0}ext ).', '2001', $cltrid );
    }
    if ( $cont{authInfo}  and  length( $cont{authInfo} ) < 16 ) {
        return _fail_body( 'authInfo code is invalid: password must be at least 16 characters', '2004', $cltrid );
    }
    unless ( $cont{authInfo}  and   $cont{authInfo} =~ /[A-Z]/  and  $cont{authInfo} =~ /[a-z]/  and  $cont{authInfo} =~ /[0-9]/  and  $cont{authInfo} =~ /[!\@\$\%*_.:\-=+?#,"'\\\/&]/ ) {
        return _fail_body( 'authInfo code is invalid: password must contain a mix of uppercase and lowercase characters', '2004', $cltrid );
    }

    # TODO: update statuses

    if ( $act eq 'create' ) {
        my ( $cre_date ) = get_dates();

        $s->data->{conts}{$cont{id}} = { %cont, reason => 'in use', statuses => { 'ok' => '+' }, owner => $obj->{user}, creater => $obj->{user}, updater => $obj->{user}, cre_date => $cre_date, upd_date => $cre_date, roid => uc(md5_hex($cont{id}.$cre_date)) . '-TEST' };

        return _ok_answ( qq|<contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>$cont{id}</contact:id><contact:crDate>$cre_date</contact:crDate></contact:creData>|, $cltrid );
    }
    else { # update
        my $old = $s->data->{conts}{$cont{id}};

        if ( $old->{owner} ne $obj->{user} ) {
            # TODO: check main domain
            return _fail_body( 'You are not authorised to modify this contact object (you do not sponsor the parent domain).', '2201', $cltrid );
        }

        my ( $upd_date ) = get_dates();

        foreach my $f ( 'voice','fax','email','authInfo' ) {
            $old->{$f} = $cont{$f};
        }

        for my $t ( 'int', 'loc' ) {
            if ( $cont{$t} ) {
                $old->{$t}{name} = $cont{$t}{name} if $cont{$t}{name};
                if ( $cont{$t}{org} ) {
                    $old->{$t}{org} = $cont{$t}{org}
                }
                else {
                    delete $old->{$t}{org};
                }
                $old->{$t}{addr} = $cont{$t}{addr};
            }
            else {
                delete $old->{$t};
            }
        }

        $old->{upd_date} = $upd_date;
        $old->{updater} = $obj->{user};

        my $svtrid = get_svtrid();

        return _min_answ( '1000', $cltrid );
    }
}


sub contact_info {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<info>\s+<contact:info[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: contact:info', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</contact:info>\s+</info>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /contact:info', '2001', $cltrid );
    }

    my $id;
    if ( $body =~ m|<contact:id>([^<>]+)</contact:id>| ) {
        $id = $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}id&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;1&#039;; this underruns the allowed minimum length of &#039;3&#039;.', '2001', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    unless ( $s->data->{conts}{$id} ) {
        return _fail_body( "Cannot find an object with an ID of $id.", '2303', $cltrid );
    }

    my %cont = %{$s->data->{conts}{$id}};

    my $answ = '<contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"><contact:id>' .
        $id . '</contact:id><contact:roid>' . $cont{roid} . '</contact:roid>';

    foreach my $s ( keys %{ $cont{statuses} } ) {
        if ( $cont{statuses}{$s} eq '+' ) {
            $answ .= qq|<contact:status s="$s" />|;
        }
        else {
            $answ .= qq|<contact:status s="$s">| . $cont{statuses}{$s} . '<contact:status>';
        }
    }

    for my $t ( 'int', 'loc' ) {
        if ( $cont{$t} ) {
            $answ .= qq|<contact:postalInfo type="$t"><contact:name>|.$cont{$t}{name}.'</contact:name>';
            $answ .= $cont{$t}{org} ? qq|<contact:org>$cont{$t}{org}</contact:org>| : '<contact:org/>' ;
            $answ .= '<contact:addr>';
            $answ .= qq|<contact:street>$_</contact:street>| for @{$cont{$t}{addr}{street}};
            $answ .= qq|<contact:city>$cont{$t}{addr}{city}</contact:city>|;
            $answ .= $cont{$t}{addr}{sp} ? qq|<contact:sp>$cont{$t}{addr}{sp}</contact:sp>| : '<contact:sp/>';
            $answ .= $cont{$t}{addr}{sp} ? qq|<contact:pc>$cont{$t}{addr}{sp}</contact:pc>| : '<contact:pc/>';
            $answ .= $cont{$t}{addr}{cc} ? qq|<contact:cc>$cont{$t}{addr}{cc}</contact:cc>| : '<contact:cc/>';
            $answ .= '</contact:addr>';
            $answ .= '</contact:postalInfo>';
        }
    }
    foreach my $v ( @{$cont{voice}} ) {
        $answ .= "<contact:voice>$v</contact:voice>";
    }
    if ( scalar @{$cont{fax}} ) {
        foreach my $f ( @{$cont{fax}} ) {
            $answ .= "<contact:fax>$f</contact:fax>";
        }
    }
    else {
        $answ .= '<contact:fax/>';
    }
    foreach my $e ( @{$cont{email}} ) {
        $answ .= "<contact:email>$e</contact:email>";
    }
    $answ .= "<contact:clID>$cont{owner}</contact:clID>";
    $answ .= "<contact:crID>$cont{creater}</contact:crID>";
    $answ .= "<contact:crDate>$cont{cre_date}</contact:crDate>";
    $answ .= "<contact:upID>$cont{updater}</contact:upID>" if $cont{updater};
    $answ .= "<contact:upDate>$cont{upd_date}</contact:upDate>";

    $answ .= qq|<contact:disclose flag="1"><contact:voice/><contact:email/></contact:disclose></contact:infData>|;

    return _ok_answ( $answ, $cltrid );
}


sub contact_delete {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<delete>\s+<contact:delete[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: contact:info', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</contact:delete>\s+</delete>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /contact:delete', '2001', $cltrid );
    }

    my $id;
    if ( $body =~ m|<contact:id>([^<>]+)</contact:id>| ) {
        $id = $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:contact-1.0}id&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;1&#039;; this underruns the allowed minimum length of &#039;3&#039;.', '2001', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );

    unless ( $s->data->{conts}{$id} ) {
        return _fail_body( "Contact object cannot be found.", '2303', $cltrid );
    }

    if ( $s->data->{conts}{$id}{statuses}{linked} ) {
        return _fail_body( 'Contact object is linked to one or more domains.', '2305', $cltrid );
    }

    if ( $s->data->{conts}{$id}{owner} ne $obj->{user} ) {
        return _fail_body( 'Permission denied.', '2201', $cltrid );
    }

    delete $s->data->{conts}->{$id};

    my $svtrid = get_svtrid();

    return _min_answ( '1000', $cltrid );
}


sub host_check {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<check>\s+<host:check[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: host:check', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</host:check>\s+</check>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /host:check', '2001', $cltrid );
    }

    my ( @hosts ) = $body =~ m|(<host:name>[^<>]+</host:name>)|g;

    unless ( scalar @hosts ) {
        return _fail_body( 'XML schema validation failed: host:cd', '2001', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $answ_list = '';
    foreach my $row ( @hosts ) {
        my ( $ns ) = $row =~ m|<host:name>([^<>]+)</host:name>|;
        $ns = lc $ns;

        my $reason = '';

        if ( $s->data->{nss}{$ns} ) {
            $reason = $s->data->{nss}{$ns}{reason} || '';
        }
        elsif ( $ns !~ /^[0-9a-z\.\-]+$/ ) {
            my ( $c ) = $ns !~ /([^0-9a-z\.\-])/;
            $reason = 'the following characters are not permitted: &#039;'.$c.'&#039;';
        }

        my $avail = $reason ? 0 : 1;

        $reason = "<host:reason>$reason</host:reason>" if $reason;

        $answ_list .= qq|<host:cd><host:name avail="$avail">$ns</host:name>$reason</host:cd>|;
    }

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="1000">
<msg>Command completed successfully.</msg>
</result>
<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0">$answ_list</host:chkData></resData><trID>
<clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|;
}


sub host_create {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<create>\s+<host:create[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: host:create', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</host:create>\s+</create>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /host:create', '2001', $cltrid );
    }

    my ( $ns, $local_ns );
    if ( $body =~ m|<host:name>([0-9A-Za-z\-\.]+)</host:name>| ) {
        $ns = lc $1;
    }
    else {
        return _fail_body( 'Host name is invalid.', '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $nss = $s->data->{nss};
    my $doms = $s->data->{doms};

    if ( $nss->{$ns} ) {
        return _fail_body( 'A host object with that hostname already exists.', '2302', $cltrid );
    }

    my @v4 = $body =~ m|<host:addr ip="v4">([^<>]+)</host:addr>|g;
    my @v6 = $body =~ m|<host:addr ip="v6">([^<>]+)</host:addr>|g;

    foreach my $dm ( keys %{$doms} ) {
        if ( $ns =~ /\.$dm$/ ) {
            if ( $doms->{$dm}{owner} ne $obj->{user} ) {
                return _fail_body( 'You are not the sponsor for the parent domain of this host and cannot create subordinate host objects for it.', '2201', $cltrid );
            }
            elsif ( ( scalar( @v4 ) + scalar( @v6 ) ) == 0 ) {
                return _fail_body( 'You need IPv4 or IPv6 address.', '2004', $cltrid );
            }

            $local_ns = $dm;
        }
    }

    foreach my $v ( @v4 ) {
        unless ( $v =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
            return _fail_body( "IP address $v is not valid.", '2004', $cltrid );
        }
    }
    foreach my $v ( @v6 ) {
        unless ( $v =~ /^[0-9a-z:]{1,29}$/ ) {
            return _fail_body( "IP address $v is not valid.", '2004', $cltrid );
        }
    }

    my ( $cre_date ) = get_dates();

    $nss->{$ns} = { avail => 0, reason => 'in use', statuses => { ok => '+' }, creater => $obj->{user}, owner => $obj->{user}, cre_date => $cre_date, addr_v4 => \@v4, addr_v6 => \@v6, roid => uc(md5_hex($ns.$cre_date)) . '-TEST' };

    if ( $local_ns ) {
        $doms->{$local_ns}{hosts}{$ns} = '+';
    }

    return _ok_answ( qq|<host:creData xmlns:host="urn:ietf:params:xml:ns:host-1.0"><host:name>$ns</host:name><host:crDate>$cre_date</host:crDate></host:creData>|, $cltrid );
}


sub host_info {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<info>\s+<host:info[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: host:info', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</host:info>\s+</info>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /host:info', '2001', $cltrid );
    }

    my $ns;
    if ( $body =~ m|<host:name>([0-9A-Za-z\-\.]+)</host:name>| ) {
        $ns = lc $1;
    }
    else {
        return _fail_body( 'Host name is invalid.', '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $nss = $s->data->{nss};

    unless ( $nss->{$ns} ) {
        return _fail_body( "The host &#039;$ns&#039; does not exist", '2303', $cltrid );
    }

    my $answ = '<host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0">';
    $answ   .= "<host:name>$ns</host:name>";
    $answ   .= "<host:roid>$$nss{$ns}{roid}</host:roid>";
    foreach my $st ( keys %{$$nss{$ns}{statuses}} ) {
        if ( $$nss{$ns}{statuses}{$st} eq '+' ) {
            $answ .= qq|<host:status s="$st" />|;
        }
        else {
            $answ .= qq|<host:status s="$st">| . $$nss{$ns}{statuses}{$st} . '</host:status>';
        }
    }
    foreach my $v ( @{$$nss{$ns}{addr_v4}} ) {
        $answ .= qq|<host:addr ip="v4">$v</host:addr>|;
    }
    foreach my $v ( @{$$nss{$ns}{addr_v6}} ) {
        $answ .= qq|<host:addr ip="v6">$v</host:addr>|;
    }
    $answ   .= "<host:clID>$$nss{$ns}{owner}</host:clID>";
    $answ   .= "<host:crID>$$nss{$ns}{creater}</host:crID>";
    $answ   .= "<host:crDate>$$nss{$ns}{cre_date}</host:crDate>";
    $answ   .= "<host:crDate>$$nss{$ns}{upd_date}</host:crDate>" if $$nss{$ns}{upd_date};
    $answ   .= '</host:infData>';

    return _ok_answ( $answ, $cltrid );
}


sub host_update {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<update>\s+<host:update[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: host:update', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</host:update>\s+</update>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /host:update', '2001', $cltrid );
    }

    my ( $ns, $local_ns );
    if ( $body =~ m|<host:name>([0-9A-Za-z\-\.]+)</host:name>| ) {
        $ns = lc $1;
    }
    else {
        return _fail_body( 'Host name is invalid.', '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $nss = $s->data->{nss};

    unless ( $nss->{$ns} ) {
        return _fail_body( "The host &#039;$ns&#039; does not exist", '2303', $cltrid );
    }

    if ( $nss->{$ns}{owner} ne $obj->{user} ) {
        # TODO: check main domain
        return _fail_body( 'You are not authorised to modify this host object (you do not sponsor the parent domain).', '2201', $cltrid );
    }

    my ( @a4, @a6, @d4, @d6, @ast, @dst );

    for my $act ( 'add', 'rem' ) {
        if ( $body =~ m|<host:$act>(.+?)</host:$act>|s ) {
            my $ab = $1;

            my @v4 = $ab =~ m|<host:addr ip="v4">([^<>]+)</host:addr>|g;
            my @v6 = $ab =~ m|<host:addr ip="v6">([^<>]+)</host:addr>|g;

            foreach my $v ( @v4 ) {
                unless ( $v =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                    return _fail_body( "IP address $v is not valid.", '2004', $cltrid );
                }

                if ( $act eq 'add' ) { push @a4, $v } else { push @d4, $v }
            }

            foreach my $v ( @v6 ) {
                unless ( $v =~ /^[0-9a-f:]{1,29}$/ ) {
                    return _fail_body( "IP address $v is not valid.", '2004', $cltrid );
                }

                if ( $act eq 'add' ) { push @a6, $v } else { push @d6, $v }
            }

            # Centralnic ignored add/rem client* statuses for host
        }
    }

    # TODO: chg name

    if ( scalar @a4 ) {
        my %h = map { $_ => '+' } @{$nss->{$ns}{addr_v4}};

        $h{$_} = '+' for @a4;

        $nss->{$ns}{addr_v4} = [ sort keys %h ];
    }

    if ( scalar @a6 ) {
        my %h = map { $_ => '+' } @{$nss->{$ns}{addr_v6}};

        $h{$_} = '+' for @a6;

        $nss->{$ns}{addr_v6} = [ sort keys %h ];
    }

    if ( scalar @d4 ) {
        my %h = map { $_ => '+' } @{$nss->{$ns}{addr_v4}};

        delete( $h{$_} ) for @d4;

        $nss->{$ns}{addr_v4} = [ sort keys %h ];
    }

    if ( scalar @d6 ) {
        my %h = map { $_ => '+' } @{$nss->{$ns}{addr_v6}};

        delete( $h{$_} ) for @d6;

        $nss->{$ns}{addr_v6} = [ sort keys %h ];
    }

    my $svtrid = get_svtrid();

    return _min_answ( '1000', $cltrid );
}


sub host_delete {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<delete>\s+<host:delete[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: host:delete', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</host:delete>\s+</delete>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /host:delete', '2001', $cltrid );
    }

    my $ns;
    if ( $body =~ m|<host:name>([0-9A-Za-z\-\.]+)</host:name>| ) {
        $ns = lc $1;
    }
    else {
        return _fail_body( 'Host name is invalid.', '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $nss = $s->data->{nss};

    unless ( $nss->{$ns} ) {
        return _fail_body( "The host &#039;$ns&#039; does not exist", '2303', $cltrid );
    }

    if ( $nss->{$ns}{statuses}{linked} ) {
        return _fail_body( 'Host object is linked to one or more domains.', '2305', $cltrid );
    }

    my $doms = $s->data->{doms};
    foreach my $dm ( keys %{$doms} ) {
        if ( $ns =~ /\.$dm$/ ) {
            delete $doms->{$dm}{hosts}->{$ns};
        }
    }

    if ( $nss->{$ns}{owner} ne $obj->{user} ) {
        return _fail_body( 'Permission denied.', '2201', $cltrid );
    }

    delete $nss->{$ns};

    my $svtrid = get_svtrid();

    return _min_answ( '1000', $cltrid );
}


sub domain_check {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<check>\s+<domain:check[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: domain:check', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</domain:check>\s+</check>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /domain:check', '2001', $cltrid );
    }

    my ( @domains ) = $body =~ m|(<domain:name>[^<>]+</domain:name>)|g;

    unless ( scalar @domains ) {
        return _fail_body( 'XML schema validation failed: domain:cd', '2001', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $answ_list = '';
    foreach my $row ( @domains ) {
        my ( $dm ) = $row =~ m|<domain:name>([^<>]+)</domain:name>|;
        $dm = lc $dm;

        my $reason = '';

        if ( $s->data->{doms}{$dm} ) {
            $reason = $s->data->{doms}{$dm}{reason} || '';
        }
        elsif ( $dm !~ /^[0-9a-z\.\-]+$/ ) {
            my ( $c ) = $dm !~ /([^0-9a-z\.\-])/;
            $reason = 'the following characters are not permitted: &#039;'.$c.'&#039;';
        }
        elsif ( $dm =~ /^reg/ ) { # reged
            $reason = 'in use';
        }
        elsif ( $dm =~ /^blo/ ) {
            $reason = 'blocked';
        }
        elsif ( $dm =~ /^ava/ ) {
            # available
        }
        else {
            $reason = int( rand( 10 ) ) == 1 ? 'in use' : ''; # 10% -- domains is not available
        }

        my $avail = $reason ? 0 : 1;

        unless ( $s->data->{doms}{$dm} ) {
            if ( $reason  &&  $reason !~ /not permitted/ ) {
                $s->data->{doms}{$dm} = { avail => $avail, reason => $reason };
            }
        }

        $reason = "<domain:reason>$reason</domain:reason>" if $reason;

        $answ_list .= qq|<domain:cd><domain:name avail="$avail">$dm</domain:name>$reason</domain:cd>|;
    }

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="1000">
<msg>Command completed successfully.</msg>
</result>
<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">$answ_list</domain:chkData></resData><trID>
<clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|;
}


sub domain_create {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<create>\s+<domain:create[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: domain:create', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</domain:create>\s+</create>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /domain:create', '2001', $cltrid );
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]+)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}name&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.', '2001', $cltrid );
    }

    if ( $dname =~ /([^0-9a-z\.\-])/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: the following characters are not permitted: &#039;$1&#039;", '2004', $cltrid );
    }

    if ( $dname !~ /^[0-9a-z\.\-]+\.[0-9a-z\-]+$/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: suffix ... does not exist", '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $conts = $s->data->{conts};
    my $nss   = $s->data->{nss};
    my $doms  = $s->data->{doms};

    if ( $doms->{$dname} ) {
        return _fail_body( "&#039;$dname&#039; is already registered.", '2302', $cltrid );
    }

    my $period;
    if ( $body =~ m|<domain:period unit="y">([^<>]+)</domain:period>| ) {
        $period = $1;

        if ( $period =~ /([^0-9])/ ) {
            return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}period&#039;: &#039;$period&#039; is not a valid value of the atomic type &#039;{urn:ietf:params:xml:ns:domain-1.0}pLimitType&#039;." );
        }
    }
    else {
        $period = 1;
    }

    if ( $period < 1  or $period > 9 ) {
        return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}period&#039;: [facet &#039;maxInclusive&#039;] The value &#039;100&#039; is greater than the maximum value allowed (&#039;9&#039;).", '2001', $cltrid );
    }

    my $reg_id;
    if ( $body =~ m|<domain:registrant>([^<>]+)</domain:registrant>| ) {
        $reg_id = $1;

        unless ( $conts->{$reg_id} ) {
            return _fail_body( "Specified registrant contact $reg_id is not registered here.", '2303', $cltrid );
        }
    }
    else {
        return _fail_body( 'The &#039;registrant&#039; attribute is empty or missing', '2003', $cltrid );
    }

    my %cc = ( admin => {}, tech => {}, billing => {} );
    for my $t ( 'admin', 'tech', 'billing' ) {
        my @acs = $body =~ m|<domain:contact type="$t">([^<>]+)</domain:contact>|gs;

        foreach my $ac ( @acs ) {
            if ( $conts->{$ac} ) {
                $cc{$t}{$ac} = '+';
            }
            else {
                return _fail_body( "Specified $t contact $ac is not registered here.", '2303', $cltrid );
            }
        }
    }

    my $pw;
    if ( $body =~ m|<domain:authInfo>\s*<domain:pw>([^<>]+)</domain:pw>\s*</domain:authInfo>|s ) {
        $pw = $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}authInfo&#039;: Missing child element(s). Expected is one of ( {urn:ietf:params:xml:ns:domain-1.0}pw, {urn:ietf:params:xml:ns:domain-1.0}ext ).', '2001', $cltrid );
    }
    if ( $pw  and  length( $pw ) < 16 ) {
        return _fail_body( 'authInfo code is invalid: password must be at least 16 characters', '2004', $cltrid );
    }
    unless ( $pw  and  $pw =~ /[A-Z]/  and  $pw =~ /[a-z]/  and  $pw =~ /[0-9]/  and  $pw =~ /[!\@\$\%*_.:\-=+?#,"'\\\/&]/ ) {
        return _fail_body( 'authInfo code is invalid: password must contain a mix of uppercase and lowercase characters', '2004', $cltrid );
    }

    my %nss;
    if ( $body =~ m|<domain:ns>(.+?)</domain:ns>|s ) {
        my $hosts = $1;

        my @nss0 = $hosts =~ m|<domain:hostObj>([^<>]+)</domain:hostObj>|gs;

        foreach my $ns ( @nss0 ) {
            unless ( $nss->{$ns} ) {
                return _fail_body( "Cannot find host object &#039;$ns&#039;", '2303', $cltrid );
            }

            $nss{$ns} = '+';
        }
    }

    my ( $cre_date, $exp_date ) = get_dates( 1 );

    $doms->{$dname} = {
        registrant => $reg_id,
        admin => $cc{admin},
        tech => $cc{tech},
        billing => $cc{billing},
        nss => \%nss,
        cre_date => $cre_date,
        upd_date => $cre_date,
        exp_date => $exp_date,
        authInfo => $pw,
        roid => uc(md5_hex($dname.$cre_date)).'-TEST',
        statuses => { },
        creater => $obj->{user},
        owner => $obj->{user},
        updater => $obj->{user},
        avail => 0,
        reason => 'in use',
    };

    $conts->{$reg_id}{statuses}{linked}++;

    if ( $conts->{$reg_id}{statuses}{ok} ) {
        delete $conts->{$reg_id}{statuses}{ok};
        $conts->{$reg_id}{statuses}{serverDeleteProhibited} = '+';
    }

    for my $t ( 'admin', 'tech', 'billing' ) {

        foreach my $c ( keys %{$cc{$t}} ) {
            $conts->{$c}{statuses}{linked}++;

            if ( $conts->{$c}{statuses}{ok} ) {
                delete $conts->{$c}{statuses}{ok};
                $conts->{$c}{statuses}{serverDeleteProhibited} = '+';
            }
        }
    }

    foreach my $ns ( keys %nss ) {
        $nss->{$ns}{statuses}{linked}++;

        if ( $nss->{$ns}{statuses}{ok} ) {
            delete $nss->{$ns}{statuses}{ok};
            $nss->{$ns}{statuses}{serverDeleteProhibited} = '+';
        }
    }

    return _ok_answ( qq|<domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>$dname</domain:name><domain:crDate>$cre_date</domain:crDate><domain:exDate>$exp_date</domain:exDate></domain:creData>|, $cltrid );
}


sub domain_info {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<info>\s+<domain:info[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: domain:info', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</domain:info>\s+</info>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /domain:info', '2001', $cltrid );
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]+)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}name&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.', '2001', $cltrid );
    }

    if ( $dname =~ /([^0-9a-z\.\-])/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: the following characters are not permitted: &#039;$1&#039;", '2004', $cltrid );
    }

    if ( $dname !~ /^[0-9a-z\.\-]+\.[0-9a-z\-]+$/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: suffix ... does not exist", '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $doms  = $s->data->{doms};

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_body( "The domain &#039;$dname&#039; does not exist", '2303', $cltrid );
    }

    my $dm = $s->data->{doms}{$dname};

    my $answ = qq|<domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>$dname</domain:name>|;
    $answ .= "<domain:roid>$$dm{roid}</domain:roid>";
    unless ( scalar( keys %{$$dm{statuses}} ) ) {
        $answ .= qq|<domain:status s="ok" />|;
    }
    else {
        for my $st ( keys %{$$dm{statuses}} ) {
            if ( $$dm{statuses}{$st} eq '+' ) {
                $answ .= qq|<domain:status s="$st" />|;
            }
            else {
                $answ .= qq|<domain:status s="$st">| . $$dm{statuses}{$st} . '</domain:status>';
            }
        }
    }
    $answ .= "<domain:registrant>$$dm{registrant}</domain:registrant>";
    for my $t ( 'tech', 'admin', 'billing' ) {
        for my $c ( keys %{$$dm{$t}} ) {
            $answ .= qq|<domain:contact type="$t">$c</domain:contact>|;
        }
    }
    if ( $$dm{nss}  &&  scalar( keys %{$$dm{nss}} ) ) {
        $answ .= '<domain:ns>';
        foreach my $ns ( keys %{$$dm{nss}} ) {
            $answ .= "<domain:hostObj>$ns</domain:hostObj>";
        }
        $answ .= '</domain:ns>';
    }
    if ( $$dm{hosts}  &&  scalar( keys %{$$dm{hosts}} ) ) {
        foreach my $host ( sort keys %{$$dm{hosts}} ) {
            $answ .= "<domain:host>$host</domain:host>";
        }
    }
    # centralnic does not show authinfo to anybody
    $answ .= "<domain:clID>$$dm{owner}</domain:clID>";
    $answ .= "<domain:crID>$$dm{creater}</domain:crID>";
    $answ .= "<domain:crDate>$$dm{cre_date}</domain:crDate>";
    $answ .= "<domain:upID>$$dm{updater}</domain:upID>";
    $answ .= "<domain:upDate>$$dm{upd_date}</domain:upDate>";
    $answ .= "<domain:exDate>$$dm{exp_date}</domain:exDate>";
    $answ .= "<domain:trDate>$$dm{trans_date}</domain:trDate>" if $dm->{trans_date};
    $answ .= '</domain:infData>';

    return _ok_answ( $answ, $cltrid );
}


sub domain_renew {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<renew>\s+<domain:renew[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: domain:renew', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</domain:renew>\s+</renew>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /domain:renew', '2001', $cltrid );
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]+)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}name&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.', '2001', $cltrid );
    }

    if ( $dname =~ /([^0-9a-z\.\-])/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: the following characters are not permitted: &#039;$1&#039;", '2004', $cltrid );
    }

    if ( $dname !~ /^[0-9a-z\.\-]+\.[0-9a-z\-]+$/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: suffix ... does not exist", '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $doms  = $s->data->{doms};

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_body( "The domain &#039;$dname&#039; does not exist", '2303', $cltrid );
    }

    my $dm = $s->data->{doms}{$dname};

    for my $s ( 'clientRenewProhibited', 'serverRenewProhibited' ) {
        if ( $dm->{statuses}{$s} ) {
            return _fail_body( "Domain cannot be renewed ($s)", 2304, $cltrid );
        }
    }

    my $period = 1;
    if ( $body =~ m|<domain:period unit="y">(\d+)</domain:period>| ) {
        $period = $1;

        if ( $period > 9 ) {
            return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}period&#039;: [facet &#039;maxInclusive&#039;] The value &#039;$period&#039; is greater than the maximum value allowed (&#039;9&#039;).", '2001', $cltrid );
        }
    }

    my $edt;
    if ( $body =~ m|<domain:curExpDate>(\d\d\d\d-\d\d-\d\d)</domain:curExpDate>| ) {
        $edt = $1;
    }
    else {
        return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}curExpDate&#039;: &#039;xxx&#039; is not a valid value of the atomic type &#039;xs:date&#039;.", '2001', $cltrid );
    }

    my ( $old_exp_date ) = $dm->{exp_date} =~ /^(\d\d\d\d-\d\d-\d\d)/;
    if ( $old_exp_date ne $edt ) {
        return _fail_body( 'Expiry date is not correct.', '2004', $cltrid );
    }

    $dm->{exp_date} =~ s/^(\d+)/$1+$period/e;
    my $new_exp_date = $dm->{exp_date};

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
        <response>
                <result code="1000">
                        <msg>Command completed successfully.</msg>
                </result>

                <resData>
                        <domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
                                <domain:name>$dname</domain:name>
                                <domain:exDate>$new_exp_date</domain:exDate>
                        </domain:renData>
                </resData>
                <trID>
                        <clTRID>$cltrid</clTRID>
                        <svTRID>$svtrid</svTRID>
                </trID>
        </response>
</epp>|;
=rem
<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
        <response>
                <result code="1000">
                        <msg>Command completed successfully.</msg>
                </result>

                <resData>
                        <domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
                                <domain:name>xxx.ru.com</domain:name>
                                <domain:exDate>2022-07-18T23:59:59.0Z</domain:exDate>
                        </domain:renData>
                </resData>
                <extension><fee:renData xmlns:fee="urn:ietf:params:xml:ns:fee-0.5"><fee:currency>USD</fee:currency><fee:fee>18.00</fee:fee></fee:renData></extension>
                <trID>
                        <clTRID>f919bef2e68b168e5d39bf91aff6fa6e</clTRID>
                        <svTRID>CNIC-7295E4F58291FFD21B1702346BA9D70F25952BD03CF3780ECF0DA0D8285</svTRID>
                </trID>
        </response>
</epp>
=cut
}


sub domain_update {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<update>\s+<domain:update[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: domain:update', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</domain:update>\s+</update>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /domain:update', '2001', $cltrid );
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]+)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}name&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.', '2001', $cltrid );
    }

    if ( $dname =~ /([^0-9a-z\.\-])/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: the following characters are not permitted: &#039;$1&#039;", '2004', $cltrid );
    }

    if ( $dname !~ /^[0-9a-z\.\-]+\.[0-9a-z\-]+$/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: suffix ... does not exist", '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $conts = $s->data->{conts};
    my $nss   = $s->data->{nss};
    my $doms  = $s->data->{doms};

    unless ( $s->data->{doms}{$dname} ) {
        return _fail_body( "The domain &#039;$dname&#039; does not exist", '2303', $cltrid );
    }

    my $dm = $s->data->{doms}{$dname};

    if ( $dm->{statuses}{serverUpdateProhibited} ) {
        return _fail_body( 'The domain name cannot be updated (serverUpdateProhibited).', '2304', $cltrid );
    }

    my $no_upd = $dm->{statuses}{clientUpdateProhibited} ? 1 : 0;

    if ( $body =~ m|<domain:rem>(.+?)</domain:rem>|s ) {
        my $u = $1;

        my @sts = $u =~ m|<domain:status\s+s="(\w+)"|gs;

        foreach my $st ( @sts ) {
            if ( $no_upd  &&  $st eq 'clientUpdateProhibited' ) {
                $no_upd = 0;
            }
        }
    }

    if ( $no_upd ) {
        return _fail_body( 'The domain name cannot be updated (clientUpdateProhibited).', '2304', $cltrid );
    }


    my %add;
    my %rem;
    my %chg;

    # For NSS Registry at first adds everything, then deletes -- it is already checked
    if ( $body =~ m|<domain:add>(.+?)</domain:add>|s ) {
        my $add = $1;

        # CentralNIC not save the status reason
        my @sts = $add =~ /<domain:status\s+s="(\w+)"/gs;

        foreach my $st ( @sts ) {
            unless ( $statuses{$st} ) {
                return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}status&#039;, attribute &#039;s&#039;: [facet &#039;enumeration&#039;] The value &#039;$st&#039; is not an element of the set {&#039;clientDeleteProhibited&#039;, &#039;clientHold&#039;, &#039;clientRenewProhibited&#039;, &#039;clientTransferProhibited&#039;, &#039;clientUpdateProhibited&#039;, &#039;inactive&#039;, &#039;ok&#039;, &#039;pendingCreate&#039;, &#039;pendingDelete&#039;, &#039;pendingRenew&#039;, &#039;pendingTransfer&#039;, &#039;pendingUpdate&#039;, &#039;serverDeleteProhibited&#039;, &#039;serverHold&#039;, &#039;serverRenewProhibited&#039;, &#039;serverTransferProhibited&#039;, &#039;serverUpdateProhibited&#039;}.", '2001', $cltrid );
            }

            if ( $dm->{statuses}{$st} ) {
                return _fail_body( "$st is already set on this domain.", '2004', $cltrid );
            }

            push @{$add{statuses}}, $st;
        }

        foreach my $t ( 'admin', 'tech', 'billing' ) {
            if ( $add =~ m|<domain:contact type="$t">([^<>]+)</domain:contact>| ) {
                $add{$t} = $1;

                unless ( $conts->{$add{$t}} ) {
                    return _fail_body( "Cannot add $t contact $add{$t} contact not found.", '2303', $cltrid );
                }
            }
        }

        if ( $add =~ m|<domain:ns>(.+?)</domain:ns>|s ) {
            my $ns = $1;

            my @hosts = $ns =~ m|<domain:hostObj>([^<>]+)</domain:hostObj>|g;

            $add{nss} = {};

            foreach my $h ( @hosts ) {
                if ( $nss->{$h} ) {
                    $add{nss}{$h} = '+';
                }
                else {
                    return _fail_body( "Cannot find host object &#039;$h&#039;", '2303', $cltrid );
                }
            }
        }
    }

    if ( $body =~ m|<domain:rem>(.+?)</domain:rem>|s ) {
        my $rem = $1;

        my @sts = $rem =~ m|<domain:status\s+s="(\w+)"|gs;

        foreach my $st ( @sts ) {
            unless ( $statuses{$st} ) {
                return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}status&#039;, attribute &#039;s&#039;: [facet &#039;enumeration&#039;] The value &#039;$st&#039; is not an element of the set {&#039;clientDeleteProhibited&#039;, &#039;clientHold&#039;, &#039;clientRenewProhibited&#039;, &#039;clientTransferProhibited&#039;, &#039;clientUpdateProhibited&#039;, &#039;inactive&#039;, &#039;ok&#039;, &#039;pendingCreate&#039;, &#039;pendingDelete&#039;, &#039;pendingRenew&#039;, &#039;pendingTransfer&#039;, &#039;pendingUpdate&#039;, &#039;serverDeleteProhibited&#039;, &#039;serverHold&#039;, &#039;serverRenewProhibited&#039;, &#039;serverTransferProhibited&#039;, &#039;serverUpdateProhibited&#039;}.", '2001', $cltrid );
            }

            unless ( $dm->{statuses}{$st} ) {
                return _fail_body( "$st is not set on this domain.", '2004', $cltrid );
            }

            push @{$rem{statuses}}, $st;
        }

        foreach my $t ( 'admin', 'tech', 'billing' ) {
            if ( $rem =~ m|<domain:contact type="$t">([^<>]+)</domain:contact>| ) {
                $rem{$t} = $1;

                unless ( $conts->{$rem{$t}} ) {
                    return _fail_body( "Cannot remove $t contact $rem{$t}: contact not found.", '2303', $cltrid );
                }

                unless ( $dm->{$t}{$rem{$t}} ) {
                    return _fail_body( "Invalid contact association type &#039;$t&#039;", '2004', $cltrid );
                }
            }
        }

        if ( $rem =~ m|<domain:ns>(.+?)</domain:ns>|s ) {
            my $ns = $1;

            my @hosts = $ns =~ m|<domain:hostObj>([^<>]+)</domain:hostObj>|g;

            $rem{nss} = {};

            foreach my $h ( @hosts ) {
                if ( $add{nss}{$h} ) {
                    delete $add{nss}{$h};
                    next;
                }

                if ( $dm->{nss}{$h} ) {
                    $rem{nss}{$h} = '+';
                }
                else {
                    return _fail_body( "The host $h is not linked to this domain name.", '2303', $cltrid );
                }
            }
        }
    }

    foreach my $t ( 'admin', 'tech', 'billing' ) {
        if ( $add{$t}  and  not $rem{$t} ) {
            return _fail_body( "Cannot assign a new $t contact without removing current tech contact.", '2004', $cltrid );
        }

        if ( not $add{$t}  and  $rem{$t} ) {
            return _fail_body( "Invalid contact association type &#039;$t&#039;", '2004', $cltrid );
        }
    }

    if ( $body =~ m|<domain:chg>(.+?)</domain:chg>|s ) {
        my $chg = $1;

        if ( $chg =~ m|<domain:registrant>([^<>]+)</domain:registrant>| ) {
            $chg{registrant} = $1;

            unless ( $conts->{$chg{registrant}} ) {
                return _fail_body( "Contact $chg{registrant} does not exist, cannot change registrant.", '2303', $cltrid );
            }
        }

        if ( $chg =~ m|authInfo.+<domain:pw>([^<>]*)</domain:pw>.+authInfo|s ) {
            my $pw = $1;

            if ( $pw  and  length( $pw ) < 16 ) {
                return _fail_body( 'authInfo code is invalid: password must be at least 16 characters', '2004', $cltrid );
            }

            unless ( $pw  and  $pw =~ /[A-Z]/  and  $pw =~ /[a-z]/  and  $pw =~ /[0-9]/  and  $pw =~ /[!\@\$\%*_.:\-=+?#,"'\\\/&]/ ) {
                return _fail_body( 'authInfo code is invalid: password must contain a mix of uppercase and lowercase characters', '2004', $cltrid );
            }

            $chg{authInfo} = $pw;
        }
    }

    # at first there is adding!!!
    if ( scalar( keys %add ) ) {
        if ( $add{statuses} ) {
            foreach my $st ( @{$add{statuses}} ) {
                $dm->{statuses}{$st} = '+';
            }
        }

        foreach my $t ( 'admin', 'tech', 'billing' ) {
            if ( $add{$t} ) {
                $dm->{$t}{$add{$t}} = '+';

                $conts->{$add{$t}}{statuses}{linked}++;

                if ( $conts->{$add{$t}}{statuses}{ok} ) {
                    delete $conts->{$add{$t}}{statuses}{ok};
                    $conts->{$add{$t}}{statuses}{serverDeleteProhibited} = '+';
                }
            }
        }

        if ( $add{nss} ) {
            foreach my $ns ( keys %{$add{nss}} ) {
                $dm->{nss}{$ns} = '+';

                $nss->{$ns}{statuses}{linked}++;

                if ( $nss->{$ns}{statuses}{ok} ) {
                    delete $nss->{$ns}{statuses}{ok};
                    $nss->{$ns}{statuses}{serverDeleteProhibited} = '+';
                }
            }
        }
    }

    if ( scalar( keys %rem ) ) {
        if ( $rem{statuses} ) {
            foreach my $st ( @{$rem{statuses}} ) {
                delete $dm->{statuses}->{$st};
            }
        }

        foreach my $t ( 'admin', 'tech', 'billing' ) {
            if ( $rem{$t} ) {
                delete $dm->{$t}{$rem{$t}};

                $conts->{$rem{$t}}{statuses}{linked}--;

                if ( $conts->{$rem{$t}}{statuses}{linked} <= 0 ) {
                    delete $conts->{$rem{$t}}{statuses}{linked};

                    $conts->{$rem{$t}}{statuses}{ok} = '+';
                    delete $conts->{$rem{$t}}{statuses}{serverDeleteProhibited};
                }
            }
        }

        if ( $rem{nss} ) {
            foreach my $ns ( keys %{$rem{nss}} ) {
                delete $dm->{nss}->{$ns};

                $nss->{$ns}{statuses}{linked}--;

                if ( $nss->{$ns}{statuses}{linked} <= 0 ) {
                    delete $nss->{$ns}{statuses}{linked};

                    $nss->{$ns}{statuses}{ok} = '+';
                    delete $nss->{$ns}{statuses}{serverDeleteProhibited};
                }
            }
        }
    }

    if ( $chg{registrant} ) {
        $conts->{$dm->{registrant}}{statuses}{linked}--;

        if ( $conts->{$dm->{registrant}}{statuses}{linked} <= 0 ) {
            delete $conts->{$dm->{registrant}}{statuses}{linked};

            $conts->{$dm->{registrant}}{statuses}{ok} = '+';
            delete $conts->{$dm->{registrant}}{statuses}{serverDeleteProhibited};
        }

        $dm->{registrant} = $chg{registrant};

        $conts->{$chg{registrant}}{statuses}{linked}++;

        if ( $conts->{$chg{registrant}}{statuses}{ok} ) {
            delete $conts->{$chg{registrant}}{statuses}{ok};
            $conts->{$chg{registrant}}{statuses}{serverDeleteProhibited} = '+';
        }
    }

    $dm->{authInfo} = $chg{authInfo} if $chg{authInfo};

    my $svtrid = get_svtrid();

    return _min_answ( '1000', $cltrid );
}


sub domain_delete {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<delete>\s+<domain:delete[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: domain:delete', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</domain:delete>\s+</delete>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /domain:delete', '2001', $cltrid );
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]+)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}name&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.', '2001', $cltrid );
    }

    if ( $dname =~ /([^0-9a-z\.\-])/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: the following characters are not permitted: &#039;$1&#039;", '2004', $cltrid );
    }

    if ( $dname !~ /^[0-9a-z\.\-]+\.[0-9a-z\-]+$/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: suffix ... does not exist", '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $conts = $s->data->{conts};
    my $nss   = $s->data->{nss};
    my $doms  = $s->data->{doms};

    unless ( $doms->{$dname} ) {
        return _fail_body( "The domain &#039;$dname&#039; does not exist", '2303', $cltrid );
    }

    my $dm = $doms->{$dname};

    unless ( $dm->{reason} eq 'in use' ) {
        return _fail_body( "The domain &#039;$dname&#039; does not exist", '2303', $cltrid );
    }

    foreach my $st ( 'clientDeleteProhibited', 'serverDeleteProhibited', 'clientUpdateProhibited', 'serverUpdateProhibited' ) {
        if ( $dm->{statuses}{$st} ) {
            return _fail_body( "The domain name cannot be $statuses{$st} ($st).", '2304', $cltrid );
        }
    }

    if ( $dm->{hosts} ) {
        foreach my $h ( keys %{$dm->{hosts}} ) {
            if ( $nss->{$h}{statuses}{linked} ) {
                return _fail_body( "Domain host $h is linked to one or more domains.", '2305', $cltrid );
            }
        }
    }

    if ( $dm->{hosts} ) {
        foreach my $h ( keys %{$dm->{hosts}} ) {
            delete $nss->{$h};
        }
    }

    $conts->{$dm->{registrant}}{statuses}{linked}--;

    if ( $conts->{$dm->{registrant}}{statuses}{linked} <= 0 ) {
        delete $conts->{$dm->{registrant}}{statuses}{linked};
        delete $conts->{$dm->{registrant}}{statuses}{serverDeleteProhibited};
        $conts->{$dm->{registrant}}{statuses}{ok} = '+';
    }

    foreach my $t ( 'admin', 'tech', 'billing' ) {
        foreach my $c ( keys %{$dm->{$t}} ) {
            $conts->{$c}{statuses}{linked}--;

            if ( $conts->{$c}{statuses}{linked} <= 0 ) {
                delete $conts->{$c}{statuses}{linked};
                delete $conts->{$c}{statuses}{serverDeleteProhibited};
                $conts->{$c}{statuses}{ok} = '+';
            }
        }
    }

    foreach my $ns ( keys %{$dm->{nss}} ) {
        $nss->{$ns}{statuses}{linked}--;

        if ( $nss->{$ns}{statuses}{linked} <= 0 ) {
            delete $nss->{$ns}{statuses}{linked};
            delete $nss->{$ns}{statuses}{serverDeleteProhibited};
            $nss->{$ns}{statuses}{ok} = '+';
        }
    }

    undef $dm;
    delete $doms->{$dname};

    return _min_answ( '1000', $cltrid );
}


sub domain_transfer {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    unless ( $body =~ s|^<\?xml version="1.0" encoding="UTF-8"\?>\s+||s ) {
        return _fail_body( 'XML schema validation failed: ', '2001', $cltrid );
    }

    unless ( $body =~ s|^<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="[^"]+" xsi:schemaLocation="[^"]+">\s+||s ) {
        return _fail_body( 'XML schema validation failed: Element &#039;{uurn:ietf:params:xml:ns:epp-1.0}epp&#039;: No matching global declaration available for the validation root.', '2001', $cltrid );
    }

    my $op;
    if ( $body =~ /<transfer\s+op="(query|request|cancel|reject|approve)">/ ) {
        $op = $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:epp-1.0}transfer&#039;, attribute &#039;op&#039;: [facet &#039;enumeration&#039;] The value &#039;xxxx&#039; is not an element of the set {&#039;approve&#039;, &#039;cancel&#039;, &#039;query&#039;, &#039;reject&#039;, &#039;request&#039;}.', '2001', $cltrid );
    }

    unless ( $body =~ s|^<command>\s+<transfer op="[a-z]+">\s+<domain:transfer[^<>]+>\s+||s ) {
        return _fail_body( 'XML schema validation failed: domain:transfer', '2001', $cltrid );
    }

    unless ( $body =~ s|\s+</domain:transfer>\s+</transfer>\s+<clTRID>[^<>]+</clTRID>\s+</command>\s+</epp>\s*$||s ) {
        return _fail_body( 'XML schema validation failed: /domain:transfer', '2001', $cltrid );
    }

    my $dname;
    if ( $body =~ m|<domain:name>([^<>]+)</domain:name>| ) {
        $dname = lc $1;
    }
    else {
        return _fail_body( 'XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}name&#039;: [facet &#039;minLength&#039;] The value has a length of &#039;0&#039;; this underruns the allowed minimum length of &#039;1&#039;.', '2001', $cltrid );
    }

    if ( $dname =~ /([^0-9a-z\.\-])/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: the following characters are not permitted: &#039;$1&#039;", '2004', $cltrid );
    }

    if ( $dname !~ /^[0-9a-z\.\-]+\.[0-9a-z\-]+$/ ) {
        return _fail_body( "&#039;$dname&#039; is not a valid domain name: suffix ... does not exist", '2004', $cltrid );
    }

    my $srv_url = $obj->{sock};
    my $s = new IO::EPP::Test::Server( $srv_url );
    my $doms  = $s->data->{doms};

    unless ( $doms->{$dname} ) {
        return _fail_body( "The domain &#039;$dname&#039; cannot be found.", '2303', $cltrid );
    }

    my $dm = $doms->{$dname};

    if ( $op eq 'cancel'  or  $op eq 'reject'  or  $op eq 'approve' ) {
        unless ( $dm->{statuses}{pendingTransfer} ) {
            return _fail_body( 'There are no pending transfer requests for this object.', '2301', $cltrid );
        }
    }

    if ( $op eq 'query' ) {
        unless ( $dm->{statuses}{pendingTransfer} ) {
            return _fail_body( 'You cannot view the details of this transfer.', '2201', $cltrid );
        }

        unless ( $dm->{owner} eq $obj->{user}  or  $dm->{transfer}{new_owner} eq $obj->{user} ) {
            return _fail_body( 'You cannot view the details of this transfer.', '2201', $cltrid );
        }

        my $from = $dm->{owner};
        my $to = $dm->{transfer}{new_owner};

        my $exp_date = $dm->{exp_date};
        my $period = $dm->{transfer}{period};
        $exp_date =~ s/^(\d+)/$1+$period/e;

        my $tr_dt = $dm->{transfer}{tr_date};
        my $q_dt  = $dm->{transfer}{q_date};


        return _ok_answ( qq|<domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>flowerlab.online</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>$to</domain:reID><domain:reDate>$q_dt</domain:reDate><domain:acID>$from</domain:acID><domain:acDate>$tr_dt</domain:acDate><domain:exDate>$exp_date</domain:exDate></domain:trnData>|, $cltrid );
    }

    if ( $op eq 'request' ) {
        if ( $dm->{owner} eq $obj->{user} ) {
            return _fail_body( 'You are already the sponsor for this domain', '2304', $cltrid );
        }

        foreach my $st ( 'clientTransferProhibited', 'clientUpdateProhibited', 'serverTransferProhibited', 'serverUpdateProhibited' ) {
            if ( $dm->{statuses}{$st} ) {
                return _fail_body( "The domain name cannot be $statuses{$st} ($st).", '2304', $cltrid );
            }
        }
    }

    if ( $op eq 'cancel' ) {
        if ( $dm->{transfer}{new_owner} eq $obj->{user} ) {
            delete $dm->{transfer};
            delete $dm->{statuses}{pendingTransfer};

            return _min_answ( '1000', $cltrid );
        }

        return _fail_body( 'You cannot cancel this transfer.', '2201', $cltrid );
    }

    if ( $op eq 'reject' ) {
        if ( $dm->{owner} eq $obj->{user} ) {
            delete $dm->{transfer};
            delete $dm->{statuses}{pendingTransfer};

            return _min_answ( '1000', $cltrid );
        }

        return _fail_body( 'You cannot reject this transfer.', '2201', $cltrid );
    }

    if ( $op eq 'approve' ) {
        if ( $dm->{owner} eq $obj->{user} ) {
            $dm->{owner} = $dm->{transfer}{new_owner};
            my $p = $dm->{transfer}{period};
            $dm->{exp_date} =~ s/^(\d+)/$1+$p/e;

            delete $dm->{transfer};
            delete $dm->{statuses}{pendingTransfer};

            return _min_answ( '1000', $cltrid );
        }

        return _fail_body( 'You cannot approve this transfer.', '2201', $cltrid );
    }

    my $period = 1;
    if ( $body =~ m|<domain:period unit="y">(\d+)</domain:period>| ) {
        $period = $1;

        if ( $period > 9 ) {
            return _fail_body( "XML schema validation failed: Element &#039;{urn:ietf:params:xml:ns:domain-1.0}period&#039;: [facet &#039;maxInclusive&#039;] The value &#039;$period&#039; is greater than the maximum value allowed (&#039;9&#039;).", '2001', $cltrid );
        }
    }

    if ( $body =~ m|authInfo.+<domain:pw>([^<>]+)</domain:pw>.+authInfo|s ) {
        my $pw = $1;

        if ( $pw ne $dm->{authInfo} ) {
            return _fail_body( 'Invalid authorisation code.', '2202', $cltrid );
        }
    }

    my $from = $dm->{owner};
    my $to = $obj->{user};

    my $exp_date = $dm->{exp_date};
    $exp_date =~ s/^(\d+)/$1+$period/e;
    my ( $q_dt ) = get_dates();
    my $tr_dt = $q_dt;
    $tr_dt =~ s/^(\d+)/$1+1/e;

    $dm->{transfer} = {
        period => $period,
        new_owner => $obj->{user},
        q_date => $q_dt,
        tr_date => $tr_dt,
    };

    $dm->{statuses}{pendingTransfer} = '+';

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0"><response><result code="1001"><msg>Command completed OK; action pending</msg></result><resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>$dname</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>$to</domain:reID><domain:reDate>$q_dt</domain:reDate><domain:acID>$from</domain:acID><domain:acDate>$tr_dt</domain:acDate><domain:exDate>$exp_date</domain:exDate></domain:trnData></resData><trID><clTRID>$cltrid</clTRID><svTRID>$svtrid</svTRID></trID></response></epp>|;
}


sub poll {
    my ( $obj, $body ) = @_;

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    return _fail_cltrid() unless $cltrid;

    my $svtrid = get_svtrid();

    return qq|<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
<response>
<result code="1300">
<msg>There are no messages for you!</msg>
</result>
<trID>
<clTRID>$cltrid</clTRID>
<svTRID>$svtrid</svTRID>
</trID>
</response>
</epp>|;
}


sub logout {
    my ( $body ) = @_;

    unless ( $body =~ s|^<\?xml[^<>]+\?>\s+<epp[^<>]+>||s ) {
        _fail_body( 'XML schema validation failed: ', '2001' );
    }

    unless ( $body =~ m|<command>(.+?)</command>|s ) {
        die "closed connection\n";
    }

    my $svtrid = get_svtrid();

    my ( $cltrid ) = $body =~ m|<clTRID>([0-9A-Za-z\-]+)</clTRID>|s;

    if ( $cltrid ) {
        return _min_answ( '1500', $cltrid );
    }

    return _fail_cltrid();
}

1;
