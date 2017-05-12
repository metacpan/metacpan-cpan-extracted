package File::SambaMSNRL;

use Carp;
use warnings;
use strict;
use File::Copy;

=head1 Module de gestion du fichier de configuration de samba (smb.conf)

File::SambaMSNRL - Gestion de la configuration de Samba

=head1 VERSION

Version 0.02

=cut


use Exporter   ();
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

$VERSION     = 0.02;

@ISA         = qw(Exporter);
@EXPORT_OK   = qw(
		  new
		  GetGlobal
		  ModifGlobal
		  AddParamGlobal
		  DelParamGlobal
		  ValeurSection
		  ListPartages
		  CreaPartage
		  ListSections
		  CreaSection
		  ModifSection
		  DelPartage
		  DelValue
		  Sauve
		 );
			
=head1 Méthodes Objets

=head2 new("fichier_conf_samba");

Le fichier indiqué doit correspondre à un fichier de configuration de samba
Il doit posséder au minimum une partie [global] et au moins un partage

Retourne un nouvel objet

Example :
	 my $objet=File::SambaMSNRL->new("/etc/samba/smb.conf);

=cut

sub new {
 my $classe = shift;
 my $smbconf = shift;
 my (%global,%det_partages,@partages,%new_partage);

 my $self = { 	
		"SMB"		=> "/etc/samba/smb.conf",
		"GLOBAL" 	=> \%global,
		"DET_PARTAGES" => \%det_partages,
		"PARTAGES"	=> \@partages,
		"NEW_PARTAGE"	=> \%new_partage
	    };
 $self->{SMB} = $smbconf if (defined $smbconf);
  
 bless($self,$classe);
 
 ### Chargement du fichier samba
 my @global = $self->TakeGlobal;
 $self->TakePartages;

 return($self);
}

=head2 GetGlobal

Lit et renvoi la partie [global] du fichier smb.conf
Le retour se fait sous la forme d'un Hash

Params:
	Aucun
Returns:
	Hash du global
Example:
	my %global = $smb->GetGlobal;

=cut

sub GetGlobal {
  my $this = shift;
  my %GLOBAL = %{$this->{GLOBAL}};

  return (%GLOBAL);
};

=head2 ModifGlobal([parametre],[nouvelle_valeur]);

Modifie l'un des parametres de la partie [global] du smb.conf

Params:
	parametre = Le parametre du global à modifier
	nouvelle_valeur = la valeur du parametre à modifier
Returns:
	Retourne 1 si la modification a été effectuée
	Retourne 0 si pas de modification
Example:
	my $retour = $smb->ModifGlobal("workgroup","DOMAINE1");
	if ($retour == 1) {print("La modification du parametre s'est déroulée avec succés\n");

=cut

sub ModifGlobal {
  my $this = shift;
  my $param = shift;
  my $value = shift;

  my $return = 0;

  my %GLOBAL = %{$this->{GLOBAL}};

  $param = lc($param);

  if (exists $GLOBAL{$param}) {
    $GLOBAL{$param} = $value;
    $return = 1;
  };

  $this->{GLOBAL} = \%GLOBAL; 
  
  return($this,$return);
};

=head2 AddParamGlobal ([parametre_a_ajouter],[valeur_du_parametre]);

Ajoute un nouveau parametre sur la partie [global] du smb.conf

Params:
	parametre_a_ajouter = le nom du parametre à ajouter dans la partie global
	valeur_du_parametre = la valeur de ce parametre
Returns:
	-
Example:
	$smb->AddParamGlobal("guest ok","Yes");

=cut

sub AddParamGlobal {
 my $this = shift;
 my $param = shift;
 my $value = shift;

 $param = lc($param);

 my %GLOBAL = %{$this->{GLOBAL}};

 $GLOBAL{$param} = $value;

 $this->{GLOBAL} = \%GLOBAL;

 return($this); 
};

=head2 DelParamGlobal([parametre_a_supprimer]);

Supprime un parametre dans la partie [global] du smb.conf

Params:
	Nom du parametre à supprimer
Returns:
	Retourne 0 en cas de non suppression
	Retourne 1 si le parametre a été correctement supprimé
Example:
	my $result = $smb->DelParamGlobal("workgroup");

=cut

sub DelParamGlobal {
  my $this = shift;
  my $param = shift;

  my $return = 0;

  $param = lc($param);

  my %GLOBAL = %{$this->{GLOBAL}};


  if (exists $GLOBAL{$param}) {
    delete($GLOBAL{$param});
    $return = 1;
  };

  $this->{GLOBAL} = \%GLOBAL;

  return($this,$return);
};

=head2 ValeurSection([nom_de_partage],[nom_de_section])

Recherche la valeur d'une section pour un partage donné

Params:
	Nom du partage
	Nom de la section dont on souhaite la valeur
Returns:
	Valeur de la section d'un partage donné
Example:
	my $valeur = $smb->ValeurSection("data","path");

=cut

sub ValeurSection {
  my $this = shift;
  my $partage_section = shift;
  my $nom_section = shift;
  my $value = undef;

  my %details = %{$this->{DET_PARTAGES}};
  my @partages = @{$this->{PARTAGES}};

  $partage_section = lc($partage_section);
  $nom_section = lc($nom_section);

  if (grep(/$partage_section/,@partages)) {
    my @temp = keys %{$details{$partage_section}};
    if (grep(/$nom_section/,@temp)) {
      $value = $details{$partage_section}{$nom_section};
    }
  };
  return($value);
};  

=head2 ListPartages

Liste la totalité des partages contenus dans le fichier de configuration de samba

Params:
	Aucun
Returns:
	Tableau contenant la liste des partages
Example:
	my @partages = ListPartages;

=cut

sub ListPartages {
 my $this = shift;
 my @partages = @{$this->{PARTAGES}};
 
 return (@partages);
};

=head2 ListSections

Liste les différentes sections et leur valeur pour tous les partages samba

Params:
	Aucun
Returns:
	Hash de hash contenant le détail de chaque partage samba
Example:
	my %details = $smb->ListSections;
	my @part = keys %details;
	foreach $keys (@part) {
	  my @key2 =  keys %{$details{$keys}};
	  foreach my $value (@key2) {
	    my $valeur = $details{$keys}{$value};
	  };
	};                         

=cut

sub ListSections {
 my $this = shift;
 my %detail = %{$this->{DET_PARTAGES}};

 return (%detail);
};

=head2 CreaPartage("nom_du_partage");

Permet la creation d'un nouveau partage

Params:
	Le nom du partage à créer
Returns:
	Retourne 1 si le partage a été créé
	Retourne 0 si le partage n'a pas pu être créé
Example:
	my $result = $smb->CreaPartage("nom_du_partage");

=cut

sub CreaPartage {
 my $this = shift;
 my $partage = shift;
 my %detail = %{$this->{NEW_PARTAGE}};
 my @partages = @{$this->{PARTAGES}};
 my $result = 1;

 $partage = lc($partage); 

 ### Tester si le nom de partage n'est pas déjà utilisé ###
 if (grep /$partage/,@partages) {
   $result = 0;
 }
 else {
   ### Creer le partage ###
   $detail{$partage}{comment}=$partage;
   push(@partages,$partage);
 };
 $this->{NEW_PARTAGE} = \%detail;
 $this->{PARTAGES} = \@partages;
 return ($this,$result);
};

=head2 CreaSection([partage],[section],[valeur_de_la_section]);

Ajoute une nouvelle section au partage créé précédemment à l'aide de "CreaPartage"

Params:
	partage : Nom du partage sur lequel créer une section
	Section : Nom de la section à créer
	Valeur de la section : Valeur à inscrire pour la section indiquée

Returns:
 	Retourne 1 si la création s'est déroulée correctement
	Retourne 0 si la création n'a pas eu lieu
	
Example:
	my $result = $smb->CreaPartage("Data");
	$smb->CreaSection("donnees","path","/home/data");

=cut

sub CreaSection {
 my $this = shift;
 my $partage = shift;
 my $section = shift;
 my $value = shift;

 $partage = lc($partage);
 $section = lc($section);

 my $result = 1;
 my %new_partage = %{$this->{NEW_PARTAGE}};
 
 my @keys = keys(%new_partage);

 if (!(grep(/$partage/,@keys))) {
   $result = 0;
 }
 else {  
  ### Ajouter la nouvelle section au partage en cours de creation
  $new_partage{$partage}{$section} = $value;
 };

 return ($this,$result);
};

=head2 ModifSection([partage],[section],[valeur_de_la_section]);

Modifie la valeur d'une section pour un partage donné

Params:
	[partage] : nom du partage sur lequel travailler
	[section] : nom de la section dans le partage indiqué
	[valeur_de_la_section] : Valeur de la section

Returns:
	Retourne 1 si la modification a été réalisée
	Retourne 0 si la modification a échouée

Example:
	my $retour = $smb->ModifSection("games","inherit permissions","No");

=cut

sub ModifSection {
 my $this = shift;
 my $partage_modif = shift;
 my $section_modif = shift;
 my $value_modif = shift;

 my $result = 1;

 $partage_modif = lc($partage_modif);
 $section_modif = lc($section_modif);

 my @partages = @{$this->{PARTAGES}};
 my %detail   = %{$this->{DET_PARTAGES}};

 if (grep(/$partage_modif/,@partages)) {
   $detail{$partage_modif}{$section_modif}=$value_modif;
 }
 else { $result = 0; };

 return ($this,$result);
};

=head2 DelPartage([@partages]);

Supprime un partage du fichier smb.conf

Params:
	Un tableau contenant le nom de chaque partage à supprimer
Returns:
	Retourne une référence sur un tableau contenant le nom des partages supprimés
Example:
	my @partages = ("data","games","mp3","avi");
	my $RefPartagesSupp = $smb->DelPartage(@partages);
	my @PartSupp = @$RefPartagesSupp;
	
	foreach my $val (@PartSupp) {
	  print("Partage Supprimé : $val\n");
	};

=cut

sub DelPartage {
 my $this = shift;
 my (@partage_del) = @_;

 my @retour;
 my $part;
 my @partages   = @{$this->{PARTAGES}};
 my %detail	= %{$this->{DET_PARTAGES}};

 foreach $part (@partage_del) {
  $part = lc($part);

  if (grep(/$part/,@partages)) {
     delete($detail{$part});
     for (my $i=0;$i<=$#partages;$i++) {
	if ($partages[$i] eq $part) { 
	 splice(@partages,$i,1); 
	 push (@retour,$part);
	 last; 
	};
     };	
   };
  };

 $this->{PARTAGES} = \@partages;
 $this->{DET_PARTAGES} = \%detail;

 return ($this,\@retour);
};

=head2 DelValue([nom_partage],[valeur_a_supprimer]);

Suppression d'un parametre dans un partage

Params:
	nom_partage : Nom du partage où le paramètre doit être supprimé
	valeur_a_supprimer : Le paramètre à supprimer dans ce partage
Returns:
 	Retourne 1 si le parametre a été supprimé
	Retourne 0 si le parametre n'a pas été supprimé	
Example:
	my $retour = $smb->DelValue("games","inherit permissions");

=cut

sub DelValue {
 my $this = shift;
 my $partage = shift;
 my $value = shift;

 $partage = lc($partage);
 $value = lc($value);

 my $retour = 1;

 my @partages = @{$this->{PARTAGES}};
 my %detail   = %{$this->{DET_PARTAGES}};

 if (grep(/$partage/,@partages)) {
  
  if (exists $detail{$partage}) {
   delete $detail{$partage}{$value};
   $this->{DET_PARTAGES} = \%detail;
  }
  else {
   $retour = 0;
  };
 }
 else { 
  $retour = 0; 
 };

 return($this,$retour);
};

=head2 Sauve([nom_du_fichier]);

Sauvegarde des modifications effectuées > Ecriture du fichier final
Pour que l'enregistrement se passe correctement, il faut au minimum une partie global et un partage.

Params:
	Nom du fichier à sauvegarder. Ce paramêtre est facultatif.
	S'il n'est pas donné, le fichier est enregistré sous son nom d'origine. 
	Dans ce cas, une sauvegarde de ce fichier est réalisée dans le même répertoire avant l'écriture.

Returns:
 	Si sauvegarde avec le nom du fichier d'origine, renvoi le nom du fichier sauvegardé
	Si sauvegarde avec un nouveau nom, renvoi 1

Example:
	my $retour = $smb->Sauve("/etc/samba/smbnew.conf");

=cut

sub Sauve {
 my $this = shift;
 my $fic_sauve = shift;

 my $retour;
 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

 my %partage_a_sauver = %{$this->{NEW_PARTAGE}};
 my %det_part = %{$this->{DET_PARTAGES}};
 my $smb = $this->{SMB};
 my %global = %{$this->{GLOBAL}};
 $year = $year+1900;
 my $save = "$smb-$mon$year-$hour$min$sec";

 if ((defined $fic_sauve) and ($smb ne $fic_sauve)) { 
  $smb = $fic_sauve; 
  $retour = 1;
 }
 else {
  ### Sauvegarde du fichier d'origine ### 
  copy("$smb","$save");
  $retour = $save; 
 };

 ### Integration du nouveau partage dans la liste des partages à enregistrer
 my @keys_new = keys(%partage_a_sauver);
 
 if ($#keys_new >= 0) {
  foreach my $key_new (@keys_new) {
   my @section_new = keys(%{$partage_a_sauver{$key_new}});
   foreach my $sectio (@section_new) {
     $det_part{$key_new}{$sectio}=$partage_a_sauver{$key_new}{$sectio};
   };
  };
 };

 ### Mettre le premier caractere en majuscule (uniquement pour Yes ou No)
 my @keys_maj = keys(%det_part);

 foreach my $_key (@keys_maj) {
  my @section_maj = keys(%{$det_part{$_key}});
  foreach my $_section (@section_maj) {
   if ($det_part{$_key}{$_section} =~ /^yes$|^no$/i) { 
     $det_part{$_key}{$_section} = ucfirst($det_part{$_key}{$_section});
   };
  };
 };

 ### Ouverture du fichier en ecriture
 open(FICSMB,">",$smb)||croak("Impossible de créer le fichier $smb !!!\n");

 ### En-tête personnalisé
 print FICSMB (";============================================================================\n");
 print FICSMB (";================== xxxxxxx  perl  --  SambaMSNRL  xxxxxxx ==================\n");
 print FICSMB (";============ xxxx  raphael.gommeaux\@gmail.com  xxxx ===========\n"); 
 print FICSMB (";============================================================================\n\n\n");
 
 ### Ecriture du global dans le fichier
 my @keys_global = sort(keys(%global));
 my $maj_key;

 if ($#keys_global >= 0) {
  print FICSMB ("[global]\n");
  foreach my $key_global (@keys_global) {
  $maj_key = $global{$key_global};

   if ($global{$key_global} =~ /^yes$|^no$/i) {
     $maj_key = lc($maj_key);
     $maj_key = ucfirst($maj_key);
   }
   print FICSMB ("\t$key_global = $maj_key\n");
  };
 }
 else { croak("Impossible de trouver la partie global...\n"); };

 ### Separation entre le global et les partages
 print FICSMB ("\n;=========================================================================\n\n");
 ### Ecriture des partages dans le fichier
 my @keys_detail_part = sort(keys(%det_part));
 if ($#keys_detail_part >= 0) {
  foreach my $key_part (@keys_detail_part) { 
   print FICSMB ("\n[$key_part]\n");
   my @section = sort(keys(%{$det_part{$key_part}}));
   foreach my $sectio (@section) {
    my $det_maj = $det_part{$key_part}{$sectio};
    if ($det_maj =~ /^yes$|^no$/i) { 
     $det_maj = lc($det_maj);
     $det_maj = ucfirst($det_maj);
   };
    print FICSMB ("\t$sectio = $det_maj\n");
   };
  };
 }
 else { croak("Pas de partages à enregistrer... surement une erreur...\n");};

 ### Fermeture du fichier
 close FICSMB;

 return($retour);
};



=head2 load("nom_du_fichier");

Charge un fichier de configuration samba

Params:
	Nom du fichier de configuration
Returns:
	Retourne un tableau contenant le fichier chargé
	
=cut

sub load {
 my $name = shift;

 my @smbconf;

 if (-z $name) { croak("Le fichier $name est vide !!!\n");};
 open(FICSMB,$name)||croak("Impossible de lire le fichier $name !!!!!\n");
 my @smb = <FICSMB>;
 close FICSMB;

 return (@smb);
};

=head2 TakePartages

Charge la liste des partages présents dans le fichier de configuration de samba

=cut

sub TakePartages {
  my $this = shift;
  my @SHARES;
  my @SHARES_DET;
  my $share_detail;
  my $fin;
  my %share_detail;
  my $part;
  my $ligne;

  my @SMB = load($this->{SMB});

  for (my $i=0;$i<=$#SMB;$i++) {
    chomp($SMB[$i]);
    $ligne = $SMB[$i];
   
    if (($ligne =~ /\[/) and (!($ligne =~ /\[global\]/))) {
      $part = lc($SMB[$i]);
	
      $part =~ s/\[//;
      $part =~ s/\]//;
      $part =~ s/ //g;

      push(@SHARES,$part);
    }
    ### Ne passe pas dans cette boucle si :
    ###		- pas encore trouvé de partage
    ### 	- la ligne est vide
    ###		- la ligne commence par un ; ou un #
    ###		- la ligne commence par une ou plusieurs tabulations suivies d'un ; ou d'un #
    ###		- la ligne commence par un ou plusieurs espaces suivis d'un ; ou d'un #
    elsif (($#SHARES >= 0) and (!($ligne =~ /^\s*$|^;|^\t*;|^\s*;|^#|^\t*#|^\s*#/))) {
      $ligne =~ /(.+)=(.+)/;
      my $section = $1;
      my $valeur  = $2;

      if (($valeur eq "") or ($valeur eq " "))
      {
       $section = $ligne;
       $section =~ s/=//;
      }

      $section =~ s/\t//;
      $section =~ s/^ +//;
      $section =~ s/ +$//;

      $section = lc($section);

      $valeur =~ s/\t//;
      $valeur =~ s/^ +//;
      $valeur =~ s/ +$//;

      $share_detail{$part}{$section} = $valeur;
    };
   };
 
  $this->{PARTAGES} = \@SHARES;
  $this->{DET_PARTAGES} = \%share_detail;

  return $this;
};

=head2 TakeGlobal

Charge la partie global du fichier de configuration samba

=cut

sub TakeGlobal {
  my $this = shift;
  my @smb = load($this->{SMB});
  my %GLOBAL;

  for (my $i=0;$i<=$#smb;$i++) {
  chomp($smb[$i]);
  if ($smb[$i] eq "[global]") {
    for (my $j=$i+1;$j<=$#smb;$j++) {
      if (grep (/\[/,$smb[$j])) {
        last;
      }
      else {
        chomp($smb[$j]);
        if ((!($smb[$j] =~ /^;/)) and (!($smb[$j] =~ /^#/)) and (grep (/=/,$smb[$j]))) {
         # $smb[$j] =~ /(.*?)=(.*)/;
	  $smb[$j] =~ m/([^=]+) = (.+)/x;
          my $section_global = $1;
          my $valeur_section = $2;

        if (($valeur_section eq "") or ($valeur_section eq " "))
        {
         $section_global = $smb[$j];
         $section_global =~ s/=//;
        }

          $section_global =~ s/\t//;

          $section_global =~ s/^ +//;
          $section_global =~ s/ +$//;
	  $section_global = lc($section_global);
          $valeur_section =~ s/\t//;
          $valeur_section =~ s/^ +//;
          $valeur_section =~ s/ +$//;

          $GLOBAL{$section_global}=$valeur_section;
        };
      };
    };
  };
  };
  $this->{GLOBAL} = \%GLOBAL;
 return (%GLOBAL);
};


1;
