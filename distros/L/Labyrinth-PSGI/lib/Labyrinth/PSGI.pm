package Labyrinth::PSGI;

use warnings;
use strict;

our $VERSION = '1.02';

use Labyrinth;
use Labyrinth::Variables;

sub new {
    my ($class,$env,$cnf) = @_;

    my $lab = Labyrinth->new();

    # create an attributes hash
    my $atts = {
        cnf => $cnf,
        lab => $lab
    };

    # create the object
    bless $atts, $class;

    $settings{psgi}{env} = $env;

    return $atts;
};

sub run {
    my $self = shift;
    my $cnf  = shift || $self->{cnf};

    return [ 500, 'text/html', [ '<html><head><title>Oops!</title></head><body>Oops, something went wrong</body></html>' ] ]
        unless($cnf && -f $cnf);

    $self->{lab}->run( $cnf );

    return [ $settings{psgi}{status}, $settings{psgi}{headers}, [ $settings{psgi}{body} ] ];
}

1;

__END__

=head1 NAME

Labyrinth::PSGI - PSGI handler for Labyrinth

=head1 DESCRIPTION

Allow Labyrinth to run under Plack. Use the PSGI protocol to interface with
a Plack web server to process web requests.

=head1 SYNOPSIS

Update your settings file to include the following lines.

    query-parser=PSGI
    writer-render=PSGI

Then create a .psgi file for your application, containing the following:

    use Labyrinth::PSGI;

    my $app = sub {
        my $env = shift;
        my $lab = Labyrinth::PSGI->new( $env, '/var/www/<mywebsite>/cgi-bin/config/settings.ini' );
        return $lab->run();
    };

You may also need to add builder instructions. These should be added to your 
.psgi file, and may look something like:

    use Plack::Builder;

    builder {
        enable "Static", path => qr!^/images/!,     root => '../html';
        enable "Static", path => qr!^/(cs|j)s/!,    root => '../html';
        enable "Static", path => qr!^/favicon.ico!, root => '../html';
        enable "Static", path => qr!^/robots.txt!,  root => '../html';
        $app;
    };

The above lines allow static files to pass through and be retrieved from the
file system, rather than through your application.

=head1 METHODS

=head2 new( $env [, $config ] )

The constructor. Must be passed the environment variable from the PSGI server. 
You may optionally pass the Labyrinth configuration file as well, or via the 
run() method.

=head2 run( [ $config ] )

=head1 SEE ALSO

L<CGI::PSGI>,
L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2013-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
