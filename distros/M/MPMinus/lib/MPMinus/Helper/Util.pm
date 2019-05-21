package MPMinus::Helper::Util; # $Id: Util.pm 281 2019-05-16 16:53:58Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

MPMinus::Helper::Util - MPMinus Helper's utility

=head1 VERSION

Version 1.05

=head1 SYNOPSIS

    use MPMinus::Helper::Util;

=head1 DESCRIPTION

MPMinus Helper's utility

=head1 FUNCTIONS

=over 8

=item B<back2slash>

    print back2slash(" C:\foo\bar "); # C:/foo/bar

Convert backslashes to slashes in strings

=item B<cleanProjectName>

    my $name = cleanProjectName( "foo" );

Returns clean name of project

=item B<cleanServerName>

    my $name = cleanServerName( "localhost" );

Returns clean name of server

=item B<getApache>, B<getApache2>

    my $hash = getApache();
    my $value = getApache("APACHE_VERSION"); # => '2.0418'

Returns HTTPD_ROOT, SERVER_CONFIG_FILE, SERVER_VERSION and etc., as hash structure
(reference).

    {
      'SERVER_VERSION' => '2.4.18',
      'HTTPD_ROOT' => '/etc/apache2',
      'SERVER_CONFIG_FILE' => '/etc/apache2/apache2.conf',
      'APACHE_VERSION' => '2.0418',
      'APACHE_SIGN' => 24,
      'APACHE_LOG_DIR' => '/var/log/apache2',
    };

=item B<load_metadata>

    my %meta = load_metadata("meta.yml");

Returns metadata from YAML file

=item B<to_void>

    my $v = to_void( $value );

Returns '' (void) if undefined $value else - returns $value

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

Coming soon

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION @EXPORT_OK);
$VERSION = 1.05;

use base qw /Exporter/;
@EXPORT_OK = qw(
        getApache getApache2
        to_void
        cleanProjectName cleanServerName
        load_metadata
        back2slash
    );

use Carp;
use CTK::Util qw/ :BASE :EXT /;
use CTK::ConfGenUtil;
use YAML::XS ();
use JSON::XS ();
use Try::Tiny;
use File::Spec;

