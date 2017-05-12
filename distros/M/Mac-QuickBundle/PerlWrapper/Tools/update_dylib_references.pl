#!/usr/bin/perl

# -------------------------------------------------------------------------
# update_dylib_references.pl: PerlWrapper dylib references helper
# -------------------------------------------------------------------------
# If you bundle dynamic libraries with your application, the references
# inside these libraries and the XS bundles using them should be changed
# to relative paths pointing inside the library. This tool helps you
# to do that.
# -------------------------------------------------------------------------
# $Id: update_dylib_references.pl 5 2004-06-11 23:45:52Z crenz $
# Copyright (C) 2004 Christian Renz <crenz@web42.com>.
# All rights reserved.

use File::Find;

my $quiet = @ARGV && $ARGV[0] eq '-q';

my $install_name_tool = 'install_name_tool';
my $otool = 'otool';

my $dir_dylib = '../Libraries/';
my $dir_perllib = '../Perl-Libraries/';
my $dir_executables = '../../MacOS/';

my $prefix_dylib = '@executable_path/../Resources/Libraries';

my @dylibs = ();
my %dylib_refs = ();

sub log_msg {
    print @_ unless $quiet;
}

sub wanted_dylibs {
    next unless /\.dylib$/;
    next unless -r && -f;
    
    my $out = `$otool -L $_`;
    my @libs = ($out =~ m|^\s+(/[^ ]+)|mg);
    
    foreach my $l (@libs) {
        push @{$dylib_refs{$l}}, $_;
    }

    s/^$dir_dylib//;    
    push @dylibs, $_;
}

sub wanted_dylib_refs {
    next unless /\.bundle$/;
    next unless -r && -f;

    my $out = `$otool -L $_`;
    my @libs = ($out =~ m|^\s+(/[^ ]+)|mg);
    
    foreach my $l (@libs) {
        push @{$dylib_refs{$l}}, $_;
    }
}

sub wanted_executable_refs {
    next unless -x;
    next unless -r && -f;

    my $out = `$otool -L $_`;
    my @libs = ($out =~ m|^\s+(/[^ ]+)|mg);
    
    foreach my $l (@libs) {
        push @{$dylib_refs{$l}}, $_;
    }
}

log_msg("\nSearching for bundled dylibs in $dir_dylib ...\n");
find({wanted => \&wanted_dylibs, no_chdir => 1}, $dir_dylib);
log_msg(scalar @dylibs, " dylibs found.\n");

log_msg("Searching for XS bundles in $dir_perllib ...\n");
find({wanted => \&wanted_dylib_refs, no_chdir => 1}, $dir_perllib);

log_msg("Searching for executables in $dir_executables ...\n");
find({wanted => \&wanted_executable_refs, no_chdir => 1}, $dir_executables);
log_msg(scalar keys %dylib_refs, " different dylibs references found.\n");

log_msg("Changing references...\n");
my $c = 0;
foreach my $ref (sort keys %dylib_refs) {
    my ($newref) = grep { $ref =~ /$_$/ } @dylibs;
    
    unless ($newref) {
        log_msg("References to $ref remain unchanged\n");
        next;
    }
    
    log_msg("Changing '$ref'\n      to '$prefix_dylib/$newref'\n");
    foreach my $lib (@{$dylib_refs{$ref}}) {
        log_msg("      in $lib\n");
        `$install_name_tool -change $ref $prefix_dylib/$newref $lib`;
        $c++;
    }
}
log_msg("$c references changed.\n\n");
    
# - eot -------------------------------------------------------------------

