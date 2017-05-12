package Kolab::Conf;

##
##  Copyright (c) 2003  Code Fusion cc
##
##    Writen by Stuart Bingë  <s.binge@codefusion.co.za>
##    Portions based on work by the following people:
##
##      (c) 2003  Tassilo Erlewein  <tassilo.erlewein@erfrakon.de>
##      (c) 2003  Martin Konold     <martin.konold@erfrakon.de>
##      (c) 2003  Achim Frank       <achim.frank@erfrakon.de>
##
##
##  This  program is free  software; you can redistribute  it and/or
##  modify it  under the terms of the GNU  General Public License as
##  published by the  Free Software Foundation; either version 2, or
##  (at your option) any later version.
##
##  This program is  distributed in the hope that it will be useful,
##  but WITHOUT  ANY WARRANTY; without even the  implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You can view the  GNU General Public License, online, at the GNU
##  Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.
##

use 5.008;
use strict;
use warnings;
use IO::File;
use File::Copy;
use Kolab;
use Kolab::Util;
use Kolab::LDAP;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
        &buildPostfixTransportMap
        &buildCyrusConfig
        &buildCyrusGroups
        &rebuildTemplates
        %haschanged
    ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = sprintf('%d.%02d', q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub build {
    my $tmpl = shift;
    my $cfg = shift;
    my $prefix = $Kolab::config{'prefix'};

    my $TEMPLATE;
    if (!($TEMPLATE = IO::File->new($tmpl, 'r'))) {
        Kolab::log('T', "Unable to open template file `$tmpl'", KOLAB_ERROR);
        exit(1);
    }
    my @tempfile = ();

    while (<$TEMPLATE>) {
        if (/\@{3}(\S+)\@{3}/) {
            if ($Kolab::config{$1}) {
                s/\@{3}(\S+)\@{3}/$Kolab::config{$1}/g;
            } else {
                Kolab::log('T', "No configuration variable corresponding to `$1' exists", KOLAB_WARN);
                s/\@{3}(\S+)\@{3}//g;
            }
        }
        push (@tempfile, $_);
    }
    $TEMPLATE->close;

    my $configchanged = 0;
    my $CONFIGFILE;
    if (!($CONFIGFILE = IO::File->new($cfg, 'r'))) {
        Kolab::log('T', "Unable to open config file `$cfg'", KOLAB_ERROR);
        $configchanged = 1;	
    } else {
     
       my @configfile = <$CONFIGFILE>;
       $CONFIGFILE->close;
       undef $CONFIGFILE;

       if ($#configfile == $#tempfile) {
          foreach my $line (@tempfile) {
            my $configline = shift(@configfile);
            $configchanged = 1 if ($configline ne $line)
          }
       } else {
          $configchanged = 1;
       }
    }

    return 0 if ($configchanged ne 1);

    if ($configchanged) {
            Kolab::log('T', "`$cfg' change detected.", KOLAB_DEBUG);

	    if ($cfg =~ /postfix/) {
                $Kolab::haschanged{'postfix'} = 1;
            } elsif ($cfg =~ /saslauthd/) {
                $Kolab::haschanged{'saslauthd'} = 1;
            } elsif ($cfg =~ /apache/) {
                $Kolab::haschanged{'apache'} = 1;
            } elsif ($cfg =~ /proftpd/) {
                $Kolab::haschanged{'proftpd'} = 1;
            } elsif ($cfg =~ /openldap/) {
                $Kolab::haschanged{'slapd'} = 1;
            } elsif ($cfg =~ /imapd/) {
                $Kolab::haschanged{'imapd'} = 1;
            }
    }
    Kolab::log('T', "Creating new configuration file `$cfg' from template `$tmpl'");

    my $tmpfile = $prefix . '/etc/kolab/.tmp';
    unlink($tmpfile);
    my $NEWFILE;
    if ($cfg =~ /openldap/) {
      if (!($NEWFILE = IO::File->new($tmpfile, O_RDWR|O_CREAT|O_EXCL, 0600))) {
        Kolab::log('T', "Unable to open configuration file `$tmpfile'", KOLAB_ERROR);
        exit(1);
      }
    } else {
      if (!($NEWFILE = IO::File->new($tmpfile, O_RDWR|O_CREAT|O_EXCL, 0644))) {
        Kolab::log('T', "Unable to open configuration file `$tmpfile'", KOLAB_ERROR);
        exit(1);
      }
    }

    foreach my $line (@tempfile) {
       print $NEWFILE $line;
    }
    $NEWFILE->close;
    unlink($cfg);
    link($tmpfile,$cfg);
    unlink($tmpfile);
    chown($Kolab::config{'kolab_uid'}, $Kolab::config{'kolab_gid'}, $cfg);


    Kolab::log('T', "Finished creating configuration file `$cfg'");
}

sub buildPostfixTransportMap
{
    Kolab::log('T', 'Building Postfix transport map');

    my $prefix = $Kolab::config{'prefix'};
    my $cfg = "$prefix/etc/postfix/transport";
    my $oldcfg = $cfg . '.old';
    copy($cfg, $oldcfg);
    chown($Kolab::config{'kolab_uid'}, $Kolab::config{'kolab_gid'}, $oldcfg);
    copy("$prefix/etc/kolab/transport.template", $cfg);

    my $transport;
    if (!($transport = IO::File->new($cfg, 'a'))) {
        Kolab::log('T', 'Unable to create Postfix transport map', KOLAB_ERROR);
        exit(1);
    }

    my $ldap = Kolab::LDAP::create(
        $Kolab::config{'ldap_ip'},
        $Kolab::config{'ldap_port'},
        $Kolab::config{'bind_dn'},
        $Kolab::config{'bind_pw'}
    );

    my $mesg = $ldap->search(
        base    => $Kolab::config{'base_dn'},
        scope   => 'sub',
        filter  => '(objectclass=*)'
    );
    if ($mesg->code) {
        Kolab::log('T', 'Unable to locate Postfix transport map entries in LDAP', KOLAB_ERROR);
        exit(1);
    }

    my $ldapobject;
    if ($mesg->code <= 0) {
        foreach $ldapobject ($mesg->entries) {
            my $routes = $ldapobject->get_value('postfix-transport', asref => 1);
            foreach (@$routes) {
                $_ = trim($_);
                Kolab::log('T', "Adding SMTP route `$_'");
                print $transport $_ . "\n";
            }
        }
    } else {
        Kolab::log('T', 'No Postfix transport map entries found');
    }

    Kolab::LDAP::destroy($ldap);
    $transport->close;

    # FIXME: bad way of doing things...
    system("chown root.root $prefix/etc/postfix/*");
    system("$prefix/sbin/postmap $prefix/etc/postfix/transport");

    if (-f $oldcfg) {
        my $rc = `diff -q $cfg $oldcfg`;
        chomp($rc);
        if ($rc) {
           Kolab::log('T', "`$cfg' change detected: $rc", KOLAB_DEBUG);
           $Kolab::haschanged{'postfix'} = 1;
        }
    } else {
        $Kolab::haschanged{'postfix'} = 1;
    }

    Kolab::log('T', 'Finished building Postfix transport map');
}

sub buildCyrusConfig
{
    Kolab::log('T', 'Building Cyrus config');

    my $prefix = $Kolab::config{'prefix'};
    my $cyrustemplate;
    if (!($cyrustemplate = IO::File->new("$prefix/etc/kolab/cyrus.conf.template", 'r')))  {
        Kolab::log('T', "Unable to open template file `cyrus.conf.template'", KOLAB_ERROR);
        exit(1);
    }

    my $cfg = "$prefix/etc/imapd/cyrus.conf";
    my $oldcfg = $cfg . '.old';
    copy($cfg, $oldcfg);
    chown($Kolab::config{'kolab_uid'}, $Kolab::config{'kolab_gid'}, $oldcfg);

    my $cyrusconf;
    if (!($cyrusconf = IO::File->new($cfg, 'w'))) {
        Kolab::log('T', "Unable to open configuration file `$cfg'", KOLAB_ERROR);
        exit(1);
    }

    while (<$cyrustemplate>) {
        if (/\@{3}cyrus-imap\@{3}/ && ($Kolab::config{"cyrus-imap"} =~ /true/i)) {
            $_ = "imap cmd=\"imapd -C $prefix/etc/imapd/imapd.conf\" listen=\"143\" prefork=0\n";
        }
        elsif (/\@{3}cyrus-pop3\@{3}/ && ($Kolab::config{"cyrus-pop3"} =~ /true/i)) {
            $_ = "pop3 cmd=\"pop3d -C $prefix/etc/imapd/imapd.conf\" listen=\"110\" prefork=0\n";
        }
        elsif (/\@{3}cyrus-imaps\@{3}/ && ($Kolab::config{"cyrus-imaps"} =~ /true/i)) {
            $_ = "imaps cmd=\"imapd -s -C $prefix/etc/imapd/imapd.conf\" listen=\"993\" prefork=0\n";
        }
        elsif (/\@{3}cyrus-pop3s\@{3}/ && ($Kolab::config{"cyrus-pop3s"} =~ /true/i)) {
            $_ = "pop3s cmd=\"pop3d -s -C $prefix/etc/imapd/imapd.conf\" listen=\"995\" prefork=0\n";
        }
        elsif (/\@{3}cyrus-sieve\@{3}/ && ($Kolab::config{"cyrus-sieve"} =~ /true/i)) {
            $_ = "sieve cmd=\"timsieved -C $prefix/etc/imapd/imapd.conf\" listen=\"2000\" prefork=0\n";
        }
        $_ =~ s/\@{3}.*\@{3}//;
        print $cyrusconf $_;
    }

    $cyrustemplate->close;
    $cyrusconf->close;

    chown($Kolab::config{'kolab_uid'}, $Kolab::config{'kolab_gid'}, $cfg);

    if (-f $oldcfg) {
        my $rc = `diff -q $cfg $oldcfg`;
        chomp($rc);
        if ($rc) {
           Kolab::log('T', "`$cfg' change detected: $rc", KOLAB_DEBUG);
           $Kolab::haschanged{'imapd'} = 1;
        }
    } else {
        $Kolab::haschanged{'imapd'} = 1;
    }

    Kolab::log('T', 'Finished building Cyrus config');
}

sub buildCyrusGroups
{
    Kolab::log('T', 'Building Cyrus groups');

    my $prefix = $Kolab::config{'prefix'};
    my $cfg = "$prefix/etc/imapd/imapd.group";
    my $oldcfg = $cfg . '.old';
    copy($cfg, $oldcfg);
    chown($Kolab::config{'kolab_uid'}, $Kolab::config{'kolab_gid'}, $oldcfg);
    copy("$prefix/etc/kolab/imapd.group.template", $cfg);
    my $groupconf;
    if (!($groupconf = IO::File->new($cfg, 'a'))) {
        Kolab::log('T', "Unable to open configuration file `$cfg'", KOLAB_ERROR);
        exit(1);
    }

    my $ldap = Kolab::LDAP::create(
        $Kolab::config{'ldap_ip'},
        $Kolab::config{'ldap_port'},
        $Kolab::config{'bind_dn'},
        $Kolab::config{'bind_pw'}
    );

    my $mesg = $ldap->search(
        base    => $Kolab::config{'base_dn'},
        scope   => 'sub',
        filter  => '(objectclass=groupofnames)'
    );
    if ($mesg->code) {
        Kolab::log('T', 'Unable to locate Cyrus groups in LDAP', KOLAB_ERROR);
        exit(1);
    }

    my $ldapobject;
    my $count = 60000;
    if ($mesg->code <= 0) {
        foreach $ldapobject ($mesg->entries) {
            my $group = $ldapobject->get_value('cn') . ":*:$count:";
            my $userlist = $ldapobject->get_value('uid', asref => 1);
            foreach (@$userlist) { $group .= "$_,"; }
            $group =~ s/,$//;
            print $groupconf $group . "\n";
            Kolab::log('T', "Adding cyrus group `$group'");
            $count++;
        }
    } else {
        Kolab::log('T', 'No Cyrus groups found');
    }

    $groupconf->close;
    Kolab::LDAP::destroy($ldap);

    chown($Kolab::config{'kolab_uid'}, $Kolab::config{'kolab_gid'}, $cfg);

    if (-f $oldcfg) {
        my $rc = `diff -q $cfg $oldcfg`;
        chomp($rc);
        if ($rc) {
           Kolab::log('T', "`$cfg' change detected: $rc", KOLAB_DEBUG);
           $Kolab::haschanged{'imapd'} = 1;
        }
    } else {
        $Kolab::haschanged{'imapd'} = 1;
    }

    Kolab::log('T', 'Finished building Cyrus groups');
}

sub rebuildTemplates
{
    my $key;
    my $value;
    my $section="";

    my $prefix = $Kolab::config{'prefix'};

    my %templates = (
        "$prefix/etc/kolab/session_vars.php.template" => "$prefix/var/kolab/www/admin/include/session_vars.php",
        "$prefix/etc/kolab/main.cf.template" => "$prefix/etc/postfix/main.cf",
        "$prefix/etc/kolab/master.cf.template" => "$prefix/etc/postfix/master.cf",
        "$prefix/etc/kolab/saslauthd.conf.template" => "$prefix/etc/sasl/saslauthd.conf",
        "$prefix/etc/kolab/imapd.conf.template" => "$prefix/etc/imapd/imapd.conf",
        "$prefix/etc/kolab/httpd.conf.template" => "$prefix/etc/apache/apache.conf",
        "$prefix/etc/kolab/legacy.conf.template" => "$prefix/etc/apache/legacy.conf",
        "$prefix/etc/kolab/php.ini.template" => "$prefix/etc/apache/php.ini",
        "$prefix/etc/kolab/proftpd.conf.template" => "$prefix/etc/proftpd/proftpd.conf",
        "$prefix/etc/kolab/slapd.conf.template" => "$prefix/etc/openldap/slapd.conf"
    );

    Kolab::log('T', 'Regenerating configuration files');

    foreach $key (keys %templates) {
        build($key, $templates{$key});
    }

    buildPostfixTransportMap;
    buildCyrusConfig;
    buildCyrusGroups;

    Kolab::log('T', 'Finished regenerating configuration files');
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kolab::Conf - Perl extension for Kolab template generation

=head1 ABSTRACT

  Kolab::Conf handles the generation of template files, used by
  kolabconf.

=head1 AUTHOR

Stuart Bingë, E<lt>s.binge@codefusion.co.zaE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003  Code Fusion cc

Portions based on work by the following people:

  (c) 2003  Tassilo Erlewein  <tassilo.erlewein@erfrakon.de>
  (c) 2003  Martin Konold     <martin.konold@erfrakon.de>
  (c) 2003  Achim Frank       <achim.frank@erfrakon.de>

This  program is free  software; you can redistribute  it and/or
modify it  under the terms of the GNU  General Public License as
published by the  Free Software Foundation; either version 2, or
(at your option) any later version.

This program is  distributed in the hope that it will be useful,
but WITHOUT  ANY WARRANTY; without even the  implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You can view the  GNU General Public License, online, at the GNU
Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.

=cut
