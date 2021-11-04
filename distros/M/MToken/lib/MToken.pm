package MToken; # $Id: MToken.pm 116 2021-10-12 15:17:49Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken - Tokens processing system (Security)

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

    use MToken;

=head1 DESCRIPTION

Tokens processing system (Security)

=head2 client

    my $client = $mt->client;

Returns the Mojo client (user agent) instance

=head2 execmd

    my %exest = $self->execmd("command", "arg1", "arg2", "argn");

Performs execute system commands and returns hash:

=over 8

=item command

The command line

=item status

The status of operation. 1 - no errors; 0 - error

=item exitval

The exitval value

=item error

The error message

=item output

The data from program

=back

=head2 get_fingerprint

Returns the fingerprint from local config or ask it

=head2 get_gpgbin

Returns the GNUPG path from local config

=head2 get_manifest

Returns manifest of current token

=head2 get_name

Returns name of current token

=head2 get_opensslbin

Returns the OpenSSL path from local config

=head2 get_server_url

Returns SERVER_URL from local config

=head2 lconfig

    my $lconfig = $mt->lconfig;

Returns local config instance

=head2 raise

    return $mt->raise("Red message");

Sends message to STDERR and returns 0

=head2 store

    my $store = $mt->store;

Returns the Store instance (Database)

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

C<openssl>, C<gnupg>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<Mojolicious>, L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = "1.04";

use feature qw/say/;
use Carp;
use Encode; # Encode::_utf8_on();
use Encode::Locale;

use Archive::Tar;
use Cwd qw/getcwd/;
use Digest::MD5 qw/md5_hex/;
use ExtUtils::Manifest qw/maniread/;
use File::Spec;
use File::HomeDir;
use File::Find;
use File::stat qw//;
use List::Util qw/uniq/;
use POSIX qw//;
use Text::SimpleTable;
use URI;

use Mojo::File qw/path/;
use Mojo::Util qw/tablify steady_time/;
use Mojo::Date qw//;
use Mojo::Server::Prefork;

use CTK::Skel;
use CTK::Util qw/preparedir which dtf tz_diff isTrueFlag rundir sharedir sharedstatedir/;
use CTK::UtilXS qw/wipe/;
use CTK::TFVals qw/ :ALL /;
use CTK::ConfGenUtil;

use MToken::Const;
use MToken::Util qw/explain sha1sum red green yellow cyan blue magenta yep nope skip wow filesize/;
use MToken::Config;
use MToken::Store;
use MToken::Server;
use MToken::Client;

use base qw/ CTK::App /;

use constant {
        ERROR_NO_TOKEN => "No token selected. Please use --datadir option or change the current directory to Your token device",
    };

__PACKAGE__->register_handler(
    handler     => "test",
    description => "MToken testing (internal use only)",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;

    #say tablify [['foo', 'bar'], ['yadaffffgff', 'yada'], ['baz', 'yada']];

    #my $fingerprint = $self->get_fingerprint;
    #say explain(\%exest);
    #my @strings = split("\n", $exest{output});
    #say explain(\@strings);

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "version",
    description => sprintf("%s Version", PROJECTNAME),
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    printf("%s/%s\n", PROJECTNAME, $self->VERSION);
    return 1;
});

