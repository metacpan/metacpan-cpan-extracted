#!/usr/bin/perl 

# Created: 10/21/2011 02:37:36 PM
# Last Edit: 2013 Apr 02, 09:16:31 PM
# $Id$

=head1 NAME

grade_dic.pl - Grade only dic letters written

=head1 VERSION

Version 0.01

=cut

use strict;
use warnings;
# use lib qw( /var/www/cgi-bin/target/lib );
use lib qw( lib );

use YAML qw/LoadFile Dump/;

=head1 SYNOPSIS

perl script_files/grade_name_file.pl -l GL00016 -r 5 -x rueda | sponge ../001/GL00016/homework/5.yaml

=cut

use Grades;

my $script = Grades::Script->new_with_options;
my $leagueid = $script->league;
( my $id = $leagueid ) =~ s/^([[:alpha:]]+[[:digit:]]+).*$/$1/;
my $round = $script->round;
my $exercise = $script->exercise;
my $one = $script->one;
my $two = $script->two;

my $l = League->new( id => $id );
my $m = $l->members;
my %m = map { $_->{id} => $_ } @$m;
my $g = Grades->new({ league => $l });

=head1 DESCRIPTION

Converts yaml file, homework/r.yaml of grades keyed on names to Homework type file. Absent keys are entered as undef. Create r.yaml with DumpFile 'r.yaml', { points =>  { map { $m{$_}->{name} => { letters => undef } } keys %m } }

=cut

my $hwdir = $g->hwdir;
my $hw_named = $l->inspect( "$hwdir/$round.yaml" );
$exercise ||= $hw_named->{exercise};
$one ||= $hw_named->{cutpoints}->{one};
$two ||= $hw_named->{cutpoints}->{two};

my %grades = map { my $name = $m{$_}->{name};
		$_ => $hw_named->{points}->{$name}->{letters} } keys %m;
my $points = $hw_named->{points};

print Dump { exercise => $exercise, grade => \%grades, points => $points,
		cutpoints => { one => $one, two => $two } };

=head1 AUTHOR

Dr Bean C<< <drbean at cpan, then a dot, (.), and org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of grade_dic.pl

# vim: set ts=8 sts=4 sw=4 noet:
