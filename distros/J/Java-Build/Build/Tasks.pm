package Java::Build::Tasks;
use strict; use warnings;

=head1 NAME

Java::Build::Tasks - collects common Java build tasks in one place: jar, jarsigner, etc.

=head1 SYNOPSIS

    use Java::Build::Tasks;

    set_logger($log_object);

    copy_file('source', 'dest');
    copy_file('list', 'of', 'sources', 'dest');
    copy_file('-r', 'list', 'of', 'sources', 'with', 'flags', 'dest');
    copy_file([ 'list', 'of', 'sources' ], 'dest');
    copy_file([ '-r', 'list', 'of', 'sources', 'with', 'flags' ], 'dest');

    my $file_list = build_file_list(
        BASE_DIR         => 'where/to/start',
        EXCLUDE_PATTERNS => [ qr/leave/, qr/these/, qr/out/ ],
        INCLUDE_PATTERNS => [ qr/.*include/, qr/these.*/    ],
        EXCLUDE_DEFAULTS => 1,
        STRIP_BASE_DIR   => 1,
        QUOTE_DOLLARS    => 1,
    );

    jar(
        JAR_FILE  => 'some/full/path/ending/in/a.jar',
        FILE_LIST => $file_list;
        MANIFEST  => 'location/of/manifest/to/put/in/jar',
        BASE_DIR  => 'path/to/change/to/before/building/jar',
        APPEND    => 1,
    );

    signjar(
        JAR_FILE         => 'what/to/sign',
        KEYSTORE         => 'path/to/your/keystore',
        ALIAS            => $your_alias,
        STOREPASS        => $your_keystore_pass,
    );

    my $config_hash = read_prop_file($prop_file_name);

    update_prop_file(
        NAME      => '/optional/path/and/file.properties',
        NEW_PROPS => \%values_to_add_or_update,
    );

    filter_file(
        INPUT   => 't/file1',
        OUTPUT  => 't/file2',
        FILTERS => [
            sub { my $string = shift; $string =~ s/Happy/Joyous/g; $_;}
        ],
    );

    my $dirties = what_needs_compiling(
        SOURCE_FILE_LIST         => $list,
        SOURCE_DIR               => 'path/to/your/source/files',
        DEST_DIR                 => 'path/to/your/compiled/files',
        SOURCE_TO_COMPILIED_NAME => sub { ... },
    );

    my $classpath = make_jar_classpath(
        DIRS             => [ '/path/to/some/set/of/jars',
                              '/path/to/some/other/jars' ],
        INCLUDE_PATTERNS => [ qr/.jar$/, qr/.ZIP$/ ], # optional
    );

    purge_dirs($base_dir, qw(sub directories to remove));

=head1 DESCRIPTION

There are currently six tasks in this file.  Three are like Ant tasks:
update_prop_file (Ant calls this propertyfile), jar and signjar.  Two
build lists of files: build_file_list and what_needs_compiling.  One
reads a config file (or properties file) into a hash which it returns.

Call all of them with their hashes as shown above.  The $file_list which
jar expects, can be formed using build_file_list (as shown) or by simply
supplying a list of file names, as in:

    FILE_SET => [ "file1", "file2" ],

=head2 EXPORT

build_file_list
copy_file
filter_file
jar
make_jar_classpath
read_prop_file
set_logger
signjar
update_prop_file
what_needs_compiling

=head1 DEPENDENCIES

    Carp
    Exporter
    Cwd
    File::Find
    File::Temp

=head1 FUNCTIONS

Each function is described in more detail below.

=cut

use Carp;
use File::Find;
use Cwd;
use File::Temp qw( tempfile );
use Exporter;
our @ISA     = qw( Exporter );
our @EXPORT  = qw(
    filter_file build_file_list what_needs_compiling
    jar signjar read_prop_file update_prop_file copy_file
    make_jar_classpath purge_dirs
);
our $logger;
our $VERSION = "0.04";

sub _my_croak {
    my $message = shift;

    $logger->log($message, 100) if $logger;
    croak "$message\n";
}

sub _my_carp {
    my $message = shift;

    $logger->log($message, 60) if $logger;
    carp "$message\n";
}

