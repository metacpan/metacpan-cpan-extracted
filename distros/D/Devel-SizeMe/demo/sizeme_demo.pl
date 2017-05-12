
use strict;
use Term::ReadKey;
use IO::Handle;

$ENV{SIZEME_HIDE} = 1; # hide addr to refcnt=1 and immortals

my @steps = (
    {
        note => "Integer value",
        perl => q{total_size(1)},
    },
    {
        note => "String value",
        perl => q{total_size("Hello world!")},
    },
    {
        note => "Numeric value",
        perl => q{total_size(rand)},
    },
    {
        note => "Numeric value, stringified",
        perl => q{$data = rand(); print "$data\n"; total_size($data)},
    },
    {
        note => "Array",
        perl => q{$data = [ 42, "Hi!", rand ]; total_size($data)},
    },
    {
        note => " ... as token stream",
        sizeme => q{| cat},
        perl => q{$data = [ 42, "Hi!", rand ]; total_size($data)},
    },
    {
        note => " ... processed by sizeme_store.pl",
        sizeme => q{| sizeme_store.pl --text},
        perl => q{$data = [ 42, "Hi!", rand ]; total_size($data)},
    },
    {
        note => " ... generating Graphviz dot",
        sizeme => q{| sizeme_store.pl --dot sizeme.dot --open},
        perl => q{$data = [ 42, "Hi!", rand ]; total_size($data)},
    },
    #{ note => "Reference counting", sizeme => q{| sizeme_store.pl --dot sizeme.dot --open}, perl => q{$ref = {}; $data = [ $ref, $ref, $ref ]; undef $ref; total_size($data)}, },
    {
        note => "Array of hashes - dashed line shows alternative 'route'",
        sizeme => q{| sizeme_store.pl --dot sizeme.dot --open},
        perl => q{$data = [ { foo => 42 }, { foo => 43 } ]; total_size($data)},
    },
    {
        note => "Limit of reference chasing - dotted line shows unfollowed reference",
        sizeme => q{| sizeme_store.pl --dot sizeme.dot --open},
        perl => q{$data = { ref_we_do_not_own => \@ARGV }; total_size($data)},
    },
    {
        note => "Subroutine",
        sizeme => q{| sizeme_store.pl --dot sizeme.dot --open},
        perl => q{sub fac { my $x=shift; return $x if $x <= 1; return fac($x-1) }; $data = \&fac; total_size($data)},
    },
    {
        note => "Subroutine that has recursed",
        sizeme => q{| sizeme_store.pl --dot sizeme.dot --open},
        perl => q{sub fac { my $x=shift; return $x if $x <= 1; return fac($x-1) }; fac(3); $data = \&fac; total_size($data)},
    },
    {
        note => "Package",
        sizeme => q{| sizeme_store.pl --dot sizeme.dot --open},
        perl => q{$data = \%Exporter::; total_size($data)},
    },
    {
        note => " ... same but hide some less interesting details",
        hide => '7',
        sizeme => q{| sizeme_store.pl --dot sizeme.dot --open},
        perl => q{$data = \%Exporter::; total_size($data)},
    },
    {
        note => "Now try a bigger package (slow to open)",
        hide => '7',
        sizeme => q{| sizeme_store.pl --dot sizeme.dot --open},
        perl => q{$data = \%main::; total_size($data)},
    },
    {
        note => "Entire perl interpreter! (No --open option - too slow!)",
        hide => '7',
        sizeme => q{| sizeme_store.pl --dot sizeme.dot},
        perl => q{perl_size()},
    },
    {
        note => "Entire perl interpreter written to a SQLite db",
        hide => '7',
        sizeme => q{| sizeme_store.pl --db sizeme.db},
        perl => q{use Moo; heap_size()},
    },
    {
        note => "Entire perl interpreter written to a GEXF file",
        hide => '7',
        sizeme => q{| sizeme_store.pl --gexf sizeme.gexf --open},
        perl => q{use Moo; heap_size()},
        post_comand => 'open -a Gephi',
    },
);

sub runstep {
    my ($spec) = @_;
    print "\n";

    my $cmd = "perl -MDevel::SizeMe=:all -e '$spec->{perl}'";

    my @exports;
    local $ENV{SIZEME} = $spec->{sizeme};
    push @exports, "SIZEME='$spec->{sizeme}'";
    local $ENV{SIZEME_HIDE} = $spec->{hide}      if defined $spec->{hide};
    push @exports, "SIZEME_HIDE='$spec->{hide}'" if defined $spec->{hide};

    print "-------- $spec->{note} --------\n\n";
    print "\$ export @exports\n";
    print "\$ $cmd ";
    my $key = getkey();
    if ($key =~ m/[ npl]/i) {
        print "\012".(" " x 80)."\n";
        return $key;
    }
    print "\n\n";
    system $cmd;
    print "\n";
    system $spec->{post_comand} if $spec->{post_comand};
    return undef;
}

my $atstep = 0;

while (my $key = runstep($steps[$atstep]) || getkey()) {
    if ($key =~ m/[ n\n]/) {
        if ($atstep == @steps-1) {
            warn "[LAST EXAMPLE]\n";
        }
        ++$atstep if $atstep < @steps-1;
    } 
    elsif ($key =~ m/[p]/) { --$atstep if $atstep > 0; }
    elsif ($key =~ m/[l]/) { $atstep = @steps-1; }
    else {
        print "[press n, p, l, or q]\n";
        $key = getkey();
        redo;
    }
}


sub getkey {
    STDOUT->flush();
    ReadMode 'raw';
    my $key = ReadKey(0);
    ReadMode 'normal';
    exit 1 if $key =~ /[q\x03\x04]/i;
    return $key;
}
