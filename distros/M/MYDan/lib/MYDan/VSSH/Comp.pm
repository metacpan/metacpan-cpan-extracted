package MYDan::VSSH::Comp;
use base Term::Completion;

use strict;
use warnings;

use MYDan::VSSH::History;


sub get_term_size
{
    my ( $r, $c ) = ( 0, 0 );
    if ( $^O ne "solaris" )
    {
        my $size = eval { `stty size` };
        if ( $size =~ /^\s*(\d+)\s+(\d+)\s*/ )
        {
            ( $r, $c ) = ( $1, $2 );
        }
    }
    else
    {
        eval {
            foreach (`stty`)
            {
                if (/^rows = (\d+); columns = (\d+)/) {
                    $r = $1;
                    $c = $2;
                    last;
                }
            }
        };
    }

    if ( $r == 0 || $c == 0 )
    {
        if ( exists $ENV{'LINES'} ) { $r = $ENV{'LINES'}; }
        else { $r = 80; }    # this is often wrong
        if ( exists $ENV{'COLUMNS'} ) { $c = $ENV{'COLUMNS'}; }
        else { $c = 80; }
    }

    return ( $r, $c );
}

sub complete
{
  my __PACKAGE__ $this = shift;

  my $return = $this->{default};
  my $r = length($return);

  if(defined $this->{helptext} && !defined $this->{help}) {
    $this->show_help();
  }

  # we grab full control of the terminal, switch off echo
  $this->set_raw_tty();

  my $tab_pressed = 0; # repeated tab counter
  my $choice_num; # selector
  my @choice_cycle;
  my $eof = 0;

  # handle terminal size changes
  # save any existing signal handler


  if(exists $SIG{'WINCH'}) {
    $this->{_sig_winch} = $SIG{WINCH};
    # set new signal handler
    local $SIG{'WINCH'} = sub {
      if($this->{_sig_winch}) {
        &{$this->{_sig_winch}};
      }
      # write new prompt and completion line
      $this->{out}->print($this->{eol}, $this->{prompt}, $return);
    };
  }

my ( undef, $col_len) = get_term_size();
my $prompt_len = length $this->{prompt};
my $last_len = $col_len - $prompt_len -2;
my $cut_len = int ( $col_len /3 );

my $prompt_l = $this->{prompt};
$prompt_l =~ s/sh\$$/<<</;

my $danger = 0;
my $reverse_prompt = '(reverse-i-search)';

  # main loop for completion
  my ( $lr, $reverse, $reverse_2 ) = 0;
  LOOP: {
    local $_ = '';
    $this->{out}->print($this->{prompt}, $return);
    my $key;
    GETC: while (defined($key = $this->get_key) && ($_ .= $key, $_ !~ $this->{enter})) {
      CASE: {
        # deal with arrow key escape sequences
        if(/^\x1b([^\[])/ || /^\x1b\[(?:[A-Z]|\d+~)(.)/) {
          # unknown ESC sequence: just keep the last key typed
          $_ = $1;
          redo CASE;
        }

        $_ =~ $this->{'reverse'} && do {
            $this->{out}->print( $this->{del_one} x $col_len , "\033[K", $reverse_prompt." :" );
            ( $return, $reverse, $reverse_2 ) = ( '', 1, '' );
             $danger = 1;
            last CASE;
        };

        if( $reverse )
        {
                $_ =~ /^[a-zA-Z0-9 -\/]$/ && do {
                    $this->{out}->print( $this->{del_one} x $col_len , "\033[K");
                    for my $his ( reverse  @MYDan::VSSH::History::HISTORY )
                    {
                        if( $his =~ /$reverse_2$_/ )
                        {
                            $reverse_2 .= $_;
                            $return = $his;
                            my %tmp;
                            @choice_cycle = 
                                grep{ /$reverse_2/ && $tmp{$_} == 1 }
                                map{ $tmp{$_} ++; $_} 
                                @MYDan::VSSH::History::HISTORY;
                            $choice_num = $#choice_cycle;
                            last;
                        }
                    }
                   
                   my $show = "$reverse_prompt `$reverse_2': $return";
                   my $len = length $show;
        
                   ($len > ( $col_len -2 ) )
                      ? $this->{out}->print( substr( $show , 0 , ( $col_len -2 ) ), ">>")
                      :  $this->{out}->print( $show );
                   ( $r, $lr ) = ( length( $return), 0 );
                   
                   last CASE;
                };
        
                $_ =~ $this->{erase} && do {
                    $this->{out}->print( $this->{del_one} x $col_len , "\033[K");
                    chop $reverse_2;
                    for my $his ( reverse  @MYDan::VSSH::History::HISTORY )
                    {
                        if( $his =~ /$reverse_2/ )
                        {
                            $return = $his;
                            my %tmp;
                            @choice_cycle = 
                                grep{ /$reverse_2/ && $tmp{$_} == 1 }
                                map{ $tmp{$_} ++; $_}
                            @MYDan::VSSH::History::HISTORY;
                            $choice_num = 0;
                            last;
                        }
                    }
                   my $show = "$reverse_prompt `$reverse_2': $return";
                   my $len = length $show;
        
                   ($len > ( $col_len -2 ) )
                      ? $this->{out}->print( substr( $show , 0 , ( $col_len -2 ) ), ">>")
                      :  $this->{out}->print( $show );
         
                   ( $r, $lr ) = ( length( $return), 0 );
                   last CASE;
                };
        
                $_ =~ $this->{up} && do {
                    if($choice_num <= 0) {
                        $this->bell();
                    }
                    else{ $choice_num-- };
                    $return ||='';
                    $return = $choice_cycle[$choice_num]||'';
                    $this->{out}->print( $this->{del_one} x $col_len , "\033[K");
        
                   my $show = "$reverse_prompt: $return";
                   my $len = length $show;
                    ($len > ( $col_len -2 ) )
                      ? $this->{out}->print( substr( $show , 0 , ( $col_len -2 ) ), ">>")
                      :  $this->{out}->print( $show );
                   ( $r, $lr ) = ( length( $return), 0 );
                  last CASE;
                };
        
                $_ =~ $this->{down} && do {
                    if(++$choice_num >= @choice_cycle) {
                      $choice_num = $#choice_cycle;
                      $this->bell();
                    }
                  $return ||='';
                  $this->{out}->print( $this->{del_one} x $col_len , "\033[K");
                  $return = $choice_cycle[$choice_num] ||'';
        
                   my $show = "$reverse_prompt: $return";
                   my $len = length $show;
                  ($len > ( $col_len -2 ) )
                    ? $this->{out}->print( substr( $show , 0, ( $col_len -2 ) ), ">>")
                    :  $this->{out}->print( $show );
                   ( $r, $lr ) = ( length( $return), 0 );
                  last CASE;
                };
                
                ( $_ =~ $this->{left} || $_ =~ $this->{right} ) && do {
                      $this->{out}->print($this->{del_one} x $col_len, "\033[K");

                      if( $r >= $last_len )
                      {
                          $this->{out}->print( 
                              $prompt_l, substr( $return, ( $r - $last_len ) , $last_len ),);
                      }
                      else
                      {
                          $this->{out}->print( $this->{prompt}, $return);
                      }
            
                     $reverse = 0;
                     last CASE;
                };
        }
        else{

        # (TAB) attempt completion
        $_ =~ $this->{tab} && do {
          if($tab_pressed++) {
            $this->show_choices($return);
            redo LOOP;
          }
          my @match = $this->get_choices($return||'');
          if (@match == 0) {
            # sound bell if there is no match
            $this->bell();
          } else {
            my $l = length(my $test = shift(@match));
            if(@match) {
              # sound bell if multiple choices
              $this->bell();
            }
            elsif($this->{delim}) {
              $test .= $this->{delim};
              $l++;
            }
            foreach my $cmp (@match) {
              until (substr($cmp, 0, $l) eq substr($test, 0, $l)) {
                $l--;
              }
            }
            my $add = $l - $r;
            if($add) {
              $this->{out}->print($test = substr($test, $r, $add));
              # reset counter if something was added
              $tab_pressed = 0;
              $choice_num = undef;
              $return .= $test;
              $r += $add;
            }
          }
          last CASE;
        };

        $tab_pressed = 0; # reset repeated tab counter

        # (^D) completion list
        $_ =~ $this->{list} && do {
          $this->reset_tty();
          exit 0;
        };

        # on-demand help
        if(defined $this->{help}) {
          $_ =~ $this->{help} && do {
            if(defined $this->{helptext}) {
              $this->{out}->print($this->{eol});
              $this->show_help();
            }
            redo LOOP;
          };
        }

        # (^U) kill
        $_ =~ $this->{'kill'} && do {
          if ($r) {
            $this->{out}->print($this->{eol});
            $choice_num = undef;
            ( $return, $r, $lr ) = ( '', 0, 0 );
            redo LOOP;
          }
          last CASE;
        };

        # (^L) clear
        $_ =~ $this->{'clear'} && do {
            system 'clear';
            $this->{out}->print($this->{prompt});
            ( $return, $r, $lr ) = ( '', 0, 0 );
            last CASE;
        };
        # (^L) quit
        $_ =~ $this->{'quit'} && do {
            $this->{out}->print("\n");
            $return = '';
            redo LOOP;
            #last CASE;
        };

        $_ =~ $this->{'wipe'} && do {
            if( $r && $r <= $last_len && !$lr )
            {
                $return =~ s/(\s*[^\s]+\s*)$//;
                $this->{out}->print( $this->{del_one} x length($1));
                $r = length($return);
            }
          last CASE;
        };

       $_ =~ $this->{up} && do {
          @choice_cycle = @MYDan::VSSH::History::HISTORY;
          last CASE unless @choice_cycle;
          unless(defined $choice_num) {
              $choice_num = $#choice_cycle;
          } else {
            if($choice_num <= 0) {
                $this->bell();
            }
            else{ $choice_num-- };
          }
          $return = $choice_cycle[$choice_num];
          $lr =0;
          $r = length($return);

          $this->{out}->print($this->{del_one} x $col_len , "\033[K" );

          if( length( $return ) >= $last_len )
          {
              $this->{out}->print(
                  $prompt_l,substr( $return, ( length($return) - $last_len ) , $last_len) );
          }
          else
          {
              $this->{out}->print( $this->{prompt}, $return );
          }
          last CASE;
        };

        # down (CTRL-N)
        $_ =~ $this->{down} && do {
          @choice_cycle = @MYDan::VSSH::History::HISTORY;
          last CASE unless @choice_cycle;
          unless(defined $choice_num) {
              $this->bell();
              last CASE;
          } else {
            if(++$choice_num >= @choice_cycle) {
              $choice_num = $#choice_cycle;
              $this->bell();
            }
          }
          #TODO only delete/print differences, not full string
          $return = $choice_cycle[$choice_num];
          $lr =0;
          $r = length($return);

          $this->{out}->print($this->{del_one} x $col_len, "\033[K");

          if( length( $return ) >= $last_len )
          {
              $this->{out}->print(
                  $prompt_l, substr( $return, ( length($return) - $last_len ) , $last_len) );
          }
          else
          {
              $this->{out}->print( $this->{prompt}, $return );
          }
 
          last CASE;
        };


        $_ =~ $this->{left} && do {
          unless( $lr >= $r )
          {
               $lr ++;
               if( $r >= $last_len )
               {
                  $this->{out}->print( $this->{del_one} x $col_len, "\033[K" );

                  my $post = $r - $lr;
                  if( $post >= $last_len )
                  {
                      $this->{out}->print(
                          $prompt_l,substr( $return, ( $post - $last_len ) , $last_len),
                          ">>\033[2D" );
                  }
                  else
                  {
                      my $back_cur = $last_len + 2 - $post;
                      $this->{out}->print( 
                          $this->{prompt}, substr( $return, 0, $last_len),
                          ">>"."\033[".$back_cur."D" );
                  }
               }
               else
               {
                   $this->{out}->print( "\033[1D" );
               }
          }
          last CASE;
        };

        $_ =~ $this->{right} && do {
          if( $lr )
          {
               $lr --;
               if( $r >= $last_len )
               {
                  $this->{out}->print( $this->{del_one} x $col_len, "\033[K" );
                  my $post = $r - $lr;

                  if( $post >= $last_len )
                  {
                      $this->{out}->print(
                          $prompt_l, substr( $return, ( $post - $last_len ) , $last_len ),
                          ">>\033[2D");
                  }
                  else
                  {
                      my $back_cur = $last_len + 2 - $post;
                      $this->{out}->print(
                          $this->{prompt}, substr( $return, 0, $last_len), 
                          ">>"."\033[".$back_cur."D");
                  }
               }
               else
               {
                   $this->{out}->print("\033[1C");
               }
 
          }
          else
          {
              $this->{out}->print( "\033[K" );             
          }
          last CASE;
        };

        # (DEL)
        $_ =~ $this->{erase} && do {
          if($r && $r > $lr) {

            $choice_num = undef;

            if( $lr )
            {           
                $this->{out}->print( $this->{del_one} x $col_len, "\033[K" );

                $danger = 1;
                my $post = $r - $lr;
                substr( $return, ( $post -1 ), 1 ) = '';
                $r--;

                unless( $r > $last_len )
                {
                    $this->{out}->print( $this->{prompt}, $return, "\033[".$lr."D");
                }
                elsif( $post >= $last_len )
                {
                    $this->{out}->print( 
                        $prompt_l, substr( $return, ( $post - $last_len ) , $last_len ),
                         ">>\033[2D");
                }
                else
                {
                    my $back_cur = $last_len - $post +1;
                    $this->{out}->print(  
                        $this->{prompt}, substr( $return, 0, $last_len ),
		        "\033[".$back_cur."D");
                }
            }
            else
            {
                chop($return);
                $r--;
                if( $r > $last_len )
                {
                    $this->{out}->print( $this->{del_one} x $col_len, "\033[K" );
                    $this->{out}->print( 
                        $prompt_l, substr( $return, ( $r - $last_len ) )
                    );
                }
                else
                {
                      $this->{out}->print( $this->{del_one} );
		}
            }
          }
          last CASE;
        };

 
        ord >= 32 && do {
          if( $lr )
          {
              $danger = 1;
              $this->{out}->print($this->{del_one} x $col_len, "\033[K");
              my $post = $r - $lr;
              substr( $return, $post, 0 ) = $_;

              if( $r >= $last_len )
              {
                  if( $post >= $last_len )
                  {
                      $this->{out}->print( 
                          $prompt_l, substr( $return, ( $post - $last_len ) , $last_len ),
                          ">>\033[2D");
                  }
                  else
                  {
                      my $back_cur = $last_len + 2 - $post;
                      $this->{out}->print(  
                          $this->{prompt}, substr( $return, 1, $last_len ),
			  ">>"."\033[".$back_cur."D");
                  }
              }
              else
              {
                  $this->{out}->print( $this->{prompt}, $return, "\033[".$lr."D");
              }
          }
          else
          {
              if( $r >= $last_len )
              {
                  $this->{out}->print( 
                      $this->{del_one} x $col_len, $prompt_l, 
                      substr( $return, ( $r - $last_len +1 ) )
                  );
              }

              $return .= $_;
              $this->{out}->print($_);
          }

          $r++;
          $choice_num = undef;
          last CASE;
        };

        $_ !~ /^\x1b/ && do {
          # sound bell and reset any unknown key
          $this->bell();
          $_ = '';
        };
       }#last else
        next GETC; # nothing matched - get new character
      } # :ESAC
      $_ = '';
    } # while getc != enter
    $this->{out}->print($this->{eol});
    $return = $this->post_process($return);
    # only validate if we had input
    my $match = defined($key) ? $this->validate($return) : $return;
    unless(defined $match) {
      redo LOOP;
    }
    $return = $match;
  } # end LOOP

  $this->reset_tty;
  delete $this->{_sig_winch};

  return ( $return, $danger );
}

1;
