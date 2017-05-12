#!/app/unido-i06/magic/perl
#                              -*- Mode: Perl -*- 
use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($^O eq 'VMS' or $^O eq 'os2');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -*- 
!GROK!THIS!
print OUT <<'!NO!SUBS!';
#                              -*- Mode: Perl -*- 
# try -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Dec  4 15:57:13 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Thu Jan 16 16:23:25 1997
# Last Modified On: Mon Jan 13 11:37:31 1997
# Language        : CPerl
# Update Count    : 30
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universit‰t Dortmund, all rights reserved.
# 
# $Locker: pfeifer $
# $Log: infobrief.PL,v $
# Revision 1.1  1996/12/12 12:07:15  pfeifer
# Initial revision
#
# 
!NO!SUBS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
eval 'exec perl -S $0 "$@"'
    if 0;

use InfoBrief;
use Getopt::Long;
use Pod::Usage;
use vars qw(%OPT);

my %CC = (
       'A'   => '÷sterreich',
       'CH'  => 'Schweiz',
       'F'   => 'Frankreich',
       'GB'  => 'Great Britain',
       'H'   => 'Ungarn',
       'IRL' => 'Irland',
       'J'   => 'Japan',
       'L'   => 'Luxemburg',
       'NL'  => 'Niederlande',
       'PL'  => 'Polen',
       'USA' => 'USA',
       'GR'  => 'Griechenland',
       'B'   => 'Belgien',
       'BG'  => 'Bulgarien',
       );

$OPT{packed} = 1;

GetOptions (\%OPT,
            'a4!',
            'b5!',
            'c6!',
            'stempel!',
            'foreign!',
            'help!',
            'man!',
            'packed!',
            'sender=s@',
            'infobrief!',
            'numbering!',
            'verbose:i',
           ) || pod2usage(2);
pod2usage(1)  if ($OPT{help});
pod2usage(VERBOSE => 2)  if ($opt{MAN});

unless (exists $OPT{stempel}) {
  $OPT{stempel} = ! $OPT{foreign};
}

my $x = new InfoBrief %OPT;


print $x->preamble;

if ($OPT{packed}) {
  $/="\r\n";
  chomp($_ = <>);
  @fld = split /;/, $_;
} else {
  $/="";
}

while (<>) {
  if ($OPT{packed}) {
    chomp;
    $_ =~ s/;;/; ;/g;
    @rec = split /;/, $_;
    my %rec;
    for (@fld) {
      $rec{$_} = shift @rec;
      $rec{$_} =~ s/^ $//;
      #print STDERR "$_\t$rec{$_}\n";
    }
    if ($rec{Land}) {
      next unless $OPT{foreign};
      $rec{S} = $rec{Land};
      $rec{Land} = $CC{$rec{S}};
      print STDERR "WOAH: $rec{S}: $rec{Land}\n" ;
      if ($rec{S} eq 'USA') {
        $rec{S}   = '';
        $rec{PLZ} = '';
      }
    } else {
      next if $OPT{foreign};
    }
    #$c_rec ++;
    #$row = int(($c_rec-1)/3)+1;
    #next if $row % 9;
    record(%rec);
    #last if ++$x > 10;
  } else {
    my @rec = split /\n/, $_;
    my $last = pop @rec;
    push @rec, '', $last;
    print $x->page(@rec);
  }
}

print $x->trailer;

sub record {
  my %rec = @_;

  delete $rec{S} if $rec{S} eq 'D';
  my @rec = 
    grep /./,                   # grep /./, ($rec{Anrede}, $rec{Titel})),
    (
     join(' ', grep /./, ($rec{Titel}, $rec{Name}, $rec{Vorname})),
     $rec{Firma},
     $rec{Abteilung},
     $rec{Strasse},
     'lf',
     join(' ', grep /./, ((($rec{S})?$rec{S}.'-':'').$rec{PLZ}, $rec{Ort})),
     $rec{Land},
    );
  map s/^lf//, @rec;
  print $x->page(@rec);
}

__END__

=head1 NAME

infobrief -- Erzeuge Poscript f¸r Infobrief Umschl‰ge

=head1 SYNOPSIS

B<try> B<[-a4]> B<[-foreign]>

=head1 DESCRIPTION

B<Try> liest von I<stdin> eine Datei mit Adressen, jede Adresse in
einer Zeile, Eintrage durch C<;> getrennt. Die erste Zeile enth‰lt die
namen der Felder. Hier ist ein Beispiel.

   S;PersNr;Titel;Anrede;Name;Vorname;Firma;Abteilung;Land;PLZ;Ort;Strasse
   D;29643;;Herr;M¸ller;Ottokar;TU Dresden, Fak.Inform.;IBDR-LS DB;;01062;Dresden;
   D;2881;Prof. Dr.;Herr;Selters;Eugen;TU Dresden;FakultÑt Informatik;;01062;Dresden;Institut BDR
   D;24939;;Herr;Gates;Bill;;;;01187;Dresden;WÅrzburger Str. 51

=head1 OPTIONS

=item B<-a4>

Ausgabe in DIN A4 anstelle von DIN A5.

=item B<-foreign>

Ausgabe der Umschl‰ge f¸r Auslandsadressen.

=item B<-help>

=item B<verbose> [I<number>]

=item B<-nopacked>

Use a the nonpacked input format: paragraphs separated by blank lines.

=item B<-sender> I<line>

Specify a sender line. May be given multiple times.

=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@ls6.informatik.uni-dortmund.de>E<gt>

=cut

!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