__PACKAGE__->register_handler(
    handler     => "status",
    description => "Get status information",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;

    printf("Version         : %s\n", $self->VERSION);
    printf("Data dir        : %s\n", $self->datadir);
    printf("Temp dir        : %s\n", $self->tempdir);
    printf("Global config   : %s\n", $self->conf("loadstatus") ? $self->configfile : yellow("not loaded"));
    $self->debug(explain($self->config)) if $self->conf("loadstatus") && $self->verbosemode;
    printf("Local config    : %s\n", $self->lconfig->is_loaded ? green("loaded") : red("not loaded"));
    $self->debug(explain($self->lconfig)) if $self->lconfig->is_loaded && $self->verbosemode;

    # Return if no token selected
    return 1 unless $self->lconfig->is_loaded;

    # Database

    my $store = $self->store;
    printf("DB DSN          : %s\n", $store->dsn);
    printf("DB status       : %s\n", $store->status ? green("ok") : red($store->error || sprintf("Store (%s): Unknown error", $store->dsn)));
    if ($store->file) {
        my $s = filesize($store->file) || 0;
        printf("DB size         : %s\n", $store->status ? sprintf("%s (%d bytes)", _fbytes($s), $s) : yellow("unknown"));
        printf("DB modified     : %s\n", $store->status ? _fdate(File::stat::stat($store->file)->mtime || 0) : yellow("unknown"));
    }
    printf("Stored files    : %s\n", $store->status ? $store->count || 0 : yellow("unknown"));

    # Server
    my $client = $self->client;
    $client->check(); # Check
    printf("Server URL      : %s\n", $client->url ? $client->url->to_string : yellow("unknown"));
    printf("Server status   : %s\n", $client->status ? green("ok") : red($client->error));
    $self->debug($client->trace);

    # Get info from server
    if ($client->status) {
        if ($client->info($self->get_name)) {
            my $files = array($client->res->json("/files"));

            # Init table
            my $tbl = Text::SimpleTable->new(
                [24, 'TARBALL FILE'],
                [10, 'FILE SIZE'],
                [25, 'MAKE TIME'],
            );
            my $i = 0;
            my $tz = tz_diff();
            # Table caption
            foreach my $row (@$files) {
                $i++;
                $tbl->row(
                    $row->{filename} || "noname",
                    _fbytes($row->{size} || 0),
                    dtf(DATETIME_FORMAT  . " " . $tz, $row->{mtime} || 0),
                );
            }
            # Show table
            if ($i) {
                print $tbl->draw();
                say cyan("total %d file(s)", $i);
            } else {
                say yellow("No data found on server");
            }
        } else {
            say red($client->error);
            $self->debug($client->trace);
        }
    }

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "init",
    description => "Initialize token",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $tkn = shift(@arguments);
    my $dir  = $self->datadir || getcwd(); # Destination directory

    # Prepare DataDir if specified
    if ($self->option("datadir")) {
        unless (preparedir($dir)) {
            $self->error(sprintf("Can't prepare directory %s", $dir));
            return 0;
        }
    }

    # Project name
    $tkn ||= $self->cli_prompt('Token name:', $self->prefix);
    $tkn = lc($tkn);
    $tkn =~ s/\s+//g;
    $tkn =~ s/[^a-z0-9]//g;
    $tkn ||= $self->prefix;
    if ($tkn =~ /^\d/) {
        $self->error("The token name must not begin with numbers. Choose another name consisting mainly of letters of the Latin alphabet");
        return 0;
    }

    printf("Initializing token \"%s\"...\n", $tkn);

    # Initialize local configuration for device
    $self->{lconfig} = MToken::Config->new(
        file => File::Spec->catfile($dir, DIR_PRIVATE, DEVICE_CONF_FILE),
        name => $tkn,
    );
    #say(explain($self->lconfig));
    my %before = $self->lconfig->getall;


    # Ask OpenSSL
    my $opensslbin = $self->cli_prompt('OpenSSL program:', $self->lconfig->get("opensslbin") ||
        $self->conf("opensslbin") || which(OPENSSLBIN) || OPENSSLBIN);
    unless ($opensslbin) {
        return $self->raise("Program openssl not found. Please install it and try again later");
    } else {
        my $cmd = [$opensslbin, "version"];
        my $err = "";
        my $out = CTK::Util::execute( $cmd, undef, \$err );
        if ($err) {
            say cyan("#", join(" ", @$cmd));
            say STDERR red($err);
        }
        return $self->raise("Program openssl not found. Please install it and try again later") unless $out;
        unless ($out =~ /^OpenSSL\s+[1-9]\.[0-9]/m) {
            say STDERR yellow("OpenSSL Version is not correctly. May be some problems");
            say cyan($out) if $self->verbosemode;
        }
    }
    $self->lconfig->set(opensslbin => $opensslbin);

    # Ask GnuPG
    my $gpgbin = $self->cli_prompt('GnuPG (gpg) program:', $self->lconfig->get("ogpgbin") ||
        $self->conf("gpgbin") || which(GPGBIN) ||  GPGBIN);
    unless ($gpgbin) {
        return $self->raise("Program GnuPG (gpg) not found. Please install it and try again later");
    } else {
        my $cmd = [$gpgbin, "--version"];
        my $err = "";
        my $out = CTK::Util::execute( $cmd, undef, \$err );
        if ($err) {
            say cyan("#", join(" ", @$cmd));
            say STDERR red($err);
        }
        return $self->raise("Program GnuPG (gpg) not found. Please install it and try again later") unless $out;
        unless ($out =~ /^gpg\s+\(GnuPG\)\s+[2-9]\.[0-9]/m) {
            say STDERR yellow("GnuPG Version is not correctly. May be some problems");
            say cyan($out) if $self->verbosemode;
        }
    }
    $self->lconfig->set(gpgbin => $gpgbin);

    # Ask fingerprint
    my $fingerprint = $self->get_fingerprint;
    $self->lconfig->set(fingerprint => $fingerprint) if $fingerprint;

    # Server URL (server_url)
    my $default_url = _get_default_url($tkn);
    my $server_url = $self->cli_prompt('Server URL:', MToken::Util::hide_pasword($self->lconfig->get("server_url")
        || $self->conf("server_url") || $default_url, 1));
    my $uri = URI->new( $server_url );
    my $url = $uri->canonical->as_string;

    # Server credentials
    if ($self->cli_prompt('Ask the credentials interactively (Recommended, t. It\'s safer)?:','yes') =~ /^\s*y/i) {
        $uri->userinfo(undef);
    } else {
        my ($server_user, $server_password) = MToken::Util::parse_credentials($uri);
        unless ($server_user) { # User
            $server_user = $self->cli_prompt('Server user:', "anonymous") // "";
            $server_user =~ s/%/%25/g;
            $server_user =~ s/:/%3A/g;
        }
        unless ($server_password) { # Password
            system("stty -echo") unless IS_MSWIN;
            $server_password = $self->cli_prompt('Server password:', "none") // "";
            $server_password =~ s/%/%25/g;
            system("stty echo") unless IS_MSWIN;
            print STDERR "\n";  # because we disabled echo
            $server_password = "" if $server_password eq "none";
        }
        $uri->userinfo(sprintf("%s:%s", $server_user, $server_password));
        $url = $uri->canonical->as_string;
        wow("Full server URL: %s", MToken::Util::hide_pasword($url));
    }
    $self->lconfig->set(server_url => $url);

    # Hash Diff and Save
    my %after = $self->lconfig->getall;
    if (_hashmd5(%before) eq _hashmd5(%after)) {
        skip("Nothing changed in current configuration data");
    } elsif ($self->cli_prompt('Are you sure you want to save all changes to local configuration file?:','yes') =~ /^\s*y/i) {
        if ($self->lconfig->save) {
            yep("File \"%s\" successfully saved", $self->lconfig->{local_config_file});
        } else {
            return $self->raise("Can't save file \"%s\"", $self->lconfig->{local_config_file});
        }
    }

    # Skeleton
    my $skel = CTK::Skel->new (
            -name   => $tkn,
            -root   => $dir,
            -skels  => {
                        device => 'MToken::DeviceSkel',
                    },
            -debug  => $self->debugmode,
        );
    #say("Skel object: ", explain($skel));

    # Ask
    return skip("Aborted") unless $self->cli_prompt("Are you sure you want to build token $tkn to \"$dir\"?:",'no') =~ /^\s*y/i;

    # Build
    my %vars = (
            PACKAGE     => __PACKAGE__,
            VERSION     => $self->VERSION, MTOKEN_VERSION => $self->VERSION,
            TOKEN       => $tkn, TOKEN_NAME => $tkn,
            SERVER_URL  => $url,
        );
    return $self->raise("Can't build the token to \"%s\" directory", $dir)
        unless $skel->build("device", $dir, {%vars});

    # Database (store)
    my $store = $self->store(do_init => 1);
    return $self->raise($store->error ? $store->error : sprintf("Store (%s): Unknown error", $store->dsn))
        unless $store->status;
    #say(explain($store));

    # Ok
    return yep("Done");
});

