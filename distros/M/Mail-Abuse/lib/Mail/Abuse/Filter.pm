package Mail::Abuse::Filter;

require 5.005_62;

use Carp;
use strict;
use warnings;

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Filter - Filter incidents depending on various criteria

=head1 SYNOPSIS

  package Mail::Abuse::Filter::MyFilter;
  use Mail::Abuse::Filter;

  use base 'Mail::Abuse::Filter';
  sub criteria { ... }
  package main;

  my $f = new Mail::Abuse::Filter::MyFilter;

  $report->filter([$f]);

=head1 DESCRIPTION

This class allows for the specification of a set of restrictions
placed on the C<Mail::Abuse::Incidents> that are considered
interesting. Anything not interesting will be removed from a report.

The following functions are provided for the customization of the
behavior of the class.

=cut

sub new
{
    my $type	= shift;
    my $class	= ref($type) || $type;

    croak "Invalid call to Mail::Abuse::Filter::new"
	unless $class;

    bless {}, $class;
}

=pod

=over

=item C<criteria($report, $incident)>

This function receives a C<Mail::Abuse::Report> and a
C<Mail::Abuse::Incident> object. It returns a true value if the
incident should be handled or false otherwise. This function will be
generally called by the C<Mail::Abuse::Report> object when requested
to filter its events.

Derived classes must override this method.

=cut

sub criteria
{
    croak "Mail::Abuse::Filter is a virtual class";
}

sub AUTOLOAD 
{
    no strict "refs";
    use vars qw($AUTOLOAD);
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://;
    *$method = sub 
    { 
	my $self = shift;
	my $ret = $self->{$method};
	if (@_)
	{
	    $ret = $self->{$method};
	    $self->{$method} = shift;
	}
	return $ret;
    };
    goto \&$method;
}

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.2 with options

  -ACOXcfkn
	Mail::Abuse
	-v
	0.01

=back


=head1 LICENSE AND WARRANTY

This code and all accompanying software comes with NO WARRANTY. You
use it at your own risk.

This code and all accompanying software can be used freely under the
same terms as Perl itself.

=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
