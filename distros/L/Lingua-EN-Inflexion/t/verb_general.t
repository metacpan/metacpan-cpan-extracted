use Test::More;
use Lingua::EN::Inflexion;

for my $term (qw< am are is >) {
    subtest qq{"$term", singular and plural} => sub {
        my $verb = verb($term);

        is $verb->singular,    $term => "sing->sing:        $term -> $term";
        is $verb->plural,      'are' => "sing->plural:      $term -> are";
        is $verb->singular(1), 'am'  => "sing->sing   1st:  $term -> I am";
        is $verb->plural(1),   'are' => "sing->plural 1st:  $term -> We are";
        is $verb->singular(2), 'are' => "sing->sing   2nd:  $term -> You are";
        is $verb->plural(2),   'are' => "sing->plural 2nd:  $term -> Y'all are";
        is $verb->singular(3), 'is'  => "sing->sing   3rd:  $term -> It is";
        is $verb->plural(3),   'are' => "sing->plural 3rd:  $term -> They are";
    }
}

for my $modal (qw< can could may might must ought will shall should would >) {
    subtest qq{modal "$modal", singular and plural} => sub {
        my $verb = verb($modal);

        is $verb->singular,    $modal => "sing->sing:        $modal -> $modal";
        is $verb->plural,      $modal => "sing->plural:      $modal -> $modal";
        is $verb->singular(1), $modal => "sing->sing   1st:  $modal -> I $modal";
        is $verb->plural(1),   $modal => "sing->plural 1st:  $modal -> We $modal";
        is $verb->singular(2), $modal => "sing->sing   2nd:  $modal -> You $modal";
        is $verb->plural(2),   $modal => "sing->plural 2nd:  $modal -> Y'all $modal";
        is $verb->singular(3), $modal => "sing->sing   3rd:  $modal -> It $modal";
        is $verb->plural(3),   $modal => "sing->plural 3rd:  $modal -> They $modal";
    }
}

