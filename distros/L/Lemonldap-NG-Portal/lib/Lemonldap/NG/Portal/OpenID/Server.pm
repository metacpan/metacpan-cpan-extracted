## @file
# Subclass of Net::OpenID::Server that manage OpenID extensions

## @class
# Subclass of Net::OpenID::Server that manage OpenID extensions
package Lemonldap::NG::Portal::OpenID::Server;

use strict;
use base qw(Net::OpenID::Server);
use fields qw(_extensions);
use Net::OpenID::Server;
use Lemonldap::NG::Common::Regexp;

use constant DEBUG => 0;

our $VERSION = '1.9.1';

my $OPENID2_NS        = qq!http://specs.openid.net/auth/2.0!;
my $OPENID2_ID_SELECT = qq!http://specs.openid.net/auth/2.0/identifier_select!;

*_push_url_arg =
  ( $Net::OpenID::Server::VERSION >= 1.09 )
  ? *OpenID::util::push_url_arg
  : *Net::OpenID::Server::_push_url_arg;

## @cmethod Lemonldap::NG::Portal::OpenID::Server new(hash opts)
# Call Net::OpenID::Server::new() and store extensions
# @param %opts Net::OpenID::Server options
# @return Lemonldap::NG::Portal::OpenID::Server new object
sub new {
    my $class = shift;
    my $self  = fields::new($class);
    my %opts  = @_;
    $self->$_( delete $opts{$_} ) foreach (qw(extensions));
    $self->SUPER::new(%opts);

    #$self->{get_args} = sub { $self->param(@_) };
}

## @method protected void extensions()
# Manage "extensions" constructor parameter
sub extensions {
    my $self = shift;
    $self->{_extensions} = shift;
}

## @method protected list _mode_checkid(string mode, boolean redirect_for_setup)
# Overload Net::OpenID::Server::_mode_checkid to call extensions hook
# @param $mode OpenID mode
# @param $redirect_for_setup indicates that user must be redirected or not for
# setup
# @return (string $type, hashref parameters)
sub _mode_checkid {
    my Lemonldap::NG::Portal::OpenID::Server $self = shift;
    my ( $mode, $redirect_for_setup ) = @_;

    my $return_to = $self->args("openid.return_to");
    return $self->_fail("no_return_to")
      unless ( $return_to
        and $return_to =~ Lemonldap::NG::Common::Regexp::HTTP_URI );

    my $trust_root = $self->args("openid.trust_root") || $return_to;
    $trust_root = $self->args("openid.realm")
      if $self->args('openid.ns') eq $OPENID2_NS;
    return $self->_fail("invalid_trust_root")
      unless ( $trust_root =~ Lemonldap::NG::Common::Regexp::HTTP_URI
        and Net::OpenID::Server::_url_is_under( $trust_root, $return_to ) );

    my $identity = $self->args("openid.identity");

 # chop off the query string, in case our trust_root came from the return_to URL
    $trust_root =~ s/\?.*//;

    my $u = $self->_proxy("get_user");
    if (   $self->args('openid.ns') eq $OPENID2_NS
        && $identity eq $OPENID2_ID_SELECT )
    {
        $identity = $self->_proxy( "get_identity", $u, $identity );
    }
    my $is_identity = $self->_proxy( "is_identity", $u, $identity );
    my $is_trusted =
      $self->_proxy( "is_trusted", $u, $trust_root, $is_identity );

    my ( %extVars, %is_ext_trusted );
    my $is_exts_trusted = 1;
    if ( ref( $self->{_extensions} ) ) {
        my @list = $self->args->();
        my %extArgs;
        foreach my $arg (@list) {
            next unless ( $arg =~ /^openid\.(\w+)\.([\w\.]+)?/ );
            my $tmp = $1;
            my $val = $2;
            $extArgs{$tmp}->{$val} = scalar $self->args->($arg);
        }
        foreach my $ns ( keys %{ $self->{_extensions} } ) {
            print STDERR "Launching OpenIP $ns hook\n" if (DEBUG);
            my $h;
            ( $is_ext_trusted{$ns}, $h ) = $self->{_extensions}->{$ns}->(
                $u, $trust_root, $is_identity, $is_trusted,
                delete( $extArgs{$ns} ) || {}
            );
            if ($h) {
                while ( my ( $k, $v ) = each %$h ) {
                    print STDERR "$ns returned data: $k => $v\n" if (DEBUG);
                    $extVars{"$ns.$k"} = $v;
                }
            }
            $is_exts_trusted &&= $is_ext_trusted{$ns};
        }

        # TODO: warn if keys(%extArgs)
    }

    # assertion path:
    if ( $is_identity && $is_trusted && $is_exts_trusted ) {
        my %sArgs = (
            identity     => $identity,
            claimed_id   => $self->args('openid.claimed_id'),
            return_to    => $return_to,
            assoc_handle => $self->args("openid.assoc_handle"),
            ns           => $self->args('openid.ns'),
        );
        $sArgs{additional_fields} = \%extVars if (%extVars);
        my $ret_url = $self->signed_return_url(%sArgs);
        return ( "redirect", $ret_url );
    }

    # Assertion could not be made, so user requires setup (login/trust...
    # something). Two ways that can happen:  caller might have asked us for an
    # immediate return with a setup URL (the default), or explictly said that
    # we're in control of the user-agent's full window, and we can do whatever
    # we want with them now.

    # TODO: call extension sub for setup
    my %setup_args = (
        $self->_setup_map("trust_root"),   $trust_root,
        $self->_setup_map("realm"),        $trust_root,
        $self->_setup_map("return_to"),    $return_to,
        $self->_setup_map("identity"),     $identity,
        $self->_setup_map("assoc_handle"), $self->args("openid.assoc_handle"),
        %extVars,
    );
    $setup_args{ $self->_setup_map('ns') } = $self->args('openid.ns')
      if $self->args('openid.ns');

    my $setup_url = $self->{setup_url}
      or Carp::croak("No setup_url defined.");
    _push_url_arg( \$setup_url, %setup_args );

    if ( $mode eq "checkid_immediate" ) {
        my $ret_url = $return_to;
        if ( $self->args('openid.ns') eq $OPENID2_NS ) {
            _push_url_arg( \$ret_url, "openid.ns",   $self->args('openid.ns') );
            _push_url_arg( \$ret_url, "openid.mode", "setup_needed" );
        }
        else {
            _push_url_arg( \$ret_url, "openid.mode",           "id_res" );
            _push_url_arg( \$ret_url, "openid.user_setup_url", $setup_url );
        }
        return ( "redirect", $ret_url );
    }
    else {

        # the "checkid_setup" mode, where we take control of the user-agent
        # and return to their return_to URL later.

        if ($redirect_for_setup) {
            return ( "redirect", $setup_url );
        }
        else {
            return ( "setup", \%setup_args );
        }
    }
}

