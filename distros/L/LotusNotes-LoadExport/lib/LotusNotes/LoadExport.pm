#
#  LoadExport.pm
#
#  Load records from a Lotus Notes database export.
#  Expects an array reference of fields to extract.
#  Returns an array reference of hashes where each hash represents a record
#
package LotusNotes::LoadExport;

our $VERSION = sprintf("%d.%02d", q'$Revision: 1.1 $' =~ /(\d+)\.(\d+)/);

use strict;
use warnings;
use Carp;
use IO::File;

my @data;

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;

    my $self = {};
    bless($self, $class);

    # Run initialisation code
    $self->_init(@_);

    return $self;
}


sub _init
{
    my $self = shift;

    # Handle the passed arguments
    my %args = (
        filename   => 'required',
        fieldnames => 'required array ref',
        @_
    );

    # Make sure we have the required arguments
    unless ($args{filename})
    {
        carp('E921 - No filename provided to LotusNotes::LoadExport->new(filename => the_export_filename, fieldnames => \@fields', "\n");
    }
    unless (-r $args{filename})
    {
        carp('E922 - filename ', $args{filename}, " does not exist or is not readable\n");
    }

    unless ($args{fieldnames})
    {
        carp('E923 - fieldnames array reference not provided to LotusNotes::LoadExport->new(filename => the_export_filename, fieldnames => \@fields', "\n");
    }
    unless (@{$args{fieldnames}})
    {
        carp("E925 - fieldnames array reference does not have any fieldnames!\n");
    }


    # Store the arguments we want
    $self->{filename}   = $args{filename};
    $self->{fieldnames} = $args{fieldnames};
}


sub load
{
    my $self = shift;

    my $fh = IO::File->new($self->{filename}, 'r');
    unless ($fh)
    {
        carp("E926 - Open of ", $self->{filename}, " failed:$!\n");
    }


    # Generate the regex to match the labels and extract the data
    my $regex_str;
    foreach my $label (@{ $self->{fieldnames} })
    {
        $regex_str .= q{^(} . $label . q{):\s+(.*)\s*$|};
    }
    # Remove the trailing pipe character
    $regex_str =~ s/\|$//;
    my $regex = qr{$regex_str};

    my %record;
    my $record_cnt = 0;

    while (<$fh>)
    {
        # This the the end of record flag
        if (/\f/)
        {
            push @data, { %record };
            $record_cnt++;
            %record = ();
            next;
        }

        chomp;
        if ((my @matched) = $_ =~ $regex)
        {
            my ($label, $value) = grep { $_ && $_ ne '' } @matched;
            $record{$label} = $value;
        }
    }

    # Handle the last record if not already added to the array
    if (keys %record)
    {
        push @data, { %record };
    }


    $fh->close();

    $self->{record_cnt} = $record_cnt;

    return \@data;
}


sub get_next
{
    my $self = shift;

    my $fh;
    my $file_position;
    if ($self->{get_next_fh})
    {
        $fh            = $self->{get_next_fh};
        $file_position = $self->{get_next_file_position} || 0;
        $fh->setpos($file_position);

        $self->{get_next_record_cnt} = 0;
    }
    else
    {
        $fh = IO::File->new($self->{filename}, 'r');
        unless ($fh)
        {
            carp("E926 - Open of ", $self->{filename}, " failed:$!\n");
        }
        $file_position = 0;

        # Sore for later use
        $self->{get_next_fh}            = $fh;
        $self->{get_next_file_position} = $file_position;
    }


    # Generate the regex to match the labels and extract the data
    my $regex;
    if ($self->{get_next_regex})
    {
        $regex = $self->{get_next_regex};
    }
    else
    {
        my $regex_str;
        foreach my $label (@{ $self->{fieldnames} })
        {
            $regex_str .= q{^(} . $label . q{):\s+(.*)\s*$|};
        }
        # Remove the trailing pipe character
        $regex_str =~ s/\|$//;
        $regex = qr{$regex_str};

        # Sore for later use
        $self->{get_next_regex} = $regex;
    }

    my %record;
    while (<$fh>)
    {
        # This the the end of record flag
        if (/\f/)
        {
            $self->{get_next_record_cnt}++;
            $self->{get_next_file_position} = $fh->getpos();
            return \%record;
        }

        chomp;
        if ((my @matched) = $_ =~ $regex)
        {
            my ($label, $value) = grep { $_ && $_ ne '' } @matched;
            $record{$label} = $value;
        }
    }

    # Handle the last record if not already added to the array
    if (keys %record)
    {
        $self->{get_next_record_cnt}++;
        return \%record;
    }

    $fh->close();
    return;
}


#####################################################################
# DO NOT REMOVE THE FOLLOWING LINE, IT IS NEEDED TO LOAD THIS LIBRARY
1;


__END__

=head1 NAME

LotusNotes::LoadExport - A module to automate the processing of LotusNotes text export files

