###############################################################################
package Finance::Bank::DE::DTA::Create;
#
###############################################################################
# Dta class provides functions to create and handle with DTA files
# used in Germany to exchange informations about money transactions with
# banks or online banking programs.
###############################################################################

use strict;
use warnings;
use Carp;
use POSIX qw(strftime);
use Time::Local;
use vars qw($VERSION);
$VERSION = 1.03;

sub new {
	my $that = shift;
	$that = ref($that) || $that;
	my $self = {
		items          => 0,
		amount         => 0,
		sum_accounts   => 0,
		sum_bank_codes => 0,
	};

	bless $self, $that;
	return $self->_initialize(shift);
}

#****s*	_initialize
#
#	DESCRIPTION
#		Initialisierung des DTA Objekts, wir von new() aufgerufen.
#
#	PARAMETER
#		%file		optional: Accountfile des Kontoinhabers
#
#	RETURN
#		Objekt im Erfolgsfall, 0 wenn Fehlgeschlagen
#
#******************************************************************************
sub _initialize {
	my $self = shift;
	my $file = shift;    # Account file sender
	$self->{timestamp} = time();
	$self->{exchanges} = [];
	foreach my $i (
		32, 36, 37, 38, 42, 43, 44, 45, 46, 47, 48,  49,  50,  51, 52, 53, 54, 55,
		56, 57, 65, 66, 67, 68, 69, 70, 71, 72, 73,  74,  75,  76, 77, 78, 79, 80,
		81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 196, 214, 220, 223
	  )
	{
		$self->{_validChars}{"$i"} = 1;
	}
	if ( $file->{type} && $file->{type} eq "credit" ) {
		$self->{type} = "0";
	}
	elsif ( $file->{type} && $file->{type} eq "debit" ) {
		$self->{type} = "1";
	}
	else {
		$self->{type} = "2";
		carp "You did not choose the type of the DTA file.";
		return 0;
	}
	if ( $file && !$self->_setAccount($file) ) {
		carp "Setting up sender account failed.";
		return 0;    # Setup acoount file sender failed!!
	}
	return $self;
}

#****s*	_setAccount
#
#	DESCRIPTION
#		Speichern der Accountdaten des Kontoinhabers im Objekt
#
#	PARAMETER
#		%file		optional: Accountfile des Kontoinhabers
#
#	RETURN
#		Objekt im Erfolgsfall, 0 wenn Fehlgeschlagen
#
#******************************************************************************
sub _setAccount {
	my $self = shift;
	my $file = shift;

	if ( $file && length( $file->{name} ) > 0 ) {
		if ( !$self->_validNumeric( $file->{bank_code} ) ) {
			carp "Please provide a valid sender BLZ.";
			return 0;    # Fehlerhafte Bankleitzahl
		}
		if ( !$self->_validNumeric( $file->{account_number} ) ) {
			carp "Please provide a valid sender account-number.";
			return 0;    # Fehlerhafte Kontonummer
		}
		if ( !$file->{additional_name} || length( $file->{additional_name} ) == 0 ) {
			$file->{additional_name} = '';    # additional_name setzen, wenn nicht angegeben
		}
		$self->{account} = {
			"name"            => substr( $self->_makeValidString( $file->{name} ),            0, 27 ),
			"bank_code"       => $file->{bank_code},
			"account_number"  => $file->{account_number},
			"additional_name" => substr( $self->_makeValidString( $file->{additional_name} ), 0, 27 )
		};
		return $self;
	}
	else {
		croak "No sender account defined.";
		return 0;                             # Account Name oder Parameter fehlt!
	}
}

