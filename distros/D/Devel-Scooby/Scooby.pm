package Devel::Scooby;

# Scooby.pm - a relocation mechanism for use with the Mobile::Location
#             and Mobile::Executive modules.
#
# Author: Paul Barry, paul.barry@itcarlow.ie
# Create: October 2002.
# Update: April/May 2003 - Version 4.x series.
#
# Notes:  This code takes advantage of the CPAN modules
#         PadWalker and Storable (with a little help from the
#         Data::Dumper module when it comes to Objects).  The Crypt::RSA
#         module provides PK+/PK- support.
#
#         Version 1.x supported relocating simple Perl code.
#         Version 2.x supported relocating SCALARs, ARRAYs, and
#             HASHes and references to same.
#         Version 3.x supported relocating Perl OO objects.  Note 
#             that this will only occur after Scooby has contacted
#             the receiving Location and determined that any 
#             required classes exist on the remote Perl system.
#         Version 4.x supports authenticated relocation using Crypt::RSA, 
#             as well as encryption of the mobile agent source code.
#             

our $VERSION = 4.12;

# The "constant.pm" module does not want to work with the debugger mechanism, 
# so "our" variables are used instead.  

our $SCOOBY_CONFIG_FILE   = "$ENV{'HOME'}/.scoobyrc";

our $SIGNATURE_DELIMITER  = "\n--end-sig--\n";

our $ALARM_WAIT           = 30;
our $LOCALHOST            = '127.0.0.1';

our $RESPONDER_PPORT      = '30001';
our $REGISTER_PPORT       = '30002';

our $MAX_RECV_LEN         = 65536;

our $TRUE                 = 1;
our $FALSE                = 0;

##########################################################################
# The Scooby Debugger starts here.
##########################################################################