__PACKAGE__->register_handler(
    handler     => "add",
    description => "Add file(s) to token",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Database
    my $store = $self->store;
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }

    # Input files
    my @in_files = uniq(_expand_wildcards(@arguments));
    unless (scalar(@in_files)) {
        $self->error("No input file(s) specified");
        return 0;
    }

    # Get Fingerprint
    my $fingerprint = $self->get_fingerprint;
    unless ($fingerprint) {
        $self->error("No fingerprint specified");
        return 0;
    }

    # Processing every file
    foreach my $in_file (@in_files) {
        my $in_file_path = path($in_file);
        $in_file = $in_file_path->to_abs->to_string;

        # Check input file first
        unless ($in_file && -f $in_file) {
            skip("Can't load file %s", $in_file);
            next;
        }

        # Get file info
        my $fname = $in_file_path->basename();
        my $size = filesize($in_file_path->to_string);
        my $mtime =  File::stat::stat($in_file_path->to_string)->mtime;
        my $sha1 = sha1sum($in_file);
        #say explain([$fname, $size, $mtime, $sha1]);

        # Get info from DB
        my %db_info = $store->get($fname);
        unless ($store->status) {
            $self->raise($store->error);
            next;
        }
        if ($db_info{id}) {
            unless ($self->option("force") || $self->cli_prompt('The file '.$in_file.' already exists in token. Are you sure you want to update it file?:','yes') =~ /^\s*y/i) {
                skip("Skip file %s", $in_file);
                next;
            }
        }

        # Ask subject
        my $subject = $self->option("force")
            ? $db_info{subject}
            : decode(locale => $self->cli_prompt('Subject (commas, slash or backslash is as line delimiter):', encode(locale => $db_info{subject} || "")));

        # Ask tags
        my $tags = $self->option("force")
            ? $db_info{tags}
            : decode(locale => $self->cli_prompt('Tags (commas or spaces are tag delimiter):', encode(locale => $db_info{tags} || "")));


        # New filename
        my $out_file = File::Spec->catfile($self->tempdir, sprintf("%s.gpg", $fname));
        #say $out_file;

        # Encrypt file to tempdir
        my %exest = $self->execmd($self->get_gpgbin, "--encrypt", "--armor", "--quiet", "--recipient", $fingerprint, "--output", $out_file, $in_file);
        unless ($exest{status} && -f $out_file) {
            $self->raise("Can't encrypt file %s", $in_file);
            next;
        }

        # Get path object
        my $out_file_path = path($out_file);

        # Add/Set new record
        my @sarg = (
            file        => $fname,
            size        => $size,
            mtime       => $mtime,
            checksum    => $sha1,
            tags        => $tags,
            subject     => $subject,
            content     => $out_file_path->slurp,
        );
        my $sts = $db_info{id} ? $store->set(id => $db_info{id}, @sarg) : $store->add(@sarg);
        unless ($sts) {
            $out_file_path->remove;
            $self->raise($store->error);
            next;
        }

        # Remove output file
        $out_file_path->remove;

        # Remove source file (if set the remove option)
        if ($self->option("remove")) {
            if ($self->option("force") || $self->cli_prompt('Are you sure you want to remove file '.$in_file.'?:','no') =~ /^\s*y/i) {
                wipe($in_file);
                $in_file_path->remove;
            }
        }

        # Ok
        yep("File %s successfully added", $in_file);
    }

    # Ok
    return yep("Done");

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "list",
    description => "Files list on  token",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Database
    my $store = $self->store;
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }

    # Get info from DB
    my $page = $self->option("page") || 1;
    my $cnt = $store->count || 0;
    my $of = ($cnt - $cnt % RECORDS_PER_PAGE)/RECORDS_PER_PAGE + 1;
       $page = $of if $page > $of;
    say cyan("File list of \"%s\"", $self->get_name);

    my @table = $store->getall(($page - 1) * RECORDS_PER_PAGE, RECORDS_PER_PAGE); # offset, row_count
    unless ($store->status) {
        $self->error($store->error);
        return 0;
    }

    # Init table
    my $tbl_hdrs = [(
        [SCREENWIDTH() - 54, 'FILE/SUBJECT'],
        [21, 'TAGS'],
        [10, 'SIZE, B'],
        [10, 'MTIME'],
    )];
    my $tbl = Text::SimpleTable->new(@$tbl_hdrs);

    # Show table
    my $i = 0;
    my $c = scalar(@table);
    foreach my $row (@table) {
        $i++;
        #$tbl->row("Test.txt\nTest document", "foo, bar, baz", 1024, "2020-12-12\n12:12:12");
        $tbl->row(
            sprintf("%s\n  %s%s",
                $row->[1] || "noname",
                encode(locale => $row->[6] || ''),
                "", #($c > $i ? "\n" : ""),
            ),
            encode(locale => $row->[5] || '-'),
            _fbytes($row->[2] || 0),
            sprintf("%s\n  %s",
                dtf(DATE_FORMAT, $row->[3] || 0),
                dtf(TIME_FORMAT, $row->[3] || 0),
            ),
        );
        #$tbl->hr if $c > $i;
    }

    # Show table
    print $tbl->draw();
    say cyan("total %d file(s); page %d of %d", $store->count || 0, $page, $of);

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "info",
    description => "Get file/database information",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Database
    my $store = $self->store;
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }

    # Input file
    my $filename = shift @arguments;
    if ($filename) {
        my %data = $store->get($filename);
        unless ($store->status) {
            $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
            return 0;
        }

        # Show table
        say tablify([
            ['Filename  :', $filename],
            ['Id        :', $data{id} || 0],
            ['Size      :', sprintf("%s (%d bytes)", _fbytes($data{size} || 0), $data{size} || 0)],
            ['MTime     :', _fdate($data{mtime} || 0)],
            ['Checksum  :', $data{checksum} || ""],
            ['Tags      :', encode(locale => $data{tags} || "")],
        ]);
        say cyan(encode(locale => $data{subject} || "none")), "\n";
        say $data{content} || "" if $self->verbosemode;
    } else {
        my $count = $store->count || 0;
        unless ($store->status) {
            $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
            return 0;
        }
        my $dbfile = $store->{file};
        my $dbfile_size = ($dbfile && -e $dbfile) ? filesize($dbfile) || 0 : 0;
        say tablify([
            ['DSN           :', $store->dsn || ""],
            ['Files in DB   :', $count || 0],
            ($dbfile ? (
                ['DB File       :', $dbfile],
                ['DB File size  :', sprintf("%s (%d bytes)", _fbytes($dbfile_size), $dbfile_size)],
            ) : ()),
        ]);
    }

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "get",
    description => "Get (extract) file from token to disk",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Database
    my $store = $self->store;
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }

    # Input file
    my $filename = shift @arguments;
    unless ($filename) {
        $self->error("No input file specified");
        return 0;
    }

    # Get data from database
    my %data = $store->get($filename);
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }

    # Get file names
    my $enc_file_path = path($self->tempdir, sprintf("%s.gpg", $filename));
    my $dec_file_path = path($self->option("output") || File::Spec->catfile(getcwd(), $filename));
    #say explain({enc_file_path => $enc_file_path->to_string, dec_file_path => $dec_file_path->to_string});

    # Write file content on disk (spurt, spew; see also Module::Build::Base::_spew)
    $enc_file_path->spurt($data{content} || "");
    unless (filesize($enc_file_path->to_string)) {
        $self->error(sprintf("Can't load empty file %s", $enc_file_path->to_string));
        return 0;
    }

    # Decrypt file to tempdir
    # gpg -d -q -o $bname $1
    my $out_file = $dec_file_path->to_string;
    my %exest = $self->execmd($self->get_gpgbin, "--decrypt", "--quiet", "--output", $out_file, $enc_file_path->to_string);
    unless ($exest{status} && -e $out_file) {
        $self->error(sprintf("Can't decrypt file %s", $enc_file_path->to_string));
        my $newfile = $enc_file_path->copy_to(sprintf("%s.gpg", $out_file));
        say magenta("The encrypted file has been stored to %s", $newfile->to_string) if filesize($newfile->to_string);
        return 0;
    }

    # Check size
    my $nsize = filesize($dec_file_path->to_string) || 0;
    unless ($nsize == ($data{size} || 0)) {
        $self->error(sprintf("File size mismatch (%s). Expected %d, got %d", $out_file, $nsize, $data{size} || 0));
        return 0;
    }

    # Check sha1
    my $sha1 = sha1sum($out_file);
    unless ($sha1 eq ($data{checksum} || "~")) {
        $self->error(sprintf("File checksum mismatch (%s)", $out_file));
        return 0;
    }

    # Change utime
    if ($data{mtime}) {
        utime(time(), $data{mtime}, $out_file) || skip("Couldn't touch %s: %s", $out_file, $!);
    }

    # Remove temp file
    $enc_file_path->remove;

    # Ok
    yep("File %s successfully extracted", $out_file);
    say cyan(encode(locale => $data{subject} || "none")), "\n";

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "show",
    description => "Extract and print file from token to STDOUT",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Database
    my $store = $self->store;
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }

    # Input file
    my $filename = shift @arguments;
    unless ($filename) {
        $self->error("No input file specified");
        return 0;
    }

    # Get data from database
    my %data = $store->get($filename);
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }

    # Show raw file
    if ($self->option("raw")) {
        say $data{content} || "";
        return 1;
    }

    # Get file names
    my $enc_file_path = path($self->tempdir, sprintf("%s.gpg", $filename));
    my $dec_file_path = path($self->tempdir, $filename);

    # Write file content on disk (spurt, spew; see also Module::Build::Base::_spew)
    my $in_file = $enc_file_path->to_string;
    $enc_file_path->spurt($data{content} || "");
    unless (filesize($enc_file_path->to_string)) {
        $self->error(sprintf("Can't load empty file %s", $in_file));
        return 0;
    }

    # Decrypt file to tempdir
    # gpg -d -q -o $bname $1
    my $out_file = $dec_file_path->to_string;
    my %exest = $self->execmd($self->get_gpgbin, "--decrypt", "--quiet", "--output", $out_file, $in_file);
    unless ($exest{status} && -e $out_file) {
        $self->error(sprintf("Can't decrypt file %s", $in_file));
        say $data{content} || "";
        return 0;
    }

    # Check size
    my $nsize = filesize($dec_file_path->to_string) || 0;
    unless ($nsize && $nsize == ($data{size} || 0)) {
        $self->error(sprintf("File size mismatch (%s). Expected %d, got %d", $out_file, $nsize, $data{size} || 0));
        return 0;
    }

    # Check sha1
    my $sha1 = sha1sum($out_file);
    unless ($sha1 eq ($data{checksum} || "~")) {
        $self->error(sprintf("File checksum mismatch (%s)", $out_file));
        return 0;
    }

    # Check text or binary file (-T)
    if (-B $out_file) {
        say STDERR yellow("File %s is binary!\nPlease use the \"get\" command for extract it as file", $out_file);
        say STDERR cyan(encode(locale => $data{subject} || "none")), "\n";
    } else {
        say $dec_file_path->slurp;
    }

    # Remove temp files
    $enc_file_path->remove;
    wipe($out_file);
    $dec_file_path->remove;

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "del",
    description => "Delete file from token",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Database
    my $store = $self->store;
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }

    # Input file
    my $filename = shift @arguments;
    unless ($filename) {
        $self->error("No input file specified");
        return 0;
    }

    # Get data from database
    my %data = $store->get($filename);
    unless ($store->status) {
        $self->error($store->error || sprintf("Store (%s): Unknown error", $store->dsn));
        return 0;
    }
    unless ($data{id}) {
        $self->error("File not found");
        return 0;
    }

    # Delete file
    if ($self->option("force") || $self->cli_prompt('Are you sure you want to remove file '.$filename .'?:','no') =~ /^\s*y/i) {
        $store->del($filename) or do {
            $self->error($store->error);
            return 0;
        };
    } else {
        return skip("Aborted. Skip file %s", $filename);
    }

    # Ok
    return yep("File %s successfully deleted", $filename);
});

