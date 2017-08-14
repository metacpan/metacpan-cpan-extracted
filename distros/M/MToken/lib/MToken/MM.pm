package MToken::MM; # $Id: MM.pm 44 2017-07-31 14:44:24Z minus $
use strict;

=head1 NAME

MToken::MM - MakeMaker helper's functions

=head1 VIRSION

Version 1.00

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

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>

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

use MToken::Const qw/ :GENERAL :CRYPT /;
use MToken::Config;
use Sys::Hostname;
use CTK::Util;
use MToken::Util;

use vars qw/ $VERSION /;
$VERSION = "1.00";

use constant {
    HOSTNAME => 'localhost',
    PHONY => [qw/
            all show init config reconfig
            check test
            add delete del update up
            backup restore
            tar untar
            encrypt decrypt
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
        PUBLIC_GPG_KEY	=> catfile(DIR_CERTS, PUBLIC_GPG_KEY),
        PRIVATE_GPG_KEY => catfile(DIR_CERTS, PRIVATE_GPG_KEY),
        HOSTNAME        => $self->{host},
        CONFIGURED      => catfile(DIR_ETC, sprintf(".%s", $self->{host})),
        CONFFILE        => catfile(DIR_ETC, MToken::Config::GLOBAL_CONF_FILE()),
        GPGCONFFILE     => catfile(DIR_ETC, GPGCONFFILE),
        KEYSUFFIX       => KEYSUFFIX,
        GPGBIN			=> which($config->get('gpgbin') || GPGBIN) || GPGBIN,
        OPENSSLBIN      => which($config->get("opensslbin") || OPENSSLBIN) || OPENSSLBIN,
        GPGFLAGS        => '--options .$(DFSEP)$(GPGCONFFILE) --homedir .$(DFSEP)$(DIR_TMP)',
    }
}

