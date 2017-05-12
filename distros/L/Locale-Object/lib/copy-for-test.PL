#!/usr/bin/perl

use warnings;
use strict;

use File::Copy;

my @dirs = ('blib/', 'lib/', 'Locale/', 'Object');

my $where = '';

foreach my $dir (@dirs)
{
  $where = $where . $dir;

  mkdir $where;
  die "Couldn't make $where directory: $!" unless $! =~ /File exists/;
}

copy('lib/Locale/Object/locale.db', 'blib/lib/Locale/Object/locale.db')
  or die "Couldn't copy locale database: $!";

=head1 NAME

copy-for-test.PL - ensure ./Build test works

=head1 DESCRIPTION

The L<Locale::Object> modules use a L<DBD::SQLite> database of information
that they consult, which is created at build time. That file needs to be in the
same directory as L<Locale::Object::DB>.

Because L<Module::Build> won't copy non-Perl files into the C<blib> directory
when you run the tests, this script copies the DB into 
C<blib/lib/Locale/Object/> (creating those directories, if need be) when you do
C<./Build>. That way, L<Locale::Object::DB> will be able to find it when you do
a C<./Build test>.

There should be no need to run this script yourself.

=cut
