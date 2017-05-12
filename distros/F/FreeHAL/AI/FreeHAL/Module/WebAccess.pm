#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

package AI::FreeHAL::Module::WebAccess;

use AI::FreeHAL::Config;

our $data = {};
our %config;

use AI::Util;
use AI::POS;

use Data::Dumper;

our @functions = qw{
    download_pos
    download_synonyms
    download_genus
};

use LWP::UserAgent;
use HTTP::Request;
use LWP::Protocol;
use LWP::Protocol::http;
our $ua = LWP::UserAgent->new( timeout => 5 );
$ua->agent(
"Mozilla/5.0 (X11; U; Linux i686; de; rv:1.8.1.10) Gecko/20071213 Firefox/2.0.0.12"
);


sub download_pos {
    my ( $CLIENT_ref, $word, $at_beginning ) = @_;

    local $| = 1;

    say;
    say "download_pos: ( $CLIENT_ref, $word, $at_beginning )";

    return if $config{'modes'}{'offline_mode'};

    return if LANGUAGE() eq 'en';

    return if $data->{modes}{batch};

    return if !$AI::SemanticNetwork::initialized;

    print '.';

    my $url =
      'http://wortschatz.uni-leipzig.de/cgi-portal/de/wort_www?site=10&Wort='
      . $word;

    # Create a request
    # my $req = HTTP::Request->new( GET => $url );

    # Pass request to the user agent and get a response back
    # my $res = $ua->request($req);
    $ua->timeout(5);
    my $res = $ua->get($url);

    # Check the outcome of the response
    if ( !$res->is_success ) {

        #       print $res->content;
        say 'Error while Downloading:';
        say $url;
        say $res->status_line;
        return;
    }

    open my $d, ">", "downloaded.html";
    print $d $res->content;
    close $d;

    my @lines = split /\n/, $res->content;

    my @not_correct_but_conjugated_last;
    my @not_correct_but_conjugated;

    my $found_right_spelling = 0;

    while ( defined( my $line = shift @lines ) ) {
        print ".";

        #		say $line;

        if ( $line =~ /Wort:/i && $line !~ /searchform/i ) {
            chomp $line;
            $line =~ s/.*?[<]\/B[>]//igm;
            if ( ( $word eq lc $word ) == ( $line eq lc $line ) ) {
                $found_right_spelling = 1;
                print "($word eq lc $word) == ($line eq lc $line) \n";

                #				exit 0;
                #				select undef, undef, undef, 10;
            }
            else {
                print "($word eq lc $word) != ($line eq lc $line) \n";
                $found_right_spelling = 0;

                #				select undef, undef, undef, 10;
            }
        }

        if ( $line =~ /licherweise haben Sie eine Seite zu schn/i ) {
            select undef, undef, undef, 5;
            return download_pos( $CLIENT_ref, $word, $at_beginning );
        }
        if ( $line =~ /Wortart: /i ) {
            say 'wrong part, posible part of speech:';
            say $line;
        }

        next if !$found_right_spelling;

        if ( $line =~ /Stammform:/i && !@not_correct_but_conjugated ) {
            $line =~ s/Stammform: //igm;

            $line =~ s/[<].*?[>]//igm;
            $line =~ s/^\s+//igm;
            $line =~ s/\s+$//igm;

            print $line . "\n";

            if ( ( $word eq lc $word ) == ( $line eq lc $line ) ) {
                my $wt = download_pos( $CLIENT_ref, $line, $at_beginning );
                if ( $wt && $wt != $data->{const}{NO_POS} ) {
                    return $wt;
                }
            }
        }

        if ( $line =~ /falsche Rechtschreibung von/i ) {
            shift @lines;
            my $right_word = shift @lines;
            $right_word =~ s/[<](.*)//igm;

            my $ae = chr 228;
            my $Ae = chr 196;
            my $ue = chr 252;
            my $Ue = chr 220;
            my $oe = chr 246;
            my $Oe = chr 214;
            my $ss = chr 223;

            $right_word =~ s/[&]auml[;]/$ae/igm;
            $right_word =~ s/[&]Auml[;]/$Ae/igm;
            $right_word =~ s/[&]ouml[;]/$oe/igm;
            $right_word =~ s/[&]Ouml[;]/$Oe/igm;
            $right_word =~ s/[&]uuml[;]/$ue/igm;
            $right_word =~ s/[&]Uuml[;]/$Ue/igm;
            $right_word =~ s/[&]szlig[;]/$ss/igm;

            return download_pos( $CLIENT_ref, $right_word, $at_beginning );
        }

        if ( $line !~ /Wortart: /i ) {
            next;
        }

        $line =~ s/[<](.+?)[>]//igm;
        $line = ascii($line);
        say "Line: ", $line;
        $line =~ s/Wortart: //igm;
        $line =~ s/^\s+//igm;
        $line =~ s/\s+$//igm;
        say "Line: ", $line;

        push @not_correct_but_conjugated, $line;
    }

    foreach my $line (@not_correct_but_conjugated) {
        next if $line !~ /adverb/i;
        my $wt = detect_pos_from_string( $CLIENT_ref, $line, $at_beginning );
        if ( $wt != $data->{const}{NO_POS} ) {
            say "- Downloaded word type (5): ", $wt;
            return $wt;
        }
    }
    foreach my $line (@not_correct_but_conjugated) {
        my $wt = detect_pos_from_string( $CLIENT_ref, $line, $at_beginning );
        if ( $wt != $data->{const}{NO_POS} && $wt == $data->{const}{PREP} ) {
            say "- Downloaded word type (4): ", $wt;
            return $wt;
        }
    }
    foreach my $line (@not_correct_but_conjugated) {
        my $wt = detect_pos_from_string( $CLIENT_ref, $line, $at_beginning );
        if ( $wt != $data->{const}{NO_POS} && $wt == $data->{const}{ADJ} ) {
            say "- Downloaded word type (2): ", $wt;
            return $wt;
        }
    }
    foreach my $line (@not_correct_but_conjugated) {
        my $wt = detect_pos_from_string( $CLIENT_ref, $line, $at_beginning );
        if ( $wt != $data->{const}{NO_POS} && $wt == $data->{const}{VERB} ) {
            say "- Downloaded word type (2): ", $wt;
            return $wt;
        }
    }
    foreach my $line (@not_correct_but_conjugated) {
        my $wt = detect_pos_from_string( $CLIENT_ref, $line, $at_beginning );
        if ( $wt != $data->{const}{NO_POS} ) {
            say "- Downloaded word type (3): ", $wt;
            return $wt;
        }
    }
    foreach my $line (@not_correct_but_conjugated_last) {
        my $wt = detect_pos_from_string( $CLIENT_ref, $line, $at_beginning );
        if ( $wt != $data->{const}{NO_POS} ) {
            say "- Downloaded word type (last): ", $wt;
            return $wt;
        }
    }
    say;

    return $data->{const}{NO_POS};

}

