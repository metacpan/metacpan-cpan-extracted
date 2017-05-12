package Finance::QIF;

use 5.006;
use strict;
use warnings;
use Carp;
use IO::File;

our $VERSION = '3.02';
$VERSION = eval $VERSION;

my %noninvestment = (
    "D" => "date",
    "T" => "transaction",
    "U" => "total",         #Quicken 2005 added this which is usually the same
                            #as T but can sometimes be higher.
    "C" => "status",
    "N" => "number",
    "P" => "payee",
    "M" => "memo",
    "A" => "address",
    "L" => "category",
    "S" => "splits"
);

my %split = (
    "S" => "category",
    "E" => "memo",
    '$' => "amount"
);

my %investment = (
    "D" => "date",
    "N" => "action",
    "Y" => "security",
    "I" => "price",
    "Q" => "quantity",
    "T" => "transaction",
    "U" => "total",         #Quicken 2005 added this which is usually the same
                            #as T but can sometimes be higher.
    "C" => "status",
    "P" => "text",
    "M" => "memo",
    "O" => "commission",
    "L" => "account",
    '$' => "amount"
);

my %account = (
    "N" => "name",
    "D" => "description",
    "L" => "limit",
    "X" => "tax",
    "A" => "note",
    "T" => "type",
    "B" => "balance"
);

my %category = (
    "N" => "name",
    "D" => "description",
    "B" => "budget",
    "E" => "expense",
    "I" => "income",
    "T" => "tax",
    "R" => "schedule"
);

my %class = (
    "N" => "name",
    "D" => "description"
);

my %memorized = (
    "K" => "type",
    "T" => "transaction",
    "U" => "total",        #Quicken 2005 added this which is usually the same as
                           #as T but can sometimes be higher.
    "C" => "status",
    "P" => "payee",
    "M" => "memo",
    "A" => "address",
    "L" => "category",
    "S" => "splits",
    "N" => "action",       #Quicken 2006 added N, Y, I, Q, $ for investment
    "Y" => "security",
    "I" => "price",
    "Q" => "quantity",
    '$' => "amount",
    "1" => "first",
    "2" => "years",
    "3" => "made",
    "4" => "periods",
    "5" => "interest",
    "6" => "balance",
    "7" => "loan"
);

my %security = (
    "N" => "security",
    "S" => "symbol",
    "T" => "type",
    "G" => "goal",
);

my %budget = (
    "N" => "name",
    "D" => "description",
    "E" => "expense",
    "I" => "income",
    "T" => "tax",
    "R" => "schedule",
    "B" => "budget"
);

my %payee = (
    "P" => "name",
    "A" => "address",
    "C" => "city",
    "S" => "state",
    "Z" => "zip",
    "Y" => "country",
    "N" => "phone",
    "#" => "account"
);

my %prices = (
    "S" => "symbol",
    "P" => "price"
);

my %price = (
    "C" => "close",
    "D" => "date",
    "X" => "max",
    "I" => "min",
    "V" => "volume"
);

my %nofields = ();

my %header = (
    "Type:Bank"         => \%noninvestment,
    "Type:Cash"         => \%noninvestment,
    "Type:CCard"        => \%noninvestment,
    "Type:Invst"        => \%investment,
    "Type:Oth A"        => \%noninvestment,
    "Type:Oth L"        => \%noninvestment,
    "Account"           => \%account,
    "Type:Cat"          => \%category,
    "Type:Class"        => \%class,
    "Type:Memorized"    => \%memorized,
    "Type:Security"     => \%security,
    "Type:Budget"       => \%budget,
    "Type:Payee"        => \%payee,
    "Type:Prices"       => \%prices,
    "Option:AutoSwitch" => \%nofields,
    "Option:AllXfr"     => \%nofields,
    "Clear:AutoSwitch"  => \%nofields
);

sub new {
    my $class = shift;
    my %opt   = @_;
    my $self  = {};

    $self->{debug}            = $opt{debug}            || 0;
    $self->{autodetect}       = $opt{autodetect}       || 0;
    $self->{trim_white_space} = $opt{trim_white_space} || 0;
    $self->{record_separator} = $opt{record_separator} || $/;

    bless( $self, $class );

    if ( $opt{file} ) {
        $self->file( $opt{file} );
        $self->open;
    }
    return $self;
}

