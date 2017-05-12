package Lingua::Zompist::Cadhinor;

use 5.005;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %verb);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::Zompist::Cadhinor ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = (
  'all' => [ qw(
    demeric
    scrifel
    izhcrifel
    budemeric
    buscrifel
    bubefel
    dynamic
    part
    noun
    adj
    comp
    super
    adv
  ) ],
  'verb' => [ qw(
    demeric
    scrifel
    izhcrifel
    budemeric
    buscrifel
    bubefel
    dynamic
    part
  ) ],
  'nonverb' => [ qw(
    noun
    adj
    comp
    super
    adv
  ) ],
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, '%verb' );

@EXPORT = qw(
	
);
$VERSION = '0.92';

%verb = (
  static => {
    prilise => {
      demeric   => \&demeric,
      scrifel   => \&scrifel,
      izhcrifel => \&izhcrifel,
      befel     => sub { return; }, # no definite imperative
    },
    buprilise => {
      demeric   => \&budemeric,
      scrifel   => \&buscrifel,
      izhcrifel => sub { return; }, # no remote past anterior
      befel     => \&bubefel,
    },
  },
# dynamic => \&dynamic
  dynamic => {
    prilise => {
      demeric   => sub { dynamic( $_[0], 'prilise', 'demeric' ); },
      scrifel   => sub { dynamic( $_[0], 'prilise', 'scrifel' ); },
      izhcrifel => sub { dynamic( $_[0], 'prilise', 'izhcrifel' ); },
      befel     => sub { return; }, # no definite imperative
    },
    buprilise => {
      demeric   => sub { dynamic( $_[0], 'buprilise', 'demeric' ); },
      scrifel   => sub { dynamic( $_[0], 'buprilise', 'scrifel' ); },
      izhcrifel => sub { return; }, # no remote past anterior
      befel     => \&bubefel, # same for static and dynamic aspects
    },
  },
  part => \&part,
);

# Set up aliases
{
  my($aspect, $mood, $tense);

  $verb{'nuncre'} = $verb{'static'};
  $verb{'olocec'} = $verb{'dynamic'};

  for $aspect (qw(static dynamic)) {
    $verb{$aspect}{definite} = $verb{$aspect}{prilise};
    $verb{$aspect}{remote}   = $verb{$aspect}{buprilise};

    for $mood (qw(prilise buprilise)) {
      $verb{$aspect}{$mood}{'present'}       = $verb{$aspect}{$mood}{demeric};
      $verb{$aspect}{$mood}{'past'}          = $verb{$aspect}{$mood}{scrifel};
      $verb{$aspect}{$mood}{'pastanterior'}  =
      $verb{$aspect}{$mood}{'past anterior'} = $verb{$aspect}{$mood}{izhcrifel};
      $verb{$aspect}{$mood}{'imperative'}    = $verb{$aspect}{$mood}{befel};
    }

    for $tense (qw(demeric scrifel izhcrifel
                   present past pastanterior), 'past anterior') {
      $verb{$aspect}{$tense} = $verb{$aspect}{definite}{$tense};
    }

    for $tense (qw(befel imperative)) {
      $verb{$aspect}{$tense} = $verb{$aspect}{remote}{$tense};
    }
  }

  for $mood (qw(prilise buprilise definite remote)) {
    $verb{$mood} = $verb{static}{$mood};
  }

  for $tense (qw(demeric scrifel izhcrifel
                 present past pastanterior), 'past anterior') {
    $verb{$tense} = $verb{static}{definite}{$tense};
  }

  for $tense (qw(befel imperative)) {
    $verb{$tense} = $verb{static}{remote}{$tense};
  }
}


# Verbs borrowed form other languages, and thus not subject to
# stem-changing rules
my %borrowed = (
  'DEBUTAN' => 1,   # Mark says these two don't change;
  'NACITAN' => 1,   # however, I don't know why not.
  'ONOTER'  => 'Cuêzi o:inote',
);

# Fricativised versions of consonants
my %fric = (
  'T' => 'TH',
  'D' => 'DH',
  'P' => 'F',
);

my $far = qr/^FAR$/;
my $kes = qr/^KES$/;
my $nen = qr/^NEN$/;

my @persons = qw(SEO LET TU   TAS MUKH CAI);

my @cases = qw(nom gen acc dat abl);

my @numbers = qw(sing pl);

my %present = (
  EC  => [ qw( AO EOS ES OM OUS ONT ) ],
  AN  => [ qw( AI EIS ET AM  US ONT ) ],
  EN  => [ qw( AI EIS ET EM  ES ENT ) ],
  ER  => [ qw( U  EUS ET UM  US UNT ) ],
  IR  => [ qw( U  EUS IT UM  US INT ) ],
  dyn => [ qw( UI UIS UT IM  IS INT ) ],
);

my %past = (
  EC  => [ qw( I  IUS U   UM  US IUNT ) ],
  AN  => [ qw( IO IOS AE UOM UOS IONT ) ],
  EN  => [ qw( IO IOS AE UOM UES IONT ) ],
  ER  => [ qw( IE IES E   EM  ES IENT ) ],
  IR  => [ qw( IE IES AE  EM  ES IENT ) ],
);


