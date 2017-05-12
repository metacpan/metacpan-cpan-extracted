=head1 NAME

File::OSS::Scan - Scan the repository of project and detect any OSS ( Open Source Software ) files

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use File::OSS::Scan qw(:scan);

    scan_init( 'verbose' => 0, 'inflate' => 1 );

    scan_execute($proj_dir);
    my $ret = scan_result();

=head1 DESCRIPTION

This module allows you to scan your project directory based on a set of pre-defined
but also customizable rules, to detect all the used source files that originate from
OSS ( or commercial software ). Unlike some of those commercial solutions for the OSS
management, here we don't have to maintain a OSS code database, it means that we will
not conduct code snippet match, and completely rely on the pattern match ( looking for
a particular type of file, eg COPYING, LICENSE, or the existence of specific strings in
file content, eg Copyright, LGPL License etc ).

=head1 ATTRIBUTES

C<scan_init()> takes a set of options. These options will be printed out to the C<STDOUT>
if it runs in the I<CHATTY> mode ( C<'verbose' =E<gt> 2> ).

=over 4

=item C<ruleset_config>

used to specify the path of your own config file for L<File::OSS::Scan::Ruleset>, where
you can write up your own rules for OSS detection. If not specified, then it will try to
check the value of C<$ENV{OSSSCAN_CONFIG}> and C<./.ossscan.rc>, if still can not find a
valid configuration file in all of the above places, then it will default to use the
embedded rules contained in the C<__DATA__> section of L<File::OSS::Scan::Ruleset>.

=item C<verbose>

C<[0|1|2]>. set your I<Verbosity> level, 0 is silent and 2 is verbose, 1 is well. It
defaults to 1 if not specified, and only ouput messages about detected matches.

=item C<cache>

C<[0|1|2]>. set your I<Cache> mode, 0 is no cache, 1 is to use cache, 2 is to refresh cache.
It defaults to 0 if not specified, and will not enable the cache feature. if set this option
to 1, it checks every file against the records in the cache to see if the file has been
changed recently, if there is no change since the last run of scanning, then this file will
be skipped. if set to 2, it will not check the change on files and hence process each one of
them, also forces the refresh of cache records for every files.

=item C<inflate>

C<[0|1]>. This option is used to indicate whether we want to inflate a compressed or archived
files and scan those extracted content. It defaults to 0 if not specified. Supported file
types include: I<.jar>, I<.tar>, I<.gz>, I<.zip>, I<.Z>.

=item C<working_dir>

used to specify the working directory for file inflating. if not specified, it defaults to
use ( create one if not existed ) the dir named I<.working> under the current directory where
the program is running. B<Careful!>, C<scan_init()> will empty this dir everytime it is called
by using a C<rm -rf> command. so one should be very cautious to any value assigned to this
option, make sure that it doesn't clash with any existing dirs where you have important data
stored.

=item C<strings>

path of the cmd I<strings>. If not specified, it defaults to C</bin/strings>. If can not find
an executable I<strings> command, then it will skip any binary files encountered.

=item C<jar>

path of the cmd I<jar>. If not specified, it defaults to C</bin/jar>. If can not find an
executable I<jar> command, then it will skip any I<.jar> files encountered.

=item C<tar>

path of the cmd I<tar>. If not specified, it defaults to C</bin/tar>. If can not find an
executable I<tar> command, then it will skip any I<.tar> files encountered.

=item C<gunzip>

path of the cmd I<gunzip>. If not specified, it defaults to C</bin/gunzip>. If can not find an
executable I<gunzip> command, then it will skip any I<.gz> files encountered.

=item C<unzip>

path of the cmd I<unzip>. If not specified, it defaults to C</bin/unzip>. If can not find an
executable I<unzip> command, then it will skip any I<.zip> files encountered.


=item C<uncompress>

path of the cmd I<uncompress>. If not specified, it defaults to C</bin/uncompress>. If can not
find an executable I<uncompress> command, then it will skip any I<.Z> files encountered.

=back

