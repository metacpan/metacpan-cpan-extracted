package Finance::Bank::DE::DeutscheBank;
use strict;
use warnings;
use Carp;
use base 'Class::Accessor';

use WWW::Mechanize;
use HTML::LinkExtractor;
use HTML::TreeBuilder;
use Text::CSV_XS;


use vars qw[ $VERSION ];

$VERSION = '0.06';

BEGIN	{
		Finance::Bank::DE::DeutscheBank->mk_accessors(qw( agent ));
	};

use constant BASEURL	=> 'https://meine.deutsche-bank.de';
use constant LOGIN	=> BASEURL . '/trxm/db/';
use constant FUNCTIONS	=> "(Übersicht)|(Ihr Konto)|(Ihr Depot)|(Service / Optionen)|(Umsatzanzeige)|(Inlands-Überweisung)|(Daueraufträge)|(Lastschrift)|(Kunden-Logout)|(Überweisungsvorlagen)|(Ihre Finanzübersicht als PDF-Datei speichern)|(Ihre Finanzübersicht als CSV-Datei speichern)|(Customer-Logout)|(Overview)|(Your account)|(Your sec. account)|(Service / Options)|(Transactions)|(Domestic transfer order)|(Standing orders)|(Direct debit)|(Transfer order templates)|(Customer-Logout)|(Save as PDF File)|(Save as CSV File)|(Save your financial overview as PDF file)|(Save your financial overview as CSV file)";


sub new
{
	my ($class,%args) = @_;

	croak "Filiale/Branch number must be specified"
		unless $args{Branch};

	croak "Konto/Account number must be specified"
		unless $args{Account};

	croak "Unterkonto/SubAccount number must be specified"
		unless $args{SubAccount};

	croak "PIN/Password must be specified"
		unless $args{PIN};

	my $logger = $args{status} || sub {};

	my $self = {
			agent		=> undef,
			account		=> $args{Account},
			password	=> $args{PIN},
			branch		=> $args{Branch},
			subaccount	=> $args{SubAccount},
			logger		=> $logger,
			navigation	=> undef,
		};
	bless $self, $class;

	$self->log("New $class created");
	$self;
};


sub log
{
	$_[0]->{logger}->(@_);
};


sub log_httpresult
{
	$_[0]->log("HTTP Code",$_[0]->agent->status,$_[0]->agent->res->as_string)
};


sub new_session
{
	# Reset our user agent
	my ($self) = @_;
	my $url;

	$self->close_session()
		if ($self->agent);

	my $result = $self->get_login_page(LOGIN);

	if ( $result != 200 )
	{
		$self->log("Status"," Banking is unavailable");
		die "Banking is unavailable";
	}

	if ( $result == 200 )
	{
		if ($self->maintenance)
		{
			$self->log("Status","Banking is unavailable due to maintenance");
			die "Banking unavailable due to maintenance";
		};

		my $agent = $self->agent();
		my $function = 'ACCOUNTBALANCE';
		$self->log("Logging into function $function");

		# gvo=DisplayFinancialOverview&loginTab=iTAN&javascriptEnabled=true&branch=XXX&account=XXXXXX&subaccount=XX&pin=XXXXX&quickLink=DisplayFinancialOverview
		$agent->current_form->value('gvo','DisplayFinancialOverview');
		$agent->current_form->value('loginTab','iTAN');
		$agent->current_form->value('javascriptEnabled','false');
		$agent->current_form->value('quickLink','DisplayFinancialOverview');
		$agent->current_form->value('account',$self->{account});
		$agent->current_form->value('branch',$self->{branch});
		$agent->current_form->value('subaccount',$self->{subaccount});
		$agent->current_form->value('pin',$self->{password});
		$agent->add_header('Accept-Charset' => 'utf-8');
		$agent->add_header('Accept-Encoding' => '');

		local $^W=0;
		$result = $agent->submit();

		if ( $self->access_denied )
		{
			$self->log("Not possible to authenticate at bank server ( wrong account/pin combination ? )");
			return 0;
		}

		# extract links to account functions
		my $LinkExtractor = new HTML::LinkExtractor();

		$LinkExtractor->strip( 1 );
		$LinkExtractor->parse(\$agent->content());

		# needed here because of empty links ( href attribute )
		local $^W=1;

		# now we have the links in the format
		#	{
		#		'_TEXT' => 'Overview',
		#		'target' => '_top',
		#		'href' => '/mod/WebObjects/dbpbc.woa/618/wo/HpRl1hqezkxfYRosJRjTg0/4.11.1.5.3.3.5.3',
		#		'tag' => 'a',
		#		'class' => 'NaviDirektLink'
		#	},
		#	{	...
		#	}
		#


		# but I would like to have them as
		# 	{
		# 		'_TEXT' => 'Overview',
		# 		'href' => '/mod/WebObjects/dbpbc.woa/618/wo/HpRl1hqezkxfYRosJRjTg0/4.11.1.5.3.3.5.3',
		# 	},
		# 	{	...
		#	}
		# and only for functions ( not all links and images ... )

		my @tmp = ();
		foreach my $elem ( @{$LinkExtractor->links} )
		{
			if (( defined( $elem->{ '_TEXT' } ) && ( $elem->{ '_TEXT' } ne '' ) && ( $elem->{ '_TEXT' } =~ "m/". FUNCTIONS ."/" )) )
			{
				foreach $_ ( keys %$elem )
				{
					if ( $_ !~ m/(_TEXT)|(href)/ )
					{
						delete $elem->{ $_ };
					}
				}

				push @tmp, \%$elem;
			}
		}

		# save these links so that we can remember them
		$self->{navigation} = \@tmp;
		$self->log_httpresult();
		$result = $agent->status;
	};
	$result;
};


