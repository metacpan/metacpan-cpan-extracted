#!./bin/jspl

say('Hello World!');

say('Are you ' + Sys.Env.USER + '?');

if(Sys.Argv.length)
    say('My argv: ' + Sys.Argv.toString());
