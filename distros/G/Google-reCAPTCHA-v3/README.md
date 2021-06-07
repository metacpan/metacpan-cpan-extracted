# NAME

Google::reCAPTCHA::v3 - A simple Perl API for Google reCAPTCHA v3

# SYNOPSIS

        use Google::reCAPTCHA::v3;

        my $grc = Google::reCAPTCHA::v3->new(
                {
                        -secret => 'Google reCAPTCHA v3 site secret key',
                }
        );

        my $r = $grc->request(
                { 
                        -response => 'response_token',
                        -remoteip => $remote_ip, # optional 
                }
        ); 

# DESCRIPTION

Google reCAPTCHA v3 is a simple module that is used to verify the reCAPTCHA response token generated from the front end 
of your app.

See: [https://developers.google.com/recaptcha/docs/verify](https://developers.google.com/recaptcha/docs/verify). 

# METHODS

## new

        my $grc = Google::reCAPTCHA::v3->new(
                {
                        -secret => 'Google reCAPTCHA v3 site secret key',
                }
        );

Requires one paramater, `-secret`, which should be your Google reCAPTCHA v3 site secret key. 
Returns a new Google::reCAPTCHA::v3 object. 

## request

        my $r = $grc->request(
                { 
                        -response => 'response_token',
                        -remoteip => $remote_ip, # optional 
                }
        ); 

        if($r->{success} == 1){ 
                # do useful things, like check the score
        }
        else { 
                # well, that didn't work. 
        }

Requires one paramater, `-response`, which should be the reCAPTCHA response token generated from the front end 
of your app. 

Optionally, you can pass, `-remoteip`, which should be your user's IP address.

`request` returns a hashref of the response returned from the service, with the following keys: 

- success

    `1` (valid) or `0` (invalid). 

    Whether this request was a valid reCAPTCHA token for your site

- score

    `number` 

    The score for this request (0.0 - 1.0)

- action 

    The action name for this request (important to verify)

- challenge\_ts

    Timestamp of the challenge load (ISO format yyyy-MM-dd'T'HH:mm:ssZZ)

- hostname

    The hostname of the site where the reCAPTCHA was solved

- error-codes

# LICENSE

Copyright (C) Justin Simoni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# BUGS

Please file any bugs/issues within the github repo: [https://github.com/justingit/Google-reCAPTCHA-v3/issues](https://github.com/justingit/Google-reCAPTCHA-v3/issues)

# AUTHOR

Justin Simoni
