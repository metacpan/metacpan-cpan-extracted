=pod

=head1 NAME

Finance::Bank::CooperativeUKPersonal - Access to UK Cooperative personal 
bank accounts

=head1 SYNOPSIS

  use Finance::Bank::CooperativeUKPersonal

  my $conf = {
	sortCode => $sortCode,            # numeric, without dashes,
	accountNumber => $accountNumber, 
	securityCode => $securityCode,
	memorableDate => $memorableDate,  # dd/mm/yyyy
	memorableName => $memorableName,
	firstSchool => $firstSchool,
	lastSchool => $lastSchool,
	birthPlace => $birthplace
  };
  
  # Connect to bank & login
  my $bank = Finance::Bank::CooperativeUKPersonal->new($conf);
  $bank->connect();
  
  # get account summary (all accounts table)
  my $accounts = $bank->accountSummary();
  
  # get available statements for an account
  # includes dated statements & recent items statement
  my $statements = $bank->availableStatements( $accounts->[0] );

  # fetch a statement - dated or recent items
  my $transactions = $bank->statement( $statements->[0] );

=head1 DESCRIPTION

This module provides an interface to the Co-operative UK personal online banking website, 
with access to recent transactions and statements.

=head1 METHODS

=head2 new, connect - combine to start your session

  my $conf = {
	sortCode => $sortCode,            # numeric, without dashes,
	accountNumber => $accountNumber, 
	securityCode => $securityCode,
	memorableDate => $memorableDate,  # dd/mm/yyyy
	memorableName => $memorableName,
	firstSchool => $firstSchool,
	lastSchool => $lastSchool,
	birthPlace => $birthplace
  };
  
  # Connect to bank & login
  my $bank = Finance::Bank::CooperativeUKPersonal->new($conf);
  $bank->connect();

C<new()> configures your connection, C<connect()> connects to the co-op website. The co-op
expires sessions after 10 minutes of inactivity, so C<connect()> can be used at any point to
reconnect.

=head2 accountSummary - summary listing of bank accounts

Parses the initial account summary table shown after logging into the Co-Op bank website. Returns
a reference to an array of account hashrefs. e.g.

  $accounts = $bank->accountSummary();

returns

  $accounts = [
    {
        'accountNumber' => $accountNumber,
        'sortCode' => $sortCode,
        'href' => $href,
        'name' => $name,
        'availableBalance' => $balance
    }
  ];

If your balance is in credit, the co-op appends 'CR' to the available balance. I do not know 
how they indicate overdrawn accounts.

=head2 availableStatements - list of availalable statements for an account

Returns a list of available statements for an account as a reference to an array of hashrefs.

  $statements = $bank->availableStatements($accounts->[0]);

returns
  
  $statements = [
    {
        'name' => $name, 
        'href' => $href
    }
  ];

In the returned hashref, 'name' is either 'Recent Items' or the statement's issued date in 
dd/mm/yyyy format.

=head2 statement - list of transaction rows in a statement

Returns a list of transactions in a statement as a reference to an array of hashrefs.

  $transactions = $bank->statement($statements->[1]);

returns

  $transactions = [
   	{
        'reference' => $referenceString,
        'date' => $date,  # 'dd/mm/yyyy',
        'withdrawal' => $withdrawal
        'deposit' => $deposit,
        'balance' => $balance  # not present in recent items statement
     },
  ];

If your balance is in credit, the co-op appends 'CR' to the available balance. I do not know 
how they indicate overdrawn accounts.

=head1 CAVEATS

As this module accesses your bank account, you should ensure you store your configuration data
and any received transaction information in a secure place.

=head1 AUTHOR

Stephen Patterson <steve@patter.me.uk>

=cut

package Finance::Bank::CooperativeUKPersonal;

use strict;
use warnings;
use Carp qw/croak/;
use WWW::Mechanize;
use HTML::DOM;
use File::Temp;
use Data::Dumper;

# Configure connection
sub new {
	my $class = shift();
	my $self = {};
	my $params = shift();
	
	croak "sortCode required" unless ($params->{sortCode});
	croak "invalid sortCode, must be numeric" unless ($params->{sortCode} =~ /^\d+$/);
	croak "accountNumber required" unless ($params->{accountNumber});
	croak "invalid accountNumber, must be numeric" unless ($params->{accountNumber} =~ /^\d+$/);
	croak "memorableDate required" unless ($params->{memorableDate});
	croak "invalid memorableDate, must be dd/mm/yyyy" unless ($params->{memorableDate} =~ m|^\d{2}\/\d{2}\/\d{4}$|);
	croak "memorableName required" unless ($params->{memorableName});
	croak "firstSchool required" unless ($params->{firstSchool});
	croak "lastSchool required" unless ($params->{lastSchool});
	croak "birthPlace required" unless ($params->{birthPlace});
	
	foreach my $key (keys(%{$params})) {
		$self->{$key} = $params->{$key};
	}	

	$self->{siteAddress} = 'https://personal.co-operativebank.co.uk';
	$self->{linkBase}  = $self->{siteAddress} . '/CBIBSWeb/';
	$self->{startPage} = $self->{linkBase} . 'start.do';

	$self->{mech} = new WWW::Mechanize();
	return bless $self, $class;
}

