use warnings;
use strict;

=head1 NAME

Jifty::Plugin::OpenID::Action::AuthenticateOpenID - make OpenId authentication

=cut

package Jifty::Plugin::OpenID::Action::AuthenticateOpenID;

use base qw/Jifty::Action/;

use LWPx::ParanoidAgent;
use Net::OpenID::Consumer;
use Cache::FileCache;

=head2 arguments

Return the OpenID URL field

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {
    param 'openid' =>
        label is _('OpenID URL'),
        is mandatory,
        hints is _('For example: you.livejournal.com');

    param 'ax_param' =>
        render as 'Hidden';

    param 'ax_values' =>
        render as 'Hidden';

    param 'ax_mapping' =>
        render as 'Hidden';

    param 'return_to' =>
        render as 'Hidden',
        default is '/openid/verify_and_login';
};

=head2 take_action

Creates local user if non-existant and redirects to OpenID auth URL

=cut

use Jifty::JSON qw /jsonToObj/;

sub take_action {
    my $self   = shift;
    my $openid = $self->argument_value('openid');
    my $path   = $self->argument_value('return_to');
    my $plugin = Jifty->find_plugin('Jifty::Plugin::OpenID');
    my $ax_mapping   = $self->argument_value('ax_mapping') || $plugin->ax_mapping();
    my $ax_param   = $self->argument_value('ax_param') || $plugin->ax_param();
    my $ax_values   = $self->argument_value('ax_values') || $plugin->ax_values();

    my $baseurl = Jifty->web->url;
    my $csr = Jifty::Plugin::OpenID->get_csr( required_root => $baseurl );

    my $claimed_id = $csr->claimed_identity( $openid );

    if ( not defined $claimed_id ) {
        $self->result->error(_("Invalid OpenID URL.  Please check to make sure it is correct.  (%1)",@{[$csr->err]}));
        return;
    }

    $openid = $claimed_id->claimed_url;

    my $return_to = Jifty->web->url( path => $path );
    if(Jifty->web->request->continuation) {
        $return_to .= ($return_to =~ /\?/) ? '&' : '?';
        $return_to .= "J:C=" . Jifty->web->request->continuation->id;
    }

    my $check_url = $claimed_id->check_url( 
                        return_to  => $return_to,
                        trust_root => $baseurl,
                        delayed_return => 1
                    );
    Jifty->web->session->set(ax_mapping => jsonToObj($ax_mapping));
    Jifty->web->session->set(ax_values => $ax_values);
    $ax_param = '&'.$ax_param if $ax_param && $ax_param !~ m/^&/;

    Jifty->web->_redirect( $check_url . '&openid.sreg.optional=nickname'.$ax_param );
    return 1; # should never get here
}

1;
