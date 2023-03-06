# Copyrights 2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
package Math::Formula::Config;
use vars '$VERSION';
$VERSION = '0.15';


use warnings;
use strict;
 
use File::Spec ();
use Log::Report 'math-formula';


sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{	my ($self, $args) = @_;
	my $dir = $self->{MFC_dir} = $args->{directory}
		or error __x"Save directory required";

	-d $dir
		or error __x"Save directory '{dir}' does not exist", dir => $dir;

	$self;
}

#----------------------

sub directory { $_[0]->{MFC_dir} }


sub path_for($$)
{	my ($self, $file) = @_;
	File::Spec->catfile($self->directory, $file);
}

#----------------------

sub save($%) { die "Save under construction" }


sub load($%) { die "Load under construction" }

1;
