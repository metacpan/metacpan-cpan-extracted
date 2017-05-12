# Filename: UserAgent.pm
#
# OFX Interface for interacting with a Financial Institution server
# 
# Created January 30, 2008  Brandon Fosdick <bfoz@bfoz.net>
#
# Copyright 2008 Brandon Fosdick <bfoz@bfoz.net> (BSD License)
#
# $Id: UserAgent.pm,v 1.2 2008/03/04 04:22:27 bfoz Exp $

package Finance::OFX::UserAgent;

use strict;
use warnings;

our $VERSION = '2';

use Finance::OFX::Parse;
use Finance::OFX::Response;
use Data::GUID;
use LWP;
use POSIX qw(strftime);

use constant DEFAULT_OPTIONS =>
{
    'ofxVersion'    => '100',
    'ofxAppID'	    => 'QWIN',
    'ofxAppVer'	    => '0900',
    'userID'	    => 'anonymous00000000000000000000000',
    'userPass'	    => 'anonymous00000000000000000000000',
};

sub new
{
    my ($this, %options) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    # Initialization
    $self->{Institution} = delete $options{Institution};
    $self->{ofxVersion} = delete $options{ofxVersion};
    $self->{ofxAppID} = delete $options{ofxAppID};
    $self->{ofxAppVer} = delete $options{ofxAppVer};
    $self->{userID} = delete $options{userID};
    $self->{userPass} = delete $options{userPass};

    # Defaults
    for( keys %{DEFAULT_OPTIONS()} )
    {
	$self->{$_} = DEFAULT_OPTIONS()->{$_} unless defined $self->{$_};
    }

    $self->{ua} = LWP::UserAgent->new(%options);

    return $self;
}

