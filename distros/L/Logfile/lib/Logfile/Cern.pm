#!/usr/local/ls6/bin/perl
#                              -*- Mode: Perl -*- 
# Cern.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Mar 25 09:59:37 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu May 23 15:09:04 1996
# Language        : Perl
# Update Count    : 11
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: Cern.pm,v $
# Revision 0.1.1.4  1997/01/20 09:07:30  pfeifer
# patch15: -w fix by Hugo van der Sanden.
#
# Revision 0.1.1.3  1996/05/23 14:16:28  pfeifer
# patch11: Removed site specific stuff. Added limit to level 3 for urls.
#
# Revision 0.1.1.2  1996/03/27 14:41:35  pfeifer
# patch6: Renamed Tools::Logfile to Logfile.
#
# Revision 0.1.1.1  1996/03/26 13:50:04  pfeifer
# patch2: Renamed module to Logfile and Logfile.pm to
# patch2: Logfile/Base.pm
#
# Revision 0.1  1996/03/25 10:52:16  pfeifer
# First public version.
#
# 

package Logfile::Cern;
require Logfile::Base;

@ISA = qw ( Logfile::Base ) ;

sub next {
    my $self = shift;
    my $fh = $self->{Fh};

    *S = $fh;
    my ($line,$host,$user,$pass,$rest,$date,$req,$code,$bytes);
    while (defined ($line = <S>)) {
        ($host,$user,$pass,$rest) = split ' ', $line, 4;
        next unless $rest;
        ($rest =~ s!\[([^\]]+)\]\s*!!) && ($date = $1);
        ($rest =~ s!\"([^\"]+)\"\s*!!) && ($req = (split ' ', $1)[1]);
        ($code, $bytes) = split ' ', $rest;
        last if $date;
    }
    return undef unless $date;
    # print "($host,$user,$pass,$date,$req,$code,$bytes)\n";
    #print $line unless $req;
    Logfile::Base::Record->new(Host  => $host,
                          Date  => $date,
                          File  => $req,
                          Bytes => $bytes,
                          );
}

sub norm {
    my ($self, $key, $val) = @_;

    if ($key eq File) {
        $val =~ s/\?.*//;           # remove that !!!
        $val = '/' unless $val;
        $val =~ s/\.\w+$//;
        $val =~ s!%([\da-f][\da-f])!chr(hex($1))!eig;
        $val =~ s!~(\w+)/.*!~$1!;
        # proxy
        $val =~ s!^((http|ftp|wais)://[^/]+)/.*!$1!;
        # confine to depth 3
        my @val = split /\//, $val;
        $#val = 2 if $#val > 2;
        #printf STDERR "$val => %s\n", join('/', @val) || '/';
        join('/', @val) || '/';
    } elsif ($key eq Bytes) {
        $val =~ s/\D.*//;
    } else {
        $val;
    }
}

1;
