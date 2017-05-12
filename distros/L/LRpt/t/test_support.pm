###########################################################################
#
# $Id: test_support.pm,v 1.4 2006/09/17 07:59:57 pkaluski Exp $
# $Name: Stable_0_16 $
#
# This is a bunch of functions which are handy during runing test suite
#
# $Log: test_support.pm,v $
# Revision 1.4  2006/09/17 07:59:57  pkaluski
# Added tests for new command line switches and environment variables
#
# Revision 1.3  2005/10/01 22:54:16  pkaluski
# Added selective comparison of RTF files
#
# Revision 1.2  2004/10/15 21:51:11  pkaluski
# Added test case for logging when comparing with expecations. Fixed some bugs.
#
# Revision 1.1.1.1  2004/10/02 11:31:05  pkaluski
# Changed the naming convention. All packages start with LRpt
#
#
#
###########################################################################
package test_support;
use strict;
use File::Basename;
use File::Compare;
use File::Find;
use Cwd;

$test_support::test_dir = "";

sub store_test_dir
{
    $test_support::test_dir = getcwd() . "/t";
}

sub get_test_dir
{
    return $test_support::test_dir;
}


###########################################################################
# File comparison, with removing time stamps from the lines (because they
# are always different) 
#
###########################################################################
sub compare_logs
{
    my $file1 = shift;
    my $file2 = shift;

    my @lines1 = ();
    my @lines2 = ();

    open( FILE1, "<$file1" ) or die "Cannot open $file1 : $!";
    while( <FILE1> ){
        s/^\w+\s+\w+\s+\w+\s+\S+\s+\d+-->//; #Get rid of the timestamp from 
                                             #the line
        push( @lines1, $_ );
    }
    close( FILE1 ) or die "Cannot close $file1 : $!";
    open( FILE2, "<$file2" ) or die "Cannot open $file2 : $!";
    while( <FILE2> ){
        s/^\w+\s+\w+\s+\w+\s+\S+\s+\d+-->//; #Get rid of the timestamp from 
                                             #the line
        push( @lines2, $_ );
    }
    close( FILE2 ) or die "Cannot close $file2 : $!";

    if( @lines1 != @lines2 ){
        print STDERR "Number of lines in actual log is diffent from expected\n";
        return 0;
    }
    for( my $i = 0; $i < @lines1; $i++ ){
        if( $lines1[ $i ] ne $lines2[ $i ] ){
            print STDERR "Lines in actual log are different from expected\n";
            return 0;
        }
    }
    return 1;
}
        
    

###########################################################################
# Compares 2 directory structures
#
###########################################################################
sub compare_dirs 
{
    my $exp_dir = shift;
    my $act_dir = shift;
    my $excluded = shift;
    my %exp_files = ();
    my %act_files = ();
    
    my %excluded_files = ();
    if( $excluded ){
        @excluded_files{ @$excluded } = 1;
    }

    find( sub { 
              if( $File::Find::name eq $exp_dir ){
                  return;
              }
              my $cmp_path = $File::Find::name;
              $cmp_path =~ s/^$exp_dir\///;
              $exp_files{ $cmp_path } = 1; 
          }, 
          $exp_dir );

    find( sub { 
              if( $File::Find::name eq $act_dir ){
                  return;
              }
              my $cmp_path = $File::Find::name;
              $cmp_path =~ s/^$act_dir\///;
              $act_files{ $cmp_path } = 1; 
          }, 
          $act_dir );

    my %all_files = ();
    @all_files{ keys %exp_files } = 1;
    @all_files{ keys %act_files } = 1;

    foreach my $file ( keys %all_files ){
        if( $file =~ /\bCVS\b/ ){
            next;
        }
        if( exists $excluded_files{ $file } ){
            next;
        }
        if( -d "$exp_dir/$file" and !( -d "$act_dir/$file" ) ){
            print STDERR "# Failed comparing $exp_dir/$file with ".
                         "$act_dir/$file\n";
            return 0;
        }
        if( -d "$act_dir/$file" and !( -d "$exp_dir/$file" ) ){
            print STDERR "# Failed comparing $exp_dir/$file with ".
                         "$act_dir/$file\n";
            return 0;
        }
        if( -d "$act_dir/$file" and -d "$exp_dir/$file" ){
            next;
        }
            
        if( $file =~ /\.rtf$/ ){
            if( compare_rtf( "$exp_dir/$file", "$act_dir/$file" ) ){
                print STDERR "# Failed comparing $exp_dir/$file with ".
                             "$act_dir/$file\n";
                return 0;
            }
        }elsif( compare( "$exp_dir/$file", "$act_dir/$file" ) ){
            print STDERR "# Failed comparing $exp_dir/$file with ".
                         "$act_dir/$file\n";
            return 0;
        }
    }
    print "\n";
    return 1;
}

###########################################################################
# Compares 2 rtf files, skiping some lines in compared files.
#
###########################################################################
sub compare_rtf
{
    my $file1 = shift;
    my $file2 = shift;

    open( FILE1, "<$file1" ) or die "Cannot open $file1 for comparing: $!"; 
    open( FILE2, "<$file2" ) or die "Cannot open $file2 for comparing: $!"; 
    my $result = 0;
    while( <FILE1> ){
        my $line2 = <FILE2>;
        if( /\{\\doccomm/ ){
            next;
        }
        if( $_ ne $line2 ){
            print STDERR "# Failed comparing RTFs\n";
            $result = 1;
            last;
        }
    }
    close( FILE1 ) or die "Cannot close $file1 : $!"; 
    close( FILE2 ) or die "Cannot close $file2 : $!"; 
    return $result;
}

sub redirect_stdout
{
    my $file = shift;
    open(OLDOUT, ">&STDOUT");

    # redirect stdout and stderr
    open(STDOUT, "> $file")  or die "Can't redirect stdout to $file: $!";
}

sub restore_stdout
{
    close( STDOUT );
    open( STDOUT, ">&OLDOUT")            or die "Can't restore stdout: $!";

    # avoid leaks by closing the independent copies
    close( OLDOUT )                       or die "Can't close OLDOUT: $!";
}
        
1; 
