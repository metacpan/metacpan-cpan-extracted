   
    package Devel::Animator;   
    our $VERSION = '2.30';   
    my $pl  = 'animate.pl';
    my $stk = 'stack.dat'; 
	$DB::index=1;
    unlink $pl;
    unlink $stk;
    &display;

    BEGIN { $| = 1 }
    open( $DB::fh,"> $stk") or die "stack file disappeared!";

    sub DB::DB {
    my ($p, $f, $l) = caller;
    my $code = \@{"::_<$f"};  
    sub strip{ $_[0] =~ s/\r//g; $_[0] =~ s/\n//g; return $_[0] if defined($_[0]);} 
    my $fcode = substr $code->[$l], 0, 80;   
    print $DB::fh sprintf("%6d", $DB::index++), sprintf("%-128s", $f), sprintf("%6d", $l), sprintf("%-80s",&strip($fcode)),"\n"; 
    }

    sub display {    
    open ( my $fh,">$pl");
      while ( <DATA> ) {     
          print $fh $_;
      }
    close $fh;
   
    system (1,"perl $pl") if   ($^O eq 'MSWin32');
    system ("perl $pl &") if ! ($^O eq 'MSWin32'); 
    }  
    1;    

    __DATA__
	
#  set_init_state failing because meta_ref may not have updated sequence array in bypass_file
use strict;
use warnings;
use Tk;
use Tk::Table;
use Tk::StatusBar;
use Tk::BrowseEntry;
use Tk::Balloon;
use File::stat;
if ($^O eq 'MSWin32') { require Win32::GUI;}
no warnings qw(recursion deprecated);

BEGIN { 
package Devel;  

 sub new {   
  my $class = shift;   
  my $self = { };   
 bless $self, $class;   
 return $self;  
}  

sub set {    
 my $self   = shift; 
 my $key    = shift;     
 my $value  = shift;   

 sub _define { defined $_[0] ? return $_[0] : return 'undefined' }

 $self->{$key} = $value;   
 return $self;
}  

sub get_value {    
my $self   = shift;    
my $key    = shift;    
unless ( defined( $self->{ $key } ))     
 {       
  print "Key $key is not a valid object attribute","\n";       
  print "Exiting...","\n";       
  exit(0);     
 }     
 return $self->{ $key };  
}

sub set_stack_file {
my $self = shift;
 $self->set( '_stack_file', 'stack.dat'); 
}

sub done_loading_meta_data {
my $self = shift;

        my $filesz = -s $self->{'_stack_file'}; 
   if ( ! $self->{_loaded} ) {
       if ( $self->{_filesize} eq  $filesz and $filesz > 0 ) {              
         # load file into array    
         my @meta;
		 open my $fh, "<", "$self->{'_stack_file'}" or die "stack file corrupted: $!";
		 while(<$fh>) {  
           my $file = $self->good_filename( substr $_, 6, 128 );
           next if ! defined($file);
           push( @meta, $_ );		   
         }
        
         $self->set('_meta_data_start', '1'); 	
		 $self->set('_meta_data_start_display', sprintf( "%8d", 1 ));
		 $self->set('_meta_data_end', scalar(@meta));
		 $self->set('_meta_data_end_display', sprintf( "%8d",  scalar(@meta)));
         $self->set('_meta_ref', \@meta);
         $self->update_delay(50); 
         $self->set('_loaded', 1);
         $self->set('_status', "RUNNING");
         $self->set('_msg', "Animation in Progress");  
         $self->load_file_cache();
		 		 
         $self->{_filelist_ref} = $self->get_file_names;
         $self->{_mw}->{_filelist}->configure( -choices => $self->{_filelist_ref} );
         $self->{_mw}->{_filelist}->configure( -browsecmd => sub { $self->bypass_file } );		
		 
		 $self->{_mw}->{_mod_start_seq}->delete( 0.1, 'end' );
		 $self->{_mw}->{_mod_start_seq}->insert("end", "$self->{_meta_data_start}");
		 
         $self->{_mw}->{_mod_end_seq}->delete( 0.1, 'end' );
		 $self->{_mw}->{_mod_end_seq}->insert("end", "$self->{_meta_data_end}");
		 
		 #use Data::Dumper;
		 #print Dumper(@meta);
		 #exit;
		 
         return(1);
       }
       else 
          {
          $self->set('_filesize', $filesz);
          $self->update_delay(1000);
          return(0);     
          }    
   }
return(1);
}

sub bypass_file {
my $self = shift;
my @temp1 = ();
my @temp2 = ();
my $start_seq=1;

my ($sequence, $file, $line, $code);
 $self->set_stopped_state(); 
 # define the different states

 # add file to bypass list
 push(@{$self->{_bypass_file_ref}}, $self->{_filelist});

 # re-define meta-ref 
   foreach (@{$self->{_meta_ref}}) {
    $sequence = substr $_, 0, 6;
    $file     = substr $_, 6, 128;
    $line     = substr $_, 134, 6;
    $code     = substr $_, 140, 80;
   
    if ( $self->trim($self->{_filelist}) ne $self->trim($file )) {
        # re-number sequence
        $sequence = sprintf( "%6d", $start_seq++ );
        $file     = substr $_, 6,   128;
        $line     = substr $_, 134,   6;
        $code     = substr $_, 140,  80;
	    push( @temp2, $sequence . $file . $line . $code );
	}
  }
  $self->set('_meta_ref', \@temp2);
    
 # update status bar
 $self->{_meta_data_end_display} = scalar(@{$self->{_meta_ref}});
 
 # update browse-entry widget
 foreach (@{$self->{_filelist_ref}}) {
  if ( $_ ne $self->{_filelist} ) {
   push (@temp1, $_ );
  }
 } 
 
 # initialize be widget entry value to be not filled
 $self->{_filelist} = undef;

 # update the files in widget 
 $self->{_filelist_ref} = \@temp1;
 $self->{_mw}->{_filelist}->configure( -choices => $self->{_filelist_ref} );

 # initialize program
 $self->set_init_state();
}

sub exit_app { 
my $self = shift;
unlink $self->{_animate};
unlink $self->{_stack_file}; 
 system("taskkill /F /PID $$") if ($^O eq 'MSWin32');
 system("kill $$") if ($^O ne 'MSWin32');
}

sub get_screen_width {
my $self = shift;
my $mw = shift;

 if ($^O eq 'MSWin32') {
   #return( int($mw->screenwidth * .99));
   return( $self->{_mw}->fontMeasure('TkDefaultFont', 'X') * 100);
   }
}

sub get_screen_height {
my $self = shift;
 if ($^O eq 'MSWin32') {
  $self->{_desk} = Win32::GUI::GetDesktopWindow();
  my $height = int(Win32::GUI::Height($self->{_desk}) * .90);
  return( $height); 
 }
}

sub create_control {
my $self = shift;
my ( $frame);

$self->{_msgarea} = $self->{_mw}->Label(-borderwidth => 2, -relief => 'groove')->pack(-side => 'bottom', -fill => 'x');
my $balloon = $self->{_mw}->Balloon(-statusbar => $self->{_msgarea}, -bg => 'yellow');

$self->{_mw}->Label(-bg => 'grey', -borderwidth => 0, -relief => 'sunken',  -text => 'Perl Source Code Animator', )->pack(-anchor => 'n', -fill => 'both'); 
$frame = $self->{_mw}->Frame()->pack(-expand => 0, -fill => 'both');
$self->set( '_frame', $frame);
$self->{_mw}->{_exit}  = $frame->Button(-width => $self->{_button_width}, -text=>"Exit", -command=>sub{ $self->exit_app()} )->pack(-side=>"left");
$balloon->attach($self->{_mw}->{_exit}, -balloonmsg => "Exit the App", -statusmsg => "Press the Button to exit the application");

$self->{_mw}->{_stop}  = $frame->Button(-width => $self->{_button_width}, -text=>"Stop", -command=>sub{ $self->stop_app()} )->pack(-side=>"left");
$balloon->attach($self->{_mw}->{_stop}, -balloonmsg => "Stop the App", -statusmsg => "Press the Button to pause the application");

$self->{_mw}->{_start} = $frame->Button(-width => $self->{_button_width}, -text=>"Start",-command=>sub{ $self->start_app()})->pack(-side=>"left");
$balloon->attach($self->{_mw}->{_start}, -balloonmsg => "Start the App", -statusmsg => "Press the Button to start the application");

$self->{_mw}->{_reset} = $frame->Button(-width => $self->{_button_width}, -text=>"Reset",-command=>sub{ $self->set_init_state()})->pack(-side=>"left");
$balloon->attach($self->{_mw}->{_reset}, -balloonmsg => "Reset the App", -statusmsg => "Press the Button to reset the application to the initial state");

$self->{_filelist} = 'loading...';

$self->{_mw}->{_repeat}      = $frame->BrowseEntry(-label => "Repeat", -variable => \$self->{_repeat}, -width => '10');
$self->{_mw}->{_repeat}->insert("end", "YES");
$self->{_mw}->{_repeat}->insert("end", "NO");
$self->{_mw}->{_repeat}->pack(-side=>"right");


$self->{_repeat} = "NO";
$balloon->attach($self->{_mw}->{_repeat}, -balloonmsg => "Enable App Looping", -statusmsg => "Press the dropdown to set whether application loops");

$self->{_mw}->{_mod_end_seq} = $frame->Entry(  
		                                    -background  => 'yellow',
		                                    -foreground  => 'black',
	                                        -width       => 10,
                                            -justify     => 'right',
		                                    )->pack(-side=>"right");
$self->{_mw}->{_mod_end_seq}->insert("end", 0);
$self->{_mw}->{_mod_end_seq}->bind( '<Button-1>', sub {
                                                       unless ( $self->{_status} eq 'STOPPED' ) {
                                                          $self->set_stopped_state();
														}
                                                        $self->{_mw}->{_mod_end_seq}->delete( 0.1, 'end' ); 
                                                      } );
													  
$balloon->attach($self->{_mw}->{_mod_end_seq}, -balloonmsg => "End sequence number", -statusmsg => "Enter integer value for end sequence number for animation");
													  
													  
$self->{_mw}->{_mod_start_seq} = $frame->Entry( 
		                                      -background  => 'yellow',
		                                      -foreground  => 'black',
	                                          -width       => 10,
                                              -justify     => 'right',
		                                      )->pack(-side=>"right");
$self->{_mw}->{_mod_start_seq}->insert("end", 0);
$self->{_mw}->{_mod_start_seq}->bind( '<Button-1>', sub { 
                                                       unless ( $self->{_status} eq 'STOPPED' ) {
                                                          $self->set_stopped_state();
														}
                                                        $self->{_mw}->{_mod_start_seq}->delete( 0.1, 'end' ); 
                                                        } );
$balloon->attach($self->{_mw}->{_mod_start_seq}, -balloonmsg => "Start sequence number", -statusmsg => "Enter integer value for start sequence number for animation");

$self->{_mw}->{_filelist}   = $frame->BrowseEntry(-label => "Bypass a file", -variable => \$self->{_filelist}, -width => '30' );
$self->{_mw}->{_filelist}->pack(-side=>"right");

$balloon->attach($self->{_mw}->{_filelist}, -balloonmsg => "omit from animation", -statusmsg => "select a file to omit from animation");

#$self->{_mw}->{_dir}      = $frame->BrowseEntry(-label => "Direction", -variable => \$self->{_direction}, -width => '10');
#$self->{_mw}->{_dir}->insert("end", "FWD");
#$self->{_mw}->{_dir}->insert("end", "REV");
#$self->{_mw}->{_dir}->pack(-side=>"right");

$self->{_mw}->{speed}  = $frame->BrowseEntry(-label => "Speed(ms)", -variable => \$self->{_delay}, -width => '10', -browsecmd => sub { $self->update_delay($self->{_delay}) }  );
$self->{_mw}->{speed}->insert("end", "50");
$self->{_mw}->{speed}->insert("end", "100");
$self->{_mw}->{speed}->insert("end", "250");
$self->{_mw}->{speed}->insert("end", "500");
$self->{_mw}->{speed}->insert("end", "750");
$self->{_mw}->{speed}->insert("end", "1000");
$self->{_mw}->{speed}->insert("end", "2000");
$self->{_mw}->{speed}->pack(-side=>"right");

$balloon->attach($self->{_mw}->{speed}, -balloonmsg => "select speed", -statusmsg => "select the desired speed for animation for animation");
}

sub get_file_names {
my $self = shift;
my @ary = ();
return \@ary if ! defined(@{$self->{_cache_ref}});

   foreach my $ref (@{$self->{_cache_ref}}) { 
    push( @ary, ${$$ref}{name});   
   }
 return( \@ary);  
}

sub config_window {
my $self = shift;

$self->{_mw}->{_config_window} = $self->{_mw}->Toplevel();
$self->set( '_config_window', $self->{_mw}->{_config_window});
$self->{_config_window}->title('Config');
$self->{_config_window}->Label(-bg => 'grey', -borderwidth => 0, -relief => 'sunken',  -text => 'Configuration Setup', )->pack(-anchor => 'n', -fill => 'both'); 
my $top = $self->{_config_window}->Frame(-background => 'pink'  )->pack(-expand => 0, -fill => 'both');
my $bottom = $self->{_config_window}->Frame(-background => 'white' )->pack(-expand => 0, -fill => 'both');

$top->Label(-bg => 'pink',  -borderwidth => 0, -relief => 'sunken',  -text => 'meta data begin', )->pack(-side => 'left');
$top->Label(-bg => 'white', -fg => 'grey', -borderwidth => 1, -relief => 'sunken',  -text => $self->{_meta_data_start} )->pack(-side => 'left', -padx => 2, -pady => 2);
$top->Label(-bg => 'pink', -borderwidth => 0, -relief => 'sunken',  -text => ' ', )->pack(-side => 'left', -padx => 20);
$top->Label(-bg => 'pink', -borderwidth => 0, -relief => 'sunken',  -text => 'meta data end', )->pack(-side => 'left');
$top->Label(-bg => 'white', -fg => 'grey', -borderwidth => 1, -relief => 'sunken',  -text => $self->{_meta_data_end}, )->pack(-side => 'left', -padx => 2, -pady => 2);
}

sub create_table {
my $self = shift;

 $self->{_table} = $self->{_mw}->Table(
   -columns    => 2,
   -rows       => $self->{_frame_window},
   -fixedrows  => 0,
   -scrollbars => 'oe',
   -relief     => 'raised',
 )->pack(-expand => 0, -fill => 'both');
}

sub create_status_bar {
my $self = shift;
 
 $self->{_status_bar} = $self->{_mw}->StatusBar()->pack(-expand => 0, -fill => 'x');

 my $msgarea = $self->{_mw}->Label(-borderwidth => 2, -relief => 'groove')->pack(-side => 'bottom', -fill => 'x');
 my $balloon = $self->{_mw}->Balloon(-statusbar => $self->{_msgarea}, -bg => 'yellow');


 my $msg = $self->{_status_bar}->addLabel( -relief         => 'flat',          -textvariable   => \$self->{_msg} );
 $balloon->attach($msg, -balloonmsg => "status message", -statusmsg => "current informational message");

 my $file = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_loaded_file},   -width => '35',  -anchor => 'w', -foreground => 'black', );
 $balloon->attach($file, -balloonmsg => "file being animated", -statusmsg => "current file meta-data being executed");

 my $cur_srce_line = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_cur_srce_line}, -width =>  '4',  -anchor => 'e', -foreground => 'black', );
 $balloon->attach($cur_srce_line, -balloonmsg => "current line number", -statusmsg => "current line number of file being animated");

 my $cur_exec_line = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_cur_exec_line}, -width =>  '5',  -anchor => 'e', -foreground => 'black', );
 $balloon->attach($cur_exec_line, -balloonmsg => "current meta line number", -statusmsg => "current line number of the meta file");
 
 my $pct_complete = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_pct_complete},  -width =>  '5',  -anchor => 'e', -foreground => 'black', );  
 $balloon->attach($pct_complete, -balloonmsg => "percent complete of processing meta records", -statusmsg => "percent complete of meta file");
 
 my $meta_start = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_meta_data_start_display}, -width => '10',  -anchor => 'e', -foreground => 'black');
 $balloon->attach($meta_start, -balloonmsg => "position in the meta-file animation starts from", -statusmsg => "meta-file start pointer");
 
 my $meta_end = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_meta_data_end_display},   -width => '10',  -anchor => 'e', -foreground => 'black');
 $balloon->attach($meta_end, -balloonmsg => "position in the meta-file animation ends", -statusmsg => "meta-file end pointer");
 
 # spacing
 $self->{_status_bar}->addLabel( -relief         => 'flat',  -text   => "  ", -width =>  '2',  -anchor => 'w', -foreground => 'black', ); 
 
 my $status = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_status}, -width => '10',  -anchor => 'center', -foreground => 'black', );
 $balloon->attach($status, -balloonmsg => "current animation status", -statusmsg => "animation status");
  
 #my $direction = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_direction},     -width => '5',   -anchor => 'center', -foreground => 'black', );
 #$balloon->attach($direction, -balloonmsg => "current animation direction", -statusmsg => "animation direction");
 
 my $delay = $self->{_status_bar}->addLabel( -textvariable   => \$self->{_delay_msg},     -width => '10',  -anchor => 'center', -foreground => 'black', );
 $balloon->attach($delay, -balloonmsg => "current animation speed", -statusmsg => "animation speed");
 }

