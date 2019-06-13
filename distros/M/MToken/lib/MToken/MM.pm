package MToken::MM; # $Id: MM.pm 71 2019-06-09 19:07:03Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken::MM - MakeMaker helper's functions

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    use MToken::MM;

    my $mm = new MToken::MM;

    my $data = $mm->proc();

=head1 DESCRIPTION

MakeMaker helper's functions

=head1 METHODS

=over 8

=item B<new>

    my $mm = new MToken::MM;

Create MakeMaker's object

=item B<proc>

    my $data = $mm->proc();

Start processing

=item B<macro>

    my $macro = $mm->macro();

Returns macroses hash: { NAME => "VALUE", ... }

=item B<sec_*>

Direct call is not provided.

Each function returns the corresponding Makefile section

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

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

use MToken::Const qw/ :GENERAL :CRYPT /;
use MToken::Config;
use Sys::Hostname;
use CTK::Util qw/which/;
use File::Spec;

use vars qw/ $VERSION /;
$VERSION = "1.01";

use constant {
    PHONY => [qw/
            all show init config flushconfig reconfig
            check test
            add delete del update up
            backup restore
            tar untar
            gengpgkey encrypt decrypt
            store fetch list ls info backupdelete backupupdate
            serverconfig
            cleanup
            usage help
        /],
};

sub new {
    my $class = shift;
    my $attrs = {@_};
    $attrs->{phony} = PHONY unless defined($attrs->{phony}) && ref($attrs->{phony}) eq 'ARRAY';

    # Set hostname
    my $host = lc(hostname());
    $host =~ s/\s+//g;
    $host =~ s/[^a-z0-9.\-_]//g;
    $attrs->{host} = $host || HOSTNAME;

    my $self = bless $attrs, $class;
    return $self;
}
sub proc {
	my $self = shift;
	my @output;

	foreach my $sec ( @{($self->{phony})} ) {
	    my $meth = "sec_$sec";
	    next unless $self->can($meth);
	    print "Processing MToken::MM '$sec' section\n" if $self->{debug};
        push @output, "# --- MToken::MM $sec section:";
        push @output, $self->$meth();
	}
	$self->{output} = [@output];
	return join "\n", @output;
}
sub macro {
    my $self = shift;
    my $config = new MToken::Config;
    return {
        # General constants
        DIR_BACKUP      => DIR_BACKUP,
        DIR_RESTORE     => DIR_RESTORE,
        DIR_KEYS        => DIR_KEYS,
        DIR_CERTS       => DIR_CERTS,
        DIR_ETC         => DIR_ETC,
        DIR_TMP			=> DIR_TMP,
        MY_PUBLIC_KEY   => MY_PUBLIC_KEY,
        MY_PRIVATE_KEY  => MY_PRIVATE_KEY,
        PUBLIC_GPG_KEY	=> File::Spec->catfile(DIR_KEYS, PUBLIC_GPG_KEY),
        PRIVATE_GPG_KEY => File::Spec->catfile(DIR_KEYS, PRIVATE_GPG_KEY),
        HOSTNAME        => $self->{host},
        CONFIGURED      => File::Spec->catfile(DIR_ETC, sprintf(".%s", $self->{host})),
        CONFFILE        => File::Spec->catfile(DIR_ETC, GLOBAL_CONF_FILE()),
        GPGCONFFILE     => File::Spec->catfile(DIR_ETC, GPGCONFFILE),
        KEYSUFFIX       => KEYSUFFIX,
        GPGBIN			=> which($config->get("gpgbin") || GPGBIN) || GPGBIN,
        OPENSSLBIN      => which($config->get("opensslbin") || OPENSSLBIN) || OPENSSLBIN,
        GPGFLAGS        => '--options $(GPGCONFFILE) --homedir $(DIR_TMP)',
    }
}

