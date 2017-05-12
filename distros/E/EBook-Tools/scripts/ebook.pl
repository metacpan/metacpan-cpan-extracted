#!/usr/bin/perl
use warnings; use strict;
use v5.10.1;


=head1 NAME

ebook - create and manipulate e-books from the command line

=head1 SYNOPSIS

 ebook COMMAND arg1 arg2 --opt1 --opt2

See also L</EXAMPLES>.

=cut

use Config::IniFiles;
use Cwd qw(chdir getcwd realpath);
use EBook::Tools qw(:all);
use EBook::Tools::IMP qw(:all);
use EBook::Tools::Mobipocket qw(:all);
use EBook::Tools::MSReader qw(:all);
use EBook::Tools::Unpack;
use File::Basename qw(dirname fileparse);
use File::Path;              # Exports 'mkpath' and 'rmtree'
use File::Slurp qw(slurp);   # Also exports 'read_file' and 'write_file'
use File::Temp qw(tempfile tempdir);
use Getopt::Long qw(:config bundling);

# Exit values
use constant EXIT_SUCCESS       => 0;   # Success
use constant EXIT_BADCOMMAND    => 1;   # Invalid main command
use constant EXIT_BADOPTION     => 2;   # Invalid subcommand or option
use constant EXIT_BADINPUT      => 10;  # Bad input data
use constant EXIT_BADOUTPUT     => 11;  # Bad/unexpected output data
use constant EXIT_TOOLSERROR    => 20;  # Internal EBook::Tools error
use constant EXIT_MISSINGHELPER => 30;  # Required helper file not found
use constant EXIT_HELPERERROR   => 31;  # Helper command exited improperly


########################################
########## CONFIGURATION FILE ##########
########################################

my $defaultconfig = slurp(\*DATA);
my $configdir = userconfigdir();
my $configfile = $configdir . '/config.ini';
my $config;
if(-f $configfile)
{
    $config = Config::IniFiles->new( -file => $configfile );
}
$config = Config::IniFiles->new() unless($config);
#$config->read($configfile);

# Tidysafety requires special handling, since 0 is a valid value
my $tidysafety = $config->val('config','tidysafety');
undef($tidysafety) if(defined($tidysafety) and $tidysafety eq '');


#####################################
########## OPTION HANDLING ##########
#####################################

my %opt = (
    'author'      => '',
    'category'    => undef,
    'compression' => undef,
    'dir'         => '',
    'erotic'      => 0,
    'fileas'      => '',
    'firstname'   => undef,
    'fix'         => 1,
    'format'      => '',
    'help'        => 0,
    'htmlconvert' => 0,
    'identifier'  => undef,
    'input'       => '',
    'key'         => '',
    'lastname'    => undef,
    'middlename'  => undef,
    'mimetype'    => '',
    'mobi'        => 0,
    'mobigencmd'  => $config->val('helpers','mobigen') || undef,
    'names'	  => 0,
    'nosave'      => 0,
    'noscript'    => 0,
    'oeb12'       => 0,
    'opf20'       => 0,
    'opffile'     => '',
    'raw'         => 0,
    'subcategory' => undef,
    'tidy'        => 0,
    'tidycmd'     => $config->val('helpers','tidy') || undef,
    'tidysafety'  => $tidysafety,
    'title'       => undef,
    'verbose'     => $config->val('config','debug') || 0,
    );

GetOptions(
    \%opt,
    'author=s',
    'category|cat=s',
    'compression|c=i',
    'delete|del',
    'dir|d=s',
    'erotic|sex',
    'fileas=s',
    'firstname=s',
    'fix',
    'format=s',
    'help|h|?',
    'htmlconvert',
    'identifier|id=s',
    'input|i=s',
    'key|pid=s',
    'lastname=s',
    'middlename=s',
    'mimetype|mtype=s',
    'mobi|m',
    'mobigencmd|mobigen=s',
    'names',
    'nosave',
    'noscript',
    'raw',
    'oeb12',
    'opf20',
    'opffile|opf=s',
    'output|o=s',
    'subcategory|subcat=s',
    'tidy',
    'tidycmd',
    'tidysafety|ts=i',
    'title=s',
    'verbose|v+',
    );

if($opt{oeb12} && $opt{opf20})
{
    print "Options --oeb12 and --opf20 are mutually exclusive.\n";
    exit(EXIT_BADOPTION);
}

# Default to OPF20 if neither format is specified
if(!$opt{oeb12} && !$opt{opf20}) { $opt{opf20} = 1; }

$EBook::Tools::debug = $opt{verbose};
$EBook::Tools::tidycmd = $opt{tidycmd} if($opt{tidycmd});
$EBook::Tools::tidysafety = $opt{tidysafety} if(defined $opt{tidysafety});


######################################
########## COMMAND HANDLING ##########
######################################

my %dispatch = (
    'adddoc'      => \&adddoc,
    'additem'     => \&additem,
    'bisac'       => \&bisac,
    'blank'       => \&blank,
    'convert'     => \&convert,
    'dc'          => \&downconvert,
    'dlbisac'     => \&dlbisac,
    'downconvert' => \&downconvert,
    'config'      => \&config,
    'fix'         => \&fix,
    'genepub'     => \&genepub,
    'genimp'      => \&genimp,
    'genmobi'     => \&genmobi,
    'genncx'	  => \&genncx,
    'impmeta'     => \&impmeta,
    'setcover'    => \&setcover,
    'setmeta'     => \&setmeta,
    'splitmeta'   => \&splitmeta,
    'splitpre'    => \&splitpre,
    'stripscript' => \&stripscript,
    'tidyxhtml'   => \&tidyxhtml,
    'tidyxml'     => \&tidyxml,
    'unpack'      => \&unpack_ebook,
    );

my $cmd = shift;

if(!$cmd)
{
    print "No command specified.\n";
    print "Valid commands are: ",join(" ",sort keys %dispatch),"\n";
    exit(EXIT_BADCOMMAND);
}
if(!$dispatch{$cmd})
{
    print "Invalid command '",$cmd,"'\n";
    print "Valid commands are: ",join(" ",sort keys %dispatch),"\n";
    exit(EXIT_BADCOMMAND);
}

