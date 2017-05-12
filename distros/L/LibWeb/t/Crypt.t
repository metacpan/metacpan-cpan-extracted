# -*- perl -*-

# $Id: Crypt.t,v 1.5 2000/07/08 14:38:45 ckyc Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use lib '..','../blib/lib','../blib/arch';

# Test to see if dependencies have been installed.
eval "use Crypt::CBC";
if ($@) {
    warn "Crypt::CBC module not installed.\n";
    print "1..0\n";
    exit;
}

my $cipher_algo;
eval "use Crypt::IDEA"; $cipher_algo = 'Crypt::IDEA' if !$@;
eval "use Crypt::DES"; $cipher_algo = 'Crypt::DES' if !$@;
eval "use Crypt::Blowfish"; $cipher_algo = 'Crypt::Blowfish' if !$@;
unless ( defined $cipher_algo ) {
    warn "Crypt::Blowfish/Crypt::DES/Crypt::IDEA module not installed.\n";
    print "1..0\n";
    exit;
}

print "1..9\n";

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{QUERY_STRING}    = 'game=chess&game=checkers&weather=dull';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'the.good.ship.lollypop.com';
$ENV{REQUEST_URI}     = "$ENV{SCRIPT_NAME}$ENV{PATH_INFO}?$ENV{QUERY_STRING}";
$ENV{HTTP_LOVE}       = 'true';
$ENV{DOCUMENT_ROOT}   = '/home/puffy/public_html';
$ENV{HTTP_HOST}       = 'www.puffy.dom';

# rc
my $rc =  './eg/dot_lwrc';

# Subroutines.
sub test {
    local($^W) = 0;
    my($num, $true, $msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

# test_LibWeb_Crypt
eval "use LibWeb::Crypt";
test(1, !$@, "Could not load LibWeb::Crypt module.  $@");

my $crypt;
eval { $crypt = LibWeb::Crypt->new(); };
test(2, !$@, "LibWeb::Crypt cannot be instantiated.  $@");

test(3, $cipher_algo,
     'Crypt::Blowfish or Crypt::DES or Crypt::IDEA not found.');

if ($crypt && $cipher_algo) {    
    my $is_encrypt_cipher_diff_data_ok;
    eval { $is_encrypt_cipher_diff_data_ok = $crypt->encrypt_cipher(
								    -data => 'hello world',
								    -key => '1234abcd',
								    -algorithm => $cipher_algo,
								    -format => 'hex'
								   )
	     ne $crypt->encrypt_cipher(
				       -data => 'hello world!',
				       -key => '1234abcd',
				       -algorithm => $cipher_algo,
				       -format => 'hex'
				      );
       };
    test(4, $is_encrypt_cipher_diff_data_ok, 'LibWeb::Crypt::encrypt_cipher diff_datafailed.');
    
    my $is_encrypt_cipher_diff_key_ok;
    my $cipher;
    eval { 
	$cipher = $crypt->encrypt_cipher(
					 -data => 'hello world',
					 -key => '1234abcd',
					 -algorithm => $cipher_algo,
					 -format => 'hex'
					);
	$is_encrypt_cipher_diff_key_ok = $cipher 
	  ne $crypt->encrypt_cipher(
				    -data => 'hello world',
				    -key => '1234abce',
				    -algorithm => $cipher_algo,
				    -format => 'hex'
				   );
    };
    test(5, $is_encrypt_cipher_diff_key_ok, 'LibWeb::Crypt::encrypt_cipher diff_key failed.');
    
    my $is_decrypt_cipher_pos_ok;
    eval { $is_decrypt_cipher_pos_ok = $crypt->decrypt_cipher(
							      -cipher => $cipher,
							      -key => '1234abcd',
							      -algorithm => $cipher_algo,
							      -format => 'hex'
							     )
	     eq $crypt->decrypt_cipher(
				       -cipher => $cipher,
				       -key => '1234abcd',
				       -algorithm => $cipher_algo,
				       -format => 'hex'
				      );
       };
    test(6, $is_decrypt_cipher_pos_ok, 'LibWeb::Crypt::decrypt_cipher positively failed.');
    
    my $is_decrypt_cipher_neg_ok;
    eval { $is_decrypt_cipher_neg_ok = $crypt->decrypt_cipher(
							      -cipher => $cipher,
							      -key => '1234abce',
							      -algorithm => $cipher_algo,
							      -format => 'hex'
							     )
	     ne 'hello world';
       };
    test(7, $is_decrypt_cipher_neg_ok, 'LibWeb::Crypt::decrypt_cipher negatively failed.');
    
    my $is_encrypt_password_pos_ok;
    eval {
	my $encrypted_pass = $crypt->encrypt_password('pineapple');
	$is_encrypt_password_pos_ok = crypt('pineapple', $encrypted_pass)
	  eq $encrypted_pass;
    };
    test(8, $is_encrypt_password_pos_ok, 'LibWeb::Crypt::encrypt_password positively failed.');
    
    my $is_encrypt_password_neg_ok;
    eval {
	my $encrypted_pass = $crypt->encrypt_password('pineapple');
	$is_encrypt_password_pos_ok = crypt('pinesapple', $encrypted_pass)
	  ne $encrypted_pass;
    };
    test(9, $is_encrypt_password_pos_ok, 'LibWeb::Crypt::encrypt_password negatively failed.');
}