sub get_login_page
{
	my ($self,$url) = @_;
	$self->log("Connecting to $url");
	$self->agent(WWW::Mechanize->new(agent => "Mozilla/4.78 (Linux 2.4.19-4GB i686; U) Opera 6.03 [en]",  cookie_jar => {} ));

	my $agent = $self->agent();
	$agent->add_header('Accept-Language' => 'en-us,en;q=0.5');
	$agent->get(LOGIN);
	$self->log_httpresult();
	$agent->status;
};


sub error_page
{
	# Check if an error page is shown (a page with much red on it)
	my ($self) = @_;
	my $content = $self->agent->content;
	$content =~ s!<div class="errorMsg"><label for="">Bitte beachten Sie, da\&szlig; die "Hochstell-Taste" \(Capslock\) aktiv ist.</label></div>!!;
	$content =~ s!<div class="errorMsg"><label for="">Please note capslock-key is active.</label></div>!!;
	$content =~ /<tr valign="top" bgcolor="#FF0033">/sm || $content =~ /<div class="errorMsg">/ || $content =~ /<div class="backendErrorMsg">/ ;
};


sub maintenance
{
	my ($self) = @_;

	# would be nice if someone could mail me the actual english and german messages which are displayed in case of maintenance ...
	$self->error_page or
	$self->agent->content =~ /derzeit steht das Internet Banking aufgrund von Wartungsarbeiten leider nicht zur Verf&uuml;gung.\s*<br>\s*In K&uuml;rze wird das Internet Banking wieder wie gewohnt erreichbar sein./gsm;
};


sub access_denied
{
	my ($self) = @_;
	my $content = $self->agent->content;

	$self->error_page or
	(  $content =~ /Die eingegebene Kontonummer ist unvollst&auml;ndig oder falsch\..*\(2051\)/gsm
		or $content =~ /Die eingegebene PIN ist falsch\. Bitte geben Sie die richtige PIN ein\.\s*\(10011\)/gsm
		or $content =~ /Die von Ihnen eingegebene Kontonummer ist ung&uuml;ltig und entspricht keiner Deutsche Bank-Kontonummer.\s*\(3040\)/gsm
		or $content =~ /Leider konnte Ihre Anmeldung nicht erfolgreich durchgef&uuml;hrt werden/
		or $content =~ /Unfortunately, you were not able to register successfully./
		or $content =~ /Bitte überpr&uuml;fen Sie Ihre Anmeldedaten oder versuchen Sie es zu einem sp&auml;teren Zeitpunkt noch einmal./
		or $content =~ /Please check your registration data or try again later./
		or $content =~ /Bitte geben Sie ein g&uuml;ltiges Datum ein/
	);
};


sub session_timed_out
{
	my ($self) = @_;
	$self->agent->content =~ /Die Sitzungsdaten sind ung&uuml;ltig, bitte f&uuml;hren Sie einen erneuten Login durch.\s+\(27000\)/;
};


sub functions
{
	my ($self,$function) = @_;
	my $link = ();

    	if ( $function =~ "m/". FUNCTIONS ."/" )
	{
		foreach $_ ( @{$self->{ navigation }} )
		{
			if ( $_->{ '_TEXT' } eq $function )
			{
				$link = $_->{ 'href' };
			}
		}
		return $link;
	}
	else
	{
		return 0;
	}
}