my %demeric = (
  ESAN    => [ qw( SAI     SEIS   ES     ESAM    ESOS     SONT     ) ],
  EPESAN  => [ qw( EUSAI   EUSEIS EPES   EPESAM  EPESOS   EUSONT   ) ],
  CTANEN  => [ qw( CTAI    CTES   CTET   CTANAM  CTANUS   CTANONT  ) ],
# FAR     => [ qw( FAEO    FAES   FAET   FASCOM  FASCOUS  FASCONT  ) ],
  FAR     => [ qw( FAEU    FAES   FAET   FASCOM  FASCOUS  FASCONT  ) ],
  IUSIR   => [ qw( IUSU    IUS    IUT    IUSUM   IUSUS    IUINT    ) ],
  LIUBEC  => [ qw( LIUO    LIUOS  LIUS   LIUBOM  LIUBOUS  LIUBONT  ) ],
  KETHEN  => [ qw( KETHUI  KETHUS KETHUT KETHEM  KETHES   KENT     ) ],
  CULLIR  => [ qw( CULLU   CULS   CULT   CULLUM  CULLUS   CULLINT  ) ],
  OHIR    => [ qw( OHU     UIS    UIT    OHUM    OHUS     OHINT    ) ],
  SCRIFEC => [ qw( SCRIFAO SCRIS  SCRIT  SCRIFOM SCRIFOUS SCRIFONT ) ],
  NEN     => [ qw( NEI     NIS    NIT    NESEM   NESES    NENT     ) ],
  KES     => [ qw( KEAI    KIES   KIET   KEHAM   KEHUS    KEHONT   ) ],
# VOLIR   => [ qw( VULU    VUIS   VUIT   VOLUM   VOLUS    VOLINT   ) ],
  VOLIR   => [ qw( VULU    VULS   VULT   VOLUM   VOLUS    VOLINT   ) ],
  FAUCIR  => [ qw( FAU     FEUS   FEUT   FAUCUM  FAUCUS   FAUCINT  ) ],
  FAILIR  => [ qw( FAILU   FELS   FELT   FAILUM  FAILUS   FAILINT  ) ],
);

sub demeric {
  my $verb = shift;
  my $stem = $verb;
  my $table;

  return $demeric{$verb} if exists $demeric{$verb};

ENDING:
  for my $ending ( keys %present ) {
    if(substr($stem, -2, 2) eq $ending) {
      substr($stem, -2, 2) = '';
      $table = [ map "$stem$_", @{$present{$ending}} ];
      last ENDING;
    }
  }

  # Stem change
  if($verb =~ /[AEIOU][TDP][IE]R$/ && !exists $borrowed{$verb} &&
     ($verb !~ /ATIR$/ || $verb eq 'CLATIR')) {
    for(@$table) {
      s/([TDP])(U(?:[MS]|NT)?)$/$fric{$1}$2/;
    }
  }

  return $table;
}

my %scrifel = (
  ESAN   => [ qw( FUIO       FUIOS   FUAE FUOM    FUOS    FUNT     ) ],
  EPESAN => [ qw( EUSIO      EUSIOS  EPAE EUSUOM  EUSUOS  EUSIONT  ) ],
# KETHEN => [ qw( KIO/KETHIO KETHIOS KIAE KETHUOM KETHUES KIONT    ) ],
  KETHEN => [ qw( KIO/KETHIO KETHIOS KIAE KETHUOM KETHUES KETHIONT ) ],
  NEN    => [ qw( NIO        NIOS    NAE  NESUOM  NESUES  NIONT    ) ],

  # semi-regular: FAR is like FASCEC, KES like KAIVAN
  FAR    => [ qw( FASCI  FASCIUS FASCU  FASCUM  FASCUS  FASCIUNT ) ],
  KES    => [ qw( KAIVIO KAIVIOS KAIVAE KAIVUOM KAIVUOS KAIVIONT ) ],
);

sub scrifel {
  my $verb = shift;
  my $stem = $verb;
  my $table;

  return $scrifel{$verb} if exists $scrifel{$verb};

ENDING:
  for my $ending ( keys %past ) {
    if(substr($stem, -2, 2) eq $ending) {
      substr($stem, -2, 2) = '';
      $table = [ map "$stem$_", @{$past{$ending}} ];
      last ENDING;
    }
  }

  # Stem change
  if($verb =~ /[AEIOU][TDP]EC$/ && !exists $borrowed{$verb}) {
    for(@$table) {
      s/([TDP])(U[MS]?)$/$fric{$1}$2/;
    }
  }

  return $table;
}

my %izhcrifel = (
  ESAN   => [ qw( FURIO   FURIOS   FURAE  FUROM   FUROS   FURIONT ) ],
  EPESAN => [ qw( EUSERIO EUSERIOS EPERAE EUSEROM EUSEROS EUSERIONT ) ],
);

sub izhcrifel {
  my $verb = shift;
  my $stem = $verb;
  my $table;

  return $izhcrifel{$verb} if exists $izhcrifel{$verb};

  if($stem =~ s/$far/FASCER/o ||
     $stem =~ s/([BPDTGKCFVRSZMNL]|[TDK]?H)REC$/$1$1ER/ ||
     $stem =~ s/EC$/ER/) {
    $table = [ map "$stem$_", @{$past{EC}} ];
  } elsif($stem =~ s/$kes/KAIVER/o ||
          $stem =~ s/([BPDTGKCFVRSZMNL]|[TDK]?H)RAN$/$1$1ER/ ||
          $stem =~ s/AN$/ER/) {
    $table = [ map "$stem$_", @{$past{AN}} ];
    for(@$table) {
      s/UOM$/OM/;
      s/UOS$/OS/;
    }
  } elsif($stem =~ s/$nen/NESER/o ||
          $stem =~ s/([BPDTGKCFVRSZMNL]|[TDK]?H)REN$/$1$1ER/ ||
          $stem =~ s/EN$/ER/) {
    $table = [ map "$stem$_", @{$past{EN}} ];
    for(@$table) {
      s/UOM$/OM/;
      s/UES$/ES/;
    }
  } elsif($stem =~ s/([BPDTGKCFVRSZMNL]|[TDK]?H)RER$/$1$1IR/ ||
          $stem =~ s/ER$/IR/) {
    $table = [ map "$stem$_", @{$past{ER}} ];
    s/U(O[SM])$/$1/ for @$table;
  } elsif($stem =~ s/([BPDTGKCFVRSZMNL]|[TDK]?H)RIR$/$1$1IR/ ||
          $stem =~ m/IR$/) {
    $table = [ map "$stem$_", @{$past{IR}} ];
    s/U(ES|OM)$/$1/ for @$table;
  } else {
    return;
  }

  return $table;
}