sub sec_all {<<'EOS'
all :: Makefile.PL init
[CMD]$(NOECHO) $(ECHO) Device $(PROJECT) on $(HOSTNAME)
[CMD]$(NOECHO) $(ECHO) "OpenSSL info:"
[CMD]$(OPENSSLBIN) version
[CMD]$(NOECHO) $(ECHO) "GPG info:"
[CMD]$(GPGBIN) $(GPGFLAGS) --version
EOS
}
sub sec_show {<<'EOS'
show :: Makefile.PL init
[CMD]$(NOECHO) $(PERLMTOKEN) -e show
EOS
}
sub sec_init {<<'EOS'
init : $(CONFIGURED) $(DIR_TMP)$(DFSEP).exists $(DIR_KEYS)$(DFSEP)$(PROJECT)$(KEYSUFFIX)
[CMD]$(NOECHO) $(NOOP)

$(DIR_TMP)$(DFSEP).exists :
[CMD]$(NOECHO) $(MKPATH) $(DIR_TMP)
[CMD]$(NOECHO) $(CHMOD) 700 $(DIR_TMP)
[CMD]$(NOECHO) $(TOUCH) $(DIR_TMP)$(DFSEP).exists

$(DIR_KEYS)$(DFSEP)$(PROJECT)$(KEYSUFFIX) :
[CMD]$(NOECHO) $(ECHO) "Initializing..."
[CMD]$(PERLMTOKEN) -e genkey -- $(DIR_KEYS)$(DFSEP)$(PROJECT)$(KEYSUFFIX)
[CMD]$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest
EOS
}
sub sec_config {<<'EOS'
config : $(CONFIGURED)
[CMD]$(NOECHO) $(ECHO) "Project has been successfully configured"
[CMD]$(NOECHO) $(ECHO) "For reconfiguration You can run the follow command:"
[CMD]$(NOECHO) $(ECHO) "  make reconfig"

reconfig : flushconfig $(CONFIGURED)
[CMD]$(NOECHO) $(ECHO) "Project has been successfully reconfigured"

flushconfig :
[CMD]-$(RM_F) $(CONFIGURED)
[CMD]$(NOECHO) $(ECHO) "Configuration marker was flushed"

$(CONFIGURED) : $(DIR_ETC)$(DFSEP)mtoken.conf
[CMD]$(NOECHO) $(ECHO) "Configuration..."
[CMD]$(CONFIGURE) $(PROJECT) $(CONFIGURED)
[CMD]$(NOECHO) $(TOUCH) $(CONFIGURED)
EOS
}
sub sec_backup {<<'EOS'
backup : check tar encrypt store
[CMD]$(NOECHO) $(NOOP)
EOS
}
sub sec_restore {<<'EOS'
restore : fetch decrypt untar
[CMD]$(NOECHO) $(NOOP)
EOS
}
sub sec_tar {<<'EOS'
tar : $(DISTVNAME).tar$(SUFFIX)
[CMD]$(NOECHO) $(NOOP)

$(DISTVNAME).tar$(SUFFIX) : distdir
[CMD]$(NOECHO) $(ECHO) "Compressing..."
[CMD]$(PREOP)
[CMD]$(TO_UNIX)
[CMD]$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
[CMD]$(RM_RF) $(DISTVNAME)
[CMD]$(COMPRESS) $(DISTVNAME).tar
[CMD]$(NOECHO) $(ECHO) "Created $(DISTVNAME).tar$(SUFFIX) file"
[CMD]$(POSTOP)

distdir :
[CMD]$(NOECHO) $(ECHO) "Snapshot creating..."
[CMD]$(RM_RF) $(DISTVNAME)
[CMD]$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" -e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"
[CMD]$(NOECHO) $(ECHO) "Created $(DISTVNAME) directory"
EOS
}
sub sec_untar {<<'EOS'
untar :
[CMD]$(NOECHO) $(ECHO) "Extracting..."
[CMD]- $(COMPRESS) -d $(DIR_RESTORE)$(DFSEP)*$(SUFFIX)
[CMD]$(PERLMTOKEN) -e untar -- $(DIR_RESTORE)$(DFSEP)*.tar $(DIR_RESTORE)
EOS
}
sub sec_gengpgkey {<<'EOS'
gengpgkey : $(DIR_TMP)$(DFSEP).exists $(DIR_KEYS)$(DFSEP)$(MY_PUBLIC_KEY) $(DIR_KEYS)$(DFSEP)$(MY_PRIVATE_KEY)
[CMD]$(NOECHO) $(NOOP)

$(DIR_TMP)$(DFSEP)pubring.kbx :
[CMD]$(GPGBIN) $(GPGFLAGS) --full-gen-key
[CMD]$(GPGBIN) $(GPGFLAGS) -k | $(PERLMTOKEN) -e gpgrecipient -- $(GPGCONFFILE)
[CMD]$(NOECHO) $(TOUCH) $(DIR_TMP)$(DFSEP)pubring.kbx

$(DIR_KEYS)$(DFSEP)$(MY_PUBLIC_KEY) : $(DIR_TMP)$(DFSEP)pubring.kbx
[CMD]$(GPGBIN) $(GPGFLAGS) --export -a -o $(DIR_KEYS)$(DFSEP)$(MY_PUBLIC_KEY)

$(DIR_KEYS)$(DFSEP)$(MY_PRIVATE_KEY) : $(DIR_TMP)$(DFSEP)pubring.kbx
[CMD]$(GPGBIN) $(GPGFLAGS) --export-secret-keys -a -o $(DIR_KEYS)$(DFSEP)$(MY_PRIVATE_KEY)
EOS
}
sub sec_encrypt {<<'EOS'
encrypt : $(DISTVNAME).asc
[CMD]$(NOECHO) $(NOOP)

$(DISTVNAME).asc : $(DISTVNAME).tar$(SUFFIX) $(PUBLIC_GPG_KEY)
[CMD]$(NOECHO) $(ECHO) "Encrypting..."
[CMD]$(PERLMTOKEN) -e encrypt -- $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).asc
[CMD]$(RM_F) $(DISTVNAME).tar$(SUFFIX)
[CMD]$(NOECHO) $(ECHO) "Created $(DISTVNAME).asc file"