sub file {
    my $self = shift;
    if (@_) {
        my @file = ( ref( $_[0] ) eq "ARRAY" ? @{ shift @_ } : (), @_ );
        $self->{file} = [@file];
    }
    if ( $self->{file} ) {
        return wantarray ? @{ $self->{file} } : $self->{file}->[0];
    }
    else {
        return undef;
    }
}

sub record_separator {
    my $self = shift;
    return $self->{record_separator};
}

sub _filehandle {
    my $self = shift;
    if (@_) {
        my @args = @_;
        $self->{_filehandle} = IO::File->new(@args)
          or croak("Failed to open file '$args[0]': $!");
        binmode( $self->{_filehandle} );
        $self->{_linecount} = 0;
    }
    if ( !$self->{_filehandle} ) {
        croak("No filehandle available");
    }
    return $self->{_filehandle};
}

sub open {
    my $self = shift;
    if (@_) {
        $self->file(@_);
    }
    if ( $self->file ) {
        $self->_filehandle( $self->file );
        if ( $self->{autodetect} ) {
            if ( $self->_filehandle->seek( -2, 2 ) ) {
                my $buffer = "";
                $self->_filehandle->read( $buffer, 2 );
                if ( $buffer eq "\015\012" ) {
                    $self->{record_separator} = "\015\012";
                }
                elsif ( $buffer =~ /\012$/ ) {
                    $self->{record_separator} = "\012";
                }
                elsif ( $buffer =~ /\015$/ ) {
                    $self->{record_separator} = "\015";
                }
            }
        }
        $self->reset();
    }
    else {
        croak("No file specified");
    }
}

sub next {
    my $self = shift;
    my %object;
    my $continue = 1;
    my $csplit;    # Need to keep track of current split for adding split values
    if ( $self->_filehandle->eof ) {
        return undef;
    }
    if ( exists( $self->{header} ) ) {
        $object{header} = $self->{header};
    }
    while ( !$self->_filehandle->eof && $continue ) {
        my $line = $self->_getline;
        next if ( $line =~ /^\s*$/ );
        my ( $field, $value ) = $self->_parseline($line);
        if ( $field eq '!' ) {
            $value =~ s/\s+$//;    # Headers sometimes have trailing white space
            $self->{header} = $value;
            $object{header} = $value;
            if ( !exists( $header{$value} ) ) {
                $self->_warning("Unknown header format '$value'");
            }
        }
        else {
            if ( $field eq '^' ) {
                $continue = 0;
            }
            else {
                if (
                    !exists( $header{ $object{header} } )
                    && !(
                        exists( $header{"split"} )
                        && (   $object{header} eq "noninvestment"
                            || $object{header} eq "memorized" )
                    )
                  )
                {
                    $self->_warning(
                        "Unknown header '$object{header}' can't process line");
                }
                elsif ( $object{header} eq "Type:Prices" ) {
                    $object{"symbol"} = $field;
                    push( @{ $object{"prices"} }, $value );
                }
                elsif ($field eq 'A'
                    && $header{ $object{header} }{$field} eq "address" )
                {
                    if ( $self->{header} eq "Type:Payee" ) {

                        # The address fields are numbered for this record type
                        if ( length($value) == 0 ) {
                            $self->_warning( 'Improper address record for '
                                  . 'this record type' );
                        }
                        else {
                            $value = substr( $value, 1 );
                        }
                    }
                    if ( exists( $object{ $header{ $object{header} }{$field} } )
                        && $object{ $header{ $object{header} }{$field} } ne "" )
                    {
                        $object{ $header{ $object{header} }{$field} } .= "\n";
                    }
                    $object{ $header{ $object{header} }{$field} } .= $value;
                }
                elsif ($field eq 'S'
                    && $header{ $object{header} }{$field} eq "splits" )
                {
                    my %mysplit;    # We assume "S" always appears first
                    $mysplit{ $split{$field} } = $value;
                    push( @{ $object{splits} }, \%mysplit );
                    $csplit = \%mysplit;
                }
                elsif ( ( $field eq 'E' || $field eq '$' ) && $csplit ) {

                    # this currently assumes the "S" was found first
                    $csplit->{ $split{$field} } = $value;
                }
                elsif ($field eq 'B'
                    && $header{ $object{header} }{$field} eq "budget" )
                {
                    push( @{ $object{budget} }, $value );
                }
                elsif ( exists( $header{ $object{header} }{$field} ) ) {
                    $object{ $header{ $object{header} }{$field} } = $value;
                }
                else {
                    $self->_warning("Unknown field '$field'");
                }
            }
        }
    }

    # Must check that we have a valid record to return
    if ( scalar( keys %object ) > 1 ) {
        return \%object;
    }
    else {
        return undef;
    }
}

