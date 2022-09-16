package Lemonldap::NG::Portal::Auth::GPG;

use strict;
use File::Temp 'tempdir';
use IPC::Run;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_ERROR
  PE_FORMEMPTY
  PE_NOTOKEN
  PE_OK
);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Auth::_WebForm';

has db => ( is => 'rw' );
has tmp => (
    is      => 'rw',
    default => sub {
        tempdir( CLEANUP => 1 );
    },
);

sub init {
    my $self = shift;

    $self->db( $self->conf->{gpgDb} );
    unless ( $self->db ) {
        $self->error("gpgDb not set");
        return 0;
    }
    unless ( -r $self->db ) {
        $self->error( "Unable to read " . $self->db );
        return 0;
    }

    return $self->SUPER::init();
}

sub extractFormInfo {
    my ( $self, $req ) = @_;

    unless ( $self->ottRule->( $req, {} ) ) {
        $self->error("OTT isn't set, unable to use GPG");
    }

    # Keep token data for later use
    my ( $token, $gpgToken );
    if ( $token = $req->param('token') ) {
        $gpgToken = $self->ott->getToken($token);
        $req->data->{tokenVerified} = 1 if ($gpgToken);
    }
    my $res = $self->SUPER::extractFormInfo($req);
    return $res if ($res);
    my $signed = $req->data->{password};
    unless ( $signed =~ /SIGNATURE/s ) {
        $self->userLogger->error("Bad signature content");
        $self->userLogger->debug($signed);
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    unless ( $signed =~ /\b\Q$token\E\b/ ) {
        $self->userLogger->error("User replayed a bad token in GPG !");
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    my ( $out, $err );
    $self->logger->debug(
"Launching:\ngpgv --homedir /dev/null --keyring $self->{db} <<EOF\n$signed\nEOF"
    );
    my ( $lang, $language ) = ( $ENV{LANG}, $ENV{LANGUAGE} );
    $ENV{LANG} = $ENV{LANGUAGE} = 'C';
    IPC::Run::run( [ 'gpgv', '--homedir', '/dev/null', '--keyring', $self->db ],
        \$signed, \$out, \$err, IPC::Run::timeout(10) );
    if ( $? >> 8 != 0 ) {
        $self->userLogger->error("GPG verification fails:\n$out\n# # #\n$err");
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    $self->setSecurity($req);
    $self->userLogger->notice("Good GPG signature");
    $self->userLogger->debug("GPG out:\n$out\n$err");
    unless ( $err =~ /using .*? key (.*)$/m ) {
        $self->logger->error("Unable to parse gpgv result:\n$err");
        return PE_ERROR;
    }
    my $key = $1;
    chomp $key;
    $self->logger->debug("GPG full sign key: $key");
    my $in;
    IPC::Run::run( [
            'gpg',     '--homedir',  $self->tmp, '--keyring',
            $self->db, '--list-key', $key
        ],
        \$in,
        \$out,
        \$err,
        IPC::Run::timeout(10)
    );
    ( $ENV{LANG}, $ENV{LANGUAGE} ) = ( $lang, $language );
    if ( $? >> 8 != 0 ) {
        $self->logger->error("gpg --list-key return an error:\n$err");
        return PE_ERROR;
    }
    unless ( $out =~ /pub [^\n]*\r?\n +([^\n]+)\n/ ) {
        $self->logger->error(
            "Unable to parse gpg --list-key result:\n$out\n$err\n");
        return PE_ERROR;
    }
    $key = $1;
    chomp $key;
    $self->logger->debug("GPG full master key: $key");

    # Keep only gpgKeyLength characters
    my $length = $self->conf->{gpgKeyLength} || 8;
    $length = 8 if ( $length < 8 );
    $key =~ s/.*?(.{8,$length})$/$1/;
    $self->logger->info("User key: $key");

    my @identities = ( $out =~ /uid\s+(.*)$/gm );
    my $mail       = $req->param('user');
    foreach (@identities) {
        if (/^(.*)\s+<\Q$mail\E>/) {
            $req->data->{gpgFullName} = $1;
            $req->data->{gpgMail}     = $mail;
            $req->user($mail);
            $self->userLogger->notice("GPG user $mail authenticated");
            return PE_OK;
        }
    }
    $self->userLogger->warn("Given mail does not match with gpg key");
    $self->setSecurity($req);
    return PE_BADCREDENTIALS;
}

sub authenticate {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->sessionInfo->{gpgMail}             = $req->data->{gpgMail};
    $req->sessionInfo->{authenticationLevel} = $self->conf->{gpgAuthnLevel};
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

sub getDisplayType {
    return "gpgform";
}

1;
