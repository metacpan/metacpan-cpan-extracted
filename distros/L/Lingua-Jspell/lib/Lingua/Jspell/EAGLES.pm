package Lingua::Jspell::EAGLES;

# Mais uma vez, isto tudo é específico do português.
# algum código devia passar a ser baseado num YAML qualquer
# que defina a estrutura certa. 
#
# para já, não abrir demasiadas frentes.

use warnings;
use strict;

our $VERSION = '1.95';

# modo: {I}ndicativo, {S}ubjuntivo, i{M}perativo, 
#       i{N}finitivo, {G}erundio, {P}articipio
# tempo: {P}resente, {I}mperfeito, {F}uturo,
#        pas{S}ado, {C}ondicional
my %temposverbais = (
     ip     => "NE", # infinitivo pessoal           ???FIXME(tempo E = pEssoal)
     inf    => "N0", # infinitivo
     pp     => "IS", # pretérito perfeito (simples)
     ppa    => "P0", # particípio passado
     pc     => "SP", # presente do conjuntivo
     pic    => "SI", # pretérito imperfeito do conjuntivo
     c      => "IC", # condicional
     p      => "IP", # presente
     fc     => "SF", # futuro do conjuntivo
     g      => "G0", # gerúndio
     pmp    => "IM", # pretérito mais que perfeito  ???FIXME (tempo M = mais que perf.)
     pi     => "II", # pretérito Imperfeito
     f      => "IF", # Futuro
     i      => "M0", # iMperativo
);

# NUNCA NA VIDA JUNTAR ESTAS DUAS LINHAS
# NUMA ÚNICA OU A REGRA DO a_nc DEIXA DE
# FUNCIONAR.

