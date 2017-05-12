package Devel::CoreStack;

require 5.002;

$VERSION = substr q$Revision: 1.3 $, 10;

# $Id: CoreStack.pm,v 1.3 1996/07/04 20:33:17 timbo Exp $ 
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
# (c)1996 Tim Bunce. Modified by Tim Bunce.
#
# May be used under the same terms as perl itself.
#
# $Log: CoreStack.pm,v $
# Revision 1.3  1996/07/04  20:33:17  timbo
# *** empty log message ***
#
# Revision 1.2  1996/07/04  20:17:55  timbo
# Major reorg into functions. Added path and Exporter etc.
#
# Revision 1.1  1996/07/02 17:49:16  descarte
# Initial revision
#
#
# Use as:
#
#     perl -MDevel::CoreStack -e 'stack'

=head1 NAME

Devel::CoreStack - try to generate a stack dump from a core file

=head1 SYNOPSIS

  perl -MDevel::CoreStack -e 'stack'

  perl -MDevel::CoreStack -e 'stack("../myperl", "./mycore", "debugger")'

=head1 DESCRIPTION

This module attempts to generate a stack dump from a core file by
locating the best available debugger (if any) and running it with
the appropriate arguments and command script.

=cut

use Config;
use Exporter;
use vars qw($Verbose);

@ISA = qw(Exporter);
@EXPORT = qw(stack);

use strict;

$Verbose = 0;

my @path = split(/:/, $ENV{PATH});
foreach(@path) { $_ = "." if $_ eq '' }

# throw in a few more paths for good measure
push @path, qw(
	/usr/bin
	/usr/local/bin
	/opt/gnu/bin
	/usr/ccs/bin
	/
);


# List of debuggers in weight order of goodness

my @dbg_names = qw(
	gdb
	dbx
	adb
	kadb
);

# Hash of debugger characteristics

my %dbg_specs = (

    gdb  => {	script => 'bt',
	    },
    dbx  => {	script => 'where',
	    },
    adb  => {	script => '$c',
	    },
    kadb => {	script => '$c',
	    },
);



sub find_bin {
    my ($name, $dirs) = @_;
    return $name if $name =~ m:/: and -e $name; # is already a path
    $dirs ||= \@path;
    my $dir;
    foreach $dir ( @$dirs ) {
	return "$dir/$name" if -e "$dir/$name";
    }
    warn "Unable to find $name in @$dirs\n" if $Verbose;
    return '';
}


sub pick_dbg {
    warn "Looking for one of @dbg_names to use...\n" if $Verbose;
    my $dbg_name;
    foreach $dbg_name ( @dbg_names ) {
	return $dbg_name if find_bin($dbg_name);
    }
    return '';
}


sub run_dbg {
    my ($cmd, $args, $script, $filter) = @_;
    my @args = map { '"'.$_.'"' } @$args;;

    my $popen = "$cmd @args";
    $popen .= " | $filter" if $filter;

    print "Executing $popen ($script)...\n";
    open(DEBUGGER, "| $popen") || die "popen $popen: $!";
    print DEBUGGER $script,"\n" if defined $script;
    my $status = close DEBUGGER;
    print "\n";
    return $status;
}


sub stack {
    my $perl     = shift || 'perl';
    my $core     = shift || 'core';
    my $dbg_name = shift || pick_dbg()   || die "Unable to find a debugger\n";

    my $dbg_path = find_bin($dbg_name)   || die "Unable to find $dbg_name\n";
    my $dbg_spec = $dbg_specs{$dbg_name} || die "Unknown debugger $dbg_name\n";;
    $perl = find_bin($perl) || $Config{perlpath};

    my $dbg_script = $dbg_spec->{script};
    my $dbg_filter = $dbg_spec->{filter} || '';

    return run_dbg($dbg_path, [ $perl, $core ], $dbg_script, $dbg_filter);
}

1;