=head1 METHODS

=head2 C<scan_init(%params)>

    use File::OSS::Scan qw( :scan );

    scan_init(
        'verbose' => 2,     # chatty output
        'inflate' => 1,     # inflate archived files
        'cache'   => 1      # enable cache
    );

Do the necessary initialization works required prior to running the scan, including availability
checks on needed commands, initialize the working directory and initiate a L<File::OSS::Scan::Ruleset>
and a L<File::OSS::Scan::Matches> instance. Accepted parameters are described in details in
L</"ATTRIBUTES"> section.

=head2 C<scan_execute($proj_dir)>

    use File::OSS::Scan qw( :scan );

    scan_init();    # we are fine with defaults
    scan_execute($proj_dir);

Do the actual scanning on the given project directory and any detected OSS files will be recorded
in the instance of L<File::OSS::Scan::Matches> and can be fetched via method C<scan_result()> later.
The only parameter required here is the C<$proj_dir>, which is used to tell the module which project
directory you want to scan.

=head2 C<scan_result($format)>

    use File::OSS::Scan qw( :scan );

    scan_init();    # we are fine with defaults
    scan_execute($proj_dir);

    my $ret_hash = scan_result();
    my $ret_text = scan_result('txt');
    my $ret_html = scan_result('html');
    my $ret_json = scan_result('json');

Get all the detected matches on files within the project directory. Parameter $format can be one of
the I<txt> - plain text, I<html> - formatted HTML tables or I<json> - JSON string. If not specified,
then it will return the raw data hash.

=head2 C<clear_cache()>

    use File::OSS::Scan qw( :all );

    clear_cache();

Clean all cached results from file system.

=head1 SCAN RULES

Scan rules can be configured in the config file specified via param C<ruleset_config>, or in the file
I<.ossscan.rc> under the current directory where the program is running. If neither of them exists,
then as a last resort, it will read the C<__DATA__> section of the module L<File::OSS::Scan::Ruleset>.
Currently it supports the following types of rules, If you are not sure about how to compose it, then
the best approach is to refer to the C<__DATA__> section of the module L<File::OSS::Scan::Ruleset>.

=head2 C<[SECTION]>

    # section for file check
    [FILE]
        ...

    # section for line check
    [LINE]
        ...

This is used to declare section of rules that all following rules are belong to. Valid sections contain
C<GLOBAL>, C<DIRECTORY>, C<FILE> and C<LINE>.

=head2 C<filename_match>

    100% filename_match COPYING\.\w+
    50%  filename_match AUTHOR[S]?

Detect OSS file based on the filename check. The first element is the I<Certainty Level>, ranging from 0(%)
to 100 (%). The second element is the function name which will be called to process this rule. The
rest part is a pattern(regex) used for searching.

=head2 C<content_match>

    100% content_match MIT\W*Licen[cs]e
    100% content_match Artistic\W*Licen[cs]e

Detect OSS file by checking if the file's content matches some of the license strings. The first
element is the I<Certainty Level>, ranging from 0(%) to 100 (%). The second element is the function
name which will be called to process this rule. The rest part is a pattern(regex) used for searching.

=head2 C<copyright_match>

    50%  copyright_match MY_COMPANY MyCompany

Detect OSS file by checking if there is a copryright declaration statement in the file. The first
element is the I<Certainty Level>, ranging from 0(%) to 100 (%). The second element is the function
name which will be called to process this rule. The rest part is a list of names to be excluded, usually
we specify our own company's name here, so when we found a copyright statement like:

    Copyright (C) 1998 - 2012, MyCompany, <xxx@xxx>

we will know that these are proprietary codes and should be excluded from the detected matches.

=head2 C<exclude_dir>

    exclude_dir: data

This is a global setting, so should be defined under the section C<GLOBAL> or in the very begining of the
configuration file. It accepts a list of directory names and these directories will be skipped during the
scanning.

=head2 C<exclude_file>

    exclude_file: Makefile Build\.PL

