package MToken::Command; # $Id: Command.pm 70 2019-06-09 18:25:29Z minus $
use strict;
use feature qw/say/;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Command - utilities to replace common UNIX commands in Makefiles etc.

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    perl -MMToken::Command -e COMMAND -- ARGUMENS

=head1 DESCRIPTION

Utilities to replace common UNIX commands in Makefiles etc.

=head2 add

    perl -MMToken::Command -e add -- 2017/07/03

Add file to Device

=head2 backupdelete

    perl -MMToken::Command -e backupdelete -- myfooproject.20170703

Remove backup file from remote server

=head2 backupupdate

    perl -MMToken::Command -e backupupdate -- backup/myfooproject.20170703

Update backup file on remote server

=head2 check

    perl -MMToken::Command -e check -- 2017/07/03

Check files on Device

=head2 config

    perl -MMToken::Command -e config -- PROJECTNAME

Configure the Device

=head2 cpgpgkey

    perl -MMToken::Command -e cpgpgkey -- certs/public.key
    perl -MMToken::Command -e cpgpgkey -- certs/private.key

Copy public or private key file to Device

=head2 decrypt

    perl -MMToken::Command -e decrypt -- *.asc .tar.gz

GPG decrypt files

=head2 del

    perl -MMToken::Command -e del

Remove file from Device

=head2 encrypt

    perl -MMToken::Command -e encrypt -- file.tar.gz file.asc

GPG encrypt file

=head2 fetch

    perl -MMToken::Command -e fetch -- backup/myfooproject.20170703

Download backup file from remote server

=head2 genkey

    perl -MMToken::Command -e genkey -- keys/myfooproject.key

Generate main key file for Device

=head2 gpgrecipient

    echo "<mail@example.com>" | perl -MMToken::Command -e gpgrecipient -- etc/gpg.conf

Get default recipient for GPG encrypting/decrypting

=head2 info

    perl -MMToken::Command -e info -- 20170731

Get information about actual backup file

=head2 list

    perl -MMToken::Command -e list

Get list of backup files on server

=head2 serverconfig

    perl -MMToken::Command -e serverconfig

Get configuration section for Apache2 server

=head2 show

    perl -MMToken::Command -e show

Show current list of the device content

=head2 store

    perl -MMToken::Command -e store -- backup/myfooproject.20170703

Send the backup file to remote server