sub select_function
{
	my ($self,$function) = @_;
	carp "Unknown account function '$function'"
		unless $self->functions($function);

	$self->new_session unless $self->agent;
	$self->agent->get( $self->functions( "$function" ) );

	if ( $self->session_timed_out )
	{
		$self->log("Session timed out");
		$self->agent(undef);
		$self->new_session();
		$self->agent->get( $self->functions( $function ) );
	};
	$self->log_httpresult();
	$self->agent->status;
};


sub close_session
{
	my ($self) = @_;
	my $result;
	if (not $self->access_denied)
	{
		$self->log("Closing session");
		local $^W=0;
		$self->select_function('Customer-Logout');
		local $^W=1;
		$result = $self->agent->res->as_string =~ /https:\/\/meine.deutsche-bank.de\/trxm\/db\/.*;link=trxm_en_logout-pbcde-to-txm_login.*/;
	}
	else
	{
		$result = 'Never logged in';
	};
	$self->agent(undef);
	$result;
};


sub login
{
	my ($self) = @_;

	if ( $self->new_session() )
	{
		return 1;
	}
	else
	{
		return 0;
	}

};


sub parse_account_overview
{
	my ($self) = @_;
	my $agent = $self->agent();
	my %saldo = ();

	my $tree = HTML::TreeBuilder->new();
	$tree->parse( $agent->content() );

	foreach my $table ( $tree->look_down('_tag', 'table') )
	{
		foreach my $row ( $table->look_down('_tag', 'tr') )
		{
			foreach my $child ( $row->look_down('_tag', 'td') )
			{
				if (( defined $child->attr('class')) && ( $child->attr('class') eq 'balance'))
				{
					my $tmp = $child->as_trimmed_text;

					if ( $child->attr('class') eq 'balance')
					{
						if ( $tmp =~ m/\.[0-9][0-9]$/ )
						{
							$tmp =~ s/\./#/;
							$tmp =~ s/,/./g;
							$tmp =~ s/#/,/;
						}
						$saldo{ 'Saldo' }  = $tmp;
					}
				}

				foreach my $morechildren ( $child->look_down('_tag', 'acronym') )
				{
					if (( defined $morechildren->attr('title')) && ( $morechildren->attr('title') eq 'Euro'))
					{
						$saldo{ 'Währung' } = $morechildren->as_trimmed_text;
					}
				}
			}
		}
	}
	return %saldo
}


sub saldo
{
	my ($self) = @_;
	my $agent = $self->agent;
	if ($agent)
	{
		local $^W=0;
		$self->select_function('Overview');
		local $^W=1;
		return $self->parse_account_overview();
	}
	else
	{
		return undef;
	}
};