This is a global setting, so should be defined under the section C<GLOBAL> or in the very begining of the
configuration file. It accepts a list of file names ( or pattern ) and these files will be skipped during
the scanning.

=head2 C<exclude_extension>

    exclude_extension: png jpg gif pdf doc docx html htm xml json xls

This is a global setting, so should be defined under the section C<GLOBAL> or in the very begining of the
configuration file. It accepts a list of file extension names and files with the listed extensions will be
skipped during the scanning.

=head1 SEE ALSO

=over 4

=item * L<File::OSS::Scan::Ruleset>

=item * L<File::OSS::Scan::Matches>

=item * L<File::OSS::Scan::Cache>

=item * L<File::OSS::Scan::Constant>

=back

=head1 AUTHOR

Harry Wang <harry.wang@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Harry Wang.

This is free software, licensed under:

    Artistic License 1.0

=cut

package File::OSS::Scan;

use strict;
use warnings FATAL => 'all';

use Fatal qw( open close );
use Carp;
use English qw( -no_match_vars );
use Data::Dumper; # for debug
use Cwd;
use File::Copy;
use File::Basename;

use File::OSS::Scan::Constant qw(:all);
use File::OSS::Scan::Ruleset;
use File::OSS::Scan::Matches;
use File::OSS::Scan::Cache;

our $VERSION = '0.04';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(scan_init scan_execute scan_result clear_cache);

our %EXPORT_TAGS = (
            all => \@EXPORT_OK,
            scan => [ @EXPORT_OK[0..2] ],
        );

my $curr_dir;
my $recur_depth;
my $scan_base = '';
my $anchor_file;

our $cmd_strings;
our $cmd_jar;
our $cmd_tar;
our $cmd_gunzip;
our $cmd_unzip;
our $cmd_uncompress;

my $ruleset = undef;
my $setting = undef;
my $result  = undef;

# list all valid options with their default values
my %valid_options = (
    ruleset_config  => undef,
    verbose         => VERBOSE_NORMAL,
    cache           => CACHE_NONE,
    strings         => '/bin/strings',
    jar             => '/bin/jar',
    tar             => '/bin/tar',
    gunzip          => '/bin/gunzip',
    unzip           => '/bin/unzip',
    uncompress      => '/bin/uncompress',
    working_dir     => getcwd() . "\/\.working",
    inflate         => UNI_FALSE,
);

my $options = undef;
my $user = getlogin() || ( getpwuid $< )[0];

sub scan_init {
    my %params = ( scalar(@_) != 1 ) ? @_ : ( 'ruleset_config' => $_[0] );

    # convert hash keys to lower case
    %params = map { lc $_ => $params{$_} } keys %params;

    # clear previously set options
    undef $options;

    # set options
    foreach my $opt ( keys %valid_options ) {
        $options->{$opt} = defined $params{$opt} ?
        $params{$opt} : $valid_options{$opt};
    }

    croak "invalid option verbose: $options->{'verbose'}"
    if ( ( $options->{'verbose'} !~ /^\d$/ ) ||
         ( $options->{'verbose'} < VERBOSE_SILIENT ) ||
         ( $options->{'verbose'} > VERBOSE_CHATTY ) );

    croak "invalid option cache: $options->{'cache'}"
    if ( ( $options->{'cache'} !~ /^\d$/ ) ||
         ( $options->{'cache'} < CACHE_NONE ) ||
         ( $options->{'cache'} > CACHE_REFRESH ) );

    croak "working directory $options->{'working_dir'} doesn't exist or not writable"
    if ( ! ( ( -d $options->{'working_dir'} and
                -w $options->{'working_dir'} ) ||
                    mkdir( $options->{'working_dir'}, 0755 ) ) );

    # empty the working directory,
    # should be very very cautious with the param working_dir ...
    system("rm -rf $options->{'working_dir'}/*");

    # make sure the tools are available
    foreach ( qw/strings jar tar gunzip unzip uncompress/ ) {
        no strict 'refs';

        my $cmd_var = __PACKAGE__ . '::cmd_' . $_;
        $$cmd_var = $options->{$_};

        if ( ! -x $$cmd_var ) {
            carp "unable to execute the $_ binary $$cmd_var";
            undef $$cmd_var;
        }
    }

    my $config_file = $options->{'ruleset_config'};

    # clear previously set rulesets
    undef $ruleset;

    # clear previous settings
    undef $setting;

    # initiate an Ruleset object with the rules
    # fetched from the config file.
    File::OSS::Scan::Ruleset->init($config_file);

    # set rulesets
    $ruleset = File::OSS::Scan::Ruleset->get_ruleset();

    $setting = $ruleset->{'GLOBAL'};

    # initialize Matches object to store the result.
    File::OSS::Scan::Matches->init();

    return SUCCESS;
}

