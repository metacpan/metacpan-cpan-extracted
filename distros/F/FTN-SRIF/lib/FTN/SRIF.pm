package FTN::SRIF;

use warnings;
use strict;
use Carp qw( croak );

=head1 NAME

FTN::SRIF - Perl extension to parse an Fidonet/FTN Standard Request Information File.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 DESCRIPTION

Parsing an FTN SRIF (Standard Request Information File) received by an FTN mailer for what
is being requested by another mailer.  A common use of such files is for use by an external
request processor (ERP) for an Fidonet/FTN mailer.

To give an example of it being used:

    use FTN::SRIF qw(&parse_srif);
    ...
    $srif_info = FTN::SRIF::parse_srif($SRIF);
    ...
    $request_file = ${$srif_info}{'RequestList'};
    $response_file = ${$srif_info}{'ResponseList'};
    ...

=head1 EXPORT

The following is a list of functions that can be exported:  parse_srif().

=head1 FUNCTIONS

=head2 parse_srif

Syntax:	$srif_info = parse_srif($srif_file);

Parses the SRIF $srif_file and returns the information therein as a refererence
to a hash containing the SRIF information.  Note that the only keyword that is
allowed to have multiple values is the one for Akas, which is returned as a 
refererence to an array containing the Akas list.

The base set of keys to the hash, and also that required in the SRIF,
are as follows:

=over 4

=item Sysop

<Sysop_Name>
This is the name of the remote sysop

=item AKA

<Zone:Net/Node[.Point][@Domain]>
This is the main aka of the remote system in 4D or 5D notation. A zero
as point number may be ommited, the domain with "@" is optional.  This 
is included in a key, Akas, which is a reference to an array containing it.

=item Baud

<Current LINE rate>
This is the effective baud rate, not the fixed DTE rate

=item Time

<Time in minutes>
This is the time till next event which does not allow file requests.
Use -1 if there is no limit.

=item RequestList

<File of request list>
This is the filename of the file containing the request list. If
the request(s) is for files, it will be a listing of files being
requested.

=item ResponseList

<File of response list>
This is the filename of the response list. It must not be equal
to RequestList. One file per line, including drives/pathes to the
file. The first character defines the way the mailer should act after
sending that file:
    =   erase file if sent successfully
    +   do not erase the file after sent
    -   erase the file in any case after session

=item RemoteStatus

<PROTECTED or UNPROTECTED>
Defines whether the session is protected by password or not.

=item SystemStatus

<LISTED or UNLISTED>
Defines whether the remote system is listed in any current nodelist
of a system.

=back

The following are optional statements: these parameters are already known and defined,
but an ERP should run also without them:

=over 4

=item SessionProtocol

e.g. ZAP,ZMO,XMA.

=item AKA 

<Zone:Net/Node[.Point][@Domain]>
Additional AKAs. One AKA is required (see REQUIRED section, above)
They are included in a key, Akas, which is a reference to an array
containing them.

=item Site

<Site Info>
The site info as given e.g. in EMSI handshake

=item Location

<Location and/or ZIP>
The location info as given e.g. in EMSI handshake

=item Phone

<Phone Number>
The  phone number info as given e.g. in EMSI handshake

=item CallerID

<Phone Number>
The phone number as delivered by the PTT. This is
only possible in digital networks like ISDN.

=item Password

<Session password>
On protected sessions, the session password. If
no protected session, this parameter must be ommited!

=item DTE

<Current DTE rate>
The PC<->Modem speed (so call DTE rate)

=item PORT

<COM Port from 1 to 8>
The FOSSIL Communication Port. The Mailer should
leave the fossil "hot" for the Request Processor

=item Mailer

<Remote's mailer if EMSI>
The Mailer name as defined by FTC

=item MailerCode

<Remote's FTSC code>
The hex code of the remote mailer as defined by FTC

=item SerialNumber

<Remote's serial number if passed>
The remote mailer's serial number if transfered

=item Version

<Remote's version number if EMSI>
The remote mailer's version number if transfered

=item Revision

<remote's revision number if EMSI>
The remote mailer's revision number if transfered

=item SessionType

<may be EMSI, FTSC0001, WAZOO, JANUS, HYDRA or OTHER>
The session-type, this may be one of the known
session types or "OTHER" if not (yet) defined

=item OurAKA

<AKA which has been called for proper response>
If the mailer does AKA matching, the AKA of the
mailer being called

=item TRANX

<Tranx Line as 8 digit hex string>
The unix-style time stamp (hexadecimal notation
of seconds since 1.1.1980)

=back

=cut

sub parse_srif {

    my $srif_file = shift;

    my (%srif_info, $keyword, $value, @akas);
    
    open my $srif_handle, q{<}, "$srif_file" or croak ("Could not open SRIF file $srif_file.");
    
    while (<$srif_handle>) {
    
	($keyword, $value) = split(' ', $_, 2);

	if ($keyword ne "AKA") {

	    $srif_info{$keyword} = $value;	# add to SRIF hash

	} else {

	    push @akas, $value;			# add to akas array

	}

    }
    
    close ($srif_handle);

    # Add a reference to the Akas array to the srif_info hash.
    $srif_info{Akas} = \@akas;
    
    return \%srif_info;
}

=head2 get_request_list

Syntax: @request_list = get_request_list($request_file);

Reads the request file passed to it and returns a reference to an array of lines
containing the list of requests in that request file.

=cut

sub get_request_list {

    my $request_file = shift;

    open my $req_handle, q{<}, "$request_file"
            or croak ("Could not open Request File $request_file");

    my @request_list  = <$req_handle>;

    close($req_handle);

    return \@request_list;
}



=head1 AUTHOR

Robert James Clay, C<< <jame at rocasa.us> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ftn-srif at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FTN-SRIF>.
I will be notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::SRIF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FTN-SRIF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FTN-SRIF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FTN-SRIF>

=item * Search CPAN

L<http://search.cpan.org/dist/FTN-SRIF>

=back

=head1 SEE ALSO

For more information regarding SRIF, see L<http://www.ftsc.org/docs/fsc-0086.001>

See also L<ftn-srif>, for an example of usage of this module.

=head1 COPYRIGHT & LICENSE

Copyright 2001-2003,2010-2012 Robert James Clay, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of FTN::SRIF
