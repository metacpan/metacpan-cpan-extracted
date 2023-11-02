# NAME

File::Takeput - Slurp style file IO with locking.

# VERSION

0.30

# SYNOPSIS

    use File::Takeput;

    # Lock some file and read its content.
    my @content1 = take('some_file_name.csv');

    # Read content of some other file.
    # Retry for up to 2.5 seconds if it is already locked.
    my @content2 = grab('some_other_file_name.log' , patience => 2.5);

    # Append some data to that other file.
    append('some_other_file_name.log')->(@some_data);

    # Read content of some third file as a single string.
    my ($content3) = grab('some_third_file_name.html' , separator => undef);

    # Write content back to the first file after editing it.
    # The locks will be released right afterwards.
    $content1[$_] =~ s/,/;/g for (0..$#content1);
    put('some_file_name.csv')->(@content1);

# DESCRIPTION

Slurp style file IO with locking. The purpose of Takeput is to make it pleasant for you to script file IO. Slurp style is both user friendly and very effective if you can have your files in memory.

The other major point of Takeput is locking. Takeput is careful to help your script be a good citizen in a busy filesystem. All its file operations respect and set flock locking.

If your script misses a lock and does not release it, the lock will be released when your script terminates.

Encoding is often part of file IO operations, but Takeput keeps out of that. It reads and writes file content just as strings of bytes, in a sort of line-based binmode. Use some other module if you need decoding and encoding. For example:

    use File::Takeput;
    use Encode;

    my @article = map {decode('iso-8859-1',$_)} grab 'article.latin-1';

# SUBROUTINES AND VARIABLES

Imported by default:
[append](#append-filename-data),
[grab](#grab-filename),
[pass](#pass-filename),
[plunk](#plunk-filename-data),
[put](#put-filename-data),
[take](#take-filename)

Imported on demand:
[fgrab](#fgrab-filename),
[fpass](#fpass-filename),
[ftake](#ftake-filename),
[reset](#reset),
[set](#set-settings)

- append( $filename )->( @data )

    Appends @data to the $filename file.

- grab( $filename )

    Reads and returns the content of the $filename file. Will never change the content of $filename, or create the file.

    Reading an empty file will return a list with one element, the empty string. If a false value is returned instead, it is because "grab" could not read the file.

- pass( $filename )

    Releases the lock on the $filename file.

    The content of the file will normally be the same as when the lock was taken with the "take" subroutine. This is useful when a lock was taken, but it later turned out that there was nothing to write to the file.

    There are two caveats. If the "create" configuration parameter is true, the file might have been created when it was taken, so it has been changed in that sense. And of course flock locks are only advisory, so other processes can ignore the locks and change the file while it is taken.

- plunk( $filename )->( @data )

    Overwrites the $filename file with @data.

- put( $filename )->( @data )

    Overwrites the taken $filename file, with @data, and releases the lock on it.

    Setting the ["create" configuration parameter](#create) on this call will not work. Set it on the "take" call instead.

- take( $filename )

    Sets a lock on the $filename file, reads and returns its content.

    The "take" call has write intention, because it is the first part of an operation. The second part is a call A call to "put" or "pass".

    Opening an empty file will return a list with one element, the empty string. If a false value is returned instead, it is because "take" could not read the file.

- fgrab( $filename )

    A functional version of the "grab" subroutine.

- fpass( $filename )

    A functional version of the "pass" subroutine.

- ftake( $filename )

    A functional version of the "take" subroutine.

    Note that "take"s twin, "put", also returns a function. With these you can separate the file operations from their definitions. As you can with filehandles. This is true for all the functional subroutines. Here is an example using "ftake" and "put", where they are sent as parameters.

        sub changecurr($r,$w,$x) {
            $w->( map {s/((\d*\.)?\d+)/$x*$1/ger} $r->() );
            };

        my $r = ftake('wednesday.csv' , patience => 5);
        my $w = put('wednesday.csv');
        my $rate = current_rate('GBP');
        changecurr($r,$w,$rate);

- reset

    Sets the default configuration parameters back to the Takeput defaults.

- set( %settings )

    Customize the default values by setting parameters as in %settings. Can be reset by calling "reset".

# CONFIGURATION

There are eight configuration parameters.

- create

    A scalar. If true the subroutines that have write intention, will create the file if it does not exist. If false, they will just fail if the file does not exist.

    Be careful with this parameter. For example if a process renames the file while another process is waiting for the lock, that other process will open the file with the new name when it gets the lock. If it plunks, it is not to a file with the name it was called with, but to the file with this new name. Maybe not what is wanted...

    The "create" parameter is ignored by "put". Use it on "take" instead, if you want this functionality.

- error

    A ref to a subroutine that is called if Takeput runs into a runtime error. It will be called without parameters. The $@ variable will be set just prior to the subroutine call, and the subroutines return value will be passed on back to your script. An example:

        use Logger::Syslog qw(warning);
        use File::Takeput error => sub {warning 'commit.pl: '.$@; die;};

        my @data = take('transaction.data' , patience => 10);
        do_stuff [@data];
        put('transaction.data')->(@data);

    If you just need non-fatal warnings, here is a simple error handler you can use:

        use File::Takeput error => sub {print STDERR "$@\n"; undef;};

    If the value of "error" is undef, Takeput will not make these calls.

- exclusive

    A scalar. If true Takeput will take an exclusive lock on read operations. If false it will just take a shared lock on them, as it normally does.

- flatten

    A scalar. If true Takeput will flatten the file content and return it as a string. If false it will return an array.

    Normally you would also set "separator" to undef, when you set "flatten" to true. For example:

        use YAML::XS qw(Load Dump);                            # Working with YAML.

        File::Takeput::set(separator => undef , flatten => 1); # Because of this...
        my $fancy_data = Load grab('my_file.yaml');            # ...this will work.

    Note that with "flatten" set to true, reading an empty file returns the empty string, which counts as false. Failing to read a file returns undef. So test for definedness to not be tricked by this.

- newline

    A string that replaces the "separator" string at the end of each line when reading from a file. When writing to a file the replacement is the other way around. Then "separator" will replace "newline".

    If either the "newline" value or the "separator" value is undef, no replacements will be done.

- patience

    The time in seconds that a call will wait for a lock to be released. The value can be fractional.

    If "patience" is set to 0, there will be no waiting.

- separator

    The string defining the end of a line. It is used in read operations to split the data into lines. Note that the value is read as a bytestring. So take care if you use a special separator in combination with an unusual encoding.

    Setting this parameter does not change the value of $/ or vice versa.

    The "separator" value cannot be an empty string. If it is undef the data is seen as a single string.

- unique

    A scalar. If true Takeput will fail opening a file if it already exists. This can be used to avoid race conditions.

    Only used by calls with write intention.

    If "unique" is true, calls will work as if "create" is true and "patience" is 0, no matter what they are set to.

## CONFIGURATION OPTIONS

You have a number of options for setting the configuration parameters.

- 1. In a file operation call, as optional named parameters.
- 2. In a statement by calling "set" or "reset".
- 3. Directly in the use statement of your script.
- 4. Default configuration.

If a parameter is set in more than one way, the most specific setting wins out. In the list above, the item with the lowest number wins out.

### 1. OPTIONAL NAMED PARAMETERS

All the file operation subroutines can take the configuration parameters as optional named parameters. That means that you can set them per call. The place to write them is after the filename parameter. Example:

    my @text = grab 'windows_file.txt' , separator => "\r\n" , newline => "\n";

### 2. SET AND RESET SUBROUTINES

The two subroutines "set" and "reset" will customize the default values of the configuration parameters, so that subsequent file operations are using those defaults.

You use "set" to set the values, and "reset" to set the values back to the Takeput defaults. Think of it as assignment statements. If there are multiple calls, the last one is the one that is in effect.

Customized defaults are limited to the namespace in which you set them.

### 3. USE STATEMENT

Another way to customize the default values is in the use statement that imports Takeput. For example:

    use File::Takeput separator => "\n";

When you do it like this, the values are set at compile-time. Because of that, Takeput will die on any errors that those settings will give rise to.

Note that customized defaults are limited to the namespace in which you set them.

### 4. DEFAULT CONFIGURATION

The Takeput defaults are:

`create`: undef (false)

`error`: undef

`exclusive`: undef (false)

`flatten`: undef (false)

`newline`: undef

`patience`: 0

`separator`: $/ (at compile time)

`unique`: undef (false)

# ERROR HANDLING

Takeput will die on compile-time errors, but not on runtime errors. In case of a runtime error it might or might not issue a warning. But it will always write an error message in $@ and return an error value.

That said, you have the option of changing how runtime errors are handled, by using the ["error" configuration parameter](#error).

# DEPENDENCIES

Cwd

Exporter

Fcntl

File::Basename

Scalar::Util

Time::HiRes

# KNOWN ISSUES

No known issues.

# TODO

Decide on empty string "separator". It ought to give a list of bytes, but readline gives an unintuitive list. It would be a mess with the line ending transformations.

An empty string will be an invalid value for now.

# SEE ALSO

[Encode](https://metacpan.org/pod/Encode)

[File::Slurp](https://metacpan.org/pod/File::Slurp)

[File::Slurper](https://metacpan.org/pod/File::Slurper)

# LICENSE & COPYRIGHT

(c) 2023 Bjørn Hee

Licensed under the Apache License, version 2.0

https://www.apache.org/licenses/LICENSE-2.0.txt