sub sec_all {<<'EOS'
all :: Makefile.PL init
	$(NOECHO) $(PERLMTOKEN) -e show
EOS
}
sub sec_show {<<'EOS'
show :: Makefile.PL init
	$(NOECHO) $(PERLMTOKEN) -e show
EOS
}
sub sec_init {<<'EOS'
init : $(CONFIGURED) $(DIR_KEYS)$(DFSEP)$(PROJECT)$(KEYSUFFIX)
	$(NOECHO) $(NOOP)

$(DIR_KEYS)$(DFSEP)$(PROJECT)$(KEYSUFFIX) :
	$(NOECHO) $(ECHO) "Initializing..."
	$(PERLMTOKEN) -e genkey -- $(DIR_KEYS)$(DFSEP)$(PROJECT)$(KEYSUFFIX)
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest
	$(NOECHO) $(ECHO) "Done."
EOS
}
sub sec_config {<<'EOS'
config : reconfig $(CONFIGURED)
	$(NOECHO) $(NOOP)

$(CONFIGURED) : $(DIR_ETC)$(DFSEP)mtoken.conf
	$(NOECHO) $(ECHO) "Configuration..."
	$(CONFIGURE) $(PROJECT) $(CONFIGURED)
	$(NOECHO) $(TOUCH) $(CONFIGURED)
	$(NOECHO) $(ECHO) "Done."

reconfig :
	-$(RM_F) $(CONFIGURED)
	$(NOECHO) $(ECHO) "Please run the follow command:"
	$(NOECHO) $(ECHO) "    make config"
EOS
}
sub sec_backup {<<'EOS'
backup : check tar encrypt store
	$(NOECHO) $(NOOP)
EOS
}
sub sec_restore {<<'EOS'
restore : fetch decrypt untar
	$(NOECHO) $(NOOP)
EOS
}
sub sec_tar {<<'EOS'
tar : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(NOECHO) $(ECHO) "Compressing..."
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(NOECHO) $(ECHO) "Created $(DISTVNAME).tar$(SUFFIX) file"
	$(POSTOP)

distdir :
	$(NOECHO) $(ECHO) "Snapshot creating..."
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" -e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"
	$(NOECHO) $(ECHO) "Created $(DISTVNAME) directory"
EOS
}
sub sec_untar {<<'EOS'
untar :
	$(NOECHO) $(ECHO) "Decompressing..."
	- $(COMPRESS) -d $(DIR_RESTORE)$(DFSEP)*$(SUFFIX)
	$(PERLMTOKEN) -e untar -- $(DIR_RESTORE)$(DFSEP)*.tar $(DIR_RESTORE)
EOS
}
sub sec_encrypt {<<'EOS'
encrypt : $(DISTVNAME).asc
	$(NOECHO) $(NOOP)

$(DISTVNAME).asc : $(DISTVNAME).tar$(SUFFIX) $(PUBLIC_GPG_KEY)
	$(NOECHO) $(ECHO) "Encrypting..."
	$(NOECHO) $(MKPATH) $(DIR_TMP)
	$(NOECHO) $(CHMOD) 700 $(DIR_TMP)
	$(GPGBIN) $(GPGFLAGS) --import $(PUBLIC_GPG_KEY)
	$(GPGBIN) $(GPGFLAGS) --list-keys | $(PERLMTOKEN) -e gpgrecipient -- $(GPGCONFFILE)
	$(GPGBIN) $(GPGFLAGS) --always-trust -o $(DISTVNAME).asc -a -e $(DISTVNAME).tar$(SUFFIX)
	$(RM_F) $(DISTVNAME).tar$(SUFFIX)
	- $(RM_RF) $(DIR_TMP)
	$(NOECHO) $(ECHO) "Created $(DISTVNAME).asc file"

$(PUBLIC_GPG_KEY) :
	$(NOECHO) $(ECHO) "Getting GPG public key file"
	$(PERLMTOKEN) -e cpgpgkey -- $(PUBLIC_GPG_KEY)
EOS
}
sub sec_decrypt {<<'EOS'
decrypt : $(PRIVATE_GPG_KEY)
	$(NOECHO) $(ECHO) "Decrypting..."
	$(NOECHO) $(MKPATH) $(DIR_TMP)
	$(NOECHO) $(CHMOD) 700 $(DIR_TMP)
	$(GPGBIN) $(GPGFLAGS) --import $(PRIVATE_GPG_KEY)
	$(GPGBIN) $(GPGFLAGS) --list-secret-keys | $(PERLMTOKEN) -e gpgrecipient -- $(GPGCONFFILE)
	$(PERLMTOKEN) -e gpgfileprepare -- $(DIR_RESTORE)$(DFSEP)* .tar$(SUFFIX).gpg
	$(GPGBIN) $(GPGFLAGS) --decrypt-files $(DIR_RESTORE)$(DFSEP)*.gpg
	- $(RM_RF) $(DIR_RESTORE)$(DFSEP)*.gpg
	- $(RM_RF) $(DIR_TMP)

$(PRIVATE_GPG_KEY) :
	$(NOECHO) $(ECHO) "Getting GPG private key file"
	$(PERLMTOKEN) -e cpgpgkey -- $(PRIVATE_GPG_KEY)
EOS
}
sub sec_store {<<'EOS'
store : $(DIR_BACKUP)$(DFSEP)$(BACKUP)
	$(NOECHO) $(ECHO) "Storing created backup to remote server..."
	$(PERLMTOKEN) -e store -- $(DIR_BACKUP)$(DFSEP)$(BACKUP)

$(DIR_BACKUP)$(DFSEP)$(BACKUP) : $(DISTVNAME).asc
	$(NOECHO) $(ECHO) "Preparing file to backup..."
	$(NOECHO) $(MKPATH) $(DIR_BACKUP)
	$(MV) $(DISTVNAME).asc $(DIR_BACKUP)$(DFSEP)$(BACKUP)
	$(NOECHO) $(ECHO) "Created $(DIR_BACKUP)$(DFSEP)$(BACKUP) file"
EOS
}
sub sec_fetch {<<'EOS'
fetch : $(DIR_RESTORE)$(DFSEP).exists list
	$(NOECHO) $(ECHO) "Fetching backups from remote server..."
	$(PERLMTOKEN) -e fetch -- $(DIR_RESTORE)

$(DIR_RESTORE)$(DFSEP).exists :
	$(NOECHO) $(MKPATH) $(DIR_RESTORE)
	$(NOECHO) $(TOUCH) $(DIR_RESTORE)$(DFSEP).exists
EOS
}
sub sec_list {<<'EOS'
list :
	$(PERLMTOKEN) -e list

ls : list
	$(NOECHO) $(NOOP)
EOS
}
sub sec_info {<<'EOS'
info :
	$(PERLMTOKEN) -e info -- $(DATE_SFX)
EOS
}
sub sec_backupdelete {<<'EOS'
backupdelete :
	$(NOECHO) $(ECHO) "Deleting backup on remote server..."
	$(PERLMTOKEN) -e backupdelete -- $(BACKUP)
EOS
}
sub sec_backupupdate {<<'EOS'
backupupdate : $(DIR_BACKUP)$(DFSEP)$(BACKUP)
	$(NOECHO) $(ECHO) "Updating backup on remote server..."
	$(PERLMTOKEN) -e backupupdate -- $(DIR_BACKUP)$(DFSEP)$(BACKUP)
EOS
}
sub sec_cleanup {<<'EOS'
clean purge ::
	- $(TEST_F) MANIFEST.SKIP.bak && $(MV) MANIFEST.SKIP.bak MANIFEST.SKIP
	- $(RM_F) \
		MYMETA.json \
		MYMETA.yml
	- $(RM_RF) \
		*.bak *.tmp build \
		$(DISTVNAME) $(DIR_BACKUP) $(DIR_RESTORE)
	$(NOECHO) $(RM_F) $(FIRST_MAKEFILE)
EOS
}
sub sec_serverconfig {<<'EOS'
serverconfig : $(CONFIGURED)
	$(NOECHO) $(PERLMTOKEN) -e serverconfig
EOS

}
sub sec_check {<<'EOS'
check :
	$(NOECHO) $(ECHO) "Checking your device..."
	$(NOECHO) $(PERLMTOKEN) -e check -- $(DATE_FMT)
	$(NOECHO) $(ECHO) "Checking remote server..."
	$(NOECHO) $(PERLMTOKEN) -e list
	$(NOECHO) $(ECHO) "Checking the actual backup file..."
	$(NOECHO) $(PERLMTOKEN) -e info -- $(DATE_SFX)
test : check
	$(NOECHO) $(NOOP)
EOS
}
sub sec_add {<<'EOS'
add :
	$(NOECHO) $(ECHO) "Add file(s) on device..."
	$(NOECHO) $(PERLMTOKEN) -e add -- $(DATE_FMT)
EOS
}
sub sec_update {<<'EOS'
update :
	$(NOECHO) $(ECHO) "Update files on device..."
	$(NOECHO) $(PERLMTOKEN) -e update -- $(DATE_FMT)
up : update
EOS
}
sub sec_delete {<<'EOS'
delete :
	$(NOECHO) $(ECHO) "Remove file from device..."
	$(NOECHO) $(PERLMTOKEN) -e del
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
    reconfig -- unset configuration flag. Remove $(CONFIGURED) file
    usage, help -- show this information
    show (default) -- show files on the your device
    check -- checking files in your device
    clean -- clean the device
    serverconfig -- show configuration file for Apache2 web server
    add -- add file(s) to device (manifest file edit)
    update, up -- update files on device (manifest file edit)
    delete, del -- remove file(s) from device

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
	$(NOECHO) $(NOOP)
EOS
}

1;
