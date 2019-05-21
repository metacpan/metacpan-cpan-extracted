package MPMinus::Util; # $Id: Util.pm 280 2019-05-14 06:47:06Z minus $

use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Util - Utility functions

=head1 VERSION

Version 1.25

=head1 SYNOPSIS

    use MPMinus::Util;

    my $fsecs = getHiTime();
    my $sid = getSID( 20 );

    my $login = MPMinus::Util::correct_loginpass( "anonymous" ); # 'anonymous'
    my $md5_apache = MPMinus::Util::get_md5_apache( "password" );
    my $md5_unix = MPMinus::Util::get_md5_unix( "password" );

=head1 DESCRIPTION

MPMinus utilities

=head1 FUNCTIONS

=head2 getHiTime

    my $fsecs = getHiTime();

Returns a floating seconds since the epoch. See function L<Time::HiRes/gettimeofday>

Please note! This function is not exported automatically!

=head2 get_md5_apache

    my $md5_apache = get_md5_apache( "password" );

Returns MD5-hash digest of "password" value in apache notation

Please note! This function is not exported automatically!

=head2 get_md5_unix

    my $md5_unix = get_md5_unix( "password" );

Returns MD5-hash digest of "password" value in unix notation

=head2 getSID

    my $sid = getSID( $length, $chars );
    my $sid = getSID( 16, "m" ); # 16 successful chars consisting of MD5 hash
    my $sid = getSID( 20 ); # 20 successful chars consisting of a set of chars 0-9A-Z
    my $sid = getSID(); # 16 successful chars consisting of a set of chars 0-9A-Z

Function returns Session-ID (SID)

$chars - A string containing a collection of characters or code:

    d - characters 0-9
    w - characters A-Z
    h - HEX characters 0-9A-F
    m - Digest::MD5 function from Apache::Session::Generate::MD5
      - default characters 0-9A-Z

=head2 correct_loginpass

    my $login = correct_loginpass( "anonymous" ); # 'anonymous'
    my $password = correct_loginpass( "{MOON}" ); # ''

Correcting a login or password. Issued lc() format username / password thatmust not contain
characters other than those listed:

    a-zA-Z0-9.,-_!@#$%^&*+=/\~|:;

Otherwise, it returns an empty value ('')

Please note! This function is not exported automatically!

=head2 msoconf2args

    my %args = msoconf2args($m->conf('store'));
    my $mso = new MPMinus::Store::MultiStore(
        -m   => $m,
        -mso => \%args,
    );

Converting MSO configuration section to MultiStore -mso arguments

In conf/mso.conf:

    <store foo>
        dsn   DBI:mysql:database=NAME;host=HOST
        user  login
        pass  password
        <Attr>
            mysql_enable_utf8 1
            RaiseError        0
            PrintError        0
        </Attr>
    </store>

    <store bar>
        dsn   DBI:Oracle:SID
        user  login
        pass  password
        <Attr>
            RaiseError        0
            PrintError        0
        </Attr>
    </store>

Please note! This function is not exported automatically!

=head1 HISTORY

=over 8

=item B<1.00 / 27.02.2008>

Init version on base mod_main 1.00.0002

=item B<1.10 / 01.04.2008>

Module is merged into the global module level

=item B<1.11 / 12.01.2009>

Fixed bugs in functions *datatime*

=item B<1.12 / 27.02.2009>

Module is merged into the global module level

=item B<1.20 / 28.04.2011>

Binary file's mode supported

=item B<1.21 / 14.05.2011>

modified functions tag and slash

=item B<1.22 / 19.10.2011>

Added function datetime2localtime and localtime2datetime as alias for localtime2date_time.

Added alias current_datetime for current_date_time

=item B<1.23 / Wed Apr 24 14:53:38 2013 MSK>

General refactoring

=item B<1.24 / Wed May  8 15:37:02 2013 MSK>

Added function msoconf2args

=back

See C<Changes> file

=head1 DEPENDENCIES

C<mod_perl2>, L<CTK>, L<Time::HiRes>, L<Digest::MD5>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<mod_perl2>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = 1.25;


use base qw/Exporter/;
our @EXPORT = qw/
        getHiTime
        getSID

    /;
our @EXPORT_OK = (@EXPORT, qw/
        msoconf2args
        correct_loginpass
        get_md5_apache
        get_md5_unix
    /);

use Time::HiRes qw(gettimeofday);
use Digest::MD5;
use CTK::ConfGenUtil qw/hash/;

use constant {
    ITOA64  => './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
};

