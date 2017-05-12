##########################################################################
#
# $Id: CSVEADiff.pm,v 1.5 2006/09/17 19:28:42 pkaluski Exp $
# $Name: Stable_0_16 $
# 
# Object of this class compares a set of csv files with expectations.
#
# $Log: CSVEADiff.pm,v $
# Revision 1.5  2006/09/17 19:28:42  pkaluski
# Adjusted command line parameters for new key definitions. Adjusted to performance related changes in Collection class
#
# Revision 1.4  2006/09/10 18:18:17  pkaluski
# Converted from dos to Unix format
#
# Revision 1.3  2006/04/09 15:42:19  pkaluski
# Small code clean-up. Each module has comprehensive POD
#
#
###############################################################
package LRpt::CSVEADiff;

use strict;
use Getopt::Long;
use LRpt::RKeysRdr;
use XML::Simple;
use LRpt::Collection;
use LRpt::CollEADiff;
use File::Basename;

=head1 NAME

LRpt::CSVEADiff - A module for comparing a set of csv files with expectations

=head1 SYNOPSIS

  lcsveadiff.pl --keys_file=keys.txt --cmp_rules=cmp_rules.xml 
                --log_file=logfile.txt --expectations=exp.xml actual_dir 

=head1 DESCRIPTION

This module is a part of L<C<LRpt>|LRpt> (B<LReport>) library.
It is used to compare set of I<csv> files with expectations and 
report found differences.
You should not use C<LRpt::CSVEADiff> module directly in your code.
Instead you should use B<lcsveadiff.pl> tool, which is a simple wrapper
around the module. B<lcsveadiff.pl> looks like this:

  use strict;
  use LRpt::CSVEADiff;
  
  ea_diff( @ARGV );
  

=head1 COMMAND LINE OPTIONS

=over 4

=item --key=string

Row key defined in command line as one string. Don't use it. I will probably
get read of this switch in future

=item --keys_file=file

Name of the file containing row keys definitions

=item --cmp_rules=$cmp_rules

Name of a file containing comparing rules.

=item --log_file=$log_file

Name of a file to which log messages should be written

=item --expectations=$e_file

Name of a file containing expectations

=item --help

Prints help screen.

=item actual_dir

A file name or a directory containing I<actual> state.

=back

=cut

use vars qw( @EXPORT @ISA );
@ISA = qw( Exporter );
@EXPORT = qw( ea_diff );

my $rkeys_rdr = "";
my %actual_colls = ();
my %expected_colls = ();

=head1 METHODS

In this sections you will find a more or less complete listing of all
methods provided by the package. 

=cut

############################################################################

=head2 C<ea_diff>

  ea_diff( @ARGV );

Main function. @ARGV is processes by standard Getopt::Long module. Meaning 
of each switch is given in L<SYNOPSIS|"SYNOPSIS">.

=cut

#############################################################################
sub ea_diff
{
    local ( @ARGV ) = @_;
    my @key        = ();
    my @key_cols   = ();
    my $keys_file  = "";
    my $cmp_rules  = "";
    my $global_keys  = "";
    my $exp_file   = "";
    my $log_file   = "";
    my $help       = "";
    GetOptions( "key=s"      => \@key,
                "key_cols=s"  => \@key_cols,
                "keys_file=s" => \$keys_file,
                "global_keys" =>  \$global_keys,
                "cmp_rules=s"  => \$cmp_rules,
                "log_file=s"   => \$log_file,
                "expectations=s"  => \$exp_file,
                "help"         => \$help );

    if( $help ){
        print_usage();
    }

    $rkeys_rdr = LRpt::RKeysRdr->new( 'fname'    => $keys_file,
                                      'key'      => \@key,
                                      'key_cols' => \@key_cols,
                                      'global_keys' => $global_keys );
    load_csvs();
    load_expectations( $exp_file );
    compare( $cmp_rules, $log_file );
}    

############################################################################

=head2 C<load_expectations>

  load_expectations( $exp_file );

Loads expecations from the file C<$exp_file>.

=cut

