#
# Finance::Bank::NL::CLIEOP03
#
# Copyright (C) 2007 Sebastiaan Hoogeveen. All rights reserved.
#

=pod

=head1 NAME

Finance::Bank::NL::CLIEOP03 - Generate CLIEOP03 files for Dutch banks.

=head1 SYNOPSIS

 use Finance::Bank::NL::CLIEOP03;

 $c = Finance::Bank::NL::CLIEOP03->new;

 $batch = $c->batch (
   account => '1234567',
   sender_name => 'My Company',
   type => Finance::Bank::NL::CLIEOP03::T_INCASSI
 );

 $batch->add (
   amount => 25,
   account_number => '1234567',
   account_name => 'Ms. Example',
   description => 'Taking your money'
 );

 $c->write ( 'CLIEOP03' );

=head1 DESCRIPTION

This module allows for easy creation of CLIEOP03 batch transaction files
which can be processed by Dutch banks. CLIEOP03 files can be used for
automatic debiting ("automatische incasso") or batch transfers
("verzamelgiro"). You must have a business bank account and (usually) an
additional agreement with your bank for using this.

=head1 DISCLAIMER

This module is provided as-is. Due to the nature of this module you should
check for yourself that it does its work correctly, e.g. by auditing the
source code and checking the generated files.

=head1 METHODS

=head2 Finance::Bank::NL::CLIEOP03

=cut

package Finance::Bank::NL::CLIEOP03;

our $VERSION = '0.03';

use strict;
use warnings;

use constant T_INCASSI => '10';
use constant T_BETALINGEN => '00';

use Carp;

=pod

=head3 new

 $c = Finance::Bank::NL::CLIEOP03->new (
  sender_id => 'CMPNY'
 );

Create a new CLIEOP03 file. The following parameter can be specified:

=over

=item * always_include_name

This tells the module to always include the name of the account holder, even
when the CLIEOP03 documentation says it shouldn't do that. Use this to
overcome compatibility problems with the software of the Postbank.

=item * sender_id

An identifier that is used to identify you. This may be anything of upto 5
characters. Optional, defaults to ''.

=item * serial

When more than one file is created on a single day, each must have a
different serial. Specify the serial here. Optional, defaults to 1.

=back

=cut

sub new {

  my $class = shift;
  my %param = @_;

  Carp::croak 'Required parameter sender_id not specified' unless ( $param{sender_id} );

  $param{serial} ||= 1;  
  Carp::croak 'Specified serial is invalid (must be 1 to 99)' unless (( $param{serial} >= 1 ) && ( $param{serial} <= 99 ));
  
  my $self = {
    always_include_name => $param{always_include_name},
    sender_id => $param{sender_id},
    serial => $param{serial},
    batches => []
  };

  bless $self, $class;

}

=pod

=head3 batch

 $b = $c->batch (
   account => '1234567',
   fixed_description => 'Costs for your hosting',
   sender_name => 'Hosting Corporation',
   type => Finance::Bank::NL::CLIEOP03::T_INCASSI
 )

Add a batch to the specified CLIEOP03 file. The batch is returned as a
reference to a Finance::Bank::NL::CLIEOP03::Batch object. The following
parameters can be specified:

=over

=item * account

The account number of the party that is offering the transactions for
processing (thus, your account number). This is either a 9-digit bank
account or a 3 to 7 digit giro account. Required.

=item * currency

Indicates the currency that is to be used in this batch. Valid values are
either 'NLG' for Dutch Guilder, or 'EUR' for Euro. Optional, defaults to
'EUR'.

=item * fixed_description

Indicate a description to be added to every transaction in this batch. This
field is specified as a string, but will be processed as a maximum of four
lines containing a maximum of 32 characters each. You can use newlines to
split the lines, but the string will be capped if it exceeds the limits
specified here. Optional, defaults to no fixed description.

=item * is_test

If this parameter is specified with a true value, the CLIEOP03 file is
created as a 'test' file only. Optional, defaults to writing production
files.

=item * schedule_for

Indicate the date on which the transactions from this batch are to be
executed. Specify the date in the format DDMMYY, with the date no more
than 30 days in the future. Optional, defaults to immediate transfer.

=item * sender_name

