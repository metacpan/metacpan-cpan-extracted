use strict;

package InSilicoSpectro::InSilico::ModRes;
require Exporter;
use Carp;

use InSilicoSpectro::Utils::io;
use InSilicoSpectro::InSilico::MassCalculator;

=head1 NAME

InSilicoSpectro::InSilico::ModRes Residue modifications package


=head1 SYNOPSIS

  #read all modres definitions in the default file ({phenyx.config.modres})
  InSilicoSpectro::InSilico::ModRes::init();

  #or, if the ohenyx system is not installed
  InSilicoSpectro::InSilico::ModRes::init("some/path/to/defatultdef.xml");

  #print all the modifications
  foreach (InSilicoSpectro::InSilico::ModRes::getList()){
    $_->print();
  }

  #given a swissprot FT valkue, return the related modres
  foreach ('PHOSPHORYLATION', 'ACETYLATION (IN ISOFORM SHORT))', 'PHOSPHORYLATION', 'ACETYLATION', 'SULFATION'){
    print "$_ => ".InSilicoSpectro::InSilico::ModRes::getModifFromSprotFT($_)->get('name')."\n";
  }

=head1 DESCRIPTION

Manage all what is related to residue modifications (masses, positions, SwissProt annotations...)

=head1 FUNCTIONS

=head2 Initialization

=head3 init([$files, [$files, [...]]])

Opens the given files or try to locate the file ${phenyx.config.modres} and stores all the modif in the dictionnary

=head3 getFromDico(name)

A dictionnary holds all the enzymes, based on their key

=head3 getList()

Returns a list of all the enzymes, sorted by name

=head3 registerModResHandler([\&sub])

