package MPMinus::BaseHandlers; # $Id: BaseHandlers.pm 145 2013-05-28 16:21:48Z minus $
use strict;

=head1 NAME

MPMinus::BaseHandlers - Base handlers of MPMinus

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    package MPM::foo::Handlers;
    use strict;

    use MPMinus;
    use base qw/MPMinus::BaseHandlers/;
    
    sub new { bless {}, __PACKAGE__ }
    sub handler {
        my $r = shift;
        my $m = MPMinus->m;
        $m->conf_init($r, __PACKAGE__);
        __PACKAGE__->Init($m);

        # Handlers
        $r->handler('modperl'); # modperl, perl-script
        
        $r->set_handlers(PerlHeaderParserHandler => sub { __PACKAGE__->HeaderParserHandler($m) });
        $r->set_handlers(PerlAccessHandler => sub { __PACKAGE__->AccessHandler($m) });
        $r->set_handlers(PerlAuthenHandler => sub { __PACKAGE__->AuthenHandler($m) });
        $r->set_handlers(PerlAuthzHandler => sub { __PACKAGE__->AuthzHandler($m) });
        $r->set_handlers(PerlTypeHandler => sub { __PACKAGE__->TypeHandler($m) });
        $r->set_handlers(PerlFixupHandler => sub { __PACKAGE__->FixupHandler($m) });
        $r->set_handlers(PerlResponseHandler => sub { __PACKAGE__->ResponseHandler($m) });
        $r->set_handlers(PerlLogHandler => sub { __PACKAGE__->LogHandler($m) });
        $r->set_handlers(PerlCleanupHandler => sub { __PACKAGE__->CleanupHandler($m) });
        
        return __PACKAGE__->InitHandler($m);
    }
    sub InitHandler {
        my $pkg = shift;
        my $m = shift;

        # ... Setting Nodes ...
        # $m->set( nodename => ' ... value ... ' ) unless $m->nodename;
        
        ...

        return __PACKAGE__->SUPER::InitHandler($m);
    }

=head1 DESCRIPTION

Base handlers of MPMinus.

See L<http://perl.apache.org/docs/2.0/user/handlers/intro.html>

=head1 METHODS

=over 8

=item B<Init>

    sub handler {
        my $r = shift;
        my $m = MPMinus->m;
        $m->conf_init($r, __PACKAGE__);
        __PACKAGE__->Init($m);
        
        ...
    }

NOTE: This is a required module call of MPM::foo::Handlers

=back

=head1 SERVER LIFE CYCLE HANDLERS

=over 8

=item B<OpenLogsHandler>

    PerlModule            MPM::foo::Handlers
    PerlOpenLogsHandler   MPM::foo::Handlers::OpenLogs
    
    sub OpenLogs {
        my ($conf_pool, $log_pool, $temp_pool, $s) = @_;
        say("process $$ is born to reproduce");
        return Apache2::Const::OK;
    }

The open_logs phase happens just before the post_config phase.

Handlers registered by PerlOpenLogsHandler are usually used for opening module-specific log files 
(e.g., httpd core and mod_ssl open their log files during this phase).

At this stage the STDERR stream is not yet redirected to error_log, and therefore any messages to 
that stream will be printed to the console the server is starting from (if such exists).

    Type  : RUN_ALL
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/server.html>

=item B<PostConfigHandler>

    PerlModule            MPM::foo::Handlers
    PerlPostConfigHandler MPM::foo::Handlers::PostConfig

    sub PostConfig {
        my ($conf_pool, $log_pool, $temp_pool, $s) = @_;
        say("configuration is completed");
        return Apache2::Const::OK;
    }

The post_config phase happens right after Apache has processed the configuration files, before any 
child processes were spawned (which happens at the child_init phase).

This phase can be used for initializing things to be shared between all child processes. You can do 
the same in the startup file, but in the post_config phase you have an access to a complete 
configuration tree (via Apache2::Directive).

    Type  : RUN_ALL
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/server.html>

=item B<ChildInitHandler>

    PerlModule            MPM::foo::Handlers
    PerlChildInitHandler  MPM::foo::Handlers::ChildInit

    sub ChildInit {
        my ($child_pool, $s) = @_;
        say("process $$ is born to serve");
        return Apache2::Const::OK;
    }

The child_init phase happens immediately after the child process is spawned. Each child process 
(not a thread!) will run the hooks of this phase only once in their life-time.

