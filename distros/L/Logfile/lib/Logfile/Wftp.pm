#!/usr/local/ls6/bin/perl
#                              -*- Mode: Perl -*- 
# Wftp.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Mar 25 09:59:37 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue Mar 26 14:26:37 1996
# Language        : Perl
# Update Count    : 14
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: Wftp.pm,v $
# Revision 0.1.1.2  1996/03/27 14:41:39  pfeifer
# patch6: Renamed Tools::Logfile to Logfile.
#
# Revision 0.1.1.1  1996/03/26 13:50:10  pfeifer
# patch2: Renamed module to Logfile and Logfile.pm to
# patch2: Logfile/Base.pm
#
# Revision 0.1  1996/03/25 10:52:20  pfeifer
# First public version.
#
# 

package Logfile::Wftp;
require Logfile::Base;

@ISA = qw ( Logfile::Base ) ;

sub next {
    my $self = shift;
    my $fh = $self->{Fh};
    my ($host,$date,$file,$bytes);
    *S = $fh;
    $line = <S>;
    $date = substr($line,0,24);
    $line = substr($line,24);
    ($host,$bytes,$file) = (split ' ', $line)[1,2,3];
    #print "$date,$host,$bytes,$file\n";
    Logfile::Base::Record->new(Host  => $host,
                               Date  => $date,
                               File  => $file,
                               Bytes => $bytes,
                               );
}

sub norm {
    my ($self, $key, $val) = @_;

    if ($key eq File) {
        $val = join('/', (split /\//, $val)[2,3]);
    }
    $val;
}

1;