sub getHiTime {
    return gettimeofday() * 1;
}
sub getSID {
    my $length = shift || 16;
    my $chars    = shift || "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    # Copyright(c) 2000, 2001 Jeffrey William Baker (jwbaker@acm.org)
    # Distribute under the Perl License
    # Source: Apache::Session::Generate::MD5
    return substr(
        Digest::MD5::md5_hex(
            Digest::MD5::md5_hex(
                time() . {} . rand() . $$
            )
        ), 0, $length) if $chars =~ /^\s*m\s*$/i;

    $chars = "0123456789" if $chars =~ /^\s*d\s*$/i;
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" if $chars =~ /^\s*w\s*$/i;
    $chars = "0123456789ABCDEF" if $chars =~ /^\s*h\s*$/i;

    my @rows = split //, $chars;

    my $retv = '';
    for (my $i=0; $i<$length; $i++) {
        $retv .= $rows[int(rand(length($chars)-1))]
    }

    return "$retv"
}
sub msoconf2args {
    my $mso_conf = shift;
    my @stores = $mso_conf && ref($mso_conf) eq 'HASH' ? keys(%$mso_conf) : ();
    my %args = ();
    for (@stores) {
        my $store = hash($mso_conf, $_);
        $args{$_} = {};
        while (my ($key, $value) = each %$store) {
            $args{$_}{"-".$key} = $value
        }
    }
    return %args;
}
sub correct_loginpass {
    my $v = shift || '';
    return "" if $v =~ /[^a-zA-Z0-9.,-_!@#\$%^&*+=\/\\~|]|[:;]/g;
    return lc($v);
}

#
# MD5 Apache notation
#
sub get_md5_apache {
    my $password = shift // return "";
    return _md5_crypt(q/$apr1$/, $password, _get_salt());
}
sub get_md5_unix {
    my $password = shift // return "";
    return _md5_crypt(q/$1$/, $password, _get_salt());
}
sub _get_salt {
    my($salt,$i, $rand);
    $rand=0;
    my (@itoa64) = (0 .. 9,'a' .. 'z','A' .. 'Z');
    $salt = '';
    for ($i = 0; $i < 8; $i++) {
      srand(time + $rand + $$);
      $rand = rand(25*29*17 + $rand);
      $salt .=  $itoa64[$rand & $#itoa64];
    }
    return $salt; # crypt($passwd,$salt);
}
sub _to64 {
    my ($v, $n) = @_;
    my $ret = '';
    while (--$n >= 0) {
        $ret .= substr(ITOA64, $v & 0x3f, 1);
        $v >>= 6;
    }
    return $ret;
}
sub _md5_crypt {
    my($Magic, $pw, $salt) = @_;
    my $passwd;

    if ( defined $salt ) {
        $salt =~ s/^\Q$Magic//; # Take care of the magic string if
                                # if present.
        $salt =~ s/^(.*)\$.*$/$1/; # Salt can have up to 8 chars...
        $salt = substr($salt, 0, 8);
    } else {
        $salt = ''; # in case no salt was proffered
        $salt .= substr(ITOA64, int(rand(64)+1),1)
            while length($salt) < 8;
    }

    my $ctx = new Digest::MD5; # Here we start the calculation
    $ctx->add($pw); # Original password...
    $ctx->add($Magic); # ...our magic string...
    $ctx->add($salt); # ...the salt...

    my ($final) = new Digest::MD5;
    $final->add($pw);
    $final->add($salt);
    $final->add($pw);
    $final = $final->digest;

    my $pl;
    for ($pl = length($pw); $pl > 0; $pl -= 16) {
        $ctx->add(substr($final, 0, $pl > 16 ? 16 : $pl));
    }

    # Now the 'weird' xform
    my $i;
    for ($i = length($pw); $i; $i >>= 1) {
        if ($i & 1) { $ctx->add(pack("C", 0)); }
        # This comes from the original version,
        # where a memset() is done to $final
        # before this loop.
        else { $ctx->add(substr($pw, 0, 1)); }
    }
    $final = $ctx->digest;

    # The following is supposed to make
    # things run slower. In perl, perhaps
    # it'll be *really* slow!
    my $ctx1;
    for ($i = 0; $i < 1000; $i++) {
        $ctx1 = new Digest::MD5;
        if ($i & 1) { $ctx1->add($pw); }
        else { $ctx1->add(substr($final, 0, 16)); }
        if ($i % 3) { $ctx1->add($salt); }
        if ($i % 7) { $ctx1->add($pw); }
        if ($i & 1) { $ctx1->add(substr($final, 0, 16)); }
        else { $ctx1->add($pw); }
        $final = $ctx1->digest;
    }

    # Final xform
    $passwd = '';
    $passwd .= _to64(int(unpack("C", (substr($final, 0, 1))) << 16)
            | int(unpack("C", (substr($final, 6, 1))) << 8)
            | int(unpack("C", (substr($final, 12, 1)))), 4);
    $passwd .= _to64(int(unpack("C", (substr($final, 1, 1))) << 16)
            | int(unpack("C", (substr($final, 7, 1))) << 8)
            | int(unpack("C", (substr($final, 13, 1)))), 4);
    $passwd .= _to64(int(unpack("C", (substr($final, 2, 1))) << 16)
            | int(unpack("C", (substr($final, 8, 1))) << 8)
            | int(unpack("C", (substr($final, 14, 1)))), 4);
    $passwd .= _to64(int(unpack("C", (substr($final, 3, 1))) << 16)
            | int(unpack("C", (substr($final, 9, 1))) << 8)
            | int(unpack("C", (substr($final, 15, 1)))), 4);
    $passwd .= _to64(int(unpack("C", (substr($final, 4, 1))) << 16)
            | int(unpack("C", (substr($final, 10, 1))) << 8)
            | int(unpack("C", (substr($final, 5, 1)))), 4);
    $passwd .= _to64(int(unpack("C", substr($final, 11, 1))), 2);

    $final = '';
    return $Magic . $salt . q/$/ . $passwd;
}

1;
