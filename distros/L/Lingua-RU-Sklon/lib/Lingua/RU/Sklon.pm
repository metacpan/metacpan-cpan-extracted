#!/usr/bin/perl -w
use strict;
use warnings;
use POSIX qw(locale_h);
use locale;
setlocale(LC_CTYPE, "ru_RU.cp1251"); 

package Lingua::RU::Sklon; 




BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 0.01;
    
    @ISA         = qw(Exporter);
    @EXPORT      = qw(&parse_n &parse_lastname &convert &initcap &sklon);
    %EXPORT_TAGS = ( );

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw(%pads);


}
use Carp;

our @EXPORT_OK;

our %pads;

# non-exported package globals go here
our $dos;
our $iso;
our $koi;
our $win;

# initialize package globals, first exported ones

%pads=(
  I=>1, IMEN=>1, 1=>1, #это жена
  R=>2, ROD=>2,  2=>2, #отстался без жены
  D=>3, DAT=>3,  3=>3, #студенту жене
  V=>4, VIN=>4,  4=>4, #порвал жену
  T=>5, TVOR=>5, 5=>5, #назвался женой
  P=>6, PRED=>6, 6=>6  #пишу о жене
  );


 $dos={'а'=>160,'б'=>161,'в'=>162,'г'=>163,'д'=>164,'е'=>165,'ё'=>241,'ж'=>166,'з'=>167,'и'=>168,'й'=>169,'к'=>170,'л'=>171,'м'=>172,'н'=>173,'о'=>174,'п'=>175,'р'=>224,'с'=>225,'т'=>226,'у'=>227,'ф'=>228,'х'=>229,'ц'=>230,'ч'=>231,'ш'=>232,'щ'=>233,'ь'=>236,'ы'=>235,'ъ'=>234,'э'=>237,'ю'=>238,'я'=>239,'А'=>128,'Б'=>129,'В'=>130,'Г'=>131,'Д'=>132,'Е'=>133,'Ё'=>240,'Ж'=>134,'З'=>135,'И'=>136,'Й'=>137,'К'=>138,'Л'=>139,'М'=>140,'Н'=>141,'О'=>142,'П'=>143,'Р'=>144,'С'=>145,'Т'=>146,'У'=>147,'Ф'=>148,'Х'=>149,'Ц'=>150,'Ч'=>151,'Ш'=>152,'Щ'=>153,'Ь'=>156,'Ы'=>155,'Ъ'=>154,'Э'=>157,'Ю'=>158,'Я'=>159};
 $iso={'а'=>208,'б'=>209,'в'=>210,'г'=>211,'д'=>212,'е'=>213,'ё'=>241,'ж'=>214,'з'=>215,'и'=>216,'й'=>217,'к'=>218,'л'=>219,'м'=>220,'н'=>221,'о'=>222,'п'=>223,'р'=>224,'с'=>225,'т'=>226,'у'=>227,'ф'=>228,'х'=>229,'ц'=>230,'ч'=>231,'ш'=>232,'щ'=>233,'ь'=>236,'ы'=>235,'ъ'=>234,'э'=>237,'ю'=>238,'я'=>239,'А'=>176,'Б'=>177,'В'=>178,'Г'=>179,'Д'=>180,'Е'=>181,'Ё'=>161,'Ж'=>182,'З'=>183,'И'=>184,'Й'=>185,'К'=>186,'Л'=>187,'М'=>188,'Н'=>189,'О'=>190,'П'=>191,'Р'=>192,'С'=>193,'Т'=>194,'У'=>195,'Ф'=>196,'Х'=>197,'Ц'=>198,'Ч'=>199,'Ш'=>200,'Щ'=>201,'Ь'=>204,'Ы'=>203,'Ъ'=>202,'Э'=>205,'Ю'=>206,'Я'=>207};
 $koi={'а'=>193,'б'=>194,'в'=>215,'г'=>199,'д'=>196,'е'=>197,'ё'=>163,'ж'=>214,'з'=>218,'и'=>201,'й'=>202,'к'=>203,'л'=>204,'м'=>205,'н'=>206,'о'=>207,'п'=>208,'р'=>210,'с'=>211,'т'=>212,'у'=>213,'ф'=>198,'х'=>200,'ц'=>195,'ч'=>222,'ш'=>219,'щ'=>221,'ь'=>216,'ы'=>217,'ъ'=>223,'э'=>220,'ю'=>192,'я'=>209,'А'=>225,'Б'=>226,'В'=>247,'Г'=>231,'Д'=>228,'Е'=>229,'Ё'=>179,'Ж'=>246,'З'=>250,'И'=>233,'Й'=>234,'К'=>235,'Л'=>236,'М'=>237,'Н'=>238,'О'=>239,'П'=>240,'Р'=>242,'С'=>243,'Т'=>244,'У'=>245,'Ф'=>230,'Х'=>232,'Ц'=>227,'Ч'=>254,'Ш'=>251,'Щ'=>253,'Ь'=>248,'Ы'=>249,'Ъ'=>255,'Э'=>252,'Ю'=>224,'Я'=>241};
 $win={'а'=>224,'б'=>225,'в'=>226,'г'=>227,'д'=>228,'е'=>229,'ё'=>184,'ж'=>230,'з'=>231,'и'=>232,'й'=>233,'к'=>234,'л'=>235,'м'=>236,'н'=>237,'о'=>238,'п'=>239,'р'=>240,'с'=>241,'т'=>242,'у'=>243,'ф'=>244,'х'=>245,'ц'=>246,'ч'=>247,'ш'=>248,'щ'=>249,'ь'=>252,'ы'=>251,'ъ'=>250,'э'=>253,'ю'=>254,'я'=>255,'А'=>192,'Б'=>193,'В'=>194,'Г'=>195,'Д'=>196,'Е'=>197,'Ё'=>168,'Ж'=>198,'З'=>199,'И'=>200,'Й'=>201,'К'=>202,'Л'=>203,'М'=>204,'Н'=>205,'О'=>206,'П'=>207,'Р'=>208,'С'=>209,'Т'=>210,'У'=>211,'Ф'=>212,'Х'=>213,'Ц'=>214,'Ч'=>215,'Ш'=>216,'Щ'=>217,'Ь'=>220,'Ы'=>219,'Ъ'=>218,'Э'=>221,'Ю'=>222,'Я'=>223}; 