get/set a subroutine to be called whenever a new modres is instanciated (for example, register into MassCalaculator

=head1 METHODS

=head3 my $mr=InSilicoSpectro::InSilico::ModRes->new([$h])

$h contains a pointer to a hash for definition

=head3 $mr->name([$str])

Set the name if an argument is given.

Returns the name value

=head3 $mr->regexp([$str]);

Set the modif regular expression from a string (or return this regular expression if no argument is given)

=head3 $mr->cTerm([$val]);
=head3 $mr->nTerm([$val]);

Set if the modif is peptide C/N terminus (or just returns the current status is no value is passed to the function)

=head3 $mr->protCTerm([$val]);
=head3 $mr->protNTerm([$val]);

Set if the modif is protein C/N terminus (or just returns the current status is no value is passed to the function)

=head3 $mr->seq2pos($seq);

returns an array of position where the modif can appear on sequence $seq.

This array contains

=over 4

=item [-1] if it can be attributed nterm

=item [length $seq] if it can be attributer cterm

=item else, a list of indices, starting at 0 for the first AA of the sequence

=back

=head3 $mr->set($name, $val)

Set an instance paramter.

=head3 $mr->get($name)

Get an instance parameter.

=head3 $mr->getXMLTwigElt()

return an XML::Twig::Elt object containing the modres

=head1 EXAMPLES

see t/InSilico/tesModRes.pl script

=head1 SEE ALSO

Phenyx::Config::GlobalParam

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut


our (@ISA, @EXPORT, @EXPORT_OK, $isInit, %dico, %re2Modif);
@ISA = qw(Exporter);

@EXPORT = qw(&init &getFromDico &getList &getModifFromSprotFT &twig_addModRes &registerModResHandler);
@EXPORT_OK = ();

our $rsRegisterModResHandler;

sub new{
  my $pkg=shift;
  my %h;
  if((ref $_[0]) eq 'HASH'){
    %h=%{$_[0]}
  }else{
    %h=@_;
  }

  my $mr={};
  bless $mr, $pkg;

  my $dvar={};
  bless $dvar, $pkg;

  foreach (keys %h){
    $mr->set($_, $h{$_});
  }
  return $mr;
}

#output

use SelectSaver;
sub print{
  my ($this, $out)=@_;
  my $fdOut=(defined $out)?(new SelectSaver(InSilicoSpectro::Utils::io->getFD($out) or CORE::die "cannot open [$out]: $!")):\*STDOUT;
  print $fdOut "$this->{name} $this->{delta_monoisotopic}"
}

#-------------------------------- accessors

sub regexp{
  my ($this, $reStr)=@_;

  if($reStr){
    $this->{regexp}=qr/$reStr/;
  }
  return $this->{regexp};
}

sub cTerm{
  my ($this, $val)=@_;
  if(defined $val){
    $this->{cTerm}=$val;
  }
  return $this->{cTerm};
}

sub nTerm{
  my ($this, $val)=@_;
  if(defined $val){
    $this->{nTerm}=$val;
  }
  return $this->{nTerm};
}

sub protCTerm{
  my ($this, $val)=@_;
  if(defined $val){
    $this->{protCTerm}=$val;
  }
  return $this->{protCTerm};
}

sub protNTerm{
  my ($this, $val)=@_;
  if(defined $val){
    $this->{protNTerm}=$val;
  }
  return $this->{protNTerm};
}

sub name{
  my ($this, $val)=@_;
  if(defined $val){
    $this->{name}=$val ;
    add2Dico($this);
  }
  return $this->{name};
}

sub set{
  my ($this, $name, $val)=@_;
  $this->{$name}=$val;
  if($name eq 'name'){
    $val=~s/'/p/g;
    $this->{$name}=$val;
    add2Dico($this);
  }
  if($name eq 'sprotFT'){
      $re2Modif{$val}=$this if (defined $val);
  }
}

sub get{
  my ($this, $n)=@_;
  return $this->{$n};
}


#-------------------------------- static dictonary


sub getFromDico{
  my ($name)=@_;
  return $dico{$name};
}

sub add2Dico{
  my($mr)=@_;
  croak "duplicate name for two modif [".($mr->get('name'))."]" if defined $dico{$mr->get('name')};
  $dico{$mr->get('name')}=$mr;
  $re2Modif{$mr->get('sprotFT')}=$mr if (defined $mr->get('sprotFT'))
					       and
					       (not defined $re2Modif{$mr->get('sprotFT')});
}



sub getList{
  return sort {$a->{name} cmp $b->{name}} values %dico;
}


sub getModifFromSprotFT{
  my ($ftmodres)=@_;
  foreach (keys %re2Modif){
    next unless $_;
    return $re2Modif{$_} if $ftmodres=~/^$_$/i;
  }
  return undef;
}


#--------------------------------- positions

sub seq2pos{
  my ($this, $seq)=@_;
  my @pos;
  my $re=$this->regexp;
  if($this->nTerm){
    push @pos, -1 if $seq=~/$re/;
  }elsif($this->cTerm){
    push @pos, length $seq if $seq=~/$re/;

  }else{
    while ($seq=~/$re/g){
      push @pos, pos($seq)-1;
    }
}
  return @pos;
}

#--------------------------------- init

use XML::Twig;

sub init{
  my @listFiles=@_;
  return if $isInit;
  my $twig=XML::Twig->new(twig_handlers=>{
					  'oneModRes'=> \&twig_addModRes,
					  'OneModRes'=> \&twig_addModRes,
					  pretty_print=>'indented'
					 }
			 );
  if(@listFiles){
    foreach (@listFiles){
      CORE::die "file [$_] is not readable" unless -r $_;
      $twig->parsefile($_) or InSilicoSpectro::Utils::io::croakIt "cannot parse [$_]: $!";
    }
  }else{
    eval{
      require Phenyx::Config::GlobalParam;
      InSilicoSpectro::Utils::io::croakIt "no [phenyx.config.modres] is set" unless defined Phenyx::Config::GlobalParam::get('phenyx.config.modres');
      foreach(split /,/, Phenyx::Config::GlobalParam::get('phenyx.config.modres')){
	print STDERR __PACKAGE__." opening [$_]\n" if $InSilicoSpectro::Utils::io::VERBOSE;
	$twig->parsefile($_) or InSilicoSpectro::Utils::io::croakIt "cannot parse [$_]: $!";
      }
    };
    if ($@){
      croak "not possible to open default config files: $@";
    }
  }
  $isInit=1;
}


sub twig_addModRes{
  my ($twig, $el)=@_;

  my $mr=InSilicoSpectro::InSilico::ModRes->new();

  foreach (qw (name type description)) {
    $mr->set($_, $el->atts->{$_});
  }
  $mr->set('description', $el->first_child('description')->text) if $el->first_child('description');

  if (my @tmp=$el->get_xpath('residue')) {
    #old fashion
    my $elres=$tmp[0];
    foreach (qw (aaCur aa aaBefore )) {
      $mr->set($_, $elres->atts->{$_});
    }
    my $str="(?<=[$mr->{aaBefore}]" if $mr->{aaBefore};
    $str.="[$mr->{aa}]";
    $str.="(?=[$mr->{aaAfter}])" if $mr->{aaAfter};
    $mr->regexp($str);
  } elsif (my $elSite=$el->first_child('site')) {
    my $elRes=$elSite->first_child('residue') or croak "no [residue] child";
    $mr->nTerm(defined $elSite->first_child('nterm'));
    $mr->cTerm(defined $elSite->first_child('cterm'));
    $mr->{site}{residue}=$elRes;
    my $re.=$mr->nTerm?'^':'';
    $re.="[".($elRes->text || '.')."]";
    $re.=$mr->cTerm?'$':'';
    $mr->regexp($re);
  } elsif (my $elSite=$el->first_child('siteRegexp')) {
    $mr->nTerm(defined $elSite->atts->{nterm});
    $mr->cTerm(defined $elSite->atts->{cterm});
    my $re.=$mr->nTerm?'^':'';
    $re.=$elSite->text;
    $re.=$mr->cTerm?'$':'';
    $mr->regexp($re);
  } else {
    croak "in oneModRes tag, could not find any of (residue|site|siteRegexp) child notations";
  }

  my @tmp=$el->get_xpath('delta') or  InSilicoSpectro::Utils::io::croakIt "cannot find <delta> tag";
  my $eldelta=$tmp[0];
  foreach (qw (monoisotopic average)) {
    $mr->set("delta_$_", $eldelta->atts->{$_});
  }
  if (@tmp=$el->get_xpath('sprotFT')) {
    $mr->set('sprotFT', $tmp[0]->text);
  }

#  $mr->add2Dico();
  if(registerModResHandler()){
    registerModResHandler()->($mr);
  }

}

sub getXMLTwigElt{
  my $this=shift;
  my $el=XML::Twig::Elt->new()->parse("<oneModRes type='".($this->{type}||'aaModif')."' name='$this->{name}'/>");
  XML::Twig::Elt->new()->parse("<description><![CDATA[$this->{description}]]></description>")->paste(last_child=>$el);
  if($this->{site}){
    my $termtag="";
    $termtag.='<nterm/>' if($this->nTerm);
    $termtag.='<cterm/>' if($this->cTerm);
    XML::Twig::Elt->new()->parse("<site><residue>$this->{site}{residue}</residue>$termtag</site>")->paste(last_child=>$el);
  }else{
    my $termatts="";
    $termatts=' nterm="yes"' if($this->nTerm);
    $termatts=' cterm="yes"' if($this->cTerm);
    XML::Twig::Elt->new()->parse("<siteRegexp$termatts>$this->{regexpStr}</siteRegexp>")->paste(last_child=>$el);
  }
  XML::Twig::Elt->new()->parse("<delta monoisotopic='$this->{delta_monoisotopic}' average='$this->{delta_average}'/>")->paste(last_child=>$el);

  XML::Twig::Elt->new()->parse("<formula>$this->{formula}</formula>")->paste(last_child=>$el);
  XML::Twig::Elt->new()->parse("<sprotFT><![CDATA[$this->{sprotFT}]]></sprotFT>")->paste(last_child=>$el) if $this->{sprotFT};
  return $el;
}

sub registerModResHandler{
  my $sub=shift;
  if($sub){
    $rsRegisterModResHandler=$sub;
  }
  return $rsRegisterModResHandler;
}
# -------------------------------   misc
return 1;
