package LEOCHARRE::CLI2;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %OPT @OPT_KEYS $OPT_STRING %ARGV);
use Exporter;
use Carp;
use Cwd;
use strict;
use Getopt::Std;
no warnings;

my @export_argv = qw/argv_files argv_files_count argv_dirs argv_dirs_count argv_cwd/;
@ISA = qw(Exporter);
@EXPORT_OK = ( qw/yn sq cwd abs_path slurp burp opt_selected user_exists/, @export_argv );
%EXPORT_TAGS = ( argv => \@export_argv, all => \@EXPORT_OK, );
$VERSION = sprintf "%d.%02d", q$Revision: 1.16 $ =~ /(\d+)/g;

#use Smart::Comments '###';
use String::ShellQuote;
use YAML;

*sq = \&String::ShellQuote::shell_quote;
*abs_path = \&Cwd::abs_path;
*cwd = \&Cwd::cwd;


sub user_exists {
   my $uname = shift;
   $uname=~/\w+/ or Carp::cluck("missing user argument") and return;
   ( system('id', $uname ) == 0) ? 1 : 0
}

sub opt_selected {

   if (@_){ # then we want to check that every one of thse and no more are selected
      my %want;
      @want{@_} =();
      for ( keys %OPT ){
         if( defined $OPT{$_} ){
            exists $want{$_} or return; # then one is set which we did not ask for
            $want{$_}++;
         }
      }
      for (keys %want){ # make sure they have all been seen as set
         $want{$_} or return;
      }
      return 1;
   }

   my @selected;
   for(keys %OPT){
      defined $OPT{$_} and push @selected, $_;
   }
   @selected or return;
   wantarray ? (@selected) : [@selected];
}

sub slurp {
   my $abs = shift;
   -f $abs or Carp::cluck("Not on disk '$abs'") and return;


   open( FILE, '<', $abs ) or warn("Could not open for reading '$abs', $!") and return;

   if (wantarray){
      my @lines = <FILE>;
      close FILE;
      @lines and scalar @lines or return _empty();
      return @lines;
   }

   else {

      local $/;
      my $txt = <FILE>;
      close FILE;
      (length $txt) or return _empty();
      $txt;
   }

   sub _empty { Carp::cluck("Nothing inside :'$abs' ?"); return; }
}

sub burp {
   my $abs = shift;
   my $content = shift;
   defined $content or Carp::cluck("No content arg provided") and return;
   open( FILE,'>', $abs) or warn("Could not open for writing '$abs', $!") and return;
   print FILE $content;
   close FILE;
   $abs;
}

sub import {
   my $class = shift;

   # find the opt string
   import_resolve_opt_string(\@_);
   import_make_opts();
   
   _init_env_ext();


   no strict 'refs';
   main->can('debug') or *{'main::debug'} = \&debug;
   main->can('usage') or *{'main::usage'} = \&usage;
   ### @_

   __PACKAGE__->export_to_level(1, ( $class, @_));
}


sub import_resolve_opt_string {
   ### finding opt string..   
   my $import_list = shift;

   my @changed_list;
   
   for my $arg ( @$import_list ){
      ### testing arg -----------------
      ### $arg

     # if arg is between brackers, it is a definition for parent package
      if ($arg=~/^\[(.+)\]$/){
         $ENV{SCRIPT_PARENT_PACKAGE} = $1;
         next;
      }

      # if arg is between parens, it is a definition for what man page to look up more in
      if ($arg=~/^\((.+)\)$/){
         
         $ENV{SCRIPT_MAN} = $1;
         next;
      }

      # if the arg has spaces, it is deemed as the SCRIPT_DESCRIPTION    
      if ($arg=~/ /){
         $ENV{SCRIPT_DESCRIPTION} = $arg;
         next;
      }


      my $tag = $arg;
      $tag=~s/^\://;
      
      if( __PACKAGE__->can($arg) or $EXPORT_TAGS{$tag} ){          
         ### arg is a sub or export tag:
         ### $arg
         push @changed_list, $arg; 
         next;
      }
      ### arg is not a sub or export tag


             
      #$opt_string and die("bad args? cant have $arg as export arg?");
      $OPT_STRING = $arg;      
      ### $OPT_STRING
   }

   # replace the import list
   @$import_list = @changed_list;

   # note that this does NOT replace the list: 
   # $import_list = \@changed_list
   # it just changes the reference! ;-)


   ### $import_list

   
   
}

sub _init_env_ext {

   $0=~/([^\/]+)$/;
   $ENV{SCRIPT_FILENAME} = $1;

}