# Connect to the Co-op through their multi-factor auth screens
sub connect {
	my $self = shift();

	## Step 1, Fetch startpage, fill in sort code & account number
	$self->{mech}->get($self->{startPage});
	my $res = $self->{mech}->submit_form(
		form_name => 'loginForm',
		fields => {
			sortCode => $self->{sortCode},
			accountNumber => $self->{accountNumber}
		});
	croak "Couldn't submit login form" unless $res->is_success;
	
	## Step 2, fill in security code, see what info we need next
	if ($self->{mech}->content() =~ m/Enter the (\w+) and (\w+) digits/i) {
		my $offsets = {
			first => 0,
			second => 1,
			third => 2,
			fourth => 3
		};
		
		my $digit1 = substr($self->{securityCode}, $offsets->{$1}, 1);
		my $digit2 = substr($self->{securityCode}, $offsets->{$2}, 1);
		
		## Enter security code digits on form, next page asks for various secure information
		## return name of the page 
		my $res = $self->{mech}->submit_form(
			form_name => 'passCodeForm',
			fields => {
				firstPassCodeDigit => $digit1,
				secondPassCodeDigit => $digit2
		});
		croak "Couldn't submit security code" unless $res->is_success;

		if ($self->{mech}->content() =~ /Memorable date/) {
			# Were asked to enter memorable date
			my ($day, $month, $year) = split('/', $self->{memorableDate});
			my $res = $self->{mech}->submit_form(
				form_name => 'loginSpiForm',
				fields => {
					memorableDay => $day,
					memorableMonth => $month,
					memorableYear => $year
			});
			croak "Couldn't submit Memorable Date" unless $res->is_success;
		} elsif ($self->{mech}->content() =~ /firstschool/) {
			# Were asked to enter first school
			my $res = $self->{mech}->submit_form(
				form_name => 'loginSpiForm',
				fields => {
					firstSchool => $self->{firstSchool}
			});
			croak "Couldn't submit last school" unless $res->is_success;
		} elsif ($self->{mech}->content() =~ /lastschool/) {
			# asked for last school
			my $res = $self->{mech}->submit_form(
				form_name => 'loginSpiForm',
				fields => {
					lastSchool => $self->{lastSchool}
			});
			croak "Couldn't submit last school" unless $res->is_success;
		} elsif ($self->{mech}->content() =~ /birthPlace/) {
			# birthplace
			my $res = $self->{mech}->submit_form(
				form_name => 'loginSpiForm',
				fields => {
					birthPlace => $self->{birthPlace}
			});
			croak "Couldn't submit birthplace" unless $res->is_success;
		} elsif ($self->{mech}->content() =~ /memorableName/) {
			# memorable name
			my $res = $self->{mech}->submit_form(
				form_name => 'loginSpiForm',
				fields => {
					memorableName => $self->{memorableName}
			});
			croak "Couldn't submit memorable name" unless $res->is_success;
		} else {
			croak "The 2-factor authentication requested was not of a recognised type";
		}
		
		# Invalid security info, redo from start
		if ($self->{mech}->content() =~ /security information.*incorrect/) {
			croak "invalid security information entered";
		}
		
		# bypass interstitial
		if ($self->{mech}->content() =~ /linearButtonNavigationForm/) {
			$self->{mech}->submit_form(
				#formName => 'linearButtonNavigationForm'
			);
		}
	} else {
		croak "Did not receive security code entry page";
	}
	return 1;
}


############################################################################################
## Inner information pages