{
    package DB;  # Remember: Scooby is a DEBUGGER.
        
    our ( $package, $file, $line );  # XXXXX: Note these are 'global'.

    sub DB {

        # Called for every line in the program that can be breakpointed.
        #
        # IN:  nothing.
        #
        # OUT: nothing.

        ( $package, $file, $line ) = caller;  # XXXXX: Writing to globals!
    }

    sub sub {

        # Called before every subroutine call in the program.
        #
        # IN:  nothing.  Although "$sub" is set to the name of the
        #      subroutine that was just called (thanks to Perl's debugging
        #      mechanisms).
        #
        # OUT: nothing.

        if ( $sub =~ /^Mobile::Executive::relocate$/ )
        {
            use Socket;                      # Functional interface to Socket API.
            use Storable qw( freeze thaw );  # Provides a persistence mechanism.
            use PadWalker qw( peek_my );     # Provides access to all lexically scoped variables.

            use Crypt::RSA;                  # Provides authentication and 
                                             # encryption services.

            my $remote = shift; 

            # Next two lines turn the IP name into a dotted-decimal.

            my $tmp = gethostbyname( $remote ) or inet_aton( $remote );
            $remote = inet_ntoa( $tmp );

            my $remote_port = shift;

            my $filename_mem = $file;
            my $linenum_mem = ( $line + 1 );

            my $stringified;
            
            # We first determine the list of lexicals in the caller.

            my $them = peek_my( 0 );  

            # Then we turn the list of lexicals into "Storable" output.

            my $str = freeze( \%{ $them } );

            # Then we turn the thawed output back into Perl code.  This 
            # code is referred to as the "lexical init" code.

            $stringified = _storable_decode( 
                                                $remote,
                                                $remote_port,
                                                thaw( $str ) 
                                           );

            # Determine the KEYSERVER address from the .scoobyrc file.

            open KEYFILE, "$SCOOBY_CONFIG_FILE"
                or die "Scooby: unable to access ~/.scoobyrc. Does it exist?\n";

            my $keyline = <KEYFILE>;

            close KEYFILE;

            # Note: format of 'rc' file is very strict.  No spaces!

            $keyline =~ /^KEYSERVER=(.+)/;

            my $key_server = $1;

            # Now that we know the address of the key server, we can 
            # request the PK+ of the key server and the next location.

            _get_store_pkplus( $key_server, $LOCALHOST, $RESPONDER_PPORT );
            _get_store_pkplus( $key_server, $remote, $remote_port );

            open RELOCATE_FILE, "$Mobile::Executive::absolute_fn" 
                or die "Scooby: Unable to open file for relocation: $!.\n";

            # Dump the current state of the agent to a temporary disk-file
            # so that we can encrypt it with the next Location's PK+.

            my $tmp_filename = "$0.$$.temporary.tmp";

            open TMP_FILE, ">$tmp_filename"
                or die "Scooby: could not write to temporary encryption file: $!.\n";

            my $line_count = 0;

            # Write the agent's source code one line at a time to the temporary file.

            while ( my $line2send = <RELOCATE_FILE> )
            {
                ++$line_count;
                print TMP_FILE $line2send;

                # Check to see if we need to insert the "lexical init" code.

                if ( $line_count == ($linenum_mem-1) )
                {
                    print TMP_FILE $stringified if defined( $stringified );
                }
            }

            close RELOCATE_FILE;

            close TMP_FILE;

            # The agent source code (which has mutated) is now in "$tmp_filename".

            open TOENCRYPT_FILE, "$tmp_filename"
                or die "Scooby: temporary encryption file could not be opened: $!.\n";

            my @entire_toencrypt = <TOENCRYPT_FILE>;

            close TOENCRYPT_FILE;

            # We are now done with the temporary file, so we can remove it from 
            # the local storage.

            unlink $tmp_filename;

            my $message = "@entire_toencrypt\n";
            my $public_key_filename = "$remote.$remote_port.public";

            my $public_key = new Crypt::RSA::Key::Public( 
                                     Filename => $public_key_filename 
                                 );

            my $rsa = new Crypt::RSA;

            # Encrypt the mutated agent using the PK+ of the next Location.

            my $cyphertext = $rsa->encrypt(
                                 Message   => $message,
                                 Key       => $public_key,
                                 Armour    => $TRUE
                             ) or die $rsa->errstr, "\n";

            # Use the PK- of this Mobile::Executive invocation to 
            # sign the encrypted mobile agent.

            my $cypher_signature = $rsa->sign(
                                       Message  => $cyphertext,
                                       Key      => $Mobile::Executive::private_key,
                                       Armour   => $TRUE
                                   ) or die $rsa->errstr, "\n";

            # Networking code to send agent to the server starts here.

            my $trans_serv  = getprotobyname( 'tcp' );
            my $remote_host = gethostbyname( $remote ) or inet_aton( $remote );
            my $destination = sockaddr_in( $remote_port, $remote_host );

            socket( TCP_SOCK, PF_INET, SOCK_STREAM, $trans_serv ) 
                or die "Scooby: socket creation failed: $!.\n";

            connect( TCP_SOCK, $destination )
                or die "Scooby: connect to remote system failed: $!.\n";

            # Turn on auto-flushing.

            my $previous = select TCP_SOCK;
            $| = 1;
            select $previous;

            # Send the filename of the agent to the remote Location. 

            print TCP_SOCK $filename_mem . "\n";

            # Send the line# for the next executable line to the Location. 

            print TCP_SOCK $linenum_mem . "\n";

            # We need to work out the port that this client is using "locally".
            # The Location will use this protocol port number to query the
            # keyserver for the just-about-to-be-sent public key.

            my ( $local_pport, $local_ip ) = sockaddr_in( getsockname( TCP_SOCK ) );

            # Prior to sending the signature and cyphertext to the next
            # Location, we need to update the keyserver with the appropriate
            # PK+ so that the next Location can verify the signature.  We 
            # write the PK+ to a disk-file, then read it back in, as this is 
            # the format that the keyserver expects to receive it in.

            $Mobile::Executive::public_key->write(
                Filename => "$0.$$.$local_pport.public"
            );

            open LOCAL_KEYFILE, "$0.$$.$local_pport.public"
                or die "Scooby: the local public key file does not exist: $!.\n";

            my @entire_local_file = <LOCAL_KEYFILE>;

            close LOCAL_KEYFILE;

            # We have no further need for the public key file, so remove it.

            unlink "$0.$$.$local_pport.public";

            # Send the "local" protocol port number and PK+ to the keyserver.

            my $keysock_obj = IO::Socket::INET->new( PeerAddr  => $key_server,
                                                     PeerPort  => $REGISTER_PPORT,
                                                     Proto     => 'tcp' );

            if ( !defined( $keysock_obj ) )
            {
                die "Scooby: could not create socket object to key server: $!.\n";
            }

            print $keysock_obj "$local_pport\n";

            print $keysock_obj @entire_local_file;

            $keysock_obj->close;

            # ACK that the just inserted PK+ is in the keyserver.

            _wait_for_pkplus_confirm( $key_server, inet_ntoa( $local_ip ), $local_pport );

            # Send the signature to the next Location.

            print TCP_SOCK "$cypher_signature" . $SIGNATURE_DELIMITER;

            # Send the encoded cyphertext to the next Location.

            print TCP_SOCK $cyphertext;

            close TCP_SOCK
                or warn "Scooby: close failed: $!.\n";

            exit;  # We are done on this Location, having just relocated
                   # to another.  This is why we "exit" at this time.
        }

        # Call the original subroutine with parameters (if there was any).
        # We only get to here if there's no request for relocation.

        if ( defined @_ ) 
        { 
            &$sub( @_ ); 
        } 
        else 
        { 
            &$sub; 
        }
    }

##########################################################################
# Scooby support routines follow.
##########################################################################

    sub _wait_for_pkplus_confirm {

        # Contacts the key server and requests the PK+ for a specified
        # IP address/port combo.  Keeps asking for the PK+ until such time as the PK+
        # is ACKed by the key server.
        #
        # IN:  The IP name/address of the key server.
        #      The IP address to use when requesting a PK+ from the key server.
        #      The protocol port to use when requesting a PK+.
        #
        # OUT: nothing.
    
        use IO::Socket;  # Provides OO interface to Socket API.
    
        my $server = shift;
        my $lookup = shift;
        my $port   = shift;
  
        my $sig_ack = $FALSE;

        while ( $sig_ack == $FALSE )
        {
            # Opens a socket object to the keyserver.

            my $key_sock = IO::Socket::INET->new( 
                                                    PeerAddr => $server,
                                                    PeerPort => $RESPONDER_PPORT,
                                                    Proto    => 'tcp'
                                                );

            if ( !defined( $key_sock ) )
            {
                die "Scooby: could not create key server socket object: $!.\n";
            }
    
            # Send the lookup details to the keyserver.

            print $key_sock "$lookup\n";
            print $key_sock $port;
        
            # We are done writing, so half close the socket.

            $key_sock->shutdown( 1 ); 
    
            my $data = '';

            # Read the entire response from the keyserver.
        
            while ( my $chunk = <$key_sock> )
            {
                $data = $data . $chunk;
            }
    
            $key_sock->close;
   
            # This splits the signature and data on the SIGNATURE_DELIMITER 
            # pattern as used by the keyserver.

            ( my $key_sig, $data ) = split /\n--end-sig--\n/, $data;
    
            if ( $key_sig eq "NOSIG" )
            {
                $sig_ack = $FALSE;
            } 
            else
            {
                $sig_ack = $TRUE;
            }
        }
    }

    sub _get_store_pkplus {

        # Contacts the key server and requests the PK+ for a specified
        # IP address/port combo. Stores the PK+ in the named disk-file.
        #
        # IN:  The IP name/address of the key server.
        #      The IP address to use when requesting a PK+ from the key server.
        #      The protocol port to use when requesting a PK+.
        #
        # OUT: nothing.
        #
        # This code is an extension of the "_wait_for_pkplus_confirm" code.
    
        use Crypt::RSA;  # Provides authentication and encryption services.
        use IO::Socket;  # Provides OO interface to Socket API.
    
        my $server = shift;
        my $lookup = shift;
        my $port   = shift;
   
        my $key_sock = IO::Socket::INET->new( 
                                                PeerAddr => $server,
                                                PeerPort => $RESPONDER_PPORT,
                                                Proto    => 'tcp'
                                            );

        if ( !defined( $key_sock ) )
        {
            die "Scooby: could not create key server socket object: $!.\n";
        }
    
        print $key_sock "$lookup\n";
        print $key_sock $port;
    
        # We are done writing, so half close the socket.

        $key_sock->shutdown( 1 ); 
    
        my $data = '';
    
        while ( my $chunk = <$key_sock> )
        {
            $data = $data . $chunk;
        }
    
        $key_sock->close;
   
        # This splits the signature and data on the SIGNATURE_DELIMITER 
        # pattern as used by the keyserver.

        ( my $key_sig, $data ) = split /\n--end-sig--\n/, $data;

        if ( $key_sig eq "NOSIG" )
        {
            die "Scooby: no signature found: aborting.\n";
        } 
        elsif ( $key_sig eq "SELFSIG" )
        {
            my $lf = "$lookup.$port.public";  # Location PK+ filename.

            open KEYFILE, ">$lf"
                or die "Scooby: could not create key file: $!.\n";
    
            print KEYFILE $data;
    
            close KEYFILE;
        }
        else
        {
            my $ksf = "$LOCALHOST.$RESPONDER_PPORT.public";

            my $key_server_pkplus = new Crypt::RSA::Key::Public(
                                            Filename => $ksf 
                                        );
   
            my $rsa = new Crypt::RSA;
   
            my $verify = $rsa->verify(
                                         Message    => $data,
                                         Signature  => "$key_sig",
                                         Key        => $key_server_pkplus,
                                         Armour     => $TRUE
                                      );
    
            if ( !$verify )
            {
                die "Scooby: signature for next location does not verify: aborting.\n";
            }
            else
            {
                open KEYFILE, ">$lookup.$port.public"
                    or die "Scooby: could not create key file: $!.\n";
    
                print KEYFILE $data;
      
                close KEYFILE;
            }
        }
    }
    
    sub _check_modules_on_remote {

        # Contacts the remote Location, sends the list of required modules,
        # waits for a response, then returns it to the caller.
        #    
        # IN:   The IP name (or address) of the remote Location.
        #       The protocol port number of the remote Location.
        #       The list of modules to look for.
        #
        # OUT:  The message received from the server.
    
        my $remote         = shift;
        my $remote_port    = shift;
        my @tocheck        = @_;
    
        use Socket;  # Functional interface to Socket API.
    
        my $trans_serv  = getprotobyname( 'tcp' );
        my $remote_host = gethostbyname( $remote ) or inet_aton( $remote );
    
        # Note: the server listens at Port+1.

        my $destination = sockaddr_in( $remote_port+1, $remote_host );
    
        socket( CHECK_MOD_SOCK, PF_INET, SOCK_STREAM, $trans_serv ) 
            or die "Scooby: socket creation failed: $!.\n";
        my $con_ok = connect( CHECK_MOD_SOCK, $destination )
            or die "Scooby: connect to remote system failed: $!.\n";
    
        # Send the list of modules to check.

        send( CHECK_MOD_SOCK, join( ' ', @tocheck ), 0 )
            or warn "Scooby: problem with send: $!.\n";
    
        shutdown( CHECK_MOD_SOCK, 1 );  # Close the socket for writing.
    
        my $remote_response = '';
        
        # Add a signal handler to execute when the alarm sounds (or expires).

        $SIG{ALRM} = sub { die "no remote module check\n"; };
    
        alarm( $ALARM_WAIT );
       
        # We wait for up to ALARM_WAIT seconds for a response from the Location. 

        eval {
            recv( CHECK_MOD_SOCK, $remote_response, $MAX_RECV_LEN, 0 );

            alarm( 0 );  # Cancel the alarm, we do not need it now.
        };
    
        close CHECK_MOD_SOCK
            or warn "Scooby: close failed: $!.\n";
    
        # Process the timeout if it happened.  Die if we see some message
        # other than the one we expect.

        if ( $@ )
        {
            die "Scooby: $@\n" unless $@ =~ /no remote module check/;
    
            warn "Scooby: not able to check existence of remote modules.\n";
        } 
    
        return $remote_response;
    }
    
    sub _storable_decode {

        # Called immediately after the lexical variables are stringified
        # in order to return the "Storable" output to its original form.
        #
        # IN:   The IP name (or address) of the remote Location.
        #       The protocol port number of the remote Location.
        #       The "thawed" output from the Storable::thaw method.
        #
        # OUT:  The stringified representation of the Perl code that can be
        #       executed to reinitialize the relocated variables.
        #
        # NOTE: This code also checks to see if any required modules exist
        #       on the remote Location.  It will "die" if some are missing.
    
        my $remote      = shift;
        my $remote_port = shift;
        my $thawed      = shift;  
    
        my %for_refs;
        my $stringified = '';
        my @required_classes = ();
    
        # The lexicals are processed TWICE, as it is not possible to
        # handle REFerences with a single pass over "$thawed".
    
        # Process the lexicals once, for SCALARs, ARRAYs and HASHes.
        #
        # Note: we need to remember the 'memory address' of each variable, so
        # we check them against any REFerences in the second pass.
        #
        # The generated code is indented by four spaces.

        while ( my ( $name, $value ) = each ( %{ $thawed } ) )
        {
            if ( ref( $value ) eq 'SCALAR' )
            {
                $for_refs{ $value } = $name;

                # We do NOT want to enclose SCALAR numbers in quotes!

                if ( $$value =~ /[^0123456789.]+/ )
                {
                    $stringified .= "    $name = \"$$value\";\n";
                } 
                else           
                {
                    $stringified .= "    $name = $$value;\n";
                }
            } 

            if ( ref( $value ) eq 'ARRAY' )
            {
                $for_refs{ $value } = $name;
                $stringified .= "    $name = qw( @$value );\n";
            } 

            if ( ref( $value ) eq 'HASH' )
            {
                $for_refs{ $value } = $name;
                $stringified .= "    $name = (\n";
                while ( my ( $h_name, $h_value ) = each ( %{ $value } ) )
                {
                    $stringified .= "        \"$h_name\" => \"$h_value\",\n"
                }
                $stringified .= "    );\n";
            } 
        }
    
        # Second pass: process the lexicals again, this time for REFs.

        while ( my ( $name, $value ) = each ( %{ $thawed } ) )
        {

            # Deal with references to Perl OO objects.

            if ( ref( $value ) eq 'REF' && !defined( $for_refs{ $$value } ) )
            {
                push @required_classes, ref( $$value );
    
                use Data::Dumper;
    
                my $string = Dumper( $value );
    
                # Make sure the appropriate Class is used.

                $stringified .= "    use " . ref( $$value ) . ";\n\n";
        
                # Replace Data::Dumper's generated $VARn with correct name.

                $string =~ s/^\$VAR\d+ = \\//;
    
                # Add the code to bless the object to the stringified code.

                $stringified .= "    $name = $string\n";
            }
    
            # Deal with references to SCALARs, ARRAYs and HASHes.

            if ( ref( $value ) eq 'REF' && defined( $for_refs{ $$value } ) )
            {
                $stringified .= "    $name = \\$for_refs{ $$value };\n";
            }
        }
    
        # Check to see if any required modules exist on the remote Location.
        # The list provided is calculated as a result of processing any
        # references to object instances.

        if ( @required_classes )
        {
            my $message = _check_modules_on_remote( 
                                                      $remote,
                                                      $remote_port, 
                                                      @required_classes 
                                                  );
          
            if ( $message =~ /^NOK/ )
            {
                $message =~ s/^NOK: //;

                die "Required modules missing on remote: $message.\n";
            }
            elsif ( $message !~ /^OK/ )
            {
                warn "Something strange has happened: $message.\n";

                die "Is the remote Location ready?\n";
            }
        }
    
        # Assuming we haven't died, return the Perl code to the caller.

        return $stringified;
    }

} # End of DB package.

