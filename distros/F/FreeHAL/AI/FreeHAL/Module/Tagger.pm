package AI::FreeHAL::Module::Tagger;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

    # set the version for version checking
    $VERSION = 0.01;

    @ISA = qw(Exporter);

    # functions
    @EXPORT = qw(
        &pos_prop
        &pos_of
    );
    %EXPORT_TAGS = ();    # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK = qw();
}
our @EXPORT_OK;

our $data = {};
our %config;

use AI::Util;
use AI::POS;

use Data::Dumper;

our @functions = qw{
    sql_get_part_of_speech_property
    pos_prop
    short_save_in_memory
    pos_of
    find_word_type
};

sub sql_get_part_of_speech_property {
    my ($word) = @_;

    return { type => '', genus => '' } if !$data->{modes}{use_sql};

    #say 'word', $word;

    eval q{

    use DBI;

    my $db_string = "DBI:mysql:database=" . $config{'mysql'}{'database'};
    if ( $config{'mysql'}{'host'} ) {
        $db_string .= ';host=' . $config{'mysql'}{'host'};
    }
    my $user      = $config{'mysql'}{'user'};
    my $password  = $config{'mysql'}{'password'};
    my $dbh       = DBI->connect( $db_string, $user, $password )
      or (
        say(
            "not connected to ",
            $config{'mysql'}{'database'},
            ", user ",
            $config{'mysql'}{'user'},
            ", password ",
            $config{'mysql'}{'user'},
            ": "
        )
        and return { type => '', genus => '' }
      );

    my $sql = qq{SELECT type, genus FROM part_of_speech WHERE word = '$word' };
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( $sth && ( my $data = $sth->fetchrow_arrayref ) ) {
        my $return_hash = { type => $data->[0], genus => $data->[1] };

        print Dumper $return_hash;
        $sth->finish();
        $dbh->disconnect();
        return $return_hash;
    }
    $sth->finish();
    $dbh->disconnect();
    } if !$::batch;
    return { type => '', genus => '' };
}

