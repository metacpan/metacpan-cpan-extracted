# -*- perl -*-
#
#   HTML::EP::Glimpse - A simple search engine using Glimpse
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.005;
use strict;

use HTML::EP ();
use HTML::EP::Locale ();
use HTML::EP::Glimpse::Config ();

package HTML::EP::Glimpse;

$HTML::EP::Glimpse::VERSION = '0.05';
@HTML::EP::Glimpse::ISA = qw(HTML::EP::Locale HTML::EP);


sub _prefs {
    my $self = shift; my $attr = shift; my $prefs = shift;
    $self->{'glimpse_config'} ||= $HTML::EP::Glimpse::Config::config;
    my $config = $self->{'glimpse_config'};
    my $vardir = $config->{'vardir'};
    die "A directory $vardir does not exist. Please create it, with write "
        . " permissions for the web server, or modify the value of "
        . " vardir in $INC{'HTML/EP/Glimpse/Config.pm'}."
            unless -d $vardir;
    my $prefs_file = "$vardir/prefs";
    if (!$prefs) {
        # Load Prefs
	require Safe;
	my $cpt = Safe->new();
        $prefs = $self->{'prefs'} = $cpt->rdo($prefs_file) || {};

        $prefs->{'rootdir'} = $ENV{'DOCUMENT_ROOT'}
            unless exists($prefs->{'rootdir'});
        $prefs->{'dirs'} = "/"
            unless exists($prefs->{'dirs'});
        $prefs->{'dirs_ignored'} =
            (($ENV{'PATH_INFO'} =~ /(.*)\//) ? $1 : "")
                unless exists($prefs->{'dirs_ignored'});
        $prefs->{'suffix'} = ".html .htm"
            unless exists($prefs->{'suffix'});
    } else {
        # Save Prefs
        require Data::Dumper;
        my $d = Data::Dumper->new([$prefs])->Indent(1)->Terse(1)->Dump();
        require Symbol;
        my $fh = Symbol::gensym();
        if ($self->{'debug'}) {
            print "Saving Preferences to $prefs_file.\n";
            $self->print("Saving data:\n$d\n");
        }
        die "Could not save data into $prefs_file: $!. Please verify whether"
            . " the web server has write permissions in $vardir and on"
            . " $prefs_file."
                unless open($fh, ">$prefs_file")  and  (print $fh "$d\n")
                    and close($fh);
    }
    $self->{'glimpse_prefs'} = $prefs;
}


sub _ep_glimpse_load {
    my $self = shift; my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $prefs = $self->_prefs($attr);

    if ($cgi->param('modify')) {
        my $modified = 0;
        foreach my $p ($cgi->param()) {
            if ($p =~ /^glimpse_prefs_(.*)/) {
                my $sp = $1;
                my $old = $prefs->{$sp};
                my $new = $cgi->param($p);
                if (!defined($old)) {
                    if (defined($new)) {
                        $modified = 1;
                        $prefs->{$sp} = $new;
                    }
                } elsif (!defined($new)) {
                    $modified = 1;
                    $prefs->{$sp} = $new;
                } else {
                    $modified = ($new ne $old);
                    $prefs->{$sp} = $new;
                }
            }
        }
        if ($self->{'debug'}) {
            $self->print("Modifications detected.\n");
        }
        $self->_prefs($attr, $prefs);
    }
    '';
}


sub _ep_glimpse_create {
    my $self = shift; my $attr = shift;
    my $prefs = $self->_prefs($attr);
    my $vardir = $self->{'glimpse_config'}->{'vardir'};
    my $debug = $self->{'debug'};
    my $cfg = $self->{'glimpse_config'};

    my $rootdir = $prefs->{'rootdir'};
    my $dirlist = $prefs->{'dirs'};
    $dirlist =~ s/\s+/ /sg;
    $dirlist =~ s/^\s+//;
    $dirlist =~ s/\s+$//;
    my @dirs = map { "$rootdir/$_" } split(/ /, $dirlist);
    $dirlist = $prefs->{'dirs_ignored'};
    $dirlist =~ s/\s+/ /sg;
    $dirlist =~ s/^\s+//;
    $dirlist =~ s/\s+$//;
    my @dirs_ignored = map { "$rootdir/$_" } split(/ /, $dirlist);

    my $matchesDirsIgnored;
    if (@dirs_ignored) {
        my $dirsIgnoredRe = join("|", map { "\\Q$_\\E" } @dirs_ignored);
        my $func = "sub { shift() =~ m[^(?:$dirsIgnoredRe)] }";
        $matchesDirsIgnored = eval $func;
        $self->print("Making function for directory match: $func",
                     " ($matchesDirsIgnored))\n") if $debug;
    } else {
        $matchesDirsIgnored = sub { 0 }
    }
    my $suffixList = $prefs->{'suffix'};
    $suffixList =~ s/\s+/ /sg;
    $suffixList =~ s/^\s+//;
    $suffixList =~ s/\s+$//;
    my @suffix = split(/ /, $suffixList);
    my $matchesSuffix;
    if (@suffix) {
        my $suffixRe = join("|", map { "\\Q$_\\E" } @suffix);
        my $func = "sub { shift() =~ m[(?:$suffixRe)\$] }";
        $matchesSuffix = eval $func;
        $self->print("Making function for suffix match: $func",
                     "($matchesSuffix)\n") if $debug;
    } else {
        $matchesSuffix = sub { 1 }
    }

    my $fileList = '';
    require File::Find;
    File::Find::find
        (sub {
             if (&$matchesDirsIgnored($File::Find::dir)) {
                 $self->print("Skipping directory $File::Find::dir.\n")
                     if $debug;
                 $File::Find::prune = 1;
             } else {
                 my $f = $File::Find::name;
                 my $ok = ((-f $f)  and  &$matchesSuffix($f));
                 $self->print("    $f: $ok\n") if $debug;
                 $fileList .= "$f\n" if $ok;
             }
         }, @dirs);

    die "No files found" unless $fileList;

    my $fh = Symbol::gensym();
    my $cmd = "$cfg->{'glimpseindex_path'} -b -F -H $vardir -X";
    $self->print("Creating pipe to command $cmd\n") if $debug;
    die "Error while creating index: $!"
        unless (open($fh, "| $cmd >$vardir/.glimpse_output 2>&1")  and
                (print $fh $fileList)  and  close($fh));

    $fileList;
}


sub _ep_glimpse_matchline {
    my $self = shift; my $attr = shift;
    my $template = defined($attr->{'template'}) ?
        $attr->{'template'} : return undef;
    $self->print("Setting matchline template to $template\n")
        if $self->{'debug'};
    $self->{'line_template'} = $template;
    '';
}

sub _format_MATCHLINE {
    my $self = shift; my $f = shift;
    my $debug = $self->{'debug'};
    my $template = $self->{'line_template'};
    my $lines = $f->{'lines'};
    $self->print("MATCHLINE: f = $f, lines = $lines (", @$lines, ")\n",
                 "line_template = $template\n") if $debug;
    my $output = $self->_ep_list({'items' => $lines,
                                  'item' => 'l',
                                  'template' => $template});
    $self->print("output = ", (defined($output) ? $output : "undef"), "\n")
        if $debug;
    $output;
}

sub _ep_glimpse_search {
    my $self = shift; my $attr = shift;
    my $prefs = $self->_prefs($attr);
    my $vardir = $self->{'glimpse_config'}->{'vardir'};
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};
    my $start = ($cgi->param('start')  or  0);
    my $max = ($cgi->param('max')  or  $attr->{'max'}  or  20);
    my @opts = ($self->{'glimpse_config'}->{'glimpse_path'}, '-UOnbqy', '-L',
                "0:" . ($start+$max), '-H', $vardir);
    my $case_sensitive = $cgi->param('opt_case_sensitive') ? 1 : 0;
    push(@opts, '-i') unless $case_sensitive;
    my $word_boundary = $cgi->param('word_boundary') ? 1 : 0;
    push(@opts, '-w') if $word_boundary;
    my $whole_file = $cgi->param('opt_whole_file') ? 1 : 0;
    push(@opts, '-W') unless $whole_file;
    my $opt_regex = $cgi->param('opt_regex') ? 1 : 0;
    push(@opts, $opt_regex ? '-e' : '-k');
    my $opt_or = $cgi->param('opt_or') ? 1 : 0;

    # Now for the hard part: Split the search string into words
    my $search = $cgi->param('search');
    $self->{'link_opts'} = $self->{'env'}->{'PATH_INFO'} . "?"
        . join("&", "search=" . CGI->escape($search),
               "max=$max", "opt_case_sensitive=$case_sensitive",
               "word_boundary=$word_boundary", "opt_whole_file=$whole_file",
               "opt_regex=$opt_regex", "opt_or=$opt_or");
    my @words;
    while (length($search)) {
        $search =~ s/^\s+//s;
        if ($search =~ /^"/s) {
            if ($search =~ /"(.*?)"\s+(.*)/s) {
                push(@words, $1);
                $search = $2;
            } else {
                $search =~ s/^"//s;
                $search =~ s/"$//s;
                push(@words, $search);
                last;
            }
        } else {
            $search =~ s/^(\S+)//s;
            push(@words, $1) if $1;
        }
    }
    if (!@words) {
        my $language = $self->{'_ep_language'};
        my $msg;
        if ($language eq 'de') {
            $msg = "Keine Suchbegriffe gefunden";
        } else {
            $msg = "No search strings found";
        }
        $self->_ep_error({'type' => 'user', 'msg' => $msg});
    }
    my $sep = $opt_or ? ';' : ',';

    push(@opts, join($sep, @words));

    # First try using fork() and system() for security reasons.
    my $ok;
    my $tmpnam;
    my $fh = eval {
        my $infh = Symbol::gensym();
        my $outfh = Symbol::gensym();
        pipe ($infh, $outfh) or die "Failed to create pipe: $!";
        my $pid = fork();
        die "Failed to fork: $!" unless defined($pid);
        if (!$pid) {
            # This is the child
            close $infh;
            open(STDOUT, ">&=" . fileno($outfh))
                or die "Failed to reopen STDOUT: $!";
            exec @opts;
            exit 0;
        }
        close $outfh;
        $self->printf("Forked command %s\n", join(" ", @opts)) if $debug;
        $infh;
    } || eval {
        # Rats, doesn't work. :-( Run glimpse by storing the output in
        # a file and read from that file. We need to be aware of shell
        # metacharacters and the like.
        require POSIX;
        $tmpnam = "$vardir/" . POSIX::tmpnam();
        my $command = join(" ", map{ quotemeta $_ } @opts). " >$tmpnam";
        $self->print("Running command $command\n") if $debug;
        system $command or die "system() failed: $!";
        my $infh = Symbol::gensym();
        open($infh, "<$tmpnam")
            or die "Failed to open $tmpnam: $!";
        $infh;
    };
    $self->print("fh = $fh\n") if $debug;
    eval {
        my $blank_seen;
        my (@files, @lines, $file, $title, $lineNum, $byteOffset, $offsetStart,
            $offsetEnd);
        my $fileNum = $start;
        my $ignoreFiles = $start;
        while (defined(my $line = <$fh>)) {
            #$self->print("Glimpse output: $line") if $debug;
            if ($line =~ /^\s*$/) {
                $blank_seen = 1;
                if ($file) {
                    if ($ignoreFiles) {
                        --$ignoreFiles
                    } else {
                        push(@files, {'file' => $file,
                                      'fileNum' => ++$fileNum,
                                      'title' => $title,
                                      'lines' => [@lines]})
                    }
                }
                undef $file;
                undef $lineNum;
                @lines = ();
                #$self->print("Blank line detected\n") if $debug;
            } elsif ($blank_seen) {
                $blank_seen = 0;
                if ($line =~ /^(\S+)\s+(\S.*?)\s+$/) {
                    $file = $1;
                    $title = $2;
                    #$self->print("New file detected: $file, $title\n")
                    #    if $debug;
                } elsif ($line =~ /^(\S+)\:\s*$/) {
                    $file = $title = $1;
                } else {
                    $self->print("Cannot parse file line: $line") if $debug;
                }
            } elsif ($file) {
                if ($lineNum) {
                    push(@lines, {'line' => $line,
                                  'lineNum' => $lineNum,
                                  'byteOffset' => $byteOffset,
                                  'offsetStart' => $offsetStart,
                                  'offsetEnd' => $offsetEnd});
                    #$self->print("Match line detected: $lineNum, $line\n")
                    #    if $debug;
                    undef $lineNum;
                } elsif ($line =~ /^(\d+)\:\s+(\d+)\=\s+\@(\d+)\{(\d+)\}/) {
                    $lineNum = $1;
                    $byteOffset = $2;
                    $offsetStart = $3;
                    $offsetEnd = $4;
                } else {
                    $self->print("Cannot parse line: $line\n") if $debug;
                }
            } else {
                $self->print("Unexpected line: $line\n") if $debug;
            }
        }
        if ($file) {
            if ($ignoreFiles) {
                --$ignoreFiles
            } else {
                push(@files, {'file' => $file,
                              'fileNum' => ++$fileNum,
                              'title' => $title,
                              'lines' => [@lines]})
            }
        }
        $self->print("Found " . scalar(@files) . " files\n") if $debug;
        foreach my $file (@files) {
            my $url = $file->{'file'};
            $url =~ s/^\Q$prefs->{'rootdir'}\E//;
            $url =~ s/^\/+/\//;
            $file->{'url'} = $url;
        }
        $self->{'files'} = \@files;
        if (@files == $max) {
            $self->{'next'} = $start + $max;
        }
        $self->{'prev'} = $start ? $start - $max : -1;
    } unless $@;
    close $fh if $fh;
    undef $fh;
    unlink $tmpnam if $tmpnam;
    '';
}


1;


__END__

=pod

=head1 NAME

HTML::EP::Glimpse - A simple search engine using Glimpse


=head1 SYNOPSIS

  <!-- Put the following in your EP page: -->
  <!-- Load the Glimpse package: -->
  <ep-package name="HTML::EP::Glimpse">
  <!-- Run glimpse: -->
  <ep-glimpse-search>
  <!-- List the hits: -->
    <ep-list items=files item=f>
      <tr><td><a href="$f->url$">$f->title$</a></td>
    </ep-list>


=head1 DESCRIPTION

This is a simple search engine I wrote for the movie pages of a friend,
Anne Haasis.

It is based on HTML::EP, my embedded Perl system and Glimpse, the well
known indexing system, as a backend.


=head1 INSTALLATION

First of all, you have to install the latest version of HTML::EP, 0.20
or later, and it's prerequisites. Next you have to install this package,
HTML::EP::Glimpse. If you don't know how to install Perl packages, it's
fairly simple: Fetch the required archives from any CPAN mirror, for
example

  ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module/HTML

and then do, for example

  gzip -cd HTML-EP-0.20.tar.gz | tar xf -
  perl Makefile.PL
  make
  make test
  make install

It's even more simple, if you have the CPAN module available:

  perl -MCPAN -e shell
  install HTML::EP
  install HTML::EP::Glimpse

While running B<perl Makefile.PL> in the HTML::EP::Glimpse directory,
you'll be prompted some questions. These are explained in the
CONFIGURATION section below. See L<CONFIGURATION>.

Your web server must be ready for serving EP pages. See the HTML::EP
docs for details of the web server configuration. L<HTML::EP(3)>.


=head1 CONFIGURATION

The module is configured at installation time when running B<perl
Makefile.PL>. However, you can repeat the configuration at any
later time by running B<perl -MHTML::EP::Glimpse::Install -e Config>.

Configuration will create a module I<HTML::EP::Glimpse::Config>, which
holds a single hash ref with the following keys:

=over

=item install_html_files

A TRUE (yes) value means, that the HTML examples will be copied to
your web servers document root. This is recommended, unless you have
an existing installation with own modifications in the HTML files.
Of course you wouln't want to overwrite your own files.

=item html_base_dir

Base directory, where you put your HTML files to. The default is
F</home/httpd/html/Glimpse>, which is fine on a Red Hat Linux box.

=item vardir

A directory, where the web server is allowed to create files, in
particular your preferences and the Glimpse index. By default the
subdirectory F<admin/var> of the base directory is choosen.

=item httpd_user

The UID under which your web server is running CGI binaries. The
vardir must have read, execute and write permissions for this user.
The default is I<nobody>, which is fine on a Red Hat Linux box
again.

=item glimpse_path

=item glimpseindex_path

Path of the I<glimpse> and I<glimpseindex> binaries.

=back


=head2 The Preferences

All other settings are fixed via the Web browser. Assuming your base directory
is accessible via

  http://localhost/Glimpse/

point your browser to

  http://localhost/Glimpse/admin/index.ep

and enter the preferences page. The following items must be entered here:

=over

=item Web servers root directory

This is your web servers home directory, for example

  /home/httpd/html

on a Red Hat Linux box.

=item Directories being indexed

Usually you just put the value F</> here, because you want your whole
web server being indexed. However, if you want restrict the index to
some directories, enter them here. For example, if you have a manual
in F</manual> and want to index the manual directory only, then enter

  /manual

The directory names are relative to the servers root directory.

=item Directories being excluded

If you don't want your whole directory tree being indexed, you can
also exclude some directories. For example, there's not much sense
in indexing the Glimpse directory, so I usually enter

  /Glimpse

here.

=item Suffixes of files being indexed

Of course you don't want all files being indexed. For example, there's not
much sense in indexing GIF's or JPEG's. By default only files with the
extensions I<.htm> and I<.html> are indexed. If you want your EP files
being indexed as well, add a I<.ep>. Likewise you might want to add
I<.php> for PHP3 files or I<.txt> for text files.

=back


=head2 Running glimpseindex

As soon as you modified your preferences, you should create an index.
This is done by returning to the admin menu and calling the index
page.

The same procedure should be repeated each time you modify your HTML
files. If this is happening frequently, you might prefer using a cron
job, for example

  su - nobody -c "/usr/bin/glimpseindex -b -H $vardir -X"

with B<$vardir> being the vardir from above. Note that your job shouln't
run as root, unless you want to disable a manual recreation via the
web browser.


=head2 Configuring for multiple virtual servers or multiple directories

So far configuration is fine, but can you use multiple instances of
HTML::EP::Glimpse on one machine? Of course you can!

It is quite simple: Just copy the base directory to another location.
Then create a subdirectory F<admin/lib/HTML/EP/Glimpse> of the new
base directory. Create a new configuration by running

  cd $basedir/admin/lib/HTML/EP/Glimpse
  perl -MHTML::EP::Glimpse::Install -e Config Config.pm

That's it!


=head1 AUTHOR AND COPYRIGHT

This module is

    Copyright (C) 1998-1999	Jochen Wiedmann
                          	Am Eisteich 9
                          	72555 Metzingen
                          	Germany

                          	Phone: +49 7123 14887
                          	Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<DBI(3)>, L<CGI(3)>, L<HTML::Parser(3)>

=cut