sub scan_execute {
    my $base_dir = shift || return SUCCESS;

    # if we have fetched the ruleset config ?
    croak __PACKAGE__ . " is not properly initialized."
        if ( ! defined $ruleset );

    # reset scan result
    undef $result;

    # reset recursion depth
    $recur_depth = 0;

    # store the top level directory where the scan begins
    $scan_base = $base_dir;

    # get current directory
    $curr_dir = getcwd();

    # be nice to your users
    greeting()
    if ( $options->{'verbose'} != VERBOSE_SILIENT );

    # initiate a cache object
    File::OSS::Scan::Cache->init($base_dir)
    if ( $options->{'cache'} != CACHE_NONE );

    File::OSS::Scan::Cache->clear()
    if ( $options->{'cache'} == CACHE_REFRESH );

    # call scan_dir to recursivly scan for all files and
    # directories under the given base dir.
    scan_dir($base_dir);

    return SUCCESS;
}

sub scan_result {
    return
        File::OSS::Scan::Matches->get_matches($_[0]);
}

sub clear_cache {
    return
        File::OSS::Scan::Cache->clear_all();
}

sub scan_dir {
    my $base_dir = shift || return SUCCESS;

    my $exclude_dirs = $setting->{'exclude_dir'};

    foreach my $exclude_dir ( @$exclude_dirs ) {
        if ( $base_dir =~ /$exclude_dir/ ) {
            printing("exclude directory pattern $exclude_dir, skipping directory $base_dir")
                if ( $options->{'verbose'} == VERBOSE_CHATTY );

            $recur_depth--;
            return SKIP;
        }
    }

    my $leading_fmt = "--> " x $recur_depth;

    if ( $options->{'verbose'} == VERBOSE_CHATTY ) {
        $base_dir =~ /^$scan_base\/(.*)$/;
        my $short_base_dir = $1 || '';

        if ( not $short_base_dir ) {
            $base_dir =~ /^$options->{'working_dir'}\/(.*)$/;
            $short_base_dir = $1 || '';
        }
        printing("entering directory: ./$short_base_dir");
    }

    local *DIR;
    opendir(DIR, $base_dir) ||
        croak "could not open directory $base_dir, $!";

    my @items = sort grep { $_ !~ m{^\.} } readdir DIR;
    closedir(DIR);

    my ( @subfiles, @subdirs );
    map {
            ( -f "$base_dir/$_" ) ?
                ( push @subfiles, $_ ) :
                ( push @subdirs, $_ )
        } @items;

    # check for each files
    foreach my $file ( @subfiles ) {
        my $file_path = $base_dir . "/" . $file;

        my ( $size, $mtime )  = (stat($file_path))[7,9];
        my $mtime_stamp = localtime($mtime);

        printf(  " " x 10 . $leading_fmt . "%-" . WIDTH_FILENAME . "s " .
                "%-" . WIDTH_SIZE . "s " .
                "%-" . WIDTH_MTIME . "s\n",
                    $file, $size, $mtime_stamp)
            if ( $options->{'verbose'} == VERBOSE_CHATTY );

        my $h_file = {
            'name'  => $file,
            'path'  => $file_path,
            'size'  => $size,
            'mtime' => $mtime,
        };

        my $skip_flag = UNI_FALSE;
        if ( $options->{'cache'} == CACHE_USE ) {
            my $cached_file = File::OSS::Scan::Cache->get($file_path);

            if ( defined $cached_file ) {

                my $c_size  = $cached_file->{'size'};
                my $c_mtime = $cached_file->{'mtime'};

                if ( ( $size eq $c_size ) &&
                     ( $mtime eq $c_mtime ) ) {

                    printing("file $file_path has not been changed since the last scan, skipping ...")
                    if ( $options->{'verbose'} == VERBOSE_CHATTY );

                    $skip_flag = UNI_TRUE;
                }
            }

        }

        File::OSS::Scan::Cache->set( $file_path => $h_file )
        if ( ! $skip_flag and
                ( $options->{'verbose'} != CACHE_NONE ) );

        check_file($h_file)
            if not $skip_flag;
    }

    # check for each subdirs
    foreach my $dir ( @subdirs ) {
        my $new_dir = $base_dir . "/" . $dir;
        $recur_depth++;
        scan_dir($new_dir);
    }

    $recur_depth--;

    return SUCCESS;

}

