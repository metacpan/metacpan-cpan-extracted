#!/usr/bin/perl

use Finance::Bank::Wachovia;
use strict;
$| = 1;

our $VERSION = 0.4;

# set option defaults
my $opts = {
	keyfile => $ENV{HOME}.'/.wachovia', # file that stores encrypted login info + account number
};

# parse command line options -- see perldocs for info
for (@ARGV){
	$opts->{lc($1)} = $2 if /--(\w+)=(.+)/g;	
	$opts->{lc($1)} = 1 if /^--(\w+)$/g;
}  

# Since I can never remember myself which one of these it is, then 
# why not make them all valid?
my $userid;
my $password;
$opts->{user_id} = $userid if( $userid = $opts->{userid} 
	|| $opts->{user_id}
	|| $opts->{user}
	|| $opts->{login}
	|| $opts->{'user-id'}
	|| $opts->{id}
	|| $opts->{name}
	);
	
$opts->{password} = $password if( $password = $opts->{password}
	|| $opts->{pass}
	|| $opts->{pw}
	);

if( $opts->{key} ){
	eval {
		require Crypt::CBC;
		import Crypt::CBC;
	};
	if($@){ die "Must have Crypt::CBC and Crypt::DES_PP module installed to use --key feature: $@\n" }

	# if here, then user provided key + some info, so we want to preserve whatever it is they provided
	# while keeping whatever it is they didn't provide.
	my $new_opts = {};
	my $file_opts = get_account_info( $opts->{keyfile}, $opts->{key} );
	for(keys %$opts){ $new_opts->{$_} = $opts->{$_} }
	for(keys %$file_opts){ $new_opts->{$_} = $file_opts->{$_} unless $new_opts->{$_} }
	$opts = $new_opts;
	save_account_info( $opts );
}
else{
	# if here, then the user must provide all the info them self, and they don't plan on keeping it
	# in a key-file.
	unless( ( $opts->{can} && $opts->{pin} && $opts->{codeword} ) || ( $opts->{userid} && $opts->{password} ) ){
		print "Need either login info, or file-key to login.  see `perldoc wachovia.pl`\n";	
		exit(1);
	}	
}
my $x;

my %login_info = $opts->{userid}
	? ( user_id => $opts->{userid}, password => $opts->{password} )
	: ( customer_access_number => $opts->{can}, pin => $opts->{pin}, code_word => $opts->{codeword} );
	
my $wachovia  = Finance::Bank::Wachovia->new( %login_info ) 
	or die Finance::Bank::Wachovia->ErrStr;

my @account_nums = $wachovia->account_numbers();

die $wachovia->ErrStr()
	if $wachovia->ErrStr;

my($num, $name, $type, $bal) = qw/Number Name Type Balance/;
format Summary = 
@<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>>>	  
$num,              $name, 		              $bal
.
$~ = 'Summary';
write;
print <<EOF;
=================  =========================  ===========
EOF

foreach $num ( @account_nums ){
	my $a = $wachovia->account( $num );
	$name = $a->name    or die $a->ErrStr;
	#$type = $a->type    or die $a->ErrStr;
	$bal  = $a->balance or die $a->ErrStr;
	write;
}



#==============================================================================  
# Fills the options hash with account info from the local .wachovia file
sub get_account_info {
	my($keyfile, $key) = @_;
	my $opts;
	return unless -e $keyfile;
	open( F, $keyfile ) or die "Can't open ".$keyfile." for reading: $!";
	my $cipher = Crypt::CBC->new({
		'key'=> $key,
		'cipher'=> 'DES_PP',
		'iv'=> '%_j,!z"{'
	});
	my $plaintext = $cipher->decrypt( <F> );
	my @opts = split( /\//, $plaintext );
	for( @opts ){
		my($k, $v) = split(/=>/);
		$opts->{$k} = $v;	
	}
	return $opts;
}

# Writes an MD5 hash for the hash info.
sub save_account_info {
	my $opts = shift;
	open( F, '>', $opts->{keyfile} ) or die "Can't open ".$opts->{keyfile}." for writing: $!";
	my $cipher = Crypt::CBC->new({
		'key'=> $opts->{key},
		'cipher'=> 'DES_PP',
		'iv'=> '%_j,!z"{'
	});
	my $ciphertext = $cipher->encrypt( join('/', (map { "$_=>".$opts->{$_} } keys %$opts) ) );
	print F $ciphertext;
	close( F );
	return 1;
}


__END__

=begin

=head1 NAME

wachovia_summary.pl - program bundled with Finance::Bank::Wachovia dumps quick summary of all accounts.

=head1 SYNOPSIS

Use this program from the command line to get a miniature report on your wachovia savings/checkings account.

You can provide the login info every time you run the command:

  wachovia_summary.pl --can=123456789 --pin=1234 --codeword=foo
  
  OR
  
  wachovia_summary.pl --userid=foo --password=bar
 
NOTE ABOUT LOGINS: you can either use the customer access number method (--can --pin and --codeword) or the user id method ( --userid and --password )
it depends on how you log into the wachovia website.
  
But that's alot to type in every time you want to check your accounts.  It's easier to provide the login info
and have the program store it in a file ( "~/.wachovia" by default ).  The file is encrypted (thanks Doug)
and you use a "key" to decrypt the contents.  The first time you run the command, you have to include all the login/account
info PLUS a password (key) and optionally a file path to use.

  wachovia_summary.pl --can=123456789 --pin=1234 --codeword=foo --key=password --file=.checking
  
After doing that, you can have the same affect as typing all that in just by typing:

  wachovia_summary.pl --key=password --file=~/.checking
  
And if you choose to use the default "~/.wachovia" file path (best choice for the account you'll check most often) then
you can omit the --file argument.

  wachovia_summary.pl --key=password
  
And if you decide that you want to change the account number, or your PIN number needs to be changed, then just supply that 
changed info plus the key and it will update your key-file:

  wachovia_summary.pl --key=password --pin=4321
  
Now your pin will be updated, all else will remain the untouched.  Remember, the only time you need to provide the --file argument 
is when you do want to use the default "~/.wachovia" file path.

=head1 DESCRIPTION

Uses Finance::Bank::Wachovia (which retrieves, parses, and objectifies your account info) and generates a report.

=head1 ARGS

=head2 --can

Your customer access number.

=head2 --pin

Your 4-digit PIN.

=head2 --codeword

Your super secret word.

=head2 --key

Optional. The password you use if you want to be smart and lazy.  Read SYNOPSIS for details.

=head2 --keyfile

The file you want to store your login/account info if you are using --key.  It's optional, and "~/.wachovia" is the default.  Read SYNOPSIS for details.

=head1 THANKS

Larry Wall for Perl.

Doug Feuerbach for so many things, but for this instance of thankfulness: the encryption/decryption routines.

=head1 AUTHOR

Jim Garvin E<lt>jg.perl@thegarvin.comE<gt>

Copyright 2004 by Jim Garvin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<Finance::Bank::Wachovia>

=cut



