#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <errno.h>
#include <libssh/libssh.h>
#include <libssh/sftp.h>
#include <libssh/callbacks.h>
#include "channel.h"

/* C functions */

void store_attributes_inHV(sftp_attributes attributes, HV *hv) {
    dTHX;

    (void)hv_store(hv, "size", 4, newSViv(attributes->size), 0);
    (void)hv_store(hv, "type", 4, newSViv(attributes->type), 0);
    (void)hv_store(hv, "flags", 5, newSViv(attributes->flags), 0);
    (void)hv_store(hv, "uid", 3, newSViv(attributes->uid), 0);
    (void)hv_store(hv, "gid", 3, newSViv(attributes->gid), 0);
    (void)hv_store(hv, "mtime", 5, newSViv(attributes->mtime), 0);
    (void)hv_store(hv, "permissions", 11, newSViv(attributes->permissions), 0);
        
    if (attributes->owner != NULL) {
        (void)hv_store(hv, "owner", 5, newSVpv(attributes->owner, strlen(attributes->owner)), 0);
    } else {
        (void)hv_store(hv, "owner", 5, newSV(0), 0);
    }
    
    if (attributes->group != NULL) {
        (void)hv_store(hv, "group", 5, newSVpv(attributes->group, strlen(attributes->group)), 0);
    } else {
        (void)hv_store(hv, "group", 5, newSV(0), 0);
    }
    
    // it's null when we use sftp_lstat
    if (attributes->name != NULL) {
        (void)hv_store(hv, "name", 4, newSVpv(attributes->name, strlen(attributes->name)), 0);
    } else {
        (void)hv_store(hv, "name", 4, newSV(0), 0);
    }
    
    sftp_attributes_free(attributes);
}

MODULE = Libssh::Session		PACKAGE = Libssh::Session

# XS code

PROTOTYPES: ENABLED

ssh_session
ssh_new()
    CODE:
        RETVAL = ssh_new();
    OUTPUT: RETVAL

int
ssh_connect(ssh_session session)
    CODE:
        RETVAL = ssh_connect(session);
    OUTPUT: RETVAL

socket_t
ssh_get_fd(ssh_session session)
    CODE:
        RETVAL = ssh_get_fd(session);
    OUTPUT: RETVAL
    
#
# ssh_options_set functions
#

int
ssh_options_set_host(ssh_session session, char *host)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_HOST, host);
    OUTPUT: RETVAL
    
int
ssh_options_set_port(ssh_session session, int port)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_PORT, &port);
    OUTPUT: RETVAL

int
ssh_options_set_user(ssh_session session, char *user)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_USER, user);
    OUTPUT: RETVAL

int
ssh_options_set_timeout(ssh_session session, long timeout)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_TIMEOUT, &timeout);
    OUTPUT: RETVAL

int
ssh_options_set_stricthostkeycheck(ssh_session session, int value)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_STRICTHOSTKEYCHECK, &value);
    OUTPUT: RETVAL

int
ssh_options_set_ssh_dir(ssh_session session, char *ssh_dir)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_SSH_DIR, ssh_dir);
    OUTPUT: RETVAL

int
ssh_options_set_knownhosts(ssh_session session, char *knownhosts)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_KNOWNHOSTS, knownhosts);
    OUTPUT: RETVAL

int
ssh_options_set_identity(ssh_session session, char *identity)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_IDENTITY, identity);
    OUTPUT: RETVAL

int
ssh_options_set_log_verbosity(ssh_session session, int verbosity)
    CODE:
        RETVAL = ssh_options_set(session, SSH_OPTIONS_LOG_VERBOSITY, &verbosity);
    OUTPUT: RETVAL

#
# ssh auth
#

int
ssh_userauth_password(ssh_session session, char *password)
    CODE:
        RETVAL = ssh_userauth_password(session, NULL, password);
    OUTPUT: RETVAL

int
ssh_userauth_publickey_auto(ssh_session session, char *passphrase, int passdefined)
    CODE:
        if (passdefined == 1) {
            RETVAL = ssh_userauth_publickey_auto(session, NULL, passphrase);
        } else {
            RETVAL = ssh_userauth_publickey_auto(session, NULL, NULL);
        }
    OUTPUT: RETVAL

int
ssh_userauth_none(ssh_session session)
    CODE:
        RETVAL = ssh_userauth_none(session, NULL);
    OUTPUT: RETVAL

int
ssh_userauth_gssapi(ssh_session session)
    CODE:
        RETVAL = ssh_userauth_gssapi(session);
    OUTPUT: RETVAL

char *
ssh_get_issue_banner(ssh_session session)
    CODE:
        RETVAL = ssh_get_issue_banner(session);
    OUTPUT: RETVAL

#

int
ssh_is_server_known(ssh_session session)
    CODE:
        RETVAL = ssh_is_server_known(session);
    OUTPUT: RETVAL

