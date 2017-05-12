package FWS::V2::Net;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Net - Framework Sites version 2 network access methods

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;
    
    my $fws = FWS::V2->new();

    my $responseRef = $fws->HTTPRequest(url=>'http://www.thiswebsite.com');


=head1 DESCRIPTION

FWS version 2 core network methods 

=head1 METHODS

=head2 HTTPRequest

Post HTTP or HTTPS and return the result to a hash reference containing the results plus the parameters provided.

    my $responseRef = $fws->HTTPRequest(    
        url         => 'http://www.cpan.org'# only required parameter
        type        => 'get'                # default is get [get|post]
        user        => 'theUser'            # if needed for auth
        password    => 'thePass'            # if needed for auth 
        noRedirect  =>  1                   # do not follow redirects (defaults to 0)
        timeout     => '30'                 # fail if 30 seconds go by
        expire      =>  30                  # cache this for 30 minutes 
                                            # and return cache till it expires
        ip    =>'1.2.3.4'                   # show that I am from this ip
    );

    print $responseRef->{url} . "\n";                       # what was passed to HTTPRequest
    print $responseRef->{success} . "\n";                   # will be a 1 or a 0
    print $responseRef->{content} . "\n";                   # the content returned
    print $responseRef->{status} . "\n";                    # the status returned

=cut

sub HTTPRequest {
    my ( $self, %paramHash ) = @_;

    #
    # URL Hash caching if needed
    #
    use Digest::MD5  qw(md5_hex);
    my $URLHash = md5_hex( $paramHash{url} );

    #
    # check if we are cached, and if so lets return if we are still in time
    #
    if ( $paramHash{expire} ) {
        $paramHash{content} = $self->cacheValue( 'FWSHTTP_' . $URLHash );
        if ( $paramHash{content} ne '' ) { 
            $paramHash{success} = 1;
            return \%paramHash;
        }
    }
    
    #
    # lets use the LWP to get this done
    #
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new();

    #
    # disable redirect if passed
    #
    if ( $paramHash{noRedirect} )  { $ua->requests_redirectable( [] ) }

    #
    # set the agent if we need to
    #
    if ( $paramHash{agent} )       { $ua->agent( $paramHash{agent} ) }
    if ( $paramHash{timeout} )     { $ua->timeout( $paramHash{timeout} ) }

    #
    # lets get our request obj ready
    #
    my $req;

    #
    # force an IP if needed
    #
    if ( $paramHash{ip} )         { $ua->local_address( $paramHash{ip} ) }

    #
    # this is a post... but we get the stuff just like a get - but do the work
    #
    if ( $paramHash{type} =~ /post/i ) {
        my ( $postURL, $content ) = split( /\?/, $paramHash{url} );
        $req = HTTP::Request->new( POST => $postURL );
        $req->content_type( 'application/x-www-form-urlencoded' );
        $req->content( $content );
    }
    else { $req = HTTP::Request->new( GET => $paramHash{url} ) }

    #
    # if auth is set, lets set it!
    #
    if ( $paramHash{user} && $paramHash{password} ) { $req->authorization_basic( $paramHash{user}, $paramHash{password} ) }

    #
    # do the request and see what happens
    #
    my $response = $ua->request( $req );
    $paramHash{content} = $response->content;
    if ( $response->is_success ) { 
        $paramHash{success} = 1 ;
    
        #
        # because we have success lets cache this if we are supposed to
        #
        if ( $paramHash{expire} ) {
            $self->saveCache( key => 'FWSHTTP_' . $URLHash, expire => $paramHash{expire}, value => $paramHash{content} ); 
        }

    }
    else {
        $paramHash{success} = 0;
    }

    #
    # return the reference
    #
    return \%paramHash;
}



=head2 send

Send an email: Documentation needed.

=cut