# Get (HTTP_ROOT, SERVER_CONFIG_FILE, SERVER_VERSION, APACHE_VERSION, APACHE_SIGN, APACHE_LOG_DIR)
my %A2;
sub getApache2 {
    my $key = shift;
    if (%A2) { return $key ? $A2{uc($key)} : {%A2} }

    my $httpdata;
    my $httpdpath;
    if (isostype("Windows")) {
        $httpdpath = execute(q{pv.exe -e 2>NUL});
        if ($httpdpath =~ /^httpd.exe\s+\d+\s+\S+\s+(.+?)\s*$/m) {
            $httpdpath = $1;
            $httpdata = execute(qq{$httpdpath -V});
        } else {
            if ($httpdpath =~ /^(apache.+?)\s+\d+\s+\S+\s+(.+?)\1\s*$/im) {
                $httpdpath = File::Spec->catfile($2,'httpd.exe');
                $httpdata  = execute(qq{$httpdpath -V});
            } else {
                $httpdpath = '';
                $httpdata  = '';
            }
        }
    } else {
        # Fix #198
        my @err;
        foreach my $httpd (qw/apache2ctl apachectl httpd apache2 apache22 apache/) {
            my $cmd = qq{$httpd -V};
            my $e = "";
            try {
                $httpdata = execute($cmd, undef, \$e);
                push @err, $e if $e;
            } catch {
                push @err, sprintf("%s: %s", $cmd, $_)
            };
            last if $httpdata && $httpdata =~ /HTTPD_ROOT/im;
        }
        carp(join "\n", @err) if ((!$httpdata) && @err)
    }

    my $httpd_root          = $httpdata =~ /HTTPD_ROOT\="(.+?)"/m ? $1 : '';
    my $server_config_file  = $httpdata =~ /SERVER_CONFIG_FILE\="(.+?)"/m ? $1 : '';
    my $sver                = $httpdata =~ /version\:\s+[a-z]+\/([0-9.]+)/im ? $1 : '';
    my $aver                = 0;

    if ($sver =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/) {
        $aver = $1 + ($2/100) + ($3/10000);
    } elsif ($sver =~ /([0-9]+)\.([0-9]+)/) {
        $aver = $1 + ($2/100);
    } elsif ($sver =~ /([0-9]+)/) {
        $aver = $1;
    }

    my $httpdconfig = '';
    if ($server_config_file && $httpd_root) {
        $httpdconfig = File::Spec->catfile($httpd_root,$server_config_file);
    }

    my $acc = '';
    unless ($httpdconfig && -e $httpdconfig) {
        foreach (split /[\/\\]/, $httpdpath) {
            $acc = $acc ? File::Spec->catfile($acc,$_) : $_;
            $httpdconfig = File::Spec->catfile($acc,$server_config_file);
            if ($httpdconfig && (-e $httpdconfig) && ((-f $httpdconfig) || (-l $httpdconfig))) {
                last;
            }
        }
    }
    $acc ||= $httpd_root;

    # APACHE_SIGN
    my $sign = 0;
    if ($aver) {
        my $major = int($aver*1);
        my $minor = int(($aver - $major) * 100);
        $sign = ($major*10+$minor);
    }

    # APACHE_LOG_DIR
    my $alogdir = ($aver && $aver >= 2.04) ? '${APACHE_LOG_DIR}' : "logs";
    my @atlds = (
        File::Spec->catdir(CTK::Util::syslogdir(), "apache2"),
        File::Spec->catdir(CTK::Util::syslogdir(), "httpd"),
        File::Spec->catdir($acc, "logs"),
    );
    foreach my $ald (@atlds) {
        if (-e $ald) {
            $alogdir = $ald;
            last;
        }
    }

    %A2 = (
        HTTPD_ROOT          => $acc,
        SERVER_CONFIG_FILE  => $httpdconfig || '',
        SERVER_VERSION      => $sver,
        APACHE_VERSION      => $aver,
        APACHE_SIGN         => $sign,
        APACHE_LOG_DIR      => $alogdir,
    );
    return $key ? $A2{uc($key)} : {%A2};
}
sub getApache { goto &getApache2 }
sub to_void { goto &_void }
sub cleanProjectName {
    # Cleaning project name
    my $pn = _void(shift);
    $pn =~ s/[^a-z0-9_]/X/ig;
    return $pn;
}
sub cleanServerName {
    # Cleaning server name
    my $sn = _void(shift);
    $sn =~ s/[^a-z0-9_\-.]/X/ig;
    return $sn;
}
sub load_metadata {
    my $metaf = shift || '';
    my $meta = {};
    if ($metaf && -e $metaf) {
        if ($metaf =~ /\.ya?ml$/) {
            try {
                $meta = YAML::XS::LoadFile($metaf);
            } catch {
                carp(sprintf("Can't load META file %s: %s", $metaf, $_));
            };
        } elsif ($metaf =~ /\.json$/) {
            try {
                my $json_text = CTK::Util::bload($metaf, 1) // "";
                $meta = JSON::XS->new->decode($json_text);
            } catch {
                carp(sprintf("Can't load META file %s: %s", $metaf, $_));
            };
        } else {
            carp(sprintf("Incorrect META file format: %s", $metaf));
        }
    } else {
        carp(sprintf("Can't load META file %s", $metaf));
    }
    return %$meta;
}
sub back2slash {
    my $s = shift // return "";
    $s =~ s/\\/\//g;
    return $s;
}

sub _void {
    # Returns '' (void) if undef
    my $v = shift;
    return '' unless defined $v;
    return $v;
}

1;

__END__
