package Flower::Chronos::Application::Firefox;

use strict;
use warnings;

use base 'Flower::Chronos::Application::Base';

use URI;
use JSON ();

sub run {
    my $self = shift;
    my ($info) = @_;

    return
         unless $info->{role} =~ 'browser'
      && $info->{class} =~ 'Navigator'
      && $info->{name} =~ m/(?:Iceweasel|Firefox)/;

    $info->{application} = 'Firefox';
    $info->{category}    = 'browser';

    $info->{url} = $self->_find_current_url;

    return 1;
}

sub _find_current_url {
    my $self = shift;

    my $json = $self->_parse_current_session;

    my @tabs;
    foreach my $w (@{$json->{"windows"}}) {
        foreach my $t (@{$w->{"tabs"}}) {
            push @tabs,
              {
                last_accessed => $t->{lastAccessed},
                url           => $t->{"entries"}[-1]->{"url"}
              };
        }
    }

    @tabs = sort { $b->{last_accessed} <=> $a->{last_accessed} } @tabs;

    my $url = $tabs[0]->{url};
    return '' unless $url;

    return URI->new($url)->host;
}

sub _parse_current_session {
    my $self = shift;

    my $session = $self->_slurp_session;
    return JSON::decode_json($session);
}

sub _slurp_session {
    my $self = shift;
    my ($session_file) =
      glob "$ENV{HOME}/.mozilla/firefox/*default/sessionstore.js";
    if (!$session_file ||!-e $session_file) {
      ($session_file) =
        glob "$ENV{HOME}/.mozilla/firefox/*default/sessionstore-backups/recovery.js";
    }
    return do { local $/; open my $fh, '<', $session_file; <$fh> };
}

1;
