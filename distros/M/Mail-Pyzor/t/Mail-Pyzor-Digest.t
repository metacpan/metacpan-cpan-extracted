#!/usr/local/cpanel/3rdparty/bin/perl -w

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# Apache 2.0 license.

package t::Mail::Pyzor::Digest;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw(
  Test::Class
);

use Test::More;
use Test::FailWarnings;

use Test::Mail::Pyzor ();

use Data::Dumper ();
use File::Slurp  ();
use File::Which  ();
use IO::Pty      ();

use Mail::Pyzor::Digest ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

sub SKIP_CLASS {
    my ($self) = @_;

    return $self->{'_pyzor_bin'} ? q<> : 'No “pyzor” binary found.';
}

#e.g., num_method_tests()
sub new {
    my ( $class, @args ) = @_;
    my $self = $class->SUPER::new(@args);

    $self->{'_pyzor_bin'} = File::Which::which('pyzor');

    $self->{'_message_hr'} = Test::Mail::Pyzor::get_test_emails_hr();

    $self->num_method_tests( test_get => 1 * keys %{ $self->{'_message_hr'} } );

    return $self;
}

sub _run_pyzor {
    my ( $self, $cmd, $msg_text ) = @_;

    # Ugh. This is really ugly because the pyzor client script doesn’t know
    # how to output UTF-8 to a pipe.
    # https://github.com/SpamExperts/pyzor/issues/71

    my $pty = IO::Pty->new();

    # Although pyzor requires a pty for STDOUT,
    # it can still take a pipe as STDIN.
    pipe my $cr, my $pw;

    my $pid = fork or do {
        close $pw;

        my $slv = $pty->slave();
        close $pty;

        open \*STDIN,  '<&=', $cr  or die "redirect STDIN: $!";
        open \*STDOUT, '>&=', $slv or die "redirect STDOUT: $!";

        exec { $self->{'_pyzor_bin'} } $self->{'_pyzor_bin'}, $cmd or do {
            warn "exec($self->{'_pyzor_bin'} $cmd): $!";
            exit 1;
        };
    };

    close $cr;

    syswrite $pw, $msg_text;
    close $pw;

    $pty->blocking(0);

    my $finished;

    my $out = q<>;

    # This is wonky, but the alternative is a messy-ish thing where we
    # select() on a SIGCHLD self-pipe and the PTY until the self-pipe
    # indicates we’ve gotten SIGCHLD, then read the PTY until we get
    # EAGAIN. It’s simpler--though hackier--just to do it this way.
    while (1) {
        CORE::sysread( $pty, $out, 65536, length $out ) or do {
            local $?;

            last if $finished;

            if ( CORE::waitpid $pid, 1 ) {
                $finished = 1;
                die "failed: $?" if $? && $? != -1;
            }
        };
    }

    close $pty;

    return $out;
}

sub _get_predigest_from_pyzor {
    my ( $self, $msg_text ) = @_;

    return $self->_run_pyzor( 'predigest', $msg_text );
}

sub _get_digest_from_pyzor {
    my ( $self, $msg_text ) = @_;

    my $digest = $self->_run_pyzor( 'digest', $msg_text );
    $digest =~ s<\s+\z><>;

    return $digest;
}

sub test_get : Tests() {
    my ($self) = @_;

    for my $name ( sort keys %{ $self->{'_message_hr'} } ) {
        my $msg_sr = $self->{'_message_hr'}{$name};

        my $perl_digest = do {
            local $SIG{'__WARN__'} = sub { };
            Mail::Pyzor::Digest::get($$msg_sr);
        };

        my $expect = Test::Mail::Pyzor::EMAIL_DIGEST()->{$name};
        $expect ||= $self->_get_digest_from_pyzor($$msg_sr);

        is( $perl_digest, $expect, $name ) or do {
            diag( "we deduced: " . Test::Mail::Pyzor::dump( ${ Mail::Pyzor::Digest::_get_predigest($$msg_sr) } ) );

            diag( "should be : " . Test::Mail::Pyzor::dump( $self->_get_predigest_from_pyzor($$msg_sr) ) );
        };
    }

    return;
}

use constant _TEXT_TEMPLATE => <<'END';
MIME-Version: 1.0
Sender: chirila@spamexperts.com
Received: by 10.216.90.129 with HTTP; Fri, 23 Aug 2013 01:59:03 -0700 (PDT)
Date: Fri, 23 Aug 2013 11:59:03 +0300
Delivered-To: chirila@spamexperts.com
X-Google-Sender-Auth: p6ay4c-tEtdFpavndA9KBmP0CVs
Message-ID: <CAK-mJS9aV6Kb7Z5XCRJ_z_UOKEaQjRY8gMzsuxUQcN5iqxNWUg@mail.gmail.com>
Subject: Test
From: Alexandru Chirila <chirila@spamexperts.com>
To: Alexandru Chirila <chirila@spamexperts.com>
Content-Type: multipart/alternative; boundary=001a11c2893246a9e604e4999ea3

--001a11c2893246a9e604e4999ea3
Content-Type: text/plain; charset=ISO-8859-1

%s

--001a11c2893246a9e604e4999ea3
END

sub test_get__pyzor_string_tests : Tests(9) {
    my ($self) = @_;

    my @string_inserts = (
        't@abc.ro',
        't1@abc.ro',
        't+@abc.ro',
        't.@abc.ro',

        '0A2D3f%a#S',
        '3sddkf9jdkd9',
        '@@#@@@@@@@@@',

        join( "\n", 'This line is included', 'not this', 'This also' ),

        join( "\n", 'All this message', 'Should be included', 'In the predigest' ),
    );

    for my $insert (@string_inserts) {
        my $msg = sprintf( _TEXT_TEMPLATE(), $insert );

        my $digest = $self->_get_digest_from_pyzor($msg);

        is( Mail::Pyzor::Digest::get($msg), $digest, $insert ) or do {
            diag( "we deduced: " . Test::Mail::Pyzor::dump( ${ Mail::Pyzor::Digest::_get_predigest($msg) } ) );

            diag( "should be : " . Test::Mail::Pyzor::dump( $self->_get_predigest_from_pyzor($msg) ) );
        };
    }

    return;
}

1;
