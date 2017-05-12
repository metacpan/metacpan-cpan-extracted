package Email::ECGListe;

use warnings;
use strict;
use Digest::SHA1 qw( sha1 );

our $VERSION = '0.07';

BEGIN {
	use Exporter;
	our @ISA         = qw( Exporter );
	our @EXPORT      = qw( );
	our %EXPORT_TAGS = ( );
	our @EXPORT_OK   = qw( &Abgleich );
} # BEGIN

sub Abgleich($$;$$$;$$$$;$$$$$) {

	my ($dateiEcgHash, $dateiEin, $gesOrFixOrDel, $feld, $trennZ) = (shift, shift, shift, shift, shift);

	die $! if not -e $dateiEcgHash;
	die $! if not -e $dateiEin;
	my $dateiAus = $dateiEin.".txt";

	if (not($gesOrFixOrDel)) {
		print "Bitte Dateiformat angeben (F/D/G): ";
		chomp($gesOrFixOrDel = uc(<STDIN>));
		die $! if $gesOrFixOrDel ne "F" and $gesOrFixOrDel ne "D" and $gesOrFixOrDel ne "G";
	} # if

	$gesOrFixOrDel = uc($gesOrFixOrDel);
	if (not($feld)) {
		if ($gesOrFixOrDel eq "F") {
			print "Bitte Stelle,Laenge eingeben: ";
			chomp($feld = <STDIN>);
			die $! if not $feld;
		} # if
		elsif ($gesOrFixOrDel eq "D") {
			print "Bitte Feldnummer eingeben: ";
			chomp($feld = <STDIN>);
			die $! if not $feld;
			print "Bitte Trennzeichen eingeben: ";
			chomp(my $trennZ = <STDIN>);
			die $! if not $trennZ;
		} # elsif
		elsif ($gesOrFixOrDel eq "G") {
			print "Ganze Zeile ist die Emailadresse.\n";
		} # elsif
		else {
			die $!;
		} # else
	} # if

	my %verboten;
	my ($bytes, $hashwert) = ("", "");

	open(my $fhHash, "<", $dateiEcgHash) or die $!;
	do {
		$bytes = read($fhHash, $hashwert, 20);
	   $verboten{$hashwert} = 1;
	} # do
	while ( $bytes == 20 );
	close($fhHash) or die $!;

	open(my $fhEin, "<", $dateiEin) or die $!;
	open(my $fhAus, ">", $dateiAus) or die $!;

	while (my $zeile = <$fhEin>) {
		chomp $zeile;
		my $email = "";
		if ($gesOrFixOrDel eq "F") {
			my @aiFeld = ();
			@aiFeld    = split(/,/, $feld);
			$email     = substr($zeile,$aiFeld[0],$aiFeld[1]);
		} # if
		elsif ($gesOrFixOrDel eq "D") {
			my @satz = ();
			@satz    = split(/$trennZ/, $zeile);
			$email   = $satz[$feld];
		} # elsif
		else {
			$email = $zeile;
		} # else
		my $domain = "";
		($domain = $email) =~ s%.*\@%%;
		if (not($verboten{sha1($email)}) and not($verboten{sha1("\@".$domain)})) {
			print $fhAus $zeile."\n";
		} # if
	} # while

	close($fhEin) or die $!;
	close($fhAus) or die $!;

} # Abgleich

1;
__END__

=pod

=head1 NAME

ECGListe - a module for alignment emailadresses with ECGListe

=head1 SYNOPSIS

  use warnings;
  use strict;
  use ECGListe qw( Abgleich );
	
  # 1. Argument: ecg-liste
  # 2. Argument: Eingabedatei
  # 3. Argument: (D)elimited (F)ix (G)esamt (wenn nur die Emailadresse in der Eingabedatei steht)
  # 4. Argument: wenn Delimited dann Feld der Emailadressen
  #              wenn Fix       dann Stelle,Laenge der Emailadressen
  #              wenn Gesamt    dann leer lassen
  # 5. Argument: wenn Delimited dann Trennzeichen
  #              sonst leer lassen

  # Example
  Abgleich("ecg-liste.hash", "Emailadressen.csv", "D", "1", ",");

=head1 DESCRIPTION

...

=head1 AUTHOR AND LICENSE

copyright 2009 (c)
Gernot Havranek

=cut
