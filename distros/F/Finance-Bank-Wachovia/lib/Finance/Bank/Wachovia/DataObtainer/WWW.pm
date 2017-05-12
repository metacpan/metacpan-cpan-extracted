package Finance::Bank::Wachovia::DataObtainer::WWW;

use WWW::Mechanize;
use HTTP::Cookies;
use Finance::Bank::Wachovia::DataObtainer::WWW::Parser;
use Finance::Bank::Wachovia::ErrorHandler;
use strict;
use warnings;

my $DEBUG = 1 if "@ARGV" =~ /--www-debug/;
my $CONFIRM_LOGIN = 1 if "@ARGV" =~ /--www-confirm/;
my @attrs;
our @ISA = qw/Finance::Bank::Wachovia::ErrorHandler/;

BEGIN{ 
	@attrs = qw(
		customer_access_number
		user_id
		password
		pin
		code_word
		cached_content		
		mech
		start_url
		logged_in
	);
	
	my $x = @__SUPER__::ATTRIBUTES;
	for( @attrs ){
		eval "sub _$_ { $x }";
		$x++;
	}
}

sub new {
	my($class, %attrs) = @_;
	my $self = [];
	bless $self, $class;	
	foreach my $att ( keys %attrs ){
		$self->$att( $attrs{$att} );	
	}
	$self->init();
	return $self;
}

sub init {
	no strict;
	my $self = shift;
	$self->start_url('https://onlineservices.wachovia.com/auth/AuthService?action=presentLogin') 
		unless $self->start_url;
	$self->[ &{"_cached_content"} ] = {};
}

sub AUTOLOAD {
	no strict 'refs';
	our $AUTOLOAD;
	my $self = shift;
	my $attr = lc $AUTOLOAD;
	$attr =~ s/.*:://;
	return $self->Error("$attr is not a valid attribute")
		unless grep /$attr/, @attrs;
	# get if no args passed
	return $self->[ &{"_$attr"} ] unless @_;	
	# set if args passed
	$self->[ &{"_$attr"} ] = shift;
	return $self; 
}

sub trash_cache {
	my $self = shift;
	$self->[ &{"_cached_content"} ] = {};	
}

sub get_account_numbers {
	my $self = shift;
	return Finance::Bank::Wachovia::DataObtainer::WWW::Parser
		->get_account_numbers( $self->get_summary_content() );
}

sub get_credit_account_current_balance {
	get_account_available_balance( @_ );
}

sub get_credit_account_available_credit {
	my $self = shift;
	return $self->Error( "must pass credit account number" ) unless @_;
	return Finance::Bank::Wachovia::DataObtainer::WWW::Parser
		->get_credit_account_available_credit( $self->get_detail_content( @_ ) ); 
}

sub get_credit_account_limit {
	my $self = shift;
	return $self->Error( "must pass credit account number" ) unless @_;
	return Finance::Bank::Wachovia::DataObtainer::WWW::Parser
		->get_credit_account_limit( $self->get_detail_content( @_ ) ); 

}

sub get_account_available_balance {
	my $self = shift;
	return $self->Error( "must pass account number" ) unless @_;
	return Finance::Bank::Wachovia::DataObtainer::WWW::Parser
		->get_account_available_balance( $self->get_summary_content(), @_ );
}

sub get_account_name {
	my $self = shift;
	return $self->Error( "must pass account number" ) unless @_;
	return Finance::Bank::Wachovia::DataObtainer::WWW::Parser
		->get_account_name( $self->get_summary_content(), @_ );
}

sub get_account_type {
	my($self) = shift;	
	return $self->Error( "must pass account number" ) unless @_;
	return Finance::Bank::Wachovia::DataObtainer::WWW::Parser
		->get_account_type( $self->get_detail_content(@_) );
}

sub get_account_posted_balance {
	my $self = shift;
	return $self->Error( "must pass account number" ) unless @_;
	return Finance::Bank::Wachovia::DataObtainer::WWW::Parser
		->get_account_posted_balance( $self->get_detail_content(@_) );
}

sub get_account_transactions {
	my $self = shift;
	return $self->Error( "must pass account number" ) unless @_;
	return Finance::Bank::Wachovia::DataObtainer::WWW::Parser
		->get_account_transactions( $self->get_detail_content(@_) );
}

sub get_summary_content {
	no warnings;
	local $^W = 0;
	print STDERR "Getting Summary Content:\n" if $DEBUG;
	my $self = shift;
	if( $self->cached_content->{'summary'} ){
		print STDERR "Returning cached summary:\n",
			"============== BEGIN SUMMARY =============\n",
			$self->cached_content->{'summary'}, "\n",
			"=============== END SUMMARY ==============\n" if $DEBUG;
		return $self->cached_content->{'summary'};
	}
	if( ! $self->logged_in ){
		$self->login
			or return $self->Error( $self->ErrStr );	
		return $self->get_summary_content()
			or return $self->Error( $self->ErrStr );
	}
	my $mech = $self->mech();
	$mech->form_number( 1 );
	$mech->field( inputName => 'RelationshipSummary' );
	$mech->submit();
	$self->cached_content->{'summary'} = $mech->content();
	print STDERR "Returning NOT cached summary:\n",
		"============== BEGIN SUMMARY =============\n",
		$self->cached_content->{'summary'}, "\n",
		"=============== END SUMMARY ==============\n" if $DEBUG;
	return $self->cached_content->{'summary'};
}

