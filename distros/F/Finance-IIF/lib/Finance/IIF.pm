package Finance::IIF;

use 5.006;
use strict;
use warnings;
use Carp;
use IO::File;

our $VERSION = '0.20.01';
$VERSION = eval $VERSION;

sub new {
    my $class = shift;
    my %opt   = @_;
    my $self  = {};

    $self->{debug}           = $opt{debug}           || 0;
    $self->{autodetect}      = $opt{autodetect}      || 0;
    $self->{field_separator} = $opt{field_separator} || "\t";

    bless( $self, $class );

    if ( $opt{record_separator} ) {
        $self->record_separator( $opt{record_separator} );
    }

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
    if (@_) {
        $self->{record_separator} = $_[0] if ( $_[0] );
    }
    return $self->{record_separator} || $/;
}

sub _filehandle {
    my $self = shift;
    if (@_) {
        my @args = @_;
        $self->{_filehandle} = IO::File->new(@args)
          or croak("Failed to open file '$args[0]': $!");
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
                if ( $buffer eq "\r\n" ) {
                    $self->record_separator("\r\n");
                }
                elsif ( $buffer =~ /\n$/ ) {
                    $self->record_separator("\n");
                }
                elsif ( $buffer =~ /\r$/ ) {
                    $self->record_separator("\r");
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
    if ( $self->_filehandle->eof ) {
        return undef;
    }
    while ( !$self->_filehandle->eof && $continue ) {
        my $line = $self->_getline;
        next if ( $line =~ /^\s*$/ );
        my @data = $self->_parseline($line);

        if ( $self->{debug} > 1 ) {
            warn("_getline:   line($line)\n");
            warn( "_parseline: data[" . scalar(@data) . "](@data)\n" );
        }

        if ( $data[0] =~ /^!(.*)$/ ) {
            delete( $self->{headerfields} );
            shift(@data);
            $self->{header}       = $1;
            $self->{headerfields} = \@data;
        }
        elsif ( $data[0] eq $self->{header} ) {
            $continue = 0;
            $object{header} = shift(@data);
            my $num_hdr = scalar( @{ $self->{headerfields} } );
            my $num_dat = scalar(@data);

            # have seen IIF timer data where last column (USEID) was
            # missing but QuickBooks imports the data without error
            if ( $num_dat < ( $num_hdr - 1 ) ) {
                no warnings 'uninitialized';
                $self->_warning( "parse error: found $num_dat fields but"
                      . " expected $num_hdr." );
                warn(
                    "error info: [header,data] "
                      . join(
                        ' ',
                        map( "$_" . '['
                              . $self->{headerfields}->[$_] . ','
                              . $data[$_] . ']',
                            0 .. ( $num_hdr - 1 ) )
                      )
                );
            }
            else {
                for ( my $i = 0 ; $i <= $#{ $self->{headerfields} } ; $i++ ) {
                    my $val = defined( $data[$i] ) ? $data[$i] : "";
                    $object{ $self->{headerfields}[$i] } = $val;
                }
            }
        }
        else {
            $self->_warning("unable to parse line '$_'");
        }
    }

    if ($continue) {
        return undef;
    }
    else {
        return \%object;
    }
}

sub _parseline {
    my $self = shift;
    my $line = shift;
    my $sep  = $self->{field_separator} || "\t";
    my @data;
    while ( defined $line ) {
        if ( $line =~ /^"(.*?)(?:[^\\]["])[$sep](.*)/ ) {
            warn("parse1: data($1) line($2)\n") if ( $self->{debug} > 2 );
            $line = $2;
            push( @data, $1 );
        }
        elsif ( $line =~ /^([^$sep]+)[$sep](.*)/ ) {
            warn("parse2: data($1) line($2)\n") if ( $self->{debug} > 2 );
            $line = $2;
            push( @data, $1 );
        }
        elsif ( $line =~ /^[$sep](.*)/ ) {
            warn("parse3: data() line($1)\n") if ( $self->{debug} > 2 );
            $line = $1;
            push( @data, "" );
        }
        elsif ( $line =~ /^"(.*?)(?:[^\\]["])$/ ) {
            warn("parse4: data($1) line()\n") if ( $self->{debug} > 2 );
            $line = undef;
            push( @data, $1 );
        }
        elsif ( $line =~ /^(.+)$/ ) {
            warn("parse5: data($1) line()\n") if ( $self->{debug} > 2 );
            $line = undef;
            push( @data, $1 );
        }
        else {
            warn("parse6: data() line($line)\n") if ( $self->{debug} > 2 );
            $line = undef;
            push( @data, "" );
        }
    }
    return @data;
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