sub budemeric {
  my $verb = shift;
  my $stem = $verb;

  return [ map "EST$_", qw( AO EIS ES OM OS ONT ) ] if $verb eq 'ESAN';

  if($stem =~ s/$far/FASS/o ||
     $stem =~ s/^CURREC$/CORS/) {
    return [ map "$stem$_", @{$present{EC}} ];
  } elsif($stem =~ s/^METTAN$/MESS/ ||
          $stem =~ s/^DAN$/DON/ ||
          $stem =~ s/^PU([GH])AN$/PO$1/ ||
          $stem =~ s/^BRIGAN$/BROG/ ||
          $stem =~ s/^SUBRAN$/SOBR/ ||
          $stem =~ s/^LEGAN$/LOG/ ||
          $stem =~ s/^LAUDAN$/LOD/ ||
          $stem =~ s/^KUSAN$/KOSS/) {
    return [ map "$stem$_", @{$present{AN}} ];
  } elsif($stem =~ s/^([DKL]E|TO)SCEN$/$1SS/ ||
          $stem =~ s/^(DES|FER)IEN$/$1S/ ||
          $stem =~ s/^LEILEN$/LELS/ ||
          $stem =~ s/^KETHEN$/KOTH/) {
    return [ map "$stem$_", @{$present{EN}} ];
  } elsif($stem =~ s/^([SV])ALTER$/$1ELS/ ||
          $stem =~ s/^STERER$/STERS/ ||
          $stem =~ s/^NOER$/NOS/) {
    return [ map "$stem$_", @{$present{ER}} ];
  } elsif($stem =~ s/^MERIR$/MERS/ ||
          $stem =~ s/^NURIR$/NORS/ ||
          $stem =~ s/^AMARIR$/AMERS/ ||
          $stem =~ s/^DUCIR$/DOC/ ||
          $stem =~ s/^IUSIR$/IOSS/) {
    return [ map "$stem$_", @{$present{IR}} ];
  } elsif($stem =~ s/EC$/ET/) {
    return [ map "$stem$_", qw( AO EIS ES OM OS ONT ) ];
  } elsif($stem =~ s/$kes/KAIVEM/o ||
          $stem =~ s/AN$/EM/) {
    return [ map "$stem$_", qw( AI ES  ET AM US ONT ) ];
  } elsif($stem =~ s/$nen/NESEM/o ||
          $stem =~ s/EN$/EM/) {
    return [ map "$stem$_", qw( AI ES  ET EM ES ENT ) ];
  } elsif($stem =~ s/ER$/ET/) {
    return [ map "$stem$_", qw( U  OS  IS UM US UNT ) ];
  } elsif($stem =~ s/IR$/ET/) {
    return [ map "$stem$_", qw( U  OS  IS UM US INT ) ];
  } else {
    return;
  }
}

sub buscrifel {
  my $verb = shift;
  my $stem = $verb;

  return [ map "ESC$_", qw( AO EIS ES OM OS ONT ) ] if $verb eq 'ESAN';

  if($stem =~ s/$far/FASS/o ||
     $stem =~ s/^CURREC$/CORS/) {
    return [ map "$stem$_", @{$past{EC}} ];
  } elsif($stem =~ s/^METTAN$/MESS/ ||
          $stem =~ s/^DAN$/DON/ ||
          $stem =~ s/^PU([GH])AN$/PO$1/ ||
          $stem =~ s/^BRIGAN$/BROG/ ||
          $stem =~ s/^SUBRAN$/SOBR/ ||
          $stem =~ s/^LEGAN$/LOG/ ||
          $stem =~ s/^LAUDAN$/LOD/ ||
          $stem =~ s/^KUSAN$/KOSS/) {
    return [ map "$stem$_", @{$past{AN}} ];
  } elsif($stem =~ s/^([DKL]E|TO)SCEN$/$1SS/ ||
          $stem =~ s/^(DES|FER)IEN$/$1S/ ||
          $stem =~ s/^LEILEN$/LELS/ ||
          $stem =~ s/^KETHEN$/KOTH/) {
    return [ map "$stem$_", @{$past{EN}} ];
  } elsif($stem =~ s/^([SV])ALTER$/$1ELS/ ||
          $stem =~ s/^STERER$/STERS/ ||
          $stem =~ s/^NOER$/NOS/) {
    return [ map "$stem$_", @{$past{ER}} ];
  } elsif($stem =~ s/^MERIR$/MERS/ ||
          $stem =~ s/^NURIR$/NORS/ ||
          $stem =~ s/^AMARIR$/AMERS/ ||
          $stem =~ s/^DUCIR$/DOC/ ||
          $stem =~ s/^IUSIR$/IOSS/) {
    return [ map "$stem$_", @{$past{IR}} ];
  } elsif($stem =~ m/EC$/) {
    return [ map "$stem$_", qw( AO EIS ES OM OS ONT ) ];
  } elsif($stem =~ s/$kes/KAIVIN/o ||
          $stem =~ s/AN$/IN/) {
    return [ map "$stem$_", qw( AI ES  ET AM US ONT ) ];
  } elsif($stem =~ s/$nen/NESIN/o ||
          $stem =~ s/EN$/IN/) {
    return [ map "$stem$_", qw( AI ES  ET EM ES ENT ) ];
  } elsif($stem =~ s/([BPDTGKCFVRSZMNL]|[TDK]?H)RER$/$1$1IR/ ||
          $stem =~ s/ER$/IR/) {
    return [ map "$stem$_", qw( U  OS  IS UM US UNT ) ];
  } elsif($stem =~ s/([BPDTGKCFVRSZMNL]|[TDK]?H)RIR$/$1$1IR/ ||
          $stem =~ m/IR$/) {
    return [ map "$stem$_", qw( U  OS  IS UM US INT ) ];
  } else {
    return;
  }
}