sub _my_log {
    my $message  = shift;
    my $severity = shift;
    $logger->log($message, $severity) if $logger;
}

=head1 copy_file

This function performs a copy.  The only advantages of using it are to
gain error checking, file name quoting (to guard spaces), and optional
logging.  The last argument must be the destination.  The other argument(s)
can be either

    a flattened list which starts with optional flags for the cp command
    or
    an array reference which starts with optional flags

See sample calls in the SYNOPSIS for examples.

All space in the arguments are quoted.  Those in the source(s) with backslash,
those in the destintation with single quotes.

=cut

sub copy_file {
    my $dest         = pop;
    my @sources;

    if (ref($_[0]) =~ /ARRAY/) { @sources = @{$_[0]}; }
    else                       { @sources = @_;       }

    @sources = map { "'$_'" } @sources;

# This one appeared to fail:
#    @sources = map { s/ /\ /g; $_ } @sources;

    my $cp_out = `cp @sources '$dest' 2>&1`;
    if ($?) {
        _my_croak("couldn't cp @sources to $dest $cp_out $?");
    }
}

=head1 purge_dirs

Pass in the parent directory and a list of its children to vaporize.

=cut

sub purge_dirs {
    _my_log("purging...", 40);
    my $base = shift;

    foreach my $doomed_subdir (@_) {
        my $command = "rm -rf $base/$doomed_subdir";
        _my_log("$command", 20);
        my $purge_out = `$command 2>&1`;
        if ($?) {
            _my_log(
                "couldn't purge $base/$doomed_subdir $purge_out $?",
                HertzLog->WARNING
            );
        }
    }
}

=head1 set_logger

If you want logging of the tasks, pass a logging object to this method.
That object must implement a log method, which will receive two parameters
(in addition to the invocant): message and level.  Levels go from 0 (debug)
through 100 (fatal).  Typically, the tasks croak immediately after
sending fatal log messages.  Most message are informational an have level 40.
Only 0, 20, 40, 60, 80, and 100 are used.

Note that this is a class method, so only one logger can be used at any
given time.

To turn off logging, call the method again with undef.

=cut

sub set_logger {
    $logger = shift;
}

=head1 read_prop_file

Opens the given file, reads it, and returns a hash of the var=value pairs.
The config file may have blank lines or comments which start with a #
at the left margin.  For example:

    # This is a config file....

    base_dir=/some/path

=cut

