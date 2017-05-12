###########################################################################
#
# $Id: CSVDumper.pm,v 1.4 2006/09/17 13:43:52 pkaluski Exp $
# $Name: Stable_0_16 $
#
# This is a tool for dumping select results to csv files.
# 
# $Log: CSVDumper.pm,v $
# Revision 1.4  2006/09/17 13:43:52  pkaluski
# Refinement of POD. Added ability to read connection file givenin environment variable
#
# Revision 1.3  2006/09/10 18:16:12  pkaluski
# Added chunking. Selects are read from files or standard input (like in diamond operator.
#
# Revision 1.2  2006/02/10 22:32:16  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.1  2006/01/01 13:13:49  pkaluski
# Initial revision. Works.
#
#
########################################################################### 
package LRpt::CSVDumper;
use Getopt::Long;
use DBI;
use LRpt::JarReader;
use LRpt::Config;
use LRpt::Collection;
use strict;

use vars qw( @EXPORT @ISA );
@ISA = qw( Exporter );
@EXPORT = qw( dump_selects );


#
# I reference to an opened DBI connection
#
our $dbh_opened   = "";

#
# Initialization data for LRpt::JarReader
#
our @sel_rules = ( { 'name' => 'name' },
                  { 'name' => 'select' } );

=head1 NAME

LRpt::CSVDumper - LReport csv dumper. Dumps results of selects to csv files.

=head1 SYNOPSIS

  lcsvdmp.pl selects.txt

  lcsvdmp.pl --ext=dat --path=data --sep=";" --conn_file=connection.txt --chunk_size=num selects.txt

=head1 DESCRIPTION

This module is a part of L<C<LRpt>|LRpt> (B<LReport>) library.
You should not use C<LRpt::CSVDumper> module directly in your code.
Instead you should use B<lcsvdmp.pl> tool, which is a simple wrapper
around the module. B<lcsvdmp.pl> looks like this:

  use strict;
  use LRpt::CSVDumper;
  
  dump_selects( @ARGV );
  

B<lcsvdmp.pl> is a program for dumping results of a group of selects
to a group of csv files. Each select has its own file. Each file contains 
a header row, which contains names of all columns returned 
by a select and then all rows with the data.
It connects to a database via connection file,
which is expected to contain a perl code opening a connection to a database.
See section L</DATABASE CONNECTION FILE> for details.

Selects to be executed can be given either on standard input or in a file.
See L</SELECTS DEFINITION> for details.

=head1 COMMAND LINE OPTIONS

=over 4

=item C<--ext>

Extension of csv files created. Default is "txt"

=item C<--path>

Path in which csv files are to be created. Default is a current directory

=item C<--sep>

Fields separator in csv files. Default is tab

=item C<--conn_file>

Path to a database connection file. Default is C<conn_file.txt>.

=item C<--help>

Prints help screen

=item C<--chunk_size>

