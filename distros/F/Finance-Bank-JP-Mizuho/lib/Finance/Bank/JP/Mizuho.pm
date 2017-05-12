=encoding utf8

=head1 NAME

Finance::Bank::JP::Mizuho

=head1 SYNOPSIS

    my $mizuho = Finance::Bank::JP::Mizuho-new(
        consumer_id => '123455678',
        password => 'p45sW0rD',
        questions => {
            '母親の誕生日はいつですか（例：５月１４日）' => '１０月１日', # have to use 2byte digits, sucks
            '最も年齢の近い兄弟姉妹の誕生日はいつですか（例：２月１０日）' => '１２月２日',
            '応援しているスポーツチームの名前は何ですか' => '阪神タイガース',
        },
    );
    
    my $accounts = $mizuho->accounts;
    
    my $ofx = $mizuho->get_ofx(
        $mizuho->accounts->[0],
        $mizuho->CONTINUATION_FROM_LAST,
    );


=head1 DESCRIPTION

Perl interface to access your L<Mizuho Direct|http://www.mizuhobank.co.jp/direct/start.html> account.

=head1 CONSTANT

=head2 CONTINUATION_FROM_LAST

Value for L</get_ofx>

=head2 SAME_AS_LAST

Value for L</get_ofx>

=head2 LAST_TWO_MONTHS

Value for L</get_ofx>

=head1 FUNCTIONS

=cut

package Finance::Bank::JP::Mizuho;

use strict;
use warnings;

use Carp;
use DateTime;
use Encode;
use Finance::Bank::JP::Mizuho::Account;
use Finance::OFX::Parse::Simple;
use HTTP::Cookies;
use LWP::UserAgent;

our $VERSION = '0.02';

use constant USER_AGENT => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)';
use constant START_URL  => 'http://www.mizuhobank.co.jp/direct/start.html';
use constant ENCODING   => 'shift_jis';

use constant CONTINUATION_FROM_LAST => 1;
use constant SAME_AS_LAST => 2;
use constant LAST_TWO_MONTHS => 3;

=head2 new ( %config )

Creates a new instance.

C<%config> keys:

=over 3

=item
B<consumer_id>

Consumer id of Mizuho Direct ( お客さま番号 )

=item
B<password>

Password for your consumer_id

=item
B<questions>

Hash reference paired with: Key as Question, Value as Answer

=back

=cut

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self;
}

=head2 consumer_id

=cut
sub consumer_id { shift->{consumer_id} }

=head2 accounts

returns array of L<Finance::Bank::JP::Mizuho::Account>

=cut

sub accounts {
    my $self = shift;
    return $self->{accounts} if $self->{accounts};
    return [] unless $self->login;
    $self->parse_accounts( $self->get_content( $self->list_url ) );
}

=head2 account_by_number ( $number )

returns an instance of L<Finance::Bank::JP::Mizuho::Account>

=cut

sub account_by_number {
    my ( $self, $number ) = @_;
    my @accounts = @{ $self->accounts };
    return unless @accounts && $number;
    foreach my $account ( @accounts ) {
        return $account if $account->number eq $number;
    }
}

=head2 get_ofx ( $account_or_number , $term )

C<$account_or_number>: 
an instance of L<Finance::Bank::JP::Mizuho::Account> OR bank account number

C<$term> : 

=over 3

=item L</CONTINUATION_FROM_LAST>

=item L</SAME_AS_LAST>

=item L</LAST_TWO_MONTHS>

=back

returns list of hash references, parsed by L<Finance::OFX::Parse::Simple>

=cut
sub get_ofx {
    my $self = shift;

    Finance::OFX::Parse::Simple->parse_scalar($self->get_raw_ofx(@_));
}

=head2 get_raw_ofx ( $account_or_number , $term )

arguments are same as L</get_ofx>.

returns OFX content as scalar