sub read_prop_file {
    my $file = shift;
    my %config;

    open CONFIG, "$file" or return;

    _my_log("reading prop file: $file", 0);

    while (<CONFIG>) {
        next if (/^#/);
        next if (/^\s*$/);
        chomp;
        my ($var, $value) = split /\s*=\s*/;
        $config{$var}     = $value;
    }

    close CONFIG;

    return \%config;
}

=head1 update_prop_file

The method reads a properties file, updates its keys with new supplied
values (adding keys when necessary) and writes the result back to the
disk.

At present, it does not preserve comments or the order of the keys.

There are two parameters, both are required:

=over 4

=item NAME

The name of the properties file, it will be created if it does not exist.
This name should probably be an absolute path, though it could be relative
to the directory from which the script was launched.

=item NEW_PROPS

A hash reference with the keys you want to change or add and their new values.

=back

=cut

sub update_prop_file {
    my %args             = @_;
    my $name             = delete $args{NAME}
        or _my_croak "You didn't supply a NAME to update_prop_file";
    my $new_props        = delete $args{NEW_PROPS}
        or _my_croak "You didn't supply a NEW_PROPS to update_prop_file";

    _my_croak "Bad argument to update_prop_file: ", keys %args if (keys %args);

    my $old_props        = read_prop_file($name) || {};
    my %output_props     = ( %$old_props, %$new_props );

    open PROP_FILE, ">$name" or _my_croak "Couldn't write to $name $!\n";

    _my_log("writing updated prop file: $name", 0);

    foreach my $key (keys %output_props) {
        print PROP_FILE "$key=$output_props{$key}\n";
    }

    close PROP_FILE;
}

=head1 filter_file

The method reads a file one line at a time, filtering it according
to your rules before writing it out.

There are three parameters, two are required: INPUT and FILTERS.
OUTPUT is optional, if it is omitted, the result will overwrite the
INPUT.

Note Well: This function is line oriented.  It won't work on multi-line
patterns.  Suggestions for a more general approach are welcome.

=over 4

=item INPUT

The name of a file to filter.

=item FILTERS

A list of filtering functions.  The function receives one line at a time.
It should modify the received line (change $_[0]) if needed.  It is fine
to leave the parameter unchanged.

=item OUTPUT

The name of the filtered file.  If this is omitted, or is the same
as INPUT, the result will overwrite the original.  (A temporarly file
is used so that data is not lost.)

=back

=cut

sub filter_file {
    my %args    = @_;
    my $input   = delete $args{INPUT}
        or _my_croak "You didn't supply a INPUT to filter_file";
    my $filters = delete $args{FILTERS}
        or _my_croak "You didn't supply a FILTERS to filter_file";
    my $output  = delete $args{OUTPUT};

    my ($OUTPUT, $tmp_out) = tempfile();

    _my_croak "Bad argument to filter_file: ", keys %args if (keys %args);

    open INPUT, $input or _my_croak "Couldn't read $input $!\n";

    _my_log("filtering file: $input", 40);

    while (my $line = <INPUT>) {
        foreach my $filter (@$filters) {
            &$filter($line);
        }
        print $OUTPUT $line;
    }

    close $OUTPUT;
    close INPUT;

    if ($output and $output ne $input) {
        `mv $tmp_out $output`;
    }
    else {
        `mv $tmp_out $input`;
    }
}

=head1 build_file_list

This returns a list of files (in an array reference).

There are several arguments to build_file_list, only BASE_DIR is required.

Note that this function does not include directories in its lists.  If
this is a problem, someone should add an INCLUDE_DIRS parameter which
callers can give a true value to receive directories.  For now, directories
are omitted.

=over 4

=item BASE_DIR

A path where all the files in the set live.  If you need more than one
BASE_DIR, you can call the method again, then combine the resulting lists
as in:

    my $combined_list = [ @$list1, @$list2 ];

where $list1 and $list2 are lists you built with this method or by hand.

=item EXCLUDE_PATTERNS

This is a list of regular expressions which a file must not match.  If it
matches one of these, it is left out of the list.

=item EXCLUDE_DEFAULTS => 1,

If this argument is true, a standard set of patterns will be added to the
EXCLUDE_PATTERNS.  The default excluded patterns are the same ones Ant uses:

    Files ending with ~
    Files which begin and end with #
    Files which start with .#
    Files which begin and end with %
    Files with CVS as a path element
    Files called .cvsignore
    Files with SCCS as a path element
    Files called vssver.scc

At this time, there is no way to change this list without a code change
in Java::Build::Tasks.

=item INCLUDE_PATTERNS

This is a list of regular expressions to include in the archive.  Any file
not excluded by matching something in EXCLUDE_PATTERNS (or the default
excluded patterns) will be included, if it matches any of these patterns.

=item STRIP_BASE_DIR

If this argument is true, the BASE_DIR will be removed from each file name
before it goes into the result list.  This makes all file names relative
to BASE_DIR.

Defaults to false.

=item DOTTIFY_NAMES

If this argument is true, all slashes in the file name will be replaced
with dots.  I'm not sure this is useful, but it was easy to include.

Defaults to false.

=item QUOTE_DOLLARS

If this argument is true, all dollar signs in the file name will be replaced
with \$.  This helps, since functions like jar pass the names to the shell
which doesn't treat the dollars literally.

Defaults to false.

=back

=cut

my @default_excludes = (
    qr/~$/,
    qr/^#.*#$/,
    qr/\.#/,
    qr/^%.*%$/,
    qr(/CVS$|/CVS/|^CVS/|^CVS$),
    qr/\.cvsignore/,
    qr(/SCCS$|/SCCS/|^SCCS/|^SCCS$),
    qr/vssver\.scc/,
);

sub build_file_list {
    my %args             = @_;
    my $base_dir         = delete $args{BASE_DIR}
        or _my_croak "You didn't supply a BASE_DIR to build_file_list";
    my $exclude_patterns = delete $args{EXCLUDE_PATTERNS};
    my $include_patterns = delete $args{INCLUDE_PATTERNS};
    my $exclude_defaults = delete $args{EXCLUDE_DEFAULTS};
    my $strip_base_dir   = delete $args{STRIP_BASE_DIR} || 0;
    my $dottify_names    = delete $args{DOTTIFY_NAMES}  || 0;
    my $quote_dollars    = delete $args{QUOTE_DOLLARS}  || 0;

    _my_croak "Bad argument to build_file_list: ", keys %args if (keys %args);
    _my_croak "$base_dir is not a directory" unless (-d $base_dir);

    if ($strip_base_dir and $base_dir =~ m!/$!) {
        _my_carp("You asked for STRIP_BASE_DIR, your BASE_DIR ends in /");
        _my_carp("I removed the trailing slash.");
        $base_dir =~ s!/$!!;
    }

    my @result_list;

    my $excluded_by_default = _gen_filter(\@default_excludes);
    my $excluded_by_pattern = _gen_filter($exclude_patterns);
    my $included_by_pattern = _gen_filter($include_patterns);

    my $wanted_function = sub {
        my $file = $File::Find::name;
        return if ($strip_base_dir and $file eq $base_dir);
        $file    =~ s!$base_dir/!! if ($strip_base_dir);

        return if ($exclude_defaults and &$excluded_by_default($file));
        return if &$excluded_by_pattern($file);
        if ($include_patterns) {
            return unless (&$included_by_pattern($file));
        }
        $file    =~ s!/!.!go        if ($dottify_names);
        $file    =~ s!\$!\$!g       if ($quote_dollars);
#        push @result_list, $file;
        push @result_list, $file unless (-d $File::Find::name);
    };

    find({ wanted => $wanted_function, no_chdir => 1 }, $base_dir);

    return \@result_list;
}

# _gen_filter returns a sub.  The sub is a noop when the first argument
# to _gen_filter is undefined.  This makes it safe to use the _gen_filter
# sub even if you don't validate the rules list in the calling code.
# If _gen_filter's first argument is defined, it must be a reference to an
# array of rules.  The generated function takes a file name.  It returns 1
# if the name matches any rule or 0 otherwise.
sub _gen_filter {
    my $rules = shift;

    return sub {} unless ($rules);

    return sub {
        my $file = shift;

        foreach my $rule (@$rules) {
            return 1 if ($file =~ $rule);
        }
        return 0;
    };
}

=head1 make_jar_classpath

This function makes a valid class path of all the jars in the supplied
list of directories.  It has two parameters.  DIRS is the list of directories
in which to look for jars, it is required.  INCLUDE_PATTERNS works
like it does in build_file_list.  Give an anonymous array of regexes.
By default this list is just [ qr/.jar$/ ].  You might need to set it
to [ qr/.jar$/, qr/.ZIP$/ ].

=cut

sub make_jar_classpath{
    my %args = @_;
    my $dirs = delete $args{DIRS}
        or _my_croak "You didn't supply a DIRS to make_jar_classpath";
    my $include_patterns = delete $args{INCLUDE_PATTERNS} || [ qr/jar$/ ];

    _my_croak "Bad argument to make_jar_classpath: ", keys %args
        if (keys %args);

    my @path_pieces;
    foreach my $dir (@$dirs) {
        my $jars = build_file_list(
            BASE_DIR         => $dir,
            INCLUDE_PATTERNS => $include_patterns,
        );
        my $piece = join ":", @$jars;
        push @path_pieces, $piece;
    }
    return join ":", @path_pieces;
}

=head1 what_needs_compiling

This method takes a list of source files and returns a new list which
includes source files only if they are newer than their compiled forms
(or if their compiled form is absent).

There are four paramters to this method, only SOURCE_FILE_LIST is required.

=over 4

=item SOURCE_FILE_LIST

An array reference storing paths to source code files.  If SOURCE_DIR is
omitted, paths must be absolute or they will be relative the starting
directory of the script.

=item SOURCE_DIR

A path to add to each name in the SOURCE_FILE_LIST (i.e. a parent directory
for all of the source files).

=item DEST_DIR

A path to use in place of SOURCE_DIR for compiled files (i.e. a parent
directory for all the compiled files).

=item SOURCE_TO_COMPILIED_NAME

A code reference.  The function must take a source file name and return
its compiled name.  A good choice might be:

    sub {
        my $file = shift;
        $file    =~ s/\.java/.class/;
        return $file;
    }

In fact, this is the default.  What a lucky coincidence.  If your source
and compiled files live under different base directories, it may be
convenient to leave out SOURCE_DIR and DEST_DIR, using a method to
perform the conversion from one to the other.

=back

If you have suggestions for the interface to this method, send them in.
It still doesn't feel right to me.

=cut

sub what_needs_compiling {
    my %defaults = (SOURCE_TO_COMPILIED_NAME => \&_source_to_compilied_name);
    my %args     = (%defaults, @_);

    my $source_file_list         = delete $args{SOURCE_FILE_LIST}
        or _my_croak
            "You didn't supply a SOURCE_FILE_LIST to what_needs_compiling";
    my $source_dir               = delete $args{SOURCE_DIR};
    my $dest_dir                 = delete $args{DEST_DIR};
    my $source_to_compilied_name = delete $args{SOURCE_TO_COMPILIED_NAME};

    _my_croak "Bad argument to what_needs_compiling: ", keys %args
        if (keys %args);

    $source_dir .= "/" if defined $source_dir;
    $dest_dir   .= "/" if defined $dest_dir  ;

    my @result_list;
    foreach my $source_file (@$source_file_list) {
        my $compiled_file = &$source_to_compilied_name($source_file);
        no warnings;  # dest_dir and source_dir could be undef
        if ( not -f "$dest_dir$compiled_file"
                    or
             -M "$dest_dir$compiled_file" > -M "$source_dir$source_file"
        ) {
            push @result_list, $source_file;
        }
    }
    return \@result_list;
}

sub _source_to_compilied_name {
    my $file = shift;
    $file    =~ s/\.java/.class/;
    return $file;
}

=head1 jar

jar uses the Sun supplied jar tool to package a list of files.  You may want
to construct the list by calling build_file_list above, but you may
produce it in any way you like.  The names in the list should be relative
to the BASE_DIR of the jar.

There are five arguments to jar, JAR_FILE, BASE_DIR and FILE_SET are required.
MANIFEST and APPEND are optional.

=over 4

=item JAR_FILE

The name of the destination file.

=item FILE_LIST

A list of files to put in the jar.

=item BASE_DIR

A directory to move to before issuing the jar command.  This might be
the same BASE_DIR you used to build the file list.

=item MANIFEST

The name of the manifest file to put in the jar.  If you omit this, jar
will do its default thing.  See the docs for jar to know what that default
thing is, and what to put in your MANIFEST if you choose to supply one.

=item APPEND

If this is true, files will be added to an existing jar.  Bad things will
happen if the file does not exist.

Defaults to false.

=back

=cut

sub jar {
    my %args = @_;

    my $jar_file  = delete $args{JAR_FILE}
        or _my_croak "You didn't supply a JAR_FILE to jar";
    my $file_list = delete $args{FILE_LIST}
        or _my_croak "You didn't supply a FILE_LIST to jar";
    my $manifest  = delete $args{MANIFEST};
    my $base_dir  = delete $args{BASE_DIR};
    my $append    = delete $args{APPEND};

    _my_croak "Bad argument to jar: ", keys %args if (keys %args);

    _my_croak "Nothing to jar" unless (@$file_list > 0);

    my $operation = "c";
    $operation    = "u" if $append;

    my @quoted_list = map { "'$_'" } @$file_list;

    local $" = " ";  # in case the caller has messed with it
    my $current_dir = cwd();
    chdir $base_dir if $base_dir;
    my $jar_out;
    _my_log("jar includes: @quoted_list", 0);
    if (defined $manifest and $manifest) {
        _my_log("jarring $operation: $jar_file with $manifest", 40);

        $jar_out =
            `jar ${operation}fm '$jar_file' '$manifest' @quoted_list 2>&1`;
    }
    else {
        _my_log("jarring $operation: $jar_file", 40);

        $jar_out = `jar ${operation}f '$jar_file' @quoted_list 2>&1`;
    }
    chdir $current_dir if $base_dir;
    _my_croak($jar_out) if ($?);
    _my_log("jar out: $jar_out", 20) if ($jar_out);
}

=head1 ear

The only difference between a jar and a WebSphere ear is the application.xml
which must be in META-INF/application.xml.  This is a convenience routine
for making these.

There are four parameters to ear.  All are required.

=over 4

=item EAR_FILE

The name of the output file.

=item FILE_LIST

The regular files to put in the ear.

=item BASE_DIR

The parent directory of the regular files.

=item XML_BASE_DIR

The parent directory of META-INF/application.xml.

=back

=cut

sub ear {
    my %args         = @_;
    my $ear_file     = delete $args{EAR_FILE}
        or _my_croak "You didn't supply an ear file name to ear";
    my $file_list    = delete $args{FILE_LIST}
        or _my_croak "You didn't supply a FILE_LIST to ear";
    my $base_dir     = delete $args{BASE_DIR}
        or _my_croak "You didn't supply a BASE_DIR to ear";
    my $xml_base_dir = delete $args{XML_BASE_DIR}
        or _my_croak "You didn't supply a XML_BASE_DIR to ear";

    _my_croak "Bad argument to ear: ", keys %args if (keys %args);

    jar(
        JAR_FILE  => $ear_file,
        FILE_LIST => $file_list,
        BASE_DIR  => $base_dir,
    );

    jar(
        JAR_FILE  => $ear_file,
        FILE_LIST => [ "META-INF/application.xml" ],
        BASE_DIR  => $xml_base_dir,
        APPEND    => 1,
    );
}

=head1 signjar

There are four named attributes to signjar.  JAR_FILE and ALIAS are
required KEYSTORE and STOREPASS are not (but if you use KEYSTORE,
you must use STOREPASS or unexpected bad things may happen).

=over 4

=item JAR_FILE

The name of the jar file to be signed.

=item ALIAS

The alias under which the JAR_FILE will be signed.

=item KEYSTORE

The location of your key store file.  The default is to leave out this
parameter when calling jarsigner.  See its documentation for where the
default location is.

=item STOREPASS

The password which locks your keystore.

=back

=cut

sub signjar {
    my %args = @_;

    my $jar_file  = delete $args{JAR_FILE}
        or _my_croak "You didn't supply a JAR_FILE to signjar";
    my $alias     = delete $args{ALIAS}
        or _my_croak "You didn't supply an ALIAS to signjar";
    my $storepass = delete $args{STOREPASS};
    my $keystore  = delete $args{KEYSTORE};

    _my_croak "Bad argument to signjar: ", keys %args if (keys %args);

    my $com_out;
    if ($keystore) {
        _my_log("signing jar: $jar_file",     40);
        _my_log(
            "sign parms: alias = $alias; "
          . " -keystore '$keystore' -storepass $storepass",
            0
        );

        my $command = "jarsigner -keystore '$keystore' -storepass $storepass "
                    . "'$jar_file' $alias";
        $com_out = `$command 2>&1`;
    }
    else {
        _my_log("signing jar: $jar_file alias: $alias", 40);
        $com_out = `jarsigner '$jar_file' $alias 2>&1`;
    }
    _my_croak($com_out) if ($?);
    _my_log("jarsigner out: $com_out", 20) if ($com_out);
}

# Edit history
# 0.01 Initial release
# 0.02 Changed jar and jarsigner so they only log command output when there
#      is output from the command.  This reduces log clutter.
# 0.02 Changed jar and jar signer so they die when their commands fail.
# 0.02 Changed jar so that it goes back to the proper directory before
#      calling _my_croak.  Not doing that caused problems for people who
#      trap the fatal error.
# 0.03 Make read_prop_file use a bare return if it can't read the file.
#      This prevents annoying logging in update_prop_file.
# 0.03 Made it fatal to supply a BASE_DIR parameter to build_file_list which
#      is not an existing directory name.
# 0.03 Added an optional INCLUDE_PATTERNS parameter to make_jar_classpath.
# 0.04 Changed copy_file so it uses the same space quoting scheme as jar.

1;
