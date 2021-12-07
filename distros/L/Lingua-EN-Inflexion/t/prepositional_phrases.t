use Test::More;
use Lingua::EN::Inflexion;

for my $line (<DATA>) {
    chomp $line;

    next if $line =~ m{\A \s* \Z  }xms;
    next if $line =~ m{\A \s* [#] }xms;

    my (                     $ambig,  $singular,       $plural,                 $classical)
        = $line =~ m{ \A \s* (!?) \s* (.*?) \s* => \s* ([^|]*?) \s* (?: [|] \s* (.*?) )? \s* \Z }xms
            or fail "Unexpected test data: $line";

    $plural ||= $classical;

    my $n_sing  = noun($singular  );
    my $n_plur  = noun($plural    );

    subtest "$singular -> $plural" => sub {
        is $n_sing->singular, $singular => "s->s: $singular -> $singular";
        is $n_sing->plural,   $plural   => "s->p: $singular -> $plural";
        is $n_plur->singular, $singular => "p->s: $plural -> $singular";
        is $n_plur->plural,   $plural   => "p->p: $plural -> $plural";
        done_testing();
    };

    if ($classical) {
        subtest "$singular -> $classical (classical)" => sub {
            my $n_class = noun($classical);

            is $n_sing->classical->singular,  $singular  =>  "sc->s: $singular -> $singular";
            is $n_sing->classical->plural,    $classical =>  "sc->p: $singular -> $classical";
            if (!$ambig) {
                is $n_class->classical->singular, $singular  =>  "pc->s: $plural -> $singular";
            }
            is $n_class->classical->plural,   $classical =>  "pc->pc: $plural -> $plural";
            done_testing();
        };
    }
}

done_testing();

__DATA__

    to me  => to us
    to you => to you
    to it  => to them

    with jam   => with jams
    with sheep => with sheep
    with man   => with men