$(PUBLIC_GPG_KEY) :
[CMD]$(NOECHO) $(ECHO) "Getting GPG public key file"
[CMD]$(PERLMTOKEN) -e cpgpgkey -- $(PUBLIC_GPG_KEY)
EOS
}
sub sec_decrypt {<<'EOS'
decrypt : $(PRIVATE_GPG_KEY)
[CMD]$(NOECHO) $(ECHO) "Decrypting..."
[CMD]$(PERLMTOKEN) -e decrypt -- $(DIR_RESTORE)$(DFSEP)* .tar$(SUFFIX)
[CMD]- $(RM_RF) $(DIR_RESTORE)$(DFSEP)*.gpg

$(PRIVATE_GPG_KEY) :
[CMD]$(NOECHO) $(ECHO) "Getting GPG private key file"
[CMD]$(PERLMTOKEN) -e cpgpgkey -- $(PRIVATE_GPG_KEY)
EOS
}
sub sec_store {<<'EOS'
store : init $(DIR_BACKUP)$(DFSEP)$(BACKUP)
[CMD]$(NOECHO) $(ECHO) "Uploading created backup to remote server..."
[CMD]$(PERLMTOKEN) -e store -- $(DIR_BACKUP)$(DFSEP)$(BACKUP)
[CMD]$(NOECHO) $(ECHO) "Uploaded $(DIR_BACKUP)$(DFSEP)$(BACKUP) file"

$(DIR_BACKUP)$(DFSEP)$(BACKUP) : $(DISTVNAME).asc
[CMD]$(NOECHO) $(ECHO) "Preparing file to backup..."
[CMD]$(NOECHO) $(MKPATH) $(DIR_BACKUP)
[CMD]$(MV) $(DISTVNAME).asc $(DIR_BACKUP)$(DFSEP)$(BACKUP)
[CMD]$(NOECHO) $(ECHO) "Created $(DIR_BACKUP)$(DFSEP)$(BACKUP) file"
EOS
}
sub sec_fetch {<<'EOS'
fetch : init $(DIR_RESTORE)$(DFSEP).exists list
[CMD]$(NOECHO) $(ECHO) "Downloading backup files from remote server..."
[CMD]$(PERLMTOKEN) -e fetch -- $(DIR_RESTORE)
[CMD]$(NOECHO) $(ECHO) "Downloaded backup files to $(DIR_RESTORE)"

$(DIR_RESTORE)$(DFSEP).exists :
[CMD]$(NOECHO) $(MKPATH) $(DIR_RESTORE)
[CMD]$(NOECHO) $(TOUCH) $(DIR_RESTORE)$(DFSEP).exists
EOS
}
sub sec_list {<<'EOS'
list : init
[CMD]$(PERLMTOKEN) -e list

ls : list
[CMD]$(NOECHO) $(NOOP)
EOS
}
sub sec_info {<<'EOS'
info : init
[CMD]$(PERLMTOKEN) -e info -- $(DATE_SFX)
EOS
}
sub sec_backupdelete {<<'EOS'
backupdelete : init
[CMD]$(NOECHO) $(ECHO) "Deleting backup on remote server..."
[CMD]$(PERLMTOKEN) -e backupdelete -- $(BACKUP)
EOS
}
sub sec_backupupdate {<<'EOS'
backupupdate : init $(DIR_BACKUP)$(DFSEP)$(BACKUP)
[CMD]$(NOECHO) $(ECHO) "Updating backup on remote server..."
[CMD]$(PERLMTOKEN) -e backupupdate -- $(DIR_BACKUP)$(DFSEP)$(BACKUP)
[CMD]$(NOECHO) $(ECHO) "Updated $(DIR_BACKUP)$(DFSEP)$(BACKUP) file"
EOS
}
sub sec_cleanup {<<'EOS'
clean purge ::
[CMD]- $(TEST_F) MANIFEST.SKIP.bak && $(MV) MANIFEST.SKIP.bak MANIFEST.SKIP
[CMD]- $(RM_F) \
  MYMETA.json \
  MYMETA.yml
[CMD]- $(RM_RF) \
  *.bak *.tmp build $(DIR_TMP) \
  $(DISTVNAME) $(DIR_BACKUP) $(DIR_RESTORE)
[CMD]$(NOECHO) $(RM_F) $(FIRST_MAKEFILE)
EOS
}
sub sec_serverconfig {<<'EOS'
serverconfig : $(CONFIGURED)
[CMD]$(NOECHO) $(PERLMTOKEN) -e serverconfig
EOS

}
sub sec_check {<<'EOS'
check : init
[CMD]$(NOECHO) $(ECHO) "Checking your device..."
[CMD]$(NOECHO) $(PERLMTOKEN) -e check -- $(DATE_FMT)
[CMD]$(NOECHO) $(ECHO) "Checking remote server..."
[CMD]$(NOECHO) $(PERLMTOKEN) -e list
[CMD]$(NOECHO) $(ECHO) "Checking the actual backup file..."
[CMD]$(NOECHO) $(PERLMTOKEN) -e info -- $(DATE_SFX)

test : check
[CMD]$(NOECHO) $(NOOP)
EOS
}
sub sec_add {<<'EOS'
add :
[CMD]$(NOECHO) $(ECHO) "Add file(s) on device..."
[CMD]$(NOECHO) $(PERLMTOKEN) -e add -- $(DATE_FMT)
EOS
}
sub sec_update {<<'EOS'
update :
[CMD]$(NOECHO) $(ECHO) "Update files on device..."
[CMD]$(NOECHO) $(PERLMTOKEN) -e update -- $(DATE_FMT)

up : update
EOS
}
sub sec_delete {<<'EOS'
delete :
[CMD]$(NOECHO) $(ECHO) "Remove file from device..."
[CMD]$(NOECHO) $(PERLMTOKEN) -e del

del : delete
EOS
}

