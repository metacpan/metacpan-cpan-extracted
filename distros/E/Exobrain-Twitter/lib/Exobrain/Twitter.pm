package Exobrain::Twitter;
use Moose;
use Exobrain::Config;
use feature qw(say);    # To make 5.10 happy

# ABSTRACT: Twitter components for exobrain
our $VERSION = '1.04'; # VERSION


with 'Exobrain::Component';

# This is the namespace everything will be installed in by default.
# It's automatically prepended with 'exobrain'

sub component { "twitter" };

# These are the services in that namespace. So we have
# 'exobrain.twitter.source' and 'exobrain.twitter.sink'.

sub services {
    return (
        source   => 'Twitter::Source',
        sink     => 'Twitter::Sink',
        response => 'Twitter::Response',
    )
}

sub setup {

    # Load our module for testing.

    eval 'use Net::Twitter';
    die $@ if $@;

    say "\n\nHey there, we'll need to start by getting an API key from twitter.\n";
    say "Head over to: https://apps.twitter.com/app/new\n";
    say "You need only fill in the required fields there.";
    say "Alternatively, if you already have a registered app, you can use that.";

    say "\n--> Your application MUST require read, write, and DM access <--\n";

    say "\nOnce done, you'll need to provide the API key and secret.";
    say "These are not shared with anyone.";

    print "\nAPI key: ";
    chomp(my $consumer_key = <STDIN>);

    print "\nAPI secret: ";
    chomp(my $consumer_secret = <STDIN>);

    unless ($consumer_key and $consumer_secret) {
        die "I need both the key and secret to proceed. Halting.\n";
    }

    say "\n\nThanks! Authing with twitter...\n";

    my $nt = Net::Twitter->new(
        traits          => ['API::RESTv1_1', 'OAuth'],
        consumer_key    => $consumer_key,
        consumer_secret => $consumer_secret,
        ssl             => 1,
    );

    say "\n----------------------------------------------\n";

    say "Great! Now, to complete the auth, visit this URL, and enter the PIN...\n";

    say $nt->get_authorization_url;

    print "\nPIN: ";

    my $pin = <STDIN>; # wait for input
    chomp $pin;

    my($access_token, $access_token_secret, $user_id, $screen_name) = $nt->request_access_token(verifier => $pin);

    say "\n\nThanks \@$screen_name!";

    my $config = 
        "[Components]\n" .
        "Twitter=$VERSION\n\n" .

        "[Twitter]\n" .
        "consumer_key        = $consumer_key\n" .
        "consumer_secret     = $consumer_secret\n" .
        "access_token        = $access_token\n" .
        "access_token_secret = $access_token_secret\n"
    ;

    my $filename = Exobrain::Config->write_config('Twitter.ini', $config);

    say "\n\nConfig written to $filename. Have a nice day!";
}

1;

__END__

=pod

=head1 NAME

Exobrain::Twitter - Twitter components for exobrain

=head1 VERSION

version 1.04

=head1 SYNOPSIS

    $ exobrain setup Twitter

    $ ubic start exobrain.twitter

=head1 DESCRIPTION

This distribution provides Twitter access to L<Exobrain>. To enable,
please run C<exobrain setup Twitter> file, which will run you
through the setup proceess.

Once enabled, services can be controlled using C<ubic>. Try
C<ubic status> to see them, and C<ubic start exobrain.twitter> to
start the twitter framework.

=head1 PROVIDED CLASSES

This component provides the following agents:

=over

=item L<Exobrain::Agent::Twitter::Source>

=item L<Exobrain::Agent::Twitter::Sink>

=item L<Exobrain::Agent::Twitter::Response>

=back

It also provides L<Exobrain::Intent::Tweet> and
L<Exobrain::Measurement::Tweet> classes for sending and
receiving tweets, respectively.

=for Pod::Coverage component services setup

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
