package Mail::Abuse::Processor::Explain;

require 5.005_62;

use Carp;
use strict;
use warnings;

use POSIX qw(strftime);

use base 'Mail::Abuse::Processor';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Processor::Explain - Explain a Mail::Abuse::Report

=head1 SYNOPSIS

  use Mail::Abuse::Processor::Explain;

  use Mail::Abuse::Report;
  my $p = new Mail::Abuse::Processor::Explain;
  my $report = new Mail::Abuse::Report (processors => [ $p ]);

  # ... other pieces of code that configure the report ...

=head1 DESCRIPTION

This class outputs an abuse report and information about the incidents
that were extracted, to STDOUT. It is useful when using this framework
as part of a filter that preprocesses messages before handing them to
other systems.

The following functions are implemented.

=over

=item C<process($report)>

Takes a C<Mail::Abuse::Report> object as an argument and performs the
processing action required.

=cut

sub _dump($$$$$);

sub _dump($$$$$)
{
    my $fh	= shift;	# File handle to write output to
    my $r	= shift;	# Handle to the incident
    my $indent	= shift;	# Current indent level
    my $parent	= shift;	# The name of what is being printed
    my $r_data	= shift;	# The datum returned by the handler

    if (ref $r_data eq 'ARRAY')
    {
	print $fh '| ' x ($indent - 1), "+-$parent\n";
	for my $k (0 .. $#{$r_data})
	{
	    _dump($fh, $r, $indent + 1, $parent . '.[' . $k .']',
		  $r_data->[$k]);
	}
    }
    elsif (ref $r_data eq 'HASH')
    {
	print $fh '| ' x ($indent - 1), "+-$parent\n";
	for my $k (sort keys %$r_data)
	{
	    _dump($fh, $r, $indent + 1, $parent . '.{' . $k .'}',
		  $r_data->{$k});
	}
    }
    else
    {
	print $fh '| ' x ($indent - 1), "+-$parent=$r_data\n";
    }
}

sub process
{
    my $self	= shift;
    my $rep	= shift;

    # If no work is required, simply leave quickly
    return if @{$rep->incidents} == 0;

    # Where to send the explanations...
    my $fh = \*STDOUT;

    # Print a nice header
    my $PACKAGE = __PACKAGE__;
    print $fh qq{
#================================================================
#Incident explanation by $PACKAGE
}
    ;
    print $fh q{#$Id: Explain.pm,v 1.2 2004/11/21 02:44:14 lem Exp $
#================================================================

}
    ;

    # Iterate through all the incidents
    for my $r (sort { $a->ip <=> $b->ip 
			  or $a->time <=> $b->time 
			  or $a->type cmp $b->type } 
	       @{$rep->incidents})
    {
	print $fh "# ", $r->ip, " ", strftime("%B %d, %H:%M:%S %Y (%z)", 
					      localtime($r->time)), "\n";
	for my $method (sort $r->items)
	{
	    next if grep { $method eq $_ } qw/ip time data/;
	    no strict 'refs';
	    _dump($fh, $r, 1, $method, $r->$method);
	}
    }

    # Output a trailer and introduce the report text
    print $fh q{

#================================================================
#No more incidents to explain. The recovered report body follows.
#================================================================

};

    print $fh $rep->normalized ? ${$rep->body} : ${$rep->text};
}

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: Explain.pm,v $
Revision 1.2  2004/11/21 02:44:14  lem
Field tested

Revision 1.1  2004/11/21 02:15:02  lem
Testing version


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