$dispatch{$cmd}(@ARGV);
exit(EXIT_SUCCESS);


#########################################
########## COMMAND SUBROUTINES ##########
#########################################

=head1 COMMANDS

=head2 C<adddoc>

Adds a documents to both the book manifest and spine.

=head3 Options

=over

=item C<--opffile>

=item C<--opf>

The OPF file to modify.  If not specified one will be searched for in
the current directory.

=item C<--identifier>

=item C<--id>

The ID attribute to use for the added manifest item.  This is
required, and ebook will abort if it is not specified.

=item C<--mimetype>

=item C<--mtype>

The mime type string to use for the added manifest item.  If not
specified, it will be autodetected via File::Mimeinfo::Magic.  This
may not result in an optimal string.

=back

=head3 Example

 ebook adddoc --opf mybook.opf --id 'text-ch1' chapter1.html

=cut

sub adddoc
{
    my ($newdoc) = @_;
    my $opffile = $opt{opffile};
    my $id = $opt{identifier};
    my $mtype = $opt{mimetype};

    my $ebook = EBook::Tools->new();
    $ebook->init($opffile);
    $ebook->add_document($newdoc,$id,$mtype);
    if($ebook->errors)
    {
        print {*STDERR} "Unrecoverable errors found.  Aborting.\n";
        $ebook->print_errors;
    }
    $ebook->save;
    $ebook->print_warnings;
    return 0;
}


=head2 C<additem>

Add an item to the book manifest, but not the spine.

Note that the L</fix> command will automatically insert manifest items
for any local files referenced by existing manifest items.

=head3 Options

=over

=item C<--opffile>

=item C<--opf>

The OPF file to modify.  If not specified one will be searched for in
the current directory.

=item C<--identifier>

=item C<--id>

The ID attribute to use for the added manifest item.  This is
required, and ebook will abort if it is not specified.

=item C<--mimetype>

=item C<--mtype>

The mime type string to use for the added manifest item.  If not
specified, it will be autodetected via File::Mimeinfo::Magic.  This
may not result in an optimal string.

=back

=head3 Example

 ebook additem --opf mybook.opf --id 'illus-ch1' chapter1-illus.jpg

=cut

sub additem
{
    my ($newitem) = @_;
    my $opffile = $opt{opffile};
    my $id = $opt{identifier};
    my $mtype = $opt{mimetype};

    if(!$id)
    {
        print {*STDERR} "You must specify an ID when adding a document!\n";
        exit(EXIT_BADOPTION);
    }

    my $ebook = EBook::Tools->new();
    $ebook->init($opffile);
    $ebook->add_item($newitem,$id,$mtype);
    if($ebook->errors)
    {
        print {*STDERR} "Unrecoverable errors found.  Aborting.\n";
        $ebook->print_errors;
        exit(EXIT_TOOLSERROR);
    }
    $ebook->save;
    $ebook->print_warnings;
    return 0;
}


=head2 C<bisac>

Search for a BISAC code matching a case-insensitive regular expression.

=head3 Options

=over

=item C<regexp>

The first argument is taken as a regular expression to use for the
search.  If this is either '.' or not specified, the entire list of
valid codes is printed.

This requires that the BISAC codes be downloaded ahead of time.  (See
C<dlbisac>.)

=back

=cut

sub bisac
{
    my ($regexp) = @_;
    my $bisg = EBook::Tools::BISG->new();

    my @list = $bisg->find($regexp);

    foreach my $code (@list) {
        print $code,"\n";
    }
    return 0;
}


=head2 C<blank>

Create a blank e-book structure.

=head3 Options

=over

=item C<--opffile filename.opf>

=item C<--opf filename.opf>

Use the specified OPF file.  This can also be specified as the first
non-option argument, which will override this option if it exists.  If
no file is specified, the program will abort with an error.
=item C<--author> "Author Name"

The author of the book.  If not specified, defaults to "Unknown
Author".

=item C<--title> "Title Name"

The title of the book.  If not specified, defaults to "Unknown Title".

=item C<--dir directory>

=item C<-d directory>

Output the OPF file in this directory, creating it if necessary.

=back

=head3 Example

 ebook blank newfile.opf --author "Me Myself" --title "New File"
 ebook blank --opffile newfile.opf --author "Me Myself" --title "New File"

Both of those commands have the same effect.

=cut

sub blank
{
    my ($opffile) = @_;
    my %args;
    my $ebook;

    $opffile = $opt{opffile} if(!$opffile);

    $args{opffile} = $opffile;
    $args{author} = $opt{author} if($opt{author});
    $args{title} = $opt{title} if($opt{title});

    useoptdir() unless($opt{nosave});
    $ebook = EBook::Tools->new();
    $ebook->init_blank(%args);
    $ebook->save unless($opt{nosave});
    return 0;
}


=head2 C<config>

Make changes to the EBook::Tools configuration file.

The configuration file itself is located as either
C<$ENV{HOME}/.ebooktools/config.ini> or as
C<$ENV{USERPROFILE}\Application Data\EBook-Tools>, depending on
platform and which directory is found first.  See
L<EBook::Tools/userconfigdir()> for details.

=head3 Arguments / Subcommands

Configuration is always handled in the format of:

 ebook config subcommand value

=over

=item * C<default>

Replace any existing configuration file with a default template.  This
creates the file if it does not exist.  This should be done once
before any other configuration manipulation is done, unless a
configuration file has been manually created ahead of time.

=item * C<debug>

Sets the default debugging level when no verbosity is specified.  Note
that verbosity can only be increased, not decreased, with the C<-v>
option.

=item * C<tidysafety>

Sets the default safety level when tidy is used.  Valid values are
from 0-4.  See L</unpack> for details on what each value means.

=item * C<mobipids>