__PACKAGE__->register_handler(
    handler     => "genkey",
    description => "Generate",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;

    # Output file
    my $filename = shift(@arguments) || $self->option("output");
    my $path = $filename
        ? path($filename)
        : $self->lconfig->is_loaded
            ? path($self->datadir, DIR_PRIVATE, RND_KEY_FILE)
            : path(getcwd(), RND_KEY_FILE);
    my $file_out = $path->to_string;
    if (-e $file_out) {
        unless ($self->option("force") ||
            $self->cli_prompt('File '.$file_out.' already exists. Are you sure you want to replace this file?:','no') =~ /^\s*y/i) {
            return skip("Aborted. Skip file %s", $file_out);
        }
    }

    # Get size
    my $size = $self->option("size") ||
        int(rand(MToken::Const::KEYMAXSIZE - MToken::Const::KEYMINSIZE)) + MToken::Const::KEYMINSIZE;

    my %exest = $self->execmd($self->get_opensslbin, "rand", "-out", $file_out, $size);
    unless ($exest{status} && -e $file_out) {
        $self->error(sprintf("Can't generate rand key file %s", $file_out));
        return 0;
    }
    say cyan($exest{output}) if $exest{output};

    # Ok
    return yep("File %s successfully generated", $file_out);
});

__PACKAGE__->register_handler(
    handler     => "server",
    description => "MToken HTTP server",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;

    # Dash k
    my $dash_k = shift(@arguments) || "status";
    unless (grep {$_ eq $dash_k} qw/start status stop restart reload/) {
        $self->error("Incorrect LSB command! Please use start, status, stop, restart or reload");
        return 0;
    }

    # Get permisions by names
    my $uid = $>; # Effect. UID
    my $gid = $); # Effect. GID
    if (IS_ROOT) {
        $uid = getpwnam(USERNAME) || do {
            $self->error("getpwnam failed - $!");
            return 0;
        };
        $gid = getgrnam(GROUPNAME) || do {
            $self->error("getgrnam failed - $!\n");
            return 0;
        };
    }

    # Prepare DataDir if not specified
    unless ($self->option("datadir")) {
        if (IS_ROOT) { # /var/lib/mtoken
            $self->datadir(File::Spec->catdir(sharedstatedir(), PROJECTNAMEL));
        } else { #~/.local/share/mtoken/www
            $self->datadir(File::Spec->catdir(File::HomeDir->my_data(), PROJECTNAMEL, "www"));
        }
        unless (-e $self->datadir) {
            unless (preparedir($self->datadir)) {
                $self->error(sprintf("Can't prepare directory %s", $self->datadir));
                return 0;
            }
        }
        # Set permisions (GID and UID) for work directory
        chown($uid, $gid, $self->datadir) if IS_ROOT && File::stat::stat($self->datadir)->uid != $uid;
    }

    # Prepare tempdir
    $self->tempdir(File::Spec->catdir(File::Spec->tmpdir(), PROJECTNAMEL));
    unless (preparedir( $self->tempdir, 0777 )) {
        $self->error(sprintf("Can't prepare temp directory: %s", $self->tempdir));
        return 0;
    }
    chown($uid, $gid, $self->tempdir) if IS_ROOT && File::stat::stat($self->tempdir)->uid != $uid;
    $self->debug(sprintf("Temp dir: %s", $self->tempdir));

    # Prepare log directory
    if (IS_ROOT) {
        my $logdir = $self->logdir;
        unless (preparedir( $logdir, 0777 )) {
            $self->error(sprintf("Can't prepare log directory: %s", $logdir));
            return 0;
        }
        # Set permisions (GID and UID) for log directory
        chown($uid, $gid, $logdir) if File::stat::stat($logdir)->uid != $uid;
        $self->debug(sprintf("Log dir: %s", $self->logdir));
    } else {
        $self->logfile(File::Spec->catfile($self->tempdir(), sprintf("%s.log", PROJECTNAMEL)));
        $self->debug(sprintf("Log file: %s", $self->logfile));
    }

    # Prepare pid directory and file
    my $piddir = IS_ROOT ? File::Spec->catdir( rundir(), PROJECTNAMEL) : $self->tempdir();
    my $pidfile = File::Spec->catfile($piddir, sprintf("%s.pid", PROJECTNAMEL));
    unless (preparedir($piddir)) {
        $self->error(sprintf("Can't prepare pid directory: %s", $piddir));
        return 0;
    }
    # Set permisions (GID and UID) for pid directory
    chown($uid, $gid, $piddir) if IS_ROOT && File::stat::stat($piddir)->uid != $uid;
    $self->debug(sprintf("Pid file: %s", $pidfile));

    # Hypnotoad variables
    my $upgrade = 0;
    my $reload = 0;
    my $upgrade_timeout = UPGRADE_TIMEOUT;

    # Mojolicious Application
    my $app = MToken::Server->new(ctk => $self);
       $app->attr(ctk => sub { $self }); # has ctk => sub { CTKx->instance->ctk };
    my $prefork = Mojo::Server::Prefork->new( app => $app ); # app => $self
       $prefork->pid_file($pidfile);

    # Hypnotoad Pre-fork settings
    $prefork->max_clients(tv2int(value($self->conf("clients")))) if defined $self->conf("clients");
    $prefork->max_requests(tv2int(value($self->conf("requests")))) if defined $self->conf("requests");
    $prefork->accepts(tv2int(value($self->conf("accepts")))) if defined $self->conf("accepts");
    $prefork->spare(tv2int(value($self->conf("spare")))) if defined $self->conf("spare");
    $prefork->workers(tv2int(value($self->conf("workers")))) if defined $self->conf("workers");

    # Make Listen
    my $cfg_listen = value($self->conf("listen"));
    my $tls_on = isTrueFlag(value($self->conf("tls")));
    my $listen = $tls_on ? "https://" : "http://";
    if ($cfg_listen) {
        $listen .= $cfg_listen;
    } else {
        $listen .= sprintf("%s:%d",
                value($self->conf("listenaddr")) || SERVER_LISTEN_ADDR,
                tv2int16(value($self->conf("listenport"))) || SERVER_LISTEN_PORT,
            );
    }
    my $_resolve_cf = sub {
        my $f = shift;
        return $f if File::Spec->file_name_is_absolute($f);
        return File::Spec->catfile($self->root, $f);
    };
    if ($tls_on) {
        my @p = ();
        foreach my $k (qw/ciphers version/) {
            my $v = value($self->conf("tls_$k")) // '';
            next unless length $v;
            push @p, sprintf("%s=%s", $k, $v);
        }
        foreach my $k (qw/ca cert key/) {
            my $v = value($self->conf("tls_$k")) // '';
            next unless length $v;
            push @p, sprintf("%s=%s", $k, $_resolve_cf->($v));
        }
        push @p, sprintf("%s=%s", "verify", value($self->conf("tls_verify")) || '0x00')
            if value($self->conf("tls_verify"));
        $listen .= sprintf("?%s", join('&', @p));
    }
    $prefork->listen([$listen]);

    # Working with Dash k
    if ($dash_k eq 'start') {
        if (my $pid = $prefork->check_pid()) {
            say "Already running $pid";
            return 1;
        }
    } elsif ($dash_k eq 'stop') {
        if (my $pid = $prefork->check_pid()) {
            kill 'QUIT', $pid;
            say "Stopping $pid";
        } else {
            say "Not running";
        }
        return 1;
    } elsif ($dash_k eq 'restart') {
        if (my $pid = $prefork->check_pid()) {
            $upgrade ||= steady_time;
            kill 'QUIT', $pid;
            my $up = $upgrade_timeout;
            while (kill 0, $pid) {
                $up--;
                sleep 1;
            }
            die("Can't stop $pid") if $up <= 0;
            say "Stopping $pid";
            $upgrade = 0;
        }
    } elsif ($dash_k eq 'reload') {
        my $pid = $prefork->check_pid();
        if ($pid) {
            # Start hot deployment
            kill 'USR2', $pid;
            say "Reloading $pid";
            return 1;
        }
        say "Not running";
    } else { # status
        if (my $pid = $prefork->check_pid()) {
            say "Running $pid";
        } else {
            say "Not running";
        }
        return 1;
    }

    #
    # LSB start
    #

    # This is a production server
    $ENV{MOJO_MODE} ||= 'production';

    # Listen USR2 (reload)
    $SIG{USR2} = sub { $upgrade ||= steady_time };

    # Set hooks
    #$prefork->on(spawn => sub () { # Spawn (start worker)
    #    my $self = shift; # Prefork object
    #    my $pid = shift;
    #    #say "Spawn (start) $pid";
    #    $self->app->log->debug("Spawn (start) $pid");
    #});
    $prefork->on(wait => sub { # Manage (every 1 sec)
        my $self = shift; # Prefork object

        # Upgrade
        if ($upgrade) {
            #$self->app->log->debug(">>> " . $self->healthy() || '?');
            unless ($reload) {
                $reload = 1; # Off next reloading
                if ($self->app->reload()) {
                    $reload = 0;
                    $upgrade = 0;
                    return;
                }
            }

            # Timeout
            if (($upgrade + $upgrade_timeout) <= steady_time()) {
                kill 'KILL', $$;
                $upgrade = 0;
            }
        }
    });
    #$prefork->on(reap => sub { # Cleanup (Emitted when a child process exited)
    #    my $self = shift; # Prefork object
    #    my $pid = shift;
    #    #say "Reap (cleanup) $pid";
    #    $self->app->log->debug("Reap (cleanup) $pid");
    #});
    $prefork->on(finish => sub { # Finish
        my $self = shift; # Prefork object
        my $graceful = shift;
        $self->app->log->debug($graceful ? 'Graceful server shutdown' : 'Server shutdown');
    });

    # Set GID and UID
    if (IS_ROOT) {
        if (defined($gid)) {
            POSIX::setgid($gid) || do {
                $self->error("setgid $gid failed - $!");
                return 0;
            };
            $) = "$gid $gid"; # this calls setgroups
            if (!($( eq "$gid $gid" && $) eq "$gid $gid")) { # just to be sure
                $self->error("detected strange gid");
                return 0;
            }
        }
        if (defined($uid)) {
            POSIX::setuid($uid) || do {
                $self->error("setuid $uid failed - $!");
                return 0;
            };
            if (!($< == $uid && $> == $uid)) { # just to be sure
                $self->error("detected strange uid");
                return 0;
            }
        }
    }


    # Daemonize
    $prefork->daemonize() unless $self->debugmode();

    # Running
    say "Running";
    $prefork->run();

    #my $fingerprint = $self->get_fingerprint;
    #say explain(\%exest);
    #my @strings = split("\n", $exest{output});
    #say explain(\@strings);

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "commit",
    description => "Send tarball to server (backup)",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Check client
    unless ($self->client->check) {
        $self->error($self->client->error);
        $self->debug($self->client->trace);
        return 0;
    }

    # Get Fingerprint
    my $fingerprint = $self->get_fingerprint;
    unless ($fingerprint) {
        $self->error("No fingerprint specified");
        return 0;
    }

    # Get Manifest
    my $manifest = $self->get_manifest; # file=>full_path

    # Get file for tarball making
    my $tmp_dir = $self->debugmode ? File::Spec->catdir(File::Spec->tmpdir(), "mtoken") : $self->tempdir;
    my $tarball_name = dtf(TARBALL_FORMAT, time());
    my $tarball_arch_name = sprintf("%s.tgz", $tarball_name =~ m/(.+?)\.tkn/ ? $1 : $tarball_name);
    my $tarball_path = path($tmp_dir, $tarball_name);
    my $tarball_arch_path = path($tmp_dir, $tarball_arch_name);

    # make_tarball
    my $curdir = path(getcwd())->to_abs->to_string;
    my $newdir = path($self->datadir)->to_abs->to_string;
    chdir $newdir;
    my $tar = Archive::Tar->new;
    $tar->add_files(keys(%$manifest));
    for my $f ($tar->get_files) {
        $f->mode($f->mode & ~022); # chmod go-w
    }
    $tar->write($tarball_arch_path->to_string, 1);
    chdir $curdir;

    # Encrypt file to tempdir
    my %exest = $self->execmd($self->get_gpgbin, "--encrypt", "--quiet", "--recipient", $fingerprint, "--output",
        $tarball_path->to_string, $tarball_arch_path->to_string);
    unless ($exest{status} && -f $tarball_path->to_string) {
        $self->error(sprintf("Can't encrypt file %s: %s", $tarball_arch_path->to_string, $exest{error}));
        return 0;
    }
    $tarball_arch_path->remove;

    # Upload (PUT method)
    my $status = $self->client->upload($self->get_name, $tarball_path->to_string); # "C20211009T090718.tkn"
    #say magenta($tarball_path->to_string);
    #say explain($self->client->req->content);
    #$self->debug($self->client->trace);
    #$self->debug($self->client->res->body);
    if ($status) {
        $tarball_path->remove;
    } else {
        $self->error($self->client->error);
        $self->debug($self->client->trace);
        return 0;
    }

    # Ok
    return yep("Done");
});

