# -*- perl -*-

use strict;

my $script = <<'SCRIPT';
~startperl~ 



# $Id: XText.PL,v 1.1 1998/11/18 11:23:29 msh Exp msh $
#
# (C) 1998 Mike Shoyher
#
use strict;
my $n=0;
for(<STDIN>){
$n++;
extract($_);

}

sub extract($)
{
my $s=shift;
if ($s=~/^(.*)(\'.+\').*$/){
  outString($2);
  extract($1)
}

if ($s=~/^(.*)(\".+\").*$/){
  outString($2);
  extract($1)
}
}

sub outString($)
{
my $s=shift;
$s=~tr/\'/\"/;
print "#line $n\n";
print "msgid $s\nmsgstr \"\"\n\n";
}

=head1 NAME

XText - strings extractor for perl

=head1 SYNOPSIS

  XText < <perl script> > <messages.po>



=head1 DESCRIPTION

 
Minimal version of strings extractor (just for testing)

=head1 BUGS

Must be completely rewritten.

=cut

SCRIPT


use Config;

my $file = __FILE__; $file =~ s/\.PL$//;

$script =~ s/\~(\w+)\~/$Config{$1}/eg;
if (!(open(FILE, ">$file"))  ||
    !(print FILE $script)  ||
    !(close(FILE))) {
    die "Error while writing $file: $!\n";
}
print "Extracted $file from ",__FILE__," with variable substitutions.\n";