sub sec_usage {
my $usage = <<'EOS';
Usage:
    perl Makefile.PL
    make
    make update
    make clean

Commands:
    init -- initialization and configuration your device
    config -- configuration your device
    reconfig -- reconfiguration your device
    gengpgkey -- generate GPG private/public keys pair
    show -- show files on the your device
    check -- checking files in your device
    clean -- clean the device
    serverconfig -- show configuration file for Apache2 web server
    add -- add file(s) to device (manifest file edit)
    update, up -- update files on device (manifest file edit)
    delete, del -- remove file(s) from device
    usage, help -- show this information
    (default) -- show statistic information

Backup commands:
    backup -- backup your device (check, tar, encrypt, store)
    restore -- restore previous backups (check, fetch, decrypt, untar)
    tar -- create the backup archive (.tar.gz)
    untar -- extract files from the downloaded backup archive
    encrypt -- encrypt the created backup file (via GPG)
    decrypt -- decrypt downloaded files from remote server (via GPG)
    store -- upload the created backup file to remote server
    fetch -- download the backup file (files) from remote server
    list -- get list of the backup files stored on remote server
    info -- get information about last backup file (from remote server)
    backupupdate -- update backup file on remote server
    backupdelete -- delete backup file from remote server

EOS
    my $out = "usage :\n";
    foreach my $s (split(/\n/, $usage)) {
        $out .= sprintf('[CMD]$(NOECHO) $(ECHO) "%s"', $s);
        $out .= "\n";
    }
    return $out;
}
sub sec_help {<<'EOS'
help : usage
[CMD]$(NOECHO) $(NOOP)
EOS
}

1;