sub stop_app { 
my $self = shift;
 $self->set_stopped_state(); 
}

sub start_app {
my $self = shift; 
 $self->set_started_state(); 
}

sub set_stopped_state {
my $self = shift;

 $self->set( '_status','STOPPED');
 $self->set( '_msg'   ,'Animation stopped.');
 $self->set( '_saved_index', $self->{_index});

 $self->set( '_saved_mod_end_seq',     $self->{_mw}->{_mod_end_seq}->get() );
 $self->set( '_saved_mod_start_seq',   $self->{_mw}->{_mod_start_seq}->get() );
 
 exit(0) if -e '_exit_for_test';
}

sub set_started_state {
#
# gathers program changes and processes them 
#
 my $self = shift;

 # init status bar
 $self->set('_meta_data_start', $self->{_mw}->{_mod_start_seq}->get()); 	
 $self->set('_meta_data_start_display', sprintf( "%8d", $self->{_mw}->{_mod_start_seq}->get() ));
 $self->set('_meta_data_end', $self->{_mw}->{_mod_end_seq}->get() );
 $self->set('_meta_data_end_display', sprintf( "%8d", $self->{_mw}->{_mod_end_seq}->get() ));
 $self->set( '_status','RUNNING');
 $self->set( '_msg'   ,'Animation in Progress');

 if ($self->{_mw}->{_mod_start_seq}->get() < 1 ) {
    $self->{_mw}->messageBox(-title => "Error setting new start sequence", -type => "Ok", -message => "edit start sequence to be a integer greater then 0");
    return(0);
 }

 if ($self->{_mw}->{_mod_start_seq}->get() >=  $self->{_mw}->{_mod_end_seq}->get() ) {
    $self->{_mw}->messageBox(-title => "Error setting new start sequence", -type => "Ok", -message => "edit start sequence to be less then end sequence");
    return(0);
 }
 
 if ( $self->{_mw}->{_mod_end_seq}->get() > $self->{_meta_data_end} ) {
    $self->{_mw}->messageBox(-title => "Error setting new end sequence", -type => "Ok", -message => "edit end sequence to be less then end record of meta-data");
    return(0);
 } 

   if ( $self->{_saved_mod_start_seq} != $self->{_mw}->{_mod_start_seq}->get() ) {
       $self->set( '_index', $self->{_mw}->{_mod_start_seq}->get());
      }
      elsif ( $self->{_saved_mod_start_seq} == $self->{_mw}->{_mod_start_seq}->get() ) {
               $self->set( '_index',  $self->{_index});
            }
}