sub get_detail_content {
	no warnings;
	local $^W = 0;
	my($self, $account_number) = @_;
	return $self->Error( "get_detail_content in WWW must have account_number, got: '$account_number'" )
		unless $account_number;
	if( $self->cached_content->{'details'}{$account_number} ){
		print STDERR "Returning cached details:\n",
			"============ BEGIN DETAILS ===============\n",
			$self->cached_content->{'details'}{$account_number}, "\n",
			"============ END DETAILS =================\n" if $DEBUG;
		return $self->cached_content->{'details'}->{$account_number};
	}
	unless( $self->cached_content->{'summary'} ){
		$self->get_summary_content();	
	}
	my $stmt_type = $account_number =~ /^\d{16}$/ ? 'AccountSummary' : 'AccountDetail';
	my $mech = $self->mech();
	$mech->form_number( 1 );
	$mech->field( RelSumAcctSel		=> $account_number );
	$mech->field( inputName			=> $stmt_type );
	$mech->field( RelSumStmtType	=> $stmt_type );
	$mech->submit();	
	$self->cached_content->{'details'}->{$account_number} = $mech->content();
	# return to summary page
	$mech->form_number( 1 );
	$mech->field( inputName => 'RelationshipSummary' );
	$mech->submit();
	print STDERR "Returning NOT cached details:\n",
		"============ BEGIN DETAILS ===============\n",
		$self->cached_content->{'details'}{$account_number}, "\n",
		"============ END DETAILS =================\n" if $DEBUG;
	return $self->cached_content->{'details'}->{$account_number};
}

# initilizes WWW::Mech object, uses it to get to summary page
# summary page is cached/overwritten
sub login {
	no warnings;
	local $^W = 0;
	my $self = shift;
	my %p = @_;
	
	my $start = $p{'start_url'} || $self->start_url();
	print STDERR "Starting Login (1)\n" if $DEBUG;

	# now we can get to business
	my $mech = WWW::Mechanize->new(
		autocheck => 1,
		max_redirect => 1,
	);
	
	# caches the mech object
	$self->mech( $mech );

	$mech->cookie_jar(HTTP::Cookies->new());	# have to turn on cookies manually apparently
	$mech->agent_alias( 'Mac Safari' );			# don't want the bank to know we are geniuses, (using perl) 
												# but we don't want them thinking we are dumb either (using MSIE).
												# considering changing this to Firefox (mozilla), as an exercise in pointlessness.

	# make first contact
	# TODO: add in success checking
	$mech->get( $start );
	print STDERR "Login (2) Content:\n",
		"============ BEGIN CONTENT ===============\n",
		$mech->content(), "\n",
		"============ END CONTENT =================\n" if $DEBUG;

	# the website uses javascript to set this cookie, so we have to do it manually.
	# without this, an error is returned from the website about either javascript or cookies being turned off
	$mech->cookie_jar->set_cookie( undef, 'CookiesAreEnabled', 'yes', '/', '.wachovia.com', undef, undef, 1 ); 
	#$mech->max_redirect(1);
	#$mech->requests_redirectable([]);
	if( ! $self->user_id ){
		print STDERR "Logging in via CAN method...\n" if $DEBUG || $CONFIRM_LOGIN;
		print STDERR
			"CAN => '", $self->customer_access_number, "'\n",
			"PIN => '", $self->pin, "'\n",
			"CODEWORD => '", $self->code_word, "'\n"
				if $CONFIRM_LOGIN;
		$mech->form_name( 'canAuthForm' );
		$mech->field( action				=> 'canPinLogin' );
		$mech->field( CAN				=> $self->customer_access_number );
		$mech->field( PIN				=> $self->pin );
		$mech->field( CODEWORD			=> $self->code_word );
		$mech->field( systemtarget		=> 'gotoBanking' );
		$mech->field( requestTimestamp	=> time() ); # the website uses javascript to set this value
	}
	else{
		print STDERR "Logging in via USERID method...\n" if $DEBUG || $CONFIRM_LOGIN;
		print STDERR
			"userid => '", $self->user_id, "'\n",
			"password => '", $self->password, "'\n",
				if $CONFIRM_LOGIN;
		$mech->form_name( 'uidAuthForm' );
		$mech->field( action			=> 'uidLogin' );	
		$mech->field( userid			=> $self->user_id );
		$mech->field( password			=> $self->password );
		$mech->field( systemtarget		=> 'gotoBanking' );
		$mech->field( requestTimestamp	=> time() ); # the website uses javascript to set this value
	}
	$mech->submit();
	print STDERR "Login (3) Content:\n",
		"============ BEGIN CONTENT ===============\n",
		$mech->content(), "\n",
		"============ END CONTENT =================\n" if $DEBUG;
		if( $mech->content() =~ /ASV\-201/ ){
			return $self->Error("Login failed, bad username/password (too many of these will lock your account)");
		}

	# after the initial commit, there is what appears to be a bunch of redirects. While there are some, there are
	# also some javascript onLoad submits.  The following code emulates that behavior (just submits a form that 
	# has a bunch of hidden inputs )
	$mech->form_number( 1 );
	$mech->submit();
	print STDERR "Login (4) Content:\n",
		"============ BEGIN CONTENT ===============\n",
		$mech->content(), "\n",
		"============ END CONTENT =================\n" if $DEBUG;

	# removed due to wachovia website change on 1/22
	#	$mech->form_number( 1 );
	#	$mech->submit();
	#	print STDERR "Login (5) Content:\n",
	#		"============ BEGIN CONTENT ===============\n",
	#		$mech->content(), "\n",
	#		"============ END CONTENT =================\n" if $DEBUG;

	
	$self->cached_content->{'summary'} = $mech->content();
	$self->logged_in( 1 );
	return $self;
}

sub DESTROY {}
