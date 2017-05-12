package Mail::Abuse::Reader::POP3;

require 5.005_62;

use Carp;
use strict;
use warnings;
use Net::POP3;
use NetAddr::IP;

use base 'Mail::Abuse::Reader';
				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Reader::POP3 - Reads a Mail::Abuse::Report out of a POP3 account

=head1 SYNOPSIS

  use Mail::Abuse::Report;
  use Mail::Abuse::Reader::POP3;
  my $r = new Mail::Abuse::Reader::POP3;
  my $report = new Mail::Abuse::Report (reader => $r);

=head1 DESCRIPTION

This class reads in each message in a POP3 mailbox into the text of a
C<Mail::Abuse::Report> object.

A number of configuration keys are used for establishing the
operational parameters. These config keys are described below:

=over 4

=item B<pop3 server>

Must be set to the name or address of the POP3 server where reports
are to be fetched from.

=item B<pop3 username>

The username used for the POP3 session.

=item B<pop3 password>

The corresponding password.

=item B<pop3 delete>

Set to a true value to cause messages to be deleted after reading them.

=item B<pop3 filter>

A regular expression that, if matches, discards the current
message. This is useful to avoid processing bounces.

=item B<pop3 debug>

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

    unless ($config->{'pop3 server'}
	    and $config->{'pop3 username'}
	    and $config->{'pop3 password'})
    {
	carp "Not enough config info for POP3 reader";
	return;
    }

    unless ($self->pop3)
    {
	warn "POP3 establishing session\n" if $config->{'pop3 debug'};

	$self->debug($config->{'pop3 debug'});

	$self->pop3(Net::POP3->new($config->{'pop3 server'}));
	unless ($self->pop3)
	{
	    warn "Failed to connect to POP3 server ", 
	    $config->{'pop3 server'}, ": $!\n";
	    return;
	}

	unless ($self->pop3->login($config->{'pop3 username'},
				   $config->{'pop3 password'}))
	{
	    warn "POP3 authentication failed for user ",
	    $config->{'pop3 username'}, "\n";
	    return;
	}

	if ($config->{'pop3 filter'})
	{
	    my $re = ref $config->{'pop3 filter'} eq 'ARRAY' ? 
		join ' ', @{$config->{'pop3 filter'}} : 
		    $config->{'pop3 filter'};
	    warn "POP3 filter set to <$re>\n" if $config->{'pop3 debug'};
	    $self->pop3_filter(qr($re));
	}

	$self->msg(0) unless defined $self->msg;
    }

				# Here, $self->pop3 is a handle to a
				# pop3 mailbox...

    my $ret = undef;

    while (1)
    {
	my $msg = $self->msg + 1;
	$self->msg($msg);

	warn "POP3 reading message $msg\n" if $config->{'pop3 debug'};
	my $fh = $self->pop3->getfh($msg);

	if ($fh)
	{
				# Slurp the whole thing
				# XXX - It seems that the FH returned
				# by Net::POP3 does not respect $/
	    local $/;
	    my $text;
	    while (<$fh>)
	    {
		$text .= $_;
	    }
	    warn "POP3 read ", length($text), " bytes from server\n"
		if $config->{'pop3 debug'};
	    
	    my $re = $self->pop3_filter();

	    if ($re and $text =~ m/$re/im)
	    {
		warn "POP3 skip message $msg\n"
		    if $config->{'pop3 debug'};
	    }
	    else
	    {
		$rep->text(\$text);
		$ret = 1;
	    }
	}
	else
	{
	    warn "POP3 no message $msg\n" if $config->{'pop3 debug'};
	    $ret = undef;
	    last;
	}

	if ($config->{'pop3 delete'})
	{
	    warn "POP3 deleting message $msg\n" if $config->{'pop3 debug'};
	    $self->pop3->delete($msg);
	}
	last if $ret;
    }

				# XXX - Actually, I would prefer to 
				# keep the object until we're done with it
				# but this makes it impossible to store
				# the resulting object with Storable
    $self->pop3->quit;
    $self->pop3(undef);

    return $ret;
}

=over

=item C<DESTROY>

In order to effectively delete any messages, this method terminates
gracefully the POP3 session using the C<-E<gt>quit> method of
C<Net::POP3>.

=cut

sub DESTROY
{
    my $self = shift;

    if ($self->pop3)
    {
	warn "POP3 issuing QUIT command\n" if $self->debug;
	$self->pop3->quit;
    }
}

__END__

=pod

=back

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