__PACKAGE__->register_handler(
    handler     => "update",
    description => "Get tarball from server (restore)",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Check client & get filelist
    unless ($self->client->info($self->get_name)) {
        $self->error($self->client->error);
        $self->debug($self->client->trace);
        return 0;
    }

    # Get file for tarball
    my $tarball_name = shift @arguments;
    if ($tarball_name) {
        unless ($tarball_name =~ TARBALL_PATTERN) {
            $self->error("Incorrect tarball name");
            return 0;
        }
    } else {
        my $files = array($self->client->res->json("/files"));
        my @tmp = sort {$a->{mtime} <=> $b->{mtime}} @$files;
        $tarball_name = value(pop(@tmp), "filename");
        unless ($tarball_name && $tarball_name =~ TARBALL_PATTERN) {
            $self->error("Tarball not found");
            return 0;
        }
    }

    # Get paths
    my $tmp_dir = $self->debugmode ? File::Spec->catdir(File::Spec->tmpdir(), "mtoken") : $self->tempdir;
    my $tarball_pfx = $tarball_name =~ m/(.+?)\.tkn/ ? $1 : $tarball_name;
    my $tarball_path = path($tmp_dir, $tarball_name);
    my $archive_path = path($tmp_dir, sprintf("%s.tgz", $tarball_pfx));
    my $tarball_dir = path($tmp_dir, $tarball_pfx)->make_path;

    # Download file
    unless ($self->client->download($self->get_name => $tarball_path->to_string)) {
        $self->error($self->client->error);
        $self->debug($self->client->trace);
        return 0;
    }

    # Get Last_Modified from headers
    my $lm = $self->client->res->headers->last_modified;
    my $last_modified = $lm ? Mojo::Date->new($lm)->epoch : 0;

    # Check mtime
    if ($self->store->status) {
        my $db_mtime = $self->store->file ? File::stat::stat($self->store->file)->mtime || 0 : 0;
        if ($last_modified && $db_mtime && $db_mtime > $last_modified) { # Conflict
            say yellow("%s: conflict detected", $tarball_name);
            say yellow("  Tarball created: %s", _fdate($last_modified));
            say yellow("   Token modified: %s", _fdate($db_mtime));
            say yellow("The current token was changed later than the one in the repository.");
            unless ($self->option("force") ||
                $self->cli_prompt('Are you sure you want to revert to an earlier state of the token?:','no') =~ /^\s*y/i) {
                return skip("Aborted");
            }
        }
    }

    # Decrypt file
    unless (-e $archive_path->to_string) {
        my %exest = $self->execmd($self->get_gpgbin, "--decrypt", "--quiet", "--output", $archive_path->to_string, $tarball_path->to_string);
        unless ($exest{status} && -e $archive_path->to_string) {
            $self->error(sprintf("Can't decrypt file %s: %s", $tarball_path->to_string, $exest{error}));
            return 0;
        }
        $tarball_path->remove;
    }

    # Store to selected file or directory
    if ($self->option("output") || $self->option("outdir")) {
        my $file_out = $self->option("output");
        $file_out = File::Spec->catfile($self->option("outdir"), sprintf("%s.tgz", $tarball_pfx))
            if !$file_out && -d $self->option("outdir");
        return skip("Incorrect output file %s. File already exists", $tarball_name) if -e $file_out;
        $archive_path->move_to($file_out);
        return nope("Can't download %s tarbal", $tarball_name) unless -f $file_out;
        return yep("Tarbal %s successfully downloaded as archive to %s", $tarball_name, $file_out);
    }

    # Extract files from archive
    my $tar = Archive::Tar->new;
    $tar->read($archive_path->to_abs->to_string);
    $tar->setcwd($archive_path->to_string);
    foreach my $file ($tar->list_files()) {
        $tar->extract_file($file, path($tarball_dir->to_string, $file)->to_string);
    }
    #say explain(\@files);

    # Install files
    find({
      no_chdir => 1,
      wanted => sub {
        return if -d;
        my $src = path($_);
        my $dst = path($_)->to_rel($tarball_dir->to_string);
        #say blue("%s -> %s", $src->to_string, $dst->to_string);
        $src->move_to(File::Spec->catfile($self->datadir, $dst->to_string));
    }}, $tarball_dir->to_string);

    # Ok
    return yep("Done");
});