for my $line (<DATA>) {
    chomp $line;

    next if $line =~ m{\A \s* \Z  }xms;
    next if $line =~ m{\A \s* [#] }xms;

    my (                     $singular,   $plural,     $past,       $pres_part,  $past_part)
        = $line =~ m{ \A \s* (.+?) \s{2,} (.+?) \s{2,} (.+?) \s{2,} (.+?) \s{2,} (.+?) \s* \Z }xms
            or fail "Unexpected test data: $line";

    my $v_sing      = verb($singular );
    my $v_plur      = verb($plural   );
    my $v_past      = verb($past     );
    my $v_pres_part = verb($pres_part);
    my $v_past_part = verb($past_part);

    subtest qq{"$plural" singular and plural} => sub {
        is $v_sing->singular, $singular =>  "sing->sing: $singular -> $singular";
        is $v_sing->plural,   $plural   =>  "sing->plur: $singular -> $plural";
        is $v_plur->singular, $singular =>  "plur->sing: $plural -> $singular";
        is $v_plur->plural,   $plural   =>  "plur->plur: $plural -> $plural";
        for my $person (1..2) {
            is $v_sing->singular($person), $plural  =>  "sing$person->sing: $singular -> $plural";
            is $v_sing->plural($person),   $plural  =>  "sing$person->plur: $singular -> $plural";
            is $v_plur->singular($person), $plural  =>  "plur$person->sing: $plural -> $plural";
            is $v_plur->plural($person),   $plural  =>  "plur$person->plur: $plural -> $plural";
        }
        is $v_sing->singular(3), $singular =>  "sing3->sing: $singular -> $singular";
        is $v_sing->plural(3),   $plural   =>  "sing3->plur: $singular -> $plural";
        is $v_plur->singular(3), $singular =>  "plur3->sing: $plural -> $singular";
        is $v_plur->plural(3),   $plural   =>  "plur3->plur: $plural -> $plural";
        done_testing();
    };

    subtest qq{"$past"  (simple past)} => sub {
        is $v_sing->past,      $past  =>  "     sing->past: $singular -> $past";
        is $v_plur->past,      $past  =>  "     plur->past: $plural -> $past";
        is $v_past->past,      $past  =>  "     past->past: $past -> $past";
        is $v_past_part->past, $past  =>  "past_part->past: $past_part -> $past";
        done_testing();
    };

    subtest qq{"$pres_part"  (present participle)} => sub {
        is $v_sing->pres_part,      $pres_part  =>  "     sing->pres_part: $singular -> $pres_part";
        is $v_plur->pres_part,      $pres_part  =>  "     plur->pres_part: $plural -> $pres_part";
        is $v_pres_part->pres_part, $pres_part  =>  "pres_part->pres_part: $pres_part -> $pres_part";
        done_testing();
    };

    subtest qq{"$past_part"  (past participle)} => sub {
        is $v_sing->past_part,      $past_part  =>  "     sing->past_part: $singular -> $past_part";
        is $v_plur->past_part,      $past_part  =>  "     plur->past_part: $plural -> $past_part";
        is $v_past->past_part,      $past_part  =>  "     past->past_part: $past -> $past_part";
        is $v_past_part->past_part, $past_part  =>  "past_part->past_part: $past_part -> $past_part";
        done_testing();
    };
}

done_testing();

__DATA__

#   Singular      Plural        Preterite        Pres particple     Past participle
#   __________    ___________   _______          ______________     __________

    adds          add           added            adding             added
    banks         bank          banked           banking            banked
    befits        befit         befitted         befitting          befitted
    bestows       bestow        bestowed         bestowing          bestowed
    bingos        bingo         bingoed          bingoing           bingoed
    blitzes       blitz         blitzed          blitzing           blitzed
    boos          boo           booed            booing             booed
    boxes         box           boxed            boxing             boxed
    cries         cry           cried            crying             cried
    decrees       decree        decreed          decreeing          decreed
    ebbs          ebb           ebbed            ebbing             ebbed
    eggs          egg           egged            egging             egged
    errs          err           erred            erring             erred
    fibs          fib           fibbed           fibbing            fibbed
    flees         flee          fled             fleeing            fled
    fluffs        fluff         fluffed          fluffing           fluffed
    fulfils       fulfil        fulfilled        fulfilling         fulfilled
    graffitis     graffiti      graffitied       graffitiing        graffitied
    graphs        graph         graphed          graphing           graphed
    has           have          had              having             had
    jams          jam           jammed           jamming            jammed
    japes         jape          japed            japing             japed
    kings         king          kinged           kinging            kinged
    kisses        kiss          kissed           kissing            kissed
    kneads        knead         kneaded          kneading           kneaded
    needs         need          needed           needing            needed
    pours         pour          poured           pouring            poured
    prays         pray          prayed           praying            prayed
    proofs        proof         proofed          proofing           proofed
    putts         putt          putted           putting            putted
    reaps         reap          reaped           reaping            reaped
    revs          rev           revved           revving            revved
    scries        scry          scried           scrying            scried
    sins          sin           sinned           sinning            sinned
    tics          tic           ticced           ticcing            ticced
    tills         till          tilled           tilling            tilled
    yapps         yapp          yapped           yapping            yapped
    plays         play          played           playing            played
    preys         prey          preyed           preying            preyed
    toys          toy           toyed            toying             toyed
    sphinxes      sphinx        sphinxed         sphinxing          sphinxed
    forceps       forceps       forcepsed        forcepsing         forcepsed
    caches        cache         cached           caching            cached
    watches       watch         watched          watching           watched
    cashes        cash          cashed           cashing            cashed
    oboes         oboe          oboed            oboeing            oboed
    adieus        adieu         adieued          adieuing           adieued
    chateaus      chateau       chateaued        chateauing         chateaued
    buzzes        buzz          buzzed           buzzing            buzzed
    fondues       fondue        fondued          fondueing          fondued
    alibis        alibi         alibied          alibiing           alibied
    frees         free          freed            freeing            freed
    glues         glue          glued            glueing            glued
    eyes          eye           eyed             eyeing             eyed
    skis          ski           skied            skiing             skied
    misses        miss          missed           missing            missed
    razes         raze          razed            razing             razed
    cures         cure          cured            curing             cured
    bothers       bother        bothered         bothering          bothered
    fills         fill          filled           filling            filled

