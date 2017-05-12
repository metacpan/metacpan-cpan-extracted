[![Build Status](https://travis-ci.org/apcros/Drac-Perl.svg?branch=master)](https://travis-ci.org/apcros/Drac-Perl)
# NAME

DracPerl::Client - API Client for Dell's management interface (iDRAC)

# AUTHOR

Jules Decol (@Apcros)

# SYNOPSIS

A client to interact with the iDRAC API on Dell Poweredge servers

        # Create the client
        my $drac_client = DracPerl::Client->new({
                        user            => "username",
                        password        => "password",
                        url             => "https://dracip",
                        });

        # Get what you're interested in
        # Login is done implicitly, you can save and resume sessions. See below
        my $parsed_xml = $drac_client->get("fans");

# DESCRIPTION

## WHY ?

This been created because I find the web interface of iDrac slow and far from being easy to use. 
I have the project of creating a full new iDrac front-end, but of course that project required an API Client. 
Because this is something that seem to be quite lacking in the PowerEdge community, I made a standalone repo/project for that :)

## TODO

What's to come ? 

\- Better error handling

\- Integration with Log4Perl

\- Full list of supported Method 

\- Few method to abstract commons operations

# OBJECT ARGUMENTS

## max\_retries

Login can be extremely capricious, Max retries avoid being too
annoyed by that. Defaulted to 5.

# METHODS

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