__PACKAGE__->register_handler(
    handler     => "revoke",
    description => "Revoke tarball from server (delete)",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Check client & get filelist
    unless ($self->client->info($self->get_name)) {
        $self->error($self->client->error);
        $self->debug($self->client->trace);
        return 0;
    }

    # Get file for tarball
    my $tarball_name = shift @arguments;
    if ($tarball_name) {
        unless ($tarball_name =~ TARBALL_PATTERN) {
            $self->error("Incorrect tarball name");
            return 0;
        }
    } else {
        my $files = array($self->client->res->json("/files"));
        my @tmp = sort {$a->{mtime} <=> $b->{mtime}} @$files;
        $tarball_name = value(pop(@tmp), "filename");
        unless ($tarball_name && $tarball_name =~ TARBALL_PATTERN) {
            $self->error("Tarball not found");
            return 0;
        }
    }

    # Delete
    unless ($self->client->remove($self->get_name, $tarball_name)) {
        $self->error($self->client->error);
        $self->debug($self->client->trace);
        return 0;
    }

    # Ok
    return yep("Done");
});

__PACKAGE__->register_handler(
    handler     => "clean",
    description => "Clean temporary files",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    unless ($self->lconfig->is_loaded) {
        $self->error(ERROR_NO_TOKEN);
        return 0;
    }

    # Temp directory
    my $tmp_dir = File::Spec->catdir(File::Spec->tmpdir(), "mtoken");
    find({
      no_chdir => 1,
      wanted => sub {
        return if -d;
        return if /\.pid$/;
        my $file = path($_);

        # Remove
        $file->remove;
        say magenta("Remove file %s", $file->to_string) if $self->verbosemode;
    }}, $tmp_dir);

    # Private directory
    my $priv_dir = File::Spec->catfile($self->datadir, DIR_PRIVATE);
    find({
      no_chdir => 1,
      wanted => sub {
        return if -d;
        return unless /\.tmp$/;
        my $file = path($_);

        # Remove
        $file->remove;
        say magenta("Remove file %s", $file->to_string) if $self->verbosemode;
    }}, $priv_dir);

    # Ok
    return yep("Done");
});

