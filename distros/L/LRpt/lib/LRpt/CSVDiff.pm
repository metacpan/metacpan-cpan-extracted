###########################################################################
#
# $Id: CSVDiff.pm,v 1.5 2006/09/17 13:40:33 pkaluski Exp $
# $Name: Stable_0_16 $
#
# This is a tool for comparing 2 sets of csv files.
# 
# $Log: CSVDiff.pm,v $
# Revision 1.5  2006/09/17 13:40:33  pkaluski
# Keys can be given from command line. Skip columns can be given. Only files with proper extension are selected (feature 1544070)
#
# Revision 1.4  2006/09/10 18:04:12  pkaluski
# Implemented chunking.
#
# Revision 1.3  2006/04/09 15:42:19  pkaluski
# Small code clean-up. Each module has comprehensive POD
#
# Revision 1.2  2006/02/10 22:32:16  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.1  2006/01/14 12:52:33  pkaluski
# New tool design in progress
#
########################################################################### 
package LRpt::CSVDiff;
use strict;
use File::Find;
use Getopt::Long;
use File::Basename;
use LRpt::Collection;
use LRpt::CollDiff;
use LRpt::RKeysRdr;

=head1 NAME

LRpt::CSVDiff - A module for comparing 2 sets of csv files

=head1 SYNOPSIS

  lcsvdiff.pl --all --keys_file=rkeys.txt --chunk_size=num before_dir after_dir 

=head1 DESCRIPTION

This module is a part of L<C<LRpt>|LRpt> (B<LReport>) library.
It is used to compare 2 sets of I<csv> files and report found differences.
You should not use C<LRpt::CSVDiff> module directly in your code.
Instead you should use B<lcsvdiff.pl> tool, which is a simple wrapper
around the module. B<lcsvdiff.pl> looks like this:

  use LRpt::CSVDiff;
  use strict;
  
  diff( @ARGV );
  

=head1 COMMAND LINE OPTIONS

=over 4

=item --all

If set, not only differences are reported, but all rows from both rowsets.

=item --key=string

Row key defined in command line as one string. Don't use it. I will probably
get read of this switch in future

=item --keys_file=file

Name of the file containing row keys definitions

=item --chunk_size=num

