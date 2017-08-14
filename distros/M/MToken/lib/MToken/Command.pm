package MToken::Command; # $Id: Command.pm 44 2017-07-31 14:44:24Z minus $
use strict;
use feature qw/say/;

=head1 NAME

MToken::Command - utilities to replace common UNIX commands in Makefiles etc.

=head1 VIRSION

Version 1.00

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

=head2 del

    perl -MMToken::Command -e del

Remove file from Device

=head2 fetch

    perl -MMToken::Command -e fetch -- backup/myfooproject.20170703

Download backup file from remote server

=head2 genkey

    perl -MMToken::Command -e genkey -- keys/myfooproject.key

Generate main key file for Device

=head2 gpgfileprepare

    perl -MMToken::Command -e gpgfileprepare -- restore/* .tar.gz.gpg

Rename file downloaded file

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

See C<CHANGES> file

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/ $VERSION @EXPORT /;
$VERSION = "1.00";

use base qw/Exporter/;
@EXPORT = qw/
        config genkey store fetch list info backupdelete backupupdate
        cpgpgkey gpgrecipient gpgfileprepare untar
        serverconfig
        show check add update del
    /;

use CTK qw/ :NONE /;
use CTK::Util;
use CTK::TFVals qw/ :ALL /;
use MToken::Const qw/ :GENERAL :CRYPT /;
use MToken::Util;
use MToken::Config;
use MToken::Client;
use Digest::MD5 qw/md5_hex/;
use File::Basename qw/basename/;
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
    DEBUG   => 0,
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
        $rndf = catfile(DIR_KEYS, sprintf("%s%s",$config->get("project") || PROJECT,KEYSUFFIX));
    }
    if (-e $rndf) {
        say(sprintf("Skipped. File \"%s\" already exists", $rndf));
        return 1;
    }
    my $size = int(rand(KEYMAXSIZE - KEYMINSIZE))+KEYMINSIZE;

    my $opensslbin = $config->get("opensslbin");
    unless ($opensslbin) {
        croak("Can't find OpenSSL program. Please configure first this device");
    }

    my $err = "";
    #my $cmd = [$opensslbin, "rand", sprintf("-out \"%s\"", $rndf), $size];
    my $cmd = [$opensslbin, "rand", "-out", $rndf, $size];
    say(join(" ", @$cmd));
    my $out = execute( $cmd, undef, \$err );
    carp $err if $err;
    say $out if $out;

    # Check
    unless (-e $rndf) {
        croak(sprintf("FATAL ERROR: File \"%s\" not created"), $rndf);
    }

    return 1;
}
sub config {
    my $prj = shift @ARGV || PROJECT;
    my $cgd = shift @ARGV;
    if ($cgd && -e $cgd) {
        say(sprintf("File already exists: %s", $cgd));
        say("Skipped. Device already configured. Run \"make reconfig\" for forced configuration");
        return 1;
    }
    say "Start configuration device: $prj";

    #my $config = new MToken::Config( name => 'foo' );
    my $config = new MToken::Config;
    my %before = $config->getall;
    #say(Data::Dumper::Dumper($config));

    # Internal use only
    my $c = new CTK;

    # Check openssl
    my $opensslbin = $c->cli_prompt('OpenSSL program:', which($config->get("opensslbin") || OPENSSLBIN) || $config->get("opensslbin") || OPENSSLBIN);
    unless ($opensslbin) {
        croak("FATAL ERROR: Program openssl not found. Please install it and try again later");
    } else {
        my $cmd = [$opensslbin, "version"];
        say(join(" ", @$cmd));
        my $err = "";
        my $out = execute( $cmd, undef, \$err );
        carp $err if $err;
        unless ($out && $out =~ /^OpenSSL\s+[1-9]\.[0-9]/m) {
            croak("FATAL ERROR: Program openssl not found. Please install it and try again later") unless $out;
            say $out;
            carp("OpenSSL Version is not correctly. May be some problems");
        }
    }
    $config->set(opensslbin => $opensslbin);

    # Check GnuPG
    my $gpgbin = $c->cli_prompt('GnuPG (gpg) program:', which($config->get("gpgbin") || GPGBIN) || $config->get("gpgbin") || GPGBIN);
    unless ($gpgbin) {
        croak("FATAL ERROR: Program GnuPG (gpg) not found. Please install it and try again later");
    } else {
        my $cmd = [$gpgbin, "--version"];
        say(join(" ", @$cmd));
        my $err = "";
        my $out = execute( $cmd, undef, \$err );
        carp $err if $err;
        unless ($out && $out =~ /^gpg\s+\(GnuPG\)\s+[2-9]\.[0-9]/m) {
            croak("FATAL ERROR: Program GnuPG (gpg) not found. Please install it and try again later") unless $out;
            say $out;
            carp("GnuPG Version is not correctly. May be some problems");
        }
    }
    $config->set(gpgbin => $gpgbin);

    # Server data
    while ( 1 ) {
        say "";
        # Server Host Name (server_host)
        my $server_host = cleanServerName( $c->cli_prompt('Server Host Name:', $config->get("server_host") || "my.domain.com") );
        $config->set(server_host => $server_host);

        # Server Port Number (server_port)
        my $server_port = $c->cli_prompt('Server Port Number:', $config->get("server_port") || 443);
        say("Invalid Port Number") && exit(1) unless is_int16($server_port);
        $config->set(server_port => $server_port);

        # Server scheme (server_scheme)
        my $ssdefault = 'http';
        $ssdefault = 'https' if is_int16($server_port) && $server_port == 443;
        my $server_scheme = $c->cli_prompt('Server Scheme:', $config->get("server_scheme") || $ssdefault);
        $config->set(server_scheme => $server_scheme);

        # Server path (server_path)
        my $server_path = $c->cli_prompt('Server Path:', $config->get("server_path") || "/".PROJECT);
        $config->set(server_path => $server_path);

        # Server dir (server_dir)
        my $server_dir = $c->cli_prompt('Server Directory:', $config->get("server_dir") || catfile($c->webdir, $server_host, PROJECT));
        $config->set(server_dir => $server_dir);

        # Show URL:
        my $uri = new URI( "http://localhost" );
        $uri->scheme($server_scheme);
        $uri->host($server_host);
        $uri->port($server_port) if ($server_port != 80 and $server_port != 443);
        $uri->path($server_path);
        my $url = $uri->as_string;
        say(sprintf("\nResultant Server URL: %s", $url));
        last if $c->cli_prompt('It is alright?:','yes') =~ /^\s*y/i;
    }
    if ($c->cli_prompt('Ask the credentials interactively (Recommended, t. It\'s safer)?:','yes') =~ /^\s*y/i) {
        $config->set(server_ask_credentials => 1);
        $config->set(server_user => $config->get("server_user"));
        $config->set(server_password => $config->get("server_password"));
    } else {
        # Server user & password
        $config->set(server_ask_credentials => 0);
        my $server_user = $c->cli_prompt('Server user:', $config->get("server_user") || "anonymous");
        $config->set(server_user => $server_user);
        system("stty -echo") unless MSWIN;
        my $server_password = $c->cli_prompt('Server password:');
        $config->set(server_password => $server_password);
        system("stty echo") unless MSWIN;
        print STDERR "\n";  # because we disabled echo
    }

    # Hash Diff
    my %after = $config->getall;
    #say(Data::Dumper::Dumper({ before => {%before}, after => {%after} }));
    if (_hashmd5(%before) eq _hashmd5(%after)) {
        say "Nothing changed. Skipped";
        return 1;
    }

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
        $vf = variant_stf((defined($after{$k}) ? $after{$k} : ''), 52);
        write;
    }
    say "";
FORMATTING

    if ($c->cli_prompt('Are you sure you want to save all changes to local configuration file?:','yes') =~ /^\s*y/i) {
        if ($config->save) {
            say(sprintf("File \"%s\" successfully saved", $config->get("local_conf_file")));
        } else {
            croak(sprintf("Can't save file \"%s\"", $config->get("local_conf_file")));
        }
    } else {
        say("Aborted. File not saved");
    }

    1;
}
sub store { # Upload files
    _expand_wildcards();
    my @files = @ARGV;
    croak("Agrguments missing") unless @files;
    my $config = new MToken::Config;
    #say(Data::Dumper::Dumper($config));

    # Set URI & URL
    my $uri = _mk_uri($config);
    my $url = $uri->as_string;
    my $client = new MToken::Client(
            uri => $uri,
            debug => DEBUG, # Show headers
            verbose => VERBOSE, # Show data pool

            #user => "test",
            #password => "test",
            #realm => "MToken restricted zone",
        );
    #my $status = $client->check();
    say( STDERR $client->error) && exit(1) unless $client->check();
    #say($client->error) && return 0 unless $client->status;

    # MAYBE: AAA
    #  - Дедлаем запрос check. Если возвращается - требуется авторизаия - запрашиваем
    #  - Запрашиваем авторизацию интерактивно!!
    #  - Переустанавливаем credentials
    #    $client->credentials($login, $password);
    #
    #if (!$status && $client->code && $client->code == 401) {
    #    $client->credentials("test", "test", "MToken restricted zone");
    #    say($client->error) && return 0 unless $client->check();
    #}

    #say(Dumper({ code => $client->code}));

    #say(sprintf("Response content length: %d bytes", $client->res->content_length));

    #say(Dumper($client));
    #say(Dumper({ url => $client->{url}, redirect => $client->{redirect}}));

    #say(Dumper(\%json));
    #say(Dumper(MToken::Client::_check_response(\%json)));

    # Send file
    my $retstat = 1;
    foreach my $file (@files) {
        my $filename = basename($file);
        print(sprintf("Sending file %s --> %s... ", $filename, $url));
        if (-f $file) {
            if ($client->upload($file)) {
                say "OK";
            } else {
                say "NOT OK";
                say STDERR $client->error;
                $retstat = 0;
            }
        } else { # Skipped
            say "SKIPPED. It is not file";
            $retstat = 0;
        }
    }
    exit(1) unless $retstat;
    return $retstat;
}
sub fetch { # Downlod files
    _expand_wildcards();
    my @files = @ARGV;
    my $dir = shift @files;
    croak("Agrguments missing") unless $dir;
    croak("Directory incorrect") unless (-d $dir or -l $dir);

    # Internal use only
    my $c = new CTK;
    my $f = '';
    unless (@files) {
        # Try input FileName
        $f = cleanFileName( $c->cli_prompt('Please type filename for fetching from server or (last, all):', "last"));
    }
    croak("Agrguments missing") unless $f or @files;

    my $config = new MToken::Config;
    my $distname = $config->get("distname");

    # Set URI & URL
    my $uri = _mk_uri($config);
    my $url = $uri->as_string;
    my $client = new MToken::Client(
            uri     => $uri,
            debug   => DEBUG, # Show headers
            verbose => VERBOSE, # Show data pool
        );
    #my $status = $client->check();
    say( STDERR $client->error) && exit(1) unless $client->check();

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
            say STDERR "Filename incorrect";
            next;
        }
        my $file = catfile($dir, $filename);
        print(sprintf("Fetching file %s <-- %s... ", $filename, $url));
        if (my $msg = $client->download($file)) {
            my $in_md5 = $l->{md5};
            if ($in_md5) {
                my $out_md5 = md5sum($file) || '';
                unless ($in_md5 eq $out_md5) {
                    say "NOT OK";
                    say STDERR sprintf("File md5sum mismatch: Expected: %s; Got: %s", $in_md5, $out_md5);
                    $retstat = 0;
                }
            }
            my $in_sha1 = $l->{sha1};
            if ($in_sha1) {
                my $out_sha1 = sha1sum($file);
                unless ($in_sha1 eq $out_sha1) {
                    say "NOT OK";
                    say STDERR sprintf("File sha1sum mismatch: Expected: %s; Got: %s", $in_sha1, $out_sha1);
                    $retstat = 0;
                }
            }
            if ($retstat) {
                say "OK";
                say $msg;
            }
        } else {
            say "NOT OK";
            say STDERR $client->error;
            $retstat = 0;
        }
    }
    exit(1) unless $retstat;
    return $retstat;

    return 1;
}
sub list {
    my $config = new MToken::Config;
    my $distname = $config->get("distname");
    my $client = new MToken::Client(
            uri     => _mk_uri($config),
            debug   => DEBUG, # Show headers
            verbose => VERBOSE, # Show data pool
        );
    say( STDERR $client->error) && exit(1) unless $client->check();

    my @list = sort { ($b->{date_sfx} || 0) <=> ($a->{date_sfx} || 0) } ($client->list($distname));
    say( STDERR $client->error) && exit(1) unless $client->status();

    unless (@list) {
        say "No files found";
        return 1;
    }

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
    my $distname = $config->get("distname");
    my $client = new MToken::Client(
            uri     => _mk_uri($config),
            debug   => DEBUG, # Show headers
            verbose => VERBOSE, # Show data pool
        );
    say( STDERR $client->error) && exit(1) unless $client->check();

    my %info = $client->info($fnorid);
    say( STDERR $client->error) && exit(1) unless $client->status();

    unless (%info) {
        say "File not found";
        return 1;
    }

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

    # Set URI & URL
    my $uri = _mk_uri($config);
    my $url = $uri->as_string;
    my $client = new MToken::Client(
            uri     => $uri,
            debug   => DEBUG, # Show headers
            verbose => VERBOSE, # Show data pool
        );
    say( STDERR $client->error) && exit(1) unless $client->check();

    # Delete files
    my $retstat = 1;
    foreach my $file (@files) {
        my $filename = basename($file);
        print(sprintf("Deleting backup file %s --> %s... ", $filename, $url));
        if ($client->remove($file)) {
            say "OK";
        } else {
            say "NOT OK";
            say STDERR $client->error;
            $retstat = 0;
        }
    }
    exit(1) unless $retstat;
    return $retstat;
}
sub backupupdate {
    _expand_wildcards();
    my @files = @ARGV;
    croak("Agrguments missing") unless @files;
    my $config = new MToken::Config;

    # Set URI & URL
    my $uri = _mk_uri($config);
    my $url = $uri->as_string;
    my $client = new MToken::Client(
            uri     => $uri,
            debug   => 0, #DEBUG, # Show headers
            verbose => 0, #VERBOSE, # Show data pool
        );
    say( STDERR $client->error) && exit(1) unless $client->check();

    # Updating files
    my $retstat = 1;
    foreach my $file (@files) {
        my $filename = basename($file);
        print(sprintf("Update backup file %s --> %s... ", $filename, $url));
        if (-f $file) {
            if ($client->update($file)) {
                say "OK";
            } else {
                say "NOT OK";
                say STDERR $client->error;
                $retstat = 0;
            }
        } else { # Skipped
            say "SKIPPED. It is not file";
            $retstat = 0;
        }
    }
    exit(1) unless $retstat;

    return $retstat;
}
sub cpgpgkey {
    # Copy GPG public and private key files from user directory to standard token-directory (certs)
    my @in = @ARGV;
    my $dst = shift @in;
    croak("Destination file is not specified") unless $dst;
    say("Skipped. Destination file $dst already exists") && return 1 if -e $dst;

    # Internal use only
    my $c = new CTK;
    my $src = $c->cli_prompt('Please type full path to file:');
    croak("Path to file incorrect") unless $src;
    croak("File is not exists. Try again") unless -e $src and -f $src and -r $src;

    unless (cp($src, $dst)) {
        croak("Can't copy file: $!");
        exit 1;
    }

    say(sprintf("File successfully copied: %s --> %s", $src, $dst));
    return 1;
}
sub gpgrecipient {
    # Get recipient from stdin and replace default-recipient in file
    my @in = @ARGV;
    my $fn = shift @in;
    croak("Destination file is not specified") unless $fn;

    my $config = new MToken::Config;

    # Get recipient from STDIN
    my $pool = scalar(do{local $/ = undef; <STDIN>});
    my $recipient = $1 if $pool =~ /\<(.+?\@.+?)\>/s;
    say( STDERR sprintf("Can't get recipient from input pool:\n%s", $pool)) && exit(1) unless $recipient;
    say sprintf("Found recipient: %s", $recipient);

    # Get data from file and replacing
    my $data = fload($fn);
    $data =~ s/\n{2,}//s if $data =~ s/^\s*default-recipient.+$//gm;
    $data .= sprintf("\ndefault-recipient %s\n", $recipient);

    # Save file
    unless (fsave($fn, $data)) {
        croak("Can't save file $fn") unless $fn;
    }

    return 1;
}
sub gpgfileprepare {
    _expand_wildcards();
    my @files = @ARGV;
    my $suffix = pop @files;
    croak("Suffix incorrect") unless $suffix;
    croak("No files. Missing arguments") unless @files;

    foreach my $file (@files) {
        next unless -f $file;
        unless (mv($file, $file.$suffix)) {
            say( STDERR "Can't move file: $!");
            next;
        }
        say "File $file --> $file.$suffix";
    }
    return 1;
}
sub untar {
    _expand_wildcards();
    my @files = @ARGV;
    my $directory = pop @files;
    croak("Directory incorrect") unless $directory;
    croak("No files. Missing arguments") unless @files;

    foreach my $file (@files) {
        next unless -f $file;
        my $dir = $1 if $file =~ /\.(\d{8})\./;
        unless ($dir) {
            say( STDERR "Skip file $file");
            next;
        }
        my $ae = Archive::Extract->new( archive => $file );
        unless ($ae->extract( to => catdir($directory,$dir) )) {
            say( STDERR "Error extract files from $file: ".$ae->error);
            next;
        }

        unlink($file);
        say "Untar file $file --> $dir";
    }
    return 1;
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
    [SERVER_DIR]\\.htpasswd:
# And add string:
    [SERVER_SS]
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
    [SERVER_DIR]/.htpasswd:
# And add string:
    [SERVER_SS]
EOP
    }

    my $htpasswd = which('htpasswd');
    my $suser = $config->get("server_user") || 'test';
    my $spass = $config->get("server_password") || 'test';
    my $ss = sprintf("%s:%s", $suser, $spass);
    if ($htpasswd) {
        my $err = "";
        my $cmd = [$htpasswd, "-nb", $suser, $spass];
        my $out = execute( $cmd, undef, \$err );
        if ($err) {
            say STDERR sprintf("Error running: ".join(" ", @$cmd));
            carp $err;
        }
        if ($out) {
            chomp $out;
            $ss = $out;
        }
    }

    print dformat($pool, {
        SERVER_HOST => $config->get("server_host"),
        SERVER_PORT => $config->get("server_port"),
        SERVER_PATH => $config->get("server_path"),
        SERVER_DIR  => $config->get("server_dir"),
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
        say "No files in manifest. Please initialize your device correctly";
        return 0;
    }
    return 1;
}
sub check {
    # less /usr/share/perl/5.22.2/ExtUtils/Manifest.pm
    my $date_fmt = shift(@ARGV) || CTK::dtf("%YYYY/%MM/%DD", time());
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
        say "No files in manifest. Please initialize your device correctly";
        $status = 0;
    }

    # Checking MD5 conflicts
    foreach my $k (keys %$manifest) {
        my $comment = $manifest->{$k} || '';
        my $date = $1 if $comment =~ /(\d{4}\/\d{2}\/\d{2})/; $date ||= $date_fmt;
        my $md5  = $1 if $comment =~ /([a-f0-9]{32})/i;
        next unless $md5;
        my $realf = catfile(split(/\//, $k));
        next unless -f $realf and -r _;
        my $got = md5sum($realf) || '';
        next if lc($md5) eq lc($got);

        $status = 0;
        say(sprintf("MD5 Conflict for file: %s", $k));
        say(sprintf("  Got      : %s", $got)); # Got : 745cb2db6dbc5ec03dade96ccbc51628 (получил)
        say(sprintf("  Expected : %s", $md5)); # Expected : 745cb2db6dbc5ec03dade96ccbc51629 (ожидал)
        say("");
    }

    exit(1) unless $status;
    return 1;
}
sub add {
    my $date_fmt = shift(@ARGV) || CTK::dtf("%YYYY/%MM/%DD", time());
    my $status = _check_date($date_fmt);

    # Internal use only
    my $c = new CTK;

    my $n = _show_extra();
    unless ($n) {
        say "Nothing to add. Please first copy physical file for adding";
        return 0;
    }

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
        say "Aborted";
        return 0;
    } else { # Other
        say "Incorrect answer. Try again";
        return 0;
    }

    return $status;
}
sub update {
    my $date_fmt = shift(@ARGV) || CTK::dtf("%YYYY/%MM/%DD", time());
    my $status = _check_date($date_fmt);

    # Manifest
    my $manifest = maniread(); # Текущий манифест файл => коментарий
    unless (keys %$manifest) {
        say "No files in manifest. Please initialize your device correctly";
        $status = 0;
    }

    # Checking MD5 conflicts
    my $rnames = RESERVED_NAMES;
    my %updates = ();
    foreach my $k (keys %$manifest) {
        next if grep {$_ eq $k} @$rnames;
        my $comment = $manifest->{$k} || '';
        my $date = $1 if $comment =~ /(\d{4}\/\d{2}\/\d{2})/; $date ||= "";
        my $md5  = $1 if $comment =~ /([a-f0-9]{32})/i; $md5 ||= "";

        my $realf = catfile(split(/\//, $k));
        unless (-f $realf and -r _) {
            $updates{$k} = ''; # DELETE
            say(sprintf("Missing file %s", $k));
            next;
        }

        # Check date and md5
        my $got_md5 = md5sum($realf) || '';
        next if $date && lc($md5) eq lc($got_md5);

        $updates{$k} = sprintf("\%s\t%s", $got_md5, $date_fmt);
        say(sprintf("Changed file %s", $k));
    }
    if (%updates) {
        if (ExtUtils::Manifest::maniupdate(\%updates)) {
            say("Device successfully updated");
        } else {
            say("Can't update device");
        }
    } else {
        say("Device no need to update");
    }
    say("");

    exit(1) unless $status;
    return 1;
}
sub del {
    my $c = new CTK;
    my $status = 1;

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
        say "No files in manifest. Add files first";
        $status = 0;
        return $status;
    }

    my $n = scalar(@files);
    my $sel = $c->cli_prompt(sprintf("Please type file's NNN (%d-%d) or (all, cancel):", 1, $n), "cancel");
    if ($sel && is_int($sel) && ($sel > 0) && ($sel <= $n)) { # NNN
        # Удаление конкретного файла
        my $file = $files[$sel - 1];
        my $realf = catfile(split(/\//, $file));
        unless ($file) {
            say "File not specified or incorrect";
            exit(1);
        }
        say(sprintf("File for deleting: %s", $file));
        unless (-f $realf && -w _) {
            say "File not exists or locked for writing";
            exit(1);
        }
        unless ($c->cli_prompt('Are you sure you want to remove this file?:','no') =~ /^\s*y/i) {
            say "Aborted";
            return 0;
        }
        unless (unlink($realf)) {
            say "Can't remove file: $!";
            exit(1);
        }
        if (ExtUtils::Manifest::maniupdate({$file, ''})) {
            say("Device successfully updated");
        } else {
            say("Can't update device");
            $status = 0;
        }
    } elsif ($sel && $sel =~ /all/i) { # All
        unless ($c->cli_prompt('Are you sure you want to remove all file?:','no') =~ /^\s*y/i) {
            say "Aborted";
            return 0;
        }
        my %dels;
        foreach my $file (@files) {
            my $realf = catfile(split(/\//, $file));
            say(sprintf("File for deleting: %s", $file));
            unless (-f $realf && -w _) {
                say "File not exists or locked for writing";
                $status = 0;
                next;
            }
            unless (unlink($realf)) {
                say "Can't remove file: $!";
                $status = 0;
                next;
            }
            $dels{$file} = "";
        }
        if (ExtUtils::Manifest::maniupdate({%dels})) {
            say("Device successfully updated");
        } else {
            say("Can't update device");
            $status = 0;
        }
    } elsif ($sel && $sel =~ /cancel/i) { # Cancel
        say "Aborted";
        return 0;
    } else { # Other
        say "Incorrect answer. Try again";
        return 0;
    }

    exit(1) unless $status;
    return 1;
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
sub _mk_uri { # URI constructor
    my $config = shift;
    my $uri = new URI( "http://localhost" );
    my $server_host = $config->get("server_host") || "localhost";
    my $server_port = $config->get("server_port") || 443;
    my $server_path = $config->get("server_path") || $config->get("project") || PROJECT;
    my $server_scheme = $config->get("server_scheme") || ($server_port == 443 ? 'https' : 'http');
    $uri->scheme($server_scheme);
    $uri->host($server_host);
    $uri->port($server_port) if ($server_port != 80 and $server_port != 443);
    $uri->path($server_path);
    return $uri;
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
    my $realf = catfile(split(/\//, $k));
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
    my $cur_fmt = CTK::dtf("%YYYY/%MM/%DD", time());
    unless ($date_fmt eq $cur_fmt) {
        say ("Makefile too old. Please run first follows commands:\n\tmake clean\n\tperl Makefile.PL\n");
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
    my $c = new CTK;

    # Extraneous files
    my @extra = filecheck(); # Отсутствующие файла в манифесте но есть на диске
    unless (@extra) {
        say "No files for add";
        return 0;
    }

    my $sel = "";
    my $i = 0;
    foreach (@extra) {
        $i++;
        $sel = $_ if $i == $n;
    }
    unless ($sel) {
        say "File not selected";
        return 0;
    }
    say "Selected file for adding:";
    say(sprintf("  File : %s", $sel));
    my $realf = catfile(split(/\//, $sel));
    my $fs = (-f $realf and -r _) ? (-s _) : 0; # File size
    say(sprintf("  Size : %s bytes", correct_number($fs || 0)));
    say(sprintf("  Date : %s", $d));
    my $md5 = md5sum($realf);
    say(sprintf("  MD5  : %s", $md5));
    my $sha1 = sha1sum($realf);
    say(sprintf("  SHA1 : %s", $sha1));
    unless ($c->cli_prompt('Are you sure you want to add this file?:','no') =~ /^\s*y/i) {
        say "Aborted";
        return 0;
    }

    my $comment = sprintf("\%s\t%s", $md5, $d);
    unless (maniadd({$sel, $comment})) {
        say "Can't add file";
        return 0;
    }
    say "Done";
    return 1;
}
sub _addall {
    my $d = shift || '';

    # Extraneous files
    my @extra = filecheck(); # Отсутствующие файла в манифесте но есть на диске
    unless (@extra) {
        say "No files for add";
        return 0;
    }

    foreach my $f (@extra) {
        my $realf = catfile(split(/\//, $f));
        my $comment = sprintf("\%s\t%s", md5sum($realf), $d);
        if (maniadd({$f, $comment})) {
            say(sprintf("File %s successfully added", $f));
        } else {
            say(sprintf("Can't add file %s", $f));
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