sub download_synonyms {
    my ( $word, $count, $real_word ) = @_;
    $real_word ||= $word;
    $count ||= 0;

    read_config $data->{intern}{config_file} => my %config;

    return if !$word;

    chomp $word;
    chomp $real_word;

    return () if $count >= 5;
    return () if $word =~ /^[_]/;

    return if $data->{modes}{batch};

    return if LANGUAGE() eq 'en';

    return map { $_ => 1 }
      split /[,]\s/, $data{'synonyms'}{ lc $word }
      if $data{'synonyms'}{ lc $word };
    chomp $data{'synonyms'}{ lc $word } if $data{'synonyms'}{ lc $word };
    return ()
      if $data{'synonyms'}{ lc $word }
          && $data{'synonyms'}{ lc $word } =~ /^[.]/;

    return () if !$config{'modes'}{'offline_mode'};

    #	$word = ascii( $word );

    say '-> Downloading synonyms: ', $word;

    my $url = 'http://wortschatz.uni-leipzig.de/abfrage/';

    # Create a request
    my $req = HTTP::Request->new( POST => $url );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content( 'Wort=' . $word . '&Submit=Suche!&site=10' );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ( !$res->is_success ) {

        #       print $res->content;
        say 'Error while Downloading:';
        say $url;
        say $res->status_line;
    }

    my @lines = split /\n/, $res->content;

    my %synonyms;

    while ( defined( my $line = shift @lines ) ) {
        chomp $line;

        $line =~ s/[<].*?[>]//igm;

        if ( $line =~ /Stammform:/i ) {
            $line =~ s/Stammform: //igm;
            chomp $line;
            $line = ascii( lc $line );
            say '-> base form of ' . $word . ': ' . $line;
            $line =~ s/(^\s+)|(\s+$)//igm;
            $synonyms{$line} = 1;
        }

        if ( $line =~ /Flexion:/i ) {
            my $flex = lc shift @lines;
            $flex .= lc shift @lines;
            $flex =~ s/Stammform: //igm;
            $flex = ascii($flex);
            chomp $flex;
            my @flexion = split /[,]|([<]br[>])/, $flex;
            foreach my $fl (@flexion) {
                $fl =~ s/(^\s+)|(\s+$)//igm;
                chomp $fl;
                say '-> flexion ' . $word . ': ' . $fl;
                $synonyms{$fl} = 1;
            }
        }

        if ( $line =~ /(falsche Rechtschreibung von)|(Form\(en)/i ) {
            shift @lines;
            my $right_word = shift @lines;
            $right_word =~ s/[<].*?[>]//igm;
            $right_word =~ s/[<](.*?)//igm;
            $right_word =~ s/[,.-;]//igm;

            my $ae = chr 228;
            my $Ae = chr 196;
            my $ue = chr 252;
            my $Ue = chr 220;
            my $oe = chr 246;
            my $Oe = chr 214;
            my $ss = chr 223;

            $right_word =~ s/[&]auml/$ae/igm;
            $right_word =~ s/[&]Auml/$Ae/igm;
            $right_word =~ s/[&]ouml/$oe/igm;
            $right_word =~ s/[&]Ouml/$Oe/igm;
            $right_word =~ s/[&]uuml/$ue/igm;
            $right_word =~ s/[&]Uuml/$Ue/igm;
            $right_word =~ s/[&]szlig/$ss/igm;

            if ( lc $right_word eq lc $word && lc $real_word ) {
                $data{'synonyms'}{ lc $real_word } = '.'
                  if !$data{'synonyms'}{ lc $real_word };

                foreach my $item ( values %{ $data{'synonyms'} } ) {
                    $item = '.' if !$item;
                }

                delete $config{''};
                delete $data{'synonyms'}{''};
                foreach my $value ( values %{ $data{'synonyms'} } ) {
                    $value = '' if !$value;
                }
                #write_config %config, $data->{intern}{config_file};
                return ();
            }

            return download_synonyms( $right_word, $count + 1, $real_word );
        }
    }

    #	say join ', ', keys %synonyms;

    say;

    foreach my $item ( values %{ $data{'synonyms'} } ) {
        $item = '.' if !$item;
    }

    $data{'synonyms'}{ lc $real_word } = join ', ', keys %synonyms;
    $data{'synonyms'}{ lc $real_word } =~ s/(^\s+)|(\s+$)//igm;
    $data{'synonyms'}{ lc $real_word } = '.'
      if !$data{'synonyms'}{ lc $real_word };
    delete $config{''};
    delete $data{'synonyms'}{''};
    foreach my $value ( values %{ $data{'synonyms'} } ) {
        $value = '' if !$value;
    }
    #write_config %config, $data->{intern}{config_file};

    return %synonyms;
}

sub download_genus {
    my ( $word, $count, $real_word ) = @_;
    $real_word ||= $word;
    $count ||= 0;

    chomp $word;
    chomp $real_word;

    return if $count >= 5;

    return if LANGUAGE() eq 'en';
    return if $data->{modes}{batch};

    return if !$AI::SemanticNetwork::initialized;

    return if $config{'modes'}{'offline_mode'};

    #	$word = ascii( $word );

    say '-> Downloading genus: ', $word;

    my $url = 'http://wortschatz.uni-leipzig.de/abfrage/';

    # Create a request
    my $req = HTTP::Request->new( POST => $url );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content( 'Wort=' . $word . '&Submit=Suche!&site=10' );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ( !$res->is_success ) {

        #       print $res->content;
        say 'Error while Downloading:';
        say $url;
        say $res->status_line;
    }

    my $ctn = $res->content;

    my @lines = split /\n/, $ctn;

    while ( defined( my $line = shift @lines ) ) {
        print ".";
        chomp $line;

        $line =~ s/[<].*?[>]//igm;
        $line = ascii($line);

        if ( $line =~ /Flexion:/i ) {
            my $flex = lc shift @lines;
            $flex = ascii($flex);
            return 'm' if $flex =~ /^der/;
            return 'm' if $flex =~ /^die/;
            return 'm' if $flex =~ /^das/;
        }

        if ( $line =~ /eschlecht/i && $line =~ /nnlich/i ) {
            say;
            return 'm';
        }

        if ( $line =~ /eschlecht/i && $line =~ /weiblich/i ) {
            say;
            return 'f';
        }

        if ( $line =~ /eschlecht/i && $line =~ /chlich/i ) {
            say;
            return 's';
        }
    }
    say;

    return;
}

