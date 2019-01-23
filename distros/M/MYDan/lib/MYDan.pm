package MYDan;

use strict;
use warnings;

=head1 NAME

MYDan - A suite of cluster administration tools and platforms

http://www.mydan.org

=cut

our $VERSION = '0.1.56';
our $PATH;

require 5.000;
require Exporter;
our @EXPORT_OK = qw( $PATH );
our @ISA = qw(Exporter);
use FindBin qw( $RealBin );

BEGIN{
   my @path;
   unless( $PATH = $ENV{MYDanPATH} )
   {
       for( split /\//, $RealBin )
       {
           push @path, $_;
           last if $_ eq 'mydan';
       }
       die 'nofind MYDanPATH' unless @path;
       $ENV{MYDanPATH} = $PATH = join '/', @path;
   }
};

=head1 MODULES

=head3 Node

A cluster information management platform

 MYDan::Node
 MYDan::Node::Range
 MYDan::Node::KeySet
 MYDan::Node::Integer
 MYDan::Node::Cache
 MYDan::Node::Call
 MYDan::Node::DBI::Cache
 MYDan::Node::DBI::Root

a agent

 Agent
 
=head3 API

platform api

 MYDan::API


=head1 AUTHOR

Lijinfeng, C<< <lijinfeng2011 at github.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 lijinfeng2011.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1;