sub set_init_state {
#
# sets the defaults for the program when an initial state is requested
# and is generally called after a change to the meta data is requested
#
my $self = shift;
$self->set_stopped_state(); 
$self->set( '_direction'   ,'FWD'); 
# init status bar
$self->set('_meta_data_start', 1); 	
$self->set('_meta_data_start_display', 1);
$self->set('_meta_data_end', scalar(@{$self->{_meta_ref}}) );  
$self->set('_meta_data_end_display', sprintf( "%8d", scalar(@{$self->{_meta_ref}}) ) );
$self->set( '_index', $self->{_mw}->{_mod_start_seq}->get()); 
$self->set_started_state(); 
}

sub update_delay {
my $self = shift;
my $delay = shift;

return if ( ! defined($self->{_timer_id}));

$self->set( '_delay', $delay);
$self->set( '_delay_msg', $self->{_delay} . ' ms');

$self->{_timer_id}->cancel;
$self->{_timer_id} = $self->{_table}->repeat($self->{_delay}, sub { $self->update_table }, $self->{_table});            
}

sub format_table {    
my $self = shift;
my $table = shift;
my ($row, $col);


    $table->configure( -rows => $self->{_frame_window}, -bg => 'white' );
    $table->configure( -fixedrows => 0 );
    for $row (1..$self->{_frame_window}) {

      $self->{_label_hash_ref}->{"${row}_1"} = $table->Label(-text   => '', -width  => 6,   -relief => 'flat', -background => 'white', -anchor => 'w');
      $table->put($row,1,$self->{_label_hash_ref}->{"${row}_1"});

      $self->{_label_hash_ref}->{"${row}_2"} = $table->Label(-text   => '', -width  => 6,   -relief => 'flat', -background => 'white', -anchor => 'w');
      $table->put($row,2,$self->{_label_hash_ref}->{"${row}_2"});

      $self->{_label_hash_ref}->{"${row}_3"} = $table->Label(-text   => '', -width  => 150, -relief => 'flat', -background => 'white', -anchor => 'w');
      $table->put($row,3,$self->{_label_hash_ref}->{"${row}_3"});
      
    }
    $table->pack(-expand => 0 ,-fill => 'both');
}

