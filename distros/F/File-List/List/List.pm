package File::List;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.3.1';

my $debug=0;

=head1 NAME

File::List - Perl extension for crawling directory trees and compiling lists of files

=head1 SYNOPSIS

  use File::List;

  my $search = new File::List("/usr/local");
  $search->show_empty_dirs();			# toggle include empty directories in output
  my @files  = @{ $search->find("\.pl\$") };	# find all perl scripts in /usr/local

=head1 DESCRIPTION

This module crawls the directory tree starting at the provided base directory
and can return files (and/or directories if desired) matching a regular expression

=cut

=head1 INTERFACE

The following methods are available in this module.

=cut 

=head2 new($base);

This creates a new File::List object and starts crawling the tree from this base

It takes a scalar base directory as an argument and returns an object reference

=cut  

sub new {
        my $class = shift;
        my $base  = shift;
        my $self = {};
        bless $self, $class;

	# store my base for later
        $self->{base} = $base;

	$debug && print "spawned with base [$base]\n";

	# read in contents of current directory
        opendir (BASE, $base);
	my @entries = grep !/^\.\.?\z/, readdir BASE;
	chomp(@entries);
	closedir(BASE);

        for my $entry (@entries) {

		# if entry is a directory, launch a new File::List to explore it
		# and store a reference to the new object in the dirlist hash
                if (-d "$base/$entry") {
               	        $debug && print _trace(),"following directory $base/$entry\n";
                        my $newbase = new File::List("$base/$entry");
       	                $self->{dirlist}{ $entry } = $newbase;
                }

		# if entry is a file, store it's name in the dirlist hash
                elsif ( -f "$base/$entry"){
			$debug && print _trace(),"Found file : $base/$entry\n";
                        $self->{dirlist}{ $entry } = 1;
                }
        }

	return $self;
}   

=head2 find($regexp);

This method accepts a scalar regular expression to search for.

It returns a reference to an array containing the full path to files
matching the expression (under this base).

=cut  

sub find {

	my $self   = shift;
	my $reg    = shift;
	my @result = ();
	my $file;

	for my $key (keys %{ $self->{dirlist} } ) {

		# if we found a reference to a File::List, ask for it's find()
		if ( ref ( $self->{dirlist}{ $key } ) ) {
			$debug && print _trace(),"following directory".$self->{base}."/".$key."\n";
			$self->{showdirs} && $self->{dirlist}{ $key }->show_empty_dirs();
			$self->{onlydirs} && $self->{dirlist}{ $key }->show_only_dirs();
			push @result, @{ $self->{dirlist}{ $key }->find($reg) };
		}
		# ah, found a file, push it into the results (if it matches the regexp)
		else {
			my $path = $self->{base}."/".$key;
			$debug && print _trace(),"found file $path\n"; 
			if ( ($path =~ eval{qr/$reg/}) && (! $self->{onlydirs}) ) {
				push @result, ($path);
			}
			$file++;
		}
	}

	
	if ( ( !$file && $self->{showdirs} || ( $self->{onlydirs} ) ) ){
		$debug && print _trace(),"processing dir ".$self->{base}."\n";
		push @result, ($self->{base}.'/') if ($self->{base} =~ eval {qr/$reg/} );
	}

	# we must be at the bottom level
	return \@result;
}


=head2 debug($level);

This sets the debug level for find

=cut   

sub debug {

        my $self = shift;
        $debug   = shift;

        return 1;
}

=head2 show_empty_dirs();

Toggle display of empty directories

=cut

sub show_empty_dirs {
	my $self = shift;
	$self->{showdirs} = $self->{showdirs}?undef:1;
	return 1;
}

=head2 show_only_dirs();

Toggle display of just directories

=cut

sub show_only_dirs {
	my $self = shift;
	$self->{onlydirs} = $self->{onlydirs}?undef:1;
	return 1;
}

#################
# Private methods, not to be used in the public API
#################

sub _trace {

        my @timedat = localtime( time );
        my $timestring = $timedat[ 2 ] . ':' . $timedat[ 1 ] . ':' . $timedat[ 0 ];

        return @{[ ( caller( 1 )) [ 3 ] . "(): " . $timestring . "\t" ]};
}


1;
__END__


=head1 AUTHOR

Dennis Opacki, dopacki@internap.com

=head1 SEE ALSO

perl(1).

=cut 
