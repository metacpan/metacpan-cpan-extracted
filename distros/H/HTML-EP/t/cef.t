# -*- perl -*-

my $num_tests = 3;

use strict;
use HTML::EP ();

eval { require CGI::EncryptForm };
if ($@) {
    print "1..0\n";
    exit 0;
}
print "1..$num_tests\n";

$| = 1;
$^W = 1;

{
    my $numTests = 0;
    sub Test($;@) {
	my $result = shift;
	if (@_ > 0) { printf(@_); }
	++$numTests;
	if (!$result) { print "not " };
	print "ok $numTests\n";
	$result;
    }
}

sub Test2($$;@) {
    my $a = shift;
    my $b = shift;
    my $c = ($a eq $b);
    if (!Test($c, @_)) {
	print("Expected $b, got $a\n");
    }
    $c;
}

$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = "a=1&b=2&c=3";

my $input = <<'EOF';
<ep-package name=HTML::EP::CGIEncryptForm>
<ep-perl>
  my $self = $_;
  my $cgi = $self->{'cgi'};
  $self->{'settings'}->{'a'} = $cgi->param('a');
  $self->{'settings'}->{'b'} = $cgi->param('b');
  $self->{'settings'}->{'c'} = $cgi->param('c');
  ''
</ep-perl>
<ep-cef-encrypt secret_key="itsok" source="settings" dest="enc_settings">
EOF
my $parser = HTML::EP->new();
Test2($parser->Run($input), "\n\n\n", "Encrypting\n");
my $cef = $parser->{'_ep_cgiencryptform_handle'};
Test($cef);
$cef->secret_key("itsok");



$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = "settings=" . CGI->escape($parser->{'enc_settings'});
undef @CGI::QUERY_PARAM; # Arrgh! CGI caches :-(
$input = <<'EOF';
<ep-package name=HTML::EP::CGIEncryptForm>
<ep-cef-decrypt secret_key="itsok" source="cgi->settings" dest="settings">
a=$settings->a$,b=$settings->b$,c=$settings->c$
EOF
$parser = HTML::EP->new();
Test2($parser->Run($input), "\n\na=1,b=2,c=3\n", "Decrypting\n");