# Account summary table - the 1st page seen after logging in
sub accountSummary {
	my $self = shift();
	my @summary = ();

	# to parse via HTML::DOM, need to save content as a file
	my $fh = File::Temp->new();
	print $fh $self->{mech}->content();
	my $tmpNam = $fh->filename;
	$fh->close;
	
	my $dom = HTML::DOM->new();
	$dom->parse_file( $tmpNam );
		
	# Descend into content, find table containing summary data
	# 4th child (table) of <td class="sidebar" width="80%">
	my $summaryTable;
	foreach my $td ($dom->getElementsByTagName('td')) {
		if ($td->getAttribute('class') eq 'sidebar' && $td->getAttribute('width') eq '80%') {
			my $rightChildren = $td->getElementsByTagName ( 'table' );
			$summaryTable = $rightChildren->[3]->getElementsByTagName('table')->[0];


			foreach my $row ($summaryTable->getElementsByTagName('tr')) {
				my $account = {};				
				my $columns = $row->childNodes();

				for (my $i = 0; $i < $columns->length; ++$i) {
					my $text = $columns->[$i]->as_text;
					$text =~ s/\s+//g;
					$text =~ s/\x{a3}//;
					chomp($text);
					if ($i == 1) {
						$account->{name} = $text;
						foreach my $node ($columns->[$i]->childNodes()) {
							#print ref $node, "\n";
							if (ref $node eq 'HTML::DOM::Element::A' && 
								$node->getAttribute('href') =~ /^balances\.do/) {
								$account->{href} = $self->{linkBase} . $node->getAttribute('href');
									
							}
						}
					} elsif ($i == 3) {
						#unless($text =~ /CR$/) {
						#	$text = '-' . $text;
						#}
						$text =~ s/[A-Z]+$//;
						$account->{availableBalance} = $text;
					} elsif ($i == 7) {
						$text =~ s/-//g;
						$account->{sortCode} = $text;
					} elsif ($i == 9) {
						$account->{accountNumber} = $text;
					}
				}
				push @summary, $account;
			}
		}
	}
	
	shift(@summary);
	return \@summary;
}


## Get a list of available statements on an account
sub availableStatements {
	my ($self, $account) = @_;
	
	$self->{mech}->get($account->{href});
	my $links = $self->{mech}->find_link('url_regex' => qr/statementsSummary/);	
	
	# this is the page of an account's statements
	$self->{mech}->get($links->[0]);
	
	my @statements;
	# recent items
	#my $recent = {
	#	name => 'Recent Items',
	#	href => $account->{href}
	#};
	my $recentLink= $self->{mech}->find_link('url_regex' => qr/domesticRecentItems/);
	my $tmp = {
		name => $recentLink->text(),
		href => $self->{siteAddress} . $recentLink->url()
	};
	push @statements, $tmp;
	
	# Main statement links
	my @statementLinks = $self->{mech}->find_all_links('url_regex' => qr/getDomesticStatement/);
	foreach my $link (@statementLinks) {
		if ($link->text() =~ m|^\d{2}\/\d{2}\/\d{4}$|) {
			my $tmp = {
				name => $link->text(),
				href => $self->{siteAddress} . $link->url()
			};
			push @statements, $tmp;
		}
	}
	return \@statements;
}

sub statement {
	my $self = shift();
	my $statement = shift();
			
	#print "Fetching: ", $statement->{href}, "\n";
	$self->{mech}->get($statement->{href});
	if (! $self->{mech}->success()) {
		print "HTTP ", $self->{mech}->status(), "\n";
		print Dumper($self->{mech}->response()), "\n";
	}

	#print $self->{mech}->content();

	# to parse via HTML::DOM, need to save content as a file
	my $fh = File::Temp->new();
	print $fh $self->{mech}->content();
	my $tmpNam = $fh->filename;
	$fh->close;
	
	my $dom = HTML::DOM->new();
	$dom->parse_file( $tmpNam );
	
	# Descend into content, find table containing summary data
	# 4th or 5th child (table) of <td class="sidebar" width="80%">
    # remember, we're parsing HTML so may change if Co-op regen the pages
	my $outerTable;
	my $innerTable;
	if ($statement->{name} eq 'Recent Items') {
		$outerTable = 3;
		$innerTable = 0;
	} else {
        $outerTable = 3;
        $innerTable = 0;
		#$outerTable = 2;
		#$innerTable = 2;
	}
	
	my @transactions;
	foreach my $td ($dom->getElementsByTagName('td')) {
		if ($td->getAttribute('class') eq 'sidebar' && $td->getAttribute('width') eq '80%') {
			my $rightChildren = $td->getElementsByTagName ( 'table' );
			my $summaryTable = $rightChildren->[$outerTable]->getElementsByTagName('table')
				->[$innerTable];


			foreach my $row ($summaryTable->getElementsByTagName('tr')) {
				my $account = {};				
				my $columns = $row->childNodes();

				for (my $i = 0; $i < $columns->length; ++$i) {
					my $text = $columns->[$i]->as_text;
					$text =~ s/\s+//g;
					$text =~ s/\x{a3}//;
					chomp($text);
					if ($i == 1) {
						# transaction date
						$account->{date} = $text;
					} elsif ($i == 3) {
						# transaction reference
						$account->{reference} = $text;
					} elsif ($i == 5) {
						# deposit
						$account->{deposit} = $text;
					} elsif ($i == 7) {
						$account->{withdrawal} = $text;
					} elsif ($i == 9) {
						$account->{balance} = $text;
					}
				}
				# don't include the table header row in returned results
				if ($account->{reference} !~ /LastStatement/ 
					&& $account->{reference} !~/Transaction/) {
					push @transactions, $account;
				}
			}	
				
		}
	}
	
	return \@transactions;
}
1;
