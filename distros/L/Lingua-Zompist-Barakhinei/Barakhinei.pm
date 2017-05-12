package Lingua::Zompist::Barakhinei;
# vim:set sw=2 cin cinkeys-=0#:

use 5.005;
use strict;
# use re 'debug';

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use vars qw($gendertab $pluraltab $rootconstab $subjtab);
use vars qw($cadhctab $cadhgtab $cadhutab);
use vars qw($classtab);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::Zompist::Barakhinei ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = (
  'tabs' => [ qw(
    $gendertab
    $pluraltab
    $rootconstab
    $subjtab
    $cadhutab
    $cadhgtab
    $cadhctab
) ],
  'all' => [ qw(
    demeric
    scrifel
    izhcrifel
    budemeric
    buscrifel
    befel
    part
    noun
    adj
) ],
);

push @{$EXPORT_TAGS{'all'}}, @{$EXPORT_TAGS{'tabs'}};

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '0.02';

my %verb = (demeric => \&demeric,
            scrifel => \&scrifel,
            izhcrifel => \&izhcrifel,
            budemeric => \&budemeric,
            buscrifel => \&buscrifel,
            befel => \&befel,
            part => \&part,
           );

my @persons = qw(sû lê ât ta mukh kâ);

my @cases = qw(nom gen acc dat);

my @numbers = qw(sing pl);

# Some handy things for -i- insertion and moving stress
my $cons    = qr/(?:[ctdsknlr]h|[pbtdkgfvszhmnlr])/;
my $consend = qr/[hpbtdkgfvszhmnlr]$/;
my $vow     = qr/[aeiouâêîôûAEIOUÂÊÎÔÛ]/;

# spirant forms
my %spir = (
  d => 'dh',
  t => 'th',
  p => 'v',
);


# Verbs with stems ending in -c in Cadhinor
$cadhctab = {
  'dichi'     => 'DUCIR',
  'faichi'    => 'FAUCIR',
  'farki'     => 'FARCIR',
  'fênki'     => 'VENCIR',
  'foka'      => 'VOCAN',
  'hashki'    => 'HASCIR',
  'hêshki'    => 'HESCIR',
  'kaoka'     => 'CAUCAN',
  'kashki'    => 'KASCIR',
  'kêshkê'    => 'KESCEN',
  'krêshki'   => 'CRESCIR',
  'lachê'     => 'LACEN',
  'lêshkê'    => 'LESCEN',
  'manka'     => 'MANCAN',
  'oloka'     => 'OLOCAN',
  'prechê'    => 'PRECER',
  'rashki'    => 'RASCIR',
  'shkolichê' => 'SCOLICER',
  'snuka'     => 'SNUCAN',
  'tôshkê'    => 'TOSCEN',
  'trankê'    => 'TRANCEN',
};

# Verbs with stems ending in -g in Cadhinor
$cadhgtab = {
  'benhi'  => 'BENGIR',
  'briga'  => 'BRIGAN',
  'fachi'  => 'VAGIR',
  'glonhê' => 'GLONGEC',
  'grochê' => 'GROGEC',
  'hachê'  => 'IAGEN',
  'ilhê'   => 'ULGEC',
  'klachê' => 'CLAGER',
  'kochi'  => 'COGIR',
  'krechê' => 'CREGEN',
  'lega'   => 'LEGAN',
  'mêrgê'  => 'MERGEN',
  'nochê'  => 'NOGEN',
  'puga'   => 'PUGAN',
  'trachê' => 'TRAGEN',
  'troga'  => 'TROGAN',
};

# Verbs with stems ending in -uC in Cadhinor
$cadhutab = {
  'burukha'    => 'BURUKHAN',
  'chidê'      => 'CIUDER',
  'chura'      => 'TURAN',
  'dhirê'      => 'DHUREC',
  'dichi'      => 'DUCIR',
  'dimê'       => 'DUMEC',
  'faichi'     => 'FAUCIR',
  'faoba'      => 'FAUBAN',
  'fedhura'    => 'VETHURAN',
  'fura'       => 'FURAN',
  'glunti'     => 'GLUNTIR',
  'gushta'     => 'GUSTAN',
  'hizi'       => 'IUSIR',
  'idura'      => 'IDURAN',
  'ilhê'       => 'ULGEC',
  'ilubra'     => 'ILUBRAN',
  'ishkuza'    => 'ISKUSAN',
  'izubrê'     => 'ISUBREN',
  'kaoka'      => 'CAUCAN',
  'kitê'       => 'CUTEC',
  'kupi'       => 'CULPIR',
  'kurê'       => 'CURREC',
  'laoda'      => 'LAUDAN',
  'laota'      => 'LAUTAN',
  'liri'       => 'LURIR',
  'lôndura'    => 'LONDURAN',
  'meundê'     => 'MEHUNDEN',
  'niri'       => 'NURIR',
  'plii'       => 'PLUHIR',
  'pua'        => 'PUHAN',
  'puga'       => 'PUGAN',
  'raola'      => 'RAULAN',
  'rênlaoda'   => 'RENLAUDAN',
  'rêshkuli'   => 'RESCULLIR',
  'ridhê'      => 'RUTHER',
  'rizundê'    => 'RISUNDEN',
  'shkechubrê' => 'SCEIUBREN',
  'shpiri'     => 'SPURIR',
  'sidi'       => 'SUDIR',
  'snuka'      => 'SNUCAN',
  'subra'      => 'SUBRAN',
  'sudri'      => 'SUDRIR',
  'taobrê'     => 'TAUBREN',
  'traoda'     => 'TRAUDAN',
  'ubri'       => 'UBRIR',
};

# Verb classes
$classtab = {
}; # %class

# Separate subjunctive stems
$subjtab = {
  'achupua'  => 'achupoa',
  'da'       => 'dona',
  'dichi'    => 'doki',
  'feriê'    => 'fêrsê',
  'fôtê'     => 'fêlsê',
  'hizi'     => 'hôrsi',
  'ihmêta'   => 'ihmêrsa',
  'kêshkê'   => 'kêsê',
  'kolaoda'  => 'koloda',
  'kudichi'  => 'kudoki',
  'laoda'    => 'loda',
  'lega'     => 'loga',
  'lêshkê'   => 'lêsê',
  'mêta'     => 'mêrsa',
  'noê'      => 'nozê',
  'pua'      => 'poa',
  'puga'     => 'poga',
  'rênlaoda' => 'rênloda',
  'rênlelê'  => 'rênlêlsê',
  'shterê'   => 'shtêrsê',
  'sôtê'     => 'sêlsê',
  'subra'    => 'sôbra',
  'tôshkê'   => 'tôsê',
}; # $subjtab