The name of the organisation creating the CLIEOP03 file, as it should appear
on the bank statements of the other parties. The maximum length of this
field is 35 characters, although the Postbank will only process the first 32
characters. Required.

=item * type

The type of transaction that this batch contains, required. The value for
this can be specified using one of the following constants:

=over

=item * Finance::Bank::NL::CLIEOP03::T_BETALINGEN to indicate "verzamelgiro" bank transfers.

=item * Finance::Bank::NL::CLIEOP03::T_INCASSI to indicate "automatische incasso" transactions.

=back

=back

=cut

sub batch {

  my $c = shift;
  my %param = @_;

  Carp::croak 'Account number not specified' unless ( $param{account} );
  Carp::croak 'Invalid account number' unless (( $param{account} =~ /^[0-9]{9}$/ ) || ( $param{account} =~ /^[0-9]{3,7}$/ ));

  $param{currency} ||= 'EUR';
  Carp::croak 'Invalid currency' unless (( $param{currency} eq 'NLG' ) || ( $param{currency} eq 'EUR' ));

  if ( $param{schedule_for} ) {
    Carp::croak 'Invalid schedule date' unless ( $param{schedule_for} =~ /^[0-3][0-9][0-1][0-9]{3}$/ );
  }

  Carp::croak 'No sender name specified' unless ( $param{sender_name} );

  my $batch = {
    account => $param{account},
    currency => $param{currency},
    fixed_description => $param{fixed_description},
    is_test => $param{is_test},
    schedule_for => $param{schedule_for},
    sender_name => $param{sender_name},
    type => $param{type},
    transactions => []
  };

  bless $batch, 'Finance::Bank::NL::CLIEOP03::Batch';
  push @{$c->{batches}}, $batch;
  return $batch;

}

=pod

=head3 as_string

 $s = $c->as_string;

Return the CLIEOP03 file as a single string, containing the records
specified by a \r\n pair.

=cut