#############################################################################
sub load_expectations
{
    my $exp_file = shift;
    my $exp = XMLin( $exp_file, 'forcearray' => [ 'row' ],
                                'keyattr' => []  );
    foreach my $select ( keys %$exp ){
        my @rows = ();
        foreach my $row ( @{ $exp->{ $select }->{ 'row' } } ){
            push( @rows, $row );
        }
        my $coll = LRpt::Collection->new_empty_copy( 
                      'src_coll' => $actual_colls{ $select },
                      'chunk_size' => 0 ); 
        $coll->adopt_rows( \@rows );
        $expected_colls{ $select } = $coll;
    }        
    return;
}    

############################################################################

=head2 C<load_csvs>

  load_csvs();

Loads all csvs, which names are given in a command line

=cut

#############################################################################
sub load_csvs
{
    my $file = "";
    my @files = ();
    if( !@ARGV ){
        die "CSV files names not given";
    }else{
        $file = shift( @ARGV );
        if( -d $file ){
            if( @ARGV ){
                die "When directory name given, other files " .
                    "must not be specified";
            }else{
                my $config = LRpt::Config->new();
                my $ext = $config->get_value( 'ext' );
                @files = glob( "$file/*.$ext" );
            }
        }else{
            while( $file = shift( @ARGV ) ){
                if( -f $file ){
                    die "No such file $file";
                }
                push( @files, $file );
            }
        }
    }
    my @act_colls = ();
    foreach $file ( @files ){
        push( @act_colls, load_csv_file( $file ) );
    }      
    %actual_colls = @act_colls;
    my $ref = \%actual_colls;
    return;
}


############################################################################

=head2 C<load_csv_file>

  load_csv_file();

Loads one csv file.

=cut

#############################################################################
sub load_csv_file
{
    my $file = shift;
    my $config = LRpt::Config->new();
    my $ext = $config->get_value( 'ext' );
    my $name = basename( $file );
    $name =~ s/\.$ext$//; 
    my $coll = "";
    my $rkey = "";
    if( $rkeys_rdr and $rkey = $rkeys_rdr->find_key( $name ) ){
        $coll = LRpt::Collection->new_from_csv( 'name'      => $name,
                                                'data_file' => $file,
                                                'key'       => $rkey,
                                                'chunk_size' => 0 );
    }
    return ( $name, $coll );
}

############################################################################

=head2 C<compare>

  compare( $cmp_rules_file, $log_file );

Compare loaded data with expectations.

=cut

#############################################################################
sub compare
{
    my $cmp_rules_file = shift;
    my $log_file = shift;
    my $rules = XMLin( $cmp_rules_file ); 
    print "<eadiff_report>\n";
    if( $log_file ){
        open( LOG_FILE, ">$log_file" ) or 
            die "Cannot open log file $log_file";
    }
    my %params = ( 'logger_stream' => *LOG_FILE );
    foreach my $name ( keys %actual_colls ){
        $params{ 'expected' }        = $expected_colls{ $name };
        $params{ 'actual' }          = $actual_colls{ $name };
        $params{ 'comparing_rules' } = $rules->{ $name };
        my $cdiff = LRpt::CollEADiff->new( %params );
        $cdiff->compare_collections(); 
        $cdiff->create_xml_report( 4 );
    } 
    print "</eadiff_report>\n";
    if( $log_file ){
        close( LOG_FILE ) or die "Cannot close log file $log_file";
    }
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
    print "             --rkeys=<string> --rkeys_file=<name>" .
          " --cmp_rules=<name> --log_file=<name> --expectations=<name>" . 
          " --help file_actual\n";
    print "\n";
    print "  --cmp_rules     - Name of a file containing comparing rules\n";
    print "  --expectations  - Name of a file containing expectations\n";
    print "  --help          - Prints this help screen\n";
    print "  --log_file      - Name of a log file\n";
    print "  --rkeys         - Command line row key definition. Don't use\n";
    print "  --rkeys_file    - Name of the file containing row keys " . 
                               "definitions\n";
    print "  file_actual     - A file name or a directory containing files\n" .
          "                    with actual state.\n";
    exit( 0 );
}

1;

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