=head2 untar

    perl -MMToken::Command -e untar -- restore/*.tar restore

Decompress downloaded backup from the server

=head2 update

    perl -MMToken::Command -e update -- 2017/07/03

Update backup file on server

=head1 HISTORY

See C<Changes> file

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION @EXPORT /;
$VERSION = "1.01";

use base qw/Exporter/;
@EXPORT = qw/
        config genkey store fetch list info backupdelete backupupdate
        gpgrecipient cpgpgkey untar
        serverconfig
        show check add update del
        encrypt decrypt
    /;

use Carp;
use CTK;
use CTK::Util qw/ :ALL /;
use CTK::TFVals qw/ :ALL /;
use CTK::Crypt::GPG;
use MToken::Const qw/ :GENERAL :CRYPT /;
use MToken::Util;
use MToken::Config;
use MToken::Client;
use Digest::MD5 qw/md5_hex/;
use File::Basename qw/basename/;
use File::Spec;
use File::Copy qw/cp mv/;
use URI;
use Archive::Extract;
use ExtUtils::Manifest qw/
        mkmanifest
        manicheck  filecheck  fullcheck  skipcheck
        manifind   maniread   manicopy   maniadd
        maniskip
    /;

use constant {
    VERBOSE => 0,
    RESERVED_NAMES => [qw/
            MANIFEST MANIFEST.SKIP
            LICENSE
            TODO
            DESCRIPTION
            Makefile.PL
            README
        /],
};

sub genkey {
    # Create random key file via openssl
    my $rndf = shift @ARGV || '';
    my $config = new MToken::Config;
    unless ($rndf) {
        $rndf = File::Spec->catfile(DIR_KEYS, sprintf("%s%s",$config->get("project") || PROJECT,KEYSUFFIX));
    }
    if (-e $rndf) {
        skip("File \"%s\" already exists", $rndf);
        return 1;
    }
    my $size = int(rand(KEYMAXSIZE - KEYMINSIZE))+KEYMINSIZE;

    my $opensslbin = $config->get("opensslbin");
    unless ($opensslbin) {
        say STDERR red("Can't find OpenSSL program. Please configure first this device");
        exit(1);
    }

    my $err = "";
    #my $cmd = [$opensslbin, "rand", sprintf("-out \"%s\"", $rndf), $size];
    my $cmd = [$opensslbin, "rand", "-out", $rndf, $size];
    say(join(" ", @$cmd));
    my $out = execute( $cmd, undef, \$err );
    say STDERR red($err) if $err;
    say cyan($out) if $out;

    # Check
    unless (-e $rndf) {
        say STDERR red(sprintf("File \"%s\" not created", $rndf));
        exit(1);
    }

    return 1;
}
sub config {
    my $prj = shift @ARGV || PROJECT;
    my $cgd = shift @ARGV;
    if ($cgd && -e $cgd) {
        skip("Device already configured. Run \"make reconfig\" for forced configuration");
        say(yellow("File already exists: %s", $cgd));
        return 1;
    }
    say "Start configuration device: $prj";

    #my $config = new MToken::Config( name => 'foo' );
    my $config = new MToken::Config;
    my %before = $config->getall;
    #say(MToken::Util::explain($config));

    # Internal use only
    my $c = new CTK(plugins => [qw/cli/]);

    # Check openssl
    my $opensslbin = $c->cli_prompt('OpenSSL program:', which($config->get("opensslbin") || OPENSSLBIN) || $config->get("opensslbin") || OPENSSLBIN);
    unless ($opensslbin) {
        say STDERR red("Program openssl not found. Please install it and try again later");
        exit(1);
    } else {
        my $cmd = [$opensslbin, "version"];
        say(join(" ", @$cmd));
        my $err = "";
        my $out = execute( $cmd, undef, \$err );
        say STDERR red($err) if $err;
        unless ($out) {
            say STDERR red("Program openssl not found. Please install it and try again later");
            exit(1);
        }
        unless ($out =~ /^OpenSSL\s+[1-9]\.[0-9]/m) {
            say STDERR yellow("OpenSSL Version is not correctly. May be some problems");
            say cyan($out);
        }
    }
    $config->set(opensslbin => $opensslbin);

    # Check GnuPG
    my $gpgbin = $c->cli_prompt('GnuPG (gpg) program:', which($config->get("gpgbin") || GPGBIN) || $config->get("gpgbin") || GPGBIN);
    unless ($gpgbin) {
        say STDERR red("Program GnuPG (gpg) not found. Please install it and try again later");
        exit(1);
    } else {
        my $cmd = [$gpgbin, "--version"];
        say(join(" ", @$cmd));
        my $err = "";
        my $out = execute( $cmd, undef, \$err );
        say STDERR red($err) if $err;
        unless ($out) {
            say STDERR red("FATAL ERROR: Program GnuPG (gpg) not found. Please install it and try again later");
            exit(1);
        }
        unless ($out =~ /^gpg\s+\(GnuPG\)\s+[2-9]\.[0-9]/m) {
            say STDERR yellow("GnuPG Version is not correctly. May be some problems");
            say cyan($out);
        }
    }
    $config->set(gpgbin => $gpgbin);

    # Server URL (server_url)
    say "";
    my $default_url = _get_default_url($prj);
    my $server_url = $c->cli_prompt('Server URL:', MToken::Util::hide_pasword($config->get("server_url") || $default_url, 1));
    my $uri = new URI( $server_url );

    # Server user & password
    if ($c->cli_prompt('Ask the credentials interactively (Recommended, t. It\'s safer)?:','yes') =~ /^\s*y/i) {
        $uri->userinfo(undef);
    } else {
        my ($server_user, $server_password) = MToken::Util::parse_credentials($uri);
        unless ($server_user) { # User
            $server_user = $c->cli_prompt('Server user:', "anonymous") // "";
            $server_user =~ s/%/%25/g;
            $server_user =~ s/:/%3A/g;
        }
        unless ($server_password) { # Password
            system("stty -echo") unless MSWIN;
            $server_password = $c->cli_prompt('Server password:') // "";
            $server_password =~ s/%/%25/g;
            system("stty echo") unless MSWIN;
            print STDERR "\n";  # because we disabled echo
        }
        $uri->userinfo(sprintf("%s:%s", $server_user, $server_password));
    }

    # Result
    my $url = $uri->canonical->as_string;
    say(cyan("Full server URL: %s", MToken::Util::hide_pasword($url)));
    unless ($c->cli_prompt('It is alright?:','yes') =~ /^\s*y/i) {
        nope("Aborted");
        exit(1);
    }
    $config->set(server_url => $url);

    # Hash Diff
    my %after = $config->getall;
    #say(Data::Dumper::Dumper({ before => {%before}, after => {%after} }));
    return skip("Nothing changed") if _hashmd5(%before) eq _hashmd5(%after);

    say "Current configuration:";
eval <<'FORMATTING';
    my ($kf,$vf);
    say "";
say "------------------------+-------------------------------------------------------";
format STDOUT_TOP =
                   Name | Value
------------------------+-------------------------------------------------------
.
format STDOUT =
 @>>>>>>>>>>>>>>>>>>>>> | @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$kf,$vf
.
    foreach my $k (sort {$a cmp $b} keys %after) {
        $kf = $k;
		my $tv = defined($after{$k}) ? $after{$k} : '';
		if ($k =~ /(^ur[il])|(ur[il]$)/i) {
			$vf = variant_stf(MToken::Util::hide_pasword($tv), 52);
		} else {
			$vf = variant_stf($tv, 52);
		}
        write;
    }
    say "";
FORMATTING

    if ($c->cli_prompt('Are you sure you want to save all changes to local configuration file?:','yes') =~ /^\s*y/i) {
        if ($config->save) {
            yep("File \"%s\" successfully saved", $config->get("local_conf_file"));
        } else {
            nope("Can't save file \"%s\"", $config->get("local_conf_file"));
            exit(1);
        }
    } else {
        skip("Aborted. File not saved");
    }

    1;
}
sub store {
    # Upload files
    _expand_wildcards();
    my @files = @ARGV;
    croak("Agrguments missing") unless @files;
    my $config = new MToken::Config;

    # Client
    my $client = new MToken::Client(
            url     => $config->get("server_url"),
            verbose => VERBOSE, # Show data pool
        );

    $client->check() or do {
        nope($client->transaction);
        say STDERR red($client->error);
        say STDERR $client->trace;
        exit(1);
    };

    # Send file
    my $retstat = 1;
    foreach my $file (@files) {
        my $filename = basename($file);
        printf("Sending file %s to %s...\n", $filename, $client->{uri}->host_port);
        if (-f $file) {
            unless ($client->upload($file)) {
                nope($client->transaction);
                say STDERR red($client->error);
                say STDERR $client->trace;
                $retstat = 0;
                next;
            }
            yep($client->transaction);
        } else { # Skipped
            skip("It is not file")
        }
    }
    exit(1) unless $retstat;
    return $retstat;
}
sub fetch {
    # Downlod files
    _expand_wildcards();
    my @files = @ARGV;
    my $dir = shift @files;
    croak("Agrguments missing") unless $dir;
    croak("Directory incorrect") unless (-d $dir or -l $dir);

    # Internal use only
    my $c = new CTK(plugins => [qw/cli/]);
    my $f = '';
    unless (@files) {
        # Try input FileName
        $f = MToken::Util::cleanFileName(
            $c->cli_prompt('Please type filename for fetching from server or (last, all):', "last")
        );
    }
    unless ($f or @files) {
        nope("Incorrect filename for fetching");
        exit(1);
    }

    my $config = new MToken::Config;
    my $distname = $config->get("distname");

    # Set URI & URL
    my $client = new MToken::Client(
            url     => $config->get("server_url"),
            verbose => VERBOSE, # Show data pool
        );

    $client->check() or do {
        nope($client->transaction);
        say STDERR red($client->error);
        say STDERR $client->trace;
        exit(1);
    };

    my @list; # File list from server
    if ($f && $f eq 'all') { # All files
        @list = $client->list($distname);
    } elsif ($f && $f eq 'last') { # Last file only
        @list = sort { ($b->{date_sfx} || 0) <=> ($a->{date_sfx} || 0) } ($client->list($distname));
        splice(@list,1)
    } elsif ($f) { # Specified file
        @list = $client->list($f);
    } else { # From args
        foreach my $l ($client->list($distname)) {
            push @list, $l if grep { $_ && $l->{filename} && basename($_) eq $l->{filename} } @files;
        }
    }

    # Download files
    my $retstat = 1;
    foreach my $l (@list) {
        my $filename = $l->{filename};
        unless ($filename) {
            nope("Filename incorrect");
            next;
        }
        my $file = File::Spec->catfile($dir, $filename);
        printf("Downloading file %s from %s...\n", $filename, $client->{uri}->host_port);
        if (my $msg = $client->download($file)) {
            my $in_md5 = $l->{md5};
            if ($in_md5) {
                my $out_md5 = MToken::Util::md5sum($file) || '';
                unless ($in_md5 eq $out_md5) {
                    nope("File md5sum mismatch: Expected: %s; Got: %s", $in_md5, $out_md5);
                    $retstat = 0;
                }
            }
            my $in_sha1 = $l->{sha1};
            if ($in_sha1) {
                my $out_sha1 = MToken::Util::sha1sum($file);
                unless ($in_sha1 eq $out_sha1) {
                    nope("File sha1sum mismatch: Expected: %s; Got: %s", $in_sha1, $out_sha1);
                    $retstat = 0;
                }
            }
            if ($retstat) {
                yep($msg);
            }
        } else {
            nope($client->transaction);
            say STDERR red($client->error);
            say STDERR $client->trace;
            $retstat = 0;
        }
    }
    exit(1) unless $retstat;
    return $retstat;
}
sub list {
    my $config = new MToken::Config;
    my $distname = $config->get("distname");
    my $client = new MToken::Client(
            url     => $config->get("server_url"),
            verbose => VERBOSE, # Show data pool
        );
    $client->check() or do {
        nope($client->transaction);
        say STDERR red($client->error);
        say STDERR $client->trace;
        exit(1);
    };

    my @list = sort { ($b->{date_sfx} || 0) <=> ($a->{date_sfx} || 0) } ($client->list($distname));
    unless ($client->status) {
        nope($client->transaction);
        say STDERR red($client->error);
        say STDERR $client->trace;
        exit(1);
    }
    return skip("No files found") unless scalar(@list);

eval <<'FORMATTING';
    my @arr;
    my $total = 0;
    my $totalf = "";
    say "";
say "----------+---------------------------------+------------+--------------";
format STDOUT_TOP =
 ID (SFX) | FileName                        | Date       | Size (bytes)
----------+---------------------------------+------------+--------------
.
format STDOUT =
 @<<<<<<< | @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | @<<<<<<<<< | @>>>>>>>>>>>
@arr
.
format STDOUTBOT =
----------+---------------------------------+------------+--------------
@>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> bytes
$totalf
.
    foreach my $f (@list) {
        @arr = ();
        push @arr, $f->{date_sfx} || 0;
        push @arr, variant_stf($f->{filename} || '', 30);
        push @arr, $f->{date_fmt} || '';
        push @arr, correct_number($f->{size} || 0);
        $total += ($f->{size} || 0);
        write;
    }
    $~ = "STDOUTBOT";
    $totalf = correct_number($total);
    write;
    say "";
FORMATTING
    return 1;
}
sub info {
    my @in = @ARGV;
    my $fnorid = shift @in;
    croak("Agrguments missing") unless $fnorid;
    my $config = new MToken::Config;
    my $client = new MToken::Client(
            url     => $config->get("server_url"),
            verbose => VERBOSE, # Show data pool
        );
    $client->check() or do {
        nope($client->transaction);
        say STDERR red($client->error);
        say STDERR $client->trace;
        exit(1);
    };

    my %info = $client->info($fnorid);
    unless ($client->status) {
        nope($client->transaction);
        say STDERR red($client->error);
        say STDERR $client->trace;
        exit(1);
    }
    return skip("File not found") unless %info;

eval <<'FORMATTING';
    my ($kf,$vf);
    say "";
say "----------------+---------------------------------------------------------------";
format STDOUT_TOP =
           Name | Value
----------------+---------------------------------------------------------------
.
format STDOUT =
 @>>>>>>>>>>>>> | @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$kf,$vf
.
    foreach my $k (qw/ date_sfx filename file date_fmt size md5 sha1 /) {
        $kf = $k;
        if ($k eq 'size') {
            $vf = sprintf("%s bytes", correct_number($info{$k} || 0));
        } else {
            $vf = variant_stf((defined($info{$k}) ? $info{$k} : ''), 60);
        }
        write;
    }
    say "";
FORMATTING
    return 1;
}
sub backupdelete {
    _expand_wildcards();
    my @files = @ARGV;
    croak("Agrguments missing") unless @files;
    my $config = new MToken::Config;

    # Client
    my $client = new MToken::Client(
            url     => $config->get("server_url"),
            verbose => VERBOSE, # Show data pool
        );

    $client->check() or do {
        nope($client->transaction);
        say STDERR red($client->error);
        say STDERR $client->trace;
        exit(1);
    };

    # Delete files
    my $retstat = 1;
    foreach my $file (@files) {
        my $filename = basename($file);
        printf("Deleting backup file %s from %s...\n", $filename, $client->{uri}->host_port);
        unless ($client->remove($file)) {
            nope($client->transaction);
            say STDERR red($client->error);
            say STDERR $client->trace;
            $retstat = 0;
            next;
        }
        yep($client->transaction);
    }
    exit(1) unless $retstat;
    return $retstat;
}
sub backupupdate {
    _expand_wildcards();
    my @files = @ARGV;
    croak("Agrguments missing") unless @files;
    my $config = new MToken::Config;

    # Client
    my $client = new MToken::Client(
            url     => $config->get("server_url"),
            verbose => 0, # VERBOSE, # --disabled! binary data!
        );

    $client->check() or do {
        nope($client->transaction);
        say STDERR red($client->error);
        say STDERR $client->trace;
        exit(1);
    };

    # Updating files
    my $retstat = 1;
    foreach my $file (@files) {
        my $filename = basename($file);
        printf("Update backup file %s on %s...\n", $filename, $client->{uri}->host_port);
        if (-f $file) {
            unless ($client->update($file)) {
                nope($client->transaction);
                say STDERR red($client->error);
                say STDERR $client->trace;
                $retstat = 0;
                next;
            }
            yep($client->transaction);
        } else { # Skipped
            skip("It is not file")
        }
    }
    exit(1) unless $retstat;
    return $retstat;
}
sub gpgrecipient {
    # Get recipient from stdin and replace default-recipient in file
    my $fn = shift(@ARGV);
    croak("Destination file is not specified") unless $fn;

    # Get recipient from STDIN
    my $pool = scalar(do{local $/ = undef; <STDIN>}) // "";
    #say(blue($pool));

    # Cut a recipient
    my $recipient = $1 if $pool =~ /^\s+\b([0-9A-F]+)\b/m;
    $recipient //= "";
    unless($recipient) {
        nope("Can't get recipient from input pool");
        say cyan($pool);
        exit(1);
    }

    # Get data from file and replacing
    my $data = fload($fn);
    $data =~ s/^\s*default-recipient.+$//gm;
    $data .= sprintf("\ndefault-recipient %s\n", $recipient);
    $data =~ s/\n{2,}/\n/sg;

    # Save file
    unless (fsave($fn, $data)) {
        nope("Can't save file %s", $fn);
        exit(1);
    }
    return yep("Found recipient: %s", $recipient);
}
sub cpgpgkey {
    # Copy GPG public and private key files from user directory to standard token-directory (certs)
    my $dst = shift @ARGV;
    croak("Destination file is not specified") unless $dst;
    return skip("Destination file $dst already exists") if -e $dst;

    # Internal use only
    my $c = new CTK(plugins => [qw/cli/]);
	my $dflt = File::Spec->catfile(DIR_KEYS, $dst =~ /priv/ ? MY_PRIVATE_KEY : MY_PUBLIC_KEY);
    my $src = $c->cli_prompt('Please type full path to file:', $dflt);

    unless ($src) {
        nope("Incorrect path to key file");
        exit(1);
    }
    unless (-f $src and -r _) {
        nope("File is not exists. Try again");
        exit(1);
    }
    unless (cp($src, $dst)) {
        nope("Can't copy file: %s", $!);
        exit 1;
    }

    return yep("File has been successfully copied to %s", $dst);
}
sub untar {
    _expand_wildcards();
    my @files = @ARGV;
    my $directory = pop @files;
    croak("Directory incorrect") unless $directory;
    croak("No files. Missing arguments") unless @files;

    my $retstat = 1;
    foreach my $file (@files) {
        next unless -f $file;
        my $dir = $1 if $file =~ /\.(\d{8})\./;
        unless ($dir) {
            skip("Incorrect file %s", $file);
            next;
        }
        my $ae = Archive::Extract->new( archive => $file );
        unless ($ae->extract( to => File::Spec->catdir($directory, $dir) )) {
            nope("Error extract files from $file");
            say STDERR red($ae->error);
            $retstat = 0;
            next;
        }
        unlink($file);
        yep("Untar file %s to %s", $file, $dir);
    }
    exit(1) unless $retstat;
    return $retstat;
}
sub serverconfig {
    my $config = new MToken::Config;
    my $pool = "";

    if (MSWIN) {
$pool = <<'EOP';
# Configuration section for Apache 2.2 or latest (Windows platforms)
<VirtualHost *:[SERVER_PORT]>
    ServerName [SERVER_HOST]
    #DocumentRoot C:\\Apache2\\www

    Options All
    AddDefaultCharset utf-8

    <Location [SERVER_PATH]>
       SetHandler modperl
       PerlResponseHandler MToken::Server
       #PerlSetVar Debug 1
       PerlSetVar MTokenDir "[SERVER_DIR]"

       AuthName "MToken Server"
       AuthType Basic
       AuthUserFile  "[SERVER_DIR]\\.htpasswd"
       require valid-user

    </Location>
</VirtualHost>

# Please also create follow file:
#   [SERVER_DIR]\\.htpasswd:
# And add string:
#   [SERVER_SS]
EOP
    } else {
$pool = <<'EOP';
# Configuration section for Apache 2.2 or latest
<VirtualHost *:[SERVER_PORT]>
    ServerName [SERVER_HOST]
    #DocumentRoot /var/www

    Options All
    AddDefaultCharset utf-8

    <Location [SERVER_PATH]>
       SetHandler modperl
       PerlResponseHandler MToken::Server
       #PerlSetVar Debug 1
       PerlSetVar MTokenDir [SERVER_DIR]

       AuthName "MToken Server"
       AuthType Basic
       AuthUserFile  [SERVER_DIR]/.htpasswd
       require valid-user

    </Location>
</VirtualHost>

# Please also create follow file:
#   [SERVER_DIR]/.htpasswd:
# And add string:
#   [SERVER_SS]
EOP
    }
    my $uri = _mk_uri($config->get("server_url"));
    my ($suser, $spass) = MToken::Util::parse_credentials($uri);
    my $ss = sprintf("%s:%s", $suser, $spass);

    my $htpasswd = which('htpasswd');
    if ($htpasswd) {
        my $err = "";
        my $cmd = [$htpasswd, "-nb", $suser, $spass];
        my $out = execute( $cmd, undef, \$err );
        if ($err) {
            say STDERR join(" ", @$cmd);
            say STDERR red($err)
        }
        if ($out) {
            chomp $out;
            $ss = $out;
        }
    }

    print dformat($pool, {
        SERVER_HOST => $uri->host,
        SERVER_PORT => $uri->port || ($uri->secure ? 443 : 80),
        SERVER_PATH => $uri->path || "/",
        SERVER_DIR  => File::Spec->catfile(webdir(), $uri->host),
        SERVER_SS   => $ss,
    });
}
sub show {
    # Manifest
    my $manifest = maniread(); # Текущий манифест файл => коментарий
    my $rnames = RESERVED_NAMES;
    foreach my $f (keys %$manifest) {
        delete $manifest->{$f} if grep {$_ eq $f} @$rnames;
    }
    if (keys %$manifest) {
        say "Current device structure (without system files):";
        _show_list($manifest);
    } else {
        return nope("No files in manifest. Please initialize your device correctly");
    }
    return 1;
}
sub check {
    # less /usr/share/perl/5.22.2/ExtUtils/Manifest.pm
    my $date_fmt = shift(@ARGV) || dtf("%YYYY/%MM/%DD", time());
    my $status = _check_date($date_fmt);

    # Missing files
    my @missing = manicheck(); # Отсутствующие файлы на диске но есть в манифесте
    if (@missing) {
        $status = 0;
        say "Missing files:";
        my %tmp = ();
        $tmp{$_} = '' for @missing;
        _show_list(\%tmp);
    }

    _show_extra();

    # Manifest
    # my $found    = manifind(); # Список вообще всех файлов
    my $manifest = maniread(); # Текущий манифест файл => коментарий
    if (keys %$manifest) {
        say "Manifest:";
        _show_list($manifest);
    } else {
        say STDERR red("No files in manifest. Please initialize your device correctly");
        $status = 0;
    }

    # Checking MD5 conflicts
    foreach my $k (keys %$manifest) {
        my $comment = $manifest->{$k} || '';
        my $date = $1 if $comment =~ /(\d{4}\/\d{2}\/\d{2})/; $date ||= $date_fmt;
        my $md5  = $1 if $comment =~ /([a-f0-9]{32})/i;
        next unless $md5;
        my $realf = File::Spec->catfile(split(/\//, $k));
        next unless -f $realf and -r _;
        my $got = MToken::Util::md5sum($realf) || '';
        next if lc($md5) eq lc($got);

        $status = 0;
        say STDERR red("MD5 Conflict for file: %s", $k);
        say STDERR red("  Got      : %s", $got); # Got : 745cb2db6dbc5ec03dade96ccbc51628 (получил)
        say STDERR red("  Expected : %s", $md5); # Expected : 745cb2db6dbc5ec03dade96ccbc51629 (ожидал)
        print STDERR "\n";
    }

    exit(1) unless $status;
    return 1;
}
sub add {
    my $date_fmt = shift(@ARGV) || dtf("%YYYY/%MM/%DD", time());
    _check_date($date_fmt);

    # Internal use only
    my $c = new CTK(plugins => [qw/cli/]);

    my $n = _show_extra();
    return skip("Nothing to add. Please first copy physical file for adding") unless $n;

    # Добавление единственного файла, _add(1)
    return _add(1, $date_fmt) if $n == 1; # 1
    my $sel = $c->cli_prompt(sprintf("Please type file's NNN (%d-%d) or (all, cancel):", 1, $n), "cancel");
    if ($sel && is_int($sel) && ($sel > 0) && ($sel <= $n)) { # NNN
        # Добавление конкретного файла, _add($sel)
        return _add($sel, $date_fmt);
    } elsif ($sel && $sel =~ /all/i) { # All
        # Добавление всех файлов, _addall
        return _addall($date_fmt);
    } elsif ($sel && $sel =~ /cancel/i) { # Cancel
        return skip("Aborted");
    } else { # Other
        return nope("Incorrect answer. Try again");
    }
}
sub update {
    my $date_fmt = shift(@ARGV) || CTK::dtf("%YYYY/%MM/%DD", time());
    _check_date($date_fmt);

    # Manifest
    my $manifest = maniread(); # Текущий манифест файл => коментарий
    return skip("No files in manifest. Please initialize your device correctly") unless keys %$manifest;

    # Checking MD5 conflicts
    my $rnames = RESERVED_NAMES;
    my %updates = ();
    foreach my $k (keys %$manifest) {
        next if grep {$_ eq $k} @$rnames;
        my $comment = $manifest->{$k} || '';
        my $date = $1 if $comment =~ /(\d{4}\/\d{2}\/\d{2})/; $date ||= "";
        my $md5  = $1 if $comment =~ /([a-f0-9]{32})/i; $md5 ||= "";

        my $realf = File::Spec->catfile(split(/\//, $k));
        unless (-f $realf and -r _) {
            $updates{$k} = ''; # DELETE
            skip("Missing file %s", $k);
            next;
        }

        # Check date and md5
        my $got_md5 = MToken::Util::md5sum($realf) || '';
        next if $date && lc($md5) eq lc($got_md5);

        $updates{$k} = sprintf("\%s\t%s", $got_md5, $date_fmt);
        yep("Updated metadata for %s", $k);
    }
    if (%updates) {
        if (ExtUtils::Manifest::maniupdate(\%updates)) {
            yep("Device successfully updated");
        } else {
            nope("Can't update device");
        }
    } else {
        skip("Device no need to update");
    }
    say("");

    return 1;
}
sub del {
    # Internal use only
    my $c = new CTK(plugins => [qw/cli/]);

    # Manifest (without system files)
    # my $found    = manifind(); # Список вообще всех файлов
    my $manifest = maniread(); # Текущий манифест файл => коментарий
    my $rnames = RESERVED_NAMES;
    foreach my $f (keys %$manifest) {
        delete $manifest->{$f} if grep {$_ eq $f} @$rnames;
    }
    my @files = sort { lc $a cmp lc $b } keys %$manifest;
    if (@files) {
        say "Manifest (without system files):";
        _show_list($manifest);
    } else {
        return skip("No files in manifest. Add files first");
    }

    my $n = scalar(@files);
    my $sel = $c->cli_prompt(sprintf("Please type file's NNN (%d-%d) or (all, cancel):", 1, $n), "cancel");
    if ($sel && is_int($sel) && ($sel > 0) && ($sel <= $n)) { # NNN
        # Удаление конкретного файла
        my $file = $files[$sel - 1];
        my $realf = File::Spec->catfile(split(/\//, $file));
        unless ($file) {
            nope("File not specified or incorrect");
            exit(1);
        }
        unless ($c->cli_prompt(sprintf("Are you sure you want to remove \"%s\" file?:", $file),'no') =~ /^\s*y/i) {
            return skip("Aborted");
        }
        say(sprintf("Deleting %s...", $file));
        unless (-f $realf && -w _) {
            nope("File not exists or locked for writing");
            exit(1);
        }
        unless (unlink($realf)) {
            nope("Can't remove file: $!");
            exit(1);
        }
        if (ExtUtils::Manifest::maniupdate({$file, ''})) {
            yep("Device successfully updated");
        } else {
            nope("Can't update device");
            exit(1);
        }
    } elsif ($sel && $sel =~ /all/i) { # All
        unless ($c->cli_prompt('Are you sure you want to remove all device files?:','no') =~ /^\s*y/i) {
            return skip("Aborted");
        }
        my %dels;
        foreach my $file (@files) {
            my $realf = File::Spec->catfile(split(/\//, $file));
            say(sprintf("Deleting %s...", $file));
            unless (-f $realf && -w _) {
                nope("File not exists or locked for writing");
                next;
            }
            unless (unlink($realf)) {
                nope("Can't remove file: $!");
                next;
            }
            $dels{$file} = "";
        }
        if (ExtUtils::Manifest::maniupdate({%dels})) {
            yep("Device successfully updated");
        } else {
            nope("Can't update device");
            exit(1);
        }
    } elsif ($sel && $sel =~ /cancel/i) { # Cancel
        return skip("Aborted");
    } else { # Other
        return nope("Incorrect answer. Try again");
    }

    return 1;
}
sub encrypt {
    my $src = shift @ARGV;
    my $dst = shift @ARGV;
    croak("Incorrect source file") unless $src && (-f $src) && (-r $src);
    croak("Destination file is not specified") unless $dst;

    my $gpg = new CTK::Crypt::GPG(
        -publickey => File::Spec->catfile(DIR_KEYS, PUBLIC_GPG_KEY),
    );
    unless ($gpg) {
        nope("Can't create CTK::Crypt::GPG object");
        exit(1);
    }

    $gpg->encrypt(
        -infile => $src,
        -outfile=> $dst,
        -armor  => "yes",
    ) or do {
        nope("GPG encrypt error");
        say(red($gpg->error)) if $gpg->error;
        exit(1);
    };
    return yep("Encrypted")
}
sub decrypt {
    _expand_wildcards();
    my @files = @ARGV;
    my $suffix = pop @files;
    croak("Suffix incorrect") unless $suffix;
    croak("No files. Missing arguments") unless @files;

    my $gpg = new CTK::Crypt::GPG(
        -privatekey => File::Spec->catfile(DIR_KEYS, PRIVATE_GPG_KEY),
    );
    unless ($gpg) {
        nope("Can't create CTK::Crypt::GPG object");
        exit(1);
    }

    my $retstat = 1;
    foreach my $file (@files) {
        next unless -f $file;
        next if $file =~ /^\./;
        next if $file =~ /tar\.\w+$/;
        my $src = sprintf("%s%s.gpg", $file, $suffix);
        my $dst = sprintf("%s%s", $file, $suffix);
        if (mv($file, $src)) {
            $gpg->decrypt(
                -infile => $src,
                -outfile=> $dst,
            ) or do {
                nope("GPG decrypt error");
                say(red($gpg->error)) if $gpg->error;
                $retstat = 0;
                next;
            };
            yep("Decripted %s", $dst);
        } else {
            nope("Can't move file %s to %s: %s", $file, $src, $!);
        }
    }

    #say(MToken::Util::explain($gpg));
    exit(1) unless $retstat;
    return $retstat;
}

#####################
# Internal functions
#####################
sub _expand_wildcards {
    # Original in package ExtUtils::Command
    @ARGV = map(/[*?]/o ? glob($_) : $_, @ARGV);
}
sub _hashmd5 {
    my %h = @_ ;
    my $s = "";
    foreach my $k (sort {$a cmp $b} (keys(%h))) { $s .= uv2null($h{$k}) }
    return "" unless $s;
    return md5_hex($s);
}
sub _mk_uri {
    # URI constructor
    my $url = shift || DEFAULT_URL; # $config->get("server_url")
    my $uri = new URI( $url );
    return $uri;
}
sub _get_default_url {
    my $project = shift || PROJECT;
    my $uri = new URI( DEFAULT_URL );
    $uri->scheme('https');
    $uri->host(HOSTNAME);
    $uri->path($project);
    return $uri->canonical->as_string;
}
sub _show_list {
my $struct = shift;
return unless $struct && ref($struct) eq 'HASH';
eval <<'FORMATTING';
my $total = 0;
my $totalf = "";
my @arr;

say "-----+------------------------------------------+------------+--------------";
format STDOUT_TOP =
 NNN | File                                     | Added on   | Size (bytes)
-----+------------------------------------------+------------+--------------
.
format STDOUT =
 @>> | @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | @<<<<<<<<< | @>>>>>>>>>>>
@arr
.
format STDOUTBOT =
-----+------------------------------------------+------------+--------------
@>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> bytes
$totalf
.

#$% = 0;
local $= = scalar(keys(%$struct)) + 4;
local $^L = '';

my $i = 0;
foreach my $k (sort { lc $a cmp lc $b } keys %$struct) {
    @arr = ();
    push @arr, ++$i; # NNN
    push @arr, variant_stf($k || '', 40); # File
    my $comment = $struct->{$k} || '';
    my $datef = $1 if $comment =~ /(\d{4}\/\d{2}\/\d{2})/; $datef ||= "";
    push @arr, $datef; # Date
    my $realf = File::Spec->catfile(split(/\//, $k));
    my $fs = (-f $realf and -r _) ? (-s _) : 0; # File size
    $total += ($fs || 0);
    push @arr, correct_number($fs || 0);
    write;
}
local $~ = "STDOUTBOT";
$totalf = correct_number($total);
write;
say "";
FORMATTING
warn $@."\n" if $@;
}
sub _check_date {
    my $date_fmt = shift;
    croak("Incorrect date format") unless $date_fmt && $date_fmt =~ /^\d{4}\/\d{2}\/\d{2}$/;

    # Date conflict
    my $cur_fmt = dtf("%YYYY/%MM/%DD", time());
    unless ($date_fmt eq $cur_fmt) {
        say STDERR red("Makefile too old. Please run first follows commands:\n\tmake clean\n\tperl Makefile.PL\n");
        exit(1);
    }
    return 1;
}
sub _show_extra {
    # Extraneous files
    my @extra = filecheck(); # Отсутствующие файла в манифесте но есть на диске
    if (@extra) {
        say "Extraneous files:";
        my %tmp = ();
        $tmp{$_} = '' for @extra;
        _show_list(\%tmp);
    } else {
        return 0;
    }
    return scalar(@extra);
}
sub _add {
    my $n = shift || return 0;
    my $d = shift || '';

    # Internal use only
    my $c = new CTK(plugins => [qw/cli/]);

    # Extraneous files
    my @extra = filecheck(); # Отсутствующие файла в манифесте но есть на диске
    return skip("No files for add") unless @extra;

    my $sel = "";
    my $i = 0;
    foreach (@extra) {
        $i++;
        $sel = $_ if $i == $n;
    }
    return skip("File not selected") unless $sel;

    say(cyan("Selected file for adding:"));
    say(cyan("  File : %s", $sel));
    my $realf = File::Spec->catfile(split(/\//, $sel));
    my $fs = (-f $realf and -r _) ? (-s _) : 0; # File size
    say(cyan("  Size : %s bytes", correct_number($fs || 0)));
    say(cyan("  Date : %s", $d));
    my $md5 = MToken::Util::md5sum($realf);
    say(cyan("  MD5  : %s", $md5));
    my $sha1 = MToken::Util::sha1sum($realf);
    say(cyan("  SHA1 : %s", $sha1));
    return skip("Aborted") unless $c->cli_prompt('Are you sure you want to add this file?:','no') =~ /^\s*y/i;

    my $comment = sprintf("\%s\t%s", $md5, $d);
    return nope("Can't add file") unless maniadd({$sel, $comment});
    return yep("Done");
}
sub _addall {
    my $d = shift || '';

    # Extraneous files
    my @extra = filecheck(); # Отсутствующие файла в манифесте но есть на диске
    return skip("No files for add") unless @extra;

    foreach my $f (@extra) {
        my $realf = File::Spec->catfile(split(/\//, $f));
        my $comment = sprintf("\%s\t%s", MToken::Util::md5sum($realf), $d);
        if (maniadd({$f, $comment})) {
            yep("File %s successfully added", $f);
        } else {
            nope("Can't add file %s", $f);
        }
    }
    return 1;
}

1;

#
# External functions
#
package  # hide me from PAUSE
    ExtUtils::Manifest;
sub maniupdate {
    my($additions) = shift;
    my $manifile = $ExtUtils::Manifest::MANIFEST;

    _normalize($additions);
    _fix_manifest($manifile);

    my $manifest = maniread();
    my @needed = grep { exists $manifest->{$_} } keys %$additions;
    return 1 unless @needed;

    open(MANIFEST, ">", $manifile) or
      die "maniupdate() could not open $manifile: $!";
    binmode MANIFEST, ':raw';

    foreach my $file (@needed) {
        $manifest->{$file} = $additions->{$file} || '';
    }
    foreach my $file (_sort(keys(%$manifest))) {
        my $realf = File::Spec->catfile(split(/\//, $file));
        next unless -f $realf and -r _;
        my $cmt = $manifest->{$file} || '';
        if ($file =~ /\s/) {
            $file =~ s/([\\'])/\\$1/g;
            $file = "'$file'";
        }
        if ($cmt) {
            printf MANIFEST "%-40s %s\n", $file, $cmt;
        } else {
            printf MANIFEST "%s\n", $file;
        }
    }
    close MANIFEST or die "Error closing $manifile: $!";
    return 1;
}

1;

__END__
