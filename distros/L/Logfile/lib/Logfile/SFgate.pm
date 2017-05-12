#                              -*- Mode: Perl -*- 
# SFgate.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Mar 25 09:59:37 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri Jun 12 10:09:26 1998
# Language        : Perl
# Update Count    : 35
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: SFgate.pm,v $
# Revision 0.1.1.1  1996/04/01 09:36:21  pfeifer
# patch8: New. Only extracts databases currently.
#

package Logfile::SFgate;
require Logfile::Base;
use strict;
use vars qw(@ISA);

@ISA = qw ( Logfile::Base ) ;


sub next {
    my $self = shift;
    my $fh = $self->{Fh};
    my ($date, $Hour, @Databases, $Queries);
    unless (@Databases) {
      *S = $fh;
    LINE: while (1) {
        return undef if (eof(S));
        my $line = <S>;
        $date = substr($line,0,14);
        ($Hour) = ($line =~ /\s(\d\d):\d\d/);
        next LINE if length($line) < 24;
        my ($pid, $host, $request) = split ' ', substr($line,24);
        my $field;
        for $field (split /\&/, $request) {
          my ($field, $value) = split /=/, $field;
          if ($field eq 'database') {
            push (@Databases, $value);
          }
        }
        last LINE if @Databases;
      }
      $Queries = 1/@Databases;
      
    }
    Logfile::Base::Record->new(Database   => shift @Databases,
                               Queries    => $Queries,
                               Date       => $date,
                               Hour       => $Hour,
                              );
}

sub norm {
    my ($self, $key, $val) = @_;

    if ($key eq 'Database') {
        (split '/', $val)[-1];
    } else {
        $val;
    }
}

1;