my %demeric = (
  'epeza'     => [ qw( ûzâ ûzê epê epeza epezu ûzôn ) ],
  'eza'       => [ qw( sâ sê ê eza ezu sôn ) ],
  'fâli'      => [ qw( fâl fêl fêl fâlu fâlu fâlîn ) ],
  'foli'      => [ qw( ful ful fut folu folu folîn ) ],
  'hizi'      => [ qw( huz hu hut hizu hizu hizîn ) ],
  'kedhê'     => [ qw( kedhâ kedhê kedhu kedha kedhu kên ) ],
  'lhibê'     => [ qw( lhua lhû lhu lhubu lhubu lôn ) ],
  'nhê'       => [ qw( nhe ni ni nheza nhezu nhên ) ],
  'oi'        => [ qw( oh fi fit ou ou oîn ) ],
  'shkrivê'   => [ qw( shkriva shkri shkri shkrivu shkrivu shkrivôn ) ],
  'shtanê'    => [ qw( shtâ shtê shtê shtana shtanu shtôn ) ],
  'rênshtanê' => [ qw( rênshtâ rênshtê rênshtê rênshtana rênshtanu rênshtôn ) ],
);

sub demeric {
  my $verb  = shift;
  my $class = shift;
  my $stem = $verb;
  my $table;

  return $demeric{$verb} if exists $demeric{$verb};

  if(! defined($class) && exists $classtab->{$verb}) {
    $class = $classtab->{$verb};
  }

  $class = 2 if !defined($class) && $verb =~ /a$/;
  $class = 3 if !defined($class) && $verb =~ /ê$/;
  $class = 4 if !defined($class) && $verb =~ /i$/;
  $class = 0 unless defined $class;

  if($class == 1 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( a û ê u u ôn ) ];
  } elsif($stem =~ s/a$//) {
    $table = [ map "$stem$_", qw( â ê ê a u ôn ) ];
  } elsif($class == 3 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( â ê ê a u ên ) ];
  } elsif($stem =~ s/i$//) {
    $table = [ map "$stem$_", '', qw( û i u u în ) ];
  } elsif($class == 5 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", '', qw( û ê u u un ) ];
  } else {
    return;
  }

  # Cadhinor verbs in -c- and -g-
  if($class == 1 || $class == 4 || $class == 5) {
    for(@{$table}[0,3,4,5]) {
      if(exists $cadhctab->{$verb}) {
        s/ch([auoâô]?n?)$/k$1/;
      } elsif(exists $cadhgtab->{$verb}) {
        s/ch([auoâô]?n?)$/g$1/;
      }
    }
    for(@{$table}[1,2]) {
      if(exists $cadhctab->{$verb}) {
        s/k([eiêîû]n?)$/ch$1/;
      } elsif(exists $cadhgtab->{$verb}) {
        s/g([eiêîû]n?)$/ch$1/;
      }
    }
  } elsif($class == 2 || $class == 3) {
    for(@{$table}[0]) {
      if(exists $cadhctab->{$verb}) {
        s/ch([auoâô]?n?)$/k$1/;
      } elsif(exists $cadhgtab->{$verb}) {
        s/ch([auoâô]?n?)$/g$1/;
      }
    }
    for(@{$table}[1,2]) {
      if(exists $cadhctab->{$verb}) {
        s/k([eiêîû]n?)$/ch$1/;
      } elsif(exists $cadhgtab->{$verb}) {
        s/g([eiêîû]n?)$/ch$1/;
      }
    }
  }

  for(@$table) {
    s/shtu$/kchu/;
    s/sht$/ch/;
    s/g$/k/;
    s/b$/p/;
  }

  # spirantise -d -t -p in 4th and 5th conjugation
  if(($class == 4 || $class == 5) && $verb =~ /$vow[dtp][êai]$/o) {
    for($table->[0]) {
      s/d$/dh/;
      s/t$/th/;
      s/p$/f/;
    }

    for(@{$table}[3,4,5]) {
      s/d(un?|în)$/dh$1/;
      s/t(un?|în)$/th$1/;
      s/p(un?|în)$/v$1/;
    }
  }

  # front and back vowel alternations for Cadhinor verbs in -u-
  if(exists $cadhutab->{$verb}) {
    for(@$table) {
      s/i($cons+[aouâôû]?)$/o$1/;
      s/u($cons+[êiî]n?)$/i$1/;
    }
  }

  return $table;
} # demeric

my %scrifel = (
  'epeza' => [ qw( ûzi ûzi epâ ûzu ûzê ûzîn ) ],
  'eza'   => [ qw( fuch fuch fâ fu fuê fûn ) ],
  'kedhê' => [ qw( kedhi kedhi kiâ kedhu kedhê kedhîn ) ],
);

sub scrifel {
  my $verb  = shift;
  my $class = shift;
  my $stem = $verb;
  my $table;

  return $scrifel{$verb} if exists $scrifel{$verb};

  if(! defined($class) && exists $classtab->{$verb}) {
    $class = $classtab->{$verb};
  }

  $class = 2 if !defined($class) && $verb =~ /a$/;
  $class = 3 if !defined($class) && $verb =~ /ê$/;
  $class = 4 if !defined($class) && $verb =~ /i$/;
  $class = 0 unless defined $class;

  if($class == 1 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( i î ), '', qw( ê ê în ) ];
  } elsif($stem =~ s/a$//) {
    $table = [ map "$stem$_", qw( i i â u ê în ) ];
  } elsif($class == 3 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( i i â u ê în ) ];
  } elsif($stem =~ s/i$//) {
    $table = [ map "$stem$_", qw( i ê â ê ê ên ) ];
  } elsif($class == 5 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( i ê ), '', qw( ê ê ên ) ];
  } else {
    return;
  }

  # Cadhinor verbs in -c- and -g-
  if($class == 1 || $class == 2 || $class == 3) {
    for(@$table) {
      if(exists $cadhctab->{$verb}) {
        s/ch([êâu]?)$/k$1/;
        s/k([iî]n?)$/ch$1/;
      } elsif(exists $cadhgtab->{$verb}) {
        s/ch([êâu]?)$/g$1/;
        s/g([iî]n?)$/ch$1/;
      }
    }
  } elsif($class == 4) {
    for(@{$table}[2]) {
      if(exists $cadhctab->{$verb}) {
        s/ch(â)$/k$1/;
      } elsif(exists $cadhgtab->{$verb}) {
        s/ch(â)$/g$1/;
      }
    }
  }

  for(@$table) {
    s/shtu$/kchu/;
    s/g$/k/;
    s/b$/p/;
  }

  # -sht --> -ch in III.sg for 1st conjugation
  # spirantise -d -t -p in 1st conjugation
  if($class == 1) {
    for($table->[2]) {
      s/sht$/ch/;

      if($verb =~ /$vow[dtp][êai]$/o) {
        s/d$/dh/;
        s/t$/th/;
        s/p$/f/;
      }
    }
  }

  # front and back vowel alternations for Cadhinor verbs in -u-
  if(exists $cadhutab->{$verb}) {
    for(@$table) {
      s/i($cons+[uâ]?)$/o$1/;
      s/u($cons+[êiî]n?)$/i$1/;
    }
  }

  return $table;
} # scrifel