#*args = \&get_args;

#sub get_args {
#    my $self = shift;
#
#    if ( my $what = shift ) {
#        Carp::croak("Too many parameters") if @_;
#
#        # Lemonldap::NG only (direct CGI)
#        $self->{get_args} = sub { $what->param( $_[0] ) };
#
#        # INCLUDE IN PROPOSED PATCH FOR Net::OpenID::Server
#        #my $getter;
#        #if ( !ref $what ) {
#        #    Carp::croak("No get_args defined") unless $self->{get_args};
#        #    return $self->{get_args}->($what) || "";
#        #}
#        #elsif ( ref $what eq "HASH" ) {
#        #    $getter = sub { $_[0] ? $what->{ $_[0] } : ( keys %$what ); };
#        #}
#        #elsif ( ref $what eq "Apache" ) {
#        #    my %get = $what->args;
#        #    $getter = sub { $_[0] ? $get{ $_[0] } : ( keys %get ); };
#        #}
#        #elsif ( ref $what eq "CODE" ) {
#        #    $getter = $what;
#        #}
#        #else {
#        #    my $r = eval { $what->can('param') };
#        #    if ( $@ or not $r ) {
#        #        Carp::croak("Unknown parameter type ($what)");
#        #    }
#        #    else {
#        #        $getter = sub {
#        #            $_[0] ? scalar $what->param( $_[0] ) : ( $what->param() );
#        #        };
#        #    }
#        #}
#        #if ($getter) {
#        #    $self->{get_args} = $getter;
#        #}
#    }
#    $self->{get_args};
#}

1;
__END__

=encoding utf8

=head1 NAME

Lemonldap::NG::Portal::OpenID::Server - Add capability to manage extensions to
Net::OpenID::Server

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::OpenID::Server;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Lemonldap::NG::Portal::OpenID::Server, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2010-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