=head1 SYNOPSIS

 #! perl -w
 use strict;
 use LotusNotes::LoadExport;
 use Data::Dumper;
 $Data::Dumper::Indent = 1;

 my @labels = (qw{ VersionLic AppName Version UserID WorkstationID });
 # Here application_license.txt is a LotusNotes export (see DESCRIPTION below)
 my $ln     = LotusNotes::LoadExport->new(filename => 'application_license.txt', fieldnames => \@labels);

 # Get ALL the data (you may not want to do this - see next below)
 my $data   = $ln->load();
 print Dumper($data), "\n";
 exit;

 # Iterator based data access
 while (my $data = $ln->get_next())
 {
     # Do something with each record
     print Dumper($data), "\n";
 }


 Example output:

 $VAR1 = [
  {
    'AppName' => 'ABC Flowcharter',
    'Version' => '7.0',
    'WorkstationID' => 'PC-1234',
    'UserID' => 'tom.smith',
    'VersionLic' => '7.0'
  },
  {
    'AppName' => 'MS-Access',
    'Version' => '2007',
    'WorkstationID' => 'PC-3043',
    'UserID' => 'sally.jones'
  }
 ];

=head1 DESCRIPTION

This module is designed to read text files generated from a LotusNotes 'Structured Text' export.
Normally the 'Word wrap within documents' entry (as part of the export) is set to 999
characters (as many 9's as you can enter in the field).  The 'Separator between documents' is
assumed to be linefeed (the export default).

Load records from a Lotus Notes database export.

Expects an array reference of fields to extract.

Returns an array reference of hashes where each hash represents a record

=head1 METHODS

=head2 new

Create the LotusNotes::LoadExport object.  There are two reqired named arguments: filename and fieldnames.
The filename is the name of the 'Lotus Notes' export file.  fieldnames is an array reference to a list of
the labels from the 'Lotus Notes' export file that you are interested in.  See synopsis above.

=head2 get_next

The method get_next is an iterator, returning the next record until all records are processed at
which point undef is returned.  This is more efficent then the load() method

=head2 load

This method returns all records in one hit, which has the disadvantage of allocating more memory
compared with the iterator get_next()


=head1 KNOWN ISSUES

Currently multi line records are not supported - you only get the first line.

Calling load() returns ALL the data for the fields specified, using get_next() an
iterator method may be a better alternative


=head1 SAMPLE DATA

### Below is a typical export record (not the \f as the record separator)
RefNo:  2
AppName:  ABC Flowcharter
Version:  7.0
AppNameLic:  ABC Flowcharter
VersionLic:  7.0
UserGroup:  Tar Pit
UserName:  Gavin Sticky
UserID:  g.sticky
WorkstationID:  BB10202
LicenceProof:  Purchase Order
PONumber:  AXS0311062
LastEditor:  Road Runner
TimesModified:  0
PastAuthors:  Road Runner
PastEditDates:  29/01/99 16:30:58
CreatedBy:  Road Runner
CreatedDate:  29/01/1999 05:29:49 PM
Business:  Acme
Ownership:  Head Honcho
$UpdatedBy:  CN=Road Runner/OU=AU/OU=ITS/O=Acme,CN=Acme Template Designer/O=Acme
$Revisions:  29/01/1999 05:29:49 PM,29/01/1999 05:30:58 PM,11/03/1999 02:50:25 PM


RefNo:  7
AppName:  ABC Flowcharter
Version:  7.0
AppNameLic:  ABC Flowcharter
VersionLic:  7.0
UserGroup:  Acme Glue
UserName:  Marcus Scrooge
UserID:  m.scrooge
WorkstationID:  BB38484
LicenceProof:  Purchase Order
PONumber:  AXS0311062
LastEditor:  Road Runner
TimesModified:  0
PastAuthors:  Road Runner
PastEditDates:  29/01/99 16:30:58
CreatedBy:  Road Runner
CreatedDate:  29/01/1999 05:29:50 PM
Business:  Acme
Ownership:  Head Honcho
$UpdatedBy:  CN=Road Runner/OU=AU/OU=ITS/O=Acme,CN=Acme Template Designer/O=Acme
$Revisions:  29/01/1999 05:29:49 PM,29/01/1999 05:30:58 PM,11/03/1999 02:50:25 PM


RefNo:  8
AppName:  ABC Flowcharter
Version:  7.0
AppNameLic:  ABC Flowcharter
VersionLic:  7.0
UserGroup:  Acme Glue
UserName:  Mark Tube
UserID:  m.tube
WorkstationID:  BB93932
LicenceProof:  Purchase Order
PONumber:  AXS0311062
LastEditor:  Road Runner
TimesModified:  0
PastAuthors:  Road Runner
PastEditDates:  29/01/99 16:30:58
CreatedBy:  Road Runner
CreatedDate:  29/01/1999 05:29:50 PM
Business:  Acme
Ownership:  Head Honcho
$UpdatedBy:  CN=Road Runner/OU=AU/OU=ITS/O=Acme,CN=Acme Template Designer/O=Acme
$Revisions:  29/01/1999 05:29:49 PM,29/01/1999 05:30:58 PM,11/03/1999 02:50:25 PM



=head1 CVS ID

 $Id: LoadExport.pm,v 1.1 2009/06/20 08:22:53 Greg Exp $

=head1 CVS LOG

 $Log: LoadExport.pm,v $
 Revision 1.1  2009/06/20 08:22:53  Greg
 - Initial development

 Revision 1.2  2008/12/15 05:55:24  gxg6
 - Change to allow handling of last record without a \f to finish


=head1 AUTHOR

 Greg George, IT Technology Solutions P/L,
 Mobile: 0404-892-159, Email: gng@cpan.org


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LotusNotes::LoadExport


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LotusNotes-LoadExport>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LotusNotes-LoadExport>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LotusNotes-LoadExport>

=item * Search CPAN

L<http://search.cpan.org/dist/LotusNotes-LoadExport/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Greg George, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
=cut

#---< End of File >---#