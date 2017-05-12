package Exobrain::HabitRPG;
use Moose;
use Exobrain::Config;
use feature qw(say);

# ABSTRACT: HabitRPG components for Exobrain
our $VERSION = '0.01'; # VERSION

with 'Exobrain::Component';

sub component { "habitrpg" };

sub services {
    return (
        sink => 'HabitRPG::Sink',
    );
}

sub setup {

    # Load module and die swiftly on failure
    eval 'use WebService::HabitRPG; 1;' or die $@;

    say "Welcome to the Exobrain::HabitRPG setup process.";
    say "To complete setup, we'll need your HabitRPG API key and user ID";
    say "These can be found on your HabitRPG settings page.";

    print "API token: ";
    chomp( my $api = <STDIN> );

    print "User ID: ";
    chomp( my $user = <STDIN> );

    # Check to see if we auth okay.

    my $habit = WebService::HabitRPG->new(
        api_token => $api,
        user_id   => $user,
    );
    
    # Make a call to ensure we auth

    $habit->user;

    say "\nThanks! Writing configuration...";

    my $config =
        "[Components]\n" .
        "HabitRPG=$VERSION\n\n" .

        "[HabitRPG]\n" .
        "api_token = $api\n" .
        "user_id   = $user\n"
    ;

    my $filename = Exobrain::Config->write_config('HabitRPG.ini', $config);

    say "\nConfig written to $filename. Have a nice day!";

    return;
}

1;

__END__

=pod

=head1 NAME

Exobrain::HabitRPG - HabitRPG components for Exobrain

=head1 VERSION

version 0.01

=for Pod::Coverage setup services component

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
