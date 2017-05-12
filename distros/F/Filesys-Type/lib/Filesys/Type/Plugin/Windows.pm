package Filesys::Type::Plugin::Windows;
use strict;

our $VERSION = 0.02;

sub new {
    my $pkg = shift;

    return undef unless $^O =~ /win/i;

    eval {
	require Win32;
	require Cwd;
	require File::Spec;
    };
    return undef if $@;

    bless {}, $pkg;
}

our ($dest,$err);

sub fstype {
    my ($self,$path) = @_;

    my $cur = Cwd::cwd;

    eval {
        my ($vol,$dir,$file) = File::Spec->splitpath($path);
	$dest = File::Spec->catpath($vol,$dir);
    };
    ($err = $@) && return undef;
    chdir $dest or return undef;
    my $fstype = Win32::FsType();
    chdir $cur;
    $fstype;
}

sub diagnose {
    $err . "\nWorking directory: ".$dest;
}


1;