my %izhcrifel = (
  'eza' => [ qw( firi firi furâ furu furê firiôn ) ],
);

sub izhcrifel {
  my $verb  = shift;
  my $class = shift;
  my $stem = $verb;
  my $table;

  return $izhcrifel{$verb} if exists $izhcrifel{$verb};

  if(! defined($class) && exists $classtab->{$verb}) {
    $class = $classtab->{$verb};
  }

  $class = 2 if !defined($class) && $verb =~ /a$/;
  $class = 3 if !defined($class) && $verb =~ /ê$/;
  $class = 4 if !defined($class) && $verb =~ /i$/;
  $class = 0 unless defined $class;

  if($class == 1 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( ri rî êr rê rê rîn ) ];
  } elsif($stem =~ s/a$//) {
    $table = [ map "$stem$_", qw( ri ri râ ru rê rîn ) ];
  } elsif($class == 3 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( ri ri râ ru rê rîn ) ];
  } elsif($stem =~ s/i$//) {
    $table = [ map "$stem$_", qw( ri rê râ rê rê rên ) ];
  } elsif($class == 5 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( ri rê êr rê rê rên ) ];
  } else {
    return;
  }

  return $table;
} # izhcrifel

my %budemeric = (
  'eza' => [ qw( êshta êshtê êshtê êshta êshtu êshtôn ) ],
);

sub budemeric {
  my $verb  = shift;
  my $class = shift;
  my $stem = $verb;
  my $table;

  return $budemeric{$verb} if exists $budemeric{$verb};

  return demeric($subjtab->{$verb}, $class) if exists $subjtab->{$verb};

  if(! defined($class) && exists $classtab->{$verb}) {
    $class = $classtab->{$verb};
  }

  $class = 2 if !defined($class) && $verb =~ /a$/;
  $class = 3 if !defined($class) && $verb =~ /ê$/;
  $class = 4 if !defined($class) && $verb =~ /i$/;
  $class = 0 unless defined $class;

  if($class == 1 && $stem =~ s/ê$/t/) {
    $table = [ map "$stem$_", qw( a ê ê u u ôn ) ];
  } elsif($stem =~ s/a$/m/) {
    $table = [ map "$stem$_", qw( â ê ê a u ôn ) ];
  } elsif($class == 3 && $stem =~ s/ê$/m/) {
    $table = [ map "$stem$_", qw( â ê ê a u ên ) ];
  } elsif($stem =~ s/i$/t/) {
    $table = [ map "$stem$_", '', '', qw( i u u în ) ];
    for(@$table) {
      s/t$/ech/;
      s/tu$/chu/;
      s/t(ti|chu|tîn)$/$1/; # for beshti
    }
  } elsif($class == 5 && $stem =~ s/ê$/t/) {
    $table = [ map "$stem$_", '', '', qw( i u u în ) ];
    for(@$table) {
      s/t$/ech/;
      s/tu$/chu/;
    }
  } else {
    return;
  }

  return $table;
} # budemeric


my %buscrifel = (
  'eza' => [ qw( êshka êshkê êshkê êshka êshku êshkôn ) ],
);

sub buscrifel {
  my $verb  = shift;
  my $class = shift;
  my $stem = $verb;
  my $table;

  return $buscrifel{$verb} if exists $buscrifel{$verb};

  return scrifel($subjtab->{$verb}, $class) if exists $subjtab->{$verb};

  if(! defined($class) && exists $classtab->{$verb}) {
    $class = $classtab->{$verb};
  }

  $class = 2 if !defined($class) && $verb =~ /a$/;
  $class = 3 if !defined($class) && $verb =~ /ê$/;
  $class = 4 if !defined($class) && $verb =~ /i$/;
  $class = 0 unless defined $class;

  if($class == 1 && $stem =~ s/ê$/k/) {
    $table = [ map "$stem$_", qw( a ê ê u u ôn ) ];
    for(@$table) {
      s/kê$/chê/;
    }
  } elsif($stem =~ s/a$/n/) {
    $table = [ map "$stem$_", qw( â ê ê a u ôn ) ];
  } elsif($class == 3 && $stem =~ s/ê$/n/) {
    $table = [ map "$stem$_", qw( â ê ê a u ên ) ];
  } elsif($stem =~ s/i$/r/) {
    $table = [ map "$stem$_", '', '', qw( i u u în ) ];
    for(@$table) {
      s/r$/ir/;
    }
  } elsif($class == 5 && $stem =~ s/ê$/r/) {
    $table = [ map "$stem$_", '', '', qw( i u u în ) ];
    for(@$table) {
      s/r$/ir/;
    }
  } else {
    return;
  }

  return $table;
} # bucrifel


my %befel = (
);