sub as_string {

  my $self = shift;
  my $s;

  # Bestandsvoorloopinfo (0001)

  my @now = localtime;
  $self->{sender_id} = substr ( $self->{sender_id}, 0, 5 ) if ( length ( $self->{sender_id} ) > 5 );

  $s = sprintf ( 
    "%04d%1s%02d%02d%02d%-8s%-5s%02d%02d%1d%21s\r\n",
    '0001',			# Infocode
    'A',			# Variantcode
    $now[3],			# Aanmaakdatumbestand (day)
    $now[4] + 1,		# Aanmaakdatumbestand (month)
    $now[5] % 100,		# Aanmaakdatumbestand (year without century)
    'CLIEOP03',			# Bestandsnaam
    $self->{sender_id} || '', 	# Inzenderidentificatie
    $now[3],			# Bestandsidentificatie (day)
    $self->{serial} || 1,	# Bestandsidentificatie (serial)
    1,				# Duplicaatcode
    ''				# Filler
  );

  my $batch_serial = 1;

  foreach my $batch ( @{$self->{batches}} ) {

    # Batchvoorloopinfo (0010)

    $s .= sprintf (
      "%04d%1s%02d%010d%04d%-3s%26s\r\n",
      '0010',			# Infocode
      'B',			# Variantcode
      $batch->{type},		# Transactiegroep
      $batch->{account},	# Reknropdrachtgever
      $batch_serial,		# Batchvolgnummer
      $batch->{currency},	# Aanleveringsmuntsoort
      ''			# Filler
    );

    if ( $batch->{fixed_description} ) {
      foreach my $desc_line ( $self->_split_description ( $batch->{fixed_description} )) {

        # Vasteomschrijvinginfo (0020)

        $s .= sprintf (
          "%04d%1s%-32s%13s\r\n",
          '0020',		# Infocode
          'A',			# Variantcode
          $desc_line,		# Vasteomschrijving
          ''			# Filler
        );
        
      }
    }

    # Opdrachtgeverinfo (0030)

    $batch->{sender_name} = substr ( $batch->{sender_name}, 0, 35 ) if ( length ( $batch->{sender_name} ) > 35 );

    $s .= sprintf (
      "%04d%1s%1d%06d%-35s%1s%2s\r\n",
      '0030',				# Infocode
      'B',				# Variantcode
      1,				# NAWcode
      $batch->{schedule_for} || 0,	# Gewensteverwerkingsdatum
      $batch->{sender_name},		# Naamopdrachtgever
      $batch->{is_test} ? 'T' : 'P',	# Testcode
      ''				# Filler
    );

    my ( $totalcents, $totalaccounts, $totaltransactions ) = ( 0, 0, 0 );

    if ( $batch->{type} == Finance::Bank::NL::CLIEOP03::T_INCASSI ) {

      # INCASSI transactions

      foreach my $inc ( @{$batch->{transactions}} ) {

        # Transactieinfo (0100)

        $s .= sprintf (
          "%04d%1s%04d%012.0f%010d%010d%9s\r\n",
          '0100',				# Infocode
          'A',					# Variantcode
          ( $inc->{check} ? 1002 : 1001 ),	# Transactiesoort
          $inc->{amount} * 100,			# Bedrag
          $inc->{account_number},		# Reknrbetaler
          $batch->{account},			# Reknrbegunstigde
          ''					# Filler
        );

        $totalcents += int ( $inc->{amount} * 100 );
        $totalaccounts += $inc->{account_number} + $batch->{account};
        $totaltransactions++;

        if ( $inc->{check} || $self->{always_include_name} ) {

          # Naambetalerinfo (0110)

          $inc->{account_name} = substr ( $inc->{account_name}, 0, 35 ) if ( length ( $inc->{account_name} ) > 35 );

          $s .= sprintf (
            "%04d%1s%-35s%10s\r\n",
            '0110',			# Infocode
            'B',			# Variantcode
            $inc->{account_name},	# Naambetaler
            ''				# Filler
          );

          if ( $inc->{account_city} ) {

            # Woonplaatsbetalerinfo (0113)

            $inc->{account_city} = substr ( $inc->{account_city}, 0, 35 ) if ( length ( $inc->{account_city} ) > 35 );

            $s .= sprintf (
              "%04d%1s%-35s%10s\r\n",
              '0113',			# Infocode
              'B',			# Variantcode
              $inc->{account_city},	# Woonplaatsbetaler
              ''			# Filler
            );

          }
        }

        if ( $inc->{identifier} ) {

          # Betalingskenmerkinfo (0150)

          $s .= sprintf (
            "%04d%1s%016.0f%29s\r\n",
            '0150',			# Infocode
            'A',			# Variantcode
            $inc->{identifier},		# Betalingskenmerk
            '' 				# Filler
          );

        }

        if ( $inc->{description} ) {

          foreach my $desc_line ( $self->_split_description ( $inc->{description} )) {

            # Omschrijvingsinfo (0160)

            $s .= sprintf (
              "%04d%1s%-32s%13s\r\n",
              '0160',			# Infocode
              'A',			# Variantcode
              $desc_line,		# Omschrijving
              ''			# Filler
            );

          }
        }
      }
    }

    # Batchsluitinfo (9990)

    $s .= sprintf (
      "%04d%1s%018.0f%010.0f%07.0f%10s\r\n",
      '9990',				# Infocode
      'A',				# Variantcode
      $totalcents % 10**18,		# Totaalbedrag
      $totalaccounts % 10**10,		# Totaalreknrs
      $totaltransactions % 10**7,	# Aantal posten
      ''				# Filler
    );	

  }

  # Bestandssluitinfo (9999)

  $s .= sprintf (
    "%04d%1s%45s\r\n",
    '9999',			# Infocode
    'A',			# Variantcode
    ''				# Filler
  );

}

=pod

=head3 write

 $c->write ( 'CLIEOP03' );

Write the CLIEOP03 file to the filename specified.

=cut

sub write {

  my $self = shift;
  my ( $filename ) = @_;

  Carp::croak 'Required filename not specified' unless ( $filename );
  open ( CLIEOPFILE, ">$filename" ) or Carp::croak "Cannot open $filename for writing: $!";
  print CLIEOPFILE $self->as_string;
  close ( CLIEOPFILE );

}

#
# PRIVATE METHODS
#

#
# @lines = $self->_split_description ( $description )
#
# Split a description to a maximum of 4 lines containing a maximum of 32
# characters each. Note that we do not do any fancy wrapping here; however,
# any newlines or returns in the description can be used to wrap text.
#