sub reset {
    my $self = shift;
    $self->_filehandle->seek( 0, 0 );
}

sub close {
    my $self = shift;
    $self->_filehandle->close;
}

1;

__END__

=head1 NAME

Finance::IIF - Parse and create IIF files for QuickBooks

=head1 SYNOPSIS

  use Finance::IIF;
  
  my $iif = Finance::IIF->new( file => "test.iif" );
  
  while ( my $record = $iif->next ) {
      print( "Header: ", $record->{header}, "\n" );
      foreach my $key ( keys %{$record} ) {
          print( "     ", $key, ": ", $record->{$key}, "\n" );
      }
  }

=head1 DESCRIPTION

Finance::IIF is a module for working with IIF files for QuickBooks in
Perl.  This module reads IIF data records from a file passing each
successive record to the caller for processing.

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

 TRNS (QuickBooks can't export but does import this format)
             TRNS                                    SPLT
 CODE         IIF          QIF           CODE         IIF          QIF
          TRNSID                                    SPLID
          TRNSTYPE                                  TRNSTYPE
          TRANSTYPE                                 TRANSTYPE
 date     DATE             D                        DATE
          ACCNT                          category   ACCNT          S
 payee    NAME             P                        NAME
 amount   ACCOUNT          T                        CLASS
 number   DOCNUM           N             amount     AMOUNT         $
 memo     MEMO             M                        DOCNUM
 status   CLEAR            C             memo       MEMO           E
          TOPRINT                                   CLEAR
          NAMEISTAXABLE                             QNTY
          NAMEIS TAXABLE                            PRICE
 address  ADDR1            A                        REIMBEXP
 address  ADDR2            A                        INVITEM
 address  ADDR3            A                        SERVICEDATE
 address  ADDR4            A                        TAXABLE
 address  ADDR5            A                        PAYMETH
          DUEDATE                                   OTHER2
          TERMS                                     VALADJ
          SHIPVIA                                   YEARTODATE
          PAID                                      OTHER3
          SHIPDATE
          OTHER1
          YEARTODATE
          REP
          FOB
          PONUM
          INVTITLE
          INVMEMO
          SADDR1
          SADDR2
 category                  L                 

QuickBooks doesn't support investment accounts Quicken does.

 HDR (Generated in every export)
 PROD
 VER
 REL
 IIFVER
 DATE
 TIME

In QuickBooks accounts and categories are the same thing accounts.  In
Quicken they are separate accounts and categories.

 ACCNT (Chart of Accounts)
 CODE         IIF          QIF Account   QIF Category
 name         NAME         N             N
              REFNUM
              TIMESTAMP
 type         ACCNTTYPE    T
 balance      OBAMOUNT     B
 description  DESC         D             D
              ACCNUM
              SCD
              EXTRA
 limit                     L
 tax                       X             T
 note                      A
 expense                                 E
 income                                  I
 schedule                                R

Customer, Vendor, Employee, Other Name are all possible payee's in
QuickBooks in Quicken you don't really have a notion of payee.

 CUST (Customer List)
 NAME
 REFNUM
 TIMESTAMP
 BADDR1
 BADDR2
 BADDR3
 BADDR4
 BADDR5
 SADDR1
 SADDR2
 SADDR3
 SADDR4
 SADDR5
 PHONE1
 PHONE2
 FAXNUM
 CONT1
 CONT2
 CTYPE
 TERMS
 TAXABLE
 LIMIT
 RESALENUM
 REP
 TAXITEM
 NOTEPAD
 SALUTATION
 COMPANYNAME
 FIRSTNAME
 MIDINIT
 LASTNAME
 CUSTFLD1
 CUSTFLD2
 CUSTFLD3
 CUSTFLD4
 CUSTFLD5
 CUSTFLD6
 CUSTFLD7
 CUSTFLD8
 CUSTFLD9
 CUSTFLD10
 CUSTFLD11
 CUSTFLD12
 CUSTFLD13
 CUSTFLD14
 CUSTFLD15
 
 VEND (Vendor List)
 NAME
 REFNUM
 TIMESTAMP
 PRINTAS
 ADDR1
 ADDR2
 ADDR3
 ADDR4
 ADDR5
 VTYPE
 CONT1
 CONT2
 PHONE1
 PHONE2
 FAXNUM
 NOTE
 TAXID
 LIMIT
 TERMS
 NOTEPAD
 SALUTATION
 COMPANYNAME
 FIRSTNAME
 MIDINIT
 LASTNAME
 CUSTFLD1
 CUSTFLD2
 CUSTFLD3
 CUSTFLD4
 CUSTFLD5
 CUSTFLD6
 CUSTFLD7
 CUSTFLD8
 CUSTFLD9
 CUSTFLD10
 CUSTFLD11
 CUSTFLD12
 CUSTFLD13
 CUSTFLD14
 CUSTFLD15
 1099
 
 EMP (Employee List)
 EMP             QBP          CUSTOMPI      HOURLYPI     LOCALPI
 NAME            EMPLOYEE     PAYITEM       PAYITEM      PAYITEM
 REFNUM          NAME         AMOUNT        AMOUNT       AMOUNT
 TIMESTAMP       REFNUM       LIMIT         LIMIT        LIMIT
 INIT            TIMESTAMP                               LOCALITY
 ADDR1           SALARY                                  W2LOCNAME
 ADDR2           PAYPERIOD
 ADDR3           CLAS
 ADDR4           NUMCUSTOM
 ADDR5           NUMHOURLY
 SSNO            SICKACCRL
 PHONE1          SICKRATE
 PHONE2          SICKACCRD
 NOTEPAD         SICKUSED
 FIRSTNAME       VACACCRL
 MIDINIT         VACRATE
 LASTNAME        VACACCRD
 SALUTATION      VACUSED
 CUSTFLD1        HIREDATE
 CUSTFLD2        RELEASEDATE
 CUSTFLD3        FEDSTATUS
 CUSTFLD4        FEDALLOW
 CUSTFLD5        FEDEXTRA
 CUSTFLD6        STATESWH
 CUSTFLD7        STATESDI
 CUSTFLD8        STATESUI
 CUSTFLD9        PAYITEMSWH
 CUSTFLD10       PAYITEMSDI
 CUSTFLD11       PAYITEMSUI
 CUSTFLD12       STATESTATUS
 CUSTFLD13       STATEALLOW
 CUSTFLD14       STATEEXTRA
 CUSTFLD15       STATEMISC
                 FEDTAX
                 SSEC
                 MCARE
                 FUTA
                 TIMECARD
                 CARRYSICK
                 CARRYVAC
                 SICKPERPAY
                 VACPERPAY
 
 OTHERNAME (Other Name List)
 NAME
 REFNUM
 TIMESTAMP
 BADDR1
 BADDR2
 BADDR3
 BADDR4
 BADDR5
 PHONE1
 PHONE2
 FAXNUM
 CONT1
 NOTEPAD
 SALUTATION
 COMPANYNAME
 FIRSTNAME
 MIDINIT
 LASTNAME

 CTYPE (Customer Type List)
 NAME
 REFNUM
 TIMESTAMP

 VTYPE (Vendor Type List)
 NAME
 REFNUM
 TIMESTAMP

 CLASS (Class List)
 CODE         IIF          QIF
 name         NAME         N
              REFNUM
              TIMESTAMP
 description               D

 INVITEM (Item List)
 INVITEM                INVITEM
 NAME                   NAME
 REFNUM                 REFNUM
 TIMESTAMP              TIMESTAMP
 INVITEMTYPE            INVITEMTYPE
 DESC                   DESC
 PURCHASE               TOPRINT
 DESC                   EXTRA
 ACCNT                  QNTY
 ASSETACCNT             CUSTFLD1
 COGSACCNT              CUSTFLD2
 PRICE                  CUSTFLD3
 COST                   CUSTFLD4
 TAXABLE                CUSTFLD5
 PAYMETH
 TAXVEND
 TAXDIST
 PREFVEND
 REORDERPOINT
 EXTRA
 CUSTFLD1
 CUSTFLD2
 CUSTFLD3
 CUSTFLD4
 CUSTFLD5
 DEP_TYPE
 ISPASSEDTHRU

 TODO (To Do Notes)
 REFNUM
 ISDONE
 DATE
 DESC

 TERMS (Payment Terms List)
 NAME
 REFNUM
 TIMESTAMP
 DUEDAYS
 MINDAYS
 DISCPER
 DISCDAYS
 TERMSTYPE

 PAYMETH (Payment Method List)
 NAME
 REFNUM
 TIMESTAMP

 SHIPMETH (Shipping Method List)
 NAME
 REFNUM
 TIMESTAMP

 INVMEMO (Customer Message List)
 NAME
 REFNUM
 TIMESTAMP

 BUD (Budgets)
 Code          IIF           QIF
 name          ACCNT         N
               PERIOD
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
 budget        AMOUNT        B
               STARTDATE
               CLASS
               CUSTOMER
 description                 D
 expense                     E
 income                      I
 tax                         T
 schedule                    R

=head1 METHODS

=head2 new()

Creates a new instance of Finance::IIF.  Supports the following
initializing values.

  my $iif = Finance::IIF->new( file => "myfile", debug => 1 );

If the file is specified it will be opened on new.

=over

=item file

Specifies file to use for processing.  See L<file()|/file__> for details.

  my $in = Finance::IIF->new( file => "myfile" );
OR
  my $in = Finance::IIF->new( file => [ "myfile", "<:crlf" ] );

=item record_separator

Can be used to redefine the IIF record separator.  Default is $/.

  my $in = Finance::IIF->new( record_separator => "\n" );

Note: For MacOS X it may be necessary to change this to "\r".  See
L</autodetect> for another option.

=item autodetect

Enable auto detection of the record separator based on the file
contents.  Default is "0".

  my $in = Finance::IIF->new( autodetect => 1 );

Perl uses $/ to define line separators for text files.  Perl sets this
value according to the OS perl is running on:

  Windows="\r\n"
  Mac="\r"
  Unix="\n"

In many cases you may find yourself with text files that do not match
the OS.  In these cases Finance::IIF by default will not process that
IIF file correctly. This feature is an attempt to help with the most
common cases of having the wrong text file for the OS Finance::IIF is
running on.

This feature depends on being able to seek to the end of the file and
reading the last 2 characters to determine the proper separator. If a
seek can not be performed or the last 2 characters are not a proper
separator the record_separator will default to $/ or the value passed
in. If a valid record_separator is found then it will be set according
to what was in the file.

=item debug

Can be used to output debug information.  Default is "0".

  my $iif = Finance::IIF->new( debug => 1 );

=back

=head2 file()

Specify file name and optionally additional parameters that will be
used to obtain a filehandle.  The argument can be a filename (SCALAR)
an ARRAY reference or an ARRAY whose values must be valid arguments
for passing to IO::File->new.

  $iif->file("myfile");
 OR
  $iif->file( [ "myfile", "<:crlf" ] );
 OR
  $iif->file( "myfile", "<:crlf" );

=head2 record_separator()

Returns the currently used record_separator.  This is used primarly in
situations where you open a IIF file with autodetect and then want to
write out a IIF file in the same format.

  my $iif = Finance::IIF->new( file => "input.iif", autodetect => 1 );
  my $rs  = $iif->record_separator;

=head2 open()

Open already specified file.

  $iif->open();

Open also supports the same arguments as L<file()|/file__>.

  $iif->open("myfile");

=head2 next()

For input files return the next record in the IIF file.

  my $record = $in->next();

Returns undef if no more records are available.

=head2 reset()

Resets the filehandle so the records can be read again from the
beginning of the file.

  $iif->reset();

=head2 close()

Closes the open file.

  $iif->close();

=head1 TODO

=over 4

=item *

Examples

=item *

Add support for writing IIF files

=item *

Test cases for IIF parsing

=back

=head1 SEE ALSO

L<Carp>, L<IO::File>

=head1 AUTHORS

Matthew McGillis E<lt>matthew@mcgillis.orgE<gt> L<http://www.mcgillis.org/>

Phil Lobbes E<lt>phil at perkpartners dot comE<gt>

Project maintaned at L<http://sourceforge.net/projects/finance-iif>

=head1 COPYRIGHT

Copyright (C) 2006 by Matthew McGillis and Phil Lobbes.  All rights
reserved.  This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
