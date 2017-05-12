use Test::More;
use Scalar::Util qw(blessed reftype looks_like_number);
use Data::Dumper;

sub test_moves {
   my $sgf = shift;
   my $name = shift;
   my(@moves) = @_;
   my $color = "B";
   for(my $i = 0; $i < @moves; $i++) {
      ok($sgf->next, "$i $name");
      tag_eq($sgf, "$i $name",
         $color => [$moves[$i]]);
      $color = $color eq 'B' ? 'W' : 'B';
   }
}

# TODO recursive definition
sub tag_eq {
   my $sgf = shift;
   my $name = shift;
   my( %tags ) = @_;

   TAG: foreach my $t( keys %tags ) {
      # get the property value
      my $values = $sgf->property($t);
      if( not( defined $tags{$t} ) ) {
        if( $values ) {
           fail( "$t - name" );
           diag( "Expected no tag\nGot " . Dumper $values );
        } else {
           pass( "$t - name");
        }
        next TAG;
      }
      # adds array ref if not ref'ed
      # blessed $refs count as a single item
      if( not( ref $tags{$t}) or blessed($tags{$t}) ) {
         $tags{$t} = [$tags{$t}];
      }

      # actually test the value
      if( not $values ) {
         fail( "$t - $name" );
         diag( " Parser returned error: " . $sgf->Fatal);
         next TAG;
      }
      my( $pass, $str ) = deep_test( $values, $tags{$t} );
      if( $pass ) {
         pass( "$t - $name" );
      } else {
         fail( "$t - $name" );
         diag($str);
      }
   }
}

#TODO save diff for use in diag
#     maybe
#        return 1 on equal
#        return 0,str on diff
#           where str is a string giving the difference
#     add a Have compared hash
my %compared;
sub deep_test {
   # init vars
   my( $got ) = shift;
   my( $expect ) = shift;
   return _deep_test( $got, $expect );
}
sub _deep_test {
   my $got = shift;
   my $expect = shift;
   #if( not defined $got or not defined $expect ) {
   #   return (0, join( "\n", Dumper($got, $expect)));
   #}

   my $rGot = reftype $got;
   my $rExp = reftype $expect;
   my $bGot = blessed $got;
   my $bExp = blessed $expect;

   if( (defined $rGot && defined $rExp and $rGot ne $rExp) or
         defined $rGot xor defined $rExp ) {
      return (0, "reftype('$rGot', '$rExp'):\n" 
         . join( "\n", Data::Dumper->Dump([$got, $expect],["got","expect"])));
   }


   #if blessed make sure are blessed the same
   if( (defined $bGot && defined $bExp and $bGot ne $bExp) or
         defined $bGot xor defined $bExp ) {
      return (0, "blessed('$bGot','$bExp'):\n" 
         . join( "\n", Data::Dumper->Dump([$got, $expect],["got","expect"])));
   }

   # the references are the same
   if( defined $rGot ) {
      if( $rGot eq 'ARRAY' ) {
         if( @$got != @$expect ) {
            return (0, join( "\n", Data::Dumper->Dump(
                     [$got, $expect],["got","expect"])));
            return 0;
         }
   
         # the arrays are the same length
         
         for( my $i = 0; $i < @$got; $i++ ) {
            my($pass, $str) = _deep_test( $got->[$i], $expect->[$i] );
            if( not $pass ) {
               return (0, $str);
            }
         }
         return 1;
      } elsif( $rGot eq 'HASH') {
         if( scalar keys %$got != scalar keys %$expect ) {
            return (0, join( "\n", Data::Dumper->Dump(
                     [$got, $expect],["got","expect"])));
         }
      
         # same number of keys
         foreach(keys %$got ) {
            my($pass, $str) = _deep_test( $got->{$_}, $expect->{$_} );
            if( not $pass ) {
               return (0, $str);
            }
         }
         return 1;
      } elsif( $rGot eq 'SCALAR' ) {
         return _deep_test($$got, $$expect);
      }
   } else { # then they are not refs and should be directly compared
      if( looks_like_number $got and looks_like_number $expect ) {
         if( $got == $expect ) {
            return 1;
         } else {
            return (0, join( "\n", Data::Dumper->Dump(
                     [$got, $expect],["got","expect"])));
         }
      } elsif( (not looks_like_number $got) 
            and (not looks_like_number $expect)) {
         if( $got eq $expect ) {
            return 1;
         } else {
            return (0, join( "\n", Data::Dumper->Dump(
                     [$got, $expect],["got","expect"])));
         }
      } else {
         return (0, join( "\n", Data::Dumper->Dump(
                 [$got, $expect],["got","expect"])));
      }
   }
   return(0,"Not sure how I reached the end(must be strange reftype $rGot\n");
}
1;