=cut
sub get_raw_ofx {
    my ($self, $account, $term) = @_;
    
    $term ||= CONTINUATION_FROM_LAST;
    
    if( $term !~ /^(1|2|3)$/ ) {
        carp( 'Invalid value to $term:'. $term );
        return 0;
    }
    
    my $val;
    $account = $self->account_by_number( $account )
        if( ref($account) ne 'Finance::Bank::JP::Mizuho::Account' );
    
    unless( $account ) {
        carp( 'No account' );
        return 0;
    }

    $self->get_content( $self->ref_url );
    
    my $content = $self->get_content( $self->list_url );
    my $emfpostkey = $self->emfpostkey( $content );
    my $action = $self->form1_action( $content );
    
    unless( $emfpostkey && $action ) {
        carp( 'Failed to parse page' );
        return 0;
    }
    
    my $res = $self->ua->post(
        $action,
        Referer => $self->list_url,
        Content => [
            Token => '',
            REDISP => 'OFF',
            NLS => 'JP',
            EMFPOSTKEY => $emfpostkey,
            SelectRadio => $account->radio_value,
            DownhaniBox => $term,
            Next => 'Yippee!',
        ],
    );
    
    my $dest = $res->header('location');
    
    unless( $dest ) {
        carp( 'Query fail' );
        return 0;
    }
    
    $content = $self->get_content( $dest );
    $emfpostkey = $self->emfpostkey( $content );
    $action = $self->form1_action( $content );
    
    $res = $self->ua->post(
        $action,
        Referer => $action,
        Content => [
            Token => '',
            NLS => 'JP',
            EMFPOSTKEY => $emfpostkey,
        ],
    );
    
    $dest = $res->header('location');
    unless( $dest ) {
        carp( 'Query fail' );
        return 0;
    }
    
    $content = $self->get_content( $dest );
    $emfpostkey = $self->emfpostkey( $content );
    $action = $self->form1_action( $content );
    
    my $ofx = $self->ua->get( $self->ofx_url )->content;
    
    $res = $self->ua->post(
        $action,
        Referer => $action,
        Content => [
            Token => '',
            NLS => 'JP',
            EMFPOSTKEY => $emfpostkey,
        ],
    );
    
    $ofx
}

=head2 host

returns random host, provided by Mizuho Direct web service.

=cut
sub host {
    my $self = shift;
    if(@_) {
        my $host = shift;
        $self->ua->default_headers->header(
            Origin => "https://$host",
            Host => $host,
        );
        $self->{host} = $host;
    }
    return $self->{host} if $self->{host};
    $self->{host} || 'web.ib.mizuhobank.co.jp'
}


=head2 logged_in

returns this instance has logged in

=cut
sub logged_in  {
    my $self = shift;
    $self->{logged_in} = shift if @_;
    $self->{logged_in};
}


=head2 login

returns logged in successfully.

calling this method is not neccesary.

=cut

sub login {
    my $self = shift;
    return 1 if $self->logged_in;
    my $url = $self->login_url2;
    ($url=~m{xtr=Emf00005}) ?
        $self->_login($url) :
        $self->_question($url);
}

=head2 logout

if you leave the process without calling this method,
the account will be locked for about 10 minutes,
and you will not able to access the web service.

=cut

sub logout {
    my $self = shift;
    return unless $self->logged_in;
    my $res = $self->ua->get($self->logout_url);
    $self->logged_in(0);
}

=head2 password

=cut
sub password   { shift->{password}   }

=head2 questions

=cut
sub questions  { shift->{questions}  }

=head2 ua

=cut

sub ua {
    shift->{ua} ||= LWP::UserAgent->new(
        agent => USER_AGENT,
        cookie_jar => HTTP::Cookies->new,
        max_redirect => 0,
        requests_redirectable => [],
    )
}

## private __________________________________________________________________________________________

sub login_url1 { 'https://'. shift->host .'/servlet/mib?xtr=Emf00000' }
sub logout_url { 'https://'. shift->host . ':443/servlet/mib?xtr=EmfLogOff&NLS=JP' }
sub ref_url    { 'https://'. shift->host . '/servlet/mib?xtr=Emf04000&NLS=JP' }
sub list_url   { 'https://'. shift->host . '/servlet/mib?xtr=Emf04610&NLS=JP' }
sub ofx_url    { 'https://'. shift->host . ':443/servlet/mib?xtr=Emf04625' }

sub login_url2 {
    my $self = shift;
    my $action = $self->form1_action($self->get_content($self->login_url1));
    my $res = $self->ua->post( $action, [
        pm_fp => '',
        KeiyakuNo => $self->consumer_id,
        Next => 'Yippee!',
    ]);
    my $url = $res->header('location') || '';
    $self->host($1) if $url =~ m%^https://([^/\:]+).*%;
    $url;
}

sub _question {
    my ($self,$url) = @_;
    my $content = $self->get_content($url);
    my $action = $self->form1_action($content);
    my ( $question, $answer );    
    unless( $question = $self->parse_question($content) ) {
        carp('Failed to parse question screen');
        return 0;
    }
    unless( $answer = $self->questions->{$question} ) {
        carp("No answer for '$question'");
        return 0;
    }
    my $res = $self->ua->post( $action, [
        rskAns => encode(ENCODING, decode('utf8', $answer) ),
        Next => 'Yippee!',
        NLS => 'JP',
        Token => '',
        jsAware => 'on',
        frmScrnID => 'Emf00000',
    ]);
    my $dest = $res->header('location');
    unless($dest) {
        carp('Login failure');
        return 0;
    }
    $dest eq $url ? 
        $self->_question($url) : 
        $self->_login($dest);
}

