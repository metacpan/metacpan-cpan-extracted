package Finance::Bank::AU::StGeorge;

use 5.005;
use HTTP::Request::Common qw/POST/;
use WWW::Mechanize;
use strict;

use vars qw($VERSION $IBANK_URL $ERROR);

$VERSION = '0.01';
$IBANK_URL = "https://ibank.stgeorge.com.au/scripts/ibank.dll?ibank";
$ERROR = '';

sub new
{
    my ($class, %args) = @_;

    my $self = bless {
	_ua   => WWW::Mechanize->new(autocheck => 1),
	card  => "",
	pin   => "",
	pass  => "",
	issue => 1,
    }, $class;

    return $self->_set(%args);
}

sub _set
{
    my ($self, %args) = @_;

    $self->{lc $_} = $args{$_}
	foreach grep !/^_/ && exists $self->{lc $_}, keys %args;

    return $self;
}

sub logged_in
{
    my ($self) = @_;
    return unless $self->{_params};
    return unless $self->{_params}{Session};
}

sub login
{
    my ($self, %args) = @_;

    $self = $self->new(%args) unless ref $self;

    my $params = $self->{_params} ||= {
	Route   => "IBS",
	Id      => "JBANK.12.P",
	origin  => "ABA",
	Session => "",
    };

    return $self if $params->{Session};

    my $ua = $self->{_ua};
    $ua->env_proxy;
    $ua->get("https://ibank.stgeorge.com.au/html/index.asp");

    my ($popup_url) = $ua->content =~ m|window\.open\(\"([^\"]+)\"|;

    $ua->get($popup_url);

    # one-time warnings
    $ua->form(1);
    $ua->submit();

    # login
    my $form = $ua->form(1);
    $form->value(Card     => $self->{card});
    $form->value(Pin      => $self->{pin});
    $form->value(LastName => $self->{pass});
    $form->value(hWidth   => 800);
    $form->value(hHeight  => 600);
    $form->value(Issue    => $self->{issue});
    $ua->click();

    # scrape out session id's and stuff
    for ($ua->content)
    {
	($params->{Route})   = $1 if /route=([^\&]+)/m;
	($params->{Id})      = $1 if /clid=([^\&]+)/m;
	($params->{origin})  = $1 if /origin=([^\&]+)/m;
	($params->{Session}) = $1 if /Session=([a-f0-9]{32})/m;
    }

    return $self if $params->{Session};
    return;
}

sub logout
{
    my ($self) = @_;

    $self->logged_in or return;

    my $ua = $self->{_ua};

    $ua->request(POST $IBANK_URL, [
	route  => "IBS",
	params => _format_params(%{ $self->{_params} }, Tran => "Logout"),
    ]);

    return 1;
}

sub accounts
{
    my ($self, %args) = @_;

    $self = $self->new(%args) unless ref $self;
    $self->login or return;

    my $ua = $self->{_ua};

    my $accounts = $self->{_accounts};

    if (not $accounts or $args{reload})
    {
	$ua->request(POST $IBANK_URL, [
	    route  => "IBS",
	    params => _format_params(%{ $self->{_params} }, Tran => "BrowseAccounts"),
	]);

	$accounts = $self->{_accounts} = [ _parse_params($ua->content) ];
    }

    my @ret;

    foreach (@$accounts)
    {
	next unless ref $_;
	next unless ($args{type} ||= "ACC") eq "ALL" or $args{type} eq $_->{Type};

	$_->{_parent} = $self;

	if ($_->{Type} eq "ACC")
	{
	    push @ret, bless $_, "Finance::Bank::AU::StGeorge::Account";
	}
	elsif ($_->{Type} eq "ThirdParty")
	{
	    push @ret, bless $_, "Finance::Bank::AU::StGeorge::ForeignAccount";
	}
    }

    return wantarray ? @ret : $ret[0];
}

sub _account_detail
{
    my ($self, $acc, %args) = @_;

    my $ua = $self->{_ua};

    $ua->request(POST $IBANK_URL, [
	route  => "IBS",
	params => _format_params(%{ $self->{_params} },
	    Tran        => "BrowseDetail",
	    Type        => "ACC", # ALL w/o Account and AccountCode
	    Account     => $acc->number,
	    AccountCode => $acc->code,
	    RequestFlag => "BCT",
	),
    ]);

    return _parse_params($ua->content);
}

sub _account_history_csv
{
    my ($self, $acc, %args) = @_;

    my $ua = $self->{_ua};

    $ua->request(POST $IBANK_URL, [
	route  => "IBS",
	params => _format_params(%{ $self->{_params} },
	    Tran        => "ExportAccountHistory",
	    Type        => "ACC",
	    Account     => $acc->number,
	    AccountCode => $acc->code,
	    Format      => "CSV",
	    $args{start} ? (FromDate => $args{start}) : (), # 20050123
	    $args{end}   ? (ToDate   => $args{end})   : (), # 20050123
	    DateFormat  => "%d/%m/%Y",
	),
    ]);

    my @ret;
    my @fields;

    foreach (split /\r?\n/, (_parse_params($ua->content))[0])
    {
	if (@fields)
	{
	    my %ret;
	    @ret{ @fields } = split /,/, $_;
	    push @ret, bless \%ret, "Finance::Bank::AU::StGeorge::History";
	}
	else
	{
	    @fields = split /,/, $_;
	}
    }

    return @ret;
}

sub _transfer
{
    my ($self, $from, $to, %args) = @_;

    unless ($from->type eq "ACC")
    {
	die "Can only tranfer from a local account: ".$from->type."\n";
    }

    unless ($args{amount} =~ /^\d+\.\d\d$/)
    {
	die "You must specify a valid amount to transfer\n";
    }

    unless ($to->type eq "ACC" or $args{payer})
    {
	die "You must specify a payer name to third party transfers\n";
    }

    my $ua = $self->{_ua};

    $ua->request(POST $IBANK_URL, [
	route  => "IBS",
	params => _format_params(%{ $self->{_params} },
	    Tran          => "Payment",
	    Mode          => "C",
	    Frequency     => "now",
	    NotifyByEmail => "false",
	    Type          => $from->type,
	    Account       => $from->account,
	    AccountCode   => $from->code,
	)._format_params(
	    ToType        => $to->type,
	    $to->type eq "ACC" ? (
		ToAccount     => $to->account,
		ToAccountCode => $to->code
	    ) : (
		ToAccount     => $to->account,
	    ),
	    Amount        => $args{amount},
	    $to->type ne "ACC" ? (
		Payer         => $args{payer},
	    ) : (),
	    Reference     => $args{reference} || "Funding Terrorism",
	),
    ]);

    my @ret = _parse_params($ua->content);

    if (@ret == 1 and $ret[0]->{Receipt})
    {
	# adjust balances on local accounts if available
	$from->{AvailBalance} = $ret[0]->{FromAvailBalance}
	    if length $ret[0]->{FromAvailBalance};
	$from->{Balance} = $ret[0]->{FromBalance}
	    if length $ret[0]->{FromBalance};
	$to->{AvailBalance} = $ret[0]->{ToAvailBalance}
	    if length $ret[0]->{ToAvailBalance};
	$to->{Balance} = $ret[0]->{ToBalance}
	    if length $ret[0]->{ToBalance};

	return bless $ret[0], "Finance::Bank::AU::StGeorge::Receipt";
    }

    return;
}

# sub _account_history
# {
#     my ($self, $acc, %args) = @_;
# 
#     my $ua = $self->{_ua};
# 
#     $ua->request(POST $IBANK_URL, [
# 	route  => "IBS",
# 	params => _format_params(
# 	    %{ $self->{_params} },
# 	    Tran        => "BrowseDetail",
# 	    Type        => "ACC",
# 	    Account     => $acc->number,
# 	    AccountCode => $acc->code,
# 	    RequestFlag => "H",
# 	    $args{start} ? (FromDate => $args{start}) : (), # 20050123 / -30
# 	    $args{end}   ? (ToDate   => $args{end})   : (), # 20050123
# 	),
#     ]);
# 
#     return _parse_params($ua->content);
# }

sub DESTROY
{
    shift->logout;
}

sub _format_params
{
    my $ret;

    while (my ($k, $v) = splice(@_, 0, 2))
    {
	$ret .= join(chr(0x1c), $k, $v).chr(0x1d);
    }

    $ret .= chr(0x1e);

    return $ret;
}

sub _parse_params
{
    my @ret;

    foreach my $r (split /\x1e/, $_[0])
    {
	my $p = {};

	foreach my $g (split /\x1d/, $r)
	{
	    my ($k, @v) = split /\x1c/, $g, -1;

	    if (@v > 1 or exists $p->{$k})
	    {
		unshift @v, delete $p->{$k}
		    if exists $p->{$k};

		push @{ $p->{$k} }, @v;
	    }
	    elsif (@v)
	    {
		$p->{$k} = $v[0];
	    }
	    else
	    {
		$p = $k;
	    }
	}

	push @ret, $p;
    }

    unless (shift(@ret) =~ /^OK\w+$/)
    {
	$ERROR = $ret[0]->{Message} if @ret;
	$ERROR ||= "Non-OK Response";
	return;
    }

    return @ret;
}

package Finance::Bank::AU::StGeorge::Account;

# 'Icon'         => 'savings.gif',
# 'Flags'        => 'WDHBIER',
# 'Account'      => '0000000000000',
# 'AccountCode'  => 'SAV',
# 'AccountTitle' => '',
# 'DEUser'       => '',
# 'Number'       => '0000000000000', # same as Account
# 'SubProdCode'  => '0000',
# 'Type'         => 'ACC',
# 'IsSegmented'  => 'false',
# 'TypeName'     => 'Savings',
# 'Balance'      => '0.00',
# 'Bsb'          => '',
# 'Name'         => '',
# 'AvailBalance' => '0.00'

sub type { $_[0]->{Type} }
sub code { $_[0]->{AccountCode} }
sub number { $_[0]->{Account} }
sub account { $_[0]->number }
sub name { $_[0]->{TypeName} }
sub balance { $_[0]->{Balance} }
sub available { $_[0]->{AvailBalance} }

sub detail { ($_[0]->{_parent}->_account_detail(@_))[0] }
sub history { $_[0]->{_parent}->_account_history_csv(@_) }
sub transfer { $_[0]->{_parent}->_transfer(@_) }

package Finance::Bank::AU::StGeorge::ForeignAccount;

# 'InternetTP' => 'true',
# 'Icon'       => 'ithirdparty.gif',
# 'Payee'      => '000000-000000000', # Bsb-Account
# 'Account'    => '000000000',
# 'Number'     => '000000-000000000', # Bsb-Account
# 'Type'       => 'ThirdParty',
# 'Bsb'        => '000000',
# 'Name'       => ''

sub type { $_[0]->{Type} }
sub bsb { $_[0]->{Bsb} }
sub number { $_[0]->{Account} }
sub account { join("-", $_[0]->bsb, $_[0]->number) }
sub name { $_[0]->{Name} }

package Finance::Bank::AU::StGeorge::History;

# 'Debit'       => '0.00', # empty string if credit
# 'Balance'     => '0.00',
# 'Credit'      => '0.00', # empty string if debit
# 'Description' => '',
# 'Date'        => '24/01/2005'

sub date { $_[0]->{Date} }
sub debit { $_[0]->{Debit} }
sub credit { $_[0]->{Credit} }
sub balance { $_[0]->{Balance} }
sub description { $_[0]->{Description} }

package Finance::Bank::AU::StGeorge::Receipt;

# 'Receipt'          => '', # the big text field
# 'Message'          => '',
# 'ToAvailBalance'   => '0.00',
# 'ToBalance'        => '0.00',
# 'FromAvailBalance' => '0.00',
# 'FromBalance'      => '0.00',

sub receipt { $_[0]->{Receipt} }

1;
__END__

=head1 NAME

Finance::Bank::AU::StGeorge - Perl library for banking online with StGeorge

=head1 SYNOPSIS

  use Finance::Bank::AU::StGeorge;

  my $stg = Finance::Bank::AU::StGeorge->login(
    card => "",
    pin  => "",
    pass => "",
  );

  foreach my $acc ($stg->accounts)
  {
    printf "%s\n", $acc->balance;

    foreach my $hist ($acc->history)
    {
      printf "%s %s\n", $hist->date, $hist->balance;
    }
  }

=head1 DESCRIPTION

Stub documentation for Finance::Bank::AU::StGeorge, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Iain Wade, E<lt>iwade@optusnet.com.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Iain Wade

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
