package Mail::Abuse::Processor::Mailer;

require 5.005_62;

use Carp;
use strict;
use warnings;
use IO::File;
use Mail::Mailer;

use base 'Mail::Abuse::Processor';

use constant ANTILOOP	=> 'X-Mail-Abuse-Loop';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Processor::Mailer - Handle the email response to a Mail::Abuse::Report

=head1 SYNOPSIS

  use Mail::Abuse::Processor::Mailer;

  use Mail::Abuse::Report;
  my $p = new Mail::Abuse::Processor::Mailer;
  my $report = new Mail::Abuse::Report (processors => [ $p ]);

  # ... other pieces of code that configure the report ...

=head1 DESCRIPTION

This class handles automatic email responses sent to the originator of
the Mail::Abuse::Report. Mail loops are avoided and detected by
inserting a special header, B<X-Mail-Abuse-Loop>. If this header is
present, no messages will be sent.

The following configuration keys control the behavior of this module.

=over

=item B<debug mailer>

If set to a true value, causes this module to emit debugging info
using C<warn()>.

=cut

use constant DEBUG	=> 'debug mailer';

=pod

=item B<mailer type>

The type of mailer to use, as described in C<Mail::Mailer>. Defaults
to B<mail>.

=cut

use constant TYPE	=> 'mailer type';

=pod

=item B<mailer smtp server>

Some types of mailers require the specification of an SMTP
server. This option allows for it.

=cut

use constant SMTP	=> 'mailer smtp server';

=pod

=item B<mailer from>

The complete RFC-2822 address to be used in the B<From:> header placed
in the message header. It B<must> be specified.

=cut

use constant FROM	=> 'mailer from';

=pod

=item B<mailer reply to>

The B<Reply-To:> header to use in the message header of the reply. The
header will not be included if left unspecified.

=cut

use constant REPLYTO	=> 'mailer reply to';

=pod

=item B<mailer errors to>

The B<Errors-To:> header to use in the message header of the reply. The
header will not be included if left unspecified.

=cut

use constant ERRORSTO	=> 'mailer errors to';

=pod

=item B<mailer forced to>

If this value is set, the response message is directed to the given
address.

=cut

use constant FORCED	=> 'mailer forced to';

=pod

=item B<mailer subject>

The subject to use in the responses.

=cut

use constant SUBJECT	=> 'mailer subject';

=pod

=item B<mailer precedence>

The precedence to use. Defaults to 'bulk'.

=cut

use constant PRECEDENCE	=> 'mailer precedence';

=pod

=item B<mailer fail message>

The name of the file containing the message template that will be used
to compose a message whenever no incidents can be parsed or pass the
filters from the abuse report. This distribution includes an example
message in the C<etc/> subdirectory.

=cut

use constant FAIL	=> 'mailer fail message';

=pod

=item B<mailer success message>

The name of the file containing the message template that will be used
to compose a message when one or more incidents are parsed and
filtered from the abuse report.. This distribution includes an example
message in the C<etc/> subdirectory.

=cut

use constant SUCCESS	=> 'mailer success message';

=pod

=item B<mailer charset>

The charset used to encode the response. Defaults to 'US-ASCII'. This
is placed in the B<charset=> part of the MIME headers.

=cut

use constant CHARSET	=> 'mailer charset';

=pod

=back

The following functions are implemented.

=over

=item C<process($report)>

Takes a C<Mail::Abuse::Report> object as an argument and performs the
processing action required. MIME headers inserted by this module,
force encoding to 8bit.

=cut

sub process
{
    my $self	= shift;
    my $rep	= shift;

    unless ($rep->config or ref $rep->config ne 'HASH')
    {
	warn "Invalid or no config";
	return;
    }

    my $fail	= $rep->config->{&FAIL};
    my $from	= $rep->config->{&FROM};
    my $smtp	= $rep->config->{&SMTP};
    my $debug	= $rep->config->{&DEBUG};
    my $forced	= $rep->config->{&FORCED};
    my $success	= $rep->config->{&SUCCESS};
    my $replyto	= $rep->config->{&REPLYTO};
    my $subject	= $rep->config->{&SUBJECT};
    my $errors	= $rep->config->{&ERRORSTO};
    my $preced	= $rep->config->{&PRECEDENCE} || 'bulk';
    my $type	= $rep->config->{&TYPE} || 'mail';
    my $charset = $rep->config->{&CHARSET} || 'US-ASCII';

    unless ($fail and $success and -f $fail and -f $success)
    {
	warn "M::A::P::Mailer: Failure and success templates must be defined\n";
	return;
    }

    unless ($from)
    {
	warn "M::A::P::Mailer: No ", &FROM, " entry found in the config file";
	return;
    }

    if (($rep->normalized && $rep->header->get(&ANTILOOP)) 
	or (!$rep->normalized && $rep->text =~ m/^\s*&{ANTILOOP}:\s/m))
    {
	warn "M::A::P::Mailer: Loop detected and avoided\n" if $debug;
	return;
    }
				# Detect and avoid loops

    my $mailer;

    if (defined $smtp)
    {
	$mailer = new Mail::Mailer $type, Server => $smtp;
    }
    else
    {
	$mailer = new Mail::Mailer $type;
    }

    my %Headers	= (
	'X-Mailer'			=> __PACKAGE__ . " v$VERSION",
	&ANTILOOP			=> scalar localtime,
	'MIME-Version'			=> '1.0',
	'Content-Type'			=> qq{text/plain; charset="$charset"},
	'Content-Transfer-Encoding'	=> '8bit',
	'From'				=> $from,
    );

    $Headers{'Reply-To'}	= $replyto if $replyto;
    $Headers{'Errors-To'}	= $errors if $errors;
    $Headers{'Subject'}		= $subject if $subject;
    $Headers{'Precedence'}	= $preced;

    if ($rep->normalized)
    {
	$Headers{To} = $rep->header->get('Reply-To') 
	    || $rep->header->get('From');
    }
    else
    {
	if ($ {$rep->text} =~ m/Reply-To: (.*)$/m)
	{
	    $Headers{To} = $1;
	}
	elsif ($ {$rep->text} =~ m/From: (.*)$/m)
	{
	    $Headers{To} = $1;
	}
    }

    unless ($Headers{To})
    {
	warn "M::A::P::Mailer: Cannot determine destination address\n";
	return;
    }

    chomp $Headers{To};

    if ($forced)
    {
	warn "M::A::P::Mailer: Changing recipient from $Headers{To} ",
	"to $forced\n";
	$Headers{'X-Mail-Abuse-Original-To'} = $Headers{To};
	$Headers{To} = $forced;
    }
    
    my $fh = new IO::File;

    if ($rep->incidents and @ {$rep->incidents} > 0)
    {
				# Found an incident, so 
				# declare it a success
	unless ($fh->open($success, "r"))
	{
	    warn "M::A::P::Mailer: Cannot open success template $success\n";
	    return;
	}
    }
    else
    {
				# No incidents are applicable
	unless ($fh->open($fail, "r"))
	{
	    warn "M::A::P::Mailer: Cannot open fail template $fail\n";
	    return;
	}
    }

    $mailer->open(\%Headers);
    {
	local $/ = undef;
	print $mailer (<$fh>);
    };
    $fh->close;
    return $mailer->close;
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
