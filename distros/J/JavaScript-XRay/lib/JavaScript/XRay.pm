package JavaScript::XRay;
use warnings;
use strict;
use Carp qw(croak);
use LWP::Simple qw(get);
use URI;
use constant IFRAME_DEFAULT_HEIGHT => 200;

our $VERSION = '1.22';
our $PACKAGE = __PACKAGE__;
our %SWITCHES = (
    all => {
        type => 'bool',
        desc => 'filter all functions (default)',
    },
    none => {
        type => 'bool',
        desc => 'don\'t filter any functions',
    },
    anon => {
        type => 'bool',
        desc => 'filter anon functions (noisy)',
    },
    no_exec_count => {
        type => 'bool',
        desc => 'don\'t count function executions',
    },
    only => {
        type     => 'function1,function2,...',
        desc     => 'only filter listed functions (exact)',
        ref_type => 'ARRAY',
    },
    skip => {
        type     => 'function1,function2,...',
        desc     => 'skip listed functions (exact)',
        ref_type => 'ARRAY'
    },
    uncomment => {
        type     => 'string1,string2,...',
        desc     => 'uncomment lines prefixed with string (DEBUG1,DEBUG2)',
        ref_type => 'ARRAY'
    },
    match => {
        type     => 'string',
        desc     => 'only filter functions that match string (/^string/)',
        ref_type => 'Regexp'
    },
);

our @SWITCH_KEYS = keys %SWITCHES;

sub new {
    my ( $class, %args ) = @_;

    my $alias = $args{alias} || 'jsxray';
    my $obj = {
        alias            => $alias,
        iframe_height    => $args{iframe_height} || IFRAME_DEFAULT_HEIGHT,
        css_inline       => $args{css_inline},
        css_external     => $args{css_external},
        verbose          => $args{verbose},
        inline_methods   => ['HTTP_GET'],
        js_log           => '',
        js_log_init      => '',
        js_switches      => '',
        js_function_names => '',
    };

    bless $obj, $class;

    $obj->_init_uri( $args{abs_uri} );
    $obj->switches( %{$args{switches}} ) if $args{switches};

    return $obj;
}

sub _init_uri {
    my ( $self, $abs_uri ) = @_;
    return unless $abs_uri;
    $self->{abs_uri} = ref $abs_uri eq 'URI' ? $abs_uri : URI->new($abs_uri);
    return;
}

sub switches {
    my ( $self, %switches ) = @_;
    return $self->{switches} unless keys %switches;

    # allow 'jsxray_uncomment' or just 'uncomment'
    my $alias = $self->{alias};
    %switches = map {
        my $new_key = $_;
        $new_key =~ s/^$alias\_//;
        ( $new_key => $switches{$_} );
    } keys %switches;

    for my $switch ( keys %switches ) {
        unless ( $SWITCHES{$switch} ) {
            warn "invalid switch: $switch";
            next;
        }
        my $ref_type = ref $switches{$switch};
        $self->{switches}{$switch} =
              $ref_type eq 'ARRAY' && $SWITCHES{$switch}{ref_type} eq 'ARRAY'
            ? join(',', @{ $switches{$switch} })
            : $switches{$switch};

        $self->{js_switches} .= qq|${alias}_switches.push("${alias}_${switch}");\n|;
    }

    # init other switches so we don't get warnings
    for my $switch (@SWITCH_KEYS) {
        $self->{switches}{$switch} = ''
            unless $self->{switches}{$switch};
    }

    return %{ $self->{switches} };
}

sub inline_methods {
    my ( $self, @methods ) = @_;

    if ( @methods ) {
        my @valid_methods = ();
        for my $method (@methods) {
            unless ( -d $method
                || $method     eq 'HTTP_GET'
                || ref $method eq 'CODE' )
            {
                warn 'inline methods may only be local server '
                    . 'directories, code references, or the special string '
                    . "HTTP_GET - invalid method: $method";
            }
            else {
                push @valid_methods, $method;
            }
        }

        unless (@valid_methods) {
            warn 'inline_methods called without valid methods';
            exit;
        }
    
        $self->{inline_methods} = \@valid_methods;
    }

    return wantarray ? @{ $self->{inline_methods} } : $self->{inline_methods};
}

sub filter {
    my ( $self, $html ) = @_;

    my ( $alias, $switch ) = ( $self->{alias}, $self->{switches} );

    $self->_warn( 'Tracing anonymous functions' )
        if $switch->{anon} && !$switch->{only};

    $self->_warn( "Only tracing functions exactly matching: $switch->{only}" )
        if $switch->{only};

    $self->_warn( "Skipping functions: $switch->{skip}" ) if $switch->{skip};

    $self->_warn( "Tracing matching functions: /^$switch->{match}/" )
        if $switch->{match};

    $html = $self->_filter($html);
    $html = $self->_inline_javascript($html);

    $self->_uncomment( \$html ) if $switch->{uncomment};
    $self->_inject_console( \$html );

    $self->_inject_js_css( \$html );

    return $html;
}

