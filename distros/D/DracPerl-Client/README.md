[![Build Status](https://travis-ci.org/apcros/Drac-Perl.svg?branch=master)](https://travis-ci.org/apcros/Drac-Perl)
# NAME

DracPerl::Client - API Client for Dell's management interface (iDRAC)

# AUTHOR

Jules Decol - @Apcros

# SYNOPSIS

A client to interact with the iDRAC API on Dell Poweredge servers

    # Create the client
    my $drac_client = DracPerl::Client->new({
            user        => "username",
            password    => "password",
            url         => "https://dracip",
            });

    # Get what you're interested in
    # Login is done implicitly, you can save and resume sessions. See below
    my $parsed_xml = $drac_client->get({ commands => ['fans']});

# DESCRIPTION

## WHY ?

This been created because I find the web interface of iDrac slow and far from being easy to use. 
I have the project of creating a full new iDrac front-end, but of course that project required an API Client. 
Because this is something that seem to be quite lacking in the PowerEdge community, I made a standalone repo/project for that :)

## PITFALLS

The DRAC API this client is exploiting is meant to be used only by the DRAC front-end and therefore comes with it loads of weirdness.

\- A lot of fields have trailing whitespace in them (Possible update coming soon to clean theses)
\- When no data is available some fields will be empty, some will be 'N/A', there seem to be no consistency there
\- Some fields are padded (See [DracPerl::Models::Abstract::PhysicalDisk](https://metacpan.org/pod/DracPerl::Models::Abstract::PhysicalDisk) )

Please note that depending on your network config you might have trouble accessing DRAC from the server itself. (If you are inside a VM running on the Dell server for example)

# OBJECT ARGUMENTS

## max\_retries

Login can be extremely capricious, Max retries avoid being too
annoyed by that. Defaulted to 5.

# METHODS

## get

Will return a hash containing models of all the methods or collection you called.

    my $result = $drac_client->get({
        commands => ['fans'],
        collections => ['lcd']
    });

    # $result will contain :
    {
        fans => .. #DracPerl::Models::Commands::DellDefault::Fans,
        lcd => .. #DracPerl::Models::Commands::Collection::LCD
    }

## openSession

Can be called explicitly or is called by default if get is called and no session is available
You can pass it a saved session in order to restore it. 

    $drac_client->openSession($saved_session) #Will restore a session
    $drac_client->openSession() #Will open a new one

## saveSession

This will return the current session. (Basically the token and the cookie jar).

## closeSession

Invalidate the current session

## isAlive

Check with a quick api call if your current session is still useable.

# COMMANDS

A command is a single field defined by the DRAC API.
They can be send in the "commands" hash key on the get method

Here's the list of supported commands :

**batteries** - [DracPerl::Models::Commands::DellDefault::Batteries](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::Batteries)

**eventLogEntries** - [DracPerl::Models::Commands::DellDefault::EventLogEntries](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::EventLogEntries)

**racLogEntries** - [DracPerl::Models::Commands::DellDefault::RacLogEntries](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::RacLogEntries)

**fans** - [DracPerl::Models::Commands::DellDefault::Fans](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::Fans)

**fansRedundancy** - [DracPerl::Models::Commands::DellDefault::FansRedundancy](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::FansRedundancy)

**getInv** - [DracPerl::Models::Commands::DellDefault::GetInv](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::GetInv)

**intrusion** - [DracPerl::Models::Commands::DellDefault::Intrusion](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::Intrusion)

**powerSupplies** - [DracPerl::Models::Commands::DellDefault::PowerSupplies](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::PowerSupplies)

**temperatures** - [DracPerl::Models::Commands::DellDefault::Temperatures](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::Temperatures)

**voltages** - [DracPerl::Models::Commands::DellDefault::Voltages](https://metacpan.org/pod/DracPerl::Models::Commands::DellDefault::Voltages)

# COLLECTIONS

Collections are groups of field. This is not a Dell terminology.
This was created because some interfaces pages (LCD information for example)
will need several commands and the commands themselves are too small to justify
having a standalone model for them.

**systemInformations** - [DracPerl::Models::Commands::Collection::SystemInformations](https://metacpan.org/pod/DracPerl::Models::Commands::Collection::SystemInformations)

**lcd** - [DracPerl::Models::Commands::Collection::LCD](https://metacpan.org/pod/DracPerl::Models::Commands::Collection::LCD)