sub calculate_pct {
my $self = shift;
my $start = shift;  
my $end = shift;
my $row = shift;

   my $total_executions = abs($start-$end)+1; 
   my $executions_done = abs($start-$row);   
   return(0) if ($total_executions == 0);

   my $pct = int((($executions_done/$total_executions)*100)+.1);
   return( $pct);
}

sub load_file_cache {
my $self = shift;
my %unique_files; 
my @cache = ();

      foreach my $data (@{$self->{_meta_ref}}) {
          my $file = substr $data, 6, 128;
          $file = $self->good_filename( $file );   # if a filename cannot be parsed        
          next if ! defined($file);                # or name be parsed skip it
          if (! -e $file) {
               print STDERR "file $file not found!","\n";
               next;
          }
          $unique_files{$file} = '1' unless defined($unique_files{$file});    
      }    

      while ( my ($file, $count)=each %unique_files) {        
            my $lines=0;
            my @data = ();
            my %file_cache;
            
            open ( my $fh,"< $file" ) or die "$file went away!";
              while (<$fh>) {
                $lines++; 
                push( @data, $_);                            }
            close $fh;
             
            $file_cache{name} = $file;
            $file_cache{count} = $lines;
            $file_cache{array_ref} = \@data; 
            push( @cache, \{ name => $file, count => $lines, array_ref => \@data});
     }     
 $self->set( '_cache_ref', \@cache);
}