sub MapData
{
	my ( @data ) = @_;
	for my $row ( @data )
	{
		foreach $_ ( keys %$row  )
		{
			if (( $_ eq 'Haben' )||( $_ eq 'Soll' ))
			{
				$row->{ $_ }  =~ s/\./#/;
				$row->{ $_ }  =~ s/,/./g;
				$row->{ $_ } =~ s/#/,/;
			}
			elsif (( $_ eq 'Buchungstag' )||( $_ eq 'Wert' ))
			{
				my @tmp = split( /\//, $row->{ $_ } );
				$row->{ $_ }  = join( '.', $tmp[1], $tmp[0], $tmp[2] );
			}
			elsif ( $_ eq 'Waehrung' )
			{
				my $tmp = $row->{ 'Waehrung' };
				delete $row->{ 'Waehrung' };
				$row->{ 'Währung' } = $tmp;
			}
		}
	}
	return @data;
}


sub account_statement
{
	my ($self, %parameter) = @_;

	my $count = 0;
	my @header = ();
	my @AccountStatement = ();
	my $AccountRow = ();
	my @date;
	my $agent = $self->agent;
	if ($agent)
	{
		local $^W=0;
		$self->select_function('Overview');

		my %account = $self->parse_account_overview();
		$agent->follow_link( 'text' => 'Transactions' );
		local $^W=1;

		# should I get account statement for user defined period ?
		if ( defined $parameter{ 'period' } )
		{
			my ( $day, $month, $year ) = split( '\.', $parameter{ 'StartDate' } );

			$day	= sprintf("%02d", $day );
			$month	= sprintf("%02d", $month );
			$year	= sprintf("%04d", $year );

			croak "Year must have 4 digits in StartDate"
				unless ( length $year == 4 );

			$agent->current_form->value( 'period','dynamicRange');
			$agent->current_form->value( 'periodStartDay', $day );
			$agent->current_form->value( 'periodStartMonth', $month );
			$agent->current_form->value( 'periodStartYear', $year );

			( $day, $month, $year ) = split( '\.', $parameter{ 'EndDate' } );
			$day	= sprintf("%02d", $day );
			$month	= sprintf("%02d", $month );
			$year	= sprintf("%04d", $year );

			croak "Year must have 4 digits in EndDate"
				unless (( length $year == 4 )&&( $year > 1900 ));

			$agent->current_form->value( 'period','dynamicRange');
			$agent->current_form->value( 'periodEndDay', $day );
			$agent->current_form->value( 'periodEndMonth', $month );
			$agent->current_form->value( 'periodEndYear', $year );
		}
		elsif ( defined $parameter{ 'last' } )
		{
			my $last = ();
			$agent->current_form->value('period','fixedRange');
			if ( $parameter{ 'last' } <= 10 )
			{
				$last = 10;
			}
			elsif ( $parameter{ 'last' } <= 20 )
			{
				$last = 20;
			}
			elsif ( $parameter{ 'last' } <= 30 )
			{
				$last = 30;
			}
			elsif ( $parameter{ 'last' } <= 60 )
			{
				$last = 60;
			}
			elsif ( $parameter{ 'last' } <= 90 )
			{
				$last = 90;
			}
			elsif ( $parameter{ 'last' } <= 120 )
			{
				$last = 120;
			}
			else	# > 120
			{
				$last = 180;
			}
			$agent->select('periodDays', $last);
		}
		else	#expect that per default last login date is set ...
		{
			;
		}

		local $^W=0;
		# 'refresh view' is used to trigger update of account balance
		my $result = $agent->submit();

		# download CSV formated data of account balances
		$result = $agent->follow_link( text_regex => qr/Save your account turnover as.*CSV.*file/ );
		local $^W=1;

		#successfully downloaded account balance data in csv format
		if ( $result->is_success )
		{
			my @balance = split( '\n', $result->content );
			my $csv = Text::CSV_XS->new( { 'sep_char'    => ';' });

			my $StartLineDetected = 0;
			for ( my $loop = 0; $loop < scalar @balance; $loop++ )
			{
				my $line = $balance[ $loop ];
				chomp( $line );

				$line =~ s/^Booking date;/Buchungstag;/;
				$line =~ s/;Value date;/;Wert;/;
				$line =~ s/;Transactions Payment details;/;Verwendungszweck;/;
				$line =~ s/;Debit;/;Soll;/;
				$line =~ s/;Credit;/;Haben;/;
				$line =~ s/;Currency/;Waehrung/;
				$line =~ s/^Account balance;/Kontostand;/;

				if ( $StartLineDetected == 1 )
				{
					my $status = $csv->parse( $line );
					@header = $csv->fields();
					$AccountRow = 0;
					@AccountStatement = ();
					$StartLineDetected = 2;
				}
				elsif ( $StartLineDetected == 2 )
				{
					if ( $line !~ /^Kontostand;/ )
					{
						my $status = $csv->parse( $line );
						my @columns = $csv->fields();

						for (my $loop = 0; $loop < scalar @columns; $loop++ )
						{
							$AccountStatement[ $AccountRow ]{ $header[ $loop ] } = $columns[ $loop ];
						}
						$AccountRow++;
					}
				}
				elsif (	( $line =~ /Vorgemerkte und noch nicht gebuchte Umsätze sind nicht Bestandteil dieser Aufstellung/ )||
					( $line =~ /Transactions pending are not included in this report/ ) )
				{
					$StartLineDetected = 1;
				}
			}
			return MapData( @AccountStatement );
		}
		else
		{
			return undef;
		}
	}
	else
	{
		return undef;
	}
}


1;
__END__

=head1 NAME

Finance::Bank::DE::DeutscheBank - Checks your Deutsche Bank account from Perl

=head1 SYNOPSIS

=for example begin

  use strict;
  use Finance::Bank::DE::DeutscheBank;
  my $account = Finance::Bank::DE::DeutscheBank->new(
		Branch		=> '600',
		Account		=> '1234567',
		SubAccount	=> '00',
		PIN		=> '543210',

                status => sub { shift;
                                print join(" ", @_),"\n"
                                  if ($_[0] eq "HTTP Code")
                                      and ($_[1] != 200)
                                  or ($_[0] ne "HTTP Code");

                              },
              );
  # login to account
  if ( $account->login() )
  {
	print( "successfully logged into account\n" );
  }
  else
  {
	print( "error, can not log into account\n" );
  }

  my %saldo = $account->saldo();
  print("The amount of money you have is: $saldo{ 'Saldo' } $saldo{ 'Währung' }\n");

  # get account statement
  my %parameter = (
                        period => 1,
                        StartDate => "01.01.2005",
                        EndDate => "02.02.2005",
                  );

  my @account_statement = $account->account_statement(%parameter);

  $account->close_session;

=for example end

=head1 DESCRIPTION

This module provides a rudimentary interface to the Deutsche Bank online banking system at
https://meine.deutsche-bank.de/. You will need either Crypt::SSLeay or IO::Socket::SSL
installed for HTTPS support to work with LWP.

The interface was cooked up by me by having a look at some other Finance::Bank
modules. If you have any proposals for a change, they are welcome !

=head1 WARNING

This is code for online banking, and that means your money, and that means BE CAREFUL. You are encouraged, nay, expected, to audit the source of this module yourself to reassure yourself that I am not doing anything untoward with your banking data. This software is useful to me, but is provided under NO GUARANTEE, explicit or implied.

=head1 WARNUNG

Dieser Code beschaeftigt sich mit Online Banking, das heisst, hier geht es um Dein Geld und das bedeutet SEI VORSICHTIG ! Ich gehe
davon aus, dass Du den Quellcode persoenlich anschaust, um Dich zu vergewissern, dass ich nichts unrechtes mit Deinen Bankdaten
anfange. Diese Software finde ich persoenlich nuetzlich, aber ich stelle sie OHNE JEDE GARANTIE zur Verfuegung, weder eine
ausdrueckliche noch eine implizierte Garantie.

=head1 METHODS

=head2 new( %parameter )

Creates a new object. It takes four named parameters :

=over 5

=item Branch => '600'

The Branch/Geschaeftstelle which is responsible for you.

=item Account => '1234567'

This is your account number.

=item SubAccount => '00'

This is your subaccount number.

=item PIN => '11111'

This is your PIN.

=item status => sub {}

This is an optional
parameter where you can specify a callback that will receive the messages the object
Finance::Bank::DE::DeutscheBank produces per session.

=back

=head2 login()

Closes the current session and logs in to the website using
the credentials given at construction time.

=head2 close_session()

Closes the session and invalidates it on the server.

=head2 agent()

Returns the C<WWW::Mechanize> object. You can retrieve the
content of the current page from there.

=head2 select_function( STRING )

Selects a function. The two currently supported functions are C<Übersicht> and C<Kunden-Logout>.
Which means account statement and quit.

=head2 account_statement( %parameter )

Navigates to the html page which contains the account statement. The content is retrieved
by the agent, parsed by parse_account_overview and returned as an array of hashes.
Like:
@VAR =( {
          'Buchungstag' => '18.02.2005',
          'Wert' => '18.02.2005',
          'Verwendungszweck' => 'this is for you',
          'Haben' => '40,00',
          'Soll' => '',
          'Währung' => 'EUR'
        },
        {
          'Buchungstag' => '19.02.2005',
          'Wert' => '19.02.2003',
          'Verwendungszweck' => 'this was mine',
          'Haben'  => '',
          'Soll' => '-123.98',
          'Währung' => 'EUR'
        }) ;

Keys are in german because they are retrieved directly from the header of the
csv file which is downloaded from the server.

You can pass a hash to this method to tell the period you would like to
get the statement for. If you don't pass a parameter then you'll receive
the account statement since your last visit at the Banks server.
Parameter to pass to the function:

my %parameter = (
                        period => 1,
                        StartDate => "10.02.2005",
                        EndDate => "28.02.2005",
                );

If period is set to 1 then StartDate and EndDate will be used.

The second possibilty is to get an account overview for the last n days.

my %parameter = (
                        last => 10,
                );

This will retrieve an overview for the last ten days.
The bank server allows 10,20,30,60,90 days. If you specify any other
value then the method account_statement will use one of the above values
( the next biggest one ).

If neither period nor last is defined last login date at the bank
server is used. StartDate and EndDate have to
be in german format.


=head1 TODO:

  * Allthough more checks have been implemented to validate the HTML resp. responses from the server
it might be that some are still missing. Please let me know your feedback.

=head1 SEE ALSO

L<perl>, L<WWW::Mechanize>.

=head1 AUTHOR

Wolfgang Schlueschen, E<lt>wschl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 - 2010 by Wolfgang Schlueschen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
