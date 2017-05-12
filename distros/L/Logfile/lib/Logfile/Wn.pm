#                              -*- Mode: Perl -*- 
# Wn.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed May 22 13:17:07 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri May 29 15:29:14 1998
# Language        : CPerl
# Update Count    : 14
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: Wn.pm,v $
# Revision 0.1.1.1  1996/06/04 14:35:31  pfeifer
# patch13: Support for the WN http server.
#
# Revision 1.1  1996/05/23 13:46:05  pfeifer
# Initial revision
#
# 
package Logfile::Wn;
require Logfile::Base;

@ISA = qw ( Logfile::Base ) ;

sub next {
    my $self = shift;
    my $fh = $self->{Fh};
    my ($host, $bytes, $error, $code, $dummy, $date, $request, $client, $referer)
      = ('') x 9;
    *S = $fh;
    while (1) {
      my $line = <S>;
      return undef unless defined $line;
      if ($line =~ s/(\S+)\s+//) {
        $host = $1;
      } else {
        next;
      }
      unless ($line =~ s/(\S+)\s+(\S+)\s+//) {
        next;
      }
      if ($line =~ s/\[(.*?)\]\s+//) {
      $date = $1;
    } else {
      next;
    }
      if ($line =~ s/\"(.*?)\"\s+//) {
        $request = $1;
        $request =~ s/^(GET|HEAD) //;
        $request =~ s: HTTP/1.0$::;
      } else {
        next
      }
      if ($line =~ s/(\S+)\s+(\d+)\s+//) {
        $code  = $1;
        $bytes = $2;
      }
      if ($line =~ s/\<(.*?)\>\s+//) {
        $error = $1;
      } else {
        next
      }
      if ($line =~ s/\<(.*?)\>\s+//) {
        $client = $1;
      } else {
        next
      }
      if ($line =~ s/\<(.*?)\>\s+//) {
        $referer = $1;
      } else {
        next
      }
      return(Logfile::Base::Record->new(Host    => $host,
                                        Date    => $date,
                                        Error   => $error,
                                        Client  => $client,
                                        Referer => $referer,
                                        File    => $request,
                                        Bytes   => $bytes||0,
                                       )
            );
  }
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
        $val;
    } elsif ($key eq Bytes) {
        $val =~ s/\D.*//;
    } elsif ($key eq Error) {
      $val =~ s:^\s*\(\d+/\d+\)\s+::;
      $val = substr($val,0,$Logfile::MAXWIDTH);
      $val;
    } else {
      $val;
    }
}

1;
