#ABSTRACT: A module to explain how to use FR24::Bot
package FR24::Tutorial;

use strict;
use warnings;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FR24::Tutorial - A module to explain how to use FR24::Bot

=head1 VERSION

version 0.0.3

=head1 How to get started with FR24::Bot

This modules comes with some utilities to run a B<Telegram Bot> 
that interacts with flight data your the B<Flightradar24 antenna>.

It can be installed in the same devide (usually a Raspberry Pi) 
where the Flightradar24 antenna is running, or in another server
which is able to connect to the Flightradar24 antenna webpage. 
For this reason, it mostly parses data from the webserver, but 
it has been mostly tested in the same device.

=head2 Installing the Module

Use CPAN or cpanm to install the module:

    cpanm FR24::Bot

=head2 Setting Up the Module

You will need a configuration file to run the bot. The default location is:

    ~/.config/fr24-bot.ini

The configuration file is an INI file with the following sections:

    [telegram]
    apikey=7908487915:AEEQFftvQtEbavBGcB81iF1cF2koliWFxJE

    [server]
    port=8080
    ip=localhost

    [users]
    everyone=1

To create it you can run the following command:

    config-fr24-bot [-a API_KEY] [-i IP] [-p PORT]

If you don't specify the C<-a> option or the C<-i> options,
the script will ask you to provide them interactively.

=head3 Users

The C<users> section contains a list of authorized users. If C<everyone=1> is present,
all users will be able to query the bot. Otherwise only users with C<USER_ID=1> will be
able to use the bot. In the future higher values will be used to give different permissions.

=head2 Running the Bot

The main program is C<fr24bot>. You can run it with the following options:

    fr24-bot [-a API_KEY] [-i IP] [-p PORT] [-c CONFIG_FILE] [-v] [-d]

Type C</help> in the bot to get a list of available commands, for example C</tot> will return
the total number of flights detected.

=head1 Developer's notes

=head2 Data strcuture for the bot 

    bless( {
                    'total' => 4,
                    'users' => {},
                    'uploaded' => 3,
                    'last_url' => 'http://localhost:8754/flights.json?time=1689326300000',
                    'name' => 'fr24-bot',
                    'callsigns' => {
                                    'KLM000' => '485e30',
                                    'RYR000' => '4d21ee',
                                    'KLM100' => '485789',
                                    },
                    'apikey' => '6208587905:AAEQFfvvQtHbvvBTcB78iE8wO2zuapWFxJE',
                    'ip' => 'localhost',
                    'test_mode' => 1,
                    'refresh' => 10000,
                    'port' => '8754',
                    'config' => {
                                'users' => {
                                                'everyone' => '0',
                                                '6347455858' => '1'
                                            },
                                'server' => {
                                                'ip' => 'localhost',
                                                'port' => '8754'
                                            },
                                'telegram' => {
                                                'apikey' => '6208587905:AAEQFfvvQtHbvvBTcB78iE8wO2zuapWFxJE'
                                                }
                                },
                    'content' => '{}',
                    'flights_url' => 'http://localhost:8754/flights.json',
                    'localip' => undef,
                    'flights' => {
                                    '3c5eee' => {
                                                'id' => '3c5eee',
                                                'long' => 0,
                                                'callsign' => '',
                                                'lat' => 0,
                                                'alt' => 11775
                                                },
                                    '485789' => {
                                                'long' => '0.9666',
                                                'id' => '485789',
                                                'callsign' => 'KLM100',
                                                'alt' => 38275,
                                                'lat' => '51.94'
                                                },
                                    '485e30' => {
                                                'alt' => 34850,
                                                'lat' => '53.01',
                                                'id' => '485e30',
                                                'long' => '0.8713',
                                                'callsign' => 'KLM000'
                                                },
                                    '4d21ee' => {
                                                'lat' => '51.99',
                                                'alt' => 25875,
                                                'callsign' => 'RYR000',
                                                'id' => '4d21ee',
                                                'long' => '1.463'
                                                },
                                },
                    'last_updated' => '1689326300000'
                }, 'FR24::Bot' );

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
