use lib '../lib';
use Lingua::EN::Conjugate qw( conjugations conjugate);

my @opts =  qw(verb negation question no_pronoun tense passive pronoun modal allow_contractions);
$opt{verb} = 'do';

while (1) {

    print "(opt, quit, x=y)>";
    my $opt = <>;
    chomp $opt;

    if ( $opt =~ /^opt/i ) {
        for ( @opts ) {

	   printf "%20s -> %s\n", $_, (defined $opt{$_}? ref $opt{$_}? join(", ", @{$opt{$_}}) : $opt{$_}: '');
	    
        }
        next;

    }

    exit if $opt =~ /^quit/i;

    ( $x, $y ) = ( $opt =~ /(\S+) *[ ,=] *(.*)/ ) or next;
    next unless match_any( $x, @opts );

    if ( $y eq 'undef' ) { delete $opt{$x}; }

    else {
        if ( $y =~ /,/ ) {
            @y = split / *, */, $y;

            $y = [@y];
        }
#	else { $y = [$y]; }

        $opt{$x} = $y;
    }

    print conjugations(%opt);

}

sub match_any {
    my $a = shift;
    my @b = @_;
    for (@b) { return 1 if $a =~ /\b$_\b/i; }
    return undef;
}