In the prefork MPM this phase is useful for initializing any data structures which should be private 
to each process. For example Apache::DBI pre-opens database connections during this phase and 
Apache2::Resource sets the process' resources limits.

    Type  : VOID
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/server.html>

=item B<ChildExitHandler>

    PerlModule            MPM::foo::Handlers
    PerlChildExitHandler  MPM::foo::Handlers::ChildExit

    sub ChildExit {
        my ($child_pool, $s) = @_;
        my $m = MPMinus->m;
        say("process $$ now exits");
        return Apache2::Const::OK;
    }

Opposite to the child_init phase, the child_exit phase is executed before the child process exits. 
Notice that it happens only when the process exits, not the thread (assuming that you are using a 
threaded mpm).    

    Type  : RUN_ALL
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/server.html>

=back

See L<http://perl.apache.org/docs/2.0/user/handlers/server.html>

=head1 PROTOCOL HANDLERS

These handlers in this section are not considered. See user's guide 
L<http://perl.apache.org/docs/2.0/user/index.html>

=over 8

=item B<PerlPreConnectionHandler>

The pre_connection phase happens just after the server accepts the connection, but before it is 
handed off to a protocol module to be served. It gives modules an opportunity to modify the 
connection as soon as possible and insert filters if needed. The core server uses this phase to 
setup the connection record based on the type of connection that is being used. mod_perl itself 
uses this phase to register the connection input and output filters.

In mod_perl 1.0 during code development Apache::Reload was used to automatically reload modified 
since the last request Perl modules. It was invoked during post_read_request, the first HTTP 
request's phase. In mod_perl 2.0 pre_connection is the earliest phase, so if we want to make sure 
that all modified Perl modules are reloaded for any protocols and its phases, it's the best to set 
the scope of the Perl interpreter to the lifetime of the connection via:

    PerlInterpScope connection

and invoke the Apache2::Reload handler during the pre_connection phase. However this 
development-time advantage can become a disadvantage in production--for example if a connection, 
handled by HTTP protocol, is configured as KeepAlive and there are several requests coming on the 
same connection and only one handled by mod_perl and the others by the default images handler, the 
Perl interpreter won't be available to other threads while the images are being served.

    Type  : RUN_ALL
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/protocols.html>

=item B<PerlProcessConnectionHandler>

he process_connection phase is used to process incoming connections. Only protocol modules should 
assign handlers for this phase, as it gives them an opportunity to replace the standard HTTP 
processing with processing for some other protocols (e.g., POP3, FTP, etc.).

    Type  : RUN_FIRST
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/protocols.html>

=back

=head1 FILTERS

These handlers in this section are not considered. See user's guide, part Input and Output Filters
L<http://perl.apache.org/docs/2.0/user/handlers/filters.html>

    # Set up handlers:
    $r->add_input_filter(\&InputFilterHandler);
    $r->add_output_filter(\&OutputFilterHandler);
    
    # Realisation
    sub InputFilterHandler {
        my ($f, $bb, $mode, $block, $readbytes) = @_; # filter args
        #debug(" -- InputFilterHandler N".($f->ctx?$f->ctx:'0')." (".$f->frec->name.")");

        # runs on first invocation
        unless ($f->ctx) {
            $f->ctx(1);
        }
    
        # runs on all invocations
        while ($f->read(my $buffer, 1024)) {
            # process
        }
    
        # runs on the last invocation
        if ($f->seen_eos) {    
            # finalize
        }
        return Apache2::Const::OK;
    }
    sub OutputFilterHandler {
        my ($f, $bb, $mode, $block, $readbytes) = @_; # filter args
        #debug(" -- OutputFilterHandler N".($f->ctx?$f->ctx:'0')." (".$f->frec->name.")");
    
        # runs on first invocation
        if ($f->ctx) {
            $f->ctx( $f->ctx + 1 )
        } else {
            $f->r->headers_out->unset('Content-Length');
            $f->ctx(1);
        }
    
        # runs on all invocations
        while ($f->read(my $buffer, 1024)) {
            $buffer =~ s/\r?\n/<br>/g;
            #$f->print(CP1251toUTF8($buffer));
            $f->print($buffer);
            
        }
    
        # runs on the last invocation
        if ($f->seen_eos) {    
            $f->print('<div style="margin: 10px; padding: 10px; border: solid 1px red;"><b>OUTPUT_FILTER_TEXT_BANNER</b></div>');
        }
        return Apache2::Const::OK;
    }

