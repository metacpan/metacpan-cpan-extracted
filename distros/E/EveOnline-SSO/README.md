# NAME

EveOnline::SSO - Module for Single Sign On in EveOnline API-services.

# SYNOPSIS

    use EveOnline::SSO;

    my $sso = EveOnline::SSO->new(client_id => '03ed7324fe4f455', client_secret => 'bgHejXdYo0YJf9NnYs');
    
    # return url for open in browser
    print $sso->get_code();
    # or
    print $sso->get_code(state => 'some_ids_or_flags');
    # or
    print $sso->get_code(state => 'some_ids_or_flags', scope=>'esi-calendar.respond_calendar_events.v1 esi-location.read_location.v1');

    # return hash with access and refresh tokens by auth code
    print Dumper $sso->get_token(code=>'tCaVozogf45ttk-Fb71DeEFcSYJXnCHjhGy');
    # or hash with access and refresh tokens by refresh_token
    print Dumper $sso->get_token(refresh_token=>'berF1ZVu_bkt2ud1JzuqmjFkpafSkobqdso');
    
    # return hash with access and refresh tokens through listening light web-server
    print Dumper $sso->get_token_through_webserver(
                        scope=>'esi-calendar.respond_calendar_events.v1 esi-location.read_location.v1', 
                        state=> 'Awesome'
                    );

# DESCRIPTION

EveOnline::SSO is a perl module for get auth in https://eveonline.com through Single Sign-On (OAuth) interface.

# CONSTRUCTOR

- **new()**

    Require two arguments: client\_id and client\_secret. 
    Optional arguments: callback\_url. Default is http://localhost:10707/

    Get your client\_id and client\_secret on EveOnline developers page:
    [https://developers.eveonline.com/](https://developers.eveonline.com/)

# METHODS

- **get\_code()**

    Return URL for open in browser.

    Optional params: state, scope

    See available scopes on [https://developers.eveonline.com/](https://developers.eveonline.com/)

        # return url for open in browser
        print $sso->get_code();
        
        # or
        print $sso->get_code(state => 'some_ids_or_flags');
        
        # or
        print $sso->get_code(scope=>'esi-calendar.respond_calendar_events.v1 esi-location.read_location.v1');

- **get\_token()**

    Return hashref with access and refresh tokens.
    refresh\_token is undef if code was received without scopes.

    Need "code" or "refresh\_token" in arguments. 

        # return hash with access and refresh tokens by auth code
        print Dumper $sso->get_token(code=>'tCaVozogf45ttk-Fb71DeEFcSYJXnCHjhGy');
        
        # or hash with access and refresh tokens by refresh_token
        print Dumper $sso->get_token(refresh_token=>'berF1ZVu_bkt2ud1JzuqmjFkpafSkobqdso');

- **get\_token\_through\_webserver()**

    Return hashref with access and refresh tokens by using local webserver for get code.
    Use callback\_url parameter for start private web server on host and port in callback url.

    Default url: http://localhost:10707/

        # return hash with access and refresh tokens
        print Dumper $sso->get_token_through_webserver(scope=>'esi-location.read_location.v1');

# LICENSE

Copyright (C) Andrey Kuzmin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Andrey Kuzmin <chipsoid@cpan.org>
