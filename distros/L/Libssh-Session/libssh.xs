#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <errno.h>
#include <libssh/libssh.h>
#include <libssh/callbacks.h>
#include "channel.h"

void my_channel_close_function(ssh_session session, ssh_channel channel, void *userdata) {
    printf("in callback close===\n");
}

void my_channel_exit_status_function(ssh_session session, ssh_channel channel, int exit_status, void *userdata) {
    printf("in callback exit===\n");
}

int my_channel_data_function(ssh_session session, ssh_channel channel, void *data, uint32_t len, int is_stderr, void *userdata) {
    printf("in callback data = %s ==\n", (char *)data);
    return 0;
}

/* C functions */

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

 
MODULE = Libssh::Session		PACKAGE = Libssh::Event

# XS code

PROTOTYPES: ENABLED
    
ssh_event
ssh_event_new()
    CODE:
        RETVAL = ssh_event_new();
    OUTPUT: RETVAL

NO_OUTPUT void
ssh_event_free(ssh_event event)
    CODE:
        ssh_event_free(event);

int 
ssh_event_add_session(ssh_event event, ssh_session session)
    CODE:
        RETVAL = ssh_event_add_session(event, session);
    OUTPUT: RETVAL

int
ssh_event_remove_session(ssh_event event, ssh_session session)
    CODE:
        RETVAL = ssh_event_remove_session(event, session);
    OUTPUT: RETVAL

int
ssh_event_dopoll(ssh_event event, int timeout)
    CODE:
        RETVAL = ssh_event_dopoll(event, timeout);
    OUTPUT: RETVAL

int
ssh_channel_exit_status_callback(ssh_channel channel, char *userdata)
    CODE:
        struct ssh_channel_callbacks_struct cb = {
            .userdata = NULL,
            .channel_data_function = my_channel_data_function,
            .channel_exit_status_function = my_channel_exit_status_function
        };
        ssh_callbacks_init(&cb);
        RETVAL = ssh_set_channel_callbacks(channel, &cb);
    OUTPUT: RETVAL