sub greeting {
    my $bar_fmt = "#" x WIDTH_BAR . "\n";
    print $bar_fmt . "#\n";

    my $winfo_leading_fmt = "#" . " " x 4;

    print $winfo_leading_fmt . __PACKAGE__ . " v$VERSION\n";
    print $winfo_leading_fmt . "\n";

    printf(  $winfo_leading_fmt . "%-" . WIDTH_INFO_KEY . "s " .
        "%-" . WIDTH_INFO_VAL . "s\n", "[User]:", $user );
    printf(  $winfo_leading_fmt . "%-" . WIDTH_INFO_KEY . "s " .
        "%-" . WIDTH_INFO_VAL . "s\n", "[Current Directory]:", $curr_dir );
    printf(  $winfo_leading_fmt . "%-" . WIDTH_INFO_KEY . "s " .
        "%-" . WIDTH_INFO_VAL . "s\n", "[Scanning Directory]:", $scan_base );

    print $winfo_leading_fmt . "\n";
    print $winfo_leading_fmt . "-" x WIDTH_INFO_KEY . "\n";
    print $winfo_leading_fmt . "\n";

    print $winfo_leading_fmt . "[Options]:\n";
    print $winfo_leading_fmt . "\n";

    foreach my $opt ( keys %$options ) {
        printf(  $winfo_leading_fmt . "%-" . WIDTH_INFO_KEY . "s " .
        "%-" . WIDTH_INFO_VAL . "s\n", "$opt",
            defined $options->{$opt} ? $options->{$opt} : 'UNDEF' );
    }

    print "#\n" . $bar_fmt;
}

sub printing {
    my $msg = shift || return SUCCESS;

    my ( $sec, $min, $hr, $day, $mon, $yr ) = localtime();
    my $timestamp = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $yr + 1900,
        $mon + 1, $day, $hr, $min, $sec;

    print "$timestamp $msg\n";
    return SUCCESS;
}

