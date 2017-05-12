#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

package AI::Selector;

use strict;
use warnings;
use AI::SemanticNetwork;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 0.01;

    @ISA         = qw(Exporter);
    
    # functions
    @EXPORT      = qw(  &traditional_match
                        &modern_match ); 
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],


    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw($Var1 %Hashit &func3);
}
our @EXPORT_OK;


our %cache_is_in = ();
our $get_time_measurements_ref;


sub say;

sub new {
    my $class = shift;

    my $self = {@_};
    if ( $self->{get_time_measurements} ) {
        $get_time_measurements_ref = $self->{get_time_measurements};
    }

    bless $self, $class;
    return $self;
}

use Data::Dumper;

sub traditional_match {
    return is_in (@_);
}

sub modern_match {
    my $output = "MODERN MATCH:";
    $output .= Dumper \@_;
    
    my $self       = shift;
    my $comparison = shift;
    my $pattern    = shift;

    my $n   = 0;
    my $tot = @$pattern;

    foreach my $match (@$pattern) {
        my ($r);
        
        $output .= Dumper $match;

        if ( defined $match->{su} && defined $match->{ob} ) {
            ($r) =
              (      is_in( $self->{is_obj}, $match->{ob} )
                  && is_in( $self->{is_subj}, $match->{su} ) );
        }
        elsif ( defined $match->{su} ) {
            $r = is_in( $self->{is_subj}, $match->{su} );
        }
        elsif ( defined $match->{ob} ) {
            $r = is_in( $self->{is_obj}, $match->{ob} );
        }

        $n += 1 if $r;
        if ( $comparison eq 'or' ) {
            return $n if $n;
        }
    }
    #say $output . "\nreturn $n == $tot;" if $n == $tot;

    if ( $comparison eq 'and' ) {
        return $n == $tot if $n;
    }
    return 0;
}

