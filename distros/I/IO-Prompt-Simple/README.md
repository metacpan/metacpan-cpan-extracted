[![Build Status](https://travis-ci.org/xaicron/p5-IO-Prompt-Simple.svg?branch=master)](https://travis-ci.org/xaicron/p5-IO-Prompt-Simple)
# NAME

IO::Prompt::Simple - provide a simple user input

# SYNOPSIS

    # foo.pl
    use IO::Prompt::Simple;

    my $answer = prompt 'some question...';
    print "answer: $answer\n";

    # display prompt message, and wait your input.
    $ foo.pl
    some question: foo[Enter]
    answer: foo

# DESCRIPTION

IO::Prompt::Simple is porting [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)'s prompt() function.

Added a few more useful features.

THIS MODULE IS ALPHA LEVEL INTERFACE!!

# FUNCTIONS

## prompt($message, \[$default\_or\_option\])

Display prompt message and wait your input.

    $answer = prompt $message;

Sets default value:

    $answer = prompt 'sets default', 'default';
    is $answer, 'default';

or

    $answer = prompt 'sets default', { default => 'default' };
    is $answer, 'default';

Display like are:

    sets default [default]: [Enter]
    ...

supported options are:

- default: SCALAR

    Sets default value.

        $answer = prompt 'sets default', { default => 'default' };
        is $answer, 'default';

- anyone: ARRAYREF | HASHREF | REF-ARRAYREF | Hash::MultiValue

    Choose any one.

        $answer = prompt 'choose', { anyone => [qw/y n/] };

    Display like are:

        choose (y/n) : [Enter]
        # Please answer `y` or `n`
        choose (y/n) : y[Enter]
        ...

    If you specify HASHREF, returned value is HASHREF's value.

        $answer = prompt 'choose', { anyone => { y => 1, n => 0 } };
        is $answer, 1; # when you input is 'y'

    And, when you specify the verbose option, you can tell the user more information.

        $answer = prompt 'choose your homepage', {
            anyone => {
                google => 'http://google.com/',
                yahoo  => 'http://yahoo.com/',
                bing   => 'http://bing.com/',
            },
            verbose => 1,
        };

    Display like are:

        # bing   => http://bing.com/
        # google => http://google.com/
        # yahoo  => http://yahoo.com/
        choose your homepage : [Enter]
        # Please answer `bing` or `google` or `yahoo`
        choose your homepage : google[Enter]
        ...

    If you want preserve the order of keys, you can use [Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue).

        $answer = prompt 'foo', { anyone => { b => 1, c => 2, a => 4 } }; # prompring => `foo (a/b/c) : `
        $answer = prompt 'foo', {
            anyone => Hash::MultiValue->new(b => 1, c => 2, a => 4)
        }; # prompring => `foo (b/c/a) : `

    Or, you can use REF-ARRAYREF.

        $answer = prompt 'foo', { anyone => \[b => 1, c => 2, a => 4] };

- choices

    Alias of `anyone`

- multi: BOOL

    Returned multiple answers. Your answer are evaluated separated by space.

        use Data::Dumper;
        @answers = prompt 'choices', {
            choices => [qw/a b c/],
            multi   => 1,
        };
        print Dumper \@answers;

    Display like are:

        choices (a/b/c) : c a[Enter]
        $VAR1 = [
                  'c',
                  'a'
                ];

    Or, you can specify HASHREF:

        use Data::Dumper;
        @answers = prompt 'choices', {
            choices => {
                google => 'http://google.com/',
                yahoo  => 'http://yahoo.com/',
                bing   => 'http://bing.com/',
            },
            verbose => 1,
            multi   => 1,
        };
        print Dumper \@answers;

    Display like are:

        # bing   => http://bing.com/
        # google => http://google.com/
        # yahoo  => http://yahoo.com/
        choices: google yahoo[Enter]
        $VAR1 = [
                  'http://google.com/',
                  'http://yahoo.com/'
                ];

- regexp: STR | REGEXP

    Sets regexp for answer.

        $answer = prompt 'regexp', { regexp => '[0-9]{4}' };

    Display like are:

        regexp : foo[Enter]
        # Please answer pattern (?^:[0-9{4}])
        regexp : 1234
        ...

    It `regexp` and `anyone` is exclusive (`anyone` is priority).

- ignore\_case: BOOL

    Ignore case for anyone or regexp.

        # passed `Y` or `N`
        $answer = prompt 'ignore_case', {
            anyone      => [qw/y n/],
            ignore_case => 1,
        };

- yn: BOOL

    Shortcut of `{ anyone => \[ y => 1, n => 0 ], ignore_case => 1 }`.

        $answer = prompt 'are you ok?', { yn => 1 };

    Display like are:

        are you ok? (y/n) : y[Enter]

- use\_default: BOOL

    Force using for default value.
    If not specified defaults to an empty string.

        $answer = prompt 'use default', {
            default     => 'foo',
            use_default => 1,
        };
        is $answer, 'foo';

    I think, CLI's `--force` like option friendly.

- input: FILEHANDLE

    Sets input file handle (default: STDIN)

        $answer = prompt 'input from DATA', { input => *DATA };
        is $answer, 'foobar';
        __DATA__
        foobar

- output: FILEHANDLE

    Sets output file handle (default: STDOUT)

        $answer = prompt 'output for file', { output => $fh };

- encode: STR | Encoder

    Sets encoding. If specified, returned a decoded string.

- color: STR | ARRAYREF

    Sets prompt color. Using [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor).

        $answer = prompt 'colored prompting', { color => [qw/red on_white/] };

# NOTE

If prompt() detects that it is not running interactively
and there is nothing on `$input`
or if the `$ENV{PERL_IOPS_USE_DEFAULT}` is set to true
or `use_default` option is set to true,
the `$default` will be used without prompting.

This prevents automated processes from blocking on user input.

# AUTHOR

xaicron &lt;xaicron {at} gmail.com>

# COPYRIGHT

Copyright (C) 2011 Yuji Shimada (@xaicron).

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)
[IO::Prompt](https://metacpan.org/pod/IO::Prompt)
