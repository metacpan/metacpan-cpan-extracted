package Lemonldap::NG::Handler::Main::MsgActions;

use strict;
use Exporter 'import';

our @EXPORT = qw(msgActions addMsgAction delMsgAction);

our $msgActions = {
    newConf => sub {
        my ( $class, $msg, $req ) = @_;
        unless ( $class->checkConf() ) {
            $class->logger->error("$class: No configuration found");
            $req->data->{noTry} = 1;
        }
    },
    unlog => sub {
        my ( $class, $msg, $req ) = @_;
        $class->localUnlog( $req, $msg->{id} );
    },
};

sub msgActions { return $msgActions }

sub addMsgAction {
    my ( $name, $sub ) = @_;
    $msgActions->{$name} = $sub;
}

sub delMsgAction {
    my ($name) = @_;
    delete $msgActions->{$name};
}

1;