=over 8

=item B<PerlInputFilterHandler>

The PerlInputFilterHandler directive registers a filter, and inserts it into the relevant input 
filters chain.

    Type  : VOID
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/filters.html>

=item B<PerlOutputFilterHandler>

The PerlOutputFilterHandler directive registers a filter, and inserts it into the relevant output filters chain.

    Type  : VOID
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/filters.html>

=item B<PerlSetInputFilter>

The SetInputFilter directive, documented at 
L<http://httpd.apache.org/docs-2.0/mod/core.html#setinputfilter>, sets the filter or filters which 
will process client requests and POST input when they are received by the server (in addition to 
any filters configured earlier).

See L<http://perl.apache.org/docs/2.0/user/handlers/filters.html>

=item B<PerlSetOutputFilter>

The SetOutputFilter directive, documented at 
L<http://httpd.apache.org/docs-2.0/mod/core.html#setoutputfilter> sets the filters which will 
process responses from the server before they are sent to the client (in addition to any filters 
configured earlier).

See L<http://perl.apache.org/docs/2.0/user/handlers/filters.html>

=back

=head1 HTTP PROTOCOL HANDLERS

=over 8

=item B<PostReadRequestHandler>

    $r->set_handlers(
            PerlPostReadRequestHandler => 
                sub { __PACKAGE__->PostReadRequestHandler($m) }
        );

The post_read_request phase is the first request phase and happens immediately after the request has 
been read and HTTP headers were parsed.

This phase is usually used to do processing that must happen once per request. For example 
Apache2::Reload is usually invoked at this phase to reload modified Perl modules.

    Type  : RUN_ALL
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<TransHandler>

    $r->set_handlers(
            PerlTransHandler => 
                sub { __PACKAGE__->TransHandler($m) }
        );

The translate phase is used to perform the manipulation of a request's URI. If no custom handler 
is provided, the server's standard translation rules (e.g., Alias directives, mod_rewrite, etc.) 
will be used. A PerlTransHandler handler can alter the default translation mechanism or completely 
override it. This is also a good place to register new handlers for the following phases based on 
the URI. PerlMapToStorageHandler is to be used to override the URI to filename translation.

    Type  : RUN_FIRST
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<MapToStorageHandler>

    $r->set_handlers(
            PerlMapToStorageHandler => 
                sub { __PACKAGE__->MapToStorageHandler($m) }
        );

The map_to_storage phase is used to perform the translation of a request's URI into a corresponding 
filename. If no custom handler is provided, the server will try to walk the filesystem trying to 
find what file or directory corresponds to the request's URI. Since usually mod_perl handler don't 
have corresponding files on the filesystem, you will want to shortcut this phase and save quite a 
few CPU cycles.

    Type  : RUN_FIRST
    Scope : SRV

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<InitHandler>

    $r->set_handlers(
            PerlInitHandler => 
                sub { __PACKAGE__->InitHandler($m) }
        );

When configured inside any container directive, except <VirtualHost>, this handler is an alias for 
PerlHeaderParserHandler described earlier. Otherwise it acts as an alias for 
PerlPostReadRequestHandler described earlier.

It is the first handler to be invoked when serving a request.

    Type  : RUN_ALL

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<HeaderParserHandler>

    $r->set_handlers(
            PerlHeaderParserHandler => 
                sub { __PACKAGE__->HeaderParserHandler($m) }
        );

The header_parser phase is the first phase to happen after the request has been mapped to its 
<Location> (or an equivalent container). At this phase the handler can examine the request headers 
and to take a special action based on these. For example this phase can be used to block evil 
clients targeting certain resources, while little resources were wasted so far.

    Type  : RUN_ALL
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<AccessHandler>

    $r->set_handlers(
            PerlAccessHandler => 
                sub { __PACKAGE__->AccessHandler($m) }
        );

The access_checker phase is the first of three handlers that are involved in what's known as 
AAA: Authentication, Authorization, and Access control.

This phase can be used to restrict access from a certain IP address, time of the day or any other 
rule not connected to the user's identity.

    Type  : RUN_ALL
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<AuthenHandler>

    $r->set_handlers(
            PerlAuthenHandler => 
                sub { __PACKAGE__->AuthenHandler($m) }
        );