sub get_rows {
my $self = shift;
my $file = shift;
   foreach my $ref (@{$self->{_cache_ref}}) { 
    if ( ${$$ref}{name} eq $file ) {   
        return(${$$ref}{count});    
    }   
  }
} 

sub trim {
my $self = shift;
my $str = shift;
return(undef) if not defined($str);
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return( $str);
}

sub get_code_window {
my $self = shift;
my $file = shift;

my $lower_constraint = shift;
my $upper_constraint = shift;

   foreach my $ref (@{$self->{_cache_ref}}) { 
    if ( ${$$ref}{name} eq $file ) {   
        my @splice = @{${$$ref}{array_ref}}[$lower_constraint-1..$upper_constraint-1];
        return( \@splice);
    }
   }
}

sub dump_self {
my $self = shift;

print  '#######################################################################################################################',"\n";
print  '#######################################################################################################################',"\n";
print  '#######################################################################################################################',"\n";
foreach my $name (sort keys %$self) {   
   $$self{$name} = 'undefined' if !defined($$self{$name}); 
   printf "%-20s %s\n", $self->trim($name), $$self{$name};
}     
print  '#######################################################################################################################',"\n";
}

sub retreiving_data {
my $self = shift;



    if ( $self->{_direction} eq 'FWD' ) { 
	  if ( $self->{_first_read} eq 'TRUE' ) {
		$self->set( '_first_read', 'FALSE');
        return(1);  
       }	
	
            if ( $self->{_mw}->{_mod_end_seq}->get() <= int($self->{_index})+1) # error check  			
              {  
			  $self->set( '_first_read', 'TRUE');
			     if ( $self->{_repeat} eq 'YES' ) {
			       $self->{_index} = $self->{_mw}->{_mod_start_seq}->get()-1; 
				   return(1)
			     }
              $self->set( '_cur_exec_line', $self->{_index});
              $self->set_stopped_state; 

              return(0);
              }		  
              else { 
                   $self->set( '_index', $self->{_index}+1); 			   
                   return(1);
                   }	
    }


    if ( $self->{_direction} eq 'REV' ) {
  	        if ( $self->{_mw}->{_mod_start_seq}->get() >= int($self->{_index})+1) 	      
             {               
			     if ( $self->{_repeat} eq 'YES' ) {
    		        $self->{_index} = $self->{_mw}->{_mod_end_seq}->get()-1;
			        return(1)
			     }
             $self->set( '_cur_exec_line', $self->{_index});
             $self->set_stopped_state;  
             return(0);
             }		 
             else { 
                  $self->set( '_index', $self->{_index}-1); 
                  return(1);
                  }
    }
}