1;  # Evaluate true as the last statement of this package (required by Perl).

##########################################################################
# Documentation starts here.
##########################################################################

=pod

=head1 NAME

"Scooby" - the internal machinery that works with B<Mobile::Location> and B<Mobile::Executive> to provide a mobile agent execution and location environment for the Perl Programming Language.

=head1 VERSION

4.0x (versions 1.x and 2.x were never released; version 3.x did not support encryption and authentication).

=head1 SYNOPSIS

perl -d:Scooby mobile_agent

=head1 DESCRIPTION

This is an internal module that is not designed to be "used" directly by a program.  Assuming a mobile agent called B<multiwho> exists (that "uses" the B<Mobile::Executive> module), this module can be used to execute it, as follows:

=over 4

perl -d:Scooby multiwho

=back

The B<-d> switch to C<perl> invokes Scooby as a debugger.  Unlike a traditional debugger that expects to interact with a human, Scooby runs automatically.  It NEVER interacts with a human, it interacts with the mobile agent machinery.

Scooby can be used to relocate Perl source code which contains the following:

=over 4

SCALARs (both numbers and strings).

An ARRAY of SCALARs (known as a simple ARRAY).

A HASH of SCALARs (known as a simple HASH).

References to SCALARs.

References to a simple ARRAY.