A comma-separated list of Mobipocket PIDs to try to use to decrypt
e-books.  This value is only used if the appropriate plug-in modules
or helper applications are available, as DRM is not supported natively
by EBook::Tools.  Note that if the PID includes a $ character, the
entire PID string has to be enclosed in single quotes.

=back

=head3 Examples

 ebook config default
 ebook config debug 2
 ebook config mobipids '1234567890,2345678$90'

=cut

sub config
{
    my $subcommand = shift;
    my $value = shift;
    my $subname = ( caller(0) )[3];

    my %valid_subcommands = (
        'default' => 1,
        'debug' => 1,
        'tidysafety' => 1,
        'mobipids' => 1,
        );

    if(!$subcommand)
    {
        print {*STDERR} ("You must specify what configuration change you",
                         " want to make.\n");
        print {*STDERR} "Valid config commands are:\n";
        foreach my $subcom (keys %valid_subcommands)
        {
            print {*STDERR} "  config ",$subcom,"\n";
        }
        exit(EXIT_BADCOMMAND);
    }
    if(!$valid_subcommands{$subcommand})
    {
        print {*STDERR} "Invalid command 'config ",$subcommand,"'\n";
        print {*STDERR} "Valid config commands are:\n";
        foreach my $subcom (keys %valid_subcommands)
        {
            print {*STDERR} "  config ",$subcom,"\n";
        }
        exit(EXIT_BADCOMMAND);
    }

    if($subcommand eq 'default')
    {
        my $fh_config;
        local $/;

        print "Creating new configuration file '",$configfile,"'\n";
        open($fh_config,'>',$configfile)
            or die("Unable to open config file '",$configfile,"' for writing!\n");
        print {*$fh_config} $defaultconfig;
        close($fh_config)
            or die("Unable to close config file '",$configfile,"'!\n");
    }
    elsif($subcommand eq 'debug')
    {
        if(not defined $value)
        {
            print {*STDERR} "You must specify a debugging level.\n";
            exit(EXIT_BADOPTION);
        }
        $config->setval('config','debug',$value);
        $config->RewriteConfig;
    }
    elsif($subcommand eq 'tidysafety')
    {
        if(not defined $value)
        {
            print {*STDERR} "You must specify a tidy safety level.\n";
            exit(EXIT_BADOPTION);
        }
        $config->setval('config','tidysafety',$value);
        $config->RewriteConfig;
    }
    elsif($subcommand eq 'mobipids')
    {
        my @pids;
        if(!$value)
        {
            print {*STDERR} "You must specify at least one PID.\n";
            exit(EXIT_BADOPTION);
        }
        @pids = split(/,/,$value);
        foreach my $pid (@pids)
        {
            if(!pid_is_valid($pid))
            {
                print {*STDERR} "PID '",$pid,"' is not valid!  Aborting!\n";
                exit(EXIT_BADOPTION);
            }
        }
        $config->setval('drm','mobipids',$value);
        $config->RewriteConfig;
    }
    return 0;
}


=head2 C<convert>

Unpacks the ebook specified as the first argument, runs standard fixes
on the contents, and repacks it into a new format in the output file
specified as the second argument.  Currently the only supported output
format is epub, which is the format you will get irrespective of the
extension you actually give the output file.

=head3 Options

=over

All options from C<unpack> and C<fix> are technically valid here as
well, though of course some options are nonsensical in this context
and will likely break the conversion (e.g. --nosave).

=back

=head3 Example

 ebook convert MyBook.prc MyBook.epub
 ebook convert --name MyBook.lit /home/myname/MyBook.epub

=cut

sub convert
{
    my ($infile,$outfile) = @_;
    my $subname = ( caller(0) )[3];

    my $tempdir = File::Temp->newdir();
    $tempdir->unlink_on_destroy( 1 );
    my $cwd_orig = getcwd();

    if(!$infile) { die("You must specify an input file.\n"); }
    if(!$outfile) { die("You must specify an output file.\n"); }

    my $ebook;
    my $bookname;
    my $format;

    ($bookname,undef,undef) = fileparse($infile,'\.\w+$');
    (undef,undef,$format) = fileparse($outfile,'\.\w+$');

    # TODO: actually check $format

    $infile = realpath($infile);
    $outfile = realpath($outfile);

    $dispatch{'unpack'}($infile,$tempdir);

    chdir($tempdir);

    $dispatch{'fix'}();

    $opt{output} = $outfile;
    $dispatch{'genepub'}();

    chdir($cwd_orig);
    return 0;
}


=head2 C<dlbisac>

Downloads and caches the Book Industry Study Group BISAC codes into a
local database.  This will destroy the existing contents of that table
if this has been done previously.

=cut

sub dlbisac
{
    my $subname = ( caller(0) )[3];

    my $bisg = EBook::Tools::BISG->new();
    $bisg->download_bisac;
    $bisg->save_bisac;
    return;
}


=head2 C<downconvert>

=head2 C<dc>

If the appropriate helpers or plugins are available, write a copy of
the input file with the DRM restrictions removed.

NOTE: no actual DRM-removal code is present in this package.  This is
just presents a unified interface to other programs that have that
capability.

=head3 Arguments

=over

=item * C<infile>

The first non-option argument is taken to be the input file.  If not
specified, the program exits with an error.

=item * C<outfile>

The second non-option argument is taken to be the output file.  If not
specified, the program will use a name based on the input file,
appending '-nodrm' to the basename and keeping the extension.  In the
special case of Mobipocket files ending in '-sm', the '-sm' portion of
the basename is simply removed, and nothing else is appended.

=item * C<key>

The third non-option argument is taken to be either the decryption
key/PID, or in the case of Microsoft Reader (.lit) files, the
C<keys.txt> file containing the decryption keys.

If not specified, this will be looked up from the configuration file.
Convertlit keyfiles will be looked for in standard locations.  If no
key is found, the command aborts and exits with an error.

=back

=head3 Example

 ebook downconvert NewBook.lit NewBook-readable.lit mykeys.txt
 ebook dc MyBook-sm.prc