sub pos_prop {
    my ( $CLIENT_ref, $word, $count, $not_guess, $not_ask,
        $write_it_into_database )
      = @_;

    if ( !$data->{abilities}->{'tagger'} ) {
        my $sock = ${ connect_to( data => *data, name => 'tagger' ) };

        print {$sock} 'GET<;;>genus<;;>', join( '<;;>', @_ ) . "\n";
        my $result = <$sock>;
        chomp $result;

        close $sock;

        eval {
            local $SIG{'__DIE__'};
            $result = thaw( r_unescape($result) );
        };
        if ($@) {
            say 'error in that(): ', $@;
        }
        return $result;
    }

    AI::FreeHAL::Engine::try_use_lowlatency_mode();

    my $CLIENT = undef;
    eval '$CLIENT = ${$CLIENT_ref};';

    $count                  ||= 0;
    $write_it_into_database ||= 0;

    #$word =~ s/^(.ein.?.?)qq/$1_/igm;

    $word =~ s/^ein(.?)[_\s]//igm;
    $word =~ s/[-]//gm;
    $word =~ s/^(und|or|and|oder)\s+//gm;
    $word =~ s/_/ /igm;
    $word =~ s/^\s+//igm;
    $word =~ s/\s+$//igm;

    #if ( $word ne lc $word ) {
    $word = ucfirst lc $word;

    #}

    if ( $has_no_genus{$word} ) {
        part_of_speech_get_memory()->{$word}->{'genus'} = q{q};
    }

    part_of_speech_get_memory()->{$word} = part_of_speech_get_entry($word)
      if !$::batch && !part_of_speech_get_memory()->{$word};

    my $last_word = ( split /\s|[_]/, $word )[-1];
    if (   $last_word
        && $word ne $last_word )
    {

        my $props_for_last_word =
          pos_prop( $CLIENT_ref, $last_word, 0, $not_guess, $not_ask,
            $write_it_into_database );
        if ( $props_for_last_word->{'genus'} ) {
            return $props_for_last_word;
        }
    }

    #say '$not_guess: ', $not_guess || 0;

    # $CLIENT_ref, $word, $at_beginning_of_sentence, $noun_automatism,
    #    $do_not_ask_user, $sentence, $do_not_guess, $do_save

    my $type_str = q{};    # empty
    if (   !$not_guess
        && pos_of( $CLIENT_ref, $word, 0, 1, 0, undef, 0, 0 ) == $data->{const}{NOUN}
        && !$has_no_genus{ lc $word } )
    {

        if (
            (
                !defined part_of_speech_get_memory()->{$word}->{'genus'}
                || (
                      part_of_speech_get_memory()->{$word}->{'genus'}
                    ? part_of_speech_get_memory()->{$word}->{'genus'}
                    : q{-}
                ) eq '-'
                || (
                    length( part_of_speech_get_memory()->{$word}->{'genus'} ) ==
                    0
                    && defined part_of_speech_get_memory()->{$word}->{'genus'} )

                # experimental
                # ask if german mode and there is a "q" in db
                || (   LANGUAGE() eq 'de'
                    && part_of_speech_get_memory()->{$word}->{'genus'} eq 'q' )

            )
            && (   !( ( sql_get_part_of_speech_property $word)->{genus} )
                && !( ( sql_get_part_of_speech_property lc $word )->{genus} ) )
          )
        {

            if ( !$has_no_genus{ lc $word } ) {

                my $first_word = ( split /\s|[_]/, $word )[0];

                $first_word =~ s/_$//igm;
                $last_word  =~ s/_$//igm;

                my $wt =
                  pos_of( $CLIENT_ref, $word, 0, 1, 0, undef, 0, 0 );
                my $first_wt =
                    $word eq $last_word
                  ? $wt
                  : pos_of( $CLIENT_ref, $first_word, 0, 1, 0, undef, 0,
                    0 );
                my $last_wt =
                    $word eq $last_word
                  ? $wt
                  : pos_of( $CLIENT_ref, $last_word, 0, 1, 0, undef, 0,
                    0 );

                if ( $count > 5 ) {
                    $type_str = 'perhaps_s';
                }
                elsif ( ( $first_wt == $data->{const}{ADJ} || $first_wt == $ART )
                    && $first_word =~ /^[a-zA-Z]+nen$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ernet$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+urm$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+tter$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ek$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+urti$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( ( $first_wt == $data->{const}{ADJ} || $first_wt == $ART )
                    && $first_word =~ /^[a-zA-Z]+nem$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( ( $first_wt == $data->{const}{ADJ} || $first_wt == $ART )
                    && $first_word =~ /^[a-zA-Z]+ner$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( $last_word =~ /^[a-zA-Z]+re$/ ) {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+adt$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( $first_word =~ /^[a-zA-Z]+ige$/ ) {
                    $type_str = 'perhaps_f';
                }

                #elsif ( ( $first_wt == $data->{const}{ADJ} || $first_wt == $ART )
                #&& $first_word =~ /^[a-zA-Z]+nen$/ )
                #{
                #(my $modified = $last_word ) =~ s/nen$/n/;

                #my $revert_changes = 0;
                #if ( !part_of_speech_get_memory()->{$modified} ) {
                #$revert_changes = 1;
                #}

                ## $CLIENT_ref, $word, $count, $not_guess, $not_ask, $write_it_into_database

      #$type_str = pos_prop($CLIENT_ref, $modified, 0, 0, 1, 5)->{genus};
      #say 'reduzed to ', $modified, ' => ', $type_str;
      #if ( $revert_changes ) {
      #part_of_speech_get_memory()->{$word} = undef;
      #}
      #$revert_changes = 0;
      #$modified .= 'e';
      #if ( !part_of_speech_get_memory()->{$modified} ) {
      #$revert_changes = 1;
      #}
      #$type_str = pos_prop($CLIENT_ref, $modified, 0, 0, 1, 5)->{genus};
      #say 'reduzed to ', $modified, ' => ', $type_str;

                #if ( $revert_changes ) {
                #part_of_speech_get_memory()->{$word} = undef;
                #}

                #$type_str ||= 'perhaps_f';
                #}
                #elsif ( $last_word =~ /^[a-zA-Z]+[ndgmr]e[nsrm]$/ )
                #{
                #(my $modified = $last_word ) =~ s/.e.$/n/;

                #my $revert_changes = 0;
                #if ( !part_of_speech_get_memory()->{$modified} ) {
                #$revert_changes = 1;
                #}

      #$type_str = pos_prop($CLIENT_ref, $modified, 0, 0, 1, 5)->{genus};
      #say 'reduzed to ', $modified, ' => ', $type_str;
      #if ( $revert_changes ) {
      #part_of_speech_get_memory()->{$word} = undef;
      #}
      #$revert_changes = 0;
      #$modified .= 'e';
      #if ( !part_of_speech_get_memory()->{$modified} ) {
      #$revert_changes = 1;
      #}
      #$type_str = pos_prop($CLIENT_ref, $modified, 0, 0, 1, 5)->{genus};
      #say 'reduzed to ', $modified, ' => ', $type_str;

                #if ( $revert_changes ) {
                #part_of_speech_get_memory()->{$word} = undef;
                #}

                #$type_str ||= 'perhaps_f';
                #}
                #elsif ( $last_word =~ /^[a-zA-Z]+[nsmr]$/ )
                #{
                #(my $modified = $last_word ) =~ s/.$/n/;

                #my $revert_changes = 0;
                #if ( !part_of_speech_get_memory()->{$modified} ) {
                #$revert_changes = 1;
                #}

       #$type_str = pos_prop($CLIENT_ref, $modified, 0, 0, 1, 5)->{genus}
       #if $last_word ne $modified;
       #say 'reduzed to ', $modified, ' => ', $type_str;
       #if ( $revert_changes ) {
       #part_of_speech_get_memory()->{$word} = undef;
       #}
       #$revert_changes = 0;
       #$modified .= 'e';
       #if ( !part_of_speech_get_memory()->{$modified} ) {
       #$revert_changes = 1;
       #}
       #$type_str = pos_prop($CLIENT_ref, $modified, 0, 0, 1, 5)->{genus}
       #if $last_word ne $modified;
       #say 'reduzed to ', $modified, ' => ', $type_str;

                #if ( $revert_changes ) {
                #part_of_speech_get_memory()->{$word} = undef;
                #}

                #$type_str ||= 'perhaps_f';
                #}
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+in$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+innen$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+cken$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+iz$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ahn$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+aus$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+rom$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+amm$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+uhr$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ann$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+aph$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ext$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+od$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ohn$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+plan$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ahlen$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ua$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+uehr$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ot$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+erb$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ity$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ey$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+weg$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ind$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*?hut$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*?mut$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ut$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+na$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+aetz$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ruck$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ssi$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ail$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+til$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+opf$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*lauch$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*auch$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*och$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ip$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ell$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*fehl$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*ie$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*?[bt]uch$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*?ucht$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+mpf$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ift$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ausch$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*(st|r|erb)and$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*(l)and$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*and$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*ient$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+urst$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+unst$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+eil$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+wort$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+sort$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+to$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*zug$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*ad$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*al$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*koll$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*att$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*iki$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*fest$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*schuh$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+all$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+lust$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ust$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+uehl$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+rief$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+rst$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+epp$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+kt$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+nsa$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*zeit$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*bahn$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+beit$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ilz$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+eis$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ei[gk]$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+(ta|um)$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+off$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ohl$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+[ae]rz$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+a[xgst]$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ef$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+do$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+go$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+iff$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+eld$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ied$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+rist$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ist$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+af$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ock$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+uck$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*?ha[n]t$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+raut$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*?luft$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+huft$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+aut$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+urz$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+esen$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+acken$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+uhl$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+uv$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+orf$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+olk$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+raft$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+id$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ack$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+weck$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ueck$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+atz$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ank$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+and$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+itz$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ett$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+la$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ma$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+und$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ereich$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+rich$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+eich$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ard$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*ast$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+uff$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+iet$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*zeug$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*ing$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*isch$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*[rw]icht$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*ap$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*[d]icht$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*icht$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*acht$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*leid$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ol$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+nch$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ahl$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+aeck$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+net$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+et$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+eo$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ex$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+erl$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+nia$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+olg$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*utsch$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+log$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ang$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+amt$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+yp$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ko$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+alg$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+[nkr]itt$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+tab$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]*[rtmg]at$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+aupt$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+a[l]$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+olt$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+old$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ald$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+el$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ien$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+auf$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+rma$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ra$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ert$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ngen$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+erk$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+gen$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+[rhs]o$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ben$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+ten$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+olf$/ )
                {
                    $type_str = 'perhaps_m';
                }
                elsif (LANGUAGE() eq 'de'
                    && ( $first_wt == $data->{const}{ADJ} || $first_wt == $ART )
                    && $first_word =~ /^[a-zA-Z]+ne$/ )
                {
                    $type_str = 'perhaps_f';
                }
                elsif (LANGUAGE() eq 'de'
                    && $first_wt == $ART
                    && lc $first_word eq 'der' )
                {
                    $type_str = 'perhaps_m';
                }
                elsif (LANGUAGE() eq 'de'
                    && $first_wt == $ART
                    && lc $first_word eq 'die' )
                {
                    $type_str = 'perhaps_f';
                }
                elsif (LANGUAGE() eq 'de'
                    && $first_wt == $ART
                    && lc $first_word eq 'das' )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?(ismus|ling|or|ant)$/i )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?e$/i )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?er$/i )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?ers$/i )
                {
                    $type_str = 'perhaps_m';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?ens$/i )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?(on|um)$/i )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?(on|um)s$/i )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?ung$/i )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?au$/i )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?nis$/i )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && length($last_word) == 1 )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~
                    /.+?(ung|heit|keit|schaft|ei|enz|ie|ik|ion|taet|ur)$/i )
                {
                    $type_str = 'perhaps_f';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+st$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+e$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /^[a-zA-Z]+en$/ )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( LANGUAGE() eq 'de'
                    && $last_word =~ /.+?(chen|lein|um|ment)$/i )
                {
                    $type_str = 'perhaps_s';
                }
                elsif ( $::batch || !$AI::SemanticNetwork::initialized ) {
                    $type_str = 'perhaps_s';
                }
                elsif ( $last_wt == $data->{const}{NOUN} ) {
                    my $downloaded_genus = download_genus($last_word);

                    if ($downloaded_genus) {
                        $type_str = $downloaded_genus;
                    }
                    elsif ( LANGUAGE() eq 'en'
                        && !$AI::SemanticNetwork::initialized )
                    {
                        $type_str = 'perhaps_s';
                    }
                    elsif ( $last_word eq lc $last_word ) {
                        $type_str = 'perhaps_s';
                    }
                    elsif ( !$AI::SemanticNetwork::initialized && $in_cgi_mode )
                    {
                        $type_str = 'perhaps_s';
                    }
                    elsif ($not_ask) {
                        $type_str = 'q';
                    }
                    else {
                        $write_it_into_database ||= 1;
                        my $line = impl_get_genus( $CLIENT_ref, $last_word );

                        # return 'EXIT' if $line eq 'EXIT';
                        $type_str =
                            $line == 1 ? 'm'
                          : $line == 2 ? 'f'
                          : $line == 3 ? 's'
                          :              '';
                    }

                }
                else {
                    $type_str = 'perhaps_s';
                }
            }

            if ( !$type_str && !$has_no_genus{$word} ) {
                print "Redoing: pos_prop( $CLIENT_ref, $word )\n";
                return pos_prop( $CLIENT_ref, $word, $count + 1 );
            }

            if ( $write_it_into_database && $write_it_into_database != 5 ) {
                if ($use_sql) {
                    eval q{
                    use DBI;
                    my $db_string = "DBI:mysql:database=" . $config{'mysql'}{'database'};
                    if ( $config{'mysql'}{'host'} ) {
                        $db_string .= ';host=' . $config{'mysql'}{'host'};
                    }
                    my $user      = $config{'mysql'}{'user'};
                    my $password  = $config{'mysql'}{'password'};
                    my $dbh       = DBI->connect( $db_string, $user, $password )
                      or say(
                        "not connected to ",
                        $config{'mysql'}{'database'},
                        ", user ",
                        $config{'mysql'}{'user'},
                        ", password ",
                        $config{'mysql'}{'user'},
                        ": "
                      );

                    my $sql =
                      qq{SELECT word FROM part_of_speech WHERE word = '$word'};
                    my $sth = $dbh->prepare($sql);
                    $sth->execute();

                    if ( !( $sth && ( my $data = $sth->fetchrow_arrayref ) ) ) {
                        $dbh->do(
qq{INSERT INTO part_of_speech( word, type, genus ) VALUES ( '$word', '', '' )}
                        );
                    }

                    $sql =
qq{UPDATE part_of_speech SET genus = '$type_str' WHERE word = '$word'};
                    my $sth = $dbh->prepare($sql);
                    $sth->execute();
                    $dbh->disconnect();
                    } if !$::batch;
                }
                else {

                    part_of_speech_get_memory()->{$word}->{'genus'} = $type_str;

                    delete part_of_speech_get_memory()->{''};
                    delete part_of_speech_get_memory()->{' '};
                }
            }

        }
    }

    #    if ( part_of_speech_get_memory()->{$word}->{'genus'} eq "w" ) {
    #        part_of_speech_get_memory()->{$word}->{'genus'} = "f";
    #    }

    my $return_value = part_of_speech_get_memory()->{$word};

    return {
        type => (
                 ( part_of_speech_get_memory()->{$word} || {} )->{type}
              || ( ( sql_get_part_of_speech_property $word) || {} )->{type}
              || ( ( sql_get_part_of_speech_property lc $word ) || {} )->{type}
        ),
        genus => (
                 $type_str
              || ( part_of_speech_get_memory()->{$word}         || {} )->{genus}
              || ( ( sql_get_part_of_speech_property $word)     || {} )->{genus}
              || ( ( sql_get_part_of_speech_property lc $word ) || {} )->{genus}
        ),
    };
}