sub bubefel {
  my $verb = shift;
  my $stem = $verb;

  if($stem =~ s/$far/FASS/o ||
     $stem =~ s/^CURREC$/CORS/ ||
     $stem =~ s/EC$//) {
    return [ undef, map ( "$stem$_", qw( E UAS  ) ),
             undef, map ( "$stem$_", qw( EL UANT ) ) ];
  } elsif($stem =~ s/$kes/KAIV/o ||
          $stem =~ s/^METTAN$/MESS/ ||
          $stem =~ s/^DAN$/DON/ ||
          $stem =~ s/^PU([GH])AN$/PO$1/ ||
          $stem =~ s/^BRIGAN$/BROG/ ||
          $stem =~ s/^SUBRAN$/SOBR/ ||
          $stem =~ s/^LEGAN$/LOG/ ||
          $stem =~ s/^LAUDAN$/LOD/ ||
          $stem =~ s/^KUSAN$/KOSS/ ||
          $stem =~ s/AN$//) {
    return [ undef, map ( "$stem$_", qw( I UAT ) ),
             undef, map ( "$stem$_", qw( IL UANT ) ) ];
  } elsif($stem =~ s/$nen/NES/o ||
          $stem =~ s/^([DKL]E|TO)SCEN$/$1SS/ ||
          $stem =~ s/^(DES|FER)IEN$/$1S/ ||
          $stem =~ s/^LEILEN$/LELS/ ||
          $stem =~ s/^KETHEN$/KOTH/ ||
          $stem =~ s/EN$//) {
    return [ undef, map ( "$stem$_", qw( I UAT ) ),
             undef, map ( "$stem$_", qw( IL UANT ) ) ];
  } elsif($stem =~ s/^([SV])ALTER$/$1ELS/ ||
          $stem =~ s/^STERER$/STERS/ ||
          $stem =~ s/^NOER$/NOS/ ||
          $stem =~ s/ER$//) {
    return [ undef, map ( "$stem$_", qw( U AS ) ),
             undef, map ( "$stem$_", qw( UL ANT ) ) ];
  } elsif($stem =~ s/^MERIR$/MERS/ ||
          $stem =~ s/^NURIR$/NORS/ ||
          $stem =~ s/^AMARIR$/AMERS/ ||
          $stem =~ s/^DUCIR$/DOC/ ||
          $stem =~ s/^IUSIR$/IOSS/ ||
          $stem =~ s/IR$//) {
    return [ undef, map ( "$stem$_", qw( U UAT ) ),
             undef, map ( "$stem$_", qw( UL UANT ) ) ];
  } else {
    return;
  }
}


my %dyntense = (
  demeric => 'demeric',
  present => 'demeric',

  scrifel => 'scrifel',
  past    => 'scrifel',

  izhcrifel       => 'izhcrifel',
  pastanterior    => 'izhcrifel',
  'past anterior' => 'izhcrifel',

  befel      => 'befel',
  imperative => 'befel',
);

my %dynmood = (
  prilise  => 'prilise',
  definite => 'prilise',

  buprilise => 'buprilise',
  remote    => 'buprilise',
);

sub dynamic {
  my($verb, $mood, $tense) = @_;
  my $stem = $verb;
  my $table;

  if($stem =~ s/$far/FASC/o ||
     $stem =~ s/$nen/NES/o  ||
     $stem =~ s/$kes/KAIV/o ||
     $stem =~ s/(?:EC|[AE]N|[EI]R)$//) {
    if($dynmood{$mood} eq 'prilise') {
      return unless $dyntense{$tense} eq 'demeric' ||
                    $dyntense{$tense} eq 'scrifel' ||
                    $dyntense{$tense} eq 'izhcrifel';
      $stem .= 'EV' if $dyntense{$tense} eq 'scrifel';
      $stem .= 'ER' if $dyntense{$tense} eq 'izhcrifel';
      $table = [ map "$stem$_", @{$present{dyn}} ];
    } elsif($dynmood{$mood} eq 'buprilise') {
      return unless $dyntense{$tense} eq 'demeric' ||
                    $dyntense{$tense} eq 'scrifel' ||
                    $dyntense{$tense} eq 'befel';
      if($dyntense{$tense} eq 'demeric') {
        $table = [ map "$stem$_", qw( I IS UAT UAM UAS UANT ) ];
      } elsif($dyntense{$tense} eq 'scrifel') {
        $stem .= 'IS';
        $table = [ map "$stem$_", qw( I US AT AM AS ANT ) ];
      } elsif($dyntense{$tense} eq 'befel') {
        # imperative is the same for static and dynamic forms
        $table = bubefel($verb);
      } else {
        return;
      }
    } else {
      return;
    }
  } else {
    return;
  }

  # Stem change
  if($dyntense{$tense} ne 'befel' && # imperative endings don't trigger
                                     # sound changes
     $verb =~ /[AEIOU][TDP](?:[IE]R|[AE]N|EC)$/ && !exists $borrowed{$verb} &&
     ($verb !~ /ATIR$/ || $verb eq 'CLATIR')) {
    for(@$table) {
      # UI UIS UT UAT UAM UAS UANT
      s/([TDP])(U(?:IS?|T|A(?:[SMT]|NT)))$/$fric{$1}$2/;
    }
  }

  return $table;
}

sub part {
  my $verb = shift;
  for($verb) {
    s/$far/FASCEC/o;
    s/$nen/NESEN/o;
    s/$kes/KAIVAN/o;
  }

  my($present, $past, $gerund) = ($verb) x 3;

  return unless $verb =~ /(?:EC|[AE]N|[EI]R)$/;

  for($present) {
    s/EC$/ILES/ || s/IR$/IC/ || s/(?:ER|[AE]N)$/EC/;
  }

  for($past) {
    s/E[CR]$/EL/ || s/(?:[AE]N|IR)$/UL/;
  }

  for($gerund) {
    s/E[CR]$/IM/ || s/(?:[AE]N|IR)$/AUM/;
  }

  return wantarray ? ($present, $past, $gerund) : [ $present, $past, $gerund ];
}



my %masc = (
);

