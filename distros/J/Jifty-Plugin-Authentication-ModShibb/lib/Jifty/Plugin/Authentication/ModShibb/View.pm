package Jifty::Plugin::Authentication::ModShibb::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::Authentication::ModShibb::View - default templates

=cut

template '/shibb_access_denied' => page {
    title is _('Shibbolteh access denied');
};

template '/shibb_missing_attribute' => page {
    title is _('Shibbolteh access denied');
    outs _("Your Identity Provider don't provide a required attribute for this application.")
};

template '/shibb_test' => page {
    my ($plugin)  = Jifty->find_plugin('Jifty::Plugin::Authentication::ModShibb');
    my %env = %ENV;
    #eval { %env = Jifty->web->request->env() };
    my $remote_user = $env{'REMOTE_USER'};
    strong {'REMOTE_USER'}; outs ' : '.$remote_user;
    br {};
    return if !$remote_user;
    br {};
    outs ('Required attributes :');
    ul {
        foreach my $val (@{$plugin->shibb_mandatory} ) {
        li { strong { $val}; outs ' : '.$env{$val} };
        };
    };
    outs ('Full ENV values :');
    ul {
        foreach my $val (sort keys %env) {
        li { strong { $val}; outs ' : '.$env{$val} };
        };
    };
};

1;