sub short_save_in_memory {
    my ( $do_save, $word, $type, $always ) = @_;
    
    say "$config{'features'}{'tagger'}: ", $config{'features'}{'tagger'};

    if (   part_of_speech_get_memory()->{$word}->{'type'}
        && part_of_speech_get_memory()->{$word}->{'type'} ne 'q'
        && (!$always||!$config{'features'}{'tagger'}) )
    {

        return $type;
    }

    if ( !$do_save ) {
        return $type;
    }

    part_of_speech_get_memory()->{$word}->{'new'} = 1;
    
    print "short_save_in_memory\n";
    print join(', ', @_), "\n";

    my $val = $data->{lang}{string_to_constant}{ part_of_speech_get_memory()->{$word}->{'type'} =
          $data->{lang}{constant_to_string}{$type} };
    print "val: ", $val, "\n";
    return $val;
}

sub pos_of {
    my (
        $CLIENT_ref,               $word,
        $at_beginning_of_sentence, $noun_automatism,
        $do_not_ask_user,          $sentence,
        $do_not_guess,             $do_save,
        $no_autoguess
    ) = @_;

    my $CLIENT = undef;
    eval '$CLIENT = ${$CLIENT_ref};';

    $do_save = 1 if !defined $do_save;

    $do_not_guess ||= 0;

    return $data->{const}{NO_POS} if !defined $word;
    return $data->{const}{NO_POS} if !$word;

    $word =~ tr/-/ /;

    if ( !$sentence ) {
        $sentence = $word;
    }

    $noun_automatism = 1 if !defined $noun_automatism;

    if ( $word ne lc $word ) {
        $word = ucfirst lc $word;
    }

    my $user_defined_word_type = undef;
    if ( $_[1] =~ /[{][{][{]/ ) {
        ( $_[1], my $type ) = split /[{][{][{]/, $_[1];
        $type = ( split /[}]/, $type )[0];
        my $type_value = undef;
        my $exec_str   = '$type_value = $' . uc $type . ';';
        say $exec_str;
        eval $exec_str;
        if ( $type_value && !$@ ) {
            say 'ok. '
              . $_[1] . "->"
              . $type_value . "->"
              . $data->{lang}{constant_to_string}{$type_value};
            part_of_speech_get_memory()->{ $_[1] }->{'type'} =
              $data->{lang}{constant_to_string}{$type_value};
            say 'ok...';
            if ($at_beginning_of_sentence) {
                say 'added to cache_noun_or_not';
                $cache_noun_or_not{ $_[1] } = $type_value;
                $cache_noun_or_not{ lc $_[1] } = $type_value;
            }

          #delete part_of_speech_get_memory()->{''};
          #delete part_of_speech_get_memory()->{' '};
          #            foreach my $key ( keys %{part_of_speech_get_memory()} ) {
          #                delete part_of_speech_get_memory()->{$key}
          #                    if $key =~ /['"*+\-)(]|(^[\s_])/;
          #            }

            say 'ok... ...';

            # return $type_value;

            return pos_of( $CLIENT_ref, $_[1], $at_beginning_of_sentence,
                $noun_automatism, $do_not_ask_user, $sentence, $do_not_guess );
        }
    }

    if ( !$data->{abilities}->{'tagger'} ) {
        my $sock = ${ connect_to( data => *data, name => 'tagger' ) };

        print {$sock} 'GET<;;>type<;;>' . join( '<;;>', @_ ) . "\n";
        my $result = <$sock>;

        while ( $result =~ /GET_WORD_TYPE:/ ) {
            print $CLIENT $result;

            while ( defined( $result = <$CLIENT> ) ) {
                if ( $result =~ /HERE_IS/ ) {
                    print $sock $result;
                    last;
                }
            }
            $result = <$sock>;
        }

        chomp $result;

        #print 'result:', Dumper $result;

        close $sock;

        $result ||= r_escape( nfreeze( \undef ) );

        eval {
            local $SIG{'__DIE__'};
            $result = ${ thaw( r_unescape($result) ) };
        };
        if ($@) {
            say 'error in thaw(): ', $@;
        }
        return $result;
    }
    
    AI::FreeHAL::Engine::try_use_lowlatency_mode();

    $word =~ s/^ein(.?)[_\s]//igm;
    $word =~ s/^(und|or|and|oder)\s+//gm;
    $word =~ s/[{]//gm;
    $word =~ s/[}]//gm;
    $word =~ s{/}{}gm;
    $word =~ s/|//gm;
    $word =~ s/[-]//gm;

    #$word =~ s/^(.ein.?.?)qq/$1_/igm;
    chomp $word;

    if ( $word ne lc $word ) {
        $word = ucfirst lc $word;
    }

    return $data->{const}{ADJ} if $word =~ /^[-\s+]?\d+$/;
    return $data->{const}{ADJ}
      if $word =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/;
    return $data->{const}{ADJ} if $word =~ /^\d+$/;
    return $data->{const}{ADJ} if $word =~ /^\d+[_]\d+[_]\d+$/;
    return $data->{const}{ADJ} if $word =~ /_komma_/;
    return $data->{const}{INTER} if $word eq '+' || $word eq '-';

    return $data->{const}{NO_POS} if not $word;
    return $data->{const}{NO_POS} if $word =~ /^[?,;]/;
    return $data->{const}{ADJ}          if $word =~ /[(]/;
    return $data->{const}{NOUN}         if $word =~ /http[:]/i;
    return $data->{const}{NOUN}         if $word =~ /['"]/;
    return $data->{const}{ADJ}          if $word =~ /zum_/;
    return $data->{const}{ADJ}          if $word =~ /zur_/;
    return $data->{const}{NOUN}         if $word =~ /_/;
    return $data->{const}{NOUN}         if $word =~ / /;
    return $data->{const}{NOUN}         if $word =~ /^\$\$/;
    return $data->{const}{NOUN}         if $word =~ /^\s/;
    return $data->{const}{ADJ}          if $word =~ /[%]/;

    $word =~ s/\.|[?!,;]//gm;

    my $word_low = lc $word;

    return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
      if $word eq $word_low && $word =~ /los$/;
    return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )
      if $word eq $word_low && $word =~ /machen$/;
    return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )
      if $word eq $word_low && $word =~ /mache$/;
    return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )
      if $word eq $word_low && $word =~ /machst$/;
    return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )
      if $word eq $word_low && $word =~ /macht$/;
    return $ART if $word_low eq q{a} && LANGUAGE() eq 'en';

    #say 'pos_of(' . $word . ')';

    if ( $word_low =~ /\s/ ) {
        my $last_word = ( split /\s+/, $word_low )[-1];
        return (
            pos_of(
                $CLIENT_ref,               $last_word,
                $at_beginning_of_sentence, $noun_automatism,
                $do_not_ask_user,          $sentence
            )
        );
    }

    say '.';
    my $builtin_table = AI::FreeHAL::Engine::build_builtin_table( LANGUAGE() );
    #print Dumper $builtin_table;
    say ',';
    
    if ( defined $builtin_table->{$word_low} ) {
        return short_save_in_memory( $do_save, $word,
            $builtin_table->{$word_low} );
    }

    {
        my $word_low_stripped = $word_low;

        $word_low_stripped =~ s/.$//;

        if ( defined $builtin_table->{$word_low_stripped} ) {
            return short_save_in_memory( $do_save, $word,
                $builtin_table->{$word_low_stripped} );
        }

        $word_low_stripped =~ s/.$//;

        if ( defined $builtin_table->{$word_low_stripped} ) {
            return short_save_in_memory( $do_save, $word,
                $builtin_table->{$word_low_stripped} );
        }

        $word_low_stripped =~ s/.$//;

        if ( defined $builtin_table->{$word_low_stripped} ) {
            return short_save_in_memory( $do_save, $word,
                $builtin_table->{$word_low_stripped} );
        }
    }

    if ( !$no_autoguess && $config{'features'}{'tagger'} ) {
        if ( LANGUAGE() eq 'de' ) {
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN}, 1 )    #always
              if $word =~ /kern$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )     #always
              if $word =~ /.farben$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )     #always
              if $word =~ /.quent$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if ( $word eq lc $word || $at_beginning_of_sentence )
              && $word =~ /(der|al|haft|lich|ig|bar|isch|ich)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )     #always

              if ( $word ne lc $word || $at_beginning_of_sentence )
              && $word =~ /.(haft|lich|ig|isch|ich)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{QUESTIONWORD} )
              if ( $word eq lc $word || $at_beginning_of_sentence )
              && $word =~ /^wor/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if ( $word eq lc $word || $at_beginning_of_sentence )
              && $word =~ /(der|al|ich|bar)e$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if ( $word eq lc $word || $at_beginning_of_sentence )
              && $word =~ /(der|al|ich|bar)es$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if ( $word eq lc $word || $at_beginning_of_sentence )
              && $word =~ /(der|al|ich|bar)en$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if ( $word eq lc $word || $at_beginning_of_sentence )
              && $word =~ /(der|al|ich|bar)em$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if ( $word eq lc $word || $at_beginning_of_sentence )
              && $word =~ /(der|al|ich|bar)er$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if ( $word eq lc $word || $at_beginning_of_sentence )
              && $word =~ /(ss|mm|nn|gg)er$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )
              if $word =~ /^(ge|$regex_str_verb_prefixes).*?t$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /^(ge|ver).*?ten$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN}, 1 )
              if $word =~ /(heit|keit)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word =~ /(haft|lich|ig|isch|dnet)e?$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word =~ /(haft|lich|ig|isch|dnet)es$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word =~ /(haft|lich|ig|isch|dnet)en$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word =~ /(haft|lich|ig|isch|dnet)em$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word =~ /(haft|lich|ig|isch|dnet)er$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word =~ /angst$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~ /reich$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word eq lc $word && $word =~ /reit$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word eq lc $word && $word =~ /iert$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )    #always

              if $word eq lc $word && $word =~ /ierte$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word eq lc $word && $word =~ /ierter$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word eq lc $word && $word =~ /iertes$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word eq lc $word && $word =~ /ierten$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word eq lc $word && $word =~ /iertem$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word eq lc $word && $word =~ /ene[nmsr]?$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word eq lc $word && $word =~ /on$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /on$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /iv$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /iv(e|en|er|es|em|en)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /ig(e|es|en|em|er|)?$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /^meist/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /h(e|es|en|em|er)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /ht(e|es|en|em|er)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /er(e|en|er|es|em|en)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~ /lich$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~ /te(t|te|ter|te|ten|tem|tes)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /ens$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /st(e|en|er|es|em|en)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~ /lich(e|es|en|em)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /.det(e|es|en|em)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /.haft$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~