References to a simple HASH.

Objects.

References to objects are B<not> supported and are in no way guaranteed to behave the way you expect them to after relocation (even though they do relocate).

The relocation of more complex data structures is B<not> supported at this time (refer to the TO DO LIST section, below).

=back 

=head1 Internal methods/subroutines

=over 4

B<DB::DB> - called for every executable statement contained in the mobile agent source code file.

B<DB::sub> - called for every subroutine call contained in the mobile agent source code file.

B<_DB::storable_decode> - takes the stringified output from B<Storable>'s B<thaw> subroutine and turns it back into Perl code (with a little help from Data::Dumper for objects). 

B<DB::_check_modules_on_remote> - checks to see if a list of modules/classes "used" within the mobile agent actually exist on the remote Location's Perl system.

B<DB::_get_store_pkplus> - contacts the key server and requests a PK+, then stores the PK+ in a named disk-file.

B<DB::_wait_for_pkplus_confirm> - repeatedly contacts the key server until requested PK+ is returned (i.e., ACKed).

=back

=head1 ENVIRONMENT

This module must be installed in your Perl system's B<Devel/> directory.  This module will only work on an operating system that supports the Perl modules listed in the SEE ALSO section, below.  (To date, I've only tested it on various Linux distributions).

=head1 TO DO LIST