The check_user_id (authen) phase is called whenever the requested file or directory is password 
protected. This, in turn, requires that the directory be associated with AuthName, AuthType and at 
least one require directive.

This phase is usually used to verify a user's identification credentials. If the credentials are 
verified to be correct, the handler should return B<Apache2::Const::OK>. Otherwise the handler returns 
B<Apache2::Const::HTTP_UNAUTHORIZED> to indicate that the user has not authenticated successfully. When 
Apache sends the HTTP header with this code, the browser will normally pop up a dialog box that 
prompts the user for login information.

    Type  : RUN_FIRST
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<AuthzHandler>

    $r->set_handlers(
            PerlAuthzHandler => 
                sub { __PACKAGE__->AuthzHandler($m) }
        );

The auth_checker (authz) phase is used for authorization control. This phase requires a successful 
authentication from the previous phase, because a username is needed in order to decide whether a 
user is authorized to access the requested resource.

As this phase is tightly connected to the authentication phase, the handlers registered for this 
phase are only called when the requested resource is password protected, similar to the auth phase. 
The handler is expected to return B<Apache2::Const::DECLINED> to defer the decision, 
B<Apache2::Const::OK> to indicate its acceptance of the user's authorization, or 
B<Apache2::Const::HTTP_UNAUTHORIZED> to indicate that the user is not authorized to access the 
requested document.

    Type  : RUN_FIRST
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<TypeHandler>

    $r->set_handlers(
            PerlTypeHandler => 
                sub { __PACKAGE__->TypeHandler($m) }
        );

The type_checker phase is used to set the response MIME type (Content-type) and sometimes other bits 
of document type information like the document language.

For example mod_autoindex, which performs automatic directory indexing, uses this phase to map the 
filename extensions to the corresponding icons which will be later used in the listing of files.

Of course later phases may override the mime type set in this phase.

    Type  : RUN_FIRST
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<FixupHandler>

    $r->set_handlers(
            PerlFixupHandler => 
                sub { __PACKAGE__->FixupHandler($m) }
        );

The fixups phase is happening just before the content handling phase. It gives the last chance to 
do things before the response is generated. For example in this phase mod_env populates the 
environment with variables configured with SetEnv and PassEnv directives.

    Type  : RUN_ALL
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<ResponseHandler>

    $r->set_handlers(
            PerlResponseHandler => 
                sub { __PACKAGE__->ResponseHandler($m) }
        );

The handler (response) phase is used for generating the response. This is arguably the most 
important phase and most of the existing Apache modules do most of their work at this phase.

This is the only phase that requires two directives under mod_perl.

    Type  : RUN_FIRST
    Scope : DIR

NOTE: This method (ResponseHandler) returns B<Apache2::Const::NOT_FOUND> as default!

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<LogHandler>

    $r->set_handlers(
            PerlLogHandler => 
                sub { __PACKAGE__->LogHandler($m) }
        );

The log_transaction phase happens no matter how the previous phases have ended up. If one of the 
earlier phases has aborted a request, e.g., failed authentication or 404 (file not found) errors, 
the rest of the phases up to and including the response phases are skipped. But this phase is always 
executed.

By this phase all the information about the request and the response is known, therefore the logging 
handlers usually record this information in various ways (e.g., logging to a flat file or a database).

    Type  : RUN_ALL
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=item B<CleanupHandler>

    $r->set_handlers(
            PerlCleanupHandler => 
                sub { __PACKAGE__->CleanupHandler($m) }
        );

There is no cleanup Apache phase, it exists only inside mod_perl. It is used to execute some code 
immediately after the request has been served (the client went away) and before the request object 
is destroyed.

There are several usages for this use phase. The obvious one is to run a cleanup code, for example 
removing temporarily created files. The less obvious is to use this phase instead of PerlLogHandler 
if the logging operation is time consuming. This approach allows to free the client as soon as the 
response is sent.

    Type  : RUN_ALL
    Scope : DIR

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=back

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head1 TYPES

=over 8

=item B<VOID>

Handlers of the type VOID will be all executed in the order they have been registered disregarding 
their return values. Though in mod_perl they are expected to return Apache2::Const::OK.

=item B<RUN_FIRST>

Handlers of the type RUN_FIRST will be executed in the order they have been registered until the 
first handler that returns something other than Apache2::Const::DECLINED. If the return value is 
Apache2::Const::DECLINED, the next handler in the chain will be run. If the return value is 
Apache2::Const::OK the next phase will start. In all other cases the execution will be aborted.