sub again {
    my $self = shift;
       $self->SUPER::again(); # CTK::App again first!!

    # Device & Local configuration
    $self->{lconfig} = MToken::Config->new(file => File::Spec->catfile($self->datadir, DIR_PRIVATE, DEVICE_CONF_FILE));

    # Store conf
    my $store_conf = $self->{lconfig}->get("store") || $self->config("store") || {};
       $store_conf = {} unless is_hash($store_conf);
    $self->{store_conf} = {%$store_conf};
    $self->{store} = undef;
    #$self->debug(_explain($store));

    # Client instance
    $self->{client} = MToken::Client->new(
        url                 => $self->lconfig->is_loaded ? $self->get_server_url : undef,
        insecure            => $self->option("insecure"),
        max_redirects       => $self->conf("maxredirects"),
        connect_timeout     => $self->conf("connecttimeout"),
        inactivity_timeout  => $self->conf("inactivitytimeout"),
        request_timeout     => $self->conf("requesttimeout"),
        pwcache             => File::Spec->catfile($self->datadir, DIR_PRIVATE, PWCACHE_FILE),
        $self->option("insecure") ? (pwcache_ttl => 0) : (),
    );

    return $self; # CTK requires!
}
sub raise {
    my $self = shift;
    say STDERR red(@_);
    return 0;
}
sub store {
    my $self = shift;
    my %store_args = (@_);
    if (is_void(\%store_args)) {
        return $self->{store} if defined $self->{store}; # Already initialized
        my $sconf = $self->{store_conf};
           %store_args = %$sconf;
        $store_args{do_init} = 1 if $self->lconfig->is_loaded;
    }

    # Leazy initializing
    $store_args{file} = File::Spec->catfile($self->datadir, DIR_PRIVATE, DB_FILE)
        unless ($store_args{file} || $store_args{dsn});
    $self->{store} = MToken::Store->new(%store_args);

    return $self->{store};
}
sub lconfig {
    my $self = shift;
    return $self->{lconfig}
}
sub client {
    my $self = shift;
    return $self->{client}
}
sub execmd {
    my $self = shift;
    my @cmd = (@_);
    my $scmd = join(" ", @cmd);
    my $error;

    # Run command
    my $exe_err = '';
    my $exe_out = CTK::Util::execute([@cmd], undef, \$exe_err);
    my $stt = $? >> 8;
    my $exe_stt = $stt ? 0 : 1;
    chomp($exe_out) if defined($exe_out) && length($exe_out);
    if (!$exe_stt && $exe_err) {
        chomp($exe_err);
        say cyan("#", $scmd);
        $error = $exe_err;
        say STDERR red($error);
    } elsif ($stt) {
        say cyan("#", $scmd);
        $error = sprintf("Exitval=%d", $stt);
        say STDERR red($error);
    }

    return (
        command => $scmd,
        status  => $exe_stt,
        exitval => $stt,
        error   => $error,
        output  => $exe_out,
    );
}
sub get_name {
    my $self = shift;
    $self->lconfig->{name};
}
sub get_opensslbin {
    my $self = shift;
    return $self->lconfig->get("opensslbin") || $self->conf("opensslbin") || which(OPENSSLBIN) || OPENSSLBIN;
}
sub get_gpgbin {
    my $self = shift;
    return $self->lconfig->get("gpgbin") || $self->conf("gpgbin") || which(GPGBIN) || GPGBIN;
}
sub get_server_url {
    my $self = shift;
    return $self->lconfig->get("server_url") || $self->conf("server_url") || SERVER_URL;
}
sub get_fingerprint {
    my $self = shift;
    my $fingerprint_cfg = $self->lconfig->get("fingerprint") || $self->conf("fingerprint") || "";
    my $fingerprint = "";
    my %exest = ();

    # Get public keys info
    unless ($self->option("force")) {
        %exest = $self->execmd($self->get_gpgbin, "--list-keys");
        if ($exest{status}) {
            say blue($exest{output} || "no keys found");
        }
    }

    # Get public keys fingerprints
    %exest = $self->execmd($self->get_gpgbin, "--list-keys", "--with-colons");
    if ($exest{status} && $exest{output}) {
        my @fingerprints = map {$_ = uc($1) if /\:([0-9a-f]{16,40})\:/i } grep { /fpr/ } split("\n", $exest{output});
        my $fingerprint_default = $fingerprint_cfg || $fingerprints[0] || 'none';
        while (1) {
            if ($self->option("force")) {
                $fingerprint = $fingerprint_default;
                $fingerprint = "" if $fingerprint =~ /^\s*n/i;
                last;
            }
            $fingerprint = uc($self->cli_prompt('Please provide the fingerprint of recipient:', $fingerprint_default));
            unless (grep {$_ eq $fingerprint} @fingerprints) {
                if ($fingerprint =~ /^\s*n/i) {
                    $fingerprint = "";
                    last;
                }
                say yellow("Fingerprint not found! Type \"n\" to skip");
                next;
            }
            last;
        }
    } else {
        $fingerprint = $self->option("force")
            ? $fingerprint_cfg || "none"
            : uc($self->cli_prompt('Please provide the fingerprint of recipient:', $fingerprint_cfg || "none"));
        if ($fingerprint =~ /^\s*n/i) {
            $fingerprint = "";
        } elsif (!_fingerprint_check($fingerprint)) {
            say yellow("Fingerprint is incorrect!");
            $fingerprint = "";
        }
    }
    say cyan("Fingerprint: %s", $fingerprint) if $fingerprint;

    return $fingerprint;
}
sub get_manifest {
    my $self = shift;
    my $manifile = File::Spec->catfile($self->datadir, DIR_PRIVATE, DEVICE_MANIFEST_FILE);
    return {} unless -e $manifile;
    my $manifest = maniread($manifile);
    my $dir = path($self->datadir)->to_abs->to_string;
    while (my ($k, $v) = each %$manifest) {
        $manifest->{$k} = path($dir, $k)->to_string;
        delete $manifest->{$k} unless -e $manifest->{$k};
    }
    return $manifest;
}


