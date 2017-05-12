use strict;

package InSilicoSpectro::InSilico::CleavEnzyme;
require Exporter;
use Carp;

use InSilicoSpectro::Utils::io;

=head1 NAME

InSilicoSpectro::InSilico::CleavEnzyme Basic enzyme object.

=head1 SYNOPSIS

  # Reads all cleavage enzyme definition in the default file(s) ({phenyx.config.cleavenzymes})
  InSilicoSpectro::InSilico::CleavEnzyme::init();

  # Prints all the modifications
  foreach (InSilicoSpectro::InSilico::Enzyme::getList()){
    print;
  }

=head1 DESCRIPTION

Cleavage enzyme object that comprises a description of the enzyme and basic methods
for reading XML configuration file(s) and printing. A dictionary is created at the
package level to store all the read enzymes from the configuration file(s).

=head1 FUNCTIONS

=head2 Initialization

=head3 init([$filename])

Opens the given file, or file ${phenyx.config.cleavenzymes} if no parameter was given, and stores
all the modif in the dictionnary.

=cut

=head3 getFromDico($name)

This function retrieves and returns an enzyme from the dictionary based on its name.

=cut

=head3 getList()

Returns a sorted list of all the enzyme names in the dictionary.

=cut

=head1 METHODS

=head3 new([$h])

Creates (constructor) a new object enzyme. $h contains a reference to a hash or is a hash itself.
The hash lists object attributes with their values and it is used to initialize the newly created
object.

=head3 name([$str])

Sets the enzyme name if an argument is given, otherwise returns the name value.

=head3 regexp([$restr])

Sets a regular expression for enzymatic digestion (use looking (back|for)wards) if an argument is given,
otherwise returns the regexp (compiled).

=head3 terminus([$t])

Sets the terminus side (trypsin is C-term) of the enzyme if an argument (either 'C' or 'T') is given,
otherwise returns terminus either 'N' or 'C'.

=head3 CTermGain([$g])

Sets the atoms gained at the peptide C-terminal site after digestion (normally OH) if an argument is given,
otherwise returns the atoms gained.

=head3 NTermGain([$g])

Sets the atoms gained at the peptide N-terminal site after digestion (normally H) if an argument is given,
otherwise returns the atoms gained.

=head3 CTermModif([$g])

Sets the name of the modification induced by the enzyme at the peptide C-terminus if an argument is given,
otherwise returns the modification name.

=head3 NTermModif([$g])

Sets the name of the modification induced by the enzyme at the peptide N-terminus if an argument is given,
otherwise returns the modification name.

=head3 print

=head3 overloaded "" operator

=head1 EXAMPLES

See t/InSilico/testCleavEnzyme.pl.

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
Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut


our (@ISA, @EXPORT, @EXPORT_OK, $isInit, %dico);
@ISA = qw(Exporter);

@EXPORT = qw(&init &getFromDico &getList &twig_addEnzyme);
@EXPORT_OK = ();

our %visibleAttr = (name=>1, regexp=>1, terminus=>1, CTermGain=>1, NTermGain=>1, CTermModif=>1, NTermModif=>1);

return 1;


sub new{
  my $pkg=shift;
  my %h;
  if((ref $_[0]) eq 'HASH'){
    %h=%{$_[0]}
  }else{
    %h=@_;
  }

  my $class = ref($pkg) || $pkg;
  my $ce={};
  bless $ce, $class;

  foreach (keys %h){
    $ce->$_($h{$_}) if ($visibleAttr{$_});
  }
  return $ce;
}

#output

use SelectSaver;
use overload '""' => \&toString;
sub toString{
  my ($this, $out)=@_;
  my $string = "$this->{name}:\n";
  foreach ('regexpStr', 'terminus', 'CTermGain', 'NTermGain', 'CTermModif', 'NTermModif'){
    $string .= "  $_: $this->{$_}\n" if (defined($this->{$_}));
  }
  return $string;
}
sub print{
  my ($this, $out)=@_;
  my $fdOut=(defined $out)?(new SelectSaver(InSilicoSpectro::Utils::io->getFD($out) or CORE::die "cannot open [$out]: $!")):\*STDOUT;
  print $fdOut $this->toString();
}


#-------------------------------- static dictionary


sub getFromDico{
  my ($name)=@_;
  return $dico{$name};
}

sub add2Dico{
  my($ce)=@_;
  croak "duplicate name for two modif [".($dico{$ce->get('name')})."]" if defined $dico{$ce->name()};
  $dico{$ce->name()}=$ce;
}

sub removeFromDico{
  my($ce, $name)=@_;
  croak "not existing name to remove [$name]" if (!defined($dico{$name}));
  undef($dico{$name});
}

sub getList{
  return sort {$a->{name} cmp $b->{name}} values %dico;
}

# Accessors and modifiers --------------------------------------