sub _parseline {
    my $self = shift;
    my $line = shift;
    my @result;
    if (   $line !~ /^!/
        && exists( $self->{header} )
        && $self->{header} eq "Type:Prices" )
    {
        my %price;
        $line =~ s/\"//g;
        my @data = split( ",", $line );
        $result[0]      = $data[0];
        $price{"close"} = $data[1];
        $price{"date"}  = $data[2];
        if ( scalar(@data) > 3 ) {
            $price{"max"}    = $data[3];
            $price{"min"}    = $data[4];
            $price{"volume"} = $data[5];
        }
        $result[1] = \%price;
    }
    else {
        $result[0] = substr( $line, 0, 1 );
        $result[1] = substr( $line, 1 );
        if ( $self->{trim_white_space} ) {
            $result[1] =~ s/^\s*(.*?)\s*$/$1/;
        }
    }
    return @result;
}

sub _getline {
    my $self = shift;
    local $/ = $self->record_separator;
    my $line = $self->_filehandle->getline;
    chomp($line);
    $self->{_linecount}++;
    return $line;
}

sub _warning {
    my $self    = shift;
    my $message = shift;
    carp(   $message
          . " in file '"
          . $self->file
          . "' line "
          . $self->{_linecount} );
}

sub header {
    my $self   = shift;
    my $header = shift;
    my $fh     = $self->_filehandle;
    local $\ = $self->{record_separator};
    print( $fh "!", $header );

    # used during write to validate passed record is appropriate for
    # current header also generate reverse lookup for mapping record
    # values to file key identifier.
    $self->{currentheader} = $header;
    foreach my $key ( keys %{ $header{$header} } ) {
        $self->{reversemap}{ $header{$header}{$key} } = $key;
    }
    if ( exists( $header{$header}{S} ) && $header{$header}{S} eq "splits" ) {
        foreach my $key ( keys %split ) {
            $self->{reversesplitsmap}{ $split{$key} } = $key;
        }
    }

    $self->{_linecount}++;
    if ( !exists( $header{$header} ) ) {
        $self->_warning("Unsupported header '$header' written to file");
    }
}

