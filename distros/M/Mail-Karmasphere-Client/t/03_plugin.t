use strict;
use warnings;
use blib;
use Test::More;
# Use these subroutines as check-hooks
use vars qw($CONNECT $CONTENT);

my $DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

eval {
	require Mail::SpamAssassin;
	if ($Mail::SpamAssassin::VERSION < 3.001000) {
		warn "The SpamAssassin plugin requires SpamAssassin version 3.10, but only version $Mail::SpamAssassin::VERSION was found";
		die "SpamAssassin too old.";
	}
	require Mail::SpamAssassin::Plugin;
};

if ($@) {
	plan skip_all => "Could not load Mail::SpamAssassin::Plugin";
}
else {
	plan tests => 35;
}

use_ok('Mail::SpamAssassin', 3.0);
use_ok('Mail::SpamAssassin::Conf');
use_ok('Mail::SpamAssassin::PerMsgStatus');
use_ok('Mail::SpamAssassin::Plugin::Karmasphere');

my $check_plugin = '';
eval {
	require Mail::SpamAssassin::Plugin::Check;
	$check_plugin = 'loadplugin Mail::SpamAssassin::Plugin::Check';
};

my $config_text = <<"EOR";

$check_plugin
loadplugin Mail::SpamAssassin::Plugin::Karmasphere

karma_principal		public
karma_credentials	password

karma_range	KARMA_CONNECT_POSITIVE	connect  0.1   1000
karma_range	KARMA_CONNECT_NEGATIVE	connect -1000 -0.1
karma_range	KARMA_CONTENT_POSITIVE	content  0.1   1000
karma_range	KARMA_CONTENT_NEGATIVE	content -1000 -0.1

karma_feedset content karmasphere.nonexistent

score	KARMA_CONNECT_POSITIVE	-1.0
score	KARMA_CONNECT_NEGATIVE	 1.0
score	KARMA_CONTENT_POSITIVE	-2.0
score	KARMA_CONTENT_NEGATIVE	 2.0

add_header all Karma-Connect _KARMASCORE(connect)_: _KARMADATA(connect)_
add_header all Karma-Content _KARMASCORE(content)_: _KARMADATA(content)_

EOR

my %args = (config_text	=> $config_text);
$args{debug} = 'all' if $DEBUG;
my $main = new Mail::SpamAssassin(\%args);

{
	no strict qw(refs);
	no warnings qw(redefine);
	*{"Mail::SpamAssassin::Plugin::Karmasphere::add_connect_other"} =
	sub {
		ok(1, 'add_connect_other called');
		$CONNECT->(@_) if $CONNECT;
	};

	*{"Mail::SpamAssassin::Plugin::Karmasphere::add_content_other"} =
	sub {
		ok(1, 'add_content_other called');
		$CONTENT->(@_) if $CONTENT;
	};
}

$CONNECT = sub {
	my ($self, $scanner, $query) = @_;
	ok(defined $query, 'Query is defined in add_connect_other');
	ok(! $query->has_identities, 'Query has no identities');
};
$CONTENT = sub {
	my ($self, $scanner, $query) = @_;
	ok(defined $query, 'Query is defined in add_content_other');
	ok(! $query->has_identities, 'Query has no identities');
};
is($main->lint_rules(), 0, 'SpamAssassin lint succeeded');

my $time = time();
my $id = "$time\@lint_rules";

my $testmsg = <<"EOM";
From: from-sender\@that.net
Authentication-Results: spf.checker.net
        smtp.mail=spf-sender\@that.net; spf=pass
Authentication-Results: dkim.checker.net
        header.from=dkim-sender\@that.net; domainkeys=neutral (not signed);
        dkim=neutral (not signed)
Received: from previous.host.net ([123.45.6.7]) by
	this.host.net with esmtp (Exim 4.54) id $id for
	user\@this.host.net; Fri, 05 May 2006 19:51:32 +0100
Subject: my-subject
Message-Id:  <$id>

Hi, here are some URLs for you.
http://127.0.0.4/
http://www.anarres.org/
http://www.spammersrus.com/

--
Shevek

EOM

my $mail = $main->parse($testmsg, 1);
$CONNECT = sub {
	my ($self, $scanner, $query) = @_;
	ok(defined $query, 'Query is defined in add_connect_other');
	ok($query->has_identities, 'Query has identities');
	is(4, scalar(@{ $query->identities }), 'Query has 4 identities');
	ok($query->has_composites, 'Query has composites');
	is('karmasphere.email-sender', $query->composites->[0],
					'Connection composite is correct.');
};
$CONTENT = sub {
	my ($self, $scanner, $query) = @_;
	ok(defined $query, 'Query is defined in add_content_other');
	ok($query->has_identities, 'Query has identities');
	is(3, scalar(@{ $query->identities }), 'Query has 3 identities');
	is('karmasphere.nonexistent', $query->composites->[0],
					'Content composite is correct.');
	# Prevent the query from being sent to a duff feedset.
	$query->{Composites} = [ 'karmasphere.email-body' ];
};
my $status = $main->check($mail);

# Now we hack the internals of the API to get some useful results.
my $tag = $status->_get_tag('KARMASCORE', 'connect');
ok(defined $tag, 'Got a connect tag');
like($tag, qr/^-?[0-9]+$/, 'Connect tag is a number');

my $str = $status->_replace_tags("_KARMASCORE(connect)_");
ok(defined $str, 'Replace score tag returned a good value');
unlike($str, qr/KARMA/, 'Karma score tag is gone.');
like($str, qr/^-?[0-9]+$/, 'Karma score tag was replaced by a number.');

$str = $status->_replace_tags("_KARMADATA(connect)_");
ok(defined $str, 'Replace data tag returned a good value');
unlike($str, qr/KARMA/, 'Karma data tag is gone.');

$str = $status->_replace_tags("_KARMAFACTS(connect)_");
ok(defined $str, 'Replace facts tag returned a good value');
unlike($str, qr/KARMA/, 'Karma facts tag is gone.');
my $aryref = eval $str;
die $@ if $@;
ok(!$@, "Karma facts tag value eval'd OK");
is(ref $aryref, 'ARRAY', "Karma facts tag value eval'd to an array.");

my $output = $status->rewrite_mail();
print STDERR $output, "\n" if $DEBUG;
like($output, qr/^X-Spam-Karma-Connect:/ms, 'Karma-Connect header created');
like($output, qr/^X-Spam-Karma-Content:/ms, 'Karma-Content header created');