Loads.  The biggest item on the list would be to enhance Scooby to allow it to handle more complex data structures, such as ARRAYs of HASHes and HASHes of ARRAYs, etc., etc.

My initial plan was to allow for the automatic relocation of open disk-files.  However, on reflection, I decided not to do this at this time, but may return to the idea at some stage in the future.

The current implementation checks to see if "used" classes are available on the next Location before attempting relocation, but does not check to see if "used" modules are available.  It would be nice if it did.

It would also be nice to incorporate an updated B<Class::Tom> (by James Duncan) to handle the relocation of objects to a Location without the need to have the module exist on the remote Location.  On my system (Linux), the most recent B<Class::Tom> generates compile/run-time errors.

=head1 SEE ALSO

The B<Mobile::Executive> module and the B<Mobile::Location> class.  Internally, this module uses the following CPAN modules: B<PadWalker> and B<Storable>, in addition to the standard B<Data::Dumper> module.  The B<Crypt::RSA> modules provides encryption and authentication services.

The Scooby Website: B<http://glasnost.itcarlow.ie/~scooby/>.

=head1 AUTHOR

Paul Barry, Institute of Technology, Carlow in Ireland, B<paul.barry@itcarlow.ie>, B<http://glasnost.itcarlow.ie/~barryp/>.

=head1 COPYRIGHT

Copyright (c) 2003, Paul Barry.  All Rights Reserved.

This module is free software.  It may be used, redistributed and/or modified under the same terms as Perl itself.