sub befel {
  my $verb = shift;
  my $class = shift;
  my $stem = $verb;
  my $table;

  return $befel{$verb} if exists $befel{$verb};

  if(! defined($class) && exists $classtab->{$verb}) {
    $class = $classtab->{$verb};
  }

  $class = 2 if !defined($class) && $verb =~ /a$/;
  $class = 3 if !defined($class) && $verb =~ /ê$/;
  $class = 4 if !defined($class) && $verb =~ /i$/;
  $class = 0 unless defined $class;

  if($class == 1 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", '', '', 'a', '', 'êl', 'an' ];
  } elsif($stem =~ s/a$//) {
    $table = [ map "$stem$_", '', '', 'a', '', 'el', 'an' ];
  } elsif($class == 3 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", '', '', 'a', '', 'el', 'an' ];
  } elsif($stem =~ s/i$//) {
    $table = [ map "$stem$_", '', '', 'a', '', 'u',  'an' ];
  } elsif($class == 5 && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", '', '', 'a', '', 'u',  'an' ];
  } else {
    return;
  }

  for(@$table) {
    # Cadhinor verbs in -c- and -g-
    if(exists $cadhctab->{$verb}) {
      s/k([eiêîû]?)$/ch/;
    } elsif(exists $cadhgtab->{$verb}) {
      s/g([eiêîû]?)$/ch/;
    }

    s/shtu$/kchu/;
    s/sht(an?)$/kch$1/;
    s/sht$/ch/;
    s/g$/k/;
    s/b$/p/;
  }

  # front and back vowel alternation in II.sg of 2nd and 3rd conjugation
  if($verb =~ /a$/ || $class == 3) {
    for($table->[1]) {
      s/u($cons+)$/i$1/;
    }
  }

  # front and back vowel alternations in III.sg + III.pl
  # and spirantisation
  for(@{$table}[2,5]) {
    s/([dtp])(an?)$/$spir{$1}$2/;
    s/u($cons+an?)$/i$1/;
  }

  # I.sg and I.pl don't exist
  @{$table}[0,3] = (undef, undef);

  return $table;
} # befel


my %part = (
);

# Participles
sub part {
  my $verb = shift;
  my $class = shift;
  my $stem = $verb;

  my($present, $past);

  if(exists $part{$verb}) {
    ($present, $past) = @{ $part{$verb} };
  } else {
    if(! defined($class) && exists $classtab->{$verb}) {
      $class = $classtab->{$verb};
    }

    $class = 2 if !defined($class) && $verb =~ /a$/;
    $class = 3 if !defined($class) && $verb =~ /ê$/;
    $class = 4 if !defined($class) && $verb =~ /i$/;
    $class = 0 unless defined $class;

    if($class == 1 && $stem =~ s/ê$//) {
      ($past, $present) = map "$stem$_", 'êl', 'il';
    } elsif($stem =~ s/a$//) {
      ($past, $present) = map "$stem$_", 'u', 'ê';
    } elsif($class == 3 && $stem =~ s/ê$//) {
      ($past, $present) = map "$stem$_", 'u', 'ê';
    } elsif($stem =~ s/i$//) {
      ($past, $present) = map "$stem$_", 'u', 'i';
    } elsif($class == 5 && $stem =~ s/ê$//) {
      ($past, $present) = map "$stem$_", 'êl', 'ê';
    } else {
      return;
    }
  }

  for($past, $present) {
    # Cadhinor verbs in -c- and -g-
    if(exists $cadhctab->{$verb}) {
      s/ch([auoâô])$/k/;
      s/k([eiêîû])$/ch/;
    } elsif(exists $cadhgtab->{$verb}) {
      s/ch([auoâô]?)$/g/;
      s/g([eiêîû])$/ch/;
    }

    s/shtu$/kchu/;
  }

  return wantarray ? ($present, $past) : [ $present, $past ];
}



$gendertab = {
  'âshta' => 'masc',
  'eli' => 'masc',
  'lônd' => 'masc',

  'kal' => 'neut',
  'manu' => 'neut',
  'nôshti' => 'neut',
  'shkor' => 'neut',
  'shpâ' => 'neut',

  'chir' => 'fem',
  'elorê' => 'fem',
  'kabrâ' => 'fem',
  'medhi' => 'fem',
  'nor' => 'fem',

  'achel' => 'fem',
  'acher' => 'masc',
  'Achirê' => 'fem',
  'âdh' => 'masc',
  'âdhechu' => 'masc',
  'adipa' => 'masc',
  'adlelek' => 'fem',
  'adlelu' => 'fem',
  'air' => 'fem',
}; # $gendertab

$pluraltab = {
  'âshta' => 'âshtâ',
  'eli' => 'eliri',
  'lônd' => 'lôndi',

  'kal' => 'kalo',
  'manu' => 'mani',
  'nôshti' => 'nôkchu',
  'shkor' => 'shkoru',
  'shpâ' => 'shpao',

  'chir' => 'chirâ',
  'elorê' => 'eloriê',
  'kabrâ' => 'kabrachâ',
  'medhi' => 'medhiê',
  'nor' => 'norê',

  'âdhechu' => 'âdhechuni',
}; # $pluraltab