sub write {
    my $self   = shift;
    my $record = shift;
    if ( $record->{header} eq $self->{currentheader} ) {
        if ( $record->{header} eq "Type:Prices" ) {
            if ( exists( $record->{symbol} ) && exists( $record->{prices} ) ) {
                foreach my $price ( @{ $record->{prices} } ) {
                    if (   exists( $price->{close} )
                        && exists( $price->{date} )
                        && exists( $price->{max} )
                        && exists( $price->{min} )
                        && exists( $price->{volume} ) )
                    {
                        $self->_writeline(
                            join( ",",
                                '"' . $record->{symbol} . '"',
                                $price->{close},
                                '"' . $price->{date} . '"',
                                $price->{max},
                                $price->{min},
                                $price->{volume} )
                        );
                    }
                    elsif (exists( $price->{close} )
                        && exists( $price->{date} ) )
                    {
                        $self->_writeline(
                            join( ",",
                                '"' . $record->{symbol} . '"',
                                $price->{close},
                                '"' . $price->{date} . '"' )
                        );
                    }
                    else {
                        $self->_warning("Prices missing a required field");
                    }
                }
                $self->_writeline("^");
            }
            else {
                $self->_warning("Record missing 'symbol' or 'prices'");
            }
        }
        else {
            foreach my $value ( keys %{$record} ) {
                next
                  if (
                       $value eq "header"
                    || $value eq "splits"
                    || (   $self->{currentheader} eq "Type:Memorized"
                        && $value eq "transaction" )
                  );
                if ( exists( $self->{reversemap}{$value} ) ) {
                    if ( $value eq "address" ) {
                        my @lines = split( "\n", $record->{$value} );
                        if ( $self->{currentheader} eq "Type:Payee" ) {

                          # The address fields are numbered for this record type
                            for ( my $count = 0 ; $count < 3 ; $count++ ) {
                                if ( $count <= $#lines ) {
                                    $self->_writeline( "A", $count,
                                        $lines[$count] );
                                }
                                else {
                                    $self->_writeline( "A", $count );
                                }
                            }
                        }
                        else {
                            for ( my $count = 0 ; $count < 6 ; $count++ ) {
                                if ( $count <= $#lines ) {
                                    $self->_writeline( "A", $lines[$count] );
                                }
                                else {
                                    $self->_writeline("A");
                                }
                            }
                        }
                    }
                    elsif ( $value eq "budget" ) {
                        foreach my $amount ( @{ $record->{$value} } ) {
                            $self->_writeline( $self->{reversemap}{$value},
                                $amount );
                        }
                    }
                    else {
                        $self->_writeline( $self->{reversemap}{$value},
                            $record->{$value} );
                    }
                }
                else {
                    $self->_warning( "Unsupported field '$value'"
                          . " found in record ignored" );
                }
            }
            if ( exists( $record->{splits} ) ) {
                foreach my $s ( @{ $record->{splits} } ) {
                    foreach my $key ( 'category', 'memo', 'amount' ) {
                        if ( exists( $s->{$key} ) ) {
                            $self->_writeline( $self->{reversesplitsmap}{$key},
                                $s->{$key} );
                        }
                        else {
                            $self->_writeline(
                                $self->{reversesplitsmap}{$key} );
                        }
                    }
                }
            }
            if ( $self->{currentheader} eq "Type:Memorized"
                && exists( $record->{transaction} ) )
            {
                $self->_writeline( $self->{reversemap}{"transaction"},
                    $record->{"transaction"} );
            }
            $self->_writeline("^");
        }
    }
    else {
        $self->_warning( "Record header type '"
              . $record->{header}
              . "' does not match current output header type "
              . $self->{currentheader}
              . "." );
    }
}

sub _writeline {
    my $self = shift;
    my $fh   = $self->_filehandle;
    local $\ = $self->{record_separator};
    print( $fh @_ );
    $self->{_linecount}++;
}

sub reset {
    my $self = shift;
    map( $self->{$_} = undef,    # initialize internally used variables
        qw(_linecount header currentheader reversemap reversesplitsmap) );
    $self->_filehandle->seek( 0, 0 );
}

sub close {
    my $self = shift;
    $self->_filehandle->close;
}

1;

__END__

=head1 NAME

Finance::QIF - Parse and create Quicken Interchange Format files

=head1 SYNOPSIS

  use Finance::QIF;
  
  my $qif = Finance::QIF->new( file => "test.qif" );
  
  while ( my $record = $qif->next ) {
      print( "Header: ", $record->{header}, "\n" );
      foreach my $key ( keys %{$record} ) {
          next
            if ( $key eq "header"
              || $key eq "splits"
              || $key eq "budget"
              || $key eq "prices" );
          print( "     ", $key, ": ", $record->{$key}, "\n" );
      }
      if ( exists( $record->{splits} ) ) {
          foreach my $split ( @{ $record->{splits} } ) {
              foreach my $key ( keys %{$split} ) {
                  print( "     Split: ", $key, ": ", $split->{$key}, "\n" );
              }
          }
      }
      if ( exists( $record->{budget} ) ) {
          print("     Budget: ");
          foreach my $amount ( @{ $record->{budget} } ) {
              print( " ", $amount );
          }
          print("\n");
      }
      if ( exists( $record->{prices} ) ) {
          print("     Date     Close   Max     Min     Volume\n");
          $format = "     %8s %7.2f %7.2f %7.2f %-8d\n";
          foreach my $price ( @{ $record->{prices} } ) {
              printf( $format,
                  $price->{"date"}, $price->{"close"}, $price->{"max"},
                  $price->{"min"},  $price->{"volume"} );
          }
      }
  }