ssh_key 
ssh_get_publickey(ssh_session session)
    CODE:
        ssh_key key;
        int success;
        
        RETVAL = NULL;
        success = ssh_get_publickey(session, &key);
        if (success == SSH_OK) {
            RETVAL = key;
        }
    OUTPUT: RETVAL
    
SV *
ssh_get_publickey_hash(ssh_key key, int type)
    CODE:
        SV *ret;
        unsigned char *hash;
        size_t hlen;
        int success;

        success = ssh_get_publickey_hash(key, type, &hash, &hlen);

        ret = &PL_sv_undef;
        
        if (success == 0) {
            ret = newSVpv((char *)hash, strlen((char *)hash));
            ssh_clean_pubkey_hash(&hash);
        }
        RETVAL = ret;
    OUTPUT: RETVAL

SV *
ssh_get_hexa(unsigned char *what)
    CODE:
        SV *ret;
        char *str;

        str = ssh_get_hexa(what, strlen((char *)what));
        ret = newSVpv(str, strlen(str));
        ssh_string_free_char(str);
        RETVAL = ret;
    OUTPUT: RETVAL

int
ssh_write_knownhost(ssh_session session)
    CODE:
        RETVAL = ssh_write_knownhost(session);
    OUTPUT: RETVAL

const char *
ssh_get_error_from_session(ssh_session session)
    CODE:
        RETVAL = ssh_get_error(session);
    OUTPUT: RETVAL

int
ssh_is_connected(ssh_session session)
    CODE:
        RETVAL = ssh_is_connected(session);
    OUTPUT: RETVAL

NO_OUTPUT void
ssh_disconnect(ssh_session session)
    CODE:
        ssh_disconnect(session);

NO_OUTPUT void
ssh_free(ssh_session session)
    CODE:
        ssh_free(session);
    
NO_OUTPUT void
ssh_key_free(ssh_key key)
    CODE:
        ssh_key_free(key);

#
# channel functions
#

ssh_channel
ssh_channel_new(ssh_session session)
    CODE:
        RETVAL = ssh_channel_new(session);
    OUTPUT: RETVAL

int
ssh_channel_open_session(ssh_channel channel)
    CODE:
        RETVAL = ssh_channel_open_session(channel);
    OUTPUT: RETVAL

NO_OUTPUT void
ssh_channel_free(ssh_channel channel)
    CODE:
        ssh_channel_free(channel);

int
ssh_channel_close(ssh_channel channel)
    CODE:
        RETVAL = ssh_channel_close(channel);
    OUTPUT: RETVAL

int
ssh_channel_is_closed(ssh_channel channel)
    CODE:
        RETVAL = ssh_channel_is_closed(channel);
    OUTPUT: RETVAL

int
ssh_channel_send_eof(ssh_channel channel)
    CODE:
        RETVAL = ssh_channel_send_eof(channel);
    OUTPUT: RETVAL

int
ssh_channel_is_eof(ssh_channel channel)
    CODE:
        RETVAL = ssh_channel_is_eof(channel);
    OUTPUT: RETVAL

char *
ssh_channel_get_id(ssh_channel channel)
    CODE:
        char str[1024];
        
        snprintf(str, 1023, "%i:%i", channel->local_channel, channel->remote_channel);
        RETVAL = str;
    OUTPUT: RETVAL

int
ssh_channel_request_exec(ssh_channel channel, char *cmd)
    CODE:
        RETVAL = ssh_channel_request_exec(channel, cmd);
    OUTPUT: RETVAL

int
ssh_channel_write(ssh_channel channel, char *data)
    CODE:
        RETVAL = ssh_channel_write(channel, data, strlen(data));
    OUTPUT: RETVAL

HV *
ssh_channel_select_read(AV *list, int timeout)
    CODE:
        struct timeval tm;
        ssh_channel *read_channels;
        int ret;
        int list_len;
        int i;
        
        tm.tv_sec = timeout;
        tm.tv_usec = 0;
        
        list_len = av_len(list) + 1;

        Newxz(read_channels, list_len + 1, ssh_channel);
        for (i = 0; i < list_len; i++) {
            SV **svr = av_fetch(list, i, 0);
            
            if (svr == NULL || !SvOK(*svr) || !sv_isobject(*svr) || !sv_isa(*svr, "ssh_channel")) {
                Safefree(read_channels);
                croak("Invalid parameters");
            }
            IV t = SvIV((SV*)SvRV(*svr));
            read_channels[i] = INT2PTR(ssh_channel, t);
        }
        read_channels[i] = NULL;
        
        ret = ssh_channel_select(read_channels, NULL, NULL, &tm);

        HV *hv_ret = newHV();
        AV *channel_ids = newAV();
        char str[1024];
        
        (void)hv_store(hv_ret, "code", 4, newSViv(ret), 0);
        for (i = 0; read_channels[i] != NULL; i++) {
            int num = snprintf(str, 1023, "%i.%i:%i", ssh_get_fd(read_channels[i]->session), read_channels[i]->local_channel, read_channels[i]->remote_channel);
            av_push(channel_ids, newSVpv(str, num));
        }
        
        (void)hv_store(hv_ret, "channel_ids", 11, newRV_noinc((SV *)channel_ids), 0);

        Safefree(read_channels);
        RETVAL = hv_ret;
    OUTPUT: RETVAL

