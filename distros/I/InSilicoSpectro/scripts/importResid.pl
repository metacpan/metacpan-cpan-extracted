#!/usr/bin/perl
=head1 NAME

importResid.pl

=head1 DESCRIPTION

Convert a resid_xml (from an url or a local file) file into a insilicodef file

=head1 SYNOPSIS

importResid.pl ftp://ftp.ebi.ac.uk/pub/databases/RESID/RESIDUES.XML

importResid.pl /tmp/resid.xml

importResid - (reading from STDIN)

=head1 OPTIONS

=head3 --dest=file

Set the destination file (default is STDOUT)

=head3 --user=name

If a phenyx search engine is installed, data can be saved in a given user.If --user option is set, it overwrites the --dest one.

=head3 --help

=head3 --verbose

=cut

use strict;
use Getopt::Long;
use XML::Parser;
use File::Temp qw(tempfile);
use LWP::Simple;
use Carp;
use Pod::Usage;

use InSilicoSpectro::InSilico::ModRes;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro;

my ($help, $verbose, $dest, $username);
if (!GetOptions('dest=s'=> \$dest,
		'user=s'=>\$username,
		'help' => \$help,
		'verbose' => \$verbose) || defined($help)){
  pod2usage(-verbose=>2, -exitval=>(not $help), -output=>\*STDOUT);
}

# Opens and parse
my $src = $ARGV[0] || CORE::die "must provide a resid_xml source (url or file)";

my $residFile;
if($src=~/^(ftp|http):/i){
    my (undef, $ftmp)=tempfile(UNLINK=>1, SUFFIX=>".resid.xml");
    print STDERR "downloading $src to $ftmp\n" if $verbose;
    unless(my $rc=is_success(getstore($src, $ftmp))){
      InSilicoSpectro::Utils::io::croakIt "could not download $src: ".status_message($rc);
    }
    $residFile=$ftmp;
}else{
  $residFile=$src;
}

if($username){
  require Phenyx::Config::GlobalParam;
  Phenyx::Config::GlobalParam::readParam();
  require Phenyx::Manage::User;
  my $user=Phenyx::Manage::User->new(name=>$username);
  $dest=$user->getFile("insilicodef.xml");
  #Phenyx::InSilicoSpectro::init($dest);
}

my $parser = new XML::Parser(Style => 'Stream');
if($src eq '-'){
  $parser->parse(\*STDIN);
}else{
  open(F, $residFile) || CORE::die ("cannot open [$residFile]: $!");
  $parser->parse(\*F);
  close(F);
}

InSilicoSpectro::saveInSilicoDef($dest);

# ------------------------------ XML --------------------------

my ($curChar, $eNum);
my ($id, $myId, $correction, $weightType, $isSpFeature, $name, $alternateName, $description);
my ($formula, $avgDelta, $monoDelta, $seqSpecificity, @feature);

sub Text
{
  $curChar .= $_;

} # Text


sub StartTag
{
  my($p, $el) = @_;

  if ($el eq 'Entry'){
    $id = $_{id};
    $eNum++;
    $myId = "$id-$eNum";
    undef(@feature);
    undef $description;
  }
  elsif ($el eq 'CorrectionBlock'){
    $correction = 1;
  }
  elsif ($el eq 'Weight'){
    $weightType = $_{type};
  }
  elsif ($el eq 'Feature'){
    $isSpFeature = $_{type} == 'SWISS-PROT';
  }
  undef($curChar);

} # StartTag


sub EndTag
{
  my($p, $el)= @_;

  if ($el eq 'Name'){
    $name = $curChar;
  }
  elsif ($el eq 'AlternateName'){
    $alternateName = $curChar;
  }
  elsif ($el eq 'Description'){
    $description = $curChar;
  }
  elsif (($el eq 'Formula') && defined($correction)){
    $formula = $curChar;
    $formula=~s/\s//g;
  }
  elsif (($el eq 'Weight') && defined($correction)){
    if ($weightType eq 'chemical'){
      $avgDelta = $curChar;
    }
    else{
      $monoDelta = $curChar;
    }
  }
  elsif ($el eq 'CorrectionBlock'){
    undef($correction);
  }
  elsif (($el eq 'Feature') && $isSpFeature){
    push(@feature, $curChar);
    undef($isSpFeature);
  }
  elsif ($el eq 'SequenceSpec'){
    $seqSpecificity = $curChar;
    #    $seqSpecificity=~s/\W//g;
  }
  elsif ($el eq 'Entry'){
    my $mr =InSilicoSpectro::InSilico::ModRes->new(name=>$name);
    $mr->{description}=$description;
    $mr->{alternateName}=$alternateName;
    $mr->{residId}=$id;
    $seqSpecificity=~s/\s//g;
    if($seqSpecificity=~/,/){
      $seqSpecificity=~s/,/.*?/g;
      $mr->{regexpStr}=$seqSpecificity;
    }elsif(length($seqSpecificity)>1){
      my ($aa, $rem)=split //, $seqSpecificity, 2;
      $mr->{regexpStr}="$aa(?=$rem)";
    }else{
      $mr->{site}{residue}=$seqSpecificity;
    }
    $mr->{delta_monoisotopic}=$monoDelta;
    $mr->{delta_average}=$avgDelta;
    $mr->{sprotFT}="(".(join('|', @feature)).").*";
    $mr->{formula}=$formula;
  }

} # EndTag
