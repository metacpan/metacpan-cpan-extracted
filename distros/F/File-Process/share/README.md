# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [EXPORTED METHODS](#exported-methods)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
  * [process\_csv](#process\csv)
  * [process\_file](#process\file)
  * [Custom Processors](#custom-processors)
    * [pre(file, options)](#prefile-options)
    * [next\_line(fh, lines, options)](#next\linefh-lines-options)
    * [filter(fh, lines, options, current\_line)](#filterfh-lines-options-current\line)
    * [process(fh, lines, options, current\_line)](#processfh-lines-options-current\line)
    * [post(fh, lines, options)](#postfh-lines-options)
* [DEFAULT PROCESSORS](#default-processors)
* [STATISTICS](#statistics)
* [EXAMPLES](#examples)
* [CAVEATS](#caveats)
* [LICENSE](#license)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
# NAME

File::Process - process text files with custom handlers

# SYNOPSIS

    use File::Process;

    my ($lines, $info) = process_file($file, process => sub { 
        my ($fh, $lines, $args, $line) = @_;
        return uc $line;
       });

# DESCRIPTION

Many scripts need to process one or more text files. The boiler-plate
usually looks something like:

    open my $fh, '<', $file
       or croak "blah blah blah...\n";

    while (<$fh> ) {
      # do something...
    }

    close $fh or
       croak "blah blah blah...\n";

The _do something..._ part often involves other common operations like
removing new lines, skipping blank lines, etc. It gets tedious when you
have to write the same template for processing different files in a
script. 

This class provides a simple harness for processing files, taking
the drudgery out of writing a simple text processor. It is most effect
when used on relatively small files (see ["CAVEATS"](#caveats)).

In it's most basic form the class will return all of the lines in a
text file. The class exports one method (`process_file`) which invokes
multiple subroutines that you can override or use in conjunction with
your custom processors.

_See `File::Process::Utils` for additional recipes._

# EXPORTED METHODS

This module exports one method by default (`process_file`), since
presumably you wanted to _process_ a file? You can export all of the
default processor methods using the tag ':all'.

    use File::Process qw( pre post );

    use File::Process qw( :all );

# METHODS AND SUBROUTINES

## process\_csv

    process_csv(file, options)

See [File::Process::Utils](https://metacpan.org/pod/File%3A%3AProcess%3A%3AUtils)

## process\_file

    process_file(file, options)

You start the processing of the file by calling `process_file` with
the name of the file or a handle to an open file and a **list** of
options.  Note that the processors will pass and receive a
**reference** to this list of options during the processing of the
file.

The method returns a list containing a reference to an array that
contains each line of the file followed by the list of elements in the
hash that was originally passed to it (along with any other data your
custom method has inserted into it).

    my ($lines, %options) = process_file("foo.txt", chomp => 1);

- file

    Path to the file to be processed or a handle to an open file.

- options

    A **list** of options. You can send whatever options your custom
    processor supports. Before the default or your custom `process`
    subroutine is called, the `filter` subroutine is called. This is
    where you might massage the input in some way.  The default `filter`
    subroutine supports various options to perform routine tasks. Options
    are described below.

    - skip\_blank\_lines

        Skip _blank lines_. A blank line is considered a line with only a new
        line character.

    - skip\_comments

        Set `skip_lines` to a true value to skip lines that beging with '#'.

    - merge\_lines

        Merges lines together rather that creating an array of
        lines. Typically used with the `chomp` option. When `merge_lines` is
        set to a true value, `IO::Scalar` is used to efficiently create a
        single scalar from all of the lines in the file.  The first element of
        the return list then a scalar instead of an array reference.

    - chomp

        Set `chomp` to a true value to remove a trailing new line.

    - trim

        Set `trim` to one of _front_, _back_, _both_ to remove
        whitespace from the front, back or both front and back of a line. Note
        that this operation is performed _before_ your custom processor is
        called and may result in the line being skipped if the
        `skip_blank_lines` option is set to a true value.

## Custom Processors

`process_file` will execute a set of subroutines for each line of the
file. You can replace any of these subroutines to inject your own
custom behaviors. They are executed in this order:

- 1. `pre`
- 2. `next_line`
- 3. `filter`
- 4. `process`
- 5. `post`

- You can terminate processing of a file by returning an undefined value
for the `next_line()` hook
- Returning undef for the `filter()`, and
`process()` hooks will prevent a line from being accumulated in the
line buffer
- Any hook you define can terminate the process by throwing
an exception.

The default processors are described below.

### pre(file, options)

The default `pre` processor opens the file and returns a file handle
and a reference to an array that will be used to store the lines. If
you provide your own `pre` process it should also return a tuple that
contains the file handle and a reference to an array that will be used
to store each processed line of the file. _Note that you don't have
to adhere to this contract if your downstream processors don't require
the same returns._

- file

    Path to a file that can be opened for reading or a handle
    to an open file.

- options

    A reference to a hash that contains the options passed from
    `process_file`.  The hash will be passed to the `process` method, so
    can be used to store data as you are processing the each line.  The
    default `process` method will record counts of lines processed and other
    potentially useful statistics.

### next\_line(fh, lines, options)

The `next_line` method is passed the file handle, the buffer of
accumulated lines, and a reference to a hash of options passed to
`process_file`. It is expected to return the _next line_ of the
file, however your custom processor can return anything it
likes. That object returned will be sent to the `process` subroutine
for possible further processing.

Returning `undef` will halt further processing.

### filter(fh, lines, options, current\_line)

The default `filter` method will perform various tasks (chomp, trim,
skip) controlled by the options described above.

If the `chomp` option is set to true when you called `process_file`,
the line will be chomped.  You can also set the `skip_blank_lines`
or `skip_comments` to skip blank lines or skip lines that begin
with '# '.

Filters should return the line or `undef` to skip the current line.
If you really want to add `undef` to your buffer, do so in your
filter:

    push @{$lines}, undef;

If you want to halt processing here, `die` in your filter. Any
exception will halt further processing.

### process(fh, lines, options, current\_line)

The `process` method is passed the file handle, the buffer of
accumulated lines, a reference to a hash of options passed to
`process_file` and the next line of the the text file.  The default
processor simply returns the `current_line` value.

- fh

    Handle to an open file or an object that supports an `IO::Handle`
    like interface. If `fh` is undefined the 

- lines

    A reference to an array that contains the lines read thus far.

- options

    A reference to a hash of options passed to `process_file`.

- current\_line

    The next line of data from the file.

### post(fh, lines, options)

The `post` method is passed the same three arguments as passed to
`process`.  The default `post` method closes the file and records
the end time of process. The default `post` method returns an array
reference to the buffer of lines and list of options.  Note that a
reference to the list is passed in but a **list** is returned.  This is
also the return value of `process_file`.  Your custon post can return
anything it wants.

# DEFAULT PROCESSORS

Any of default processors (**pre**, **next\_line**, **filter**,
**process**, **post**) can be called before or after your custom
processors.  Pass these methods the same list you receive.

    process_file(
      "foo.txt",
      post  => sub {
        my @retval = post(@_);
        $retval[0] = join '', @{ $_[1] };
        return @retval;
      }
    );

# STATISTICS

- start\_time
- end\_time
- raw\_count
- skipped

# EXAMPLES

- Return the all of the lines in a text file

        my ($lines) = process_file('foo.txt');

- Read JSON file

        print Dumper(
          process_file(
            $fh,
            chomp => 1,
            post  => sub {
              post(@_);
              return decode_json( join '', @{ $_[1] } );
            }
          )
        );

    ...or

        print Dumper(
          decode_json(
            process_file(
              $fh,
              chomp       => 1,
              merge_lines => 1
            )
          )
        );

- Read CSV file

    Presented here as example, however you can use the ["process\_csv"](#process_csv)
    method for processing CSV files.

        use File::Process qw(pre process_file);
        use Text::CSV_XS;
        use Data::Dumper;

        my $csv = Text::CSV_XS->new;

        my $file = shift;

        my ($csv_lines) = process_file(
          $file,
          csv   => $csv,
          chomp => 1,
          has_headers => 1,
          pre   => sub {
            my ( $fh, $args ) = @_;

            my ($fh, $all_lines) = pre($file, $args);

            if ( $args->{'has_headers'} ) {
              my @column_names = $args->{csv}->getline($fh);
              $args->{csv}->column_names(@column_names);
            }

            return ($fh, $all_lines);
          },
          next_line => sub {
            my ( $fh, $all_lines, $args ) = @_;
            my $ref = $args->{csv}->getline_hr($fh);
            return $ref;
            }
        )

# CAVEATS

Processing each line using hooks and callbacks can introduce
inefficiencies in file processing. This class is meant to be used on
moderately sized files. In it's basic forms, the methods will read all
lines into memory as it iterates over the file. Your processing may
not require that lines be accumulated at all. Your custom `process()`
or `filter()` hook can choose to return an undefined value which
prevents a line from being added to the buffer.

Reading each line one-at-a-time may be inefficient as well, future
version may introduce a slurp mode and/or the ability to send an array
which represents a list of lines to process.

Some example times:

Timings were done a Linux system running on an _11th Gen Intel(R)
Core(TM) i7-1160G7 @ 1.20GHz (8 threads, 4.40GHz)_

As a baseline:

- Reading ~900K rows (pure Perl)

        .22s

- Slurping ~900K rows (pure Perl)

        .03s

Using `File::Process::process_file()`

- Reading ~900K rows (no processing)

        ~1.6s

- Reading ~900K rows from a CSV file with 5 columns
    - Returning an array of hashes:

            7-8s

    - Returning an array of arrays:

            ~10s

...so there's room for improving the speed of these calls...caveat emptor.

# LICENSE

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

# SEE ALSO

[File::Process::Utils](https://metacpan.org/pod/File%3A%3AProcess%3A%3AUtils)

# AUTHOR

Rob Lauer - <rlauer6@comcast.net>