=head1 DESCRIPTION

Finance::QIF is a module for working with QIF (Quicken Interchange
Format) files in Perl.  This module reads QIF data records from a file
passing each successive record to the caller for processing.  This
module also has the capability of writing QIF records to a file.

The QIF file format typically consists of a header containing a record
or transaction type, followed by associated data records.  Within a
file there may be multiple headers.  Headers are usually followed by
data records, however data is not required to always follow a header.

A hash reference is returned for each record read from a file.  The
hash will have a "header" value which contains the header type that
was read along with all supported values found for that record.  If a
value is not specified in the data file, the value will not exist in
this hash.

No processing or validation is done on values found in files or data
structures to try and convert them into appropriate types and formats.
It is expected that users of this module or extensions to this module
will do any additional processing or validation as required.

=head2 RECORD TYPES & VALUES

The following record types are currently supported by this module:

=over

=item Type:Bank, Type:Cash, Type:CCard, Type:Oth A, Type:Oth L

These are non investment ledger transactions.  All of these record
types support the following values.

=over

=item date

Date of transaction.

=item transaction

Dollar amount of transaction.

=item total

Dollar amount of transaction. This is generally the same as transaction but
in some cases can be higher. (Introduced in Quicken 2005 for windows)

=item status

Reconciliation status of transaction.

=item number

Check number of transaction.

=item payee

Who the transaction was made to.

=item memo

Additional text describing the transaction.

=item address

Address of payee.

=item category

Category the transaction is assigned to.

=item splits

If the transaction contains splits this will be defined and consist of
an array of hash references.  With each split potentially having the
following values.

=over

=item category

Category the split is assigned to.

=item memo

Additional text describing the split.

=item amount

Dollar amount of split.

=back

=back

=item Type:Invst

This is for Investment ledger transactions.  The following values are
supported for this record type.

=over

=item date

Date of transaction.

=item action

Type of transaction like buy, sell, ...

=item security

Security name of transaction.

=item price

Price of security at time of transaction.

=item quantity

Number of shares purchased.

=item transaction

Cost of shares in transaction.

=item status

Reconciliation status of transaction.

=item text

Text for non security specific transaction.

=item memo

Additional text describing transaction.

=item commission

Commission fees related to transaction.

=item account

Account related to security specific transaction.

=item amount

Dollar amount of transaction.

=item total

Dollar amount of transaction. This is generally the same as amount but
in some cases can be higher. (Introduced in Quicken 2005 for windows)

=back

=item Account

This is a list of accounts.  In cases where it is used in a file by
first providing one account record followed by a investment or
non-investment record type and its transactions, it means that that
set of transactions is related to the specified account.  In other
cases it can just be a sequence of Account records.

Each account record supports the following values.

=over

=item name

Account name.

=item description

Account description.

=item limit

Account limit usually for credit card accounts that have some upper
limit over credit.

=item tax

Defined if the account is tax related.

=item note

Additional information about the account.

=item type

Type of account.

=item balance

Current balance of account.

=back

=item Type:Cat

This is a list of categories.  The following values are supported for
category records.

=over

=item name

Name of category.

=item description

Description of category.

=item budget

An array of 12 values Jan-Dec to represent the budget amount for each
month.

=item expense

Usually exists if the category is an expense account however this is
often a default assumed value and doesn't show up in files.

=item income

Exists if the category is an income account.

=item tax

Exists if this category is tax related.

=item schedule

If this category is tax related this specifies what tax schedule it is
related if defined.

=back

=item Type:Class

This is a list of classes.  The following values are supported for
class records.

=over

=item name

Name of class.

=item description

Description of class.

=back

=item Type:Memorized

This is a list of memorized transactions.  The following values are
supported for memorized transaction records.

=over

=item type

Type of memorized transaction "C" for check, "D" for deposit, "P" for
payment, "I" for investment, and "E" for electronic payee.

=item transaction