=cut

sub downconvert
{
    my ($infile,$outfile,$key) = @_;
    my $suffix;
    my $mobidedrm = find_mobidedrm();
    my $convertlit = find_convertlit();
    my $status;

    if(!$infile)
    {
        print {*STDERR} "You must specify a file to downconvert.\n";
        exit(EXIT_BADOPTION);
    }
    unless(-f $infile)
    {
        print {*STDERR} "Could not find '",$infile,"' to downconvert!\n";
        exit(EXIT_BADINPUT);
    }

    my $unpacker = EBook::Tools::Unpack->new(
        'file' => $infile,
        'format' => $opt{format},
        );

    if($unpacker->format eq 'mobipocket')
    {
        if(!$mobidedrm)
        {
            print {*STDERR} <<'END';
Downconverting Mobipocket books requires that MobiDeDRM be available,
either on the path, in the configuration directory, or specified in
the configuration file.
END
            exit(EXIT_MISSINGHELPER);
        }
        if($key)
        {
            if(!pid_is_valid($key))
            {
                print {*STDERR} "PID '",$key,"' is not valid!\n";
                exit(EXIT_BADOPTION);
            }
            $outfile = system_mobidedrm(infile => $infile,
                                        outfile => $outfile,
                                        pid => $key);
            if(!$outfile)
            {
                print {*STDERR} "Failed to downconvert '",$infile,"'!\n";
                exit(EXIT_HELPERERROR);
            }
        }
        else
        {
            my @pids = split(/,/,$config->val('drm','mobipids'));
            if(!@pids)
            {
                print {*STDERR}
                "No PID specified, and none found in configuration file!\n";
                exit(EXIT_BADOPTION);
            }
            foreach my $pid (@pids)
            {
                if(!pid_is_valid($pid))
                {
                    print {*STDERR} "PID '",$pid,"' is not valid, skipping!\n";
                    next;
                }
                $outfile = system_mobidedrm(infile => $infile,
                                            outfile => $outfile,
                                            pid => $pid);
                last if($outfile);
            }
            if($outfile)
            {
                print("Successfully downconverted '",$infile,
                    "' into '",$outfile,"'\n");
                return 0;
            }
            else
            {
                print "Unable to downconvert '",$infile,"'!\n";
                exit(EXIT_BADOUTPUT);
            }
        } # if($key) / else
    } # if($unpacker->format eq 'mobipocket')

    elsif($unpacker->format eq 'msreader')
    {
        if(!$convertlit)
        {
            print {*STDERR} <<'END';
Downconverting MS Reader books requires that ConvertLit be available,
either on the path, in the configuration directory, or specified in
the configuration file.
END
            exit(EXIT_MISSINGHELPER);
        }
        if(!$outfile)
        {
            ($outfile,undef,$suffix) = fileparse($infile,'\.\w+$');
            $outfile .= '-nodrm' . $suffix;
        }
        my $retval = system_convertlit(infile => $infile,
                                       outfile => $outfile,
                                       keyfile => $key);
        if($retval == 0)
        {
            print("Successfully downconverted '",$infile,
                "' into '",$outfile,"'\n");
            return 0;
        }
        else
        {
            print("Failed to downconvert '",$infile,
                  " [system_convertlit returned ",$retval,"]\n");
            exit(EXIT_HELPERERROR);
        }
    }
    else
    {
        print {*STDERR} "Cannot downconvert format '",$unpacker->format,"'\n";
        exit(EXIT_BADINPUT);
    }
    return 0;
}


=head2 C<fix>

Find and fix problems with an e-book, including enforcing a standard
specification and ensuring that all linked objects are present in the
manifest.

=head3 Options

=over

=item C<--opffile filename.opf>

=item C<--opf filename.opf>

Use the specified OPF file.  This can also be specified as the first
non-option argument, which will override this option if it exists.  If
no file is specified, one will be searched for.

=item C<--oeb12>

Force the OPF to conform to the OEB 1.2 standard.  This is the default.

=item C<--opf20>

Force the OPF to conform to the OPF 2.0 standard.  If both this and
C<--oeb12> are specified, the program will abort with an error.

=item C<--mobi>

Correct Mobipocket-specific elements, creating an output element to
force UTF-8 output if one does not yet exist.

=item C<--erotic> or C<--sex>

Enable special handling for erotic fiction (most notably special
subject normalization rules).

=item C<--names>