/^(ge|$regex_str_verb_prefixes).*?nn(($)|((e|en|er|es|em|en)$))/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~
/^(ge|$regex_str_verb_prefixes).*?[lb]o[gt](($)|((e|en|er|es|em|en)$))/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~
/^(ge|$regex_str_verb_prefixes).*?b(($)|((e|en|er|es|em|en)$))/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~
/^(ge|$regex_str_verb_prefixes).*?s(($)|((e|en|er|es|em|en)$))/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~
/^(ge|$regex_str_verb_prefixes).*?mm(($)|((e|en|er|es|em|en)$))/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /^be.*?t$/ && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /^ver.*?t$/ && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq lc $word
                  && $word =~ /ier(t|en|st|e)$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /^ge.*?t$/ && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /^be.*?t$/ && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /^ver.*?t$/ && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~
/^(un|in|an|a|im|$regex_str_verb_prefixes)?ge.*?[tn]et(($)|((e|en|er|es|em|en)$))/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~
/^(un|in|an|a|im|$regex_str_verb_prefixes)?be.*?[tn]et(($)|((e|en|er|es|em|en)$))/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~
/^(un|in|an|a|im|$regex_str_verb_prefixes)?ge.*?(es|er|em|en|e)$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )
              if $word =~
                  /^(un|in|an|a|im|$regex_str_verb_prefixes)?ge.*?[fsrmnlp]t$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~
                  /^(un|in|an|a|im|$regex_str_verb_prefixes)?ge.*?[tn]et$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word =~
                  /^(un|in|an|a|im|$regex_str_verb_prefixes)?be.*?[tn]et$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|bau|iess|eig|esch|isch|ruh|err|mm|mpf|ink|ohl)en$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )    #always

              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|bau|ies|eig|esch|isch|ruh|err|mm|mpf|ink|ohl)st$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )    #always
              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|bau|iess|eig|esch|isch|ruh|err|mm|mpf|ink|ohl)e$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )    #always
              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|ruh|isch|err|mm|mpf|ieh|sch|ink|ohl)t$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )    #always

              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|ruh)et$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|ruh)test$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|ruh)est$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|ruh)tst$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq lc $word
                  && $word =~
