use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::ModShibb::Action::ShibbLogin - process ModShibb login plugin

=cut

package Jifty::Plugin::Authentication::ModShibb::Action::ShibbLogin;
use base qw/Jifty::Action/;


=head2 arguments

Return the ticket form field

=cut

sub arguments {
    return ( { } );
};


=head2 take_action

Actually check the user's password. If it's right, log them in.
Otherwise, throw an error.


=cut

#use Data::Dumper;

sub take_action {
    my $self = shift;

    my ($plugin)  = Jifty->find_plugin('Jifty::Plugin::Authentication::ModShibb');

    my $username;

    my %env = %ENV;
    #eval { %env = Jifty->web->request->env() };

    foreach my $val (@{$plugin->shibb_mandatory} ) {
        if (!$env{$val}) {
            # missing mandatory shibb attribute
            Jifty->web->_redirect('/shibb_missing_attribute');
            return 0;
        };
    };
    
    if ( $plugin->shibb_authz ) {
        my $resp = eval( $plugin->shibb_authz ) || 0;
        if (!$resp) {
            # not authz
            Jifty->web->_redirect('/shibb_access_denied');
            return 0;
        };
    };

    my $email = $env{$plugin->shibb_mapping->{email}};
    my $shibb_id = $env{$plugin->shibb_mapping->{shibb_id}};

    # Load up the user
    my $current_user = Jifty->app_class('CurrentUser');
    my $user = ($email) ? $current_user->new( email => $email)    # load by email to mix authentication
                        : $current_user->new( shibb_id => $shibb_id );  # else load by cas_id

    # Autocreate the user if necessary
    if ( not $user->id ) {
        my $action = Jifty->web->new_action(
            class           => 'CreateUser',
            current_user    => $current_user->superuser,
            arguments       => {
                shibb_id => $shibb_id,
                email => ($email)? $email : $shibb_id
            }
        );
        $action->run;

        if ( not $action->result->success ) {
            # Should this be less "friendly"?
            $self->result->error(_("Sorry, something weird happened (we couldn't create a user for you).  Try again later."));
            return;
        }

        $user = $current_user->new( shibb_id => $shibb_id);
    }

    my $u = $user->user_object;

    # Update, just in case
    $u->__set( column => 'shibb_id', value => $shibb_id ) if (!$u->shibb_id);

    foreach my $col_name (keys %{$plugin->shibb_mapping}) {
        next if $col_name eq 'shibb_id';
        my $new_val = $env{$plugin->shibb_mapping->{$col_name}} || '';
        $u->_set( column => $col_name, value => $new_val )
            if $new_val && $u->$col_name ne $new_val;
    };

    # Actually do the signin thing.
    Jifty->web->current_user( $user );
    Jifty->web->session->set_cookie;

    # Success!
    $self->report_success;

    return 1;
};

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_("Hi %1!", Jifty->web->current_user->user_object->name ));
};


1;
