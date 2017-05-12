package Mail::Abuse::Reader::Stdin;

require 5.005_62;

use Carp;
use strict;
use warnings;

use base 'Mail::Abuse::Reader';
				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Reader::Stdin - Reads an abuse report through STDIN

=head1 SYNOPSIS

  use Mail::Abuse::Report;
  use Mail::Abuse::Reader::Stdin;
  my $r = new Mail::Abuse::Reader::Stdin;
  my $report = new Mail::Abuse::Report (reader => $r);

=head1 DESCRIPTION

This class reads in messages from STDIN, creating each corresponding
C<Mail::Abuse::Report> object.

A number of configuration keys are used for establishing the
operational parameters. These config keys are described below:

=over 4

=item B<stdin separator>

A string separator between different messages. It defaults to the
string B<___END_OF_REPORT___>.

=item B<stdin debug>

If set to a true value, debug messages will be sent through C<warn()>.

=back

The following methods are implemented within this class.

=over

=item C<read($report)>

Populates the text of the given C<$report> using the C<-E<gt>text>
method. Must return true if succesful or false otherwise.

=cut

sub read
{
    my $self	= shift;
    my $rep	= shift;

    my $config	= $rep->config;
    my $text	= '';

    {
	local $/ = $config->{'stdin delimiter'} || '___END_OF_REPORT___';
	$text = <>;

	unless (defined $text)
	{
	    warn "Stdin failed to read: $!\n" if $config->{'stdin debug'};
	    return;
	}

	$text =~ s/^\r?\n//;	# Remove heading newlines
	$text =~ s!$/$!!;	# Remove trailing delimiter
    }
    
    warn "Stdin read next message\n" if $config->{'stdin debug'};
    $rep->text(\$text);

    return 1;
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