sub check_file {
    my $h_file = shift || return SUCCESS;

    my $rules = $ruleset->{'FILE'}
        || return SUCCESS;

    my $exclude = $setting->{'exclude_extension'};
    my $file_ext = ( $h_file->{'name'} =~ /\.([^.]+)$/ ) ? $1 : '';
    my $binary = UNI_FALSE;

    if ( $file_ext ne '') {

        if ( grep(/^\Q$file_ext\E$/i, @$exclude) ) {
            printing("exclude extension $file_ext, skipping file $h_file->{'path'}")
                if ( $options->{'verbose'} == VERBOSE_CHATTY );

            return SKIP;
        }
    }

    my $exclude_files = $setting->{'exclude_file'};
    foreach my $exclude_file ( @$exclude_files ) {
        if ( $h_file->{'name'} =~ /\Q$exclude_file\E/ ) {
            printing("exclude file pattern $exclude_file, skipping file $h_file->{'path'}")
                if ( $options->{'verbose'} == VERBOSE_CHATTY );

            return SKIP;
        }
    }

    if ( -f $h_file->{'path'} and ! -s $h_file->{'path'} ) {
        printing("encountered an empty file $h_file->{'path'}, skipping ...")
            if ( $options->{'verbose'} == VERBOSE_CHATTY );

        return SKIP;
    }

    if ( -B $h_file->{'path'} ) {
        printing("encountered a binary file $h_file->{'path'}")
            if ( $options->{'verbose'} == VERBOSE_CHATTY );

        $binary = UNI_TRUE;
    }

    foreach my $rule ( @$rules ) {
        my ( $func, $cert, $args )
            = @$rule{qw/func cert args/};

        {
            no strict 'refs';
            my $msg = $func->( $h_file, $cert, $args );

            if ( $msg ) {
                if ( defined $anchor_file and
                    $anchor_file =~ /^(.*)\.[^.]*$/ ) {

                    my $anchor = $1;

                    my $path = ( $h_file->{'path'} =~
                        /^$options->{'working_dir'}\/(.*)$/ ) ?
                    $1 : '';

                    $path = $anchor . "/inflated_dir/" . $path;
                    File::OSS::Scan::Matches->add(
                        {
                            'name'  => $h_file->{'name'},
                            'path'  => $path,
                            'size'  => $h_file->{'size'},
                            'mtime' => $h_file->{'mtime'},
                        },
                        $func, $cert, join(' ', @$args), $msg
                    );
                }
                else {
                    File::OSS::Scan::Matches
                    ->add( $h_file, $func, $cert, join(' ', @$args), $msg);
                }
            }
        }
    }

    if ( $binary and
            ( $file_ext eq 'jar' or
              $file_ext eq 'gz' or
              $file_ext eq 'zip' or
              $file_ext eq 'Z' or
              $file_ext eq 'tar'
            )
        ) {

        if ( not $options->{'inflate'} ) {
            printing("inflate option is not set, skipping file $h_file->{'path'}")
                if ( $options->{'verbose'} == VERBOSE_CHATTY );

            return SKIP;
        }

        my ( $cmd, $cmd_str );
        my $ext_cmd_map = {
            'jar' => [ 'jar', 'xvf' ],
            'gz'  => [ 'gunzip', undef ],
            'zip' => [ 'unzip', undef ],
            'Z'   => [ 'uncompress', undef ],
            'tar' => [ 'tar', 'xvf' ],
        };

        {
            no strict 'refs';
            $cmd = ${__PACKAGE__ . '::cmd_' .
                    $ext_cmd_map->{$file_ext}->[0]};
        }

        if ( not defined $cmd ) {
            printing("can't find the executable to process file $h_file->{'path'}, skipping ...")
            if ( $options->{'verbose'} == VERBOSE_CHATTY );

            return SKIP;
        }

        $cmd_str = "$cmd" .
                    ( defined $ext_cmd_map->{$file_ext}->[1] ?
                        " \-$ext_cmd_map->{$file_ext}->[1] " : ' ' );

        printing("try using $cmd to process file $h_file->{'path'}")
            if ( $options->{'verbose'} == VERBOSE_CHATTY );

        my $inflate_file        = undef;
        my $inflate_dir         = undef;
        my $curr_inflate_dir    = undef;

        if ( $h_file->{'path'} =~ /^$scan_base/ ) {
            $inflate_file = $options->{'working_dir'} .
                            "\/$h_file->{'name'}";

            copy($h_file->{'path'}, $inflate_file)
                or croak "Can't copy file to $inflate_file : $!";

            chdir($options->{'working_dir'});
            $anchor_file = $h_file->{'path'};
        }
        else {
            $inflate_file = $h_file->{'path'};
            my ( $file_name, $dir_name ) =
                (
                    fileparse($inflate_file,
                        qr/\.[^.]*/)
                )[0,1];

            $inflate_dir = $dir_name . "inflating_$file_name";
            $curr_inflate_dir = $dir_name;

            mkdir( $inflate_dir, 0755 );

            move($h_file->{'path'},
                $inflate_dir . "/$h_file->{'name'}");

            $inflate_file = $inflate_dir . "/$h_file->{'name'}";

            chdir($inflate_dir);
        }

        if ( -f $inflate_file and -r $inflate_file ) {

            printing("execute command ${cmd_str}${inflate_file}")
            if ( $options->{'verbose'} != VERBOSE_SILIENT );

            foreach (`${cmd_str}${inflate_file}`) {
                chomp;
                print ' ' x 10 . "$_\n"
                    if ( $options->{'verbose'} == VERBOSE_CHATTY );
            }

            unlink $inflate_file
                || carp "can't unlink file $inflate_file : $!";

            # reset the recursion depth counter and restore it
            # after finishing the scan for files in working direcotry.
            if ( $h_file->{'path'} =~ /^$scan_base/ ) {

                printing("changing to directory: $options->{'working_dir'}")
                if ( $options->{'verbose'} != VERBOSE_SILIENT );

                my $curr_recur_depth = $recur_depth;
                $recur_depth = 0;
                scan_dir($options->{'working_dir'});
                $recur_depth = $curr_recur_depth;

                chdir($curr_dir);
                system("rm -rf $options->{'working_dir'}/*");

                printing("changing to directory: $curr_dir")
                if ( $options->{'verbose'} != VERBOSE_SILIENT );

                undef $anchor_file;
            }
            else {
                $recur_depth++;
                scan_dir($inflate_dir);

                chdir($curr_inflate_dir);
                system("rm -rf $inflate_dir/*");
            }

        }

        return SUCCESS;
    }

    if ( $ruleset->{'LINE'} ) {
        check_line($h_file, $binary);
    }

    return SUCCESS;
}