sub get_file_splice {
my $self = shift;
my $file = shift;
my $line = shift;
my ( $start_sequence, $end_sequence, $size, $array_ref);


    $size = $self->get_rows( $file);
 if ( $size <= $self->{_frame_window} ) {
    $start_sequence = 1;
    $end_sequence = $size;
    $self->set( '_file_splice', 'FULL' );
    $self->set( '_start_sequence', 1 );
    $self->set( '_end_sequence', $size );
    $self->set( '_offset', $start_sequence );
 }

 if ( $size > $self->{_frame_window} ) {
    
      $self->set( '_file_splice', 'PARTIAL' ); 
      $start_sequence = $line - int($self->{_frame_window}/2);
      if ( $start_sequence < 1 ) {
         $start_sequence = 1;
      }

      $end_sequence = $line + int($self->{_frame_window}/2)-1;    
      if ( $end_sequence > $size ) {
         $end_sequence = $size;
      } 

     $self->set( '_start_sequence', $start_sequence );
     $self->set( '_end_sequence', $end_sequence );
     $self->set( '_offset', $start_sequence );
 } 
 $array_ref = $self->get_code_window( $file, $start_sequence, $end_sequence );
 return( $array_ref);  
}

sub load_display {
my $self = shift;
my $array_ref = shift;
my $line = shift;
my $offset = shift;
my $table = shift;

my ($row ); 
       my $line_label=$offset;
       my $lno=1;

       # check that $array_ref is defined as and array reference
       # check subscript is availabale on table

       if ( ref $array_ref ne 'ARRAY' ) {
          print STDERR __LINE__ . ": not array reference skipping","\n";
          print STDERR "file: $self->{_file}","\n";
          return(0);
       }

       for $row (1..$self->{_frame_window}) {
       
         $self->{_label_hash_ref}->{"${row}_1"}->configure(-text   => '',-background => 'white');
         $self->{_label_hash_ref}->{"${row}_2"}->configure(-text   => '',-background => 'white');
         $self->{_label_hash_ref}->{"${row}_3"}->configure(-text   => '',-background => 'white');     
         
         $row++;
       }

       $row=1;
       foreach (@$array_ref) {
                   
        $self->{_label_hash_ref}->{"${row}_1"}->configure(-text => $self->{_executions_ref}->{$self->{ '_loaded_file' } . $line_label } );
        $self->{_label_hash_ref}->{"${row}_2"}->configure(-text => $line_label++);
        $self->{_label_hash_ref}->{"${row}_3"}->configure(-text => $self->trim($_));
        
        $lno++;
        $row++;    
       }
$array_ref = undef;
}

