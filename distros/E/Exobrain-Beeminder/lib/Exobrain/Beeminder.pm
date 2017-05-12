package Exobrain::Beeminder;
use Exobrain::Config;
use Moose;
use feature qw(say);    # Needed to make 5.10 happy.

# ABSTRACT: Beeminder components for exobrain
our $VERSION = '1.06'; # VERSION


with 'Exobrain::Component';

# This is the namespace everything will be installed in by default.
# It's automatically prepended with 'exobrain'

sub component { "beeminder" };

# These are the services in that namespace. So we have
# 'exobrain.beeminder.source' and 'exobrain.beeminder.sink'.

sub services {
    return (
        source   => 'Beeminder::Source',
        sink     => 'Beeminder::Sink',
        notify   => 'Beeminder::Notify',
    )
}

# This runs the setup process, and is executed by the `exobrain`
# cmdline tool the first time we run our code.

sub setup {
    
    # Load our WebService for testing.
    eval 'require WebService::Beeminder';
    die $@ if $@;

    say "Welcome to the Exobrain::Beeminder setup process.";
    say "To start with we need from you is your Beeminder auth token.";
    say "If you're logged into Beeminder, you can find it here:\n";
    say "https://www.beeminder.com/settings/account";
    print "\nAuth token: ";

    chomp(my $token = <STDIN>);

    # Connect to make sure that we're working. This should throw
    # an exception if things go wrong. :)

    my $bee = WebService::Beeminder->new( token => $token );
    my $user = $bee->user->{username};

    say "\nThanks, $user!\n";

    # Now configure our callback port.

    say "Exobrain::Beeminder can be configured to accept callbacks from Beeminder.";
    say "For this, we need a dedicted port that can be reached from the outside world.";
    say "To disable this functionality, provide a port of 0";

    print "\nCallback port: [default: 3000] ";

    chomp(my $port = <STDIN>);
    if ($port eq '') { $port = 3000; }

    say "\nGreat! Writing configuration...";

    my $config =
        "[Components]\n" .
        "Beeminder=$VERSION\n\n" .

        "[Beeminder]\n" .
        "auth_token    = $token\n" .
        "callback_port = $port\n"
    ;

    my $filename = Exobrain::Config->write_config('Beeminder.ini', $config);

    say "\nConfig written to $filename. Have a nice day!";

    return;
}

1;

__END__

=pod

=head1 NAME

Exobrain::Beeminder - Beeminder components for exobrain

=head1 VERSION

version 1.06

=head1 SYNOPSIS

    $ ubic start exobrain.beeminder

=head1 DESCRIPTION

This distribution provides Beeminder access to L<Exobrain>.

Once enabled, services can be controlled using C<ubic>. Try
C<ubic status> to see them, and C<ubic start exobrain.beeminder> to
start the beeminder framework.

=head1 PROVIDED CLASSES

This component provides the following agents:

=over

=item L<Exobrain::Agent::Beeminder::Source>

=item L<Exobrain::Agent::Beeminder::Sink>

=back

It also provides L<Exobrain::Intent::Beeminder> and
L<Exobrain::Measurement::Beeminder> classes for sending and
receiving Beeminder datapoints, respectively.

=for Pod::Coverage component services setup

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
