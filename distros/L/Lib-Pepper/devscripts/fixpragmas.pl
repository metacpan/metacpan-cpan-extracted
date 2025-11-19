#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use v5.42;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 0.4;
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---

# PAGECAMEL  (C) 2008-2020 Rene Schickbauer
# Developed under Artistic license


print "Searching files...\n";
my @files = (find_pm('lib'), find_pm('devscripts'), find_pm('examples'));

print "Changing files:\n";
foreach my $file (@files) {
    my $inserted = 0;
    print "Editing $file...\n";

    my @lines;
    open(my $ifh, "<", $file) or die($ERRNO);
    @lines = <$ifh>;
    close $ifh;

    open(my $ofh, ">", $file) or die($ERRNO);
    foreach my $line (@lines) {
        if($line =~ /^use\ +(.+)\;/) {
            my $pragma = $1;
            my $skip = 0;
            if($pragma =~ /(strict|warnings|English|mro|diagnostics|Carp|Fatal|Array\:\:Contains|autodie|utf8|Encode|Data\:\:Dumper|Helpers\:\:UTF|builtin|Data\:\:Printer)/ && $pragma !~ /Digest/) {
                # Remove this (old) lines
                $skip = 1;
            }
            if($pragma =~ /(5.\d+)/ && $pragma !~ /Digest/) {
                # Always update the required perl version
                $skip = 1;
            }

            if(($file =~ /Helpers\/UTF\.pm$/ || $file =~ /LetsEncrypt\.pm/)&& $pragma =~ /Encode/) {
                # Don't skip this one instance, this is the only place that loads the Encode module
                $skip = 0;
            }


            if($skip) {
                next;
            }
        }
        if($line =~ /^no\ if.*experimental\:\:smartmatch/) {
            next;
        }
        if($line =~ /^(our|my) \$VERSION/) {
            next;
        }

        # Handle sub "signatures"
        if($line =~ /^use\ feature\ \'signatures\'/ || $line =~ /^no\ warnings\ .*experimental\:\:signatures/) {
            next;
        }
        # Handle the new "builtin" stuff
        if($line =~ /^no\ warnings\ .*experimental\:\:builtin/ || $line =~ /^use\ builtin/) {
            next;
        }

        if($line =~ /^\#\-\-\-AUTOPRAGMA/) {
           next;
        }

        print $ofh $line;

        if($inserted) {
            # Already inserted the pragmas
            next;
        }
        if($line =~ /^package\ / || $line =~ /^\#\!/) {
            print $ofh "#---AUTOPRAGMASTART---\n";
            print $ofh "use v5.42;\n";
            print $ofh "use strict;\n";
            print $ofh "use diagnostics;\n";
            print $ofh "use mro 'c3';\n";
            print $ofh "use English;\n";
            print $ofh "use Carp qw[carp croak confess cluck longmess shortmess];\n";
            print $ofh "our \$VERSION = 0.4;\n";
            print $ofh "use autodie qw( close );\n";
            print $ofh "use Array::Contains;\n";
            print $ofh "use utf8;\n";
            print $ofh "use Data::Dumper;\n";
            print $ofh "use Data::Printer;\n";
            print $ofh "#---AUTOPRAGMAEND---\n";
            $inserted = 1;
        }
    }
    close $ofh;
}
print "Done.\n";
exit(0);



sub find_pm($workDir) {
    my @files;
    opendir(my $dfh, $workDir) or die($ERRNO);
    while((my $fname = readdir($dfh))) {
        next if($fname eq "." || $fname eq ".." || $fname eq ".hg");
        $fname = $workDir . "/" . $fname;
        if(-d $fname) {
            push @files, find_pm($fname);
        } elsif($fname =~ /\.p[lm]$/i && -f $fname) {
            push @files, $fname;
        }
    }
    closedir($dfh);
    return @files;
}
