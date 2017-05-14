#================================ List.pm ===================================
# Filename:  	       List
# Description:         Internal class for managing a list of delegates.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:20:19 $ 
# Version:             $Revision: 1.5 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::ErrorHandler;

package Fault::Delegate::List;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================
my %fault = ();

sub new {
  my ($class,@list) = @_;
  my $self       = bless {}, $class;

  %fault          = ();
  $self->{'list'} = {};

  $self->add (@list);

  # If we had no good delegates, default to command line.
  scalar keys %{$self->{'list'}} or $self->add (Fault::Delegate::Stdout->new);

  return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub add ($@) {
    my ($self, @list) = @_;

    foreach my $d (@list) {
	next if (!defined $d);

	if (! ((ref $d) && 
	       ((ref $d) ne "HASH") && 
	       $d->can("log"))) {
	    Fault::ErrorHandler->warn
		("Fault::Logger->new: Ignoring an invalid logger delegate " .
		 "object. A delegate must at the very least support a 'log' " .
		 "method. Read the docs and fix your code.");
	      next;}
	my $list = $self->{'list'};
	$list->{$d} = $d;
	if ($d->can ("initfaults")) {
	    foreach my $m (eval{$d->initfaults}) {$fault{$m}=1;}
	}
    }
    return 1;
}

#-----------------------------------------------------------------------------

sub delegates    ($)  {values %{shift->{'list'}};}
sub fault_exists ($$) {my ($s,$m)=@_; return ($fault{$m->msg}) ? 1 : 0;}

#-----------------------------------------------------------------------------
#	      Apply a Delegate Protocol Methdo to each Delegate
#-----------------------------------------------------------------------------

sub log ($$@) {
    my ($s,$msg,@rest) = @_;

    foreach my $l ($s->delegates) {
	(eval ($l->log ($msg,@rest))) ||
	    (Fault::ErrorHandler->warn("Failed to report: \"" . 
				$msg->msg .
				"\" due to Delegate error \"$@\"!"),
	     return 0);
    }
    return 1;
}

#------------------------------------------------------------------------------
# Log on condition still low.

sub trans00 ($$@) {
    my ($s,$msg,@rest) = @_;

    foreach my $l ($s->delegates) {
	($l->can ("trans00")) && eval($l->trans00($msg,@rest));
    }
    return 0;
}

#------------------------------------------------------------------------------
# Log on condition rising edge. 

sub trans01 ($$@) {
    my ($s,$msg,@rest) = @_;

    $fault{$msg->msg} = 1;
    foreach my $l ($s->delegates) {
	($l->can ("trans01")) && eval($l->trans01($msg,@rest));
    }
    return 0;
}

#------------------------------------------------------------------------------
# Log on condition falling edge.

sub trans10 ($$@) {
    my ($s,$msg,@rest) = @_;

    foreach my $l ($s->delegates) {
	($l->can ("trans10")) && eval($l->trans10($msg,@rest));
    }
    return 0;
}

#------------------------------------------------------------------------------
# Log on condition still high.

sub trans11 ($$@) {
    my ($s,$msg,@rest) = @_;

    delete $fault{$msg->msg};
    foreach my $l ($s->delegates) {
	($l->can ("trans11")) && eval($l->trans11($msg,@rest));
    }
    return 0;
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Fault::Delegate::List - Internal class for managing a list of delegates.

=head1 SYNOPSIS

 use Fault::Delegate::List;
 $self      = Fault::Delegate::List->new (@delegates);
 $bool      = $self->add                 (@delegates);
 @delegates = $self->delegates;
 $bool      = $self->log                 ($msg,@rest);
 $bool      = $self->trans00             ($msg,@rest);
 $bool      = $self->trans01             ($msg,@rest);
 $bool      = $self->trans10             ($msg,@rest);
 $bool      = $self->trans11             ($msg,@rest);

=head1 Inheritance

 UNIVERSAL

=head1 Description

 Internal class for managing a list of delegates.

=head1 Examples

 None.

=head1 Class Variables

 None.

=head1 Instance Variables

 list      Contains a pointer to a hash of delegate pointers.

=head1 Class Methods

=over 4

=item B<$self = Fault::Delegate::List-E<gt>new(@delegates)>

Create an instance of Fault::Delegate::List and initialize it with the
contents of @delegates. The list may be null.

If a delegate has an initfaults method, it is executed and the results 
merged into the current list of active faults.

=head1 Instance Methods

=over 4

=item B<$bool = $self-E<gt>add (@delegates)>

Add each member of a list of delegates, that is not already present, to the 
internal list of delegates. The list may be empty. 

A member of the list is included only if it is a pointer to an object that
has a log method.

If a delegate has an initfaults method, it is executed and the results 
merged into the current list of active faults.

=item B<@delegates = $self-E<gt>delegates>

Returns a list of delegate objects suitable for iteration. The list may be
empty.

=item B<$bool = $self-E<gt>log ($msg,@rest)>

Send a message to each delegate for logging. 

=item B<$bool = $self-E<gt>trans00 ($msg,@rest)>

Send a message to each delegate for 4 state fault monitoring in the case 
that $msg was in a Fault Clear state previously and still is.

=item B<$bool = $self-E<gt>trans01 ($msg,@rest)>

Send a message to each delegate for 4 state fault monitoring in the case 
that $msg was in a Fault Clear state previously and is now in a Fault 
Raised state.

=item B<$bool = $self-E<gt>trans10 ($msg,@rest)>

Send a message to each delegate for 4 state fault monitoring in the case 
that $msg was in a Fault Raised state previously but is now in a Fault 
Clear state.

=item B<$bool = $self-E<gt>trans11 ($msg,@rest)>

Send a message to each delegate for 4 state fault monitoring in the case 
that $msg was in a Fault Raised state previously and still is.

=item B<@faults = $self-E<gt>initfaults>

Ask each delegate to return a current list of faults for this process from 
its persistant storage. Returns an empty list if there are none or the
delegate class has no such memory or if it does and is unable to retrieve
data from it.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: List.pm,v $
# Revision 1.5  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.4  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.3  2008-05-09 18:24:55  amon
# Bugs and changes due to pre-release testing
#
# Revision 1.2  2008-05-08 20:22:50  amon
# Minor bug fixes; shifted fault table and initfault from Logger to List
#
# Revision 1.1  2008-05-07 18:16:12  amon
# A class to manage a list of logger delegates
#
# $DATE   Dale Amon <amon@vnl.com>
#	  Created.
1;