sub _split_description {

  my $self = shift;
  my ( $desc ) = @_;

  my @lines;
  foreach ( split /(\n|\r)+/, $desc ) {

    chomp;

    while ( length ( $_ ) > 32 && ( @lines < 4 )) {
      push @lines, substr ( $_, 0, 32 );
      $_ = substr ( $_, 32 );
    }

    push @lines, $_ if ( $_ );

    last if ( @lines >= 4 );

  } 

  @lines = @lines[0..3] if ( @lines > 4 );
  return @lines;

}

package Finance::Bank::NL::CLIEOP03::Batch;

=pod

head2 Finance::Bank::NL::CLIEOP03::Batch

=head3 add

Add a transaction to the current batch. This method is a frontend for
add_betaling and add_incasso, and will select which method to be eventually
executed based on the type of the current batch. Note that it is not
possible to add transactions of a different type to a batch.

=cut

sub add {

  my $self = shift;
  if ( $self->{type} == Finance::Bank::NL::CLIEOP03::T_INCASSI ) {
    $self->add_incasso ( @_ );
  }

}

=pod

=head3 add_incasso

 $batch->add_incasso (
   account_number => '1234556789',
   amount => 10.00,
   description => 'Customer 1234',
   identifier => 6435893353335
 );

For payments in a batch of type T_INCASSI the following parameters can be
specified:

=over

=item * account_city

The city of residence of the payee, consisting of no more than 32
characters. This field is optional if 'check' is true, and ignored
otherwise.

=item * account_name

The name of the payee, consisting of no more than 32 characters. This field
is required if 'check' is true, and ignored otherwise.

=item * account_number

The account number of the payee, either as a 9-digit bank account number or
a 3 to 7 digit giro number.

=item * amount

The amount to be debited, specified in the batch's currency. Required.

=item * check

If specified with a true value, the account number is to be checked against
the specified name. This parameter is ignored with 9-digit bank accounts.
Optional, defaults to true.

=item * description

The description of this transaction. This is added to the fixed_description
of the batch, and should adhere to the exact same rules. Note that banks
will usually only process the first four lines of the fixed_description and
the description together. Optional.

=item * identifier

A unique identifier for this transaction, which will be reported by the bank
on any feedback. Consists of no more than 16 digits (if less than 16 digits
are specified, the identifier is padded with zeros at the left). Optional.

=back

=cut

sub add_incasso {

  my $self = shift;
  my %param = @_;

  unless ( exists $param{check} ) {
    $param{check} = 1 if ( $param{account_number} !~ /^[0-9]{9}$/ );
  }

  if ( $param{check} ) {
    Carp::croak ( 'The parameter account_name is required when check is true' ) unless ( $param{account_name} );
  }

  Carp::croak ( 'The parameter account_number is required' ) unless ( $param{account_number} );
  Carp::croak ( 'The parameter account_number is invalid' ) unless (( $param{account_number} =~ /^[0-9]{9}$/ ) || ( $param{account_number} =~ /^[0-9]{3,7}$/ ));

  Carp::croak ( 'The parameter amount is required' )  unless ( $param{amount} );
  Carp::croak ( 'The parameter amount is invalid' ) unless ( $param{amount} =~ /^[0-9\.]*$/ );

  if ( $param{identifier} ) {
    Carp::croak ( 'The parameter identifier is invalid' ) unless ( $param{identifier} =~ /^[0-9]+$/ );
  }

  my $transaction = {
    account_city => $param{account_city},
    account_name => $param{account_name},
    account_number => $param{account_number},
    amount => $param{amount},
    check => ( length ( $param{account_number} ) < 9 ? $param{check} : 0),
    description => $param{description},
    identifier => $param{identifier}
  };

  push @{$self->{transactions}}, $transaction;

}

=pod

=head1 CAVEATS

This module currently only supports the T_INCASSI transaction type.

Please note the version number; this module has not yet been extensively
tested. However, since implementing CLIEOP03 is both tedious and boring, I
thought I should make this module available ASAP.

=head1 AUTHOR

Sebastiaan Hoogeveen <pause-zebaz@nederhost.nl>

=head1 COPYRIGHT

Copyright (c) 2007 Sebastiaan Hoogeveen. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

1;