#****s*	addExchange
#
#	DESCRIPTION
#		Hinzufügen eines Bankauftrags
#
#	PARAMETER
#		%receiver		Empfänger bei Gutschrift, 
#                                       bzw. Lastschrift (Einzug von)
#
#		$amount			Betrag der Zahlung in Euro z.B. 100.50 
#
#		$purposes		Verwendungszweck: Einfacher String oder List mit zwei Strings
#		%sender			optional: Accountdaten des Kontoinhabers
#
#	EXAMPLE
#		$dta->addExchange({
#			name			=>	'Mustermann',
#			bank_code		=>	'10120900',
#			account_number	=>	'1029384756',
#			},112.45,["Kundennr: 16389176","Zeitraum: 7/06-9/06"]);
#
#	RETURN
#		Objekt im Erfolgsfall, 0 wenn Fehlgeschlagen
#
#******************************************************************************
sub addExchange {
	my $self     = shift;
	my $receiver = shift;
	my $amount   = shift;
	my $purposes = shift;
	my $sender   = shift;
	my $exchange = {};

	if ( !$receiver->{additional_name} ) {
		$receiver->{additional_name} = '';
	}
	foreach my $member qw(name bank_code account_number additional_name) {
		if ( !$sender || !$sender->{$member} ) {
			$sender->{$member} = $self->{account}{$member};
		}
	}
	$exchange->{receiver} = $receiver;
	$exchange->{sender}   = $sender;

	foreach my $account qw(sender receiver) {
		if ( !$exchange->{$account}{name} || length( $exchange->{$account}{name} ) == 0 ) {
			carp "Please provide a valid $account name.";
			return 0;
		}
		$exchange->{$account}{name} = substr( $self->_makeValidString( $exchange->{$account}{name} ), 0, 27 );

		if ( !$exchange->{$account}{bank_code} || !$self->_validNumeric( $exchange->{$account}{bank_code} ) ) {
			carp "Please privide a valid $account bank code.";
			return 0;
		}
		if (   !$exchange->{$account}{account_number}
			|| !$self->_validNumeric( $exchange->{$account}{account_number} ) )
		{
			carp "Please provide a valid $account account number.";
			return 0;
		}
		$exchange->{$account}{additional_name} =
		  substr( $self->_makeValidString( $exchange->{$account}{additional_name} ), 0, 27 );
	}
	unless($amount){
		carp "Please check the amount of the transaction.";
		return 0;
	}
	$amount =~ s/,/\./g;
	$exchange->{amount} = sprintf( "%.02f", $amount ) * 100;# if $amount && $amount > 0;

	if ( !ref($purposes) ) {
		$purposes = [ $purposes, '' ];
	}
	my $length = @$purposes;
	for ( my $i = 0 ; $i < $length ; ++$i ) {
		if ( $purposes->[$i] ) {
			$purposes->[$i] = substr( $self->_makeValidString( $purposes->[$i] ), 0, 27 );
		}
	}
	$exchange->{purposes} = $purposes;

	push( @{ $self->{exchanges} }, $exchange );
	$self->{amount} += $amount if $amount && $amount > 0;
	$self->{items}++;
	$self->{sum_accounts}   += $exchange->{receiver}{account_number};
	$self->{sum_bank_codes} += $exchange->{receiver}{bank_code};

	return $self;
}

