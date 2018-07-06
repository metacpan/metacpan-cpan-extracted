package Finance::Bank::LaPoste;

use strict;

use Carp qw(carp croak);
use Graphics::Magick;
use HTTP::Cookies;
use LWP::UserAgent;
use HTML::Parser;
use HTML::Form;
use Digest::MD5();

our $VERSION = '8.02';

# $Id: $
# $Log: LaPoste.pm,v $

=pod

=head1 NAME

Finance::Bank::LaPoste -  Check your "La Poste" accounts from Perl

=head1 SYNOPSIS

 use Finance::Bank::LaPoste;

 my @accounts = Finance::Bank::LaPoste->check_balance(
    username => "0120123456L",	# your main account is something like 
				# 0123456 L 012, stick it together with the region first
    password => "123456",	# a password is usually 6 numbers
    all_accounts => 1,          # if you want credit card and savings accounts
 );

 foreach my $account (@accounts) {
    print "Name: ", $account->name, " ", $account->owner, " Account_no: ", $account->account_no, "\n", "*" x 80, "\n";
    print $_->as_string, "\n" foreach $account->statements;
 }

=head1 DESCRIPTION

This module provides a read-only interface to the Videoposte online banking
system at L<https://www.videoposte.com/>. You will need either Crypt::SSLeay
installed.

The interface of this module is similar to other Finance::Bank::* modules.

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and that
means B<BE CAREFUL>. You are encouraged, nay, expected, to audit the source
of this module yourself to reassure yourself that I am not doing anything
untoward with your banking data. This software is useful to me, but is
provided under B<NO GUARANTEE>, explicit or implied.

=cut

my $parse_table = sub {
    my ($html) = @_;
    my $h = HTML::Parser->new;

    my (@l, $row, $td, $href);
    $h->report_tags('td', 'tr', 'a');
    $h->handler(start => sub { 
        my ($tag, $attr) = @_;
        if ($tag eq 'tr') {
	    $row = [];
        } elsif ($tag eq 'td') {
	    push @$row, ('') x ($attr->{colspan} - 1) if $attr->{colspan};
	    $td = '';
        } elsif ($tag eq 'a') {
	    $href = $attr->{href} if defined $td;
        }
    }, 'tag,attr');
    $h->handler(end => sub { 
        my ($tag) = @_;
        if ($tag eq '/tr') {
	    push @l, $row if $row;
	    undef $row;
        } elsif ($tag eq '/td' && defined $td) {
	    $td =~ s/(
|&nbsp;|\s)+/ /g;
	    $td =~ s/^\s*//;
	    $td =~ s/\s*$//;
	    push @$row, $href ? [ $td, $href ] : $td;
	    $href = $td = undef;
        }
    }, 'tag');
    
    $h->handler(text => sub { 
        my ($text) = @_;
        $td .= " $text" if defined $td;
    }, 'text');
    $h->parse($html);

    \@l;
};

my $normalize_number = sub {
    my ($s) = @_;
    defined($s) or return 0;
    $s =~ s/\xC2?\xA0//; # non breakable space, both in UTF8 and latin1
    $s =~ s/ //;
    $s =~ s/,/./;
    $s + 0; # turn into a number
};

=pod

=head1 METHODS

=head2 new(username => "0120123456L", password => "123456", cb_accounts => 1, all_accounts => 0, feedback => sub { warn "Finance::Bank::LaPoste: $_[0]\n" })

Return an object . You can optionally provide to this method a LWP::UserAgent
object (argument named "ua"). You can also provide a function used for
feedback (useful for verbose mode or debugging) (argument named "feedback")

=cut

my $first_url = 'https://voscomptesenligne.labanquepostale.fr/voscomptes/canalXHTML/identif.ea?origin=particuliers';