=item B<RUN_ALL>

Handlers of the type RUN_ALL will be executed in the order they have been registered until the first 
handler that returns something other than Apache2::Const::OK or Apache2::Const::DECLINED.

For C API declarations see include/ap_config.h, which includes other types which aren't exposed by 
mod_perl handlers

=back

See L<http://perl.apache.org/docs/2.0/user/handlers/intro.html>

=head1 SCOPES

The Scope row shows the location the directives are allowed to appear in:

=over 8

=item B<SRV>

Global configuration and <VirtualHost> (mnemonic: SeRVer). These directives are defined as RSRC_CONF 
in the source code.

=item B<DIR>

<Directory>, <Location>, <Files> and all their regular expression variants (mnemonic: DIRectory). 
These directives can also appear in .htaccess files. These directives are defined as OR_ALL in the 
source code.

These directives can also appear in the global server configuration and <VirtualHost>.

=back

See L<http://perl.apache.org/docs/2.0/user/config/config.html>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

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

use vars qw($VERSION);
$VERSION = 1.03;

use MPMinus::Dispatcher;
use Apache2::Const;

#
# Init section
#
sub Init {
    my $pkg = shift;
    my $m = shift;
    
    # Dispatcher Nodes
    $m->set(disp => new MPMinus::Dispatcher($m->conf('project'),$m->namespace)) unless $m->disp;
    $m->set(drec => $m->disp->get(-uri=>$m->conf('request_uri')));
    
    return Apache2::Const::OK;
}

#
# HTTP Protocol Handlers
#

sub PostReadRequestHandler {
    #############################################
    # Первая фаза сразу после чтения заголовков #
    #############################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{PostReadRequest}->($m) if $record->{PostReadRequest};
    return Apache2::Const::OK;
}
sub TransHandler {
    #######################################
    # Фаза RewriteURI - манипуляции с URI #
    #######################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Trans}->($m) if $record->{Trans};
    return Apache2::Const::OK;
}
sub MapToStorageHandler {
    ##########################################
    # Фаза привязки запроса к файлу на диске #
    ##########################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{MapToStorage}->($m) if $record->{MapToStorage};
    return Apache2::Const::OK;
}
sub InitHandler {
    ######################
    # Фаза инициализации #
    ######################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Init}->($m) if $record->{Init};
    return Apache2::Const::OK;
}
sub HeaderParserHandler {
    ###########################################
    # Фаза этапа сопоставления Location и URL #
    ###########################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{HeaderParser}->($m) if $record->{HeaderParser};
    return Apache2::Const::OK;
}
sub AccessHandler {
    ###################################################
    # Фаза контроля доступа по IP, веремни дня и т.д. #
    ###################################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Access}->($m) if $record->{Access};
    return Apache2::Const::OK;
}
sub AuthenHandler {
    #################################
    # Фаза проверки логина и пароля #
    #################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Authen}->($m) if $record->{Authen};
    return Apache2::Const::OK;
}
sub AuthzHandler {
    ####################################
    # Фаза проверки прав пользователея #
    ####################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Authz}->($m) if $record->{Authz};
    return Apache2::Const::OK;
}
sub TypeHandler {
    #################################
    # Фаза установки типа #
    #################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Type}->($m) if $record->{Type};
    return Apache2::Const::OK;
}
sub FixupHandler {
    #########################################
    # Фаза подготовки данных, предобработка #
    #########################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Fixup}->($m) if $record->{Fixup};
    return Apache2::Const::OK;
}
sub ResponseHandler {
    ##############################
    # Секция формирования ответа #
    ##############################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Response}->($m) if $record->{Response};
    return Apache2::Const::OK;
} 
sub LogHandler {
    ##############################################################
    # Секция записи данных в логи о событиях. Выполняется всегда #
    ##############################################################
    my $pkg = shift;
    my $m = shift;
    $m->log("Index-record not found", "error") if $m->r->status() == Apache2::Const::NOT_FOUND;
    my $record = $m->drec;
    return $record->{Log}->($m) if $record->{Log};
    return Apache2::Const::OK;
}
sub CleanupHandler {
    ###################################
    # Очистка всех временных структур #
    ###################################
    my $pkg = shift;
    my $m = shift;
    my $record = $m->drec;
    return $record->{Cleanup}->($m) if $record->{Cleanup};
    return Apache2::Const::OK;
}

1;