sub check_line {
    my $h_file = shift || return SUCCESS;
    my $binary = shift;

    my $rules = $ruleset->{'LINE'}
        || return SUCCESS;

    my $fname = $h_file->{'name'};
    my $fpath = $h_file->{'path'};

    local *FILE;

    if ( not $binary ) {
        open FILE, $fpath ||
            croak "could not open file $fpath, $!";
    }
    else {
        open FILE, "-|", "$cmd_strings $fpath" ||
            croak "could not get content from $fpath by using $cmd_strings, $!";

        printing("try using $cmd_strings on the file $h_file->{'path'}")
            if ( $options->{'verbose'} == VERBOSE_CHATTY );
    }

    my $line_no = 0;
    LINE: while(<FILE>) {
        chomp;
        my $line = $_;
        $line_no++;

        RULE: foreach my $rule ( @$rules ) {
            my ( $func, $cert, $args )
            = @$rule{qw/func cert args/};

            {
                no strict 'refs';
                my $msg = $func->( $h_file, $cert, $args, $line, $line_no );

                if ($msg) {

                    if ( defined $anchor_file and
                            $anchor_file =~ /^(.*)\.[^.]*$/ ) {

                        my $anchor = $1;

                        my $path = ( $h_file->{'path'} =~
                            /^$options->{'working_dir'}\/(.*)$/ ) ?
                                $1 : '';

                        $path = $anchor . "/inflated_dir/" . $path;
                        File::OSS::Scan::Matches->add(
                            {
                                'name'  => $h_file->{'name'},
                                'path'  => $path,
                                'size'  => $h_file->{'size'},
                                'mtime' => $h_file->{'mtime'},
                            },
                            $func, $cert, join(' ', @$args), $msg
                        );
                    }
                    else {
                        File::OSS::Scan::Matches
                            ->add( $h_file, $func, $cert, join(' ', @$args), $msg);
                    }

                   # ignore other rules on the same line
                   next LINE;
                }
            }
        }
    }

    close(FILE);

    return SUCCESS;
}