my %neut = (
  ATITRIS     => 'atüchy',
  CRENIS      => 'iscreniy',
  DACTIS      => 'dazhy',
  DROGIS      => 'drozhy',
  FILIS       => 'fiy',
  FUELIS      => 'föy',
  ISCRENILIS  => 'iscreniy',
  IULIS       => 'zhuy',
  KATTIS      => 'katy',
  KILIS       => 'ciy',
  KRAIS       => 'rhay',
  LENTILIS    => 'lëtiy',
  LITIS       => 'lichy',
  LOIS        => 'loy',
  MEIS        => 'mey',
  MIHIS       => 'miy',
  MILGIS      => 'mily',
  MITIS       => 'michy',
  NACUIS      => 'nacuy',
  NMURTHANIS  => 'múrtany',
  NOTHONIS    => 'nodhony',
  OBELIS      => 'obly',
  ORAIS       => 'oray',
  PENGIS      => 'peny',
  PLASIS      => 'plasy',
  RAIS        => 'ray',
  SABLIS      => 'sably',
  SCRAIS      => 'shray',
  SEGLIS      => 'segly',
  SPAIS       => 'sfay',
  SUIS        => 'suy',
  VELAIS      => 'vlay',
  ZURRIS      => 'zury',
);

my %noun = (
  # personal pronouns
  SEO  => [ qw( SEO EAE  ETH SEON ED     TAS  TAIE TAIM TAUN TAD   ) ],
  LET  => [ qw( LET LEAE EK  LUN  LETH   MUKH MUIE MUIM MUIN MUOTH ) ],
  TU   => [ qw( TU  TUAE TUA TUN  TOTH   CAI  CAIE CAIM CAIN CAITH ) ],
  ZE   => [ undef, qw( ZEHIE ZETH  ZEHUN ZEHOTH ),
            undef, qw( ZAHIE ZAHAM ZAHAN ZAHATH ) ],
  TAS  => [ qw( TAS  TAIE TAIM TAUN TAD   ), (undef) x 5 ],
  MUKH => [ qw( MUKH MUIE MUIM MUIN MUOTH ), (undef) x 5 ],
  CAI  => [ qw( CAI  CAIE CAIM CAIN CAITH ), (undef) x 5 ],
  ZA   => [ undef, qw( ZAHIE ZAHAM ZAHAN ZAHATH ), (undef) x 5 ],

  # possessive adjectives:
  # SEO  -> ERIS
  # LET  -> LERIS
  # TU   -> TURIS
  # TAS  -> TANDES
  # MUKH -> MUNDES
  # CAI  -> CAIRIS

  # pointers
  AELU => [ qw( AELU AELUI AELETH AELUN AELOTH ), (undef) x 5 ],
  AELO => [ qw( AELO AELOI AELOR  AELON AELOTH ), (undef) x 5 ],
  AELA => [ qw( AELA AELAE AELEA  AELAN AELAD  ), (undef) x 5 ],

  ILLU => [ qw( ILLU ILLUI ILLETH ILLUN ILLOTH ), (undef) x 5 ],
  ILLO => [ qw( ILLO ILLOI ILLO   ILLON ILLOTH ), (undef) x 5 ],
  ILLA => [ qw( ILLA ILLAE ILLEA  ILLAN ILLAD  ), (undef) x 5 ],

  AETTOS => [ qw( AETTOS AETTEI AETTOT AETTAN AETTOTH ), (undef) x 5 ],
  # TOTOS actually conjugates like a regular masculine noun, but I'm keeping
  # it here with its relatives
  TOTOS  => [ qw( TOTOS  TOTEI  TOT    TOTAN  TOTOTH  ), (undef) x 5 ],

  # AECTA and CESTA are like feminine nouns

  # question words
  KAE => [ qw( KAE KAIE KAETH KAEN KAETH   KAHE KAHIE KAHAM KAHAN KAHATH ) ],
  KETTOS => [ qw( KETTOS KETTEI KETTOT KETTAN KETTOTH ), (undef) x 5 ],
  # older forms:
  # KESTU => [ qw( KESTU KEISE KEISAM KEISAN KEISE ), (undef) x 5 ],
  KEDIE => [ qw( KEDIE KEDIEI KEDIA KEDIEN KEDID ), (undef) x 5 ],

  # quantity words
  NIKTOS => [ qw( NIKTOS NIKTEI NIKTOT NIKTAN NIKTOTH ), (undef) x 5 ],
  NISIOS => [ qw( NISIOS NISIEI NISIOT NISIAN NISIOTH ), (undef) x 5 ],
  THISIOS => [ qw( THISIOS THISIEI THISIOT THISIAN THISIOTH ), (undef) x 5 ],

  PSIAT => [ qw( PSIAT PSIE PSIAT PSIAN PSIAD ), (undef) x 5 ],

  NIES  => [ qw( NIES  NIEI  NIET  NIEN  NIETH  ), (undef) x 5 ],
  PSIES => [ qw( PSIES PSIEI PSIET PSIEN PSIETH ), (undef) x 5 ],

  THIKEDIE => [ qw( THIKEDIE THIKEDIEI THIKEDIA THIKEDIEN THIKEDID ), (undef) x 5 ],

  # NIKUDA and PSUDA are like feminine nouns
);

