[![Build Status](https://travis-ci.org/sago35/Getopt-Kingpin.svg?branch=master)](https://travis-ci.org/sago35/Getopt-Kingpin) [![Coverage Status](http://codecov.io/github/sago35/Getopt-Kingpin/coverage.svg?branch=master)](https://codecov.io/github/sago35/Getopt-Kingpin?branch=master) [![Build Status](https://img.shields.io/appveyor/ci/sago35/Getopt-Kingpin/master.svg?logo=appveyor)](https://ci.appveyor.com/project/sago35/Getopt-Kingpin/branch/master)
# NAME

Getopt::Kingpin - command line options parser (like golang kingpin)

# SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    $kingpin->flags->get("help")->short('h');
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool;
    my $name    = $kingpin->arg('name', 'Name of user.')->required->string;

    $kingpin->parse;

    # perl sample.pl hello
    printf "name : %s\n", $name;

Automatically generate --help option.

    usage: script.pl [<flags>] <name>

    Flags:
      -h, --help     Show context-sensitive help.
      -v, --verbose  Verbose mode.

    Args:
      <name>  Name of user.

Support sub-command.

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $post       = $kingpin->command('post', 'Post a message to a channel.');
    my $post_image   = $post->flag('image', 'Image to post.')->file;
    my $post_channel = $post->arg('channel', 'Channel to post to.')->required->string;
    my $post_text    = $post->arg('text', 'Text to post.')->string_list;

    my $cmd = $kingpin->parse;

    if ($cmd eq 'register') {
        printf "register %s %s\n", $register_nick, $register_name;
    } elsif ($cmd eq 'post') {
        printf "post %s %s %s\n", $post_image, $post_channel, @{$post_text->value};
    } else {
        $kingpin->help;
    }

Help is below.

    usage: script.pl [<flags>] <command> [<args> ...]

    Flags:
      --help  Show context-sensitive help.

    Commands:
      help [<command>...]
        Show help.

      register [<nick>] [<name>]
        Register a new user.

      post [<flags>] [<channel>] [<text>]
        Post a message to a channel.

# DESCRIPTION

Getopt::Kingpin is a command line parser.
It supports flags and positional arguments.

- Simple to use
- Automatically generate help flag (--help).

This module is inspired by Kingpin written in golang.
https://github.com/alecthomas/kingpin

# METHOD

## new()

Create a parser object.
Default script-name is basename($0).

    my $kingpin = Getopt::Kingpin->new;
    my $kingpin = Getopt::Kingpin->new("script-name.pl", "description of script");
    my $kingpin = Getopt::Kingpin->new(
        name        => "script-name.pl",
        description => "description of script",
    );

    # Use hash ref to set description only.
    my $kingpin = Getopt::Kingpin->new({
        description => "description of script",
    });

## flag($name, $description)

Add and return Getopt::Kingpin::Flag object.

    # Define --debug option
    my $debug = $kingpin->flag("debug", "Enable debug mode.");

    # Set $debug to boolean value
    $debug->bool;

    # shorthand
    my $debug = $kingpin->flag("debug", "Enable debug mode.")->bool;

Getopt::Kingpin::Flag object has methods below.

### value()

Get flag value.

    my $name = $kingpin->flag("name", "Set name.")->string;

    # perl script.pl --name 'kingpin'
    printf "%s\n", $name->value;  # -> kingpin

    # simple way
    printf "%s\n", $name;  # -> kingpin

### short()

Set short flag.

    # Define --debug and -d
    my $debug = $kingpin->flag("debug", "Enable debug mode.")->short('-d')->bool;

### default()

The default value can be overridden with the default($value).

    # Set default value to true (1)
    my $debug = $kingpin->flag("debug", "Enable debug mode.")->default(1)->bool;

The default can be set to a coderef or object overloading &{}.

    my $debug = $kingpin->flag("debug", "Enable debug mode.")->default(sub {
      my $config = read_config_files();
      return $config->{DEBUG};
    })->bool;

### override\_default\_from\_envar()

The default value can be overridden with the override\_default\_from\_envar($envar).

    # Set default value to environment value of __DEBUG__
    # export $__DEBUG__=1 to enable debug mode
    my $debug = $kingpin->flag("debug", "Enable debug mode.")->override_default_from_envar("__DEBUG__")->bool;

### required()

Set required.

    my $debug = $kingpin->flag("debug", "Enable debug mode.")->required->bool;

### placeholder()

Set placeholder value for flag in the help.
Here are some examples of flags with various permutations.

    --name=NAME        # flag("name")->string
    --name="Harry"     # flag("name")->default("Harry")->string
    --name=FULL-NAME   # flag("name")->placeholder("FULL-NAME")->string

### hidden()

If set hidden(), flag does not appear in the help.

### types

#### bool()

Boolean value. (0 or 1)
Boolean flag has a negative complement: --&lt;name> and --no-&lt;name>.

    # --debug or --no-debug
    my $debug = $kingpin->flag("debug")->bool;

#### existing\_dir()

Path::Tiny object.

#### existing\_file()

Path::Tiny object.

#### existing\_file\_or\_dir()

Path::Tiny object.

#### file()

Path::Tiny object.

#### int()

Integer value.

#### num()

Numeric value.

#### string()

String value.
It is default type to flag.

#### string\_list(), int\_list(), file\_list(), etc

Allows repeated uses of a flag.

    --input=customers.csv --input=customers2.csv

#### string\_hash(), int\_hash(), file\_hash(), etc

Allows repeated use of a flag as key-value pairs.

    --define os=linux --define arch=x86_64

## arg($name, $description)

Add and return Getopt::Kingpin::Arg object.

    my $name = $kingpin->arg("name", "Set name")->string;

Getopt::Kingpin::Arg object has methods below.
Below are same as Flag's.

### value()

Get value.

### default()

Set default value.

### override\_default\_from\_envar()

Set default value by environment variable.

### required()

Set required.

## command()

Add sub-command.

    my $post    = $kingpin->command("post", "post image");

## parse()

Parse @arguments.
If @arguments is empty, parse @ARGV.

    # parse @ARGV
    $kingpin->parse;

    # parse @arguments
    $kingpin->parse(@arguments);

If define sub-command, parse() return Getopt::Kingpin::Command object;

    my $kingpin = Getopt::Kingpin->new();
    my $post    = $kingpin->command("post", "post image");
    my $server  = $post->arg("server", "")->string();
    my $image   = $post->arg("image", "")->file();

    my $cmd = $kingpin->parse;
    printf "cmd : %s\n", $cmd;
    printf "cmd : %s\n", $cmd->name;

You may also pass an arrayref to parse():

    $kingpin->parse( \@arguments );

An empty arrayref will not cause Kingpin to parse @ARGV like
an empty array would.

## \_parse()

Parse @\_. Internal use only.

## version($version)

Set application version to $version.

## help\_short()

Internal use only.

## help()

Print help.

# SEE ALSO

- [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)
- [Getopt::Long::Descriptive](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ADescriptive)
- [Smart::Options](https://metacpan.org/pod/Smart%3A%3AOptions)
- [MooseX::Getopt::Usage](https://metacpan.org/pod/MooseX%3A%3AGetopt%3A%3AUsage)

# LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

sago35 <sago35@gmail.com>
