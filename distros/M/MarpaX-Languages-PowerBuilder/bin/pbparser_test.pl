use feature 'say';
use strict;
use warnings;

$|++; #autoflush stdout/stderr
my $pkg   = uc shift;
my $input = shift;

$pkg=~/^SR[QDJ]|PB[GWRT]$/ and $input or die "usage: $0 SR?|PB? input-file-name.sr?";
$pkg = "MarpaX::Languages::PowerBuilder::$pkg";
eval "require $pkg;1" or die $@;

say $pkg;

my $parsed = $pkg->new->parse( $input );
print $input, " .. ";
if($parsed->{error}){
    say "nok";
    say '-' x 40;
    say "OUPS: ", $parsed->{error};
    exit 1;
}
if($pkg eq 'SRQ'){
    say $parsed->sql;
}
else{
    say "ok";
	if(eval 'use Data::Dumper::GUI; 1'){
        Dumper( $parsed->value );
    }
    else{
        require Data::Dumper;
        say Data::Dumper::Dumper( $parsed->value );
    }
}
