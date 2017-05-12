#!/usr/bin/perl

use strict;
use warnings;

=pod

AcDbLine
 10
280.969423
 20
54.172283
 30
0.0
 11
281.362783
 21
47.846306
 31
0.0

=cut

my @data = (<STDIN>);

my $count = 0;

while (@data)
{
    my $line = shift @data;
    if ($line =~ /^AcDbLine/)
    {
        my $entity;

        shift @data;
        $entity->{points}->[0]->[0] = shift @data;
        shift @data;
        $entity->{points}->[0]->[1] = shift @data;
        shift @data;
        $entity->{points}->[0]->[2] = shift @data;

        shift @data;
        $entity->{points}->[1]->[0] = shift @data;
        shift @data;
        $entity->{points}->[1]->[1] = shift @data;
        shift @data;
        $entity->{points}->[1]->[2] = shift @data;

        $entity->{points}->[0]->[0] =~ s/[^0-9.-]//g;
        $entity->{points}->[0]->[1] =~ s/[^0-9.-]//g;
        $entity->{points}->[0]->[2] =~ s/[^0-9.-]//g;

        $entity->{points}->[1]->[0] =~ s/[^0-9.-]//g;
        $entity->{points}->[1]->[1] =~ s/[^0-9.-]//g;
        $entity->{points}->[1]->[2] =~ s/[^0-9.-]//g;
        
        $entity->{copyright} = ['Bruno Postle <bruno@postle.net>'];
        $entity->{license}   = 'http://creativecommons.org/licenses/sa/1.0/';
        $entity->{type}      = 'line';
        $entity->{units}     = 'mm';
        $entity->{version}   = 'draft1';

        use YAML;
        YAML::DumpFile ("$count.yml" , $entity);

        $count++;
    }
}