sub noun {
  my $noun = shift;
  my $gender = shift;
  my $plural = shift;
  my $table;

  # is it a pronoun?
  # nom acc dat gen   nom acc/dat gen
  return [ qw( sû   sêth sû  (eri)  ta   tâ (tandê) ) ] if $noun eq 'sû';
  return [ qw( lê   êk   lê  (leri) mukh mî (mundê) ) ] if $noun eq 'lê';
  return [ qw( ât   âtô  âta  âti   kâ   kâ (kandê) ) ] if $noun eq 'ât';
  return [ qw( tot  tô   tota toti  kâ   kâ (kandê) ) ] if $noun eq 'tot';
  return [ qw( kêt  kêtô kêta kêti   ), (undef) x 3   ] if $noun eq 'kêt';
  return [ qw( ta   tâ   tao (tandê) ), (undef) x 3   ] if $noun eq 'ta';
  return [ qw( mukh mî   mî  (mundê) ), (undef) x 3   ] if $noun eq 'mukh';
  return [ qw( kâ   kâ   kâ  (kandê) ), (undef) x 3   ] if $noun eq 'kâ';
  return [ '', qw( zêth zeu zei ), '', qw( zaa zai )  ] if $noun eq 'zê';
  return [ '', qw( zaa  zau zai ),      (undef) x 3   ] if $noun eq 'za';

  # otherwise it's a noun.

  # irregular oblique stem
  return [ qw( pû pû pea peo pei peî peich ) ] if $noun eq 'pû';

  if(!defined($gender) && exists $gendertab->{$noun}) {
    $gender = $gendertab->{$noun};
  }

  if(!defined($gender)) {
    # try to guess based on the ending
    if($noun =~ /a$/) {
      $gender = 'masc';
    } elsif($noun =~ /ê$/) {
      $gender = 'fem';
    } elsif($noun =~ /$consend/o && defined $plural && $plural =~ /i$/) {
      $gender = 'masc'; # can't detect anisosyllabic nouns as they
                        # could be neuter
    } elsif($noun =~ /(?:$cons|i)$/o && defined $plural && $plural =~ /[ou]$/) {
      $gender = 'neut';
    } elsif($noun =~ /â$/ && defined $plural && $plural =~ /ao$/) {
      $gender = 'neut';
    } elsif($noun =~ /(?:$cons|i)$/o && defined $plural && $plural =~ /[âê]$/) {
      $gender = 'fem';
    } elsif($noun =~ /â$/ && defined $plural && $plural =~ /ach$/) {
      $gender = 'fem';
    } else {
      return;
    }
  }

  if(!defined($plural) && exists $pluraltab->{$noun}) {
    $plural = $pluraltab->{$noun};
  }

  if(!defined($plural)) {
    # try to guess based on the ending
    if($noun =~ /$consend/o && $gender eq 'masc') {
      $plural = $noun . 'i'; # assume isosyllabic
    } elsif($noun =~ /a$/ && $gender eq 'masc') {
      ($plural = $noun) =~ s/a$/â/;
    } elsif($noun =~ /u$/ && $gender eq 'masc') {
      $plural = $noun . 'li'; # assume from -ul
    } elsif($noun =~ /$consend/o && $gender eq 'neut') {
      $plural = $noun . 'o'; # more than twice as comman as -u
    } elsif($noun =~ /i$/ && $gender eq 'neut') {
      ($plural = $noun) =~ s/i$/u/;
    } elsif($noun =~ /u$/ && $gender eq 'neut') {
      ($plural = $noun) =~ s/u$/i/;
    } elsif($noun =~ /â$/ && $gender eq 'neut') {
      ($plural = $noun) =~ s/â$/ao/;
    } elsif($noun =~ /$consend/o && $gender eq 'fem') {
      $plural = $noun . 'â'; # "very common"
    } elsif($noun =~ /u$/ && $gender eq 'fem') {
      $plural = $noun . 'lâ'; # assume from -ul
    } elsif($noun =~ /i$/ && $gender eq 'fem') {
      $plural = $noun . 'ê';
    } elsif($noun =~ /ê$/ && $gender eq 'fem') {
      ($plural = $noun) =~ s/ê/iê/;
    } elsif($noun =~ /â$/ && $gender eq 'fem') {
      ($plural = $noun) =~ s/â/achâ/;
    } else {
      return;
    }
  }

  my $sgstem = $noun;
  my $plstem = $plural;

  if($gender eq 'masc') {
    if($sgstem =~ /u$/ && $plstem =~ s/li$//) {
      $table = [ map("$sgstem$_", '', '', 'la', 'lo'),
                 map("$plstem$_", 'li', 'lî', 'lich') ];
    } elsif($plstem =~ s/i$//) {
      $table = [ map("$sgstem$_", '', '', 'a', 'o'),
                 map("$plstem$_", 'i', 'î', 'ich') ];
    } elsif($sgstem =~ s/a$// && $plstem =~ s/â$//) {
      $table = [ map("$sgstem$_", 'a', '', 'a', 'o'),
                 map("$plstem$_", 'â', 'î', 'ach') ];
    } else {
      return;
    }
  } elsif($gender eq 'neut') {
    if($sgstem =~ /$consend/o && $plstem =~ s/o$//) {
      $table = [ map("$sgstem$_", '', 'u', 'u', 'o'),
                 map("$plstem$_", 'o', 'oi', 'och') ];
    } elsif($sgstem =~ /$consend/o && $plstem =~ s/u$//) {
      $table = [ map("$sgstem$_", '', 'u', 'u', 'o'),
                 map("$plstem$_", 'u', 'î', 'ich') ];
    } elsif($sgstem =~ s/i$// && $plstem =~ s/u$//) {
      $table = [ map("$sgstem$_", 'i', 'i', 'i', 'io'),
                 map("$plstem$_", 'u', 'î', 'ich') ];
    } elsif($sgstem =~ s/u$// && $plstem =~ s/i$//) {
      $table = [ map("$sgstem$_", 'u', '', 'u', 'o'),
                 map("$plstem$_", 'i', 'î', 'ich') ];
    } elsif($sgstem =~ s/â$// && $plstem =~ s/ao$//) {
      $table = [ map("$sgstem$_", 'â', 'â', 'â', 'ach'),
                 map("$plstem$_", 'ao', 'aoi', 'aoch') ];
    } else {
      return;
    }
  } elsif($gender eq 'fem') {
    if($sgstem =~ /$consend/o && $plstem =~ s/â$//) {
      $table = [ map("$sgstem$_", '', 'a', 'ê', 'ach'),
                 map("$plstem$_", 'â', 'êi', 'ech') ];
    } elsif($sgstem =~ /$consend/o && $plstem =~ s/ê$//) {
      $table = [ map("$sgstem$_", '', 'e', 'ê', 'ech'),
                 map("$plstem$_", 'ê', 'êi', 'ech') ];
    } elsif($sgstem =~ /i$/ && $plstem =~ s/iê/i/) {
      $table = [ map("$sgstem$_", '', '', 'ê', 'ch'),
                 map("$plstem$_", 'ê', 'a', 'ech') ];
    } elsif($sgstem =~ s/ê$// && $plstem =~ s/ê$//) {
      $table = [ map("$sgstem$_", 'ê', 'e', 'ê', 'ech'),
                 map("$plstem$_", 'ê', 'a', 'ech') ];
    } elsif($sgstem =~ s/â$// && $plstem =~ s/â$//) {
      $table = [ map("$sgstem$_", 'â', 'a', 'ê', 'ach'),
                 map("$plstem$_", 'â', 'a', 'ech') ];
    } elsif($sgstem =~ /u$/ && $plstem =~ s/lâ$//) {
      $table = [ map("$sgstem$_", '', 'la', 'lê', 'lach'),
                 map("$plstem$_", 'lâ', 'lêi', 'lech') ];
    } elsif($sgstem =~ /u$/ && $plstem =~ s/â$//) { # chizu; others?
      $table = [ map("$sgstem$_", '', 'a', 'ê', 'ach'),
                 map("$plstem$_", 'â', 'êi', 'ech') ];
    } else {
      return;
    }
  } else {
    return;
  }

  return $table;
}