/.(ier|eid|ied|und|uch|ueh|eh|erb|arb|ng|eb|eis|s|ieg|ruh)te$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /...eck(t|en|e|st)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq lc $word && $word =~ /.ern$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word =~ /.[hk]eit$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq $word_low
                  && $word =~ /^.*?[nskz]en$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word eq $word_low
                  && $word =~ /^.*?eln$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /^(ver|be|ge|ent|er).+?et$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB} )
              if $word =~ /^(zer|ver|be|ge|ent|er).+?et$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word =~ /[ts]ion$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word ne lc $word && $word =~ /...([gftlhsbkdm]|ier)er$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word ne lc $word && $word =~ /...([gftlhsbkdm]|ier)erin$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word ne lc $word && $word =~ /...([gftlhsbkdm]|ier)erinnen$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word =~ /.([sk])um$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word ne lc $word && $word =~ /...([gftlhsbkdm]|ier)ero$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word ne lc $word && $word =~ /...([gftlhsbkdm]|ier)t$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} )
              if $word ne lc $word && $word =~ /...([gftlhsbkdm]|ier)ist/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /st(e|en|er|es|em|en)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )    #always

              if $word =~ /en(e|es|en|em|er)$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
              if $word eq lc $word && $word =~ /cht$/;
            return short_save_in_memory( $do_save, $word, $data->{const}{ADJ}, 1 )    # always
              if $word =~
                  /^(ge|$regex_str_verb_prefixes).*?(((e|en|er|es|em|en|t)$))/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )    # always
              if $word =~ /tzt$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )    # always

              if $word =~ /pft$/
                  && LANGUAGE() eq 'de';
            return short_save_in_memory( $do_save, $word, $data->{const}{VERB}, 1 )    # always
              if $word =~ /ckt$/
                  && LANGUAGE() eq 'de';
        }
    }

    if ( $word ne $word_low && $config{'features'}{'tagger'} ) {
        return short_save_in_memory( $do_save, $word, $data->{const}{NOUN} );
    }

    if ( defined $builtin_table->{$word_low} ) {
        return $builtin_table->{$word_low};
    }

    my $word_low_without_prefix = $word_low;
    foreach my $prefix ( keys %is_verb_prefix ) {
        $word_low_without_prefix =~ s/^$prefix//im;
    }

    if ( !$no_autoguess && $config{'features'}{'tagger'} ) {
        if ( $word_low =~ /end$/ && length($word) >= 6 ) {
            my $word_to_check = $word_low;
            $word_to_check =~ s/[a-z]$//;    # no 'g', only once!

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 0, 0, undef,
                    undef, 0 ) == $data->{const}{VERB}
              )
            {
                return $data->{const}{ADJ};
            }
        }

        if ( $word eq $word_low && $word_low =~ /e$/ && length($word) >= 4 ) {
            my $word_to_check = $word_low . 'n';

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 0, 1, undef,
                    undef, 0, 1 )
                || 0 == $data->{const}{VERB}
              )
            {
                return $data->{const}{VERB};
            }
        }
        if ( $word eq $word_low && $word_low =~ /s$/ && length($word) >= 4 ) {
            my $word_to_check = $word_low;
            $word_to_check =~ s/[a-z]$//;    # no 'g', only once!

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 1, 1, undef,
                    undef, 0, 1 )
                || 0 == $data->{const}{VERB}
              )
            {
                return $data->{const}{VERB};
            }
        }

        if ( $word_low =~ /s$/ && length($word) >= 4 ) {
            my $word_to_check = $word;
            $word_to_check =~ s/[a-z]$//;    # no 'g', only once!

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 0, 1, undef,
                    undef, 0, 1 )
                || 0 == $data->{const}{NOUN}
              )
            {
                return $data->{const}{NOUN};
            }
        }

        if ( $word_low =~ /e[sr]$/ && length($word) >= 4 ) {
            my $word_to_check = $word;
            $word_to_check =~ s/[a-z][a-z]$//;    # no 'g', only once!

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 0, 1, undef,
                    undef, 0, 1 )
                || 0 == $data->{const}{NOUN}
              )
            {
                return $data->{const}{NOUN};
            }
        }

        if ( $word eq $word_low && $word_low =~ /st$/ && length($word) >= 5 ) {
            my $word_to_check = $word_low;
            $word_to_check =~ s/st$/en/;    # no 'g', only once!

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 0, 1, undef,
                    undef, 0, 1 ) == $data->{const}{VERB}
              )
            {
                return $data->{const}{VERB};
            }
        }
        if ( $word eq $word_low && $word_low =~ /et$/ && length($word) >= 5 ) {
            my $word_to_check = $word_low;
            $word_to_check =~ s/et$/en/;    # no 'g', only once!

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 0, 1, undef,
                    undef, 0, 1 ) == $data->{const}{VERB}
              )
            {
                return $data->{const}{VERB};
            }
        }
        if ( $word eq $word_low && $word_low =~ /t$/ && length($word) >= 5 ) {
            my $word_to_check = $word_low;
            $word_to_check =~ s/t$/en/;     # no 'g', only once!

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 0, 1, undef,
                    undef, 0, 1 ) == $data->{const}{VERB}
              )
            {
                return $data->{const}{VERB};
            }
        }

        if (   $word_low =~ /(ed|ing)$/
            && length($word) >= 6
            && LANGUAGE() eq 'en' )
        {
            my $word_to_check = $word_low;
            $word_to_check =~ s/(ed|ing)$//;    # no 'g', only once!

            if (
                pos_of( $CLIENT_ref, $word_to_check, 0, 0, 0, undef,
                    undef, 0, 1 ) == $data->{const}{VERB}
              )
            {
                return $data->{const}{ADJ};
            }
            if (
                pos_of( $CLIENT_ref, $word_to_check . 'e',
                    0, 0, 1, undef, undef, 0, 1 ) == $data->{const}{VERB}
              )
            {
                return $data->{const}{ADJ};
            }
        }

        return short_save_in_memory( $do_save, $word, $data->{const}{ADJ} )
          if $word =~ /en(d|de|den|des|dem|der)$/;
    }

    if ($at_beginning_of_sentence) {

        if ( !$AI::SemanticNetwork::initialized ) {
            $cache_noun_or_not{$word_low} = $data->{const}{NOUN};
        }

        my $in_cache = $cache_noun_or_not{$word_low};
        if ( !$in_cache ) {
            $in_cache = $WORDTYPE_UNKNOWN;
        }
        return $in_cache                  if $in_cache == $data->{const}{NOUN};
        return $in_cache                  if $in_cache == $data->{const}{VERB};
        return $in_cache                  if $in_cache == $data->{const}{ADJ};
        print "Error in Cache: $in_cache" if $in_cache != $WORDTYPE_UNKNOWN;

        #if ( $in_cache != $WORDTYPE_UNKNOWN ) {
        my $wt1 = $WORDTYPE_UNKNOWN;
        my $wt2 = $WORDTYPE_UNKNOWN;
        if ( $word ne lc $word ) {
            $wt1 =
              pos_of( $CLIENT_ref, lc $word, 0, 0, undef, $sentence );
            $wt2 = pos_of( $CLIENT_ref, ucfirst $word, 0, 0, undef,
                $sentence );
            if ( $wt1 == $data->{const}{QUESTIONWORD} || $wt2 == $data->{const}{QUESTIONWORD} ) {
                return $data->{const}{QUESTIONWORD};
            }
        }
        if ( $wt1 != $wt2 && $word ne lc $word ) {
            if ( $wt1 == $data->{const}{VERB} || $wt2 == $data->{const}{VERB} ) {
                return $data->{const}{VERB};
            }
            if (   LANGUAGE() eq 'en'
                && ( $wt1 == $data->{const}{NOUN} || $wt2 == $data->{const}{NOUN} )
                && ( $wt1 == $data->{const}{ADJ}  || $wt2 == $data->{const}{ADJ} ) )
            {
                return $data->{const}{NOUN};
            }
            if (   LANGUAGE() eq 'en'
                && ( $wt1 == $data->{const}{NOUN} || $wt2 == $data->{const}{NOUN} )
                && ( $wt1 == $data->{const}{PREP} || $wt2 == $data->{const}{PREP} ) )
            {
                return $data->{const}{PREP};
            }
            if (   LANGUAGE() eq 'en'
                && ( $wt1 == $data->{const}{NOUN} || $wt2 == $data->{const}{NOUN} )
                && ( $wt1 == $ART  || $wt2 == $ART ) )
            {
                return $ART;
            }
            my $line =
              !$AI::SemanticNetwork::initialized
              ? 1
              : impl_get_noun_or_not( $CLIENT_ref, $word );

            if ( $line == 1 ) {
                $cache_noun_or_not{$word_low} = $data->{const}{NOUN};
            }
            elsif ( $line == 2 ) {
                $cache_noun_or_not{$word_low} = $wt1;
            }
            else {
                print "Illegal Command: HERE_IS_NOUN_OR_NOT:" . $line . "\n";
            }

            #			last;

        }
        elsif ( $wt1 != $wt2 && $word eq lc $word ) {
            return $wt1;
        }

        #}

    }

    my $word_without_underscores = $word;
    $word_without_underscores =~ s/_/ /igm;

    my $type = q{};    # empty
    if ($at_beginning_of_sentence) {
        my $prop_ref =
          part_of_speech_get_memory()->{ lc $word_without_underscores };
        if ( $prop_ref->{'type'} ) {
            $type = $prop_ref->{'type'};
        }
    }
    my $prop_ref = part_of_speech_get_memory()->{$word_without_underscores};
    if ( $prop_ref->{'type'} && !$type ) {
        $type = $prop_ref->{'type'};
    }
    if ( !$type && $at_beginning_of_sentence ) {
        my $prop_ref = part_of_speech_get_entry( lc $word_without_underscores );
        if ( $prop_ref->{'type'} ) {
            $type = $prop_ref->{'type'};
        }
    }
    if ( !$type ) {
        $prop_ref = part_of_speech_get_entry($word_without_underscores);
        if ( $prop_ref->{'type'} ) {
            $type = $prop_ref->{'type'};
        }
    }

    if ($at_beginning_of_sentence) {
        my $prop_ref = part_of_speech_get_memory()
          ->{ '_nosave_' . lc $word_without_underscores };
        if ( $prop_ref->{'type'} ) {
            $type = $prop_ref->{'type'};
        }
    }
    my $prop_ref =
      part_of_speech_get_memory()->{ '_nosave_' . $word_without_underscores };
    if ( $prop_ref->{'type'} && !$type ) {
        $type = $prop_ref->{'type'};
    }
    if ( !$type && $at_beginning_of_sentence ) {
        my $prop_ref =
          part_of_speech_get_entry( '_nosave_' . lc $word_without_underscores );
        if ( $prop_ref->{'type'} ) {
            $type = $prop_ref->{'type'};
        }
    }
    if ( !$type ) {
        $prop_ref =
          part_of_speech_get_entry( '_nosave_' . $word_without_underscores );
        if ( $prop_ref->{'type'} ) {
            $type = $prop_ref->{'type'};
        }
    }

    if ($use_sql) {
        if ( ( !$type || $type eq 'q' ) && $at_beginning_of_sentence ) {
            $type =
              ( sql_get_part_of_speech_property lc $word_without_underscores )
              ->{type};
        }
        if ( ( !$type || $type eq 'q' ) ) {
            $type =
              ( sql_get_part_of_speech_property $word_without_underscores )
              ->{type};
        }
    }

    if ( $type eq 'q' ) {
        $type = q{};    # empty
    }

