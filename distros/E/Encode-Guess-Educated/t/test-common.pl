use strict;
use warnings;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

for my $meth ( qw(output failure_output) ) {
    binmode Test::More->builder->$meth(), ":utf8";
}

use Carp qw(croak confess carp cluck);

$SIG{__WARN__} = sub { confess "FATALIZED WARNING @_" };
$SIG{__DIE__}  = sub { $^S || confess "UNCAUGHT FATAL @_"    };

sub raw_slurp {
    my $fn = shift;
    open(my $fh, "< :raw", $fn) || die "Can't open $fn: $!";
    local $/;
    my $data = <$fh>;
    close($fh) || die "Can't close $fn: $!";
    return $data;
} 

sub test_file {
    my($obj, $file, @encodings) = @_;

    my $utf8_data = raw_slurp($file);
    my $guess = $obj->guess_data_encoding($utf8_data);

    my @choices = Encode::Guess::Educated->get_suspects();

    if (is($guess, "utf8", "make sure $file is really utf8")) { 
	$utf8_data = decode("utf8", $utf8_data);
	for my $choice (@encodings) { 
	    my $as_8bit_text = encode($choice, $utf8_data, Encode::FB_PERLQQ());
	    next unless $as_8bit_text  =~ /[\x80-\xFF]/;
	    $obj->set_suspects($choice, @choices);  # use $choice for tiebreaking @choices
	    my $guess = $obj->guess_data_encoding($as_8bit_text);
	    unless (is($guess, $choice, "detect $file downverted to $choice")) {
		my $details = $obj->get_long_report();
		diag("failure details:\n$details\n");
	    } 
	} 
    }

} 

1;
