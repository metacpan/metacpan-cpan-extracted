package LiBot::Handler::CoreList;
use strict;
use warnings;
use utf8;

use Module::CoreList;

use Mouse;
no Mouse;

sub init {
    my ($self, $bot) = @_;
    $bot->register(
        qr/^corelist\s+([A-Za-z:_]+)$/ => \&_handler
    );
}

sub _handler {
    my ($cb, $event, $module) = @_;
    my $r = Module::CoreList->first_release($module);
    if (defined $r) {
        $cb->("${module} was first released with perl $r");
    } else {
        $cb->("${module} was not in CORE (or so I think)");
    }
}

1;
__END__

=for stopwords corelist

=head1 NAME

LiBot::Handler::CoreList - Module::CoreList plugin

=head1 SYNOPSIS

    # config.pl
    +{
        'handlers' => [
            'CoreList'
        ]
    }

    # In the chat
    <tokuhirom> corelist Test::More
    >bot< Test::More was first released with perl 5.006002
    <tokuhirom> corelist Acme::PrettyCure
    >bot< Acme::PrettyCure was not in CORE (or so I think)

=head1 DESCRIPTION

This plugin provides a 'corelist' command for the LiBot.

=head1 CONFIGURATION

There is no configuration parameters.
