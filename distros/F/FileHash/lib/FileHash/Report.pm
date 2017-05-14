#================================ Report.pm ===================================
# Filename:  	       Report.pm
# Description:         Generate reports from a FileHash.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:35:28 $ 
# Version:             $Revision: 1.8 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::Logger;
use FileHash::Base;

package FileHash::Report;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#                          INTERNAL METHODS                                    
#=============================================================================
# Print the contents of a hash bucket, one file to a line and an extra newline
# after the block if the flg is set.

sub _print_bucket ($$$*$) {
    my ($self,$v1,$report,$fd,$flg) = @_;
    my ($j,$ok);

    foreach $j (@$v1) {
	$ok = printf $fd "%s %12s %12s %s\n", 
	$j->md5sum, $j->sizeBytes, $j->mtime,$j->path;
	$ok or Fault::Logger->log_once ("Failed to print to '$report': $!");
    }
    if ($flg) {
	$ok = printf $fd "\n";
	$ok or Fault::Logger->log_once ("Failed to print to '$report': $!");
    }
}

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================

sub new ($) {my ($class) = @_; return bless {}, $class;}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub all (\%$$$) {
    my ($self,$files,$report,$fmtflg) = @_;
    my ($i,$j,$fd);

    defined $fmtflg or $fmtflg=0;
    
    if ($::DEBUG) {
	Fault::Logger->arg_check_isa ($files,"FileHash::Base","files") 
	    or return undef;
	Fault::Logger->arg_check_noref ($report,"reportname") 
	    or return undef;
      }
    
    Fault::Logger->assertion_check
	(!(open $fd, ">$report"),undef,"Can not open '$report': $!")
	or return undef;
    
    my $ok;
    foreach $i (values %{$files->{'filehash'}}) {
	$self->_print_bucket ($i,$report,$fd,$fmtflg);
    }
    close ($fd);
    return $self;
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 FileHash::Report - Generate reports from a FileHash.

=head1 SYNOPSIS

 use FileHash::Report;
 $obj  = FileHash::Report->new;
 $obj  = $obj->all         ($filehash,$report,$fmtflg)

=head1 Inheritance

 UNIVERSAL

=head1 Description

 Write simple reports. The output data is printed in search key/bucket order.

=head1 Examples

 use FileHash::Content;
 use FileHash::Report;

 my $r = FileHash::Report->new;
 my $a = FileHash::Content->alloc;
         $a->initFromTree ("/root");

 # print a list of all sets of files with the same md5sum and size.
 my $c = $a->identical;
         $r->all ($c,"myreport");

 # Hash the data by name instead.
 my $b = FileHash::Name->alloc;
         $b->initFromTree ($a);

 # print a list of all sets of files with the same file name.
    $c = $b->identical;
         $r->all ($c,"myreport2");

 # Print a list of all files found in a that are not in b
    $a = FileHash::Content->alloc; 
    $b = FileHash::Content->alloc; 
         $a->initFromTree ("/home/me/tree1");
         $b->initFromTree ("/home/me/tree2");
    $c = $a->andnot ($b);
         $r->all ($c,"myreport3");

 # Print a list of all files found in a that are in one or the
 # other but not both.
 my $c = $a->xor ($b);
         $r->all ($c,"myreport3");

=head1 Class Variables

 None.

=head1 Instance Variables

 None.

=head1 Class Methods

=over 4

=item B<$obj = FileHash::Report-E<gt>new>

Create instances of FileHash::Report.

=head1 Instance Methods

Methods return self on success and undef on error unless stated otherwise.

=over 4

A 'group of files' are files that have the same hash key.

=item B<$obj = $obj-E<gt>all ($filehash,$report,$fmtflg)>

Write a report of all files in $filehash to a file named $report. If
the format flag exists and is true, linefeeds are printed between each
group on output.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 Lots.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 FileHash::Base, Fault::Logger.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Report.pm,v $
# Revision 1.8  2008-08-28 23:35:28  amon
# perldoc section regularization.
#
# Revision 1.7  2008-08-04 12:13:46  amon
# Moved logical unary and binary ops to FileHash; created an internal common hash bucket print method.
#
# Revision 1.6  2008-07-27 15:16:17  amon
# Wrote lexical parse for Entry; error checking on eval and other minor issues.
#
# Revision 1.5  2008-07-25 14:30:42  amon
# Documentation improvements and corrections.
#
# Revision 1.4  2008-07-24 20:19:43  amon
# Just in case I missed anything.
#
# Revision 1.3  2008-07-24 13:35:26  amon
# switch to NeXT style alloc/init format for FileHash and Entry classes.
#
# Revision 1.2  2008-07-23 21:12:24  amon
# Moved notes out of file headers; a few doc updates; added assertion checks;
# minor bug fixes.
#
# $DATE   Dale Amon <amon@vnl.com>
#	  Created.
1;