sub noun {
  my $noun = shift;
  my $stem = $noun;
  my $type = 'fem';
  my $table;

  $type = 'masc' if exists $masc{$noun};
  $type = 'neut' if exists $neut{$noun};

  return $noun{$noun} if exists $noun{$noun};

  if($stem =~ s/OS$//) {
    $table = [ map "$stem$_", 'OS', 'EI', '', qw( AN OTH   IT IE I IN ITH ) ];
  } elsif($stem =~ s/AS$//) {
    $table = [ map "$stem$_", qw( AS AI A  AN ATH   AIT AIE AI  AIN AITH ) ];
  } elsif($stem =~ s/O$//) {
    $table = [ map "$stem$_", qw( O  OI OM ON OTH   OI  OIE OIM OIN OITH ) ];
  } elsif($stem =~ s/U$//) {
    $table = [ map "$stem$_", qw( U  UI UM UN UTH   UI  UIE UIM UIN UITH ) ];
  } elsif($type eq 'neut' && $stem =~ s/IS$//) {
    $table = [ map "$stem$_", qw( IS II IM IN ITH   UI  UIE UIM UIN UITH ) ];
  } elsif($stem =~ s/US$//) {
    $table = [ map "$stem$_", qw( US OI O  UN UTH   UIT UIE UI  UIN UITH ) ];
  } elsif($stem =~ s/A$//) {
    $table = [ map "$stem$_", qw( A  AE AA AN AD    ET  EIE EIM EIN EID  ) ];
  } elsif($stem =~ s/E$//) {
    $table = [ map "$stem$_", qw( E  EI EA EN ED    ET  EIE EIM EIN EID  ) ];
  } elsif($type eq 'fem' && $stem =~ s/IS$//) {
    $table = [ map "$stem$_", qw( IS IE IA IN ID    IAT IAE IAM IAN IAD  ) ];
  } elsif($stem =~ m/[PBTDHCGKFVSZMNLR]$/) {
    $table = [ map "$stem$_", '', 'EI', '', qw( AN OTH   IT IE I IN ITH ) ];
  } else {
    return;
  }

  return $table;
}

my %adj = (
  AELU => [ [ qw( AELU AELUI AELETH AELUN AELOTH ), (undef) x 5 ],
            [ qw( AELO AELOI AELOR  AELON AELOTH ), (undef) x 5 ],
            [ qw( AELA AELAE AELEA  AELAN AELAD  ), (undef) x 5 ], ],

  ILLU => [ [ qw( ILLU ILLUI ILLETH ILLUN ILLOTH ), (undef) x 5 ],
            [ qw( ILLO ILLOI ILLO   ILLON ILLOTH ), (undef) x 5 ],
            [ qw( ILLA ILLAE ILLEA  ILLAN ILLAD  ), (undef) x 5 ], ],
);

sub adj {
  my $adj = shift;
  my $stem = $adj;
  my $table;

  return $adj{$adj} if exists $adj{$adj};

  if($stem =~ s/ES$//) {
    $table = [ [ map "$stem$_", qw( ES  EI  E  EN ETH   EIT EIE EI  EIN EITH ) ],
               [ map "$stem$_", qw( E   EI  EM EN ETH   EI  EIE EIM EIN EITH ) ],
               [ map "$stem$_", qw( IES IAE EA EN ED    ET  EIE EIM EIN EID  ) ] ];
  } elsif($stem =~ s/IS$//) {
    $table = [ [ map "$stem$_", qw( IS II I  IN ITH   UIT UIE UI  UIN UITH ) ],
               [ map "$stem$_", qw( IS II IM IN ITH   UI  UIE UIM UIN UITH ) ],
               [ map "$stem$_", qw( IS IE IA IN ID    IAT IAE IAM IAN IAD  ) ] ];
  } elsif($stem =~ m/[PBTDHCGKFVSZMNLR]$/) {
    $table = [ [ map "$stem$_", '', 'EI', '', qw( AN OTH   IT IE I IN ITH ) ],
               [ map "$stem$_", qw( O OI OM ON OTH   OI OIE OIM OIN OITH ) ],
               [ map "$stem$_", qw( A AE AA AN AD    ET EIE EIM EIN EID  ) ] ];
  } else {
    return;
  }

  return $table;
}


my %comp = (
  MELIS => 'MELIOR',
  DURENGES => 'AVECOR',
);

sub comp {
  my $adj = shift;
  my $stem = $adj;

  return $comp{$adj} if exists $comp{$adj};

  if($stem =~ s/ES$//) {
    return $stem . 'EDHES';
  } elsif($stem =~ s/IS$//) {
    return $stem . 'IOR';
  } elsif($stem =~ m/[PBTDHCGKFVSZMNLR]$/) {
    return $stem . 'OR';
  } else {
    return;
  }
}


my %super = (
  MELIS => 'MELASTES',
  DURENGES => 'AVESTES',
);

sub super {
  my $adj = shift;
  my $stem = $adj;

  return $super{$adj} if exists $super{$adj};

  if($stem =~ s/ES$//) {
    return $stem . 'ASCES';
  } elsif($stem =~ s/IS$//) {
    return $stem . 'ISCES';
  } elsif($stem =~ m/[PBTDHCGKFVSZMNLR]$/) {
    return $stem . 'ASTES';
  } else {
    return;
  }
}


my %adv = (
  MELIS => 'MELIO',
  DURENGES => 'AVECUE',
);

sub adv {
  my $adj = shift;
  my $stem = $adj;

  return $adv{$adj} if exists $adv{$adj};

  if($stem =~ s/ES$//) {
    return $stem . 'ECUE';
  } elsif($stem =~ s/IS$//) {
    return $stem . 'ICUE';
  } elsif($stem =~ m/[PBTDHCGKFVSZMNLR]$/) {
    return $stem . 'A';
  } else {
    return;
  }
}


1;
__END__

=head1 NAME

Lingua::Zompist::Cadhinor - Inflect Cadhinor nouns, verbs, and adjectives

=head1 VERSION

This document refers to version 0.92 of Lingua::Zompist::Cadhinor,
released on 2002-05-20.