Number of rows retrieved in one chunk. If not defined - default chunking size
is used. If equal to zero, than no chunking is used (all rows are loaded
to memory

=item --help

Prints help screen.

=item before_dir

A file name or a directory containing files with I<before> state.

=item after_dir

A file name or a directory containing files with I<after> state.

=back

=cut

use vars qw( @EXPORT @ISA );
@ISA = qw( Exporter );
@EXPORT = qw( diff );

#
# Reader of row keys
#
our $rkeys_rdr = "";

our %skip_cols = ();
#
# Command line options 
#

#
# Switch deciding what to print on the difference report. 
#
our $print_all = "";

=head1 METHODS

In this sections you will find a more or less complete listing of all
methods provided by the package. 

=cut

############################################################################

=head2 C<diff>

  diff( @ARGV );

Main function. @ARGV is processed by standard Getopt::Long module.
Switches have the following meaning (see L<SYNOPSIS|"SYNOPSIS">.

=over 4

=item --all

If set, not only differences are reported, but all rows from both rowsets.

=item --key=string

Row key defined in command line as one string. Don't use it. I will probably
get read of this switch in future

=item --keys_file=file

Name of the file containing row keys definitions

=item --chunk_size=num

Number of rows retrieved in one chunk. If not defined - default chunking size
is used. If equal to zero, than no chunking is used (all rows are loaded
to memory

=item before_dir

A file name or a directory containing files with I<before> state.

=item after_dir

A file name of a directory containing files with I<after> state.

=back

=cut

##########################################################################
sub diff
{
    my ( $ext, $path, $sep, $chunk_size, $keys_file, $global_keys );
    my $skip_cols_file;
    local ( @ARGV ) = @_;
    my $help = "";
    my @key      = ();
    my @key_cols = ();
    my $skip_cols_string;

    GetOptions( "ext=s"       => \$ext,
                "path=s"      => \$path,
                "sep=s"       => \$sep,
                "key=s"      => \@key,
                "key_cols=s"  => \@key_cols,
                "keys_file=s" => \$keys_file,
                "skip_cols=s"  => \$skip_cols_string,
                "skip_cols_file=s"  => \$skip_cols_file,
                "all" =>          \$print_all,
                "global_keys" =>  \$global_keys,
                "chunk_size=s" => \$chunk_size,
                "help" =>         \$help );

    if( $print_all ){
        $print_all = 'all';
    }

    if( $help ){
        print_usage();
    }

    my $config = LRpt::Config->new( 'ext'       => $ext,
                                    'path'      => $path,
                                    'sep'       => $sep,
                                    'chunk_size' => $chunk_size );

    $rkeys_rdr = LRpt::RKeysRdr->new( 'fname'    => $keys_file,
                                      'key'      => \@key,
                                      'key_cols' => \@key_cols,
                                      'global_keys' => $global_keys );

    parse_skip_cols( $skip_cols_string, $skip_cols_file ); 
    my $file1 = shift( @ARGV );
    my $file2 = shift( @ARGV );

    compare( $file1, $file2 );
}

sub parse_skip_cols
{
    my $skip_cols_string = shift;
    my $skip_cols_file   = shift;

    $skip_cols{ 'default' } = {};
    my @skip_strings = ();
    if( $skip_cols_string ){
        @skip_strings = split( /,/, $skip_cols_string );
        my $def_ref = $skip_cols{ 'default' };
        @$def_ref{ @skip_strings } = 1;
    }

    if( $skip_cols_file ){
        my @skip_cols_rules = ( { 'name' => 'select_name' },
                                { 'name' => 'columns' } );
        open( SKIPS, "<$skip_cols_file" ) or 
                       die "Cannot open '$skip_cols_file' : $!"; 
        my $jr = LRpt::JarReader->new( 
                      'rules' => \@skip_cols_rules, 'filehandle' => *SKIPS ); 
        $jr->read_all();
        my @selects = $jr->get_all_values_of( 'select_name' );

        foreach my $select ( @selects ){
            my $sect = $jr->get_section_with( 'select_name' => $select );
            my @selects_in_entry = split( /\s*,\s*/, $select );
            foreach my $s ( @selects_in_entry ){
                my %skips = ();
                @skips{ @skip_strings } = 1;
                @skips{ split( /\s*,\s*/, $sect->{ 'columns' } ) } = 1;
                $skip_cols{ $s } = \%skips; 
            }
        }
        close( SKIPS ) or die "Cannot close $skip_cols_file";
    }

}
    
        

######################################################################

=head2 C<compare>

  compare( $st1_file, $st2_file );

Compares 2 files. If one or two of given filenames are actually directory
names then diff behavior is mimiced.

=cut

########################################################################
sub compare
{
    my $st1_file = shift;
    my $st2_file = shift;
    my %st1_files = ();
    my %st2_files = ();

    $st1_file =~ s/\\/\//g; # If using windows backslashes, convert them to
                            # slashes
    $st2_file =~ s/\\/\//g;
    #  
    # If both arguments are regular files... 
    #
    if( -f $st1_file and -f $st2_file ){
        compare_two_files( $st1_file, $st2_file );
        return;
    }

    #  
    # If one file is actually a directory... 
    #
    if( -f $st1_file and -d $st2_file ){
        compare_two_files( $st1_file, "$st2_file/$st1_file", 1 );
        return;
    }
    if( -d $st1_file and -f $st2_file ){
        compare_two_files( $st2_file, "$st1_file/$st2_file", 1 );
        return;
    }

    #
    # OK. Both arguments are directories. We have to scan those directories
    #
    my $config = LRpt::Config->new();
    my $ext = $config->get_value( 'ext' );
    find( sub { 
              if( $File::Find::name eq $st1_file ){
                  return;
              }
              if( not ( $File::Find::name =~ /\.$ext$/ ) ){
                  return;
              }
              my $cmp_path = $File::Find::name;
              $cmp_path =~ s/^$st1_file\///;
              $st1_files{ $cmp_path } = 1; 
          }, 
          $st1_file );

    find( sub { 
              if( $File::Find::name eq $st2_file ){
                  return;
              }
              if( not ( $File::Find::name =~ /\.$ext$/ ) ){
                  return;
              }
              my $cmp_path = $File::Find::name;
              $cmp_path =~ s/^$st2_file\///;
              $st2_files{ $cmp_path } = 1; 
          }, 
          $st2_file );


    my %all_files = ();
    @all_files{ keys %st1_files } = 1;
    @all_files{ keys %st2_files } = 1;

    #
    # At that stage %all_files contains a sum of all files from st1 and st2
    # directories. Names of those files are keys in the hash.
    #

    foreach my $file ( keys %all_files ){
        if( not -e "$st1_file/$file" ){
            print "$file only in $st2_file\n";
            next;
        }
        if( not -e "$st2_file/$file" ){
            print "$file only in $st1_file\n";
            next;
        }
        if( -d "$st1_file/$file" and !( -d "$st2_file/$file" ) ){
            print "$st1_file/$file is a directory, " . 
                  "$st2_file/$file is a regular file\n";
            next;
        }
        if( -d "$st2_file/$file" and !( -d "$st1_file/$file" ) ){
            print "$st1_file/$file is a regular file, " . 
                  "$st2_file/$file is a directory\n";
            next;
        }
        if( -d "$st1_file/$file" and -d "$st2_file/$file" ){
            next;
        }
        if( -f "$st1_file/$file" and -f "$st2_file/$file" ){
            compare_two_files( "$st1_file/$file" , "$st2_file/$file", 1 );
            next;
        }
    }
}

######################################################################

=head2 C<compare_two_files>

  compare_two_files( $file1, $file2 );

Performs row/column oriented comparison between 2 files 

=cut

######################################################################
sub compare_two_files
{
    my $file1 = shift;
    my $file2 = shift;
    my $print_header = shift;

    my $config = LRpt::Config->new();
    my $ext = $config->get_value( 'ext' );

    my $name = basename( $file1 );
    $name =~ s/\.$ext$//; 
    my $rkey = $rkeys_rdr->find_key( $name );
    
    my $header = undef;
    if( $print_header ){
        $header = "lcsvdiff";
    }
    
    my $coll_skip_cols;
    if( exists $skip_cols{ $name } ){
        $coll_skip_cols = $skip_cols{ $name };
    }else{
        $coll_skip_cols = $skip_cols{ 'default' }
    }  
    my $coll1 = LRpt::Collection->new_from_csv( 'name' => 'coll',
                                                'data_file' => $file1,
                                                'key' => $rkey  );
    my $coll2 = LRpt::Collection->new_from_csv( 'name' => 'coll', 
                                                'data_file' => $file2,
                                                'key' => $rkey  );
    my $cd = LRpt::CollDiff->new( 'before' => $coll1,
                                  'after'  => $coll2,
                                  'skip_cols' => $coll_skip_cols );
    $cd->compare_collections( $print_all, $header );
}

######################################################################

=head2 C<print_usage>

  print_usage();

Prints usage text.

=cut

######################################################################
sub print_usage
{
    print "Usage:  $0 --help \n";
    print "             --key=<string> --keys_file=<name>" .
          " --all file_before file_after\n";
    print "\n";
    print "  --all           - Prints not only differences but also\n";
    print "                    all rows\n";
    print "  --help          - prints this help screen\n";
    print "  --key           - Command line row key definition. Don't use\n";
    print "  --keys_file     - Name of the file containing row keys " . 
                               "definitions\n";
    print "  --chunk_size    - Number of rows retrieved in one chunk. \n";
    print "                    If not defined - default chunking size is \n";
    print "                    used. If equal to zero, than no chunking is\n";
    print "                    used (all rows are loaded to memory\n";
    print "  file_before     - A file name or a directory containing files\n" .
          "                    with before state.\n";
    print "  file_after      - A file name or a directory containing files\n" .
          "                    with after state.\n";
    exit( 0 );
}

=head1 SEE ALSO

The project is maintained on Source Forge L<http://lreport.sourceforge.net>. 
You can find there links to some helpful documentation like tutorial.

=head1 AUTHORS

Piotr Kaluski E<lt>pkaluski@piotrkaluski.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2006 Piotr Kaluski. Poland. All rights reserved.

You may distribute under the terms of either the GNU General Public License 
or the Artistic License, as specified in the Perl README file. 

=cut

1;