sub _filter {
    my ( $self, $work_html ) = @_;

    my ( $alias, $switch ) = ( $self->{alias}, $self->{switches} );

    my $new_html = '';
    while (
        $work_html =~ m{
            \G
            (.+?)
            (
                function?
                \s*
                (?:\w|_)+?
                \s*?
                [(]
                .+?
                [)]?
                \s*
                \{
            )
        }cgimosx
        )
    {

        # build output page from input page
        $new_html .= $1;

        # find the function name
        my $function .= $2;
        my ($name) = $function =~ m/function\s*(\w+?)?\s*?\(/gx;
        $name = '' unless $name;  # define it to supress warnings

        # don't want any recursive JavaScript loops
        croak( "found function '$name', functions may "
                . "not match alias: '$alias'" )
            if $name eq $alias;

        # find the function arguments
        my ($args) = $function =~ m/function\s*$name?\s*?[(](.+?)[)]/gx;
        $name = 'ANON' unless $name;

        unless ( $switch->{no_exec_count}
            || ( $name eq 'ANON' && !$switch->{anon} ) )
        {
            $self->{js_log_init} .= "${alias}_exec_count['$name'] = 0;\n";
            $function            .= "${alias}_exec_count['$name']++;";
        }

        # functions for use in form to select query parameters
        $self->_switch_function_options($name) if ($name ne 'ANON');
        
        my %only_function = $switch->{only}
            ? map { $_ => 1 } split( /\,/, $switch->{only} )
            : ();
        my %skip_function = $switch->{skip}
            ? map { $_ => 1 } split( /\,/, $switch->{skip} )
            : ();

        my $function_filter = '';
        if (ref $switch->{match} eq 'Regexp') {
            $function_filter = $switch->{match};
        }
        elsif ( $switch->{match} ) {
           my $safe_filter = quotemeta $switch->{match};
           $function_filter = qr/^$safe_filter/;
        }

        # skip filter
        #   if none
        #   if anon and not filtering anon functions
        #   if switch 'only' used and function doesn't match
        #   if switch 'skip' used and function matches
        #   if switch 'filter' used and function doesn't match
        if (   ( $switch->{none} )
            || ( $name eq 'ANON' && !$switch->{anon} )
            || ( $switch->{only}   && !$only_function{$name} )
            || ( $switch->{skip}   && $skip_function{$name} )
            || ( $switch->{match} && $name !~ m/$function_filter/x ) )
        {
            $new_html .= $function;
        }
        else {
            $self->_warn("Found function '$name'");

            # build out function arguments - this is the cool part
            # you also get to see the value of arguments passed to the 
            # function, _extremely_ handy
            my $filtered_args = '';
            if ($args) {
                my @arg_list = split( /\,/, $args );
                $filtered_args = '\'+' . join( '+\', \'+', @arg_list ) . '+\'';
            }

            # insert the log call
            $new_html
                .= $function . "$alias('$name( $filtered_args )');";
        }
    }

    if ( $work_html =~ /\G(.*)/cgs ) {
        $new_html .= $1;
    }

    return $new_html;
}

sub _inline_javascript {
    my ( $self, $work_html ) = @_;

    my $new_html = '';

    # look through the HTML for script blocks
    while (
        $work_html =~ m{
        \G
        (.*?)
        (
            <script
            .*?
            <\/script>
        )
        }cgimosx
        )
    {
        $new_html .= $1;
        my $script_block = $2;

        # pull out both script attributes and inner script
        while (
            $script_block =~ m{
                <script
                (.*?)
                \s*?>
                (.*?)
                <\/script>
            }cgimosx
            )
        {
            my ( $script_attrs, $inner_script ) = ( $1, $2 );
            $script_attrs =~ s/\s*\=\s*/\=/g;    # clean up white space

            # parse out name value pairs so we can rebuild the script
            # element properly.  (special case 'defer' is a boolean 
            # and has no value
            my %attrs = ();
            while (
                $script_attrs =~ m{
                \G
                \s*
                (?: (defer) | 
                    (.+?)
                    \s*
                    \=
                    \s*
                    (?: [\"\'](.+?)[\"\'] | (\w+) )
                )
                }cgimosx
                )
            {

                my ( $defer, $name, $value ) = ( $1, $2, $3 || $4 );
                if ($defer) {
                    $attrs{$defer} = 1;
                }
                else {
                    $attrs{$name} = $value;
                }
            }

            if ( keys %attrs && $attrs{src} ) {
                my @attrs = map {
                    $_ eq 'defer' ? $_ : "$_=\"$attrs{$_}\"";
                } grep { $_ ne 'src' } keys %attrs;

                my $js = $self->_get_external_javascript($attrs{src});
    
                if ($js) {
                    my $inline_javascript = '<script '
                        . join( ' ', @attrs ) . "><!--\n"
                        . $js
                        . "\n--></script>";

                    $new_html .= "<!-- inline $attrs{src} -->\n";
                    $new_html .= $inline_javascript;
                }
                else {
                    warn 'failed to inline (or referenced URI is empty): '
                        . $script_block;
                    $new_html .= $script_block;
                }
            }
            else {
                $new_html .= $script_block;
            }
        }
    }

    if ( $work_html =~ /\G(.*)/cgs ) {
        $new_html .= $1;
    }

    return $new_html;
}

sub _get_external_javascript {
    my ( $self, $src ) = @_;
    my $js = '';

    if ( $src !~ /^http/i && !$self->{abs_uri} ) {
        warn 'unable to inline/filter external javascript files with an'
            . 'absolute request uri: abs_uri not defined';
        return $js;
    }

    # if true its an absolute uri so no need to call new_abs
    my $abs_js_uri =
          $src =~ /^http/ || ( $src =~ /^\// && $self->{abs_uri} =~ /^\// )
        ? URI->new($src)
        : URI->new_abs( $src, $self->{abs_uri} );

    for my $method ( @{$self->{inline_methods}} ) {
        if ($method eq 'HTTP_GET') {
            $self->_warn("attempting to fetch: $abs_js_uri")
                if $self->{verbose};
            $js = get( $abs_js_uri );
        }
        elsif ( -d $method ) {
            my $possible_js_file = URI->new_abs( $src, $method );
            if ( open( my $fh, '<', $possible_js_file ) ) {
                $js = do { local $/ = undef; <$fh> };
                close $fh;
            }
            else {
                warn "failed to open: $possible_js_file: $!";
            }
        }
        elsif ( ref $method eq 'CODE' ) {
            $js = &$method( $src, $self->{abs_uri} );
        }
        last if $js;
    }

    if ($js) {
        $self->_warn("Inlining and Filtering $src");
        $js = $self->_filter($js);
    }

    return $js;
}

sub _uncomment {
    my ( $self, $html_ref ) = @_;
    my $switch = $self->{switches};

    # uncomment nessesary tags
    my @uncomment_strings
        = map { quotemeta($_) } split( /\,/, $switch->{uncomment} );
    for my $uncomment (@uncomment_strings) {
        my $uncomment_count = $$html_ref =~ s/\/\/$uncomment//gs;
        if ($uncomment_count) {
            my $label = $uncomment_count > 1 ? 'instances' : 'instance';
            $self->_warn( "$PACKAGE->filter uncommented $uncomment: "
                    . "Found $uncomment_count $label" );
        }
    }

    return;
}

sub _inject_js_css {
    my ( $self, $html_ref ) = @_;
    my ( $alias, $switches ) = ( $self->{alias}, $self->{switches} );

    my $js_css = qq|<script><!--
    var ${alias}_logging_on = true;
    var ${alias}_doc = null;
    var ${alias}_cont_div = null;
    var ${alias}_last_div = null;
    var ${alias}_count = 1;
    var ${alias}_exec_count = [];
    var ${alias}_date_start;
    var ${alias}_time_start;
    var ${alias}_pre_iframe_queue = [];
    $self->{js_log}

    function ${alias}( msg ) {
        if ( !${alias}_logging_on ) return;
        if ( ${alias}_doc == null) {
            if ( ! ${alias}_init( "Initialized" ) ) {
                ${alias}_pre_iframe_queue.push(msg);
                return;
            }
            else {
                for( var x = 0; x < ${alias}_pre_iframe_queue.length; x++ ) {
                    ${alias}_log( ${alias}_pre_iframe_queue[x] );
                }
                ${alias}_pre_iframe_queue = [];
            }
        }
        ${alias}_log( msg );
    }

    function ${alias}_log ( msg ) {
        // timing data
        var ${alias}_date_now = new Date();
        var ${alias}_time_since = ${alias}_date_now.getTime();
        var ${alias}_elapsed_time = 
            ( ${alias}_time_since - ${alias}_time_start );
        var ${alias}_time = ${alias}_date_format( ${alias}_date_now );
        var ${alias}_div  = ${alias}_doc.createElement( 'DIV' );

        ${alias}_div.className = "${alias}_desc";
        ${alias}_doc.body.appendChild( ${alias}_div );
        ${alias}_cont_div.insertBefore(${alias}_div, ${alias}_last_div);
        ${alias}_div.innerHTML = "<span class='${alias}_loginfo'>[ " 
            + ${alias}_count + ' - ' + ${alias}_time + ' - ' 
            + ${alias}_elapsed_time + "ms ]</span> " + msg;
        ${alias}_count++;
        ${alias}_last_div = ${alias}_div;
    }

    function ${alias}_init(init_msg) {
        $self->{js_log_init}
        ${alias}_date_start = new Date();
        ${alias}_time_start = ${alias}_date_start.getTime();
        if (!window.frames.${alias}_iframe) return;
        ${alias}_doc = window.frames.${alias}_iframe.document;
        ${alias}_doc.open();
        ${alias}_doc.write("<!DOCTYPE html PUBLIC -//W3C//DTD ");
        ${alias}_doc.write("XHTML 1.0 Transitional//EN ");
        ${alias}_doc.write("  http://www.w3.org/TR/xhtml1/DTD/");
        ${alias}_doc.write("xhtml1/DTD/xhtml1-transitional.dtd>\\n\\n");
        ${alias}_doc.write("<html><head><title>$PACKAGE v$VERSION");
        ${alias}_doc.write("</title>\\n");
        ${alias}_doc.write("</head>");
        ${alias}_doc.write("|;
   $js_css .= $self->_css(1);
   $js_css .= qq|");
        ${alias}_doc.write("<body style='");
        ${alias}_doc.write("background-color:white; margin: 2px'></body>\\n");
        ${alias}_doc.close();
        ${alias}_cont_div = ${alias}_doc.createElement( 'DIV' );
        ${alias}_doc.body.appendChild(${alias}_cont_div);
        ${alias}_last_div = ${alias}_doc.createElement( 'DIV' );
        ${alias}_last_div.className = "${alias}_desc";
        ${alias}_last_div.innerHTML = "<span class='${alias}_loginfo'>[ " 
            + ${alias}_count 
            + " - " 
            + ${alias}_date_format( ${alias}_date_start ) 
            + " - 0ms ]</span> $PACKAGE " + init_msg;
        ${alias}_cont_div.appendChild(${alias}_last_div);
        ${alias}_count++;

        return 1;
    }

    function ${alias}_alert_counts() {
        var msg = "";
        var sort_array = new Array;
        for ( var key in ${alias}_exec_count ) sort_array.push( key );
        sort_array.sort( ${alias}_exec_key_sort );
        for( var x = 0; x < sort_array.length; x++ ) {
             if ( ${alias}_exec_count[sort_array[x]] != 0 ) {
                 msg += sort_array[x] + " = " + ${alias}_exec_count[sort_array[x]] + "\\n";
             }
        }
        alert(msg);
    }

    function ${alias}_exec_key_sort( a, b ) {
        var x = ${alias}_exec_count[b];
        var y = ${alias}_exec_count[a];
        return ( ( x < y) ? -1 : ( (x > y) ? 1 : 0 ) );
    }

    function ${alias}_date_format ( date ) {
        var ${alias}_day   = date.getDate();
        var ${alias}_month = date.getMonth() + 1;
        var ${alias}_hours = date.getHours();
        var ${alias}_min   = date.getMinutes();
        var ${alias}_sec   = date.getSeconds();
        var ${alias}_ampm  = "AM";

        if ( ${alias}_hours > 11 ) ${alias}_ampm = "PM";
        if ( ${alias}_hours > 12 ) ${alias}_hours -= 12;
        if ( ${alias}_hours == 0 ) ${alias}_hours = 12;
        if ( ${alias}_min < 10 )   ${alias}_min = "0" + ${alias}_min;
        if ( ${alias}_sec < 10 )   ${alias}_sec = "0" + ${alias}_sec;

        return ${alias}_month + '/' + ${alias}_day + ' ' 
            + ${alias}_hours  + ':' + ${alias}_min + ':'
            + ${alias}_sec    + ' ' + ${alias}_ampm;
    }

    function ${alias}_toggle_switch() {
        var obj = ${alias}_gel( '${alias}_switch' )
        if ( !obj ) return;
        var switch_button = ${alias}_gel( '${alias}_switch_button' )
        if ( !switch_button ) return;
        if ( obj.style.display == '' ) {
            obj.style.display = 'none';
        }
        else {
            obj.style.display = '';
        }
    }
    
    function ${alias}_toggle_info() {
        var info = ${alias}_gel( '${alias}_info' )
        if ( !info ) return;
        var info_button = ${alias}_gel( '${alias}_info_button' )
        if ( !info_button ) return;
        if ( info.style.display == '' ) {
            info.style.display = 'none';
            info_button.value = "Show Info";
        }
        else {
            info.style.display = '';
            info_button.value = "Hide Info";
        }
    }

    function ${alias}_clear() {
        if ( !confirm("Are you sure?") ) return;
        ${alias}_count = 1;
        ${alias}_init( "Console - Cleared" );
    }

    function ${alias}_toggle_logging() {
        var logging_button = ${alias}_gel( '${alias}_logging_button' )
        if ( !logging_button ) return;
        if ( ${alias}_logging_on ) {
           ${alias}("$PACKAGE Console Stopped Logging");
            logging_button.value = "Resume Logging";
            ${alias}_logging_on = false;
        }
        else {
           ${alias}_logging_on = true;
           logging_button.value = "Stop Logging";
           ${alias}("$PACKAGE Console - Resumed Logging");
        }
    }

    // Parameter switches
    ${alias}_switches = [];
    $self->{js_switches};
    
    // Reload url object
    var ${alias}_reload = {};
    ${alias}_reload.params = [];
    
    // Initialize switches parameters
    ${alias}_reload.params_init = function() {
        ${alias}_reload.params = [];
    }
    
    // Add to switches parameters
    ${alias}_reload.params_add = function (id, value) {
        var query_str = id + "=" + value;
        ${alias}_reload.params.push(query_str);
        return;
    }
    
    // Assemble url to reload page in after form submission
    ${alias}_reload.params_final = function() {
        var base_url = document.URL;
        // Eliminate params for switches from url, keep others intact
        var idx = document.URL.indexOf('?');
        if (idx != -1) {
            var switches_str = ${alias}_switches.join('~');
            switches_str = '~'+switches_str+'~';
            var url_params = document.URL.split('?');
            base_url = url_params[0];
            var pairs = url_params[1].split('&');
            var n = pairs.length
            for (var i=0; i<n; i++) {
                name_value = pairs[i].split('=');
                if (!switches_str.match("~"+name_value[0]+"~")) {
                    ${alias}_reload.params.push(name_value[0]+'='+name_value[1]);
                }
           }
        }
        
        var switch_params = ${alias}_reload.params.join("&");
        var reload_url = base_url + "?" + switch_params;
        location.replace(reload_url);
    }
    
    function ${alias}_reload_console(form) {
        // initialize params array
        ${alias}_reload.params_init();
        
        for (var i=0; i < form.length; i++) {
            var form_el = form.elements[i];
            var id   = form_el.id;
            // form element type: checkbox, text
            var element_type = form_el.type;
            switch (element_type) {
                case "text":        //string values
                    var val  = form_el.value;
                    if (val != '') {
                        ${alias}_reload.params_add(id, val);
                    }
                break;
                case "checkbox":    //bool values
                    // only checked values are added as params
                    if (form_el.checked) {
                        var val = '1';
                        ${alias}_reload.params_add(id, val);
                    }
                break;
                case "select-multiple":      //string values
                    var sel = [];
                    for (var j=0; j < form_el.options.length; j++) {
                        var val = form_el.options[j].value;
                        if (form_el.options[j].selected == true && val != '') {
                            sel.push(val);
                        }
                    }
                    if (sel.length > 0) {
                        var str = sel.join(',');
                        ${alias}_reload.params_add(id, str);
                    }
                break;
            }
            
            //last form element, go ahead and assemble final url
            if (i == (form.length - 1)) {
                ${alias}_reload.params_final();
            }
        }
    }
    
    function ${alias}_reset_console(form) {
        for (var i=0; i < form.length; i++) {
            var form_el = form.elements[i];
            // form element type: checkbox, text
            var element_type = form_el.type;
            switch (element_type) {
                case "text":                //string values
                    form_el.value = "";
                break;
                case "checkbox":            //bool values
                    if (form_el.checked) {
                        form_el.checked = false;
                    }
                break;
                case "select-multiple":      //string values
                    for (var j=0; j < form_el.options.length; j++) {
                        form_el.options[j].selected = false;
                    }
                break;
            }
        }
    }
    
    function ${alias}_gel( el ) {
        return document.getElementById ? document.getElementById( el ) : null;
    }

    -->
    </script>\n|;
    $js_css .= $self->_css;

    $$html_ref =~ s/(<head.*?>)/$1$js_css/is;

    return;
}

sub _inject_console {
    my ( $self, $html_ref ) = @_;

    my ( $alias, $switches ) = ( $self->{alias}, $self->{switches} );

    my $iframe .= qq|
    <div class='${alias}_buttons' id='${alias}_buttons'>
    <span class="${alias}_version"><a href="http://search.cpan.org/~jbisbee/JavaScript-XRay/" target="_blank">$PACKAGE</a> v$VERSION</span>
    <input type="button" value="Stop Logging" id="${alias}_logging_button" 
        onClick="${alias}_toggle_logging()" class="${alias}_button">
    <input type="button" value="Show Info" id="${alias}_info_button" 
        onClick="${alias}_toggle_info()" class="${alias}_button">
    <input type="button" value="Clear" onClick="${alias}_clear()" 
        class="${alias}_button"> 
    <input type="button" value="Change Switches" id="${alias}_switch_button" 
        onClick="${alias}_toggle_switch()" class="${alias}_button">|;

    $iframe .= qq| <input type="button" value="Execution Counts" 
        onClick="${alias}_alert_counts()" class="${alias}_button">|
        unless $switches->{no_exec_count};

   $iframe .= qq|</div>
    <div id="${alias}_info" class="${alias}_buttons" style='display:none'>
    <center>
    <table cellpadding=0 cellspacing=0 border=0>|;

    for my $switch ( @SWITCH_KEYS ) {
        my $value = $switches->{$switch} || '';
        $iframe .= qq|<tr>
                <td class='${alias}_desc'>${alias}_$switch</td>
                <td>&nbsp;&nbsp;</td>
                <td class='${alias}_value'>$value</td>
                <td class='${alias}_desc'>$SWITCHES{$switch}{type}</td>
                <td>&nbsp;&nbsp;</td>
                <td class='${alias}_desc'>$SWITCHES{$switch}{desc}</td>
            </tr>|;
    }

    $iframe .= qq|
    </table>
    </center>
    </div>

    
    <div id="${alias}_switch" class="${alias}_buttons" style='display:none;'>
    <div class="${alias}_form_border">
    <table width="100%" cellpadding="1" cellspacing="1" border="0">
    <tr><td align="right"><div class="${alias}_closebutton" onClick="${alias}_toggle_switch()">X</div></td></tr>
    <tr><td>Use 'Ctrl' key to choose function names in multiple selection boxes. Click on "Reload Console" for new switches to take effect.</td></tr></table>
    <br>
    <table cellpadding=1 cellspacing=0 border=0>
    <form name="switch_console" id="switch_console" method="get" action="">|;
    
    for my $switch (@SWITCH_KEYS) {
        next if ( $switch eq 'all' );
        my $value = $switches->{$switch} || '';
        my $form_element;
        if ( $SWITCHES{$switch}{type} eq 'bool' ) {
            my $checkbox_value = $value ? ' checked' : '';
            $form_element = qq|<input type="checkbox" value=""$checkbox_value id="${alias}_$switch">|;
        }
        elsif ( $SWITCHES{$switch}{type} =~ /string/ ) {
            $form_element = qq|<input type="text" size="40" value="$value" id="${alias}_$switch">|;
        }
        elsif ( $SWITCHES{$switch}{type} =~ /function/ ) {
            $form_element = qq|<select multiple size="5" id="${alias}_$switch"><option value="">-- None -- $self->{js_function_names}</select>|;
        }
        $iframe .= qq|<tr class="${alias}_desc" valign="top"><td align="right">${alias}_$switch:&nbsp;</td><td>$form_element</td></tr>|;
    }
    
    $iframe .= qq|
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr align="center"><td colspan="2"><input type="button" value="Reload Console" onClick="${alias}_reload_console(this.form);" class="${alias}_button"> &nbsp; <input type="button" value="Reset"  onClick="${alias}_reset_console(this.form);" class="${alias}_button"></tr>
    </form>
    </table>
    </div>
    </div>
    
    <div class="${alias}_iframe_padding">
    <div class="${alias}_iframe_border">
    <iframe id="${alias}_iframe" name="${alias}_iframe" class="${alias}_iframe"></iframe>
    </div>
    </div>|;

    $$html_ref =~ s/(<body.*?>)/$1$iframe/is;

    return;
}

sub _css {
    my ($self, $escape_bool) = @_;

    my ($alias) = ($self->{alias});

    my $css = qq|<style>
    .${alias}_desc, td.${alias}_value, .${alias}_loginfo, ${alias}_buttons {
        font-family: arial,helvetica; 
        font-size: 12px; 
        background-color: white;
    }
    tr.${alias}_desc, td.${alias}_desc, td.${alias}_value, .${alias}_buttons {
        background-color: #D3D3D3
    }
    tr.${alias}_desc, td.${alias}_desc, td.${alias}_value, .${alias}_version {
        font-size: 12px; 
    }
    .${alias}_buttons { 
        padding-top: 4px; 
        padding-left: 8px; 
        padding-bottom: 4px; 
    }
    .${alias}_loginfo, .${alias}_version, .${alias}_buttons {
        color: #727272
    }
    td.${alias}_value {
        color: #5555FF;
        padding-left:1em;
        padding-right:1em;
    }
    .${alias}_version {
        font-family: arial,helvetica; 
        float:right;
        padding-right: 10px;
    }
    .${alias}_iframe_padding {
        border-width: 0px 7px 7px 7px;
        border-color: #D3D3D3;
        border-style: solid;
    }
    .${alias}_iframe_border {
        border-width: 1px;
        border-style: groove;
    }
    .${alias}_iframe {
        width: 100%;
        height: $self->{iframe_height}px;
        border: 0px;
    }
    input.${alias}_button {
        background-color: #D3D3D3;
        border-width: 1px;
        border-color: #a9a9a9;
    }
    .${alias}_form_border {
        border: 1px dashed #5e5e5e;
        padding: 5px;
        width: 50%;
    }
    .${alias}_closebutton {
        border:1px solid #5e5e5e; 
        width:10px; padding:1px; 
        font:10px arial,sans-serif; 
        text-align:center; 
        color:#5e5e5e; 
        vertical-align:middle; 
        cursor:pointer; 
        cursor:hand;
    }|;

    # cat inline css
    $css .= $self->{css_inline} if $self->{css_inline};
    $css .= "\n</style>\n";

    # include external file
    $css .= "<link href='$self->{css_external}' rel='stylesheet' "
        . "type='text/css' />\n"
        if $self->{css_external};

    if ($escape_bool) {
        $css =~ s/\n/\\n/sg;
        $css =~ s/\"/\\\"/g;
    }

    return $css;
}

sub _warn {
    my ( $self, $msg ) = @_;
    my $alias = $self->{alias};
    warn "[$alias] $msg\n" if $self->{verbose};
    $self->{js_log} .= qq|    ${alias}_pre_iframe_queue.push(|
        . qq|"${PACKAGE}-&gt;filter $msg");\n|;
    
    return;
}

sub _switch_function_options {
    my ( $self, $msg ) = @_;
    my $alias = $self->{alias};
    $self->{js_function_names} .= qq|<option value="$msg">$msg|;
    return;
}


1;

__END__

=head1 NAME

JavaScript::XRay - See What JavaScript is Doing

=head1 VERSION

Version 1.22

=head1 SYNOPSIS

 #!/usr/bin/perl
 use strict;
 use warnings;
 use JavaScript::XRay;

 # HTML page with a <head> and <body> tag and some javascript functions
 my $html_page = do { local $/; <> };

 # create a new instance
 my $jsxray = JavaScript::XRay->new();

 # to inline/filter external javascript files you'll need 'abs_uri'
 # my $jsxray = JavaScript::XRay->new( 
 #     abs_uri => $abs_url_or_local_file_path
 # );

 # use switches to change filtering behavior
 # $jsxray->switches( only => 'onData' );

 # use inlining to inline/filter external javascript files
 # $jsxray->inline_methods( 'dir1', 'dir2', \&callback, 'HTTP_GET' );

 # filter page
 print $js_xray->filter($html_page);

=head1 DESCRIPTION

JavaScript::XRay is an HTML source filter.  It was developed as
a tool to help figure out and debug large JavaScript frameworks.  

The main idea is that you hook it into your application framework
and give you the ability to 'flip a switch' an inject a JavaScript
function tracing console into your outgoing page.

=head2 Some of the things it does...

=over 4

=item * Injects an IFrame logging console

It finds the body tag in the document and injects the IFrame just after it
along with all the JavaScript to drive it.  It also provides you with a 
logging function with the same name as your alias (defaults to jsxray)

   jsxray("Hi there");

=item * Scans HTML for JavaScript functions

For each function it finds it inserts a call to this method which logs 
the function call along with the value of the function arguments.

    function sum ( x, y ) {

becomes 

    function sum ( x, y ) {
        jsxray( "sum( " + x + ", " + y + " )" );

so now any call this function and its arguments will get logged to the 
IFrame.

=item * Switches to limit what you log

You can manually B<skip> specific functions, choose to see B<only>
functions you specify, or match functions matching a specified
string. ( see the switchs methods )

=item * Provide execution counts

Provides a method to see how often your functions are being called.  This can
be helpful to target which functions to refactor to increase performance.

=item * Inlines external JavaScript files

If external javascript files are referenced, they can be inlined so they'll
be filtered as well.

=item * Command line script 'jsxray'

Use the command line script 'jsxray' to save and filter local HTML files
to see how things work.  Think reverse engineering. :)

=item * Save the log for later.

You can cut and paste the IFrame to a text file to analyze later by hand 
or munge the results with perl.  Extremely helpful in moments when you 
have a lot of code executing and your just trying to get a handle on
what's happening.

=back

=head1 CONSTRUCTOR

=head2 JavaScript::XRay->new( %hash );

Create a new instance with the following arguments

=over 4

=item * alias

Think of this as a JavaScript namespace.  All injeted JavaScript functions 
and variables are prefixed with this B<alias> to avoid colliding with 
any code that currently exists on your page.  It also is the prefix used for
all the switches to toggle things on and off.

=item * switches

Hash reference containing switches to change filtering behavior.  Actually
just dereferences the hash and passes it onto the 'switches' method.

=item * abs_uri

Used to help find and filter external javascript files.  It can be the 
absolute URL of the requested file via a webserver or the path of the 
file you're filtering from the command line.

=item * iframe_height

The height of your logging IFrame, defaults to 200 pixels.

=item * css_inline

Change the style of the logging IFrame via inline CSS.

=item * css_external

Change the style of the logging IFrame via an external stylesheet.

=item * verbose

Turn on verbose output (bool)

=back

=head1 METHODS

=head2 $jsxray->switches( %switches )

Switches control the behavior of which is going to be filtered and provide
the ability to uncomment debugging code on the fly.

=over 4

=item * all (bool)

Turn on filtering of all functions.  This is the default behavior.

    all => 1

=item * none (bool)

Turn off filtering of functions.  Helpful in combination with uncomment 
switch.

    none => 1

=item * uncomment ( string1, string2, ... )

Uncomment lines prefix with these strings.  Helpful with injecting 
timing code, or more specific debugging code.  You can deploy 
commented logging code to production and turn it on when your 
turn on filtering.  Extremely helpful when diagnosing problems you 
can't reproduce in your development environment.

    uncomment => "DEBUG1,DEBUG3"
    uncomment => [ qw( DEBUG1 DEBUG3 ) ]

will turn this...

    //DEBUG1 jsxray("Hey this is debug1");
    //DEBUG2 jsxray("Hey this is debug2");
    //DEBUG3 jsxray("Hey this is debug3");

into this

    jsxray("Hey this is debug1");
    //DEBUG2 jsxray("Hey this is debug2");
    jsxray("Hey this is debug3");

=item * anon  (bool)

Include filtering of anonymous functions.

    anon => 1

=item * no_exec_count ( bool )

Don't inject code that keeps track of how many times a function was called. 

    no_exec_count => 1

=item * only ( function1, function2, ... )

Only filter comma separated list of functions (function1,function2,...)

    only => "processData,writeToPage"
    only => [ qw( processData writeToPage ) ]

=item * skip ( function1, function2, ... )

Skip comma separated list of functions

    skip => "formatNumber,onData"
    skip => [ qw( formatNumber onData ) ]

=item * match ( /^string/ )

Only filter functions that match string

    match => 'string'           # will result in qr/^string/
    match => qr/whatever/

=back

=head2 $jsxray->inline_methods( @methods );

B<WARNING THIS FUNCTIONALITY IS EXPERIMENTAL AND THE INTERFACE MAY CHANGE>

Take external javascript blocks (use src attribute) and get the 
javascript, filter it, and inline the code.  There are currently 
three supported methods to do this.  

=over 4

=item * HTTP_GET (default)

Special string that represents using LWP::Simple to attempt to fetch 
external javascript.  If the src attribute isn't absolute, then you'll
need to pass the 'abs_uri' in when you create your instance.

=item * File Directory

Base file path to use with the src attribute to load the javascript off
disk.  From a webserver, you'd probably include the web root and from
the commandline, you'd use the path of the file you're filtering.

=item * Code Reference

The arguments to the code reference are the src attribute from the 
javascript attribute and the code block must return the coresponding
code.
    
    $javascript_code = &$code_ref( $src_attr, $abs_uri );

=back

=head2 $jsxray->filter( $html );

Pass HTML in, get modified HTML out.

=head1 AUTHOR

Jeff Bisbee, C<< <jbisbee at cpan.org> >>

=head1 TODO

Some of the things that are still in the conceptional phase

=over 4

=item * Personal proxy

Include a personal proxy script with this module so you can filter 
ANY webpage you go to.

=item * Add a user interface to the console to control the switches

Add a form to the console that will allow you to see the values of the
switches and then resubmit the url to have the changes take affect.

=item * Add .toSource to objects when logging (or a switch to turn it on)

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-JavaScript-xray at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-XRay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JavaScript::XRay

You can also look for information at:

=over 4

=item * JavaScript::XRay development mailing list

L<http://groups.google.com/group/jsxray-dev>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JavaScript-XRay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JavaScript-XRay>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JavaScript-XRay>

=item * Search CPAN

L<http://search.cpan.org/dist/JavaScript-XRay>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Senta Mcadoo

Providing the JavaScript DOM logging code in order to do the reverse logging
(solved the scrolling problem).

=item * Ronnie Paskin

General hacking on the code, good feedback, and for being a sounding board 
to work out issues.

=item * Tony Fernandez

Giving me the green light to publish this on the CPAN.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jeff Bisbee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

