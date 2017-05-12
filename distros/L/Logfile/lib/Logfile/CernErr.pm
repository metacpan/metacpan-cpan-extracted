#                              -*- Mode: Perl -*- 
# CernErr.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Mar 25 09:59:37 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue Apr  2 09:55:07 1996
# Language        : Perl
# Update Count    : 29
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: CernErr.pm,v $
# Revision 0.1.1.1  1996/04/02 08:27:31  pfeifer
# patch9: Added cern error logging.
#

package Logfile::CernErr;
require Logfile::Base;

@ISA = qw ( Logfile::Base ) ;

sub next {
    my $self = shift;
    my $fh = $self->{Fh};

    *S = $fh;
    my $line = <S>;
    my ($date, $req, $host, $referer) = ('') x 4;

    $date = $1 if ($line =~ s!^\[([^\]]+)\]\s*!!);
    $req  = $1 if ($line =~ s!, req: (.*) HTTP/1.0!!);
    ($host, $referer) = ($1, $3) if
        ($line =~ s!\[host: (\S*)( referer: (\S*))?\]!!);
    $line =~ s!\[OK-GATEWAY\]!!;
    $line =~ s!\[OK\]!!;
    $line =~ s!^\s+!!;
    $line =~ s!\s+$!!;
    Logfile::Base::Record->new(Host    => $host,
                               Date    => $date,
                               Error   => $line,
                               Referer => $referer,
                               File    => $req,
                               );
}

sub norm {
    my ($self, $key, $val) = @_;

    if ($key eq File or $key eq Referer) {
        $val =~ s/\?.*//;           # remove that !!!
        $val =~ s/GET //;
        $val = '/' unless $val;
        $val =~ s/\.\w+$//;
        $val =~ s!%([\da-f][\da-f])!chr(hex($1))!eig;
        $val =~ s!~(\w+)/.*!~$1!;
        # proxy
        $val =~ s!^((http|ftp|wais)://[^/]+)/.*!$1!;
        # specific
        $val =~ s!icons/.*!icons/*!;
        $val =~ s!freeWAIS-sf/.*!freeWAIS-sf/*!;
        $val;
    } elsif ($key eq Bytes) {
        $val =~ s/\D.*//;
    } else {
        $val;
    }
}
1;
