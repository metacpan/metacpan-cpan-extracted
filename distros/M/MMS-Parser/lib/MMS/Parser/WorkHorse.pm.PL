# vim: filetype=perl :

use strict;
use warnings;
use Parse::RecDescent;
use Path::Class qw( file );
use File::Slurp qw( read_file write_file );

my $target = shift;
my @grammars = qw( WSP MMS );

my $dir = file(__FILE__)->dir();
my @grammar_files = map { $dir->file("gr-$_.prd")->stringify() } @grammars;
unshift @grammar_files, $dir->file("g-startup.pl")->stringify();
$target = $dir->file('WorkHorse.pm')->stringify()
   unless $target =~ /WorkHorse/;

# Check if the precompiled module has been already compiled and is
# up to date
if (-e $target) {
   my $module_time = get_modification_time($target);
   my $modified    =
     grep { get_modification_time($_) >= $module_time; } @grammar_files;
   exit(0) unless $modified;
} ## end if (-e $target)

my $grammar = join '', map { read_file $_ } @grammar_files;
$Parse::RecDescent::skip = '';
Parse::RecDescent->Precompile($grammar, "MMS::Parser::WorkHorse");
write_file $target, read_file('WorkHorse.pm'), "\n";
unlink 'WorkHorse.pm';

sub get_modification_time { return (stat($_[0]))[9] }