=head1 SYNOPSIS

  # no imports; using fully qualified function names
  use Lingua::Zompist::Cadhinor;
  $i_am = Lingua::Zompist::Cadhinor::demeric('ESAN')->[0];

  # import specific functions into the current namespace
  use Lingua::Zompist::Cadhinor qw( demeric crifel );
  $you_know = demeric('SCRIFEC')->[1];
  $they_had = crifel('TENEC')->[5];

  # import all functions into the current namespace
  use Lingua::Zompist::Cadhinor ':all';
  $i_am = demeric('ESAN')->[0];

  $table = noun('CUONOS');  # nouns
  $table = noun('SEO');     # pronouns
  $table = noun('KETTOS');  # pronouns
  $table = adj('KHALTES');  # adjectives

  # verbs -- separate functions
  $table = demeric('SCRIFEC');     # (static definite) present
  $table = scrifel('SCRIFEC');     # (static definite) past
  $table = izhcrifel('SCRIFEC');   # (static definite) past anterior
  $table = budemeric('SCRIFEC');   # (static) remote present
  $table = buscrifel('SCRIFEC');   # (static) remote past
  $table = bubefel('SCRIFEC');     # (static remote) imperative

  # dynamic definite present
  $table = dynamic('SCRIFEC', 'prilise', 'demeric');
  $table = dynamic('SCRIFEC', 'definite', 'present');
  # dynamic remote past
  $table = dynamic('SCRIFEC', 'buprilise', 'scrifel');
  $table = dynamic('SCRIFEC', 'remote', 'past');

  ($present, $past, $gerund) = part('SCRIFEC'); # participles

  # verbs -- via the %verb hash -- in English
  $table = $verb{static}{definite}{present}->('SCRIFEC');
  $table = $verb{dynamic}{remote}{past}->('SCRIFEC');

  # verbs -- via the %verb hash -- in Verdurian/Cadhinor
  $table = $verb{nuncre}{prilise}{demeric}->('SCRIFEC');
  $table = $verb{olocec}{buprilise}{scrifel}->('SCRIFEC');

=head1 DESCRIPTION

=head2 Overview

Lingua::Zompist::Cadhinor is a module which allows you to inflect Cadhinor
words. You can conjugate verbs and decline nouns, pronouns, adjectives, and the
definite article.

There is one function to inflect nouns and pronouns. There are also functions
for inflect adjectives and to form comparative and superlative forms as well as
adverbs from them. Finally, there are several functions to inflect verbs,
depending on the aspect, mood, and tense, and a function to form the
participles of a verb.

There is also a hash which you can ask to import which may make the maze of
verb-inflecting functions a little easier to use.

=head2 Exports

Lingua::Zompist::Cadhinor exports no functions by default, in order to avoid
namespace pollution. This enables, for example, Lingua::Zompist::Cadhinor and
Lingua::Zompist::Verdurian to be used in the same program, since otherwise some
of the function names would clash. However, all functions listed here can be
imported explicitly by naming them, or they can be imported all together by
using the tag ':all'.

You can also ask to import the hash C<%verb>. This hash is not imported by
default, even if you ask for ':all'; you have to ask for it by name. For
example:

  use Lingua::Zompist::Cadhinor qw(:all %verb);
  # or
  use Lingua::Zompist::Cadhinor '%verb';

=head2 Capitalisation and character set

This module expects all input to be in upper case and will return all output
in upper case. You should use the standard Latin transcription method for
Cadhinor (with "TH" for I<ten>, "DH" for I<edh>, and "KH" for I<kodh>).

In the future, this module may expect and produce the charset used by the
F<Maraille> font. At that point, the module Lingua::Zompist::Convert is
expected to be available, which should be able to convert between that charset
and standard charsets such as iso-8859-1 and utf-8.

=head2 noun

This function allows you to inflect nouns and pronouns (including personal
pronouns such as I<SEO> and I<LET> and relative and interrogative pronouns
such as I<KEDIE>, I<PSIAT>, and I<KETTOS>).

It takes one argument, the noun or pronoun to inflect, and returns an arrayref
on success, or C<undef> or the empty list on failure (for example, because it
could not determine which conjugation a noun belonged to).

In general, the arrayref will have ten elements, in the following order:
nominative singular, genitive singular, accusative singular, dative singular,
ablative singular, nominative plural, genitive plural, accusative plural,
dative plural, ablative plural. In some cases, some of those elements may be
C<undef> (especially in the plural of non-personal pronouns such as I<KETTOS>
or I<THIKEDIE> -- but not I<KAE>).

The function should determine the gender and declension of the noun or pronoun
automatically. Nouns ending in I<-IS> are taken to be feminine unless they are
on an internal list of neuter nouns in I<-IS>. If you find a neuter noun
in I<-IS> which is not recognised correctly, please send me email.

=over 4

=item *

If you use the singular of a personal pronoun (I<SEO>, I<LET>, I<TU>, or
the pseudo-nominative I<ZE>), then you will get both the singular and
the plural forms of that pronoun as the ten elements of the resulting
arrayref.

=item *

If you use the plural of a personal pronoun (I<TAS>, I<MUKH>, I<CAI>, or
the pseudo-nominative I<ZA>), then you will get the plural forms as the
first five elements of the arrayref. The last five elements will be
C<undef>.

=item *

The pseudo-nominative corresponding to the accusative I<ZETH> is
I<ZE>; that corresponding to its plural forms is I<ZA> (borrowed
from Verdurian).

=back

=head2 adj

This function inflects adjectives (including I<AELU> and I<ILLU>).  It expects
one argument (the adjective to decline) and returns an arrayref on success, or
C<undef> or the empty list on failure.

The arrayref will itself contain three arrayrefs, each with ten elements. The
first arrayref will contain the masculine forms, the second arrayref will
contain the neuter forms, and the third arrayref will contain the feminine
forms. The forms are in the same order as in the arrayref returned by the
L<noun|/"noun"> function. Briefly, this order is nominative - genitive -
accusative - dative - ablative in singular and plural.

This function should determine the declension of an adjective automatically.

There is currently no function which returns the declension of an adjective
(partly because the matter is so simple -- first declension adjectives end in
-<cons>/-O/-A, second declension in -ES/-E/-IES, and third declension in
-IS/-IS/-IS); however, if there is popular demand for such a function it could
be quickly added.

=head2 comp

This function returns the comparative form of an adjective (as, "higher" from
"high"). It takes one argument (the adjective to inflect) and returns the
comparative form, or C<undef> on failure.

=head2 super

This function returns the superlative form of an adjective (as, "highest" from
"high"). It takes one argument (the adjective to inflect) and returns the
superlative form, or C<undef> on failure.

