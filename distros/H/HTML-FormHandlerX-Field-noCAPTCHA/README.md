# NAME

HTML::FormHandlerX::Field::noCAPTCHA - Google's noCAPTCHA reCAPTCHA for HTML::FormHandler

# SYNOPSIS

The following is example usage.

In your [HTML::FormHandler](https://metacpan.org/pod/HTML::FormHandler) subclass, "YourApp::HTML::Forms::YourForm":

        has_field 'nocaptcha' => (
                type=>'noCAPTCHA',
                site_key=>'[YOUR SITE KEY]',
                secret_key=>'[YOUR SECRET KEY]',
        );

Example [Catalyst](https://metacpan.org/pod/Catalyst) controller:

        my $form = YourApp::HTML::Forms::YourForm->new({ctx => $c});
        my $params = $c->request->body_parameters;
        if($form->process($c->req->body_parameters) {
                ## Do something with the form.
        } else {
                ## Redisplay form and ask to try again.
        }

Example [Catalyst](https://metacpan.org/pod/Catalyst) config:

        __PACKAGE__->config(
                'HTML::FormHandlerX::Field::noCAPTCHA' => {
                        site_key   => '[YOUR SITE KEY]',
                        secret_key => '[YOUR SECRET KEY]',
                },
        );

# FIELD OPTIONS

Support for the following field options, over what is inherited from
[HTML::FormHandler::Field](https://metacpan.org/pod/HTML::FormHandler::Field)

## site\_key

Required. The site key you get when you create an account on [https://www.google.com/recaptcha/](https://www.google.com/recaptcha/)

## secret\_key

Required. The secret key you get when you create an account on [https://www.google.com/recaptcha/](https://www.google.com/recaptcha/)

## theme

Optional. The color theme of the widget. Options are 'light ' or 'dark' (Default: light)

## noscript

Optional. When true, includes the <noscript> markup in the rendered html. (Default: false)

## remote\_address

Optional. The user's IP address. Google states this is optional.  If you are using
catalyst and pass the context to the form, noCAPTCHA will use it by default.

## api\_url

Optional. URL to the Google API. Defaults to https://www.google.com/recaptcha/api/siteverify

## api\_timeout

Optional. Seconds to wait for Google API to respond. Default is 10 seconds.

## g\_captcha\_message

Optional. Message to display if user answers captcha incorrectly.
Default is "You've failed to prove your Humanity!"

## g\_captcha\_failure\_message

Optional. Message to display if there was an issue with Google's API response.
Default is "We've had trouble processing your request, please try again."

## config\_key

Optional. When passing catalyst context to [HTML::FormHandler](https://metacpan.org/pod/HTML::FormHandler), uses this values
as the key to lookup configurations for this package.
Default is HTML::FormHandlerX::Field::noCAPTCHA

# SEE ALSO

The following modules or resources may be of interest.

[HTML::FormHandler](https://metacpan.org/pod/HTML::FormHandler)
[Captcha::noCAPTCHA](https://metacpan.org/pod/Captcha::noCAPTCHA)

# AUTHOR

Chuck Larson `<clarson@cpan.org>`

# COPYRIGHT & LICENSE

Copyright 2017, Chuck Larson `<chuck+github@endcapsoftwware.com>`

This projects work sponsored by End Cap Software, LLC.
[http://www.endcapsoftware.com](http://www.endcapsoftware.com)

Original work by John Napiorkowski `<jjnapiork@cpan.org>`

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