#****s*	getContent
#
#	DESCRIPTION
#		Abruf der DTAUS Daten. Formatieren einer DTAUS0.txt Datensequenz.
#
#	PARAMETER
#		$execday		optional: Zeitpunkt des Transfers
#                                       Format: DD.MM.[YY]YY oder YYYY-MM-DD
#
#	RETURN
#		String mit den DTAUS Daten der Transaktionen
#
#******************************************************************************
sub getContent {
	my $self = shift;
	my $execday = shift;
	my $text;

	my $sum_account_numbers = 0;
	my $sum_bank_codes      = 0;
	my $sum_amounts         = 0;
	my $num_exchanges       = 0;

	## data record A

	# record length (128 Bytes)
	$text .= sprintf( "%04s", 128 );

	# record type
	$text .= "A";

	# file mode (credit or debit)
	$text .= ( $self->{type} == 0 ) ? "G" : "L";

	# Customer File ("K") / Bank File ("B")
	$text .= "K";

	# sender's bank code
	$text .= sprintf( "%08s", $self->{account}{bank_code} );

	# only used if Bank File, otherwise NULL
	$text .= sprintf( "%08s", "" );

	# sender's name
	$text .= sprintf( "%- 27s", $self->{account}{name} );

	# date of file creation
	$text .= strftime( "%d%m%y", localtime( $self->{timestamp} ) );

	# free (bank internal)
	$text .= sprintf( "% 4s", "" );

	# sender's account number
	$text .= sprintf( "%010s", $self->{account}{account_number} );

	# sender's reference number (optional)
	$text .= sprintf( "%010s", "" );

	# free (reserve)
	$text .= sprintf( "% 15s", "" );

	# execution date 
	$execday = strftime("%d.%m.%Y", localtime( $self->{timestamp} )) 
	    unless $execday && length($execday);
	my @dayvec = split /\./,$execday;           # DD.MM.YYYY
	if ($execday =~ m|-|) {
	    @dayvec = reverse(split /-/, $execday); # YYYY-MM-DD
	}
	$dayvec[2] -= 1900 unless $dayvec[2] < 1900;
	my $exectime = timelocal(0,0,12,$dayvec[0],$dayvec[1] - 1,$dayvec[2]);
	if($exectime <= $self->{timestamp} - 12 * 60 * 60 || 
	    $exectime > $self->{timestamp} + 365 * 24 * 60 * 60) {
	    carp "The date you provided is not plausible. Please double check results!";
	}
	# set execution date ("DDMMYYYY", optional)
	$text .= sprintf( "% 8s", strftime( "%d%m%Y", localtime($exectime) ));

	# free (reserve)
	$text .= sprintf( "% 24s", "" );

	# currency (1 = Euro)
	$text .= "1";

	foreach my $exchange ( @{ $self->{exchanges} } ) {
		## data record(s) C

		$sum_account_numbers += $exchange->{receiver}{account_number};
		$sum_bank_codes      += $exchange->{receiver}{bank_code};
		$sum_amounts         += $exchange->{amount};
		$num_exchanges       += 1;

		my @additional_purposes     = @{ $exchange->{purposes} };
		my $first_purpose           = shift(@additional_purposes);
		my @additional_parts        = ();
		my $additional_parts_number = @additional_parts;

		if ( length( $exchange->{receiver}{additional_name} ) > 0 ) {
			push(
				@additional_parts,
				{
					type => "01",
					data => $exchange->{receiver}{additional_name},
				}
			);
			$additional_parts_number = @additional_parts;
		}
		foreach my $additional_purpose (@additional_purposes) {
			push(
				@additional_parts,
				{
					type => "02",
					data => $additional_purpose,
				}
			);
			$additional_parts_number = @additional_parts;
		}
		if ( length( $exchange->{sender}{additional_name} ) > 0 ) {
			push(
				@additional_parts,
				{
					type => "03",
					data => $exchange->{sender}{additional_name},
				}
			);
			$additional_parts_number = @additional_parts;
		}

		my $data;

		# record length (187 Bytes + 29 Bytes for each additional part)
		$data .= sprintf( "%04d", 187 + $additional_parts_number * 29 );

		# record type
		$data .= "C";

		# first involved bank
		$data .= sprintf( "%08s", $exchange->{sender}{bank_code} );

		# receiver's bank code
		$data .= sprintf( "%08s", $exchange->{receiver}{bank_code} );

		# receiver's account number
		$data .= sprintf( "%010s", $exchange->{receiver}{account_number} );

		# internal customer number (11 chars) or NULL
		$data .= "0" . sprintf( "%011s", "" ) . "0";

		# payment mode (text key)
		$data .= ( $self->{type} == 0 ) ? "51" : "05";

		# additional text key
		$data .= "000";

		# bank internal
		$data .= " ";

		# free (reserve)
		$data .= sprintf( "%011s", "" );

		# sender's bank code
		$data .= sprintf( "%08s", $exchange->{sender}{bank_code} );

		# sender's account number
		$data .= sprintf( "%010s", $exchange->{sender}{account_number} );

		# amount
		$data .= sprintf( "%011s", $exchange->{amount} );

		# free (reserve)
		$data .= sprintf( "% 3s", "" );

		# receiver's name
		$data .= sprintf( "%- 27s", $exchange->{receiver}{name} );

		# delimitation
		$data .= sprintf( "% 8s", "" );

		# sender's name
		$data .= sprintf( "%- 27s", $exchange->{sender}{name} );

		# first line of purposes
		$data .= sprintf( "%- 27s", $first_purpose );

		# currency (1 = Euro)
		$data .= "1";

		# free (reserve)
		$data .= sprintf( "% 2s", "" );

		# amount of additional parts
		$data .= sprintf( "%02d", $additional_parts_number );

		if ( $additional_parts_number > 0 ) {
			my $part;
			for ( my $index = 1 ; $index <= 2 ; $index++ ) {
				my $additional_part;
				if ( $additional_parts_number > 0 ) {
					$additional_part         = shift(@additional_parts);
					$additional_parts_number = @additional_parts;
				}
				else {
					$additional_part = {
						type => "  ",
						data => ""
					};
				}

				# type of addional part
				$part .= $additional_part->{type};

				# additional part content
				$part .= sprintf( "%- 27s", $additional_part->{data} );
			}

			# delimitation
			$part .= sprintf( "% 11s", "" );
			$data .= $part;
		}

		for ( my $part = 3 ; $part <= 5 ; $part++ ) {
			my $more;
			if ( $additional_parts_number > 0 ) {
				for ( my $index = 1 ; $index <= 4 ; $index++ ) {
					my $additional_part;
					if ( $additional_parts_number > 0 ) {
						$additional_part         = shift(@additional_parts);
						$additional_parts_number = @additional_parts;
					}
					else {
						$additional_part = {
							type => "  ",
							data => ""
						};
					}

					# type of addional part
					$more .= $additional_part->{type};

					# additional part content
					$more .= sprintf( "%- 27s", $additional_part->{data} );
				}

				# delimitation
				$more .= sprintf("% 12s");
				$data .= $more;
			}
		}

		#		print "<pre>ap=$additional_parts_number=\n".encode_entities(Dumper($data))."</pre>";
		$text .= $data;
	}

	## data record E

	# record length (128 bytes)
	$text .= sprintf( "%04d", 128 );

	# record type
	$text .= "E";

	# free (reserve)
	$text .= sprintf( "% 5s", "" );

	# number of records type C
	$text .= sprintf( "%07s", $num_exchanges );

	# free (reserve)
	$text .= sprintf( "%013s", "" );

	# sum of account numbers
	$text .= sprintf( "%017s", $sum_account_numbers );

	# sum of bank codes
	$text .= sprintf( "%017s", $sum_bank_codes );

	# sum of amounts
	$text .= sprintf( "%013s", $sum_amounts );

	# delimitation
	$text .= sprintf( "% 51s", "" );

	return $self->{text} = $text;
}

