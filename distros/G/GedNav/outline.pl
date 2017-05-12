#!/usr/local/bin/perl

use CGI;
use Data::Dumper;
use File::Basename;
use Roman;

use strict;

use GedNav::Menu;
use GedNav;

##  This script is provided as an example.
##  It doesn't wrap lines or paginate, but you get what you pay for...  :)

my $filename = shift || 'royal92';
my $indicode = shift || 'I52';

my $dataset = new GedNav($filename);

my $primary = $dataset->get_indi($indicode);

printf "Descendant Tree: %s\n\n", $primary->name_normal;

print &do_indi($primary, 0, basename($primary->dataset));

print "\n\n";

exit;

sub do_indi
{
   my $indi = shift;
   my $depth = shift;
   my $dataset = shift;
   my $label = shift;

   my $html = '';

   $html .= sprintf "%s%s%s -- ",
	'. . ' x $depth,
	($label) ? "$$label. " : '',
	$indi->name_normal,
	;

   $html .= sprintf "b: %s, ", $indi->birth->date if $indi->birth;
   $html .= sprintf "d: %s, ", $indi->death->date if $indi->death;

   $html .= "\n";

   my $childcount = 0;
   foreach ($indi->fams)
   {
      $html .= &do_fam($_, $depth, $indi->sex, $dataset, \$childcount);
   }

   return $html;
}

sub do_fam
{
   my $fam = shift;
   my $depth = shift;
   my $sex = shift;
   my $dataset = shift;
   my $childcount = shift;

   my $text = '';

   my $spouse = ($sex =~ /f/i) ? $fam->husb : $fam->wife;

   if ($spouse)
   {
      $text .= sprintf "%s  m: %s, %s -- ",
	'. . ' x $depth,
	$spouse->name_normal,
	$fam->marriage ? $fam->marriage->date : '',
	;

      $text .= sprintf "b: %s, ", $spouse->birth->date if $spouse->birth;
      $text .= sprintf "d: %s, ", $spouse->death->date if $spouse->death;

      $text .= "\n";
   }

   if ($fam->children)
   {
      foreach ($fam->children)
      {
         ++$$childcount;
         $text .= &do_indi($_, $depth + 1, $dataset, $childcount);
      }
   }

   return $text;
}




1;