# Lost consonants which are restored in all but s.nom. and m.s.acc.

$rootconstab = {
  'andû'  => 'r',
  'aveku' => 'r',
  'dhu'   => 'n',
  'di'    => 'n',
  'du'    => 'r',
  'glûmu' => 'l',
  'kê'    => 'r',
  'kônu'  => 'l',
  'kû'    => 'r',
  'melhu' => 'r',
  'mu'    => 'r',
  'na'    => 'n',
  'osôku' => 'l',
  'rhu'   => 'm',
}; # $rootconstab

sub adj {
  my $adj = shift;
  my $rootcons = shift;
  my $stem = $adj;
  my $table;

  if(!defined($rootcons) && exists $rootconstab->{$adj}) {
    $rootcons = $rootconstab->{$adj};
  }

  $rootcons = '' unless defined $rootcons;

  if($stem =~ /$consend/o || length $rootcons) {
    $table = [ [ $stem, $stem, map "$stem$rootcons$_", qw( a o i î ich ) ],
               [ $stem, map "$stem$rootcons$_", qw( u u o o î ich ) ],
               [ $stem, map "$stem$rootcons$_", qw( a ê ach â êi ech ) ] ];
  } elsif($stem =~ s/ê$//) {
    $table = [ [ map "$stem$_", qw( ê ê a o ê î êch ) ],
               [ map "$stem$_", qw( e ê ê o e ê ech ) ],
               [ map "$stem$_", qw( ê e ê ech ê êi ech ) ] ];
  } elsif($stem =~ s/i$//) {
    $table = [ [ map "$stem$_", 'i', '', qw( i io i î ich ) ],
               [ map "$stem$_", qw( i i i io u î ich ) ],
               [ map "$stem$_", qw( i i iê ich iê ia iech ) ] ];
  } elsif($stem =~ s/â$//) {
    $table = [ [ map "$stem$_", qw( â â â ach ao aoi aoch ) ],
               [ map "$stem$_", qw( â â â ach ao aoi aoch ) ],
               [ map "$stem$_", qw( â a ê ach achâ acha achech ) ] ];
  } else {
    return;
  }

  return $table;
}

1;
__END__

=head1 NAME

Lingua::Zompist::Barakhinei - Inflect Barakhinei nouns, verbs, and adjectives

=head1 VERSION

This document refers to version 0.02 of Lingua::Zompist::Barakhinei, released
on 2002-06-26.

=head1 SYNOPSIS

  use Lingua::Zompist::Barakhinei;
  $i_am = Lingua::Zompist::Barakhinei::demeric('eza')->[0];

or

  use Lingua::Zompist::Barakhinei ':all';
  $i_am = demeric('eza')->[0];

or

  use Lingua::Zompist::Barakhinei qw( demeric scrifel );
  $you_know = demeric("shkriv\xea", 1)->[1];
  $they_had = crifel("ten\xea", 1)->[5];
  # note "\xea" = e with circumflex

  
  # nouns and pronouns
  $word = noun('belu', 'masc', 'beluri');  # nouns
  $word = noun("s\xfb");    # pronouns ("\xfb" is u with circumflex: su^)
  $word = noun('mukh');
  # in general
  $word = noun( NOUN [, GENDER [, PLURAL ] ] );

  # adjectives
  $word = adj("kh\xf4t\xea");  # adjectives (ho^te^)

  # verbs
  # note: "ibr\xea" is ibre^
  $word = demeric("ibr\xea", 1);   # present
  $word = scrifel("ibr\xea", 1);   # past
  $word = izhcrifel("ibr\xea", 1); # past anterior
  $word = budemeric("ibr\xea", 1); # present subjunctive
  $word = buscrifel("ibr\xea", 1); # past subjunctive
  $word = befel("ibr\xea", 1);     # imperative
  $word = part("ibr\xea", 1);      # participles
  # in general
  $word = FUNC( VERB [, CLASS ] );

  # Setting inflection tables
  # nouns
  $Lingua::Zompist::Barakhinei::gendertab = \%mygendertab;
  $Lingua::Zompist::Barakhinei::pluraltab = \%mypluraltab;
  # verbs
  $Lingua::Zompist::Barakhinei::classtab = \%myclasstab;

  # ones that you will probably not need as often
  $Lingua::Zompist::Barakhinei::rootconstab = \%myrootconstab;
  $Lingua::Zompist::Barakhinei::subjtab = \%mysubjtab;
  $Lingua::Zompist::Barakhinei::cadhctab = \%mycadhctab;
  $Lingua::Zompist::Barakhinei::cadhgtab = \%mycadhgtab;
  $Lingua::Zompist::Barakhinei::cadhutab = \%mycadhutab;

=head1 DESCRIPTION

=head2 Overview

Lingua::Zompist::Barakhinei is a module which allows you to inflect
Barakhinei words. You can conjugate verbs and decline nouns, pronouns,
and adjectives.

There is one function to inflect nouns and pronouns, and another to
inflect adjectives. Verbs are covered by several functions: one for each
tense or mood and another for the participles.

=head2 Exports

Lingua::Zompist::Barakhinei exports no functions by default, in order to
avoid namespace pollution. This enables, for example,
Lingua::Zompist::Barakhinei and Lingua::Zompist::Cadhinor to be used in
the same program, since otherwise many of the function names would
clash. However, all functions listed here can be imported explicitly by
naming them, or they can be imported all together by using the tag
':all'.

=head2 A note on the character set used

This module expects input to be in iso-8859-1 (Latin-1) and will return
output in that character set as well. For example, I<lelcE<ecirc>>
(meaning I<to see>) should have a byte with the value 234 as the last
character, and its accusative, I<lelcE<acirc>>, will have a byte with
the value 226 as its last character.

In the future, this module may expect and produce the charset used by
the F<Maraille> font. At that point, the module Lingua::Zompist::Convert
is expected to be available, which should be able to convert between
that charset and standard charsets such as iso-8859-1 and utf-8.

=head2 noun

This function allows you to inflect nouns and pronouns.

It takes three arguments. All but the first are optional (and the
function will guess or use entries from L</$gendertab> and/or
L</$pluraltab> if they are not provided).