#****s*	_validChar
#
#	DESCRIPTION
#		überprüfen auf gültiges DTAUS Zeichen
#
#	PARAMETER
#		$char		zu überprüfendes Zeichen
#
#	RETURN
#		1 wenn gültig, 'undef' wenn ungültig
#
#******************************************************************************
sub _validChar {
	my $self = shift;
	my $char = ord(shift);

	return $self->{_validChars}{"$char"};
}

#****s*	_validString
#
#	DESCRIPTION
#		Überprüfen auf gültige DTAUS Zeichen im String.
#
#	PARAMETER
#		$string		zu überprüfende Zeichenkette
#
#	RETURN
#		1 wenn gültig, 0 wenn ungültig
#
#******************************************************************************
sub _validString {
	my $char;
	my $self   = shift;
	my $string = shift;
	foreach $char ( split //, $string ) {
		if ( !$self->_validChar($char) ) {
			return 0;
		}
	}
	return 1;
}

#****s*	_validNumeric
#
#	DESCRIPTION
#		Überprüfen ob gültige Zahl.
#
#	PARAMETER
#		$string		zu überprüfende Zeichenkette
#
#	RETURN
#		1 wenn gültig, 0 wenn ungültig
#
#******************************************************************************
sub _validNumeric {
	my $self   = shift;
	my $string = shift;

	return ( $string =~ m/^[0-9]+$/ ) ? 1 : 0;
}

#****s*	_makeValidString
#
#	DESCRIPTION
#		Umwandeln oder entfernen ungültiger Zeichen.
#
#	PARAMETER
#		$string		zu behandelnde Zeichenkette
#
#	RETURN
#		Umgewandelte Zeichenkette
#
#******************************************************************************
sub _makeValidString {
	my $char;
	my $self   = shift;
	my $string = shift;
	my $result = '';

	$string =~ s/Ä/Ae/;
	$string =~ s/Ö/Oe/;
	$string =~ s/Ü/Ue/;
	$string =~ s/ä/ae/;
	$string =~ s/ö/oe/;
	$string =~ s/ü/ue/;
	$string =~ s/ß/ss/;
	$string = uc($string);

	foreach $char ( split //, $string ) {
		$result .= ( $self->_validChar($char) ) ? $char : ' ';
	}

	return $result;
}

sub amount {
	my $self = shift;

	return $self->{amount};
}

sub items {
	my $self = shift;

	return $self->{items};

}

sub sum_accounts {
    my $self = shift;
    return $self->{sum_accounts};
}

sub sum_bank_codes {
    my $self = shift;
    return $self->{sum_bank_codes};
}

__END__

=head1 NAME

Finance::Bank::DE::DTA::Create - Creating DTA/DTAUS files for use in Banking Software 
or for sending to the bank. Works for inner German money transactions only (receiver and
sender must have german bank accounts)

=head1 IMPORTANT NOTE

ALWAYS doublecheck the items, after importing the DTA file into your banking software 
prior to sending the order to your bank! You can also check your DTA-file here: 
https://www.xpecto.de/index.php?id=148,7