Number of rows retrieved in one chunk. If not defined - default chunking size
is used. If equal to zero, than no chunking is used (all rows are loaded
to memory

=item C<selects.txt>

File with selects to be executed.

=back

=head1 METHODS

In this sections you will find a more or less complete listing of all
methods provided by the package. 

=cut

########################################################################

=head2 C<dump_selects>

  dump_selects( @ARGV );

Equivalent of a 'main' function. For meaning of parameters see
L<COMMAND LINE OPTIONS|"COMMAND LINE OPTIONS">.

=cut

########################################################################
sub dump_selects
{
    local ( @ARGV ) = @_;
    set_params();
    run_selects();
} 

########################################################################

=head2 C<set_params>

  set_params();

Parses command line parameters, checks environmental variables to gather
all parameters needed to process.

=cut

########################################################################
sub set_params
{
    my $ext       = "";
    my $path      = "";
    my $sep       = "";
    my $conn_file = "";
    my $help      = "";
    my $chunk_size = undef;

    GetOptions( "ext=s"       => \$ext,
                "path=s"      => \$path,
                "sep=s"       => \$sep,
                "conn_file=s" => \$conn_file,
                "chunk_size=s"   => \$chunk_size,
                "help"        => \$help );

    if( $help ){
        print_usage();
    }
    my $config = LRpt::Config->new( 'ext'       => $ext,
                                    'path'      => $path,
                                    'sep'       => $sep,
                                    'conn_file' => $conn_file,
                                    'chunk_size' => $chunk_size );
    open_db_connection();
} 

########################################################################

=head2 C<open_db_connection>

  open_db_connection()

Opens a database connection. Loads a connection file and evals it.

=cut

########################################################################
sub open_db_connection
{
    my $config = LRpt::Config->new();
    my $conn_file = "conn_file.txt";
    if( not -e $conn_file ){
        $conn_file = $config->get_value( 'conn_file' );
    }
    my $dbh = "";
    open( CONFILE, "< " . $conn_file ) or 
        die "Cannot open $conn_file : $!";
    my @lines = <CONFILE>;
    my $conn_str = join( "", @lines );
    eval $conn_str;
    if( $@ ){
        die "$@";
    }
    $dbh_opened = $dbh;
    close( CONFILE ) or 
        die "Cannot close $conn_file : $!";
}    

########################################################################

=head2 C<run_selects>

  run_selects();

Run each select and dumps data to output file for each of them.

=cut

########################################################################
sub run_selects
{
    my $path = shift;

    my $config   = LRpt::Config->new();
    my $chunk_size = $config->get_value( 'chunk_size' );

    if( !$path ){
        $path = $config->get_value( 'path' );
    }
    my $ext = $config->get_value( 'ext' );
    my $sep = $config->get_value( 'sep' );

    unshift(@ARGV, '-') unless @ARGV; 
    while( my $file = shift( @ARGV ) ){
        open( SEL_FILE, "< $file" ) or die "Cannot open $file for reading: $!";
        my $select_jr = LRpt::JarReader->new( 'rules'    => \@sel_rules,
                                              'filehandle' => *SEL_FILE );
    
        $select_jr->read_all(); 

        my @sel_names = $select_jr->get_all_values_of( 'name' );
        foreach my $sel ( @sel_names ){
            my $section = $select_jr->get_section_with( 'name' => $sel );
            my $select = $section->{ 'select' };
            my $sth = "";
            eval{
                $sth = $dbh_opened->prepare( $select );
                $sth->execute();
            };
            if( $@ ){
                die "Database error while executing query '$select'\n" .
                    "$@\n";
            }
            open( OUTFILE, ">$path/$sel.$ext" ) or
                die "Cannot open $path/$sel.$ext : $!";  
            my $rows = []; 
            print OUTFILE "" . join( $sep, @{ $sth->{ 'NAME' } } ) . "\n";
            while( my $row = 
                     ( 
                      shift( @$rows ) || # get row from cache, or reload cache:
                      shift( @{ $rows = $sth->fetchall_arrayref(undef, $chunk_size) ||
                               [] } 
                           )
                     )     
                 )
            {
                print OUTFILE "" . join( $sep, @$row ) . "\n";
            }
            close( OUTFILE ) or die "Cannot close $path/$sel.$ext : $!"; 
            print "name: $sel\n";
            print "select: $section->{ 'select' }\n";
            print "results: " . $config->get_value( 'path' ) . "/" .
                  $sel . "." . $config->get_value( 'ext' ) . "\n";
            print "%%\n";
        }
        close( SEL_FILE ) or die "Cannot close $file : $!"; 
    }
}

########################################################################

=head2 C<print_usage>

  print_usage();

Prints usage text

=cut

###########################################################################
sub print_usage
{
    print "Usage:  $0 [--help] [--ext=<name>] [--path=<name>]";
    print " [--sep=<name>] [--conn_file=<name>] [--chunk_size=size]";
    print " filenames\n";
    print "\n";
    print "  --conn_file     - name of a database connection file.\n";
    print "                    Default is conn_file.txt\n";
    print "  --ext           - extension given to csv files\n";
    print "                    Default is txt\n";
    print "  --help          - prints this help screen\n";
    print "  --path          - directory in which csv files should be ";
    print "created.\n";  
    print "                    Default is a current directory\n";
    print "  --sep           - Field separator in generated csv files.\n";
    print "                    Default is tab\n";
    print "  --chunk_size    - Number of rows retrieved in one chunk. \n";
    print "                    If not defined - default chunking size is \n";
    print "                    used. If equal to zero, than no chunking is\n";
    print "                    used (all rows are loaded to memory)\n";
    print "  filenames       - Name of files with selects to be executed.\n";
    print "                    If non is given, standard input is used\n";
    exit( 0 );
}


=head1 DATABASE CONNECTION FILE

A concept of a database connection file is supposed to provide tool's 
openness for unlimited number of database drivers. Instead of trying
to predict several types of driver initialisation, it is expected, that
a user will provide a code which opens a database connection for a given 
driver. This code will be then evaled by C<lcsvdmp.pl>.

The only thing, which is expected from this code snippet is that it assigns
a reference to an opened database connection to a variable named C<$dbh>.
Do not declare it with C<my>!

Example of the file:

  $dbh = DBI->connect( "DBI:CSV:csv_sep_char=\t;f_dir=datafile/db",
                            { RaiseError => 1 });

This is a simple case of connecting to database build from csv files.

But you can use more complex code. The example below, not only opens 
a connection but also configures ODBC driver:

  use Win32::ODBC;
  my $DBName     = "mydb";
  my $DBServer   = "myserver";
  my $DBUser     = "pkaluski";
  my $DBPassword = "password";

  no strict;
  Win32::ODBC::ConfigDSN( ODBC_CONFIG_DSN, 
                          "Sybase ASE ODBC Driver",
                          "DSN=mydriver",
                          "Database=$DBName",
                          "InterfacesFileServerName=$DBServer");
  use strict;
  my $error = Win32::ODBC::Error();
  if( $error ){
      die $error;
  } 
  $dbh = DBI->connect( "DBI:ODBC:BolekSybase", $DBUser, $DBPassword,
                       {RaiseError => 1, AutoCommit => 1});


=head1 SELECTS DEFINITION

Selects to be executed can be given either on standard input or in a file
given in command line. 

C<lcsvdmp.pl> expects the following format:

  name: myselect1
  select: select * from CUSTOMERS where id = 123
  %%
  name: myselect2
  select: select * from INVOICES where customer_id = 123
  %%
  ...
  ...

So it is basically a jar record format. For select C<myselect1> results will
be saved in C<myselect1.txt> file (unless default extension is not 
overridden), C<myselect2> in C<myselect2.txt>.

If select's names are not given, C<lcsvdmp.pl> assigns them names following
the pattern C<selectN>, where C<N> is an integer, starting from 0.

=head1 ENVIRONMENT

On launch, C<lcsvdmp.pl> looks for the following environmental variables
in order to override defaults (in case according command line option 
is not given):

=over 4

=item C<LRPT_CSV_FILE_EXT>

Extension of created csv files

=item C<LRPT_CSV_FILE_PATH>

Path, in which csv files should be created

=item C<LRPT_CSV_FIELD_SEPARATOR>

Field separator in csv files

=item C<LRPT_CSV_CONNECTION_FILE>

Path to a database connection file.

=back

=head1 AUTHORS

Piotr Kaluski E<lt>pkaluski@piotrkaluski.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2006 Piotr Kaluski. Poland. All rights reserved.

You may distribute under the terms of either the GNU General Public License 
or the Artistic License, as specified in the Perl README file. 

=cut



1;


