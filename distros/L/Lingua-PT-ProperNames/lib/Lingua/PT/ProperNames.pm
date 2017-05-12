package Lingua::PT::ProperNames;

#require Exporter;
use locale;
use IO::String;
use warnings;
use strict;

=encoding ISO-8859-1

=head1 NAME

Lingua::PT::ProperNames - Simple module to extract proper names from Portuguese Text

=head1 Version

Version 0.10

=cut

our $VERSION = '0.10';
use base 'Exporter';
our @EXPORT = qw/getPN printPN printPNstring forPN forPNstring/;

our ($em, $np1, $np, $prof, $sep1, $sep2, %vazia, @stopw);

BEGIN {

  $np1 = qr{(?:(?: [A-ZÈÉÚÓÁÂ][.])+
               |   [sS]r[.]
               |   [dD]r[.]
               |   St[oa]?[.]
               |   [A-ZÈÉÚÓÁÂ]\w+(?:[\'\-]\w+)*
         )}x;

  #if ($e) {
  #$np= qr{$np1(?:\s+(?:d[eao]s?\s+|e\s+)?$np1)*};
  #} else {
  $np= qr{$np1
          (?: \s+ (?:d[eaou]s?\s+
                  |  d'
                  |  de \s+ l[ae]s? \s+
                  |  v[oa]n\s+
                  )?
              $np1)*
         }x;
  #}

  @stopw = qw{
              no com se em segundo a o os as na nos nas do das dos da tanto
              para de desde mas quando esta sem nem só apenas mesmo até uma uns um
              pela por pelo pelas pelos depois ao sobre como umas já enquanto aos
              também amanhã ontem embora essa nesse olhe hoje não eu ele eles
              primeiro simplesmente era foi é será são seja nosso nossa nossos nossas
              chama-se chamam-se subtitui resta diz salvo disse diz vamos entra entram
              aqui começou lá seu vinham passou quanto sou vi onde este então temos
              num aquele tivemos

              en la pour le
             };

  $prof = join("|", qw{
                       astrólogo astrónomo advogado actor
                       baterista
                       cantor compositor
                       dramaturgo
                       engenheiro escritor
                       filósofo flautista físico
                       investigador
                       jogador
                       matemático médico ministro músico
                       pianista poeta professor
                       químico
                       teólogo
                      });
  $sep1 = join("|", qw{chamado "conhecido como"});

  $sep2 = join("|", qw{brilhante conhecido reputado popular});
  @vazia{@stopw} = (@stopw); # para ser mais facil ver se uma pal é stopword
  $em = '\b(?:[Ee]m|[nN][oa]s?)';
}

=head1 Synopsis

This module contains simple Perl-based functions to detect and extract
proper names from Portuguese text.

  use Lingua::PT::ProperNames;


  printPN(@options);
  printPNstring({ %options... } ,$textstrint);
  printPNstring([ @options... ] ,$textstrint);

  forPN( sub{my ($pn, $contex)=@_;... } ) ;
  forPN( {t=>"double"},
         sub{my ($pn, $contex)=@_;... }, sub{...} ) ;
  $outstr = forPN($instr, sub{my ($pn, $contex)=@_;... }, ... ) ;

  forPNstring(sub{my ($pn, $contex)=@_;... },
         $textstring, regsep) ;


  my $pndict = Lingua::PT::ProperNames->new;

=head1 Functions related to ProperNames dictionary

=head2 new

Creates a new ProperNames dictionary

=cut

sub new {
  my $class = shift;
  # my $filename = shift;

  my $self = bless {}, $class;
  $self->_load_dictionary;
  return $self;
}

sub _load_dictionary {
  my $self = shift;
  my $file = shift || undef;

  if ($file) {
    open C, $file or die;
    while(<C>) {
      chomp;
      next if m!^\s*$!;
      $self->{cdic}{$_} = $_;
    }
    close C;
  } else {
    my $f = _find_file();
    open D, $f or die "Cannot open file $f: $!\n";
    while(<D>) {
      chomp;
      next if m!^\s*$!;
      my ($nome,$prob,$type) = split /\s+/;
      $self->{dic}{$nome} = {type=>$type,prob=>$prob};
    }
    close D;
  }
}

sub _exists {
  my $self = shift;
  my $word = shift;
  return exists($self->{dic}{$word}) or
    exists($self->{cdic}{$word}) or
      exists($self->{sdic}{$word})
}

=head2 is_name

This method checks if a name exists in the Names dictionary as a Given Name.

=cut

sub is_name {
  return _exists(@_)
}

=head2 is_surname

Thie method checks if a name exists in the Names dictionary as a
Surname.

=cut

sub is_surname {
  return _exists(@_) && _type(@_) eq "apelido";
}

sub _type {
  my $self = shift;
  my $word = shift;
  if (exists($self->{dic}{$word})) {
    return $self->{dic}{$word}{type}
  } elsif (exists($self->{cdic}{$word})) {
    return $self->{cdic}{$word}{type}
  } elsif (exists($self->{sdic}{$word})) {
    return $self->{sdic}{$word}{type}
  } else {
    return undef;
  }
}


=head1 Detecting Proper Names

=head2 forPN

Substitutes all Proper Names found on STDIN by the result of calling a function C<<f>>
with arguments ($propername,$context). The result is sent to STDOUT.

Usage:

   forPN({options...}, sub{ propername processor...})

Optionally you can define input or output files:

   forPN({in=> "inputfile", out => "outputfile" }, sub{...})

Also, C<<{t => "double"}>> helps  to treat in a special way
names after punctuation (".", etc).
With this options you must provide 2 functions: one for standard Proper Names
and one for names after punctuation.

   forPN({t=>"double"}, sub{...}, sub{...})

You can also define record paragraph separator

   forPN({sep=>"\n", t=>"normal"}, sub{...}) ## each line is a par.
   forPN({sep=>""}, sub{...})                ## par. empty lines

=cut


sub forPN{
  ## opt:  in=> inputfile(sdtin), out => file(stdout)
  my %opt = (sep => "", t => "normal" );

  %opt = (%opt , %{shift(@_)}) if   ref($_[0]) eq "HASH";
  my $instring = "";
  $instring = shift(@_)        if ! ref($_[0]);

  my ($f,$f1) = @_;
  my $m="\x01";
  my $old;
  my ($F1, $F2) ;

  die "invalid parameter to 'forPN'" unless ref($f) eq "CODE";

  if ($opt{t} eq "double") {
    die "invalid parameter ". ref($f1) unless ref($f1) eq "CODE";
  }

  local $/ = $opt{sep};  # input record separator=one or more empty lines

  if (defined $opt{in}) {
    open $F1, "$opt{in}" or die "cant open $opt{in}\n";
  } elsif (defined $instring) {          ## input is a string (1st parameter)
    $F1 = IO::String->new($instring);
  } else {
    $F1=*STDIN;
  }

  if (defined $opt{out}) {
    open F, ">$opt{out}" or die "cant create $opt{out}\n";
    $old = select(F);
  } elsif (defined $instring) {          ## input is a string (1st parameter)
    $F2 = IO::String->new();
    $old = select($F2);
  }

  while (<$F1>) {
    my $ctx = $_;
    if ($opt{t} eq "double") {

      s{($np)}{$m($1$m)}g;
      s{(^\s* 
        | [-]\s+
        | [.!?]\s*
        )  $m\( ($np) $m\)
       }{
           my ($aux1,$aux2,$aux3)= ($1,$2, $f1->($2,$ctx));
	   if   (defined($aux3)){$aux1 . $aux3}
	   else                 {$aux1 . _tryright($aux2)} }xge;
      
      s{$m\(($np)$m\)}{  $f->($1,$ctx) }ge;

    } else {
      s{( \w+\s+
        | [\«\»,:()'`"]\s*
        )  ($np)
       }{$1 . $f->($2,$ctx) }xge;
    }
    print;
  }
  close $F1 if $opt{in};
  if (defined $opt{out}) {
    select $old;
    close F;
  } elsif (defined $instring) {          ## input is a string (1st parameter)
    return ${$F2->string_ref()};
  }
}

=head2 forPNstring

   forPNstring( $funref, "textstring" [, regSeparator] )>

Substitutes all C<propername> by C<funref(propername)> in the text string.

=cut

sub forPNstring {
  my $f = shift;
  die "invalid parameter to 'forPNstring': function expected" unless ref($f) eq "CODE";
  my $text = shift;
  my $sep = shift || "\n";
  my $r = '';
  for (split(/$sep/,$text)) {
    my $ctx = $_;
    s/(\w+\s+|[\«\»,()'`i"]\s*)($np)/$1 . $f->($2,$ctx)/ge       ;
    $r .= "$_$sep";
  }
  return $r;
}

=head2 printPNstring

   printPNstring("oco")

=cut

sub printPNstring{
  my $text = shift;
  my %opt = ();

  if   (ref($text) eq "HASH") { %opt = %$text        ; $text = shift; }
  elsif(ref($text) eq "ARRAY"){ @opt{@$text} = @$text; $text = shift; }

  my (%profissao, %names, %namesduv, %gnames);

  for ($text) {
    chop;
    s/\n/ /g;
    for (m/[.?!:;"]\s+($np1\s+$np)/gxs)  { $namesduv{$_}++ }
    for (m![)>(]\s*($np1\s+$np)!gxs)     { $namesduv{$_}++ }
    for (m/(?:[\w\«\»,]\s+)($np)/gxs)    { $names{$_}++ }
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++ }
    }
    if ($opt{prof}) {
      while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	{ $profissao{$2} = $1 }
      while(/(?:[\w\«\»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	{ $profissao{$1} = $2 }
    }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv) {
    if (/^(\w+)/ && $vazia{lc($1)}) { #exemplo "Como Jose Manuel"
      s/^\w+\s*//;                    # retira-se a 1.a palavra
      $names{$_}++
    } else { 
      $names{$_}++
    }
  }

  for (keys %names) {
    if (/^(\w+)/ && $vazia{lc($1)}) {  #exemplo "Como Jose Manuel"
      my $ant = $_;
      s/^\w+\s*//;                     # retira-se a 1.a palavra
      $names{$_} += $names{$ant};
      delete $names{$ant}
    }
  }

  if ($opt{oco}) {
    for (sort {$names{$b} <=> $names{$a}} keys %names ) {
      printf("%60s - %d\n", $_ ,$names{$_});
    }
  } else {
    if ($opt{comp}) {
      my @l = sort _compara keys %names;
      _compacta(\%names, @l)
    } else {
      for (sort _compara keys %names ) {
	printf("%60s - %d\n", $_ ,$names{$_});
      }
    }
    if ($opt{prof}) {
      print "\nProfissões\n";
      for (keys %profissao) {
	print "$_ -- $profissao{$_}"
      }
    }
    if ($opt{em}) {
      print "\nGeograficos\n";
      for (sort _compara keys %gnames ) {
	printf("%60s - %d\n", $_ ,$gnames{$_})
      }
    }
  }
}


=head2 getPN

=cut

sub getPN {
  local $/ = "";           # input record separator=1 or more empty lines

  my %opt;
  @opt{@_} = @_;
  my (%profissao, %names, %namesduv, %gnames);

  while (<>) {
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/g)     { $namesduv{$_}++;}
    for (/[)>(]\s*($np1\s+$np)/g)        { $namesduv{$_}++;}
    for (/(?:[\w\«\»,]\s+)($np)/g)       { $names{$_}++;}
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++;}}
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	 { $profissao{$2} = $1 }
       while(/(?:[\w\«\»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	 { $profissao{$1} = $2 }
     }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv) {
    if(/^(\w+)/ && $vazia{lc($1)}) {  # exemplo "Como Jose Manuel"
      s/^\w+\s*//;                    # retira-se a 1.a palavra
      $names{$_}++
    } else {
      $names{$_}++
    }
  }
  return (%names)
}


=head2 printPN

  printPN("oco")

  printPN  - extrai os nomes próprios dum texto.
   -comp    junta certos nomes: Fermat + Pierre de Fermat = (Pierre de) Fermat
   -prof
   -e       "Sebastiao e Silva" "e" como pertencente a PN
   -em      "em Famalicão" como pertencente a PN


=cut

sub printPN{
  local $/ = "";           # input record separator=1 or more empty lines

  my %opt;
  @opt{@_} = @_;
  my (%profissao, %names, %namesduv, %gnames);

  while (<>) {
    chop;
    s/\n/ /g;
    for (/[.?!:;"]\s+($np1\s+$np)/g)     { $namesduv{$_}++ }
    for (/[)>(]\s*($np1\s+$np)/g)        { $namesduv{$_}++ }
    for (/(?:[\w\«\»,]\s+)($np)/g)       { $names{$_}++ }
    if ($opt{em}) {
      for (/$em\s+($np)/g) { $gnames{$_}++ }
    }
    if ($opt{prof}) {
       while(/\b($prof)\s+(?:(?:$sep1)\s+)?($np)/g)
	 { $profissao{$2} = $1 }
       while(/(?:[\w\«\»,]\s+|[(])($np),\s*(?:(?:$sep2)\s+)?($prof)/g)
	 { $profissao{$1} = $2 }
     }
  }

  # tratamento dos nomes "duvidosos" = Nome prop no inicio duma frase
  #

  for (keys %namesduv){
    if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
      {s/^\w+\s*//;                  # retira-se a 1.a palavra
       $names{$_}++;}
    else
      { $names{$_}++;}
  }

  ##### Não sei bem se isto serve...

  for (keys %names){
    if(/^(\w+)/ && $vazia{lc($1)} )   #exemplo "Como Jose Manuel"
      { my $ant = $_;
        s/^\w+\s*//;                  # retira-se a 1.a palavra
        $names{$_}+=$names{$ant};
        delete $names{$ant};}
  }

  if($opt{oco}){
    for (sort {$names{$b} <=> $names{$a}} keys %names )
      {printf("%6d - %s\n",$names{$_}, $_ );}
  }
  else
    {
      if($opt{comp}){my @l = sort _compara keys %names;
		     _compacta(\%names, @l); }
      else{for (sort _compara keys %names )
	     {printf("%60s - %d\n", $_ ,$names{$_});} }

      if($opt{prof}){print "\nProfissões\n";
		     for (keys %profissao){print "$_ -- $profissao{$_}";} }

      if($opt{em}){print "\nGeograficos\n";
		   for (sort _compara keys %gnames )
		     {printf("%60s - %d\n", $_ ,$gnames{$_});} }
  }
}



##
# Auxiliary stuff

sub _tryright{
  my $a = shift;
  return $a unless $a =~ /(\w+)(.*)$/;
  my ($w,$r) = ($1,$2);
  my $m = "\x01";
  $r =~ s{($np)}{$m($1$m)}g;
  return "$w$r";
}


sub _compacta{
  my $s;
  my $names = shift;

  my $p = shift;
  my $r = $p;
  my $q = $names->{$p};
  while ($s = shift)
    { if ($s =~ (/^(.+) $p/)) { $r = "($1) $r" ;
				$q += $names->{$s};
			      }
      else {print "$r - $q"; $r=$s; $q = $names->{$s}; }
      $p=$s;
    }
  print "$r - $q";
}

sub _compara {
  # ordena pela lista de palavras invertida
  join(" ", reverse(split(" ",$a))) cmp join(" ", reverse(split(" ",$b)));
}

sub _find_file {
    my @files = grep { -e $_ } map { "$_/Lingua/PT/ProperNames/names.dat" } @INC;
    return $files[0];
}

=head1 Author

José João Almeida, C<< <jj@di.uminho.pt> >>

Alberto Simões, C<< <ambs@di.uminho.pt> >>

=head1 Bugs

Please report any bugs or feature requests to
C<bug-lingua-pt-propernames@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Projecto Natura, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Lingua::PT::ProperNames

