# NAME

Log::Any::Adapter::JSON - One-line JSON logging of arbitrary structured data

# SYNOPSIS

Get a logger and specify the output destination:

    use Log::Any '$log';
    use Log::Any::Adapter ('JSON', '/path/to/file.log');

    # or

    use Log::Any '$log';
    use Log::Any::Adapter;

    my $handle = ...; # FH, pipe, etc

    Log::Any::Adapter->set('JSON', $handle);

Log some data:

    $log->info('Hello, world');
    $log->info('Hello, %s', $name);
    $log->debug('Blabla', { tracking_id => 42 });
    $log->debug('Blorgle', { foo => 'bar' }, [qw/a b c/], 'last thing');

# DESCRIPTION

This [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) adapter logs formatted messages and arbitrary structured
data in a single line of JSON per entry. You must pass a filename or an open
handle to which the entries will be printed.

Optionally you may pass an `encoding` argument which will be used to apply
a `binmode` layer to the output handle. The default encoding is `UTF-8`.

Optionally you may turn off string formatting, see below.

# PARAMETERS

## log\_level

Set the minimum logging level to output. Any messages lower than this level
will be discarded. Default is trace.

    use Log::Any::Adapter ('JSON', \*STDERR, log_level => 'info');

## encoding

Defaults to `UTF-8`. Pass a different encoding to change the binmode applied
to the log output.

## localtime

By default the message `time` will be in UTC. If you wish to log using your
system's localtime instead, set this parameter to a true value. Output will
look something like:

    2021-05-01T10:01:37.482042-04:00

versus, by default, always something like:

    2021-05-01T10:01:37.482042Z

## without\_formatting

By default the message will be formatted using sprintf if it contains
formatting codes such as '%s'. This will cause the program to die if a
message does not contain enough arguments to process all the formatting
codes in a message. If your logs will contain the format codes and should
not be formatted, or to prevent log messages from dependencies or untrusted
sources from accidentally crashing the program, you can disable
message formatting by setting this parameter to a true value:

    use Log::Any::Adapter ('JSON', \*STDERR, without_formatting => 1);

# OUTPUT

## Logged data fields

The adapter expects a string and an optional list `@items`.

If the string has no formatting tokens, it is included in the log
entry in the `message` field as-is.

If the string has formatting tokens, `@items` is checked to verify
that the next `N` values are scalars, where `N` is the number of
tokens in the string. If the number is the same, the string and
tokens are combined using `sprintf()` and the resulting string is
included in the log entry in the `message` field. If the token
and value counts don't match, the adapter croaks.

After the format processing, the remainder of the `items` array is
processed. It may hold arrayrefs, which are included in a top-
level key named `list_data`; additional scalars, which are pushed
into the `additional_messages` key; and hashrefs. The first hashref
encountered has its keys promoted to top-level keys in the log entry,
while additional hashrefs are included in a top-level key named
`hash_data`.

## Other fields

In addition, the log entry will have the following fields:

- `time`
- `level`
- `category`

# EXAMPLES

## Plain text message

    $log->debug('a simple message');

Output is a **single line** with JSON like:

    {
      "category":"main",
      "level":"debug",
      "message":"hello, world",
      "time":"2021-03-03T17:23:25.731243Z"
    }

## Formatted message

    my $val = "string";
    my $num = 2;

    $log->debug('a formatted %s with %d tokens', $val, $num);

Output is a **single line** with JSON like:

    {
      "category":"main",
      "level":"debug",
      "message":"a formatted string with 2 tokens",
      "time":"2021-03-03T17:23:25.731243Z"
    }

## Single hashref

The first hashref encountered has its keys elevated to the top level.

    $log->debug('the message', { tracker => 42 });

Output is a **single line** with JSON like:

    {
      "category":"main",
      "level":"debug",
      "message":"the message",
      "time":"2021-03-03T17:23:25.731243Z",
      "tracker":42
    }

Reserved key names that may not be used in the first hashref include:

    * category
    * context
    * level
    * message
    * time

## Additional hashrefs and arrayrefs

    $log->debug('the message', { tracker => 42 }, { foo => 'bar'});

Output is a **single line** with JSON like:

    {
      "category":"main",
      "hash_data":[
        {"foo":"bar"}
      ],
      "level":"debug",
      "message":"the message",
      "time":"2021-03-03T17:23:25.731243Z",
      "tracker":42
    }

Another example:

    $log->debug('the message', { tracker => 42 }, {foo => 'bar'}, [1..3]);

Output is a **single line** with JSON like:

    {
      "category":"main",
      "hash_data":[
        {"foo":"bar"}
      ],
      "level":"debug",
      "list_data":[
        [1,2,3]
      ],
      "message":"the message",
      "time":"2021-03-03T17:23:25.731243Z",
      "tracker":42
  }

## Additional messages

Any scalars that are passed that are not consumed as the values of formatting
tokens will be included in an `additional_messages` key.

    $log->debug('a simple message', 'foo', 'bar');

Output is a **single line** with JSON like:

    {
      "additional_messages":[
        'foo',
        'bar'
      ],
      "category":"main",
      "level":"debug",
      "message":"hello, world",
      "time":"2021-03-03T17:23:25.731243Z"
    }

# SEE ALSO

[Log::Any](https://metacpan.org/pod/Log%3A%3AAny)

[Log::Any::Adapter](https://metacpan.org/pod/Log%3A%3AAny%3A%3AAdapter)
