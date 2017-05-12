package Lemonldap::NG::Handler::Main::Jail;

use strict;

use Safe;
use Lemonldap::NG::Common::Safelib;    #link protected safe Safe object
use constant SAFEWRAP => ( Safe->can("wrap_code_ref") ? 1 : 0 );
use Mouse;
use Lemonldap::NG::Handler::Main::Logger;

has customFunctions => ( is => 'rw', isa => 'Maybe[Str]' );

has useSafeJail => ( is => 'rw', isa => 'Maybe[Int]' );

has jail => ( is => 'rw' );

has error => ( is => 'rw' );

our $VERSION = '1.9.9';

use Lemonldap::NG::Handler::Main '$datas', '$tsv';
use Lemonldap::NG::Handler::API ':functions';

## @imethod protected build_jail()
# Build and return the security jail used to compile rules and headers.
# @return Safe object
sub build_jail {
    my $self = shift;

    return $self->jail
      if ( $self->jail
        && $self->jail->useSafeJail == $self->useSafeJail
        && $self->jail->customFunctions == $self->customFunctions );

    $self->useSafeJail(1) unless defined $self->useSafeJail;

    my @t =
      $self->customFunctions ? split( /\s+/, $self->customFunctions ) : ();
    foreach (@t) {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "Custom function : $_",
            'debug' );
        my $sub = $_;
        unless (/::/) {
            $sub = "$self\::$_";
        }
        else {
            s/^.*:://;
        }
        next if ( $self->can($_) );
        eval "sub $_ {
            my \$uri = Lemonldap::NG::Handler::API::${Lemonldap::NG::Handler::API::mode}::uri_with_args();
            return $sub(\$uri,\@_)
        }";
        Lemonldap::NG::Handler::Main::Logger->lmLog( $@, 'error' ) if ($@);
        $_ = "&$_";
    }

    if ( $self->useSafeJail ) {
        $self->jail( Safe->new );
        $self->jail->share_from( 'main', ['%ENV'] );
    }
    else {
        $self->jail($self);
    }

    # Share objects with Safe jail
    $self->jail->share_from( 'Lemonldap::NG::Common::Safelib',
        $Lemonldap::NG::Common::Safelib::functions );

    $self->jail->share_from( 'Lemonldap::NG::Handler::Main',
        [ '$tsv', '$datas' ] );
    $self->jail->share_from(
        'Lemonldap::NG::Handler::API',
        [
            qw( &hostname &remote_ip &uri &uri_with_args
              &unparsed_uri &args &method &header_in   )
        ]
    );
    $self->jail->share_from( __PACKAGE__, [ @t, '&encrypt' ] );
    $self->jail->share_from( 'MIME::Base64', ['&encode_base64'] );

    # Initialize cryptographic functions to be able to use them in jail.
    eval { encrypt('a') };

    return $self->jail;
}

# Import crypto methods for jail
sub encrypt {
    return $tsv->{cipher}->encrypt(@_);
}

## @method reval
# Fake reval method if useSafeJail is off
sub reval {
    my ( $self, $e ) = @_;
    my $res = eval $e;
    if ($@) {
        $self->error($@);
        return undef;
    }
    return $res;
}

## @method wrap_code_ref
# Fake wrap_code_ref method if useSafeJail is off
sub wrap_code_ref {
    my ( $self, $e ) = @_;
    return $e;
}

## @method share
# Fake share method if useSafeJail is off
sub share {
    my ( $self, @vars ) = @_;
    $self->share_from( scalar(caller), \@vars );
}

## @method share_from
# Fake share_from method if useSafeJail is off
sub share_from {
    my ( $self, $pkg, $vars ) = @_;

    no strict 'refs';
    foreach my $arg (@$vars) {
        my ( $var, $type );
        $type = $1 if ( $var = $arg ) =~ s/^(\W)//;
        for ( 1 .. 2 ) {    # assign twice to avoid any 'used once' warnings
            *{$var} =
                ( !$type )       ? \&{ $pkg . "::$var" }
              : ( $type eq '&' ) ? \&{ $pkg . "::$var" }
              : ( $type eq '$' ) ? \${ $pkg . "::$var" }
              : ( $type eq '@' ) ? \@{ $pkg . "::$var" }
              : ( $type eq '%' ) ? \%{ $pkg . "::$var" }
              : ( $type eq '*' ) ? *{ $pkg . "::$var" }
              :                    undef;
        }
    }
}

## @imethod protected jail_reval()
# Build and return restricted eval command with SAFEWRAP, if activated
# @return evaluation of $reval or $reval2
sub jail_reval {
    my ( $self, $reval ) = @_;

    # if nothing is returned by reval, add the return statement to
    # the "no safe wrap" reval
    my $nosw_reval = $reval;
    if ( $reval !~ /^sub\{return\(.*\}$/ ) {
        $nosw_reval =~ s/^sub\{(.*)\}$/sub{return($1)}/;
    }

    my $res;
    eval {
        $res = (
            SAFEWRAP
            ? $self->jail->wrap_code_ref( $self->jail->reval($reval) )
            : $self->jail->reval($nosw_reval)
        );
    };
    if ($@) {
        $self->error($@);
        return undef;
    }
    return $res;
}

1;