#    if ( $at_beginning_of_sentence && !$type ) {
#        $type = word_types_read_only_one_thing( lc $word_without_underscores, 'type' );
#    }
#    if ( !$type ) {
#        $type = word_types_read_only_one_thing( $word_without_underscores,    'type' );
#    }

    if (
           ( $word || '' ) ne ( $word_low || '' )
        && !$at_beginning_of_sentence
        && $noun_automatism
        && (
            ( $data->{lang}{string_to_constant}{ $type || '' } || '' ) ne $data->{const}{NOUN}
            && ( $data->{lang}{string_to_constant}{ $data->{lang}{constant_to_string}{ $type || '' } || '' }
                || '' ) ne $data->{const}{NOUN}
        )
      )
    {
    }
    else {

        if ( $data->{lang}{string_to_constant}{$type} ) {

            return $data->{lang}{string_to_constant}{$type};
        }

        if ( $data->{lang}{string_to_constant}{ $data->{lang}{constant_to_string}{$type} || '' } ) {

            return $data->{lang}{string_to_constant}{ $data->{lang}{constant_to_string}{$type} };
        }
    }

    #print "failure: " . $word . '[' . $type . "] not known\n" if is_verbose;

    if ($do_not_ask_user) {    #&& $downloaded == $data->{const}{NO_POS} ) {
        return $data->{const}{NO_POS};
    }

    my $downloaded =
        LANGUAGE() eq 'de' && $config{'features'}{'tagger'}
      ? download_pos( $CLIENT_ref, $word, $at_beginning_of_sentence )
      : $data->{const}{NO_POS};

    say "$do_not_guess || $config{'features'}{'tagger'}";
    

    my $word_type_tagged =
      $do_not_guess || !$config{'features'}{'tagger'}
      ? ''
      : uc find_word_type( $CLIENT_ref, $word, $at_beginning_of_sentence,
        $sentence );

    if (   $word_low_without_prefix ne $word_low
        && $word eq $word_low
        && $config{'features'}{'tagger'} )
    {
        if (
            pos_of( $CLIENT_ref, $word_low_without_prefix, 0, 0, 0, undef,
                0 ) == $data->{const}{VERB}
          )
        {
            $downloaded = $data->{const}{VERB};
        }

        # $do_not_guess = 1;
    }

    if (  !$at_beginning_of_sentence
        && $word_low ne $word
        && $noun_automatism
        && $downloaded == $data->{const}{NO_POS}
        && ( !$word_type_tagged || LANGUAGE() eq 'de' )
        && $config{'features'}{'tagger'} )
    {
        $downloaded = $data->{const}{NOUN};
    }

    $downloaded ||= 0;

    $downloaded =
        $downloaded == $data->{const}{NOUN}         ? 2
      : $downloaded == $data->{const}{VERB}         ? 1
      : $downloaded == $data->{const}{PREP}         ? 6
      : $downloaded == $data->{const}{ADJ}          ? 3
      : $downloaded == $data->{const}{INTER}        ? 7
      : $downloaded == $data->{const}{QUESTIONWORD} ? 5
      :                                0;

    my $word_type_tagged_new =
        $word_type_tagged eq 'CD'   ? 3
      : $word_type_tagged eq 'EX'   ? 3
      : $word_type_tagged eq 'IN'   ? 6
      : $word_type_tagged eq 'JJ'   ? 3
      : $word_type_tagged eq 'JJR'  ? 3
      : $word_type_tagged eq 'JJS'  ? 3
      : $word_type_tagged eq 'MD'   ? 1
      : $word_type_tagged eq 'NN'   ? 2
      : $word_type_tagged eq 'NNS'  ? 2
      : $word_type_tagged eq 'NNPS' ? 2
      : $word_type_tagged eq 'NNP'  ? 2
      : $word_type_tagged eq 'PDT'  ? 3
      : $word_type_tagged eq 'PRP'  ? 2
      : $word_type_tagged eq 'PRPS' ? 3
      : $word_type_tagged eq 'RB'   ? 3
      : $word_type_tagged eq 'RBR'  ? 3
      : $word_type_tagged eq 'RBS'  ? 3
      : $word_type_tagged eq 'RP'   ? 3
      : $word_type_tagged eq 'TO'   ? 6
      : $word_type_tagged eq 'UH'   ? 7
      : $word_type_tagged eq 'SYM'  ? 2
      : $word_type_tagged =~ /^VB/ ? 1
      : $word_type_tagged =~ /^W/  ? 5
      :                              0;

    if ( !$word_type_tagged_new ) {
        say 'Tagged Word type not known: ', $word_type_tagged;
    }
    else {
        say 'Word type tagged successful: ', $word_type_tagged, ' = ',
          $word_type_tagged_new;
    }
    $word_type_tagged = $word_type_tagged_new;

    if ( $do_not_ask_user && !$downloaded && !$word_type_tagged ) {
        return $data->{const}{NO_POS};
    }
    my $line =
        ($downloaded)       ? ($downloaded)
      : ($word_type_tagged) ? ($word_type_tagged)
      :                       ( impl_get_word_type( $CLIENT_ref, $word ) );

    print '$line: ', $line, "\n";

    my $type_str =
        $line == 1 ? 'vt'
      : $line == 2 ? 'n,'
      : $line == 3 ? 'adj'
      : $line == 4 ? 'n,'
      : $line == 5 ? 'fw'
      : $line == 6 ? 'prep'
      : $line == 7 ? 'inter'
      :              'nothing';

    if ( $word ne $word_low ) {
        $type_str = 'n,';
    }

    ##if ( !$in_cgi_mode ) {
