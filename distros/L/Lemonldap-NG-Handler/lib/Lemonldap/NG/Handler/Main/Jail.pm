package Lemonldap::NG::Handler::Main::Jail;

use strict;
use Safe;
use Lemonldap::NG::Common::Safelib;    #link protected safe Safe object

# Workaround for another ModPerl/Mouse issue...
BEGIN {
    require Mouse;
    no warnings;
    my $v = $Mouse::VERSION
      ? sprintf( "%d.%03d%03d", ( $Mouse::VERSION =~ /(\d+)/g ) )
      : 0;
    if ( $v < 2.005001 and $Lemonldap::NG::Handler::Apache2::Main::VERSION ) {
        require Moose;
        Moose->import();
    }
    else {
        Mouse->import();
    }
}

has customFunctions      => ( is => 'rw', isa => 'Maybe[Str]' );
has useSafeJail          => ( is => 'rw', isa => 'Maybe[Int]' );
has multiValuesSeparator => ( is => 'rw', isa => 'Maybe[Str]' );
has jail                 => ( is => 'rw' );
has error                => ( is => 'rw' );

our $VERSION = '2.0.14';
our @builtCustomFunctions;

## @imethod protected build_jail()
# Build and return the security jail used to compile rules and headers.
# @return Safe object
sub build_jail {
    my ( $self, $api, $require, $dontDie ) = @_;
    my $build = 1;

    return $self->jail
      if (  $self->jail
        and $self->jail->useSafeJail
        and $self->useSafeJail
        and $self->jail->useSafeJail == $self->useSafeJail );

    $self->useSafeJail(1) unless defined $self->useSafeJail;

    if ($require) {
        foreach my $f ( split /[,\s]+/, $require ) {
            if ( $f =~ /^[\w\:]+$/ ) {
                eval "require $f";
            }
            else {
                eval { require $f; };
            }
            if ($@) {
                $dontDie
                  ? $api->logger->error($@)
                  : die "Unable to load '$f': $@";
                undef $build;
            }
        }
    }

    if ($build) {
        @builtCustomFunctions =
          $self->customFunctions
          ? split( /[,\s]+/, $self->customFunctions )
          : ();
        foreach (@builtCustomFunctions) {
            no warnings 'redefine';
            $api->logger->debug("Custom function: $_");
            my $sub = $_;
            unless (/::/) {
                $sub = "$self\::$_";
            }
            else {
                s/^.*:://;
            }
            next if ( $self->can($_) );
            eval "sub $_ {
            return $sub(\@_)
        }";
            $api->logger->error($@) if ($@);
            $_ = "&$_";
        }
    }

    if ( $self->useSafeJail ) {
        $self->jail( Safe->new );
    }
    else {
        $self->jail($self);
    }

    # Share objects with Safe jail
    $self->jail->share_from( 'Lemonldap::NG::Common::Safelib',
        $Lemonldap::NG::Common::Safelib::functions );

    # Closure for listMatch
    {
        no warnings 'redefine';
        *listMatch = sub {
            return Lemonldap::NG::Common::Safelib::listMatch(
                $self->multiValuesSeparator, @_ );
        };
    }

    $self->jail->share_from( __PACKAGE__,
        [ @builtCustomFunctions, '&encrypt', '&token', '&listMatch' ] );

    $self->jail->share_from( 'MIME::Base64', ['&encode_base64'] );

    #$self->jail->share_from( 'Lemonldap::NG::Handler::Main', ['$_v'] );

    # Initialize cryptographic functions to be able to use them in jail.
    eval { token('a') };

    return $self->jail;
}

# Import crypto methods for jail
sub encrypt {
    return &Lemonldap::NG::Handler::Main::tsv->{cipher}->encrypt( $_[0], 1 );
}

sub token {
    return $_[0] ? encrypt( join( ':', time, @_ ) ) : encrypt(time);
}

## @method reval
# Fake reval method if useSafeJail is off
sub reval {
    my ( $self, $e ) = @_;
    return eval $e;
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
# Build and return restricted eval command
# @return evaluation of $reval or $reval2
sub jail_reval {
    my ( $self, $reval ) = @_;

    # If nothing is returned by reval, add the return statement to
    # the "no safe wrap" reval

    my $res = $self->jail->reval($reval);
    if ($@) {
        $self->error($@);
        return undef;
    }
    return $res;
}

1;
