package Mail::Abuse::Processor;

require 5.005_62;

use Carp;
use strict;
use warnings;

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Processor - Process a Mail::Abuse::Report

=head1 SYNOPSIS

  package Mail::Abuse::Processor::MyProcessor;
  use Mail::Abuse::Processor;

  use base 'Mail::Abuse::Processor';
  sub process { ... }
  package main;

  use Mail::Abuse::Report;
  my $p = new Mail::Abuse::Processor::MyProcessor;
  my $report = new Mail::Abuse::Report (processors => [ $p ]);

  # ... other pieces of code that configure the report ...

=head1 DESCRIPTION

This class implements the actions that are performed in a
C<Mail::Abuse::Report> after it has been received and parsed. Actions
usually include storing the report, opening tickets, etc.

The following functions are provided for the customization of the
behavior of the class.

=cut

sub new
{
    my $type	= shift;
    my $class	= ref($type) || $type;

    croak "Invalid call to Mail::Abuse::Processor::new"
	unless $class;

    bless {}, $class;
}

=pod

=over

=item C<process($report)>

Takes a C<Mail::Abuse::Report> object as an argument and performs the
processing action required.

=cut

sub process
{
    croak "Mail::Abuse::Processor is a virtual class";
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