sub import_make_opts {
   
   for my $l ( qw/h d/ ){ # took out v version, won't work
      $OPT_STRING=~/$l/ or $OPT_STRING.=$l;
   }


   no strict 'refs';   
   *{'main::OPT'}  = \%OPT;
   *{'main::OPT_STRING'}  = \$OPT_STRING;


   require Getopt::Std;
   Getopt::Std::getopts($OPT_STRING, \%OPT);   
   
   my $_opt_string = $OPT_STRING;
   $_opt_string=~s/\W//g;
   @OPT_KEYS = split(//, $_opt_string);
   ## @OPT_KEYS
   
   # make variables
   for my $opt_key (@OPT_KEYS){
      *{"main\::opt_$opt_key"} = \$OPT{$opt_key};
   }

   

}




# ARGV ----- begin
sub _argv {
   defined %ARGV or _init_argv();
   if (my $key = shift){
      return $ARGV{$key};
   }
   \%ARGV;
}
      
sub _init_argv { 

   my @_argv;
   my(@files,$files_count, @dirs, $dirs_count);

   ### -------------------------------- init argv paths
   for my $arg ( @ARGV ){   
      defined $arg or next;
      ### testing for disk arg
      ### $arg
      
      my ($isf, $isd) = ( -f $arg, -d $arg );

      unless( $isf or $isd ){

         ### arg -f/-d no         
         push @_argv, $arg; # leave alone
         next;
      }

      
      my $abs = Cwd::abs_path($arg);

      $isf and (push @files, $abs) and next;
      push @dirs, $abs;
   }

   if( $ARGV{DIRS_COUNT} = ( (scalar @dirs)  || 0 ) ){
      $ARGV{DIRS} = \@dirs;
      $ARGV{CWD} = $dirs[0];   
   }
   else {
      $ARGV{CWD}= Cwd::abs_path('./');
   }

   if( $ARGV{FILES_COUNT} = ( (scalar @files) || 0 ) ){
      $ARGV{FILES} = \@files;
   }

   ### %ARGV

   
   @ARGV = @_argv;
}


sub argv_files { _argv('FILES') or return; @{_argv('FILES')} }
sub argv_files_count { _argv('FILES_COUNT') }
sub argv_dirs { _argv('DIRS') or return; @{_argv('DIRS')} }
sub argv_dirs_count { _argv('DIRS_COUNT') }
sub argv_cwd { _argv('CWD') }
   

# end argv------------




INIT {
   ### LEOCHARRE CLI2 INIT
   $main::opt_h 
      and print STDERR &main::usage 
      and exit;
}


sub debug { $main::opt_d and warn(" # $ENV{SCRIPT_FILENAME}, @_\n"); 1 }


sub yn {
        my $question = shift; 
        $question ||='Your answer? ';
        my $val = undef;
        until (defined $val){
                print "$question (y/n): ";
                $val = <STDIN>;
                chomp $val;
                if ($val eq 'y'){ $val = 1; }
                elsif ($val eq 'n'){ $val = 0;}
                else { $val = undef; }
        }
        return $val;
}


# auto generated usage
sub usage {

   my $script_name = $ENV{SCRIPT_FILENAME};
   my $script_description = $ENV{SCRIPT_DESCRIPTION};
   my $script_man = $ENV{SCRIPT_MAN};
   my $script_also = $ENV{SCRIPT_PARENT_PACKAGE};

   my $script_version = $main::VERSION;

   $script_version and ($script_version=" v $script_version");
   
   $script_description and $script_description=~s/\n*$/\n/;
   
   if( $script_man ){   
      unless( $script_man=~/man /){
         $script_man = "\nTry 'man $script_man' for more info.\n";
      }
   }

   if( $script_also ){      
      $script_also = "\n$script_also - parent package\n";
   }



   my $out = "$script_name [OPTION]...\n$script_description\n";

   
   for my $opt ( sort keys %OPT ){
      my $desc = 
         $opt eq 'h' ? 'help' :
         $opt eq 'd' ? 'debug' : undef;

      my $argtype;
      if (!$desc){         
         # does it take an arg?
         if ($main::OPT_STRING=~/$opt\:/){
            $desc=undef;
            $argtype='string';
         }
      }
      no warnings;
      $out.= sprintf "%6s %-10s %s\n",
         "-$opt", $argtype, $desc;
   }

   "$out\n$script_man$script_also";
}





1;


__END__


   use LEOCHARRE::CLI2 'o:p:t', 'help','version';