Normalize names to standard capitalization and format (primary name
display is "First Middle Last", but file-as is "Last, First Middle".

This is not done by default as it can damage unusual but correct
names.

=back

=cut

sub fix
{
    my ($opffile) = @_;
    my $ebook;
    my $retval;
    my ($filebase,$filedir,$fileext);
    my $tidyfile;
    my $warncount;

    $opffile = $opt{opffile} if(!$opffile);
    $ebook = EBook::Tools->new();
    $ebook->init($opffile);
    if($opt{erotic}) { $ebook->set_erotic(1); }
    $ebook->fix_oeb12 if($opt{oeb12});
    if($opt{opf20}) {
        if(-f 'META-INF/container.xml') {
            $ebook->gen_epub_files;
        }
        else {
            $ebook->fix_opf20;
        }
    }
    $ebook->fix_misc;
    $ebook->fix_mobi if($opt{mobi});
    if($opt{names}) {
        $ebook->fix_creators;
    }
    $ebook->save unless($opt{nosave});

    if($ebook->errors) {
        $ebook->print_errors;
        print "Unrecoverable errors while fixing '",$opffile,"'!\n";
        exit(EXIT_TOOLSERROR);
    }

    $ebook->print_warnings if($ebook->warnings);
    return 0;
}


=head2 C<genepub>

Generate a .epub book from existing OPF data.

=head3 Options

=over

=item C<--input filename.opf>

=item C<--i filename.opf>

=item C<--opffile filename.opf>

=item C<--opf filename.opf>

Use the specified OPF file.  If no file is specified, one will be
searched for.

=item C<--output bookname.epub>

=item C<-o bookname.epub>

Use the specified name for the final output file.  This can also be
specified as the first non-option argument, which will override this
option if it exists.  If not specified, the book will have the same
filename as the OPF file, with the extension changed to C<.epub>.

=item C<--dir directory>

=item C<-d directory>

Output the final .epub book into the specified directory.  The default
is to use the current working directory.

=back

=head3 Example

 ebook genepub mybook.opf -o my_special_book.epub -d ../epubbooks

or in the simplest case:

 ebook genepub

=cut

sub genepub
{
    my ($outfile) = @_;
    my $ebook;

    if(!$outfile) { $outfile = $opt{output}; }

    if($opt{opffile}) {
        $ebook = EBook::Tools->new($opt{opffile});
    }
    else {
        $ebook = EBook::Tools->new();
        $ebook->init();
    }

    if(! $ebook->gen_epub(filename => $opt{output},
                          dir => $opt{dir}) )
    {
        print {*STDERR} "Failed to generate .epub file!\n";
        $ebook->print_errors;
        $ebook->print_warnings;
        exit(EXIT_BADOUTPUT);
    }
    $ebook->print_warnings if($ebook->warnings);
    return 0;
}


=head2 C<genimp>

Generate a eBookwise .imp book from a .RES directory

=head3 Options

=over

=item C<--input DIRNAME.RES>

=item C<-i DIRNAME.RES>

Specifies the resource directory to use for input.  A valid resource
directory will contain at least a C<RSRC.INF> file, a C<DATA.FRK>
file, and several other files with four-capital-letter filenames.

This can also be specified as the first non-option argument, which
will override this option if it exists.  If not specified, the current
directory will be used.

=item C<--output bookname.epub>

=item C<-o bookname.epub>

Use the specified name for the final output file.  If not specified,
the book will have the same filename as the input, with the extension
changed to C<.imp>.

=back

=head3 Examples

 ebook genimp MyUnpackedBook.RES MyBook.imp
 ebook genimp --resdir ../MyUnpackedBook.RES -f imp/MyBook.imp

=cut

sub genimp
{
    my ($input,$output) = @_;
    my $ebook;
    my $retval;

    $input ||= $opt{input};
    $input ||= '.';
    $output ||= $opt{output};

    if(! $input)
    {
        print {*STDERR} "Resource directory not specified!\n";
        exit(EXIT_BADOPTION);
    }

    if(! -d $input)
    {
        print {*STDERR} "Resource directory '",$input,"' not found!\n";
        exit(EXIT_BADOPTION);
    }

    if(! $output)
    {
        print {*STDERR} "Output file not specified!\n";
        exit(EXIT_BADOPTION);
    }

    my $imp = EBook::Tools::IMP->new();
    if(! $imp->load_resdir($input) )
    {
        print {*STDERR} ("Failed to load from resource directory '",
                         $input,"'!\n");
        exit(EXIT_BADINPUT);
    }
    if(! $imp->write_imp($output) or ! -f $output)
    {
        print {*STDERR} ("Failed to generate '",$output,"'!\n");
        exit(EXIT_BADOUTPUT);
    }
    return 0;
}


=head2 C<genmobi>

Generate a Mobipocket .mobi/.prc book from OPF, HTML, or ePub input.

=head3 Options

=over

=item C<--input filename>

=item C<--i filename>

Use the specified file for input.  Valid formats are OPF, HTML, and
ePub.  This can also be specified as the first non-option argument,
which will override this option if it exists.  If no file is
specified, an OPF file in the current directory will be searched for.

=item C<--output bookname.prc>

=item C<-o bookname.prc>

Use the specified name for the final output file.  If not specified,
the book will have the same filename as the input file, with the
extension changed to C<.mobi> (this file is always created by
C<mobigen>, specifying a different filename only causes it to be
renamed afterwards).

This can also be specified as the second non-option argument, which
will override this option if it exists.

=item C<--dir directory>

=item C<-d directory>

Output the final book into the specified directory.  The default is to
use the current working directory, which is where C<mobigen> will
always place it initially; if specified this only forces the file to
be moved after generation.

=item C<--compression x>

=item C<-c x>

Use the specified compression level C<x>, where 0 is no compression, 1
is PalmDoc compression, and 2 is HUFF/CDIC compression.  If not
specified, defaults to 1 (PalmDoc compression).

=back

=head3 Example

 ebook genmobi mybook.opf -o my_special_book.prc -d ../mobibooks
 ebook genmobi mybook.html mybook.prc -c2

or in the simplest case:

 ebook genmobi

=cut

sub genmobi
{
    my ($infile,$outfile) = @_;
    my $ebook;
    my $retval;

    $infile = $opt{input} if(!$infile);
    $infile = find_opffile() if(!$infile);

    if(!$infile)
    {
        print {*STDERR} "No input file specified or detected!\n";
        exit(EXIT_BADOPTION);
    }

    $outfile = $opt{output} if(!$outfile);

    if(!find_mobigen())
    {
        print {*STDERR} "No mobigen executable available!\n";
        exit(EXIT_MISSINGHELPER);
    }

    $retval = system_mobigen(infile => $infile,
                             outfile => $outfile,
                             dir => $opt{dir},
                             compression => $opt{compression});

    if($retval)
    {
        print {*STDERR} "Error during generation: ",$retval,"\n";
        exit(EXIT_HELPERERROR);
    }
    return 0;
}


=head2 C<genncx>

Given an OPF file, creates a NCX-format table of contents from the
package unique-identifier, the dc:title, dc:creator, and spine
elements, and then add the NCX entry to the manifest if it is not
already referenced.

The OPF file will be cleaned to OPF20 format before this happens.

=head3 Options

=over

=item C<--opffile filename.opf>

=item C<--opf filename.opf>

Use the specified OPF file.  This can also be specified as the first
non-option argument, which will override this option if it exists.  If
no file is specified, one will be searched for.

=back

=cut

sub genncx {
    my ($opffile) = @_;
    my $ebook;

    $opffile = $opt{opffile} if(!$opffile);
    $ebook = EBook::Tools->new();
    $ebook->init($opffile);
    $ebook->fix_opf20;
    $ebook->gen_ncx;
    unless($opt{nosave})
    {
        useoptdir();
        $ebook->save;
    }
    if($ebook->errors)
    {
        $ebook->print_errors;
        print "Unrecoverable errors while fixing '",$opffile,"'!\n";
        exit(EXIT_TOOLSERROR);
    }

    $ebook->print_warnings if($ebook->warnings);
    return 0;
}


=head2 C<impmeta>

Set specific metadata values in an ETI .imp file.

=head3 Options

=over

=item * C<--input filename.imp>

=item * C<-i filename.imp>

Specify the input filename.  This can also be specified as the first
argument, in which case the -i option will be ignored.

=item * C<--output modified.imp>

=item * C<-o modified.imp>

Specify the output filename.  If not specified, the input file will be
overwritten.

=item * C<--identifier>

Specify the identifier metadata.

=item * C<--category>

=item * C<--cat>

Specify the category metadata.

=item * C<--subcategory>

=item * C<--subcat>

Specify the subcategory metadata.

=item * C<--title>

Specify the title metadata.

=item * C<--lastname>

Specify the author last name metadata.

=item * C<--middlename>

Specify the author middle name metadata.

=item * C<--firstname>

Specify the author first name metadata.  Note that IMP files commonly
place the full name in this component, and leave the middlename and
lastname entries blank.

=back

=head3 Examples

 ebook impmeta mybook.imp --title 'Fixed Title' --lastname 'John Q. Brandy'
 ebook impmeta -i mybook.imp -o fixed.imp --title 'Fixed Title'

=cut

sub impmeta
{
    my ($input) = @_;
    $input ||= $opt{input} if($opt{input});
    my $output = $opt{output};

    unless($input)
    {
        print "You must specify an input file.\n";
        exit(EXIT_BADOPTION);
    }
    $output ||= $input;

    my $imp = EBook::Tools::IMP->new();
    if(! $imp->load($input))
    {
        print "Failed to load '",$input,"' -- aborting!\n";
        exit(EXIT_BADINPUT);
    }

    $imp->set_book_properties(
        'identifier'  => $opt{identifier},
        'category'    => $opt{category},
        'subcategory' => $opt{subcategory},
        'title'       => $opt{title},
        'lastname'    => $opt{lastname},
        'middlename'  => $opt{middlename},
        'firstname'   => $opt{firstname}
        );

    if(! $imp->write_imp($output) )
    {
        print "Failed to write '",$output,"' -- aborting!\n";
        exit(EXIT_BADOUTPUT);
    }
    return 0;
}

=head2 C<setcover>

Sets the cover image

Takes as a single argument the href of the file to use.

=head3 Options

=over

=item * C<--opffile>

=item * C<--opf>

Specifies the OPF file to modify.  If not specified, the script will
attempt to find one

=item * C<--identifier>

=item * C<--id>

Specifies the ID to assign to the associated manifest item.

=back

=cut

sub setcover {
    my ($href) = @_;

    unless($href) {
        print "You must specify the href (filename) of the cover image!\n";
        exit(EXIT_BADOPTION);
    }

    my $opffile = $opt{opffile};
    my $id = $opt{identifier};

    my $ebook = EBook::Tools->new();
    $ebook->init($opffile);
    $ebook->set_cover(href => $href,
                      id => $id);
    $ebook->save;
    $ebook->print_errors;
    $ebook->print_warnings;
    return 0;
}


=head2 C<setmeta>

Set specific metadata values on an OPF file, creating a new entry if
none exists.

Both the element to set and the value are specified as additional
arguments, not as options.

The elements that can be set are currently:

=over

=item author

=item date

=item description

=item publisher

=item rights

=item series

=item subject

=item title

=item type

=back

The 'series' values can take an extra argument containing the series
index position.

The 'subject' elements can be added multiple times (including in a
single command-line, though --id will only set the ID on the first one
specified).  Other entries will be overwritten.

The element argument can be shortened to the minimum number of letters
necessary to uniquely identify it.

=head3 Options

=over

=item * C<--opffile>
=item * C<--opf>

Specifies the OPF file to modify.  If not specified, the script will
attempt to find one in the current directory.

=item * C<--delete>

Allows the deletion of subject and series metadata.  Has no effect on other elements.

=item * C<--fileas>

Specifies the 'file-as' attribute when setting an author.  Has no
effect on other elements.

=item * C<--identifier>

=item * C<--id>

Specifies the ID to assign to the element.

=back

=head3 Examples

 ebook setmeta series 'Some Other Series' 03
 ebook setmeta title 'My Great Title'
 ebook setmeta t 'My Great Title'
 ebook --opf newfile.opf setmeta author 'John Smith' --fileas 'Smith, John' --id mainauthor

=cut

sub setmeta
{
    my ($element,$value,@extra) = @_;

    unless($element)
    {
        print "You must specify which element to set.\n";
        print "Example: ebook setmeta title 'My Great Title'\n";
        exit(EXIT_BADOPTION);
    }
    $value ||= '';

    my $opffile = $opt{opffile};
    my $fileas = $opt{fileas};
    my $id = $opt{identifier};

    my $ebook = EBook::Tools->new();
    $ebook->init($opffile);

    if ($element =~ /^a/) {
        $ebook->set_primary_author('text' => $value,
                                   'fileas' => $fileas,
                                   'id' => $id );
    }
    elsif ($element =~ /^da/) {
        $value = fix_datestring($value);
        $ebook->set_date('text' => $value,
                         'id' => $id);
    }
    elsif ($element =~ /^de/) {
        $ebook->set_description('text' => $value,
                                'id' => $id);
    }
    elsif ($element =~ /^p/) {
        $ebook->set_publisher('text' => $value,
                              'id' => $id);
    }
    elsif ($element =~ /^r/) {
        $ebook->set_rights('text' => $value,
                           'id' => $id);
    }
    elsif ($element =~ /^se/) {
        # Unfortunately, there are no readers as of this writing
        # that support the EPub 3.0 collection standard, so the
        # only way to currently designate series is via the
        # calibre:series and calibre:series_index meta tags.

        if($opt{delete}) {
            $ebook->set_meta(name => 'calibre:series',
                             content => undef);
            $ebook->set_meta(name => 'calibre:series_index',
                             content => undef);
        }
        else {
            $ebook->set_meta(name => 'calibre:series',
                             content => $value);
            if($extra[0]) {
                $ebook->set_meta(name => 'calibre:series_index',
                                 content => $extra[0]);
            }
        }
    }
    elsif ($element =~ /^su/) {
        if($opt{delete}) {
            $ebook->delete_subject('text' => $value,
                                   'id' => $id);
            foreach my $subject(@extra) {
                $ebook->delete_subject('text' => $subject);
            }
        }
        else {
            $ebook->add_subject('text' => $value,
                                'id' => $id);
            foreach my $subject(@extra) {
                $ebook->add_subject('text' => $subject);
            }
        }
    }
    elsif ($element =~ /^ti/) {
        $ebook->set_title('text' => $value,
                          'id' => $id);
    }
    elsif ($element =~ /^ty/) {
        $ebook->set_type('text' => $value,
                         'id' => $id);
    }
    else {
        print "Unrecognized metadata element '",$element,"'!\n";
        exit(EXIT_BADOPTION);
    }

    $ebook->save;
    $ebook->print_errors;
    $ebook->print_warnings;
    return 0;
}


=head2 C<splitmeta>

Split the <metadata>...</metadata> block out of a pseudo-HTML file
that contains one.

=cut

sub splitmeta
{
    my ($infile,$opffile) = @_;
    if(!$infile) { die("You must specify a file to parse.\n"); }
    $opffile = $opt{opffile} if(!$opffile);

    my $ebook;

    $opffile = split_metadata($infile,$opffile);

    if(!$opffile)
    {
        print {*STDERR} "No metadata block was found in '",$infile,"'\n";
        exit(EXIT_BADINPUT);
    }

    $ebook = EBook::Tools->new($opffile);
    $ebook->fix_oeb12 if($opt{oeb12});
    $ebook->fix_opf20 if($opt{opf20});
    $ebook->fix_mobi if($opt{mobi});

    # The split metadata never includes manifest/spine info, so add in the
    # HTML file now
    $ebook->add_document($infile,'item-maintext');
    $ebook->fix_misc;
    $ebook->save;

    if($ebook->errors)
    {
        $ebook->print_errors;
        $ebook->print_warnings if($ebook->warnings);
        exit(EXIT_TOOLSERROR);
    }
    $ebook->print_warnings if($ebook->warnings);
    return 0;
}


=head2 C<splitpre>

Split <pre>...</pre> blocks out of an existing HTML file, wrapping
each one found into a separate HTML file.

The first non-option argument is taken to be the input file.  The
second non-option argument is taken to be the basename of the output
files.

=cut

sub splitpre
{
    my ($infile,$outfilebase) = @_;
    if(!$infile)
    {
        print {*STDERR} "You must specify a file to parse.\n";
        exit(EXIT_BADOPTION);
    }
    split_pre($infile,$outfilebase);
    return 0;
}


=head2 C<stripscript>

Strips <script>...</script> blocks out of a HTML file.

The first non-option argument is taken to be the input file.  The
second non-option argument is taken to be the output file.  If the
latter is not specified, the input file will be overwritten.

=head3 Options

=over

=item * C<--noscript>

Strips <noscript>...</noscript> blocks as well.

=back

=cut

sub stripscript
{
    my ($infile,$outfile) = @_;

    if(!$infile)
    {
        print "You must specify an input file.\n";
        exit(EXIT_BADOPTION);
    }
    my %args;
    $args{infile} = $infile;
    $args{outfile} = $outfile;
    $args{noscript} = $opt{noscript};

    strip_script(%args);
    return 0;
}

=head2 C<tidyxhtml>

Run tidy on a HTML file to enforce valid XHTML output (required by the
OPF 2.0 specification).

=cut

sub tidyxhtml
{
    my ($inputfile,$tidyfile) = @_;
    my $retval;

    if(!$inputfile)
    {
        print "You must specify an input file to tidy.\n";
        exit(EXIT_BADOPTION);
    }

    if($tidyfile) { $retval = system_tidy_xhtml($inputfile,$tidyfile); }
    else { $retval = system_tidy_xhtml($inputfile); }
    exit($retval);
}


=head2 C<tidyxml>

Run tidy an a XML file (for neatness).

=cut

sub tidyxml
{
    my ($inputfile,$tidyfile) = @_;
    my $retval;

    if(!$inputfile)
    {
        print "You must specify an input file to tidy.\n";
        exit(EXIT_BADOPTION);
    }

    if($tidyfile) { $retval = system_tidy_xml($inputfile,$tidyfile); }
    else { $retval = system_tidy_xml($inputfile); }
    exit($retval);
}


=head2 C<unpack_ebook>

Unpacks an ebook into its component parts, creating an OPF for them if
necessary.

=head3 Options

=over

=item C<--input>
=item C<-i>

The filename of the ebook to unpack.  This can also be specified as
the first non-option argument, in which case it will override the
option if it exists.

=item C<--dir>
=item C<-d>

The directory to unpack into, which will be created if it does not
exist, defaulting to the filename with the extension removed.  This
can also be specified as the second non-option argument, in which case
it will override the option if it exists.

=item C<--format>

The unpacking routines should autodetect the type of book under normal
conditions.  If autodetection fails, a format can be forced here.  See
L<EBook::Tools::Unpack> for a list of available formats.

=item C<--htmlconvert>

Attempt to convert the extracted text to HTML.  This is obviously only
of value if the format doesn't use HTML normally.

=item C<--raw>

This causes a lot of raw, unparsed, unmodified data to be dumped into
the directory along with everything else.  It's useful for debugging
exactly what was in the file being unpacked, but not for much else.

=item C<--author>

Set the primary author of the unpacked e-book, overriding what is
detected.  Not all e-book formats contain author metadata, and if none
is found and this is not specified the primary author will be set to
'Unknown Author'.

=item C<--title>

Set the title of the unpacked e-book, overriding what is detected.  A
title will always be detected in some form from the e-book, but the
exact text can be overridden here.

=item C<--opffile>

=item C<--opf>

The filename of the OPF metadata file that will be generated.  If not
specified, defaults to C<content.opf>.

=item C<--tidy>

Run tidy on any HTML output files to convert them to valid XHTML.  Be
warned that this can occasionally change the formatting, as Tidy isn't
very forgiving on certain common tricks (such as empty <pre> elements
with style elements) that abuse the standard.

=item C<--tidycmd>

The tidy executable name.  This has to be a fully qualified pathname
if tidy isn't on the path.  Defaults to 'tidy'.

=item C<--tidysafety>

The safety level to use when running tidy (default is 1).  Potential
values are:

=item C<$tidysafety < 1>:

No checks performed, no error files kept, works like a clean tidy -m

This setting is DANGEROUS!

=item C<$tidysafety == 1>:

Overwrites original file if there were no errors, but even if there
were warnings.  Keeps a log of errors, but not warnings.

=item C<$tidysafety == 2>:

Overwrites original file if there were no errors, but even if there
were warnings.  Keeps a log of both errors and warnings.

=item C<$tidysafety == 3>:

Overwrites original file only if there were no errors or warnings.
Keeps a log of both errors and warnings.

=item C<$tidysafety >= 4>:

Never overwrites original file.  Keeps a log of both errors and
warnings.

=back

=head3 Examples

 ebook unpack mybook.pdb My_Book --author "By Me"
 ebook unpack -i mybook.pdb -d My_Book --author "By Me"

Both of the above commands do the same thing

=cut

sub unpack_ebook
{
    my ($filename,$dir) = @_;
    $filename = $filename || $opt{input};
    $dir = $dir || $opt{dir};

    unless($filename)
    {
        print {*STDERR} "You must specify a file to unpack!\n";
        exit(EXIT_BADOPTION);
    }

    unless(-f $filename)
    {
        print {*STDERR} "Could not find '",$filename,"' to unpack!\n";
        exit(EXIT_BADINPUT);
    }

    if( $opt{key} && ! pid_is_valid($opt{key}) )
    {
        print {*STDERR} "Invalid PID '",$opt{key},"'\n";
        exit(EXIT_BADOPTION);
    }

    my $unpacker = EBook::Tools::Unpack->new(
        'file' => $filename,
        'dir' => $dir,
        'format' => $opt{format},
        'htmlconvert' => $opt{htmlconvert},
        'raw' => $opt{raw},
        'author' => $opt{author},
        'title' => $opt{title},
        'opffile' => $opt{opffile},
        'tidy' => $opt{tidy},
        'nosave' => $opt{nosave},
        );

    $unpacker->unpack;

    return 0;
}

########## PRIVATE PROCEDURES ##########

sub useoptdir
{
    if($opt{dir})
    {
        if(! -d $opt{dir})
        {
            mkpath($opt{dir})
                or die("Unable to create working directory '",$opt{dir},"'!");
        }
        chdir($opt{dir})
            or die("Unable to chdir to working directory '",$opt{dir},"'!");
    }
    return 1;
}

########## END CODE ##########

=head1 EXAMPLES

 ebook splitmeta book.html mybook.opf
 ebook tidyxhtml book.html
 ebook tidyxml mybook.opf
 ebook fix mybook.opf --oeb12 --mobi
 ebook genepub

 ebook blank newbook.opf --title "My Title" --author "My Name"
 ebook adddoc myfile.html
 ebook fix newbook.opf --opf20 -v
 ebook genepub

 ebook unpack mybook.pdb my_book
 cd my_book
 ebook addoc new_document.html
 ebook fix
 ebook genepub

=head1 BUGS/TODO

=over

=item * Need to implement a one-pass conversion from one format to
another.  This will wait until more formats are supported by the
underlying modules, however.

=item * Documentation is incomplete

=item * Not all configuration file options are actually used

=back

=head1 COPYRIGHT

Copyright 2008 Zed Pobre

=head1 LICENSE

Licensed to the public under the terms of the GNU GPL, version 2.

=cut


########## DATA ##########

__DATA__
#
# config.ini
#
# Configuration file for EBook-Tools
#
#

# The [config] section holds general configuration values for
# EBook::Tools.
[config]
#
# debug sets the default debugging level if no verbosity is specified
# Note that this can only be raised, not lowered, from the command line.
debug=0
#
# tidysafety sets the safety level when running system_tidy_xhtml or
# system_tidy_xml.  See the EBook::Tools documentation for possible
# values and what they mean.
tidysafety=1

# The [drm] section holds user-specific information needed to decrypt,
# encrypt, or inscribe protected e-books.  Additional plug-in modules
# or helper applications may be needed for some of these values to
# have any effect.
[drm]
#
# ereaderkeys is a comma-separated list of EReader decryption keys to
# try, in the order that they will be tried.
ereaderkeys=
#
# litkeyfile marks the full path and filename to the keys.txt file
# needed by convertlit to downconvert or unpack MS Reader files.  If
# not specified, a keys.txt file will be searched for in the
# configuration directory and the current working directory.
litkeyfile=
#
# mobpids is a comma-separated list of Mobipocket/Kindle PIDs to try,
# in the order that they will be tried.
mobipids=
#
# username is the full name that will be used when decrypting EReader
# books and when inscribing MS Reader .lit files
username=

# The [helpers] section holds the locations of helper files, including
# the complete path.  If not specified here, they will be searched
# for in the configuration directory and other likely locations.
[helpers]
convertlit=
mobidedrm=
mobigen=
pdbshred=
tidy=
