use 5.012;
use warnings;
use Carp qw(cluck confess);
package FASTQ::Parser;
$FASTQ::Parser::VERSION = '0.01';
$FASTQ::Parser::AUTHOR = 'Fabrizio Levorin';
#ABSTRACT: *Internal test* code for non-Moose file reader;

sub new {
    my ($class, $args) = @_;
    my $self = {
        file  => $args->{file},
    };
    my $object = bless $self, $class;
 #   $object->{sequence} = [];
    $object->_find_sequence;
    return $object;
}

sub get_sequences {
    my $self = shift;
    return $self->{sequence};
}


sub _find_sequence {
	my $self = shift;

	# apro il file in lettura
	open my $fh, '<:encoding(UTF-8)', $self->{file} || confess "Could not open file '$self->{file}' $!\n";

	# Hash in cui memorizzo le sequenze, la chiave sarà il nome della sequenza e come valori
	# -seq	-> sequenza
	# -qual	-> qualità
	my %sequence;
	my $sequence_name;

	while (my $row = <$fh>) {
		chomp $row;

		# Elimino spazi iniziali e finali
		$row =~ s/^\s+|\s+$//g;

		# Nei file FASTA la sequenza inizia con il carattere >
		# nei file FASTQ la sequenza inizia con il carattare @
		if ( $row =~ /^>/ || $row =~ /^\@/ ) {
			$self->{file_type} = 'FASTA' if ( $row =~ /^>/ );
			$self->{file_type} = 'FASTQ' if ( $row =~ /^\@/ );

			# Devo creare un nuovo oggetto di tipo sequenza
			($sequence_name) = $row =~ /^.(.+)$/;

			#$self->_add_sequence($sequence_name);
			#my $hr_sequence = _new_sequence($row);
		}

		# Se la riga contiene solo le lettere acgt allora è la sequenza (che potrebbe essere splittata su più righe)
		elsif ( $row =~ /^[agct]+$/ ) {
			$sequence{$sequence_name}{seq} .= $row;
		}

		# Nei file FASTQ c'è il carattere + che separa la sequenza dalla qualita
		elsif ( $row eq '+' ) {
			# non faccio nulla
		}

		else {
			$sequence{$sequence_name}{qual} .= $row;
		}
	}

	# Dopo aver memorizzato tutte le sequenze le salvo come attributo (sarà un array di hash)
	$self->_add_sequence(\%sequence);

}

sub _add_sequence {
	my $self = shift;
	my ($hr_sequence) = @_;
	$self->{sequence} = $hr_sequence;
}


1;