Dollar amount of transaction.

=item total

Dollar amount of transaction. This is generally the same as amount but
in some cases can be higher. (Introduced in Quicken 2005 for windows)

=item status

Reconciliation status of transaction.

=item payee

Who the transaction was made to.

=item memo

Additional text describing the transaction.

=item address

Address of payee.

=item category

Category the transaction is assigned to.

=item action

Type of investment transaction like buty, sell, ... (Inroduced in Quicken
2006 for windows)

=item security

Security name of transaction. (Inroduced in Quicken 2006 for windows)

=item price

Price of security. (Inroduced in Quicken 2006 for windows)

=item quantity

Quantity of security. (Inroduced in Quicken 2006 for windows)

=item amount

Dollar amount of transaction. (Introduced in Quicken 2006 for windows)

=item splits

If the transaction contains splits this will be defined and consist of
an array of hashes.  With each split potentially having the following
values.

=over

=item category

Category the split is assigned to.

=item memo

Additional text describing the split.

=item amount

Dollar amount of split.

=back

=item first

First payment date.

=item years

Total years for loan.

=item made

Number of payments already made.

=item periods

Number of periods per year.

=item interest

Interest rate of loan.

=item balance

Current loan balance.

=item loan

Original loan amount.

=back

=item Type:Security

This is a list of securities.  The following values are supported for
security records.

=over

=item security

Security name.

=item symbol

Security symbol.

=item type

Security type.

=item goal

Security goal.

=back

=item Type:Budget

This is a list of budget values for categories.  The following values
are supported for budget records.

=over

=item name

Category name of budgeted item.

=item description

Category Description of budgeted item.

=item expense

Usually exists if the category is an expense account however this is
often a default assumed value and doesn't show up in files.

=item income

Exists if the category is an income account.

=item tax

Exists if this category is tax related.

=item schedule

If this category is tax related this specifies what tax schedule it is
related if defined.

=item budget

An array of 12 values Jan-Dec to represent the budget amount for each
month.

=back

=item Type:Payee

This is a list online payee accounts.  The following values are
supported for online payee account records.

=over

=item name

Name of payees.

=item address

Address of payee.

=item city

City of payee.

=item state

State of payee

=item zip

Zipcode of payee.

=item country

Country of payee.

=item phone

Phone number of payee.

=item account

Account number for payee transaction.

=back

=item Type:Prices

This is a list of prices for a security.  The following values are
supported for security prices records.

=over

=item symbol

Security Symbol.

=item prices

An array of hashes.  With each hash having the following values.

=over

=item date

Date of security values.

=item close

Close value of security for the date.

=item max

Max value of security for the date.

=item min

Min value of security for the date.

=item volume

Number of shares of security exchanged for the date.

=back

=back

=item Option:AllXfr, Option:AutoSwitch, Clear:AutoSwitch

These record types aren't related to transactions but instead provided
ways to control how Quicken processes the QIF file.  They have no
impact on how this software operates and are ignored when found.

=back

Note: If this software finds unsupported record types or values in a
data file a warning will be generated containing information on what
unexpected value was found.

=head1 METHODS

=head2 new()

Creates a new instance of Finance::QIF.  Supports the following
initializing values.

  my $qif = Finance::QIF->new( file => "myfile", debug => 1 );

If the file is specified it will be opened on new.

=over

=item file

Specifies file to use for processing.  See L</file()> for details.

  my $in = Finance::QIF->new( file => "myfile" );
OR
  my $in = Finance::QIF->new( file => [ "myfile", "<:crlf" ] );

For output files, be sure to open the file in write mode.  For example:

  my $out = Finance::QIF->new( file => ">myfile" );

=item record_separator

Can be used to redefine the QIF record separator.  Default is $/.

  my $in = Finance::QIF->new( record_separator => "\012" );

Note: For MacOS X it will most likely be necessary to change this to
"\015".  Quicken on MacOS X generates files with "\015" as the separator
which is typical of Mac however the native perl in MacOS X is unix
based and uses the default unix separator which is "\012".  See
L</autodetect> for another option.

=item autodetect