END { }       # module clean-up code here (global destructor)




sub convert {
  my $src=lc shift;
  my $tgt=lc shift;
  my ($src_cp, $tgt_cp);
  if      ($src eq 'dos') {  $src_cp=$dos;
  } elsif ($src eq 'win') {  $src_cp=$win;
  } elsif ($src eq 'iso') {  $src_cp=$iso;
  } elsif ($src eq 'koi') {  $src_cp=$koi;
  } else {
    croak "Wrong Source encoding: $src"; 
    return "! Wrong Source encoding: $src"; 
  }
  
  if      ($tgt eq 'dos') {  $tgt_cp=$dos;
  } elsif ($tgt eq 'win') {  $tgt_cp=$win;
  } elsif ($tgt eq 'iso') {  $tgt_cp=$iso;
  } elsif ($tgt eq 'koi') {  $tgt_cp=$koi; 
  } else {
    croak "Wrong tgt encoding: $tgt"; 
    return "! Wrong tgt encoding: $tgt";
  }
  
  my %src_cp = reverse %{$src_cp};
  my $out;
  my @out;
  foreach (@_) {
    my @a=split //;
    $out='';
    foreach (@a) {
      my $r=chr($tgt_cp->{$src_cp{ord($_)}});
      $out.= $r?$r:$_;
    }
    push @out,$out;
  }
  if (wantarray) {
    return @out;
  } else {
    return join ('',@out);
  }
}