sub _login {
    my ($self) = @_;
    $self->{feedback}->("login") if $self->{feedback};

    my $cookie_jar = HTTP::Cookies->new;
    my $response = $self->{ua}->request(HTTP::Request->new(GET => $first_url));
    $cookie_jar->extract_cookies($response);
    $self->{ua}->cookie_jar($cookie_jar);

    my %mangling_map = _get_number_mangling_map($self, _get_img_map_data($self, $response));
    my $password = join('', map { $mangling_map{$_} } split('', $self->{password}));

    my $form = HTML::Form->parse($response->content, $first_url);
    $form->value(username => $self->{username});
    $form->value(password => $password);

    push @{$self->{ua}->requests_redirectable}, 'POST';
    $response = $self->{ua}->request($form->click);
    $response->is_success or die "login failed\n" . $response->error_as_HTML;

    $self->{feedback}->("list accounts") if $self->{feedback};

    $response = _handle_javascript_redirects($self, $response);

    $self->{accounts} = [ _list_accounts($self, $response) ];
}

sub _handle_javascript_redirects {
    my ($self, $response) =@_;

    while ($response->content =~ /top.location.replace\(["'](.*)["']\)/) {	
	$response = $self->{ua}->request(HTTP::Request->new(GET => _rel_url($response, $1)));
	$response->is_success or die "login failed\n" . $response->error_as_HTML;
    }
    $response;
}

sub _rel_url {
    my ($response, $rel) = @_;
    my $base = $response->base;
    if ($rel =~ m!^/!) {
	$base =~ m!([^/]*//[^/]*)! && "$1$rel";
    } else {
	$base =~ s/\?.*//;
	_rel_fullurl("$base/../$rel");
    }
}

sub _rel_fullurl {
    my ($s) = @_;
    while ($s =~ s![^/]*/\.\./!!) {}
    $s;
}


sub _output { my $f = shift; open(my $F, ">$f") or die "output in file $f failed: $!\n"; print $F $_ foreach @_; 1 }

# to update %img_md5sum_to_number, set $debug_imgs to 1, 
# then rename /tmp/img*.xpm into /tmp/[0-9].xpm according to the image
# then do "md5sum /tmp/[0-9].xpm"
my $debug_imgs = 0;
my %img_md5sum_to_number = (
    'dbe97681a77bd75f811cd318e1b6def3' => 0,
    '264fc8643f2277ce7df738d8bf0d4533' => 1,
    'bc09366762776a5bca2161105607302b' => 2,
    '71a5e8344d0343928ff077cf292fc7e3' => 3,
    '50a363a8d16f6fbba5e8b14432e2d73e' => 4,
    'd8ce75d8bd5c64a2ed10deede9ad7bc9' => 5,
    '03c32205bcc9fa135b2a3d105dbb2644' => 6,
    'ab159c63f95caa870429812c0cd09ea5' => 7,
    '16454f3fb921be822f379682d0727f3f' => 8,
    '336809b2bb178abdb8beec26e523af34' => 9,
    '6110983d937627e8b2c131335c9c73e8' => 'blank',
);

sub _get_number_mangling_map {
    my ($self, $img_map_data) = @_;

    my $img_map=Graphics::Magick->new;
    $img_map->BlobToImage($img_map_data);
    $img_map->Threshold(threshold => '90%');

    my $size = 64;

    my $i = 0;
    my %map;
    for my $y (0 .. 3) {
	for my $x (0 .. 3) {

	    my $newimage = $img_map->Clone;
	    $newimage->Crop(geometry => 
			      sprintf("%dx%d+%d+%d",
				      12, 17,
				      25+ $x * ($size),
				      21 + $y * ($size)));
	    $newimage->Set(magick => 'xpm');
	    my ($img) = $newimage->ImageToBlob;
	    if ($debug_imgs) {
		_output("/tmp/img$x$y.xpm", $img);
	    }
	    my $md5sum = Digest::MD5::md5_hex($img);
	    my $number = $img_md5sum_to_number{$md5sum};
	    defined($number) or die "missing md5sum, please update \%img_md5sum_to_number (setting \$debug_imgs will help)\n";
	    $map{$number} = sprintf("%02d", $i);
	    $i++;
	}
    }
    %map;
}

sub _get_img_map_data {
    my ($self, $response) = @_;
    my ($url) = $response->content =~ /background:url\((loginform.*?)\)/;
    _GET_content($self, _rel_url($response, $url));
}

sub _GET_content {
    my ($self, $url) = @_;

    my $req = $self->{ua}->request(HTTP::Request->new(GET => $url));
    $req->is_success or die "getting $url failed\n" . $req->error_as_HTML;
    $req->content;
}

sub _list_accounts {
    my ($self, $response) = @_;
    my $html = $response->content;
    my @l = _list_accounts_one_page($self, $html);

    if ($self->{cb_accounts} || $self->{all_accounts}) {
        if (my ($url) = $html =~ m!<a href="(.*?mouvementsCarteDD.*?)"!) {
            $url =~ s/&amp;/&/g;
            push @l, _list_cb_accounts($self, $url);
        }
    }
    if ($self->{all_accounts}) {
        my $html = _GET_content($self, _rel_url($response, '/voscomptes/canalXHTML/comptesCommun/synthese_ep/afficheSyntheseEP-synthese_ep.ea'));
        push @l, _list_accounts_one_page($self, $html);
    }
    @l;
}

sub _list_accounts_one_page {
    my ($self, $html) = @_;
    my @l;

    my $flag = '';
    my ($url, $name, $owner, $account_no);

    foreach (split("\n", $html)) {
        if ($flag eq 'url' && m!<a href="(.*?)"!) {
            $url = $1;
        } elsif (m!<h3>(.*?)\s*</h3>(?:<span>(.*)</span>)?!) {
            $name = $1;
            $owner = $2;
        } elsif (m!num(?:&#233;|..?)ro de compte">.*</abbr>(.*?)</!) {
            $account_no = $1;
        } elsif (m!<span class="number">([\d\s,.+-]*)! && $url) {
            my $balance = $normalize_number->($1);
            push @l, { url => $url, balance => $balance, name => $name, owner => $owner, account_no => $account_no } if $url;
            $url = '';
        }

        if (/account-resume--banq|account-resume--saving/) {
            $flag = 'url';
        } else {
            $flag = '';
        }
    }

    @l;
}

sub _list_cb_accounts {
    my ($self, $url) = @_;

    my $response = $self->{ua}->request(HTTP::Request->new(GET => $url));
    $response->is_success or die "getting $url failed\n" . $response->error_as_HTML;

    my $accounts = $parse_table->($response->content);
    map {
	my ($account, $account_no, $balance) = grep { $_ ne '' } @$_;
	if (ref $account && $account_no) {
	    my $url = $account->[1];
	    $url =~ s/typeRecherche=1$/typeRecherche=10/; # 400 last operations
	    {
	        name => $account->[0],
	        account_no => $account_no, 
	        balance => $normalize_number->($balance),
		$url =~ /(releve_ccp|releve_cne|releve_cb|mouvementsCarteDD)\.ea/ ? (url => _rel_url($response, $url)) : (), 
	    };
	} else { () }
    } @$accounts;
}

sub new {
    my ($class, %opts) = @_;
    my $self = bless \%opts, $class;

    exists $self->{password} or croak "Must provide a password";
    exists $self->{username} or croak "Must provide a username";

    $self->{ua} ||= LWP::UserAgent->new(agent => 'Mozilla');

    $self->{ua}->add_handler(request_preprepare => sub {
        my ($request, $ua, $h) = @_;
        if ($request->uri =~ m!/\.\./!) {
            $request->uri(_rel_fullurl($request->uri));
        }
        #print $request->uri . "\n";
    });

    _login($self);
    $self;
}

sub default_account {
    die "default_account can't be used anymore";
}

=pod

=head2 check_balance(username => "0120123456L", password => "123456")

Return a list of account (F::B::LaPoste::Account) objects, one for each of
your bank accounts.

=cut

sub check_balance {
    my $self = &new;

    map { Finance::Bank::LaPoste::Account->new($self, %$_) } @{$self->{accounts}};
}

package Finance::Bank::LaPoste::Account;

=pod

=head1 Account methods

=head2 sort_code()

Return the sort code of the account. Currently, it returns an undefined
value.

=head2 name()

Returns the human-readable name of the account.

=head2 owner()

Return the account owner, if available.

=head2 account_no()

Return the account number, in the form C<0123456L012>.

=head2 balance()

Returns the balance of the account.

=head2 statements()

Return a list of Statement object (Finance::Bank::LaPoste::Statement).

=head2 currency()

Returns the currency of the account as a three letter ISO code (EUR, CHF,
etc.).

=cut

sub new {
    my ($class, $bank, %account) = @_;
    $account{$_} = $bank->{$_} foreach qw(ua feedback);
    bless \%account, $class;
}

sub sort_code  { undef }
sub name       { $_[0]{name} }
sub owner      { $_[0]{owner} }
sub account_no { $_[0]{account_no} }
sub balance    { $_[0]{balance} }
sub currency   { 'EUR' }
sub statements { 
    my ($self) = @_;
    $self->{url} or return;
    $self->{statements} ||= do {
    my $retry;
      retry:
	$self->{feedback}->("get statements") if $self->{feedback};
	my $response = $self->{ua}->request(HTTP::Request->new(GET => $self->{url}));
	$response->is_success or die "can't access account $self->{name} statements\n" . $response->error_as_HTML;

	my $html = $response->content;

	$self->{balance} ||= do {
	    my ($balance) = $html =~ m!<span class="amount">(.*?) &euro;</span>!;
	    $normalize_number->($balance);
	};
	my $l = $parse_table->($html);

	    @$l = map {
		my ($date, $description, $amount1, $amount2) = @$_;
		my $amount = $normalize_number->($amount2 || $amount1);
		$date && $date =~ m!(\d+)/(\d+)! ? [ $date, $description, $amount ] : ();
	    } @$l;

	[ map {
	    my ($date, $description, $amount) = @$_;
	    my ($day, $month, $year) = $date =~ m|(\d+)/(\d+)/(\d+)|;
	    Finance::Bank::LaPoste::Statement->new(day => $day, month => $month, year => $year, description => $description, amount => $amount);
	} @$l ];
    };
    @{$self->{statements}};
}

sub _rel_url { &Finance::Bank::LaPoste::_rel_url }


package Finance::Bank::LaPoste::Statement;

=pod

=head1 Statement methods

=head2 date()

Returns the date when the statement occured, in DD/MM/YY format.

=head2 description()

Returns a brief description of the statement.

=head2 amount()

Returns the amount of the statement (expressed in Euros or the account's
currency). Although the Crédit Mutuel website displays number in continental
format (i.e. with a coma as decimal separator), amount() returns a real
number.

=head2 as_string($separator)

Returns a tab-delimited representation of the statement. By default, it uses
a tabulation to separate the fields, but the user can provide its own
separator.

=cut

sub new {
    my ($class, %statement) = @_;
    bless \%statement, $class;
}

sub description { $_[0]{description} }
sub amount      { $_[0]{amount} }
sub date        { 
    my ($self) = @_;
    my ($year) = $self->{year} =~ /..(..)/; # only 2 digits for year
    "$year/$self->{month}/$self->{day}"
}

sub as_string { 
    my ($self, $separator) = @_;
    join($separator || "\t", $self->date, $self->{description}, $self->{amount});
}

1;

=pod

=head1 COPYRIGHT

Copyright 2002-2007, Pascal 'Pixel' Rigaux. All Rights Reserved. This module
can be redistributed under the same terms as Perl itself.

=head1 AUTHOR

Thanks to Cédric Bouvier for Finance::Bank::CreditMut
(and also to Simon Cozens and Briac Pilpré for various Finance::Bank::*)

=head1 SEE ALSO

Finance::Bank::BNPParibas, Finance::Bank::CreditMut

=cut