Enable auto detection of the record separator based on the file
contents.  Default is "0".

  my $in = Finance::QIF->new( autodetect => 1 );

Perl uses $/ to define line separators for text files.  Perl sets this
value according to the OS perl is running on:

  Windows="\015\012"
  Mac="\015"
  Unix="\012"

In many cases you may find yourself with text files that do not match
the OS.  In these cases Finance::QIF by default will not process that
QIF file correctly. This feature is an attempt to help with the most
common cases of having the wrong text file for the OS Finance::QIF is
running on.

This feature depends on being able to seek to the end of the file and
reading the last 2 characters to determine the proper separator. If a
seek can not be performed or the last 2 characters are not a proper
separator the record_separator will default to $/ or the value passed
in. If a valid record_separator is found then it will be set according
to what was in the file.

This code requires a file use a consistent line separator. If you find
your self dealing with unusual files containing mixed separators you
need to first Normalize the file to a consistent separator.

Normalizing a text file to have a consistent line separator is done in
modules like  File::LocalizeNewlines or Template::Parser::LocalizeNewlines
so if you are having issues with trying to process poorly formated text
files look at preprocessing them with something like those before passing
on to Finance::QIF.

=item trim_white_space

Can be used to remove leading and trailing white space from values
returned. Default is "0".

  my $qif = Finance::QIF->new( trim_white_space => 1 );

=item debug

Can be used to output debug information.  Default is "0".

  my $qif = Finance::QIF->new( debug => 1 );

=back

=head2 file()

Specify file name and optionally additional parameters that will be
used to obtain a filehandle.  The argument can be a filename (SCALAR),
an ARRAY reference, or an ARRAY whose values must be valid arguments
for passing to IO::File->new.

  $qif->file( "myfile" );
 OR
  $qif->file( [ "myfile", "<:crlf" ] );
 OR
  $qif->file( "myfile", "<:crlf" );

For output files, be sure to open the file in write mode.

=head2 record_separator()

Returns the currently used record_separator.  This is used primarly in
situations where you open a QIF file with autodetect and then want to
write out a QIF file in the same format.

  my $in  = Finance::QIF->new( file => "input.qif", autodetect => 1 );
  my $out = Finance::QIF->new( file => ">write.qif",
                               record_separator => $in->record_separator );

=head2 open()

Open already specified file.

  $qif->open();

Open also supports the same arguments as L</file()>.

=head2 next()

For input files return the next record in the QIF file.

  my $record = $in->next();

Returns undef if no more records are available.

=head2 header()

For output files use to output the passed header for records that will
then be written with write.

  $out->header( "Type:Bank" );

See L<RECORD TYPES & VALUES> for list of possible record types that
can be passed.

=head2 write()

For output files use to output the passed record to the file.

  $out->write( $record );

=head2 reset()

Resets the filehandle so the records can be read again from the
beginning of the file.

  $qif->reset();

=head2 close()

Closes the open file.

  $qif->close();

=head1 EXAMPLES

Read an existing QIF file then write out to new QIF file.

  my $in  = Finance::QIF->new( file => "input.qif" );
  my $out = Finance::QIF->new( file => ">write.qif" );
  
  my $header = "";
  while ( my $record = $in->next() ) {
      if ( $header ne $record->{header} ) {
          $out->header( $record->{header} );
          $header = $record->{header};
      }
      $out->write($record);
  }
  
  $in->close();
  $out->close();

=head1 SEE ALSO

L<Carp>, L<IO::File>

Quicken Interchange Format (QIF) specification
L<http://web.intuit.com/support/quicken/docs/d_qif.html>

=head1 ACKNOWLEDGEMENTS

Simon Cozens C<simon@cpan.org>, Author of original Finance::QIF

Nathan McFarland C<nmcfarl@cpan.org>, Maintainer of original Finance::QIF

=head1 AUTHORS

Matthew McGillis E<lt>matthew@mcgillis.orgE<gt> L<http://www.mcgillis.org/>

Phil Lobbes E<lt>phil at perkpartners dot comE<gt>

Project maintained at L<http://sourceforge.net/projects/finance-qif>

=head1 COPYRIGHT

Copyright (C) 2006-2008 by Matthew McGillis.  All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