sub parse_lastname {
  my $txt=lc shift;
  my $wrap=shift;
  my $last_letter=substr($txt,-2);
  
  #print $last_letter;
  if ($last_letter eq 'ий') {
    my $h={1=>'ий',
           2=>'ого',
           3=>'ому',
           4=>'ого',
           5=>'им',
           6=>'ом'
           };
    return substr($txt,0,-2).($h->{$wrap}||return "!$txt");
  } elsif ($last_letter eq 'ый') {
    my $h={1=>'ый',
           2=>'ого',
           3=>'ому',
           4=>'ого',
           5=>'ым',
           6=>'ом'
           };
    return substr($txt,0,-2).($h->{$wrap}||return "!$txt");
  } elsif ($last_letter eq 'ой') {
    return $txt;
  } elsif ($last_letter eq 'ая') {
    my $h={1=>'ая',
           2=>'ую',
           3=>'ой',
           4=>'ую',
           5=>'ой',
           6=>'ой'
           };
    return substr($txt,0,-2).($h->{$wrap}||return "!$txt");
  } elsif ($last_letter eq 'яя') {
    my $h={1=>'яя',
           2=>'юю',
           3=>'ей',
           4=>'юю',
           5=>'ей',
           6=>'ей'
           };
    return substr($txt,0,-2).($h->{$wrap}||return "!$txt");
  } elsif ($last_letter eq 'ок') {
  
    my $h={1=>'ок',  #это жена
           2=>'ка',  #отстался без жены
           3=>'ке',  #студенту жене
           4=>'ку',  #порвал жену
           5=>'ком', #назвался женой
           6=>'ке'   #пишу о жене
           };
    return substr($txt,0,-2).$h->{$wrap};
  }
  
  $_=substr($txt,-1);
  
  if ($_ eq 'й') {
  
  my $h={1=>'й',
           2=>'я',
           3=>'я',
           4=>'ю',
           5=>'ем',
           6=>'и'
           };
    return substr($txt,0,-1).($h->{$wrap}||return "!$txt");
  }
  if ($_ eq 'а') {
    my $h={1=>'а',  #это жена
           2=>'ой',  #отстался без жены
           3=>'у',  #порвал жену
           4=>'ой',  #студенту жене
           5=>'ой', #назвался женой
           6=>'ой'   #пишу о жене
           };
    return substr($txt,0,-1).($h->{$wrap}||return "!$txt");
  }
  if ($_ eq 'я') {
    my $h={1=>'я',  #это жена
           2=>'и',  #отстался без жены
           3=>'ю',  #порвал жену
           4=>'е',  #студенту жене
           5=>'ей', #назвался женой
           6=>'е'   #пишу о жене
           };
    return substr($txt,0,-1).($h->{$wrap}||return "!$txt");
  }
  if ($_ eq 'ь') {
    my $h={1=>'ь',  #это жена
           2=>'я',  #отстался без жены
           3=>'я',  #порвал жену
           4=>'ю',  #студенту жене
           5=>'ем', #назвался женой
           6=>'е'   #пишу о жене
           };
    return substr($txt,0,-1).($h->{$wrap}||return "!$txt");
  }
  if (/[уехъфыпролджэячсмитьбю]/) {
    return $txt;
  }
  if (/в/) {
    my $h={1=>'',  #это жена
           2=>'а',  #отстался без жены
           3=>'e',  #студенту жене
           4=>'у',  #порвал жену
           5=>'ым', #назвался женой
           6=>'е'   #пишу о жене
           };
    return $txt.$h->{$wrap};
  }
  
  if (/[цукенгшщзхъфывапролджэячсмитьбю]/) {
    my $h={1=>'',  #это жена
           2=>'а',  #отстался без жены
           3=>'у',  #порвал жену
           4=>'e',  #студенту жене
           5=>'ом', #назвался женой
           6=>'ой'   #пишу о жене
           };
    return $txt.$h->{$wrap};
  }
  carp ("Unalbe to sklon: $txt");
  return "$txt";
  
}

sub parse_n {
  my $txt=lc shift;
  my $wrap=shift;
  my $last_letter=substr($txt,-2);
  
  #print $last_letter;
  if ($last_letter eq 'ок') {
    my $h={1=>'ок',  #это жена
           2=>'ка',  #отстался без жены
           3=>'ку',  #порвал жену
           4=>'ке',  #студенту жене
           5=>'ком', #назвался женой
           6=>'ке'   #пишу о жене
           };
    return substr($txt,0,-2).$h->{$wrap};
  } elsif ($last_letter eq 'ел') {
    my $h={1=>'ел',  #это жена
           2=>'ла',  #отстался без жены
           3=>'лу',  #порвал жену
           4=>'лу',  #студенту жене
           5=>'лом', #назвался женой
           6=>'ле'   #пишу о жене
           };
    return substr($txt,0,-2).$h->{$wrap};
  } elsif ($last_letter eq 'ев') {
    my $h={1=>'ев',  #это жена
           2=>'ьва',  #отстался без жены
           3=>'ьва',  #порвал жену
           4=>'ьву',  #студенту жене
           5=>'ьвом', #назвался женой
           6=>'ьве'   #пишу о жене
           };
    return substr($txt,0,-2).$h->{$wrap};
  }
  
  $_=substr($txt,-1);
  
  if ($_ eq 'й') {
    my $h={1=>'й',
           2=>'я',
           3=>'ю',
           4=>'ю',
           5=>'ем',
           6=>'е'
           };
    return substr($txt,0,-1).($h->{$wrap}||return "!$txt");
  }
  if ($_ eq 'а') {
    my $h={1=>'а',  #это жена
           2=>'ы',  #отстался без жены
           3=>'е',  #студенту жене
           4=>'у',  #порвал жену
           5=>'ой', #назвался женой
           6=>'е'   #пишу о жене
           };
    return substr($txt,0,-1).($h->{$wrap}||return "!$txt");
  }
  if ($_ eq 'я') {
    my $h={1=>'я',  #это жена
           2=>'и',  #отстался без жены
           3=>'е',  #студенту жене
           4=>'ю',  #порвал жену
           5=>'ей', #назвался женой
           6=>'е'   #пишу о жене
           };
    return substr($txt,0,-1).($h->{$wrap}||return "!$txt");
  }
  if ($_ eq 'ь') {
    my $h={1=>'ь',  #это жена
           2=>'я',  #отстался без жены
           3=>'ю',  #студенту жене
           4=>'я',  #порвал жену
           5=>'ем', #назвался женой
           6=>'е'   #пишу о жене
           };
    return substr($txt,0,-1).($h->{$wrap}||return "!$txt");
  }
  if (/[уеъыэю]/) {
    return $txt;
  }
  if (/[вткнгзхфвпрлдмтб]/) {
    my $h={1=>'',  #это жена
           2=>'а',  #отстался без жены
           3=>'е',  #студенту жене
           4=>'у',  #порвал жену
           5=>'ом', #назвался женой
           6=>'е'   #пишу о жене
           };
    return $txt.$h->{$wrap};
  }
  
  if (/[шщхжч]/) {
    my $h={1=>'',  #это жена
           2=>'а',  #отстался без жены
           3=>'У',  #студенту жене
           4=>'у',  #порвал жену
           5=>'ем', #назвался женой
           6=>'е'   #пишу о жене
           };
    return $txt.$h->{$wrap};
  }
  carp ("Unalbe to sklon: $txt");
  return "$txt";
  
}