#my $from_yaml =
#$yaml->read( $dir . 'lang_' . LANGUAGE() . '/word_types.base' );
#foreach my $key ( %{$from_yaml->[0]} ) {
#foreach my $key_2 ( %{$from_yaml->[0]->{$key}} ) {
#part_of_speech_get_memory()->{$key}->{$key_2} = $from_yaml->[0]->{$key}->{$key_2}
#if !part_of_speech_get_memory()->{$key}->{$key_2};
#}
#}
    ##}

    if ( !$do_save ) {
        part_of_speech_get_memory()->{ '_nosave_' . $word_without_underscores }
          ->{'type'} = $type_str;
    }
    elsif ($use_sql) {
        eval q{
        use DBI;

        my $db_string = "DBI:mysql:database=" . $config{'mysql'}{'database'};
        if ( $config{'mysql'}{'host'} ) {
            $db_string .= ';host=' . $config{'mysql'}{'host'};
        }
        my $user      = $config{'mysql'}{'user'};
        my $password  = $config{'mysql'}{'password'};
        my $dbh       = DBI->connect( $db_string, $user, $password )
          or say(
            "not connected to ",
            $config{'mysql'}{'database'},
            ", user ",
            $config{'mysql'}{'user'},
            ", password ",
            $config{'mysql'}{'user'},
            ": "
          );

        my $sql =
qq{SELECT word FROM part_of_speech WHERE word = '$word_without_underscores'};
        my $sth = $dbh->prepare($sql);
        $sth->execute();
        say( $sth->errstr );
        say( $dbh->errstr );

        if ( !( $sth && ( my $data = $sth->fetchrow_arrayref ) ) ) {
            $dbh->do(
qq{INSERT INTO part_of_speech( word, type, genus ) VALUES ( '$word_without_underscores', '', '' )}
            );
            say( $sth->errstr );
            say( $dbh->errstr );
        }

        $sql =
qq{UPDATE part_of_speech SET type = '$type_str' WHERE word = '$word_without_underscores'};
        my $sth = $dbh->prepare($sql);
        $sth->execute();
        say( $sth->errstr );
        say( $dbh->errstr );
        } if !$::batch;

        #        $sth->finish();
        #        $dbh->disconnect();
        #part_of_speech_get_memory()->{$word} ||= {};
    }
    else {
        part_of_speech_get_memory()->{$word_without_underscores}->{'type'} =
          $type_str;
        part_of_speech_get_memory()->{$word_without_underscores}->{'new'} = 1;
    }

    #}
    #else {
    #    write_to( $dir . 'lang_' . LANGUAGE() . '/word_types.temp',
    #        part_of_speech_get_memory() );
    #}

    #	open HANDLE, '>>', $dir . 'lang_' . LANGUAGE() . '/word_types.dic'
    #	  or die 'Cannot write to: ' . $dir . 'lang_'
    #	  . LANGUAGE()
    #	  . '/word_types.dic';
    #	print HANDLE $word . '|' . $type_str . "\n";
    #	close HANDLE;

    return pos_of( $CLIENT_ref, $word, $at_beginning_of_sentence,
        $noun_automatism, $sentence, $do_not_guess, $do_save );

    return $data->{const}{NO_POS};
}