sub filename_match {
    my ( $h_file, $cert, $args ) = @_;
    my $msg = '';

    my $fname = $h_file->{'name'};
    my $fpath = $h_file->{'path'};

    my $sname = $args->[0];

    if ( $fname =~ /^\Q$sname\E$/i ) {

        (caller(0))[3] =~ /\:{2}(\w+)$/;

        printing("${cert}% matched: $1 " .
            join(' ', @$args) )
        if ( $options->{'verbose'} != VERBOSE_SILIENT );

        $msg = "found file $fname ($fpath)";
        printing(' ' x 4 . $msg)
        if ( $options->{'verbose'} != VERBOSE_SILIENT );
    }

    return $msg;
}

sub content_match {
    my ( $h_file, $cert, $args, $line, $line_no ) = @_;
    my $msg = '';

    my $fname = $h_file->{'name'};
    my $fpath = $h_file->{'path'};

    (caller(0))[3] =~ /\:{2}(\w+)$/;
    my $func = $1;

    my $pattern = $args->[0];

    $pattern = '\b' . $pattern . '\b'
        if ( $pattern =~ /^\w+$/ );

    my $case_sensitive = UNI_FALSE;
    $case_sensitive = $args->[1] ?  UNI_TRUE : UNI_FALSE
    if ( defined $args->[1] );

    if ( $case_sensitive ) {
        if ( $line =~ /$pattern/ ) {
            printing("${cert}% matched: $func " .
                join(' ', @$args) )
            if ( $options->{'verbose'} != VERBOSE_SILIENT );

            $msg = "found matched content in $fname ($fpath)";
            printing(' ' x 4 . $msg)
            if ( $options->{'verbose'} != VERBOSE_SILIENT );
            $msg = "[line:$line_no]$line";
            printing(' ' x 4 . $msg)
            if ( $options->{'verbose'} != VERBOSE_SILIENT );

        }
    }
    else {
        if ( $line =~ /$pattern/i ) {
            printing("${cert}% matched: $func " .
                join(' ', @$args) )
            if ( $options->{'verbose'} != VERBOSE_SILIENT );

            $msg = "found matched content in $fname ($fpath)";
            printing(' ' x 4 . $msg)
            if ( $options->{'verbose'} != VERBOSE_SILIENT );
            $msg = "[line:$line_no]$line";
            printing(' ' x 4 . $msg)
            if ( $options->{'verbose'} != VERBOSE_SILIENT );

        }
    }

    return $msg;
}

sub copyright_match {
    my ( $h_file, $cert, $args, $line, $line_no ) = @_;
    my $msg = '';

    my $fname = $h_file->{'name'};
    my $fpath = $h_file->{'path'};

    (caller(0))[3] =~ /\:{2}(\w+)$/;
    my $func = $1;

    my @exclude_list = @$args;
    my $matched = UNI_FALSE;

    $matched = UNI_TRUE
    if (
        $line =~ /Copyright\s*\(C\)\s*\w+/i or
        $line =~ /Copyright\s*[\d\-]+\s*\w+/i or
        $line =~ /Copyright.*Software/i or
        $line =~ /Copyright.*All\srights\sreserved/i or
        $line =~ /\@Copyright/i
    );

    if ( $matched ) {
        foreach my $exclude_ext ( @exclude_list ) {

            if ( $line =~ /\b$exclude_ext\b/i ) {
                if ( $options->{'verbose'} == VERBOSE_CHATTY ) {
                    printing("excluded pattern found $exclude_ext, so not a match");
                    printing(' ' x 4 . "[line:$line_no]$line");
                }

                # return no match
                return undef;
            }
        }
    }

    if ( $matched ) {
        printing("${cert}% matched: $func " .
            join(' ', @$args) )
        if ( $options->{'verbose'} != VERBOSE_SILIENT );

        $msg = "found matched copyright in $fname ($fpath)";
        printing(' ' x 4 . $msg)
        if ( $options->{'verbose'} != VERBOSE_SILIENT );
        $msg = "[line:$line_no]$line";
        printing(' ' x 4 . $msg)
        if ( $options->{'verbose'} != VERBOSE_SILIENT );

    }

    return $msg;
}







1;