=head2 adv

This function returns the adverb corresponding to an adjective (as, "highly"
from "high"). It takes one argument (the adjective) and returns the
corresponding adverb, or C<undef> on failure.

=head2 demeric

This function declines a verb in the (static definite) present tense. It takes
the verb to inflect as its argument and returns an arrayref on success, or
C<undef> or the empty list on failure.

The arrayref will contain six elements, in the following order: first person
singular ("I"), second person singular ("thou"), third person singular
("he/she/it"), first person plural ("we"), second person plural ("[all of]
you"), third person plural ("they").

=head2 scrifel

This function declines a verb in the (static definite) past tense. It is
otherwise similar to the function L<demeric|/"demeric">.

=head2 izhcrifel

This function declines a verb in the (static definite) past anterior tense. It
is otherwise similar to the function L<demeric|/"demeric">.

=head2 budemeric

This function declines a verb in the (static) remote present tense. It is
otherwise similar to the function L<demeric|/"demeric">.

The name is derived from I<buprilise> "remote" and I<demeric> "present".

=head2 buscrifel

This function declines a verb in the (static) remote past tense. It is
otherwise similar to the function L<demeric|/"demeric">.

The name is derived from I<buprilise> "remote" and I<scrifel> "past".

=head2 bubefel

This function declines a verb in the (static remote) imperative. It is
otherwise similar to the function L<demeric|/"demeric">.

=over 4

=item *

Note that there is no C<befel> function, since the imperative exists only
in the remote mood in Cadhinor.

=item *

Note also that the first and fourth elements of the returned arrayref
will be C<undef>, since the Cadhinor imperative only has forms for second
and third persons in singular and plural.

=back

The name is derived from I<buprilise> "remote" and I<befel> "imperative".

=head2 dynamic

This function declines a verb in the dynamic aspect. It takes three
arguments: first, the verb to decline; second, the mood (one of "prilise" or
"buprilise", or the English versions "definite" and "remote"); and third,
the tense (one of "demeric", "scrifel", "izhcrifel", or "befel", or the
English versions "present", "past", "pastanterior" (or "past anterior"), and
"imperative").

The return values are similar to those of the other verbal functions.

=head2 part

This function returns the three participles of a verb. It takes the verb as an
argument and returns an arrayref (in scalar context) or a list (in list
context) of three elements: the present (nominative) participle, the past
(accusative) participle, and the gerund (participle of need; "to be
E<lt>verbE<gt>ed"). On failure, it returns C<undef> or the empty list.

Specifically, the form returned for each participle is the masculine nominative
singular form of the participle (which can be considered the citation form).
Since participles decline like regular adjectives, the other forms of the
participles may be obtained by calling the L<adj|/"adj"> function, if desired.

=head2 %verb

To ease the confusion caused by the different verbal functions (remembering
to use a 'bu-' function for the remote tense, or the different interface
in the dynamic aspect), it is also possible to inflect verbs by importing the
hash C<%verb> into the current namespace.

This hash contains references to subroutines which only need to be passed
the name of the verb to be inflected.

To fully qualify a tense, use the aspect, mood, and tense in that order, for
example:

  $table = $verb{static}{remote}{present}->('SCRIFEC');

This will place an arrayref with the forms of the static remote present of
the verb "SCRIFEC" in C<$table>. It is also possible to use the
Verdurian/Cadhinor names of the moods and tenses:

  $table = $verb{nuncre}{buprilise}{demeric}->('SCRIFEC');

The Verdurian/Cadhinor names for I<static> and I<dynamic> are I<nuncre>
and I<olocec>, respectively.

For convenience, it is also possible to use an abbreviated notation. Since
I suppose that the most common aspect is the static aspect, and the most
common mood the definite mood, you can leave off those aspects and moods
if you wish. So the following should all yield the same result:

  $table = $verb{static}{definite}{past}->('SCRIFEC');
  $table = $verb{definite}{past}->('SCRIFEC');
  $table = $verb{static}{past}->('SCRIFEC');
  $table = $verb{past}->('SCRIFEC');
  $table = $verb{nuncre}{prilise}{scrifel}->('SCRIFEC');
  $table = $verb{prilise}{scrifel}->('SCRIFEC');
  $table = $verb{nuncre}{scrifel}->('SCRIFEC');
  $table = $verb{scrifel}->('SCRIFEC');

As a special nod to laziness, if you use C<{imperative}> or C<{befel}> without
specifying a mood, remote rather than the definite mood is chosen, since there
is no definite imperative in Cadhinor. So C<< $verb{befel}->('CREGEN')->[1] >>
and C<< $verb{static}{imperative}->('CREGEN')->[1] >> give you the equivalent
of C<< $verb{static}{remote}{imperative}->('CREGEN')->[1] >> rather than the
equivalent of C<< $verb{static}{definite}{imperative}->('CREGEN')->[1] >>.

On the other hand, you may find this interface to be more confusing than
calling the different functions directly. Take your pick and use whichever
you prefer :-).

=head1 BUGS

This module should handle irregular words correctly. However, if there is a
word that is inflected incorrectly, please send me email and notify me.

However, please make sure that you have checked against a current version of
http://www.zompist.com/native.htm or F<PreCadh.doc>, or that you asked Mark
Rosenfelder himself; the grammar occasionally changes as small errors are found
or words change.

=head1 FEEDBACK

If you use this module, then I'd appreciate hearing about it, just so I
have an idea of how many people use it. Drop me a line at the address
listed in L</AUTHOR>.

=head1 SEE ALSO

L<Lingua::Zompist::Kebreni>, L<Lingua::Zompist::Verdurian>,
http://www.zompist.com/native.htm, F<PreCadh.doc> (available from
http://www.zompist.com/embassy.htm#learning )

=head1 AUTHOR

Philip Newton, E<lt>pne@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

[This is basically the BSD licence.]

Copyright (C) 2001, 2002 by Philip Newton.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item *

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer. 

=item *

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution. 

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