sub find_word_type {
    my ( $CLIENT_ref, $word, $at_beginning_of_sentence, $sentence ) = @_;

    $word     =~ s/^[_]//igm;
    $word     =~ s/[_]$//igm;
    $sentence =~ s/^[_]//igm;
    $sentence =~ s/[_]$//igm;
    $sentence =~ s/\s[_]/ /igm;
    $sentence =~ s/[_]\s/ /igm;

    return 'JJ'
      if $word =~ /^ge.*?tet(($)|((e|en|er|es|em|en)$))/ && LANGUAGE() eq 'de';
    return 'JJ'
      if $word =~ /^be.*?tet(($)|((e|en|er|es|em|en)$))/ && LANGUAGE() eq 'de';
    return 'VB'
      if $word =~ /^ge.*?t(($)|((e|en|er|es|em|en)$))/ && LANGUAGE() eq 'de';
    return 'VB'
      if $word =~ /^be.*?t(($)|((e|en|er|es|em|en)$))/ && LANGUAGE() eq 'de';
    return 'VB'
      if $word =~ /^ver.*?t(($)|((e|en|er|es|em|en)$))/ && LANGUAGE() eq 'de';
    return 'JJ' if $word =~ /^ge.*?(es|er|em|en|e)$/ && LANGUAGE() eq 'de';
    return 'VB' if $word eq lc $word && $word =~ /.[gftlrs]en$/;

    my $builtin_table = AI::FreeHAL::Engine::build_builtin_table();

    foreach my $key ( keys %$builtin_table ) {
        part_of_speech_get_memory()->{$key}{'type'} =
          $data->{lang}{constant_to_string}{ $builtin_table->{$key} };
        part_of_speech_get_memory()->{$key}{rtime} = 'not_new';
        part_of_speech_get_memory()->{ ucfirst $key }{'type'} =
          $data->{lang}{constant_to_string}{ $builtin_table->{$key} };
        part_of_speech_get_memory()->{ ucfirst $key }{rtime} = 'not_new';
    }

    if ( !$use_sql ) {
        open my $old_format_file, '>', $dir . 'lang_de/word_types.taggerinput';
        foreach my $key ( sort keys %{ part_of_speech_get_memory() } ) {
            print $old_format_file $key . '|'
              . part_of_speech_get_memory()->{$key}->{'type'} . "\n"
              if part_of_speech_get_memory()->{$key}->{'type'}
                  && part_of_speech_get_memory()->{$key}->{'type'} !~ /^n/
                  && $key eq lc $key;
        }
        close $old_format_file;
    }
    else {
        eval q{
        use DBI;

        my $db_string = "DBI:mysql:database=" . $config{'mysql'}{'database'};
        if ( $config{'mysql'}{'host'} ) {
            $db_string .= ';host=' . $config{'mysql'}{'host'};
        }
        my $user      = $config{'mysql'}{'user'};
        my $password  = $config{'mysql'}{'password'};
        my $dbh       = DBI->connect( $db_string, $user, $password )
          or say(
            "not connected to ",
            $config{'mysql'}{'database'},
            ", user ",
            $config{'mysql'}{'user'},
            ", password ",
            $config{'mysql'}{'user'},
            ": "
          );

        my $sql =
qq{create table part_of_speech (word varbinary(120), type char(3), genus char(1))};
        $dbh->prepare($sql)->execute();
        $sql = qq{ALTER TABLE `part_of_speech` ADD PRIMARY KEY ( `word` )};
        $dbh->prepare($sql)->execute();

        $sql = qq{SELECT word, type FROM part_of_speech};
        my $sth = $dbh->prepare($sql);
        $sth->execute();

        open my $old_format_file, '>', $dir . 'lang_de/word_types.taggerinput';
        while ( $sth && ( my $data = $sth->fetchrow_arrayref ) ) {
            print $old_format_file $data->[0] . '|' . $data->[1] . "\n"
              if $data->[1]
                  && $data->[1] !~ /^n/
                  && $data->[0] eq lc $data->[0];
        }
        close $old_format_file;

        $sth->finish();
        } if !$::batch;
    }

    require 'convert-word-types-dic.pl' if LANGUAGE() eq 'de' && !$::batch;
    say $sentence;

    #	exit 0;

    my $p =
      LANGUAGE() eq 'en'
      ? new Lingua::EN::Tagger
      : new Lingua::DE::Tagger;
    my $readable_text = $p->get_readable($sentence);
    $readable_text =~ s/[<]\/(.+?)[>]/\/$1 /igm;
    $readable_text =~ s/[<].+?[>]//igm;
    $readable_text =~ s/[\-]//igm;
    my %word_list = map { lc $_ } map { split /\//, $_ } split /\s/,
      $readable_text;
    foreach my $k ( keys %word_list ) {
        $k = lc $k;
    }
    print Dumper \%word_list;

    my $tagged =
         $word_list{ lc $word }
      || $word_list{$word}
      || $word_list{ ucfirst $word };
    if ( lc $tagged eq 'nn' && $word =~ /(es|er|en|em)$/ ) {
        $tagged = 'JJ';
    }

    return $tagged;
}

1;