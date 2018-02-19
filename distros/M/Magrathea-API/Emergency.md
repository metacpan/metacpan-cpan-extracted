## NAME

Magrathea::API::Emergency - Access to the Magrathea 999 Interface

## EXAMPLE

    use Magrathea::API;
    my $mt = new Magrathea::API($username, $password);
    my $emerg = $mt->emergency_info($phone_number);
    # Get the status, print it and check it
    my $status = $emerg->status;
    say "Status is: $status" if $status != 0;
    # Print the thoroughfare, update it and print it again
    say "Thoroughfare is currently: ", $emerg->thoroughfare;
    $emerg->thoroughfare("He is a justice of the peace and in accommodation.");
    say "Thoroughfare is now ", $emerg->thoroughfare;
    # prints: He is a J.P. & in Accom.
    # Update the changes
    $emerge->update

## DESCRIPTION

This module represents the
[Magrathea 999 API Appendix](https://www.magrathea-telecom.co.uk/assets/Client-Downloads/Magrathea-NTSAPI-999-Appendix.pdf).

It should not be constructed by user code; it is only avalible through
the main [Magrathea::API](https://metacpan.org/pod/Magrathea::API) code as follows:

    my $mt = new Magrathea::API($username, $password);
    my $emerg = $mt->emergency_info($phone_number);

## METHODS

## create

This is used the first time a number is put onto the database and
then only if the owner changes.  It needs to be followed by an
["update"](#update) after entering all the data.

### number

This returns the number currently being worked on as a [Phone::Number](https://metacpan.org/pod/Phone::Number).

### info

This returns all the fields in a hash or as a pointer to a has
depending on list or scalar context.  The fields are as documented for
methods below.

### status

This returns a single value for status.  The valuse returned can be
used as a string and returns the message or as a number which returns
the status code.  The possible statuses are curently as below but they
are returned from Magrathea so the
[999 Appendix](https://www.magrathea-telecom.co.uk/assets/Client-Downloads/Magrathea-NTSAPI-999-Appendix.pdf)
should be treated as authoritive.

- 0 Accepted
- 1 Info received
- 2 Info awaiting further validation
- 3 Info submitted
- 6 Submitted – Awaiting manual processing
- 8 Rejected
- 9 No record found

### title

### forename

### name

### honours

### bussuffix

### premises

### thoroughfare

### locality

### postcode

The above methods will get or set a field in the 999 record.

Abbreviations are substituted and they are then checked for
maximum length.  These routines will croak if an invalid length
(or invalid postcode) is passed

To get the data, simply call the method, to change the data, pass
it as a parameter.

Nothing is sent to Magrathea until ["update"](#update) is called.

### ported

This is a boolean value showing whether or not the number has been
ported in from another provider.  It will always evaluate to `false`
though unless set by this method as there is no way to store the
information on the Magrathea database.

        $emerge->ported(true);      # Assuming true is set to 1
        my $ported = $emerg->ported;

### update

This will take the current data and send it to Magrathea.  The possible
valid responses are `Information Valid` (0 in numeric context) or
`Parsed OK. Check later for status.` (1 in numeric context).

If Magrathea's validation fails, the update will croak.

## AUTHOR

Cliff Stanford, <cliff@may.be>

## ISSUES

Please open any issues with this code on the
[Github Issues Page](https://github.com/CliffS/magrathea-api/issues).

## COPYRIGHT AND LICENCE

Copyright (C) 2012 - 2018 by Cliff Stanford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