=head1 SYNOPSIS

	use Finance::Bank::DE::DTA::Create;
	my $dta = new Finance::Bank::DE::DTA::Create({
		type           => 'credit', #or debit, for 'Lastschrifteinzug'
		name           => $sendername,
		bank_code      => $senderbankcode,
		account_number => $senderaccount,
	});

	# add an item to the list
	$dta->addExchange(
		{
			name           => "John Doe",
			bank_code      => "12345678",
			account_number => "1234567890",
		},
		100.45,
		[ "$purpose1", "$purpose2" ]
	);
	
	# add another item to the list
	$dta->addExchange(
		{
			name           => "Jane Doe",
			bank_code      => "87654321",
			account_number => "0987654321",
		},
		99.75,
		$purpose3
	);	
	
	# save the dta file
	open(DAT, ">dta.txt") || die "$!";
	print DAT $dta->getContent();
	close DAT;
	
=head1 SUBROUTINES / METHODS
	
=head2 new()

The constructor. The parameters I<type>, I<name>, I<bank_code> and I<account_number> are all mandatory.
If not set properly the module will return 0.

=over

=item *

I<type> - this parameter indicates whether you want to create a dta file with credits (you send money)
or with debits (you collect money). Possible values: I<credit> or I<debit>.

=item *

I<name> - in the new()-Method this represents the name of the account owner where the dta-file will 
be used (i.e. this is you).

=item *

I<bank_code> - in the new()-Method this represents the routing number (BLZ) of the account where the 
dta-fill will be used.

=item *

I<account_number> - in the new()-Method this represents the number of the account where the dta-fill
will be used.

=back

	my $dta = new Finance::Bank::DE::DTA::Create({
		type           => 'credit', #or debit, for 'Lastschrifteinzug' (collecting money)
		name           => $sendername,
		bank_code      => $senderbankcode,
		account_number => $senderaccount,
	});
	
=head2 addExchange()

With I<addExchange()> you add an item to the list of transactions. 

The first parameter to this method is a hash with the information of the account you are sending money 
to (or collect money from). This hash has the mandatory keys I<name>, I<bank_code> (BLZ) and I<account_number>.
If they are not set properly function returns 0.

The second parameter is the amount you are sending or collecting. If amount is not > 0 function returns 0.

The third parameter is for the purpose of the transaction. It may either be a string for just one purpose 
(one line), or an array with two purpose strings (two lines). 

	$dta->addExchange(
		{
			name           => "John Doe",
			bank_code      => "12345678",
			account_number => "1234567890",
		},
		100.45,
		[ "$purpose1", "$purpose2" ] #or just $purpose
	);

=head2 amount()

With I<amount()> you can retrieve the total amount of all transactions, you already added.

=head2 items()

With I<items()> you can retrieve the total number of transactions, you already added.

=head2 sum_accounts()

With I<sum_accounts()> you can retrieve the sum of account numbers. Use for control purposes.

=head2 sum_bank_codes()

With I<sum_bank_codes()> you can retrieve the sum of bank_codes (BLZs). Use for control purposes.

	$dta->addExchange(
		{
			name           => "Jane Doe",
			bank_code      => "87654321",
			account_number => "0987654321",
		},
		100,
		$purpose
	);
	
	$dta->addExchange(
		{
			name           => "John Doe",
			bank_code      => "12345678",
			account_number => "1234567890",
		},
		50,
		$purpose
	);

	print $dta->amount(); #would print 150
	
	print $dta->items(); #would print 2

        print $dta->sum_accounts(); # would print 2222222211

        print $dta->sum_bank_codes(); # would print 99999999
	
=head2 getContent()

With I<getContent([ExecutionDate])> you get the content of the dta-file.
The Parameter I<ExecutionDate> is optional and gives the date of transfer. Format I<ExecutionDate> as "DD.MM.[YY]YY" or as "YYYY-MM-DD"

	open(DAT, ">dta.txt") || die "$!";
	print DAT $dta->getContent(); # $dta->getContent("31.03.2017")
	close DAT;
	
=head1 BUGS

I am aware of no bugs - if you find one, please let me know, preferably you already have a
solution ;)

=head1 CREDITS

This module was mainly created by Robert Urban (http://www.webcrew.de), when we were working
together and needed a solution to handle a lot of credits, without typing until the fingers bleed.
I merely did some minor changes and all the CPAN-work.

Matthias Sch�tze added the possibility to add an execution date to the dta-file and to retrieve the
sums of the account numbers and/or bank codes, which is useful for control purposes. Thank you Matthias!

=head1 AUTHOR

Ben Schnopp, C<< <bsnoop at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ben Schnopp.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
