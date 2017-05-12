# NAME

Getopt::Compact::WithCmd - sub-command friendly, like Getopt::Compact

# SYNOPSIS

inside foo.pl:

    use Getopt::Compact::WithCmd;
    
    my $go = Getopt::Compact::WithCmd->new(
       name          => 'foo',
       version       => '0.1',
       args          => 'FILE',
       global_struct => [
          [ [qw/f force/], 'force overwrite', '!', \my $force ],
       ],
       command_struct => {
          get => {
              options     => [
                  [ [qw/d dir/], 'dest dir', '=s', undef, { default => '.' } ],
                  [ [qw/o output/], 'output file name', '=s', undef, { required => 1 }],
              ],
              desc        => 'get file from url',
              args        => 'url',
              other_usage => 'blah blah blah',
          },
          remove => {
              ...
          }
       },
    );
    
    my $opts = $go->opts;
    my $cmd  = $go->command;
    
    if ($cmd eq 'get') {
        my $url = shift @ARGV;
    }

how will be like this:

    $ ./foo.pl -f get -o bar.html http://example.com/

usage, running the command './foo.pl -x' results in the following output:

    $ ./foo.pl -x
    Unknown option: x
    foo v0.1
    usage: foo.pl [options] COMMAND FILE
    
    options:
       -h, --help           This help message
       -f, --force   Bool   Force overwrite
    
    Implemented commands are:
       get   Get file from url
    
    See 'foo.pl help COMMAND' for more information on a specific command.

in addition, running the command './foo.pl get' results in the following output:

    $ ./foo.pl get
    `--output` option must be specified
    foo v0.1
    usage: foo.pl get [options] url
    
    options:
       -h, --help                                     This help message
       -d, --dir      Str            (default: '.')   Dest dir
       -o, --output   Str (required)                  Output file name
    
    blah blah blah

# DESCRIPTION

