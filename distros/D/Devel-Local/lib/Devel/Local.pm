use strict; use warnings;
package Devel::Local;
our $VERSION = '0.22';

use Cwd 'abs_path';
use Config;
use File::Spec;
use File::Find;

my $path_sep = $Config::Config{'path_sep'};

sub import {
    my ($package, @args) = @_;
    unshift @INC, get_path('PERL5LIB', @args);
    $ENV{PATH} = join $path_sep, get_path('PATH', @args);
}

sub print_path {
    my ($name, @args) = @_;
    my @path = get_path($name, @args);
    if (@path) {
        if (not $ENV{PERL_DEVEL_LOCAL_QUIET}) {
            warn "${name}:\n";
            for (@path) {
                warn "    $_\n";
            }
            warn "\n";
        }
        print join $path_sep, @path;
    }
}

sub get_path {
    my ($name, @args) = @_;
    my $cmd = '';
    if (not @args) {
        @args = get_config_file();
    }
    elsif (@args == 1 and $args[0] =~ /^[\!\?]$/) {
        $cmd = shift @args;
    }
    my (@left, @right, $found);
    map {
        if ($_ eq '|') {
            $found = 1;
        }
        elsif ($found) {
            unshift @left, $_;
        }
        else {
            unshift @right, $_;
        }
    } reverse(($ENV{$name})
        ? grep($_, split($path_sep, $ENV{$name}, -1))
        : ()
    );
    if ($cmd eq '!') {
        return @right;
    }
    if ($cmd eq '?') {
        return scalar(@left) ? (@left, '|', @right) : (@right);
    }

    my @locals = get_locals(@args);
    for my $dir (reverse @locals) {
        add_to_path($name, $dir, \@left);
    }
    return scalar(@left) ? (@left, '|', @right) : (@right);
}

sub get_config_file {
    my $home_file = File::Spec->catfile($ENV{HOME}, '.perl-devel-local');
    my $dot_file = File::Spec->catfile(File::Spec->curdir, 'devel-local');
    return
        $ENV{PERL_DEVEL_LOCAL} ? $ENV{PERL_DEVEL_LOCAL} :
        (-f $dot_file) ? $dot_file :
        ($ENV{HOME} && -f $home_file) ? $home_file :
        ();
}

sub get_locals {
    return map {
        s!([\\/])/+!$1!g;
        s!(.)/$!$1!;
        abs_path($_);
    } grep {
        s!^~/!$ENV{HOME}/! if defined $ENV{HOME};
        -d $_;
    } map {
        -f($_) ? map { /\*/ ? glob($_) : $_ } read_config($_) :
        /\*/ ? glob($_) :
        ($_);
    } @_;
}

sub add_to_path {
    my ($name, $dir, $path) = @_;
    my $bin = File::Spec->catfile($dir, 'bin');
    my $lib = File::Spec->catfile($dir, 'lib');
    my $blib = File::Spec->catfile($dir, 'blib');
    my @add;
    if ($name eq 'PERL5LIB' and -d $lib) {
        push @add, $lib;
        if (has_xs($dir)) {
            push @add, $blib;
        }
    }
    elsif ($name eq 'PATH' and -d $bin) {
        push @add, $bin;
    }
    return unless @add;
    @$path = (
        @add,
        grep {
            not(
                ($name eq 'PERL5LIB' and ($_ eq $lib or $_ eq $blib)) or
                ($name eq 'PATH' and ($_ eq $bin))
            )
        } @$path
    );
    return;
}

sub has_xs {
    my $dir = shift;
    my @xs;
    File::Find::find sub {
        push @xs, $_ if /\.xs$/;
    }, $dir;
    return scalar @xs;
}

sub read_config {
    my ($file) = @_;
    return () unless $file and -f $file;
    open my $f, $file or die "Can't open $file for input";
    my @lines;
    while (my $line = <$f>) {
        chomp $line;
        last unless $line =~ /\S/;
        next if $line =~ /^\s*#/;
        $line =~ s/^\s*(.*?)\s*/$1/;
        push @lines, $line;
    }
    return @lines;
}

1;