HV *
ssh_channel_read(ssh_channel channel, int buffer_size, int stderr, int nonblocking)
    CODE:
        HV *hv_ret = newHV();
        char *buffer;
        int ret;
        
        Newxz(buffer, buffer_size + 1, char);
        if (nonblocking == 1) {
            ret = ssh_channel_read_nonblocking(channel, buffer, buffer_size, stderr);
        } else {
            ret = ssh_channel_read(channel, buffer, buffer_size, stderr);
        }
        (void)hv_store(hv_ret, "code", 4, newSViv(ret), 0);
        if (ret > 0) {
            (void)hv_store(hv_ret, "message", 7, newSVpv(buffer, ret), 0);
        } else {
            (void)hv_store(hv_ret, "message", 7, newSV(0), 0);
        }
        
        Safefree(buffer);
        RETVAL = hv_ret;
    OUTPUT: RETVAL

int
ssh_channel_get_exit_status(ssh_channel channel)
    CODE:
        RETVAL = ssh_channel_get_exit_status(channel);
    OUTPUT: RETVAL

char *
get_strerror()
    CODE:
        RETVAL = strerror(errno);
    OUTPUT: RETVAL


MODULE = Libssh::Session		PACKAGE = Libssh::Sftp

# XS code

PROTOTYPES: ENABLED

sftp_session
sftp_new(ssh_session session)
    CODE:
        RETVAL = sftp_new(session);
    OUTPUT: RETVAL

int
sftp_init(sftp_session sftp)
    CODE:
        RETVAL = sftp_init(sftp);
    OUTPUT: RETVAL
    
int
sftp_get_error(sftp_session sftp)
    CODE:
        RETVAL = sftp_get_error(sftp);
    OUTPUT: RETVAL

NO_OUTPUT void
sftp_free(sftp_session sftp)
    CODE:
        sftp_free(sftp);

HV *
sftp_lstat(sftp_session sftp, char *file)
    CODE:
        HV *hv_ret = NULL;
        sftp_attributes attributes;
        
        attributes = sftp_lstat(sftp, file);
        if (attributes != NULL) {
            hv_ret = newHV();
            store_attributes_inHV(attributes, hv_ret);
        } else {
            XSRETURN_UNDEF;
        }
        RETVAL = hv_ret;
    OUTPUT: RETVAL

sftp_dir
sftp_opendir(sftp_session sftp, char *dir)
    CODE:
        sftp_dir handle_dir = sftp_opendir(sftp, dir);
        if (handle_dir == NULL) {
            XSRETURN_UNDEF;
        }
        RETVAL = handle_dir;
    OUTPUT: RETVAL

HV *
sftp_readdir(sftp_session sftp, sftp_dir dir)
    CODE:
        HV *hv_ret = NULL;
        sftp_attributes attributes;
        
        attributes = sftp_readdir(sftp, dir);
        if (attributes != NULL) {
            hv_ret = newHV();
            store_attributes_inHV(attributes, hv_ret);
        } else {
            XSRETURN_UNDEF;
        }
        RETVAL = hv_ret;
    OUTPUT: RETVAL

int
sftp_dir_eof(sftp_dir dir)
    CODE:
        RETVAL = sftp_dir_eof(dir);
    OUTPUT: RETVAL

int
sftp_closedir(sftp_dir dir)
    CODE:
        RETVAL = sftp_closedir(dir);
    OUTPUT: RETVAL

sftp_file
sftp_open(sftp_session sftp, char *file, int accesstype, mode_t mode)
    CODE:
        sftp_file fileret = sftp_open(sftp, file, accesstype, mode);
        
        if (fileret == NULL) {
            XSRETURN_UNDEF;
        }
        RETVAL = fileret;
    OUTPUT: RETVAL

size_t
sftp_write(sftp_file file, char *buf)
    CODE:
        RETVAL = sftp_write(file, (void *)buf, strlen(buf));
    OUTPUT: RETVAL

int
sftp_close(sftp_file file)
    CODE:
        RETVAL = sftp_close(file);
    OUTPUT: RETVAL

int
sftp_unlink(sftp_session sftp, char *file)
    CODE:
        RETVAL = sftp_unlink(sftp, file);
    OUTPUT: RETVAL