Getopt::Compact::WithCmd is yet another Getopt::\* module.
This module is respected [Getopt::Compact](https://metacpan.org/pod/Getopt::Compact).
This module is you can define of git-like option.
In addition, usage can be set at the same time.

# METHODS

## new(%args)

Create an object.
The option most Getopt::Compact compatible.
But _struct_ is cannot use.

The new _%args_ are:

- `global_struct($arrayref)`

    This option is sets common options across commands.
    This option value is Getopt::Compact compatible.
    In addition, extended to other values can be set.

        use Getopt::Compact::WithCmd;
        my $go = Getopt::Compact::WithCmd->new(
            global_struct => [
                [ $name_spec_arrayref, $description_scalar, $argument_spec_scalar, \$destination_scalar, $opt_hashref ],
                [ ... ]
            ],
        );

    And you can also write in hash style.

        use Getopt::Compact::WithCmd;
        my $go = Getopt::Compact::WithCmd->new(
            global_struct => {
                $name_scalar => {
                    alias => $name_spec_arrayref,
                    desc  => $description_scalar,
                    type  => $argument_spec_scalar,
                    dest  => \$destination_scalar,
                    opts  => $opt_hashref,
                },
                $other_name_scalar => {
                    ...
                },
            },
        );

    _$argument\_spec\_scalar_ can be set value are [Getopt::Long](https://metacpan.org/pod/Getopt::Long)'s option specifications.
    And you can also specify the following readable style:

        Bool     # eq !
        Incr     # eq +
        Str      # eq =s
        Int      # eq =i
        Num      # eq =f
        ExNum    # eq =o

    In addition, Array and Hash type are:

        Array[Str] # eq =s@
        Hash[Int]  # eq =i%
        ...

    _$opt\_hasref_ are:

        {
            default  => $value, # default value
            required => $bool,
        }

- `command_struct($hashref)`

    This option is sets sub-command and options.

        use Getopt::Compact::WithCmd;
        my $go = Getopt::Compact::WithCmd->new(
            command_struct => {
                $command => {
                    options        => $options,
                    args           => $args,
                    desc           => $description,
                    other_usage    => $other_usage,
                    command_struct => $command_struct,
                },
            },
        );

    _$options_

    This value is compatible to `global_struct`.

    _$args_

    command args.

    _$description_

    command description.

    _$other\_usage_

    other usage message.
    be added to the end of the usage message.

    _$command\_struct_

    support nesting.

        use Getopt::Compact::WithCmd;
        my $go = Getopt::Compact::WithCmd->new(
            command_struct => {
                $command => {
                    options        => $options,
                    args           => $args,
                    desc           => $description,
                    other_usage    => $other_usage,
                    command_struct => {
                        $sub_command => {
                            options => ...
                        },
                    },
                },
            },
        );

        # will run cmd:
        $ ./foo.pl $command $sub_command ...

## add\_type($new\_type, $src\_type, $code\_ref);

This method is additional your own type.
You must be call before new() method.

    use JSON;
    use Data::Dumper;

    Getopt::Compact::WithCmd->add_type(JSON => Str => sub { decode_json(shift) });
    my $go = Getopt::Compact::WithCmd->new(
        global_struct => {
            from_json => {
                type => 'JSON',
            },
        },
    );
    my $data = $go->opts->{from_json};
    print Dumper $data;

    # will run cmd:
    $ ./add_type.pl --from_json '{"foo":"bar"}'
    $VAR1 = {
              'foo' => 'bar'
            };

## new\_from\_array(\\@myopts, %args);

`new_from_array` can be used to parse options from an arbitrary array.

    $go = Getopt::Compact::WithCmd->new_from_array(\@myopts, ...);

## new\_from\_string($option\_string, %args);

`new_from_string` can be used to parts options from an arbitrary string.

This method using [Text::ParseWords](https://metacpan.org/pod/Text::ParseWords) on internal.

    $go = Getopt::Compact::WithCmd->new_from_string('--foo bar baz', ...);

## opts

Returns a hashref of options keyed by option name.
Return value is merged global options and command options.

## command

Gets sub-command name.

    # inside foo.pl
    use Getopt::Compact::WithCmd;
    
    my $go = Getopt::Compact::WithCmd->new(
       command_struct => {
          bar => {},
       },
    );
    
    print "command: ", $go->command, "\n";
    
    # running the command
    $ ./foo.pl bar
    bar

## commands

Get sub commands. Returned value is ARRAYREF.

    # inside foo.pl
    use Getopt::Compact::WithCmd;
    
    my $go = Getopt::Compact::WithCmd->new(
       command_struct => {
          bar => {
              command_struct => {
                  baz => {},
              },
          },
       },
    );
    
    print join(", ", @{$go->commands}), "\n";
    
    # running the command
    $ ./foo.pl bar baz
    bar, baz

## status

This is a true value if the command line was processed successfully. Otherwise it returns a false result.

    $go->status ? "success" : "fail";

## is\_success

Alias of `status`

    $go->is_success # == $go->status

## usage

Gets usage message.

    my $message = $go->usage;
    my $message = $go->usage($target_command_name); # must be implemented command.

## show\_usage

Display usage message and exit.

    $go->show_usage;
    $go->show_usage($target_command_name);

## completion

Gets shell completion string.

    my $comp = $go->completion('bash');

NOTICE:
completion() supports only one nested level of "command\_struct".
completion() supports only bash.

## show\_completion

Display completion string and exit.

    $go->show_completion('bash');

## error

Return value is an error message or empty string.

    $go->error;

## args

Return value is array reference to any remaining arguments.

    $go->args # like \@ARGV

## pod2usage

__Not implemented.__

# AUTHOR

xaicron <xaicron {at} cpan.org>

# COPYRIGHT

Copyright 2010 - xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Getopt::Compact](https://metacpan.org/pod/Getopt::Compact)