sub account_info
{
    my $s = shift;

    my $r = $s->request('
    <SIGNONMSGSRQV1>
'.$s->sonrq.'
    </SIGNONMSGSRQV1>
    <SIGNUPMSGSRQV1>
	<ACCTINFOTRNRQ>
	    <TRNUID>'.(Data::GUID->new()->as_string).'
	    <ACCTINFORQ>
		<DTACCTUP>19700101
	    </ACCTINFORQ>
	</ACCTINFOTRNRQ>
    </SIGNUPMSGSRQV1>');
    return $s->{response} = Finance::OFX::Response->from_http_response($r);
}

sub statement
{
    my ($s, $acct, %options) = @_;
    my $start = delete $options{start};
    my $end = delete $options{end};
    my $transactions = delete $options{transactions};

    my $r = $s->request('
    <SIGNONMSGSRQV1>'.$s->sonrq.'
    </SIGNONMSGSRQV1>
    <BANKMSGSRQV1>
    <STMTTRNRQ>
      <TRNUID>'.(Data::GUID->new()->as_string).'
      <STMTRQ>'.$acct->bankacctfrom().'
      <INCTRAN>'.
	($start ? 
	    '<DTSTART>'.strftime('%Y%m%d%H%M%S', gmtime($start))."[0:UTC]\n" : '').
	($end ? 
	    '<DTEND>'.strftime('%Y%m%d%H%M%S', gmtime($end))."[0:UTC]\n" : '').'
        <INCLUDE>'.($transactions ? 'Y' : 'N').'
      </INCTRAN>
      </STMTRQ>
    </STMTTRNRQ>
    </BANKMSGSRQV1>');

    return $s->{response} = Finance::OFX::Response->from_http_response($r);
}

sub profile
{
    my $s = shift;

    my $request = HTTP::Request->new(POST => ${$s->{Institution}}->url);
    $request->content_type('application/x-ofx');
    $request->content($s->header().
'<OFX>
    <SIGNONMSGSRQV1>
'.$s->sonrq.'
    </SIGNONMSGSRQV1>
    <PROFMSGSRQV1>
	<PROFTRNRQ>
	    <TRNUID>'.(Data::GUID->new()->as_string).'
	    <PROFRQ>
		<CLIENTROUTING>NONE
		<DTPROFUP>'.${$s->{Institution}}->date.'
	    </PROFRQ>
	</PROFTRNRQ>
    </PROFMSGSRQV1>
</OFX>');

    print $request->as_string;
    my $r = $s->request($request);
    return $s->{response} = Finance::OFX::Response->from_http_response($r);
}

# --- Getters and Setters ---

sub institution
{
    my $s = shift;
    $s->{Institution} = shift if scalar @_;
    $s->{Institution};
}

sub response
{
    my $s = shift;
    $s->{response};
}

sub user_id
{
    my $s = shift;
    $s->{userID} = shift if scalar @_;
    $s->{userID};
}

sub user_pass
{
    my $s = shift;
    $s->{userPass} = shift if scalar @_;
    $s->{userPass};
}

# --- Internal use only ---

# Returns an OFX header appropriate for the protocol version in use
sub header
{
    my $s = shift;

'OFXHEADER:100
DATA:OFXSGML
VERSION:102
SECURITY:NONE
ENCODING:USASCII
CHARSET:1252
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE'."\n\n"
}

sub request
{
    my ($s, $content) = @_;
    my $r = HTTP::Request->new(POST => $s->{Institution}->url);
    $r->content_type('application/x-ofx');
    $r->content($s->header().'<OFX>'.$content.'</OFX>');
#    print "request: ", $r->as_string, "\n\n---\n\n";
    return $s->{ua}->request($r);
}

# Returns a SONRQ block
sub sonrq
{
    my $s = shift;
    my $t = strftime('%Y%m%d%H%M%S[%z:%Z]', localtime);
    $t =~ s/00:/:/;	# Fix the %z format

'<SONRQ>
    <DTCLIENT>'.$t.'
    <USERID>'.$s->{userID}.'
    <USERPASS>'.$s->{userPass}.'
    <LANGUAGE>'.$s->{Institution}->language.'
    <FI>
	<ORG>'.$s->{Institution}->org.'
	<FID>'.$s->{Institution}->fid.'
    </FI>
    <APPID>'.$s->{ofxAppID}.'
    <APPVER>'.$s->{ofxAppVer}.'
</SONRQ>'
}

1;

__END__

=head1 NAME

Finance::OFX::UserAgent - Open Financial Exchange client

=head1 SYNOPSIS

 use Finance::OFX::UserAgent
 
 my $ua = OFX::UserAgent->new(Institution => $fi);
 $ua->user_id($user);
 $ua->user_pass($pass);
 
 my $response = $ua->account_info();

=head1 DESCRIPTION

C<Finance::OFX::UserAgent> provides an L<LWP::UserAgent> like interface to an 
OFX server. It provides several convenience methods for performing common OFX 
requests. Results are returned as an L<Finance::OFX::Response> object, which is 
an extension of L<HTTP::Response>.

=head1 CONSTRUCTOR

=over

=item $ua = Finance::OFX::UserAgent->new( %options )

Constructs a new C<Finance::OFX::UserAgent> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
In addition to the regular C<LWP::UserAgent> options, the following options 
are also recognized:

   Key			Default
   -----------		--------------------
   Institution		undef
   language		ENG
   ofxVersion		100
   ofxAppID		QWIN
   ofxAppVer		0900
   userID		anonymous00000000000000000000000
   userPass		anonymous00000000000000000000000

All unrecognized keys are passed to C<LWP::UserAgent>.

=back

=head1 ATTRIBUTES

=over

=item $ua->institution

=item $ua->institution( $fi )

Get/Set the C<Finance::OFX::Institution> object. Setter expects a reference.

=item $ua->response

Get a reference to the most recently returned C<Finance::OFX::Response> object.

=item $ua->user_id

=item $ua->user_id( $user )

Get/Set the OFX user ID.

=item $ua->user_pass

=item $ua->user_pass( $pass )

Get/Set the OFX user password.

=back

=head1 REQUEST METHODS

All request methods return a L<Finance::OFX::Response> object unless otherwise noted.

If a user ID and password have not been set the default/anonymous OFX ID and 
password will be used.

=over

=item $ua->account_info

Request account dicovery from the configured Financial Institution. 

=item $ua->profile

Requests OFX profile information. Untested.

=item $ua->statement( $account, %options )

Request a statement download. Expects a L<Finance::OFX::Account> object as the 
first argument to indicate the account to retrieve a statement for. C<%options> 
can be:

   Key			Description
   ------------		-------------------------------------------
   start		Start of date range to retrieve (UNIX time)
   end			End of date range to retrieve (UNIX time)
   transactions		Request transaction list if set, otherwise 
			get account balances

Not specifying a date range, or specifying an incomplete range, may or may not 
be a fatal error, depending on how the OFX server is configured. Some 
institutions appear to ignore the date range entirely and simply return 
whatever they feel like.

=back

=head1 SEE ALSO

L<LWP::UserAgent>
L<Finance::OFX::Institution>
L<Finance::OFX::Response>
L<http://ofx.net>

=head1 WARNING

From C<Finance::Bank::LloydsTSB>:

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Brandon Fosdick, E<lt>bfoz@bfoz.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Brandon Fosdick <bfoz@bfoz.net>

This software is provided under the terms of the BSD License.

=cut