sub regexp{
  my ($this, $reStr)=@_;
  if($reStr){
    $this->{regexp}=qr/$reStr/;
    $this->{regexpStr}="/$reStr/";
  }
  return $this->{regexp};
}

sub name{
  my ($this, $val)=@_;
  if(defined $val){
    if (defined($this->name()) && defined(getFromDico($this->name()))){
      # Existing name whch is in the dico, remove it first
      removeFromDico($this->name());
    }
    # Modifiy name and adds the new name to the dico
    $this->{name}=$val ;
    add2Dico($this);
  }
  return $this->{name};
}

sub terminus{
  my ($this, $val)=@_;
  if(defined $val){
    croak "terminus must be [NC] instead of '$val'" unless $val =~ /^[NC]$/;
    $this->{terminus}=$val;
  }
  return $this->{terminus};
}

sub CTermGain{
  my ($this, $val)=@_;
  if (defined($val)){
    $this->{CTermGain}=$val;
  }
  return $this->{CTermGain};
}

sub NTermGain{
  my ($this, $val)=@_;
  if (defined($val)){
    $this->{NTermGain}=$val;
  }
  return $this->{NTermGain};
}

sub CTermModif{
  my ($this, $val)=@_;
  if (defined($val)){
    $this->{CTermModif}=$val;
  }
  return $this->{CTermModif};
}

sub NTermModif{
  my ($this, $val)=@_;
  if (defined($val)){
    $this->{NTermModif}=$val;
  }
  return $this->{NTermModif};
}

#--------------------------------- init

use XML::Twig;

sub init{
  my @listFiles=@_;
  return if $isInit;
  my $twig=XML::Twig->new(twig_handlers=>{
					  oneCleavEnzymeDef=> \&twig_addEnzyme,
					  oneCleavEnzyme=> \&twig_addEnzyme,
					  pretty_print=>'indented'
					 }
			 );
  if(@listFiles){
    foreach (@listFiles){
      CORE::die "file [$_] is not readable" unless -r $_;
      print STDERR "reading CleavEnzyme def from $_\n" if $InSilicoSpectro::Utils::io::VERBOSE;
      $twig->parsefile($_) or InSilicoSpectro::Utils::io::croakIt "cannot parse [$_]: $!";
    }
  }else{
    eval{
      require Phenyx::Config::GlobalParam;
      InSilicoSpectro::Utils::io::croakIt "no [phenyx.config.cleavenzymes] is set" unless defined Phenyx::Config::GlobalParam::get('phenyx.config.cleavenzymes');
      foreach(split /,/, Phenyx::Config::GlobalParam::get('phenyx.config.cleavenzymes')){
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

sub twig_addEnzyme{
  my ($twig, $el)=@_;

  my $ce=InSilicoSpectro::InSilico::CleavEnzyme->new();

  $ce->name($el->atts->{name} || $el->first_child('name')->text); # Forces add to dico
  if (my $gel=$el->first_child('CTermGain')){
    $ce->CTermGain($gel->text);
  }else{
    $ce->CTermGain('OH');
  }
  if (my $gel=$el->first_child('NTermGain')){
    $ce->NTermGain($gel->text);
  }else{
    $ce->NTermGain('H');
  }
  if (my $mel=$el->first_child('CTermModif')){
    $ce->CTermModif($mel->text);
  }
  if (my $mel=$el->first_child('NTermModif')){
    $ce->NTermModif($mel->text);
  }
  if(my $tel=$el->first_child('cleavSite')){
    #old fashioned
    my $re="(?<=".$tel->text.")";
    $ce->{cleavSite}=$tel->text;
    if($tel=$el->first_child('notBefore')){
      $re.="(?=".$tel->text.")";
      $ce->{adjacentSite}=$tel->text;
    }else{
      $ce->{adjacentSite}='.';
    }
    $ce->regexp($re);
    $ce->terminus('C');
  }elsif($tel=$el->first_child('site')){
    my $t=$tel->first_child('terminus')->text;
    $ce->terminus($t);
    my $site=$tel->first_child('cleavSite')->text || '.';
    my $adj=$tel->first_child('adjacentSite')->text || '.';
    my $adjre=($adj eq '.')?'.':"[$adj]";
    my $sitere=($site eq '.')?'.':"[$site]";
    $ce->regexp(($t eq 'C')?("(?<=$sitere)(?=$adjre)"):("(?<=$adjre)(?=$sitere)"));
  }elsif($tel=$el->first_child('siteRegexp')){
    $ce->{regexpStr}=$tel->text;
    $ce->regexp($ce->{regexpStr});
#    my $t=$el->first_child('terminus')->text;
#    $ce->terminus($t);
  }else{
    croak "no way of reading CleavEnzyme from xml node\n".$el->print."\n";
  }
}

# -------------------------------   misc