my %rules;
%rules = (
	## --[ Pronomes - Artigos ]--						
	art  => sub { my %fea = @_;
	  return "D"
           . (exists($fea{CLA}) && $fea{CLA} eq "indef" ? "I":"A")
           . "0"
           . uc($fea{G})
           . uc($fea{N})
           . "0";
    },
	## --[ Números Cardinais ]--					
	card => sub {
		my %fea = @_;
		return "Z0" . uc($fea{G} || "0") . uc($fea{N} || "0")
	},
	## --[ Números Ordinais ]--				
	nord => sub {
		my %fea = @_;
		return "AO0" . uc($fea{G} || "0") . uc($fea{N} || "0") . "0"
	},
	## --[ Pronomes Pessoais ]--				
	ppes => sub {
		my %fea = @_;
		my $tag = "PP";
		
		# pessoa (1,2,3)
		$tag .= uc($fea{P} || 0);

		# género (M,F,Comum,Neutro)
		my $G = exists $fea{G} ? uc $fea{G} : "0";
		$G = "C" if $G eq "2";
		$G = "0" if $G eq "_"; # XXX ????????
		$tag .= $G;

		# Numero (S, P, N --impessoal/invariavel)
		$tag .= exists $fea{P}
		         ? ($fea{P} =~ /[SP]/i ? uc($fea{P}) : "N")
		         : "0";
		# Caso (nominativo, acusativo, dativo, obliquo)
		$tag .= exists $fea{C} ? uc($fea{C}) : "0";

		# possuidor (Singluar, Plural)
		# XXX --- temos disto? Não --> so nos ppos
		$tag .= "0"
		
	},
	## --[ Pronomes Possessivos ]--			
	ppos => sub {
		my %fea = @_;
	    return "PX"
           . uc($fea{P} || "0")
           . uc($fea{G} || "0")
           . uc($fea{N} || "0")
           . "0"
           . uc($fea{NP} || "0")
           ;
		
		# pessoa (1,2,3)
		# género (M,F,Comum,Neutro)
		# Numero (S, P, N --impessoal/invariavel)
		# Caso (nominativo, acusativo, dativo, obliquo)
		# possuidor (Singluar, Plural)
	},
	## --[ Pronomes Indefinido ]--		
	pind => sub {
		my %fea = @_;
		my $tag = "PI"
                . "0"
                . uc($fea{G} || "0")
                . uc($fea{N} || "0")
                . "0"
                . "0"
                ;
        $tag =~ s/_/0/g;
        $tag;
		
		# pessoa (1,2,3)
		# género (M,F,Comum,Neutro)
		# Numero (S, P, N --impessoal/invariavel)
		# Caso (nominativo, acusativo, dativo, obliquo)
		# possuidor (Singluar, Plural)
	},
	## --[ Pronomes Relativos ]--	
	prel => sub {
		my %fea = @_;
		my $tag = "PR"
                . "0"
                . uc($fea{G} || "0")
                . uc($fea{N} || "0")
                . uc($fea{C} || "0")
                . "0"
                ;
        $tag =~ s/_/0/g;
        $tag;		
		# pessoa (1,2,3)
		# género (M,F,Comum,Neutro)
		# Numero (S, P, N --impessoal/invariavel)
		# Caso (nominativo, acusativo, dativo, obliquo)
		# possuidor (Singluar, Plural)
	},
	## --[ Pronomes Demonstrativos ]--
	pdem => sub {
		my %fea = @_;
	    return "PD"
             . "0"
             . uc($fea{G} || "0")
             . uc($fea{N} || "0")
             . "00";
		
		# pessoa (1,2,3)
		# género (M,F,Comum,Neutro)
		# Numero (S, P, N --impessoal/invariavel)
		# Caso (nominativo, acusativo, dativo, obliquo)
		# possuidor (Singluar, Plural)
	},
	## --[ Pronomes interrogativos ]--		
	pint => sub {
		my %fea = @_;
		my $tag = "PT";
		
		# pessoa (1,2,3)
		# género (M,F,Comum,Neutro)
		# Numero (S, P, N --impessoal/invariavel)
		# Caso (nominativo, acusativo, dativo, obliquo)
		# possuidor (Singluar, Plural)
	},
	## --[ Verbos ]--	
	v    => sub {
		my %fea = @_;
		my $tag = "V";

		# (XXX) tipo (principal, auxiliar, semiauxiliar...)
		$tag .= "0";
		$tag .= ( $fea{rad} eq "ter" ? "A" 
                : $fea{rad} eq "ser" ? "S"
                :                      "M"
                );

        
        $tag .=  $temposverbais{$fea{T}} || "00";

		# pessoa (1,2,3) -- 1_3 é desdobrado abaixo
		$tag .= exists($fea{P}) ? $fea{P} : "0";

		# numero (S, P)
		$tag .= exists($fea{N}) ? uc($fea{N}) : "0";

		# genero (M,F)
		$tag .= exists($fea{G}) ? uc($fea{G}) : "0";

		# Desdobrar pessoa.
		if ($tag =~ /1_3/) {
			my ($one, $three) = ($tag) x 2;
			$one   =~ s/1_3/1/;
			$three =~ s/1_3/3/;
			return ($one, $three)
		} else {
			return $tag;
		}
	},
	## --[ Preposições ]--	
	prep => sub { "SPS00" },
	## --[ Advérbios ]--	
	adv  => sub {
		my %fea = @_;
		my $tag = "R";
		$tag .= exists($fea{SUBCAT}) && $fea{SUBCAT} eq "neg" ? "N" : "G";
		return $tag;
	},	
	## --[ Interjeições ]--	
	in    => sub { return "I" },	
	## --[ Conjunções ]--	
	con   => sub { return "C0" },	
	## --[ Contrações ]--
	punct => sub { return "F" },
	## --[ Contrações ]--
	cp    => sub {
		my %fea = @_;
		return "SPC" . uc($fea{G} || "0") . uc($fea{N} || "0")
	},
	## --[ Nomes Comuns ]--
	nc   => sub {
		my %fea = @_;
		my $tag = "NC";

		my $gen = uc($fea{G} || '0');
		$gen =~ s/[^MF0]/C/i;
		$tag .= $gen;

		my $num = uc($fea{N} || '0');
		$num =~ s/[^SP0]/N/;
		$tag .= $num;

		# tipo de nome
		$tag .= "00";

		my $grad = $fea{GR} || "";
		$grad =~ s/dim/D/i;
		$grad =~ s/aum/A/i;
		$grad = "0" unless $grad =~ /^[DA]$/;

		$tag .= $grad;

		return $tag;
	},
	## --[ Nomes Próprios ]--
	np   => sub {
		my %fea = @_;
		my $tag = "NP";

		my $gen = uc($fea{G} || '0');
		$gen =~ s/[^MF0]/C/;
		$tag .= $gen;

		my $num = uc($fea{N} || '0');
		$num =~ s/[^SP0]/N/;
		$tag .= $num;

		$tag .= ($fea{SEM} || "") =~ /^p/i ? "SP" : "V0";
	
		my $grad = $fea{GR} || "";
		$grad =~ s/dim/D/i;
		$grad =~ s/aum/A/i;
		$grad = "0" unless $grad =~ /^[DA]$/;
		$tag .= $grad;

		return $tag;
	},
	## --[ Adjetivos ]--
	adj  => sub {
		my %fea = @_;
		my $tag = "A0";

		my $grad = $fea{GR} || "";
		$grad =~ s/dim/D/i;
		$grad =~ s/aum/A/i;
		$grad =~ s/sup/S/i;
		$grad = "0" unless $grad =~ /^[DSA]$/;
		$tag .= $grad;

		my $gen = uc($fea{G} || '0');
		$gen =~ s/[^MF0]/C/;
		$tag .= $gen;

		my $num = uc($fea{N} || '0');
		$num =~ s/[^SP0]/N/;
		$tag .= $num;

		return $tag . "0";
	},
	## --[ Nomes e Adjetivos ]--
	a_nc => sub {
		return ( $rules{nc}->(@_) , $rules{adj}->(@_) );
	},
);

sub _cat2eagles {
	my %fea = @_;

	if (exists($rules{$fea{CAT}})) {
		return $rules{$fea{CAT}}->(%fea);
	} else {
		return "_UNK"
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Lingua::Jpell::EAGLES - Perl extension for building tags in EAGLES format

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 EXPORT

=head1 AUTHOR

=head1 SEE ALSO

EAGLES -- http://www.ilc.cnr.it/EAGLES96/annotate/node1.html

EAGLES-ES -- http://nlp.lsi.upc.edu/freeling/doc/tagsets/tagset-es.html

perl(1).

=cut      