=over 4

=item *

The noun or pronoun to inflect.

=item *

(optional) The gender of the noun (one of 'masc', 'neut', or 'fem'), or
C<undef> for the function to guess. (This can remain C<undef> for
pronouns.)

=item *

(optional) The (nominative) plural of the noun, or C<undef> for the
function to guess.

In Barakhinei, it is necessary to know the singular, the gender, B<and>
the plural of a noun in order to inflect a noun correctly. However, if
you do know the plural form, you can pass C<undef> to this function and
the function will attempt to guess based on a built-in list of nouns.

=back

C<noun> returns an arrayref on success, or C<undef> or the empty list on
failure (for example, because it could not determine which declension or
gender a noun belonged to).

In general, the arrayref will have seven elements, in the following
order: nominative singular, accusative singular, dative singular,
genitive singular, nominative plural, accusative/dative plural, genitive
plural. In some cases, some of those elements may be C<undef>; the most
common case is when you ask for the declension of a plural personal
pronoun such as I<ta> or I<kE<ecirc>t>.

B<Notes:>

=over 4

=item *

If you use a singular personal pronoun as input to this function, you
will get back an arrayref with seven elements, corresponding to both
singular and plural forms of the pronoun. B<Note> that this will cause
the accusative/dative distinction to be thrown in away in the plural
forms, since nouns make no such distinction! So it is better to input
the plural form separately to get the full form.

(This behaviour may change in the future. I'm not sure whether dropping
one form is the right thing to do... singular pronouns may end up
returning only the first four elements filled.)

If you use a plural personal pronoun as input to this function, only the
first four elements will be filled (with the plural forms) and the last
three elements will be C<undef>. This appears to be more DWIMmish (at
least, it is for me -- I've used I<ta>, for example, as input and
wondered why it was being treated as a noun rather than as a personal
pronoun).

=item *

The genitive form of I<sE<ucirc>>, I<lE<ecirc>>, I<ta>, I<mukh>, and
I<kE<acirc>> will be returned in parenthesis to show that it is a
regular adjective and not an undeclined genitive form.

=item *

The reflexive pronouns are listed under the pseudo-nominative forms
I<zE<ecirc>> and I<za>; in the return list, the nominative forms will be
the empty string.

=back

=head2 adj

This function inflects adjectives. It expects two arguments:

=over 4

=item *

The adjective to be inflected

=item *

(optional) The root consonant in the oblique forms (for example, for
I<na> "north", which has the root I<nan-> in the oblique forms, pass in
C<'na'> and C<'n'>). If you pass in undef for this argument or simply
leave it out, the function will attempt to guess whether the adjective
has a different oblique stem (using L</$rootconstab>).

=back

C<adj> returns an arrayref on success and C<undef> or the empty list on
failure.

The arrayref will itself contain three arrayrefs, each with seven
elements. The first arrayref will contain the masculine forms, the
second arrayref the neuter forms, and the third arrayref the feminine
forms. The forms are in the same order as in the arrayref returned by
the L<noun|/"noun"> function.  Briefly, this order is nominative -
accusative - dative - genitive in the singular and nominative -
accusative/dative - genitive in the plural.

This function should determine the declension of an adjective
automatically.

There is currently no function which returns the declension of an
adjective (partly because the matter is so simple -- declension I
adjectives end in -C or have an extra oblique stem consonant, declension
II adjectives end in -E<ecirc>, and declension III adjectives end in -i);
however, if there is popular demand for such a function it could be
quickly added.

=head2 demeric

This function declines a verb in the present tense. It takes two
arguments:

=over 4

=item *

The verb to be conjugated

=item *

(optional) The declension of the verb as an integer (only strictly
necessary for verbs in I<-E<ecirc>>, which can be first, third, or fifth
declension, corresponding to Cadhinor verbs in I<-EC>, I<-EN>, and
I<-ER>)

=back

C<demeric> returns an arrayref on success and C<undef> or the empty list
on failure.

The arrayref will contain six elements, in the following order: first
person singular ("I"), second person singular ("thou"), third person
singular ("he/she/it"), first person plural ("we"), second person plural
("[all of] you"), third person plural ("they").

=head2 scrifel

This function declines a verb in the past tense. It is otherwise similar
to the function L<demeric|/"demeric">.

=head2 izhcrifel

This function declines a verb in the past anterior tense. It is
otherwise similar to the function L<demeric|/"demeric">.

=head2 budemeric

This function declines a verb in the present subjunctive. It is otherwise
similar to the function L<demeric|/"demeric">.

The name derives from Cadhinor grammar terms I<buprilise> "remote" and
I<demeric> "present", since the Barakhinei subjunctive mood derived from
the Cadhinor remote forms of a verb.

=head2 buscrifel

This function declines a verb in the past subjunctive. It is otherwise
similar to the function L<demeric|/"demeric">.

The name derives from Cadhinor grammar terms I<buprilise> "remote" and
I<scrifel> "past", since the Barakhinei subjunctive mood derived from
the Cadhinor remote forms of a verb.

=head2 befel

This function declines a verb in the imperative. It is otherwise similar
to the function L<demeric|/"demeric">.

=over 4

=item Note

The first and fourth elements of the arrayref will be empty, since
Barakhinei has no first person imperative, neither singular nor plural.

=back

=head2 part

This function returns the two participles of a verb. It takes the verb
and declension number (compare L</demeric>) as an argument and returns
an arrayref (in scalar context) or a list (in list context) of two
elements: the present participle and the past participle. On failure,
this function returns C<undef> or the empty list.

Specifically, the form returned for each participle is the masculine
nominative singular form of the participle (which is the citation form).
Since participles decline like regular adjectives (with an oblique stem
consonant of 'l' in the case of participles in I<-u>), the other forms
of the participles may be obtained by calling the L<adj|/"adj">
function, if desired.

=head2 Tables

Since inflection in Barakhinei usually cannot be determined by the
ending alone, this module makes use of lookup tables to provide
additional information. For example, nouns ending in a consonant can be
masculine, feminine, or neuter; if the gender is not passed explicitly
to the L</noun> function, that function attempts first to lookup the
gender in a table, and if that fails, it attempts to guess the gender
from the ending. Similarly with verb inflections or with the plural of
nouns.