sub send {
    my ( $self, %paramHash ) = @_;

    my @digitalAssets;
    if ( $paramHash{digitalAssets} ) {
        @digitalAssets = split( /\|/, $paramHash{digitalAssets} );
    }

    #
    # set the stuff if its not specified
    #
    $paramHash{characterSet}      ||= 'utf-8';
    $paramHash{transferEncoding}  ||= '7bit';
    $paramHash{mimeType}          ||= 'text/html';
    $paramHash{from}              ||= $self->{email};
    $paramHash{fromName}          ||= $self->{email};
    $paramHash{type}              ||= $self->{sendMethod};
    $paramHash{type}              ||= 'sendmail';
    $paramHash{fromQueue}         ||= 0;

    #
    # if this has a scheduled date, lets put it in the queue, instead of sending it
    #
    if ( ( ( $paramHash{scheduledDate} ) || ( $paramHash{type} && $paramHash{type} ne 'sendmail' ) ) && !$paramHash{fromQueue} ) {
        $self->saveQueue(%paramHash);
    }
    elsif ( !$paramHash{draft} ) {

        #
        # Switch anything that could have been URIed and changed to html tags that will need to be put back to regular chars.
        #
        $paramHash{from}        =~ s/(&#160;|;|\t|\n|,)/ /sg;
        $paramHash{to}          =~ s/(&#160;|;|\t|\n|,)/ /sg;

        #
        # only use the first one if there is more than one in a list.
        #
        my @mailFromSplit       = split( ' ', $paramHash{from} );
        $paramHash{from}        = $mailFromSplit[0];
        $paramHash{fromName}  ||= $paramHash{from};

        my $evalEmail;
                    
        #
        # convert the subject to utf-8 if it is
        #
        if ( $paramHash{characterSet} eq lc( 'utf-8' ) ) {
            $paramHash{subject} = '=?utf-8?B?' . encode_base64( $paramHash{subject}, '' ).'?=';
        }
 

        #
        # Split the emailTo's space delmited and process them one by one.
        #
        my @emailAccounts =  split( / /,$paramHash{to} );
        while ( @emailAccounts ) {


            #
            # if this didn't come into the queue, lets just put it in the history now so we know this went down
            #
            $self->saveQueueHistory( %paramHash );

            $paramHash{to} = shift @emailAccounts;

            #
            # For security reasons lets get rid of all the stuff that could potentialy be dangerous
            #
            $paramHash{to} =~ s/(\>|\<|\`|\/)//sg;

            if ( $self->{sendMethod} eq '' || $self->{sendMethod} eq 'sendmail' ) {

                my $boundary = "_-------------" . $self->createPassword(composition=>'1234567890',lowLength=>16,highLength=>16);

                #
                # Make sure this email is cool. otherwise we might get interneral server errors
                #
                if ( $paramHash{to} =~ /^[^@]+@[^@]+.[a-z]{2,}$/i ) {

                    use MIME::Base64;

                    open ( my $SENDMAIL, "|-", $self->{sendmailBin} . " -t" ) || $self->FWSLog( "Sendmail execute failed: " . $self->{sendmailBin} );

                    print $SENDMAIL "Reply-To: \"" . $paramHash{fromName} . "\" <" . $paramHash{from} . ">\n";
                    print $SENDMAIL "From: \"" . $paramHash{fromName} . "\" <" . $paramHash{from} . ">\n";
                    print $SENDMAIL "MIME-Version: 1.0\n";
                    print $SENDMAIL "To: " . $paramHash{to} . "\n";
                    print $SENDMAIL "Subject: " . $paramHash{subject} . "\n";
                    print $SENDMAIL "Content-Type: multipart/mixed;\n";
                    print $SENDMAIL "\tboundary=\"" . $boundary . "\"\n";
                    print $SENDMAIL "\nThis is a multi-part message in MIME format.\n";
                    print $SENDMAIL "\n--" . $boundary . "\n";
                    print $SENDMAIL "Content-Type: " . $paramHash{mimeType} . "; charset=" . $paramHash{characterSet} . "\n";
                    print $SENDMAIL "Content-Transfer-Encoding: " . $paramHash{transferEncoding} . "\n\n";
                    print $SENDMAIL $paramHash{body};

                    #
                    # Add the attachments
                    #
                    for my $fileName (@digitalAssets) {
                        if ( ( -e $fileName) && ( $fileName ) ) {
                            my $justFileName = $self->justFileName( $fileName );

                            print $SENDMAIL "\n--" . $boundary . "\n";
                            print $SENDMAIL "Content-Type: application/octet-stream;\n";
                            print $SENDMAIL "\tname=\"" . $justFileName . "\"\n";
                            print $SENDMAIL "Content-Transfer-Encoding: base64\n";
                            print $SENDMAIL "Content-Disposition: attachment\n";
                            print $SENDMAIL "\tfilename=\"" . $justFileName . "\"\n\n";
                            print $SENDMAIL $self->getEncodedBinary( $fileName );
                        }
                    }
                    print $SENDMAIL "\n--" . $boundary . "--\n\n";
                    close $SENDMAIL;
                }
            }

        }
    }
    return;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Net


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Net
