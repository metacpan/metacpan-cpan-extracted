#!/usr/bin/perl
use strict;
use warnings;

use Minecraft::RCON;
use Getopt::Long;
use Data::Dumper;

my @commands;
my $address = '127.0.0.1';
my $port = 25575;
my $password = '';
my $strip_color = 0;
my $help = 0;
my $echo = 0;
my $force_stdin = 0;

my $result = GetOptions(
    'address=s'     => \$address,
    'port=i'        => \$port,
    'password=s'    => \$password,
    'command=s'     => \@commands,
    'stdin'         => \$force_stdin,
    'stripcolor'    => \$strip_color,
    'help'          => \$help,
    'echo'          => \$echo,
);

if ($result and !$help and $password ne ''){

    my $rcon = Minecraft::RCON->new(
        {
            address     => $address,
            port        => $port,
            password    => $password,
        }
    );

    if (!$rcon->connect){
        die "Failed to connect to RCON!\n";
    }

    # I don't want two commandline options for color handling.
    # I mean, if you don't want them stripped you probably don't want them raw.
    # This goes directly to STDOUT anyway, I mean.
    if ($strip_color){
        $rcon->strip_color(1);
    }
    else {
        $rcon->strip_color(0);
        $rcon->convert_color(1);
    }
    
    if (@commands){ # --command commandlines
        foreach my $command (@commands){
            send_command($rcon,$command);
        }
    }
    if (!@commands or $force_stdin){ # No --commands given, let's open up STDIN and listen for some.
        while (my $line = <STDIN>){
            chomp $line;
            send_command($rcon,$line);
        }
    }
    $rcon->disconnect; # Because we should tidy up.
                       # Oh, wait, this is about to go out of scope and get disconnected anyway.
                       # Well, dang-nabbit :-/
}
else {
    print <<EOH

Usage:
    $0 --password somePassword --command "say hello"

Options:

--address    : Specify an address to connect to, defaults to localhost.
--port       : rcon.port in your server.properties, defaults to 25575.
--password   : ->REQUIRED<- rcon.password in server.properties 
--command    : Command to run.  I accept as many of these as you need.
--stdin      : Force STDIN listening even when --command is given
--echo       : Echo the commands given back to you with the result.
--stripcolor : If given, all color codes are stripped.
--help       : You get this friendly text, and nothing more happens.

If you specify no --command parameters, they are expected from STDIN
You can also force this behaviour woth --stdin
You can type them yourself, if you want.  Finish with ^D
Intended use, of course, is to either pipe them in or < from a file.
EOH
}

sub send_command {
    my ($rcon,$command) = @_;
    my $result = $rcon->command($command);
    if ($echo){
        print qq{[Command "$command"]\n$result};
    }
    else {
        print $result;
    }
}