sub sklon {
  $_=shift;
  print "$_\n";
  /(\w+)\s(\w+)\s(.+)/;
  my $pad=shift;
  my $decl=$pads{$pad};

  croak "Unknown pad attempting to be set : $pad" unless $decl;
  return initcap(parse_lastname($1,$decl)." ".parse_n($2,$decl)." ".parse_n($3,$decl));
  
}
sub initcap {
  $_=shift;
  my $out;
  while (/(\w)(\w*)(\W*)/g) {
    $out.=uc ($1).$2.$3;
  }
  return $out;
}

1;

__END__

=head1 NAME

Lingua::RU::Sklon - helps declensing russian word

=head1 SYNOPSIS

  use Lingua::RU::Sklon;
  
  print sklon("Алексеев Алексей Алексеевич"=>'VIN');
  print sklon(convert('koi'=>'win', 'юКЕЙЯЕЕБ юКЕЙЯЕИ юКЕЙЯЕЕБХВ' )=>'VIN');
  # gives Алексеева Алексея Алексеевича
  
=head1 DESCRIPTION

  Lingua::RU::Sklon - specially made to helps declense russian names in any acts
  or docs you've come through. This, sadly, doesn't help yet at some more
  complex names such as Московская-Муштак Виктория-Степанида Джульраби оглы.
  But, in 99.9% cases this module fits.
  
  default encoding for this module is win-1251. be sure you install this locale.
  If not, then please send all names initcapped, this should do the trick either.

=over 4

=item convert (FROM=>TO, WHAT)

usage
my $win_text=convert ('koi'=>'win', $koi_text);
This lil' helper converts russian text from/to different encodings.
available charsets koi, win, iso, dos
see L<Lingua::RU::Charset> for more flexible version.

=item sklon (WHAT=>PAD)
 
 This function gets full name of client, and transforms it into desired
 declense. Available list of declesnes is:
 
 C<
  I=>1, IMEN=>1, 1=>1, #Именительный
  R=>2, ROD=>2,  2=>2, #Родительного
  D=>3, DAT=>3,  3=>3, #Дательным
  V=>4, VIN=>4,  4=>4, #Винительный
  T=>5, TVOR=>5, 5=>5, #Творительным
  P=>6, PRED=>6, 6=>6  #о Предложном
 >
 
=item %pads

 Yes, it's the hash from above.

=item initcap (NAME)

Make First Letters of the Every Word Capital.

=item parse_n

parses noun (name or second name) of client.

=item parse_lastname

parses last name of client.
  
  
=back

=head1 AUTHOR

Alexey Usanov <alexey_usa@mail.ru>

=head1 SEE ALSO

L<Lingua::RU::Charset>, L<perllocale>

=head1 COPYRIGHT

Copyright (c) 2007, Alexey Usanov. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