This section describes the various lookup tables which the module uses
to perform its inflection tasks. All the tables described here can be
overridden from the outside; this is most useful for C<$gendertab>,
C<$pluraltab>, and C<$classtab>, which do not come pre-filled since they
would be fairly large.

It is up to you how you fill those tables -- you can leave them empty,
the way they come, and explicitly pass the necessary information to each
function; you can fill the tables from a hash which you initialise
statically in your code; you can read in the data from a file each time;
or you could use a tied hash (say, a DBM file). The last can be useful
if you only want to make a couple of requests and don't want to load the
entire database into memory; simply tie the data to a hash in your
program and assign a reference to that hash to the appropriate variable.

Sample tables, generated programmatically from baralex.htm as of
2002-05-29 and hand-massaged slightly afterwards, are included as
tab-separated value files: F<class.tsv>, F<gender.tsv>, and
F<plural.tsv>. It will be trivial to convert those to any representation
you desire. There may also be other tab-separated value files in the
distribution; have a look. Their purpose should be obvious from the
filename.

These are the lookup tables which are used by the program and which can
be influenced from outside:

=over 4

=item $gendertab

This is a hashref whose keys are nouns and whose values are one of
C<'masc'>, C<'fem'>, or C<'neut'>. This is used to determine the gender
of nouns. For example:

  san => 'neut',

indicating that the noun I<san> is neuter.

=item $pluraltab

This is a hashref whose keys are nouns and whose values are the plural
form of the noun. For example:

  ibor => 'ibro',

indicating that the (nominative) plural of the noun I<ibor> is I<ibro>.

=item $classtab

This is a hashref whose keys are verbs and whose values are the
declension number. First declension verbs end in I<-E<ecirc>> and derive
from Cadhinor verbs in I<-EC>; second declension verbs end in I<-a> and
derive from Cadhinor verbs in I<-AN>; third declension verbs end in
I<-E<ecirc>> and derive from Cadhinor verbs in I<-EN>; fourth declension
verbs end in I<-i> and derive from Cadhinor verbs in I<-IR>; fifth
declension verbs end in I<-E<ecirc>> and derive from Cadhinor verbs in
I<-ER>.

Strictly speaking, entries in this hashref are necessary only for first
and fifth declension verbs; second and fourth declension verbs can be
identified by their endings alone, and verbs ending in I<-E<ecirc>> are
taken to be third declension if no other declension is specified.

An example entry is

  "hab\xea" => 5,

indicating that the verb I<habE<ecirc>> is a fifth declension verb. (In
your source code, you'd probably write C<hab\xea> as C<habE<ecirc>>.)

=item $rootconstab

This is a hashref whose keys are adjectives and whose values are the
extra consonant which is added to the end in the oblique forms, for
first declension adjectives such as I<na, nan->. This would be listed as

  na => 'n',

You may not need to add to this table, as there aren't that many of
these adjectives, and the ones listed in baralex.htm as of 2002-05-29
should already be in the module.

=item $subjtab

This is a hashref whose keys are verbs and whose values are the
subjunctive forms of those verbs. This is used for verbs which use a
different subjunctive stem (derived from Cadhinor verbs with a separate
remote stem), for example

  laoda => 'loda',

which indicates that the subjunctive stem of I<laoda> is I<lod->. As
indicated in the example, the final letter of the subjunctive stem
should be the same as that of the normal infinitive; effectively, it is
as if the subjunctive of those verbs is the indicative of another verb.

You may not need to add to this table, as there aren't that many of
these verbs, and the ones listed in baralex.htm as of 2002-05-29 should
already be in the module.

=item $cadhctab

This is a hashref whose keys are verbs which derive from a Cadhinor verb
with a I<-C-> stem consonant. The value is not used (but it is a good
idea to have the value be true; for example, you could use the Cadhinor
infinitive). This is used because verbs deriving from Cadhinor verbs in
I<-C-> suffer consonant changes in some forms. Compare L</$cadhgtab>.

You will probably not need to add to or replace this table.

=item $cadhgtab

This is a hashref whose keys are verbs which derive from a Cadhinor verb
with a I<-G-> stem consonant. The value is not used (but it is a good
idea to have the value be true; for example, you could use the Cadhinor
infinitive). This is used because verbs deriving from Cadhinor verbs in
I<-G-> suffer consonant changes in some forms. Compare L</$cadhctab>.

You will probably not need to add to or replace this table.

=item $cadhutab

This is a hashref whose keys are verbs which derive from a Cadhinor verb
with a I<-U-> in the last syllable of the verb stem. The value is not
used (but it is a good idea to have the value be true; for example, you
could use the Cadhinor infinitive). This is used because verbs deriving
from Cadhinor verbs with I<-U-> suffer vowel changes in some forms.
Compare L</$cadhctab> and L</$cadhgtab>.

=back

=head1 BUGS

This module should handle irregular words correctly. However, if there
is a word that is inflected incorrectly, please send me email and notify
me. (Since Barakhinei has all sorts of funky sound changes, I wouldn't
be surprised if this module makes mistakes! However, I think it handles
correctly all the examples on the web page as of 2002-05-29.)

However, please make sure that you have checked against a current
version of http://www.zompist.com/bara.htm or that you asked Mark
Rosenfelder himself; the grammar occasionally changes as small errors
are found or words change.

=head1 TODO

=over 4

=item *

Flesh out the dictionary from baralex.htm.

=item *

document masculines & feminines in -u (decline like adjectives)

=item *

test masculines & feminines in -u (e.g. rizundu = m/f, klE<acirc>tandu =
m, redE<ecirc>lu = f)

=item *

test adjectives in -E<acirc>: mudrE<acirc>, shkrE<acirc>

=item *

test pE<ucirc>/pe-

=item *

test verbs with different subjunctive stems

=back

=head1 SEE ALSO

L<Lingua::Zompist::Verdurian>,
L<Lingua::Zompist::Kebreni>,
L<Lingua::Zompist::Cadhinor>,
http://www.zompist.com/bara.htm

=head1 FEEDBACK

If you use this module, I'd appreciate it if you drop me a line at the
email address in L</AUTHOR>, just so that I have an idea of how many
people use this module at all. Also, if you have any comments, feel free
to email me.

=head1 AUTHOR

Philip Newton, E<lt>pne@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

(This is basically the BSD licence.)

Copyright (C) 2002 by Philip Newton.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

=over 4

=item *

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer. 

=item *

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution. 

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