sub is_in {
    my ( $hash_ref, $item, $verbose, $no_recursion ) = @_;
    $item ||= 'nothing';
    chomp $item;
    $item = 'nothing' if ( !$item );

    if ( ref $hash_ref eq 'ARRAY' ) {

        #        say Dumper $hash_ref;
        foreach my $sub_hash_ref (@$hash_ref) {
            my $res = is_in( $sub_hash_ref, $item, $verbose, $no_recursion );
            return 1 if $res;
        }
        return 0;
    }

    if ( $item =~ /[&]/ ) {
        foreach my $sub_item ( split /[&]/, $item ) {
            $sub_item =~ s/(^\s+)|(\s+$)//igm;

            return 1
              if is_in( $hash_ref, $sub_item, $verbose, $no_recursion );
        }

        return 0;
    }

    return 1
      if $item =~ /nothing/ && $hash_ref->{'_main_original'} =~ /nothing/;

    @{ $hash_ref->{'___'} } = grep { %$_ } @{ $hash_ref->{'___'} };
    $hash_ref->{'_count'} = scalar @{ $hash_ref->{'___'} };

    my %characters = map { $_ => 1 } ( 'a' .. 'h' );
    $hash_ref->{'_main_original'} ||= '';
    foreach my $character ( keys %characters ) {
        if ( $hash_ref->{'_main_original'} eq $character ) {
            return 1;
        }
    }

    my %synonyms_list_hash = map { %$_ } @{ $hash_ref->{'___'} }
      if !$hash_ref->{'words_relevant'};
    my $id = (
        join '',
        @{
            $hash_ref->{'words_relevant'} || [ join keys %synonyms_list_hash ]
          }
    ) . $item;

    if ( defined $cache_is_in{$id} && !$verbose ) {
        return $cache_is_in{$id};
    }

    $verbose ||= 0;

    return 1 if ( $hash_ref->{$item} );

    my $item_only_under = $item;
    $item_only_under =~ s/\s+/_/igm;
    return 1 if ( $hash_ref->{$item_only_under} );

    $item = strip_to_base_word($item);

    my @endings =
      sort { length $a > length $b } ( qw{en e s n in innen es r es er}, '' );
    my @words = split /[_\s]+/, $item;
    my %is_time_measurement = map { $_ => 1 } &$get_time_measurements_ref();
    my @words_relevant = map { strip_to_base_word($_) } grep {
        $_ !~
/^(ein|der|die|das|den|dem|des|ein|eine|einer|einen|einem|eines|kein|keine|keinen|keines|keiner|a|an|the)(\s|$)/i
          && !$is_time_measurement{$_}
    } @words;

    if ( scalar @words_relevant > 1 && $words_relevant[-1] =~ /^[_].*?[_]$/ ) {
        pop @words_relevant;
        pop @words;
    }
    my @table_words = ();

    foreach my $word (@words_relevant) {
        push @table_words, $word;
    }

    my $count          = 0;
    my $count_max      = scalar @words_relevant;
    my $count_relevant = scalar @words_relevant;
    my $verbose_text   = '';
    foreach my $word (@table_words) {
        my $found = 0;
        foreach my $hash_ref_inner ( @{ $hash_ref->{'___'} } ) {

            $verbose_text .=
              "!! new_hash{ $word } = " . ( $hash_ref_inner->{$word} || 0 )
              if $verbose;
            $verbose_text .= "\n"
              if $verbose;
            if ( $hash_ref_inner->{$word} ) {
                $count += 1;
                $found = 1;
                last;
            }
        }
    }
    my @table_words_double = ();
    my $e                  = 0;
    for ( $e = 0 ; $e < scalar @table_words ; $e += 2 ) {
        if ( $table_words[ $e + 1 ] ) {
            my $x2 = strip_to_base_word( $table_words_double[$e] );
            my $y2 = strip_to_base_word( $table_words_double[ $e + 1 ] );

            my $all1 = $table_words[$e] . ' ' . $table_words[ $e + 1 ];
            my $all3 = $x2 . ' ' . $table_words[ $e + 1 ];
            my $all5 = $table_words[$e] . ' ' . $y2;
            my $all7 = $x2 . ' ' . $y2;
            push @table_words_double, $all1, $all3, $all5, $all7;
        }
    }
    foreach my $word (@table_words_double) {
        next if !$word;

        if ( $word =~ /kuenstlich/ ) {
            say $word;
        }

        my $found = 0;
        foreach my $hash_ref_inner ( @{ $hash_ref->{'___'} } ) {

            $verbose_text .=
              "!! new_hash{ $word } = " . ( $hash_ref_inner->{$word} || 0 )
              if $verbose;
            $verbose_text .= "\n"
              if $verbose;
            if ( $hash_ref_inner->{$word} ) {
                $count += 1;
                $found = 1;
                last;
            }
            $word =~ s/[_]/ /igm;
            if ( $hash_ref_inner->{$word} ) {
                $count += 1;
                $found = 1;
                last;
            }
            $word =~ s/\s+/_/igm;
            if ( $hash_ref_inner->{$word} ) {
                $count += 1;
                $found = 1;
                last;
            }
        }
    }
    $hash_ref->{'___'} = [$hash_ref] if !$hash_ref->{'___'};
    my %is_in_item = map { lc $_ => 1 } @words;
    if ( !@{ $hash_ref->{'___'} } ) {
        $hash_ref->{'___'} = [ {} ];
    }
    my $but_contains_main_word =
         $hash_ref->{'___'}->[-1]->{ $words_relevant[-1] }
      || $hash_ref->{'___'}->[-1]
      ->{ ( $words_relevant[-2] || '' ) . ' ' . $words_relevant[-1] }
      || 0;
    my $count_of_words = $hash_ref->{'_count'} || 0;
    if (
        ( grep { /ein/i } @words_relevant )
        ? $count == $count_max
        : $count <= $count_max
        && $count
        && $but_contains_main_word
        && ( $count_relevant > 0 ? $count_relevant >= $count_of_words : 1 )
      )
    {
        print $verbose_text;
        say "($count_relevant > 0 ? $count_relevant >= $count_of_words : 1) = ",
          ( $count_relevant > 0 ? $count_relevant >= $count_of_words : 1 )
          if $verbose;

        #        select undef, undef, undef, 1 if $item =~ /everest/i;
        $cache_is_in{$id} = 1;
        return 1;
    }
    say "\n", "item: ", $item, "\n",
      "($count_relevant > 0 ? $count_relevant >= $count_of_words : 1) = ",
      ( $count_relevant > 0 ? $count_relevant >= $count_of_words : 1 ),
      "\nbut_contains_main_word: ", $but_contains_main_word,
      "\ncount == count_max:", "\n$count == $count_max:", $count == $count_max,
      "\n",

      if $verbose;

    #    select undef, undef, undef, 1 if $item =~ /everest/i;

    my $item_old = $item;
    $item =~ s/^\s+//igm;
    $item =~ s/\s+$//igm;
    $item =~ s/^_+//igm;
    $item =~ s/_+$//igm;
    $item =~ s/_/ /igm;
    if ( $item ne $item_old && !$no_recursion ) {
        my $without_under = is_in( $hash_ref, $item, $verbose, 1 );
        $cache_is_in{$id} = $without_under;
        return $without_under if ($without_under);
    }
    $item = join ' ', @words_relevant;
    $item =~ s/^\s+//igm;
    $item =~ s/\s+$//igm;
    $item =~ s/^_+//igm;
    $item =~ s/_+$//igm;
    $item_old = $item;
    $item =~ s/\s+/_/igm;

    if ( $item ne $item_old && !$no_recursion ) {
        my $without_under = is_in( $hash_ref, $item, $verbose, 1 );
        $cache_is_in{$id} = $without_under;
        return $without_under if ($without_under);
    }

    $cache_is_in{$id} = 0;

    return 0;
}

sub say {
    print scalar localtime;
    print ': ';
    print grep { defined $_ } @_;
    print "\n";
    return 1;
}

1;