sub changed_window {
my $self = shift;

return(0) if ($self->{_file} ne $self->{_loaded_file} );

return(1) if ($self->{_line} < $self->{_start_sequence});
return(1) if ($self->{_line} > $self->{_end_sequence});
return(0); # default
}

sub valid_subscript {
my $self = shift;
my $sub_line = shift;
my $line_no = shift;

if ( ($sub_line < 1 or $sub_line >  $self->{_frame_window}) and ($self->{_screen_mode} ne 'load' and $self->{_screen_mode} ne 'update')) { 
   print STDERR "line: ", $line_no, " Invalid subscript, subscript $sub_line"," ","screen_mode=$self->{_screen_mode}","\n"; 
   return(0);
}

return(1);
}

sub highlight {
my $self = shift;
my $line = shift;
my $lastline = shift;
my $start_sequence = shift;
my $end_sequence = shift;
my $table = shift;
my $w;

# call twice
if ( defined( $lastline)) {
   return unless ($self->valid_subscript($lastline-$self->{_offset}+1, __LINE__));
}

if ( defined( $line)) {
   return unless ($self->valid_subscript($line-$self->{_offset}+1, __LINE__));
}

if ( defined($lastline) and $self->{_screen_mode} ne 'load') {
 $w = $table->get($lastline-$self->{_offset}+1, 1);
 $w->configure(-background => 'white') if (defined($w));
 $w = $table->get($lastline-$self->{_offset}+1, 2);
 $w->configure(-background => 'white') if (defined($w));
 $w = $table->get($lastline-$self->{_offset}+1, 3);
 $w->configure(-background => 'white') if (defined($w));
 
}

#---
#
# get executions
#
#---
my $exec_line = $table->get($line-$self->{_offset}+1, 1);
$exec_line->configure(-background => 'pink') if (defined($exec_line));
my $executions = $exec_line->cget('-text');

#---
#
# get line number for source file
#
#---

my $line_no = $table->get($line-$self->{_offset}+1, 2);
$line_no->configure(-background => 'pink') if (defined($line_no));     

my $line_number = $line_no->cget('-text');
       if ( ! defined($self->{_executions_ref}->{$self->{ '_loaded_file' } . $line_number }) ) { 
              $self->{_executions_ref}->{$self->{ '_loaded_file' } . $line_number }= 1;
          }
        else {
               $self->{_executions_ref}->{$self->{ '_loaded_file' } . $line_number }++;
             }
             
# update executions
$exec_line->configure(-text => $self->{_executions_ref}->{$self->{ '_loaded_file' } . $line_number });


my $code = $table->get($line-$self->{_offset}+1, 3);
$code->configure(-background => 'pink') if (defined($code));     

$table->see($line-$self->{_offset}+1, 1);
}

sub good_filename {
my $self = shift;
my $file = shift;

# attempts to recover distorted filenames
# should go here
#
if (($^O eq 'MSWin32') and ( $file =~ m{(\w{1}:([\\/]\w+)+(.pm|.pl)*|\w+.pl)}g )) {
    return(undef) unless defined($1);
      if ( -e $1) {
                   return($1);
                  }
}

if (($^O ne 'MSWin32') and ( $file =~ m{(([\\/]\w+)+(.pm|.pl)*|\w+.pl)}g )) {
    return(undef) unless defined($1);
      if ( -e $1) {
                   return($1);
                  }
}

return(undef)
}
       