sub _get_default_url {
    my $name = shift || PROJECTNAMEL;
    my $uri = URI->new( DEFAULT_URL );
    $uri->scheme('https');
    $uri->host(HOSTNAME);
    $uri->port(SERVER_LISTEN_PORT);
    #$uri->path(join("/", "mtoken", $name)); # Disabled!
    return $uri->canonical->as_string;
}
sub _hashmd5 {
    my %h = @_ ;
    my $s = "";
    foreach my $k (sort {$a cmp $b} (keys(%h))) { $s .= uv2null($h{$k}) }
    return "" unless $s;
    return md5_hex($s);
}
sub _expand_wildcards {
    my @files = (@_);
    # Original in package ExtUtils::Command
    @files = map(/[*?]/o ? glob($_) : $_, @files);
    return (@files);
}
sub _fingerprint_check {
    my $fpr = shift || '';
    my $l = length($fpr);
    return 0 unless $l == 40 or $l == 16; # Fingerprint or KeyID
    return 1 if $fpr =~ /^[0-9a-f]+$/i;
    return 0;
}
sub _fbytes {
    my $n = int(shift);
    if ($n >= 1024 ** 3) {
        return sprintf "%.3g GB", $n / (1024 ** 3);
    } elsif ($n >= 1024 ** 2) {
        return sprintf "%.3g MB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KB", $n / 1024.0;
    } else {
        return "$n B";
    }
}
sub _fdate {
    my $d = shift || 0;
    my $g = shift || 0;
    return "unknown" unless $d;
    return dtf(DATETIME_GMT_FORMAT, $d, 1) if $g;
    return dtf(DATETIME_FORMAT . " " . tz_diff(), $d);
}

1;

__END__