sub _login {
    my ($self,$url) = @_;
    my $content = $self->get_content($url);
    my $action = $self->form1_action($content);
    my $res = $self->ua->post( $action, [
        NLS => 'JP',
        jsAware => 'on',
        pmimg => '0',
        Anshu1No => $self->password,
        login => 'Yippee!',
    ]);
    my $dest = $res->header('location');
    return 0 unless $dest;
    $self->logged_in(1);
    1
}

sub parse_question {
    my ($self,$content) = @_;
    return $1 if( ( $content || '' ) =~ /.*<TD width="200" align="right"><DIV style="font-size:9pt">.+[^\n\r]*[\n\r].*<DIV[^>]*>([^<]+)<.*/i );
    ''
}

sub parse_accounts {
    my ($self,$content) = @_;
    $content =~ s/[\s"\r\n\t]//g;
    my $re = 
        q{<TDwidth=30[^>]*><INPUT.*NAME=SelectRadio.*value=(\d+)[^>]*></TD>}.
        q{<TDwidth=150[^>]*><DIV[^>]*>&nbsp;([^<]+)</DIV></TD>}.
        q{<TDwidth=100[^>]*><DIV[^>]*>&nbsp;([^<]+)</DIV></TD>}.
        q{<TDwidth=100[^>]*><DIV[^>]*>(\d+)</DIV></TD>}.
        q{<TDwidth=190[^>]*><DIV[^>]*>([^<]+)</DIV></TD>};

    my @tr = split /TR><TR/i, $content;
    my @accounts = ();
    my $tz = 'Asia/Tokyo';
    foreach my $t (@tr) {
        if($t =~ /$re/i) {
            my $obj = {
                radio_value => $1,
                branch => $2,
                type   => $3,
                number => $4,
            };
            my $d = $5;
            my ($start, $end);
            if( $d =~ /(\d{4})\.(\d{2})\.(\d{2})[^\d]+(\d{4})\.(\d{2})\.(\d{2})/ ) {
                $start = DateTime->new(
                    year => $1,
                    month => $2,
                    day => $3,
                    time_zone => $tz,
                );
                $end = DateTime->new(
                    year => $4,
                    month => $5,
                    day => $6,
                    time_zone => $tz,
                );
            } elsif( $d =~ /(\d{4})\.(\d{2})\.(\d{2})/ ) {
                $start = DateTime->new(
                    year => $1,
                    month => $2,
                    day => $3,
                    time_zone => $tz,
                );
            }
            $end ||= $start;
            $obj->{last_downloaded_from} = $start if $start;
            $obj->{last_downloaded_to} = $end if $end;
            push @accounts, Finance::Bank::JP::Mizuho::Account->new(%$obj);
        }
    }
    $self->{accounts} = [@accounts];
}

sub form1_action {
    my ($self,$content) = @_;
    return $1 if $content =~ /.*action="([^"]+)"[^\n\r]+name="FORM1".*/ig;
    return $1 if $content =~ /.*name="FORM1"[^\n\r]+action="([^"]+)".*/ig;
    ''
}

sub emfpostkey {
    my ($self,$content) = @_;
    return $1 if ( $content =~ /<INPUT.*NAME="EMFPOSTKEY" VALUE="([^"]+)">/i );
    ''
}

sub get_content {
    my ($self,$url) = @_;
    my $res = $self->ua->get($url);
    $self->ua->default_headers->header( Referer => $url );
    encode('utf8', decode(ENCODING,$res->content) );
}




1

__END__

=head1 TESTING

To test this module with real bank data,

Type on the shell:

    $ ppit set web.ib.mizuhobank.co.jp

$EDITOR launches, then set your account information using L<Config::Pit> like the bellow.

    ----
    consumer_id: '123455678'
    password: 'p45sW0rD'
    questions:
        '母親の誕生日はいつですか（例：５月１４日）' : '１０月１日'
        '最も年齢の近い兄弟姉妹の誕生日はいつですか（例：２月１０日）' : '１２月２日'
        '応援しているスポーツチームの名前は何ですか' : '阪神タイガース'

set environment variable C<MIZUHO_TEST_CONFIG>, instead of I<web.ib.mizuhobank.co.jp>.

    $ export MIZUHO_TEST_CONFIG=just_testing_mizuho
    $ ppit set just_testing_mizuho


=head1 SEE ALSO

L<Finance::OFX::Parse::Simple>

=head1 AUTHOR

Atsushi Nagase <ngs@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Atsushi Nagase <ngs@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