sub update_table {
my $self = shift;
my $table = shift;  

    $self->{_mw}->update; 
    return if ($self->{_status} eq 'STOPPED');  
    return if ($self->{_status} eq 'INIT');  	
    return if (! $self->done_loading_meta_data()); 

    return unless $self->retreiving_data();
	
    $self->set( '_sequence', $self->trim( substr $self->{'_meta_ref'}[ $self->{'_index'}], 0, 6) );
    $self->set( '_file', substr $self->{'_meta_ref'}[ $self->{'_index'}], 6, 128);
    $self->set( '_line', $self->trim( substr $self->{'_meta_ref'}[ $self->{'_index'}], 134, 6) );
    $self->set( '_code', substr $self->{'_meta_ref'}[ $self->{'_index'}], 140, 80);
    $self->set( '_cur_srce_line', $self->{_line} );
    $self->set( '_cur_exec_line', $self->{_sequence} );
	
	my $dir_offset;
	if ( $self->{_direction} eq 'FWD' ) { $dir_offset = 2; }
	else                                { $dir_offset = 1; }
	
    $self->set( '_pct_complete',  $self->calculate_pct( $self->{_mw}->{_mod_start_seq}->get(), $self->{_mw}->{_mod_end_seq}->get(), $self->{'_index'}+$dir_offset) . ' %');

    $self->{_file} = $self->good_filename( $self->{_file} );
    return if ! defined($self->{_file});

    # ways for a new file to be loaded
    #  1. the display widget is currently empty and we have read the first meta record
    #  2. the current meta record has a different file then is presently loaded in the display
    #     how to load a new file
    #  1. if the file is smaller then the frame_window then the entire file is loaded
    #     into the display.
    #  2. if the file is larger then the frame_window the take the line_number 
    #     - frame_window/2 and line_number + frame_window/2 from the file and
    #     load that to the display

    if ( ! defined($self->{_loaded_file}) or ($self->{_file} ne $self->{_loaded_file} ) or ($self->{_status} eq 'INIT')) {
       $self->set( '_loaded_file', $self->{_file}); 
       my $file_splice_ref = $self->get_file_splice( $self->{_file}, $self->{_line});
       $self->set( '_file_splice_ref', $file_splice_ref );   
       $self->load_display(  $self->{_file_splice_ref}, $self->{_line}, $self->{_offset}, $self->{_table});
       $self->set( '_screen_mode', 'load'); 
	   $self->set( '_status', 'RUNNING');
    }
    # if it is not an initial file or new file, ccheck if the window parameters on
    # the file have changed ot normal SOP 
    elsif ( $self->changed_window() ) {
            $self->set( '_file_splice_ref', $self->get_file_splice( $self->{_file}, $self->{_line}) );   
            $self->load_display(  $self->{_file_splice_ref}, $self->{_line}, $self->{_offset}, $self->{_table});
            $self->set( '_screen_mode', 'update');       
          }

    $self->highlight($self->{_line}, $self->{_last_line}, $self->{_start_sequence}, $self->{_end_sequence}, $self->{_table});
    $self->set( '_last_line', $self->{_line});
    $self->set( '_screen_mode', 'static');

    if ( defined($ENV{ANI_DEBUG}) and $ENV{ANI_DEBUG} == 1 ) {  $self->dump_self(),"\n"; }
}

} # end of Devel
#-----------------------
#
#        M a i n
#
#-----------------------
my ( $obj );

$obj = new Devel(); 

# initialization
$obj->set( '_executions_ref', undef);
$obj->set( '_first_read', 'TRUE' );
$obj->set( '_filesize', 0);
$obj->set( '_mw', new MainWindow() );
$obj->set( '_screen_width', $obj->get_screen_width( $obj->{_mw} ) );
$obj->set( '_screen_height', $obj->get_screen_height() );
$obj->set( '_button_width', '10' );
$obj->set( '_direction', 'FWD' );
$obj->set( '_delay', '3000' );
$obj->set( '_frame_window', '200' );
$obj->set( '_table', undef );
$obj->set( '_loaded_file', undef );  
$obj->set( '_loaded', 0 );  
$obj->set( '_cur_srce_line', undef );
$obj->set( '_cur_exec_line', undef );
$obj->set( '_pct_complete', undef );
$obj->set( '_status', 'loading' );
$obj->set( '_status_bar', undef );
$obj->set( '_timer_id', undef );
$obj->set( '_index', -1 );
$obj->set( '_msg', 'please wait' );
$obj->set( '_label_hash_ref', undef );
$obj->set( '_last_line', undef);
$obj->set( '_animate', 'animate.pl');
$obj->set( '_bypass_file_ref', \() );


# I/O
$obj->set_stack_file;

# create display
$obj->{_mw}->geometry('+0+0');
$obj->{_mw}->maxsize($obj->{_screen_width},$obj->{_screen_height});
$obj->{_mw}->minsize($obj->{_screen_width},$obj->{_screen_height});
$obj->create_control();
$obj->create_table();
$obj->create_status_bar();
$obj->format_table ( $obj->{_table} );
$obj->{_timer_id} = $obj->{_mw}->repeat($obj->{_delay}, sub { $obj->update_table }, $obj->{_table});

MainLoop();

=head1 NAME

Devel::Animator - trace based source code animator

=head1 VERSION

Version 2.30

=cut

our $VERSION = '2.30';


=head1 SYNOPSIS

    perl -d:Animator program

          Animator takes as its input the animated programs trace output. i.e. that 
	 which you may get from running 'perl -d:Trace program' from Devel::Trace. Animation
	 of this trace presents the user with a highlighted line currently being executed.

=head1 DESCRIPTION

     exit {button}  - 
	   terminates application	 
	 stop {button}  - 
	   stops current animation
	 start {button} - 
	   start the animation process
	 reset {button} - 
	   restart the animation form the beginning
	 speed {drop down} - 
	   set the speed in milli-seconds for the animation
	 bypass a file {drop down} - 
	   bypass other files your program may call through require or use from animation
	 start sequence number {text field} - 
	   user editable field, contains start sequence record from trace file 
	   where you want to start animation.
	   
	   
	   
=head1 AUTHOR

Dennis Spera, C<< <asaag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel::animator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel::Animator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Animator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel::Animator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel::Animator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel::Animator>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel::Animator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Dennis Spera.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Devel::Animator
