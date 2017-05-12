# This file tests JSON::Create's response to code references in its
# input.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Parse 'valid_json';
use JSON::Create 'create_json';

# Store of warnings.

my $warning;

# Trap warnings in $warning.

$SIG{__WARN__} = sub { $warning = "@_"; };

my $code1 = sub {
    print "# Greetings, Earthlings.\n";
};
my $hascoderef1 = {stuff => $code1};
my $outcode1 = create_json ($hascoderef1);
ok (! defined $outcode1, "Code reference returns the undefined value");
ok ($warning, "Got a warning");
like ($warning, qr/cannot be serialized/i, "Warning is the right kind of thing");
note ($warning);

# Test the code reference callback
{
    $warning = undef;
    my $gotcode;
    sub coderef {
	my ($code) = @_;
	print "# Here we go bo.\n";
	$gotcode = $code;
	return 'null';
    };
    my $jc = JSON::Create->new ();
    $jc->type_handler (\& coderef);
    my $outcode2 = $jc->run ($hascoderef1);
    ok (defined $outcode2, "output is defined");
    ok (valid_json ($outcode2), "output is valid");
    note ($outcode2);
    ok ($gotcode, "Callback was called");
    ok (ref $gotcode eq 'CODE', "Callback was called with code");
    ok (! $warning, "No warnings using code callback");
};


done_testing ();
