package HTML::SearchPage;

our $VERSION = '0.05';

# $Id: SearchPage.pm,v 1.24 2007/09/19 21:30:18 canaran Exp $

use warnings;
use strict;

use HTML::SearchPage::Files;

use Carp;
use CGI;
use CGI::Session;
use DBI;
use List::Util qw(first);
use LWP::Simple;
use Spreadsheet::WriteExcel;
use Tie::IxHash;
use Time::Format qw(%time);

###############
# CONSTRUCTOR #
###############

sub new {
    my ($class, %raw_params) = @_;

    # Remove dashes from param names
    my %params = map {
        my $key   = $_;
        my $value = $raw_params{$key};
        $key =~ s/^-//;
        $key => $value;
    } keys %raw_params;

    my $self = bless {}, $class;

    eval {

        # CGI obj created initially
        my $cgi = CGI->new;
        $self->cgi($cgi);

        my $cgi_params = $self->cgi->Vars;
        $self->cgi_params($cgi_params);

        # Temp dir
        $params{temp_dir} or croak("A temp_dir param is required!");
        $self->temp_dir($params{temp_dir});

        $params{temp_dir_eq} or croak("A temp_dir_eq param is required!");
        $self->temp_dir_eq($params{temp_dir_eq});

        # Cookie params
        my $cookie =
          defined $params{cookie} ? $params{cookie} : 'html-searchpage';
        $self->cookie($cookie);

        my $cookie_expires_in_min =
          defined $params{cookie_expires_in_min} 
          ? $params{cookie_expires_in_min} 
          : 30;
        $self->cookie_expires_in_min($cookie_expires_in_min);

        # Session id from URL/cookie
        my $session_id = 
               $self->cgi_params->{session_id}
            || $self->cgi->cookie($self->cookie)
            || undef;

        my $session_dir = $self->temp_dir . '/sessions';
        my $session =
          CGI::Session->new('file', $session_id, {Directory => $session_dir});

        # Session id may change at this step
        $self->session_id($session->id);
        $self->session($session);

        # Required params
        $params{db_access_params} or croak("A db_access_params is required!");
        $self->db_access_params($params{db_access_params});

        $params{temp_dir} or croak("A temp_dir param is required!");
        $self->temp_dir($params{temp_dir});

        $params{temp_dir_eq} or croak("A temp_dir_eq param is required!");
        $self->temp_dir_eq($params{temp_dir_eq});

        $params{base_sql_table} or croak("A base_sql_table is required!");
        $self->base_sql_table($params{base_sql_table});

        $params{base_sql_fields} or croak("A base_sql_fields is required!");
        $self->base_sql_fields($params{base_sql_fields});

        $params{base_output_headers}
          or croak("A base_output_headers is required!");
        $self->base_output_headers($params{base_output_headers});

        # Create image files
        HTML::SearchPage::Files->new(temp_dir => $self->temp_dir);

        # Required param for only display_info
        $self->base_identifier($params{base_identifier});

        # Optional params
        my $page_title =
          defined $params{page_title} ? $params{page_title} : 'Search Page';
        $self->page_title($page_title);

        $self->header($params{header});

        $self->footer($params{footer});

        $self->css($params{css});

        $self->instructions($params{instructions});

        $self->distinct($params{distinct});

        $self->no_reset($params{no_reset});

        $self->new_search($params{new_search});

        $self->group_by($params{group_by});

        $self->sort_fields($params{sort_fields});

        $self->sort_defaults($params{sort_defaults});

        my $method = defined $params{method} ? $params{method} : 'GET';
        $self->method($method);
        unless ($method eq 'GET' or $method eq 'POST') {
            croak("Invalid method ($method)!");
        }

        my $action =
          defined $params{action} ? $params{action} : $ENV{SCRIPT_NAME};
        $self->action($action);

        my $page_size = defined $params{page_size} ? $params{page_size} : 50;
        $self->page_size($page_size);

        $self->show_search_url($params{show_search_url});

        $self->debug_level($params{debug_level});

        my $go_to_results =
          defined $params{go_to_results} ? $params{go_to_results} : 1;
        $self->go_to_results($go_to_results);

        $self->modifier($params{modifier});

        $self->external_where_clauses($params{external_where_clauses});

        # If reset, empty cgi_params
        if ($self->cgi_params->{reset}) {
            $self->cgi_params({});
        }

        # If new search, redirect
        if ($self->cgi_params->{new_search}) {
            my $url = "http://" . $ENV{HTTP_HOST} . $self->new_search;
            print $self->cgi->redirect($url);
            exit 0;
        }

        # Calculate super headers
        $self->_calculate_super_headers();

        # Validate cgi params
        $self->_validate_cgi_params();

        # Create db_handle from db_access_params
        my $db_access_params = $self->db_access_params;

        # -- Re-format if a single db is entered
        if (    ref($db_access_params)
            and ref($db_access_params) eq 'ARRAY') {
            my ($datasource, $username, $password) = @$db_access_params;
            my $db_access_params = {
                database => [
                    {   alias      => 'default',
                        display    => 'Default Database',
                        datasource => $datasource,
                        username   => $username,
                        password   => $password,
                    }
                ]
            };
        }
        $self->db_access_params($db_access_params);

        # -- Extract params
        my $database = 
               $self->cgi_params->{database}
            || $self->session->param('db_selected');
        
        my @available_databases = (   ref $db_access_params->{database} 
                                   && ref $db_access_params->{database} eq 'ARRAY') 
                                ? @{$db_access_params->{database}}
                                : ($db_access_params->{database});

        unless (@available_databases) {
            croak("No database specified!");
        }

        if (!$database) {
            $database = $available_databases[0]->{alias};
        }

        my $selected_db =
          first { $_->{alias} eq $database } @available_databases;

        if (!defined($selected_db)) {
            croak("Cannot determine database ($database)!");
        }

        my $dbh = DBI->connect(
            $selected_db->{datasource},
            $selected_db->{username}, $selected_db->{password},
            {PrintError => 1, RaiseError => 1}
        ) || croak("Cannot connect to database!");

        $self->dbh($dbh);
        $self->db_selected($database);
        $self->db_display($selected_db->{display});
        
        $self->session->param('db_selected', $database);

        # Adjust URL if "go_to_results"
        if ($self->go_to_results) {
            my $action = $self->action;
            $self->action("$action#results");
        }

        # Create an empty param_fields container
        $self->{param_fields} = {};

        # Create an empty modifications container
        $self->{modifications} = [];
    };

    $self->display_error_page($@) if $@;

    return $self;
}

##################
# PUBLIC METHODS #
##################

# Function  : Adds/retrieves param_field.
# Arguments : $id [$ParamField_object]
# Returns   : $ParamField_object
# Notes     : None specified.

sub param_field {
    my ($self, $id, $value) = @_;
    if (defined $value) {
        croak(
            "A HTML::SearchPage::Param object is needed to add param_field!")
          unless ref $value eq 'HTML::SearchPage::Param';

        my $max = 0;

        foreach (keys %{$self->param_fields}) {
            my $pf = $self->param_fields->{$_};
            $max = $pf->rank if $pf->rank > $max;
        }

        $value->rank(++$max);

        $self->param_fields->{$id} = $value;
    }

    croak("This param_field ($id) does not exist!")
      unless exists $self->param_fields->{$id};

    return $self->param_fields->{$id};
}

# Function  : Adds modification.
# Arguments : $hashref
# Returns   : 1
# Notes     : None specified.

sub add_modification {
    my ($self, %value) = @_;

    croak("A modification hashref is needed!") unless %value;

    push @{$self->modifications}, \%value;

    return 1;
}

# Function  : Performs the necessary operations and
#             displays a complete search page.
# Arguments : None
# Returns   : 1
# Notes     : None specified.

sub display_page {
    my ($self) = @_;

    my $submit = $self->cgi_params->{'submit'};

    eval {
        $self->_generate_search_form unless $self->search_form;
        $self->_generate_sql_statements
          if ($submit and !$self->query_sql_statement);
        $self->_get_debug_info if $self->debug_level;
        $self->_retrieve_data  if ($submit and !$self->data);
        $self->_retrieve_count if ($submit and !(defined $self->count));
        $self->_format_data    if ($submit and !$self->formatted_data);
    };

    $self->display_error_page($@) if $@;

    eval { $self->_print_page; };

    $self->display_error_page($@) if $@;

    return 1;
}

# Function  : Generates an error page.
# Arguments : $error
# Returns   : - exists with 0 -
# Notes     : None specified.

sub display_error_page {
    my ($self, $error) = @_;

    my $cookie                 = $self->cookie;
    my $session_id             = $self->session_id;
    my $cookie_expires_in_min  = $self->cookie_expires_in_min;

    my $cookie_obj = CGI::cookie(
        -name    => $cookie,
        -value   => $session_id,
        -expires => "+${cookie_expires_in_min}m",
    );

    print $self->cgi->header(-cookie => $cookie_obj);

    my $header = $self->_content($self->header);
    my $css    = $self->_content($self->css);
    my $page_title =
      $self->page_title ? 'Error: ' . $self->page_title : 'Error Page';
    my $instructions = $self->_content($self->instructions);
    my $debug_info   = $self->debug_info;
    my $footer       = $self->_content($self->footer);
    my $temp_dir_eq  = $self->temp_dir_eq;

    print <<HTML;
<html>
    <head>
    <title>$page_title</title>
    <link rel="stylesheet" type="text/css" href="$temp_dir_eq/searchpage-main.css" />
    $css
    </head>

    <body>
    <table border="0" width="100%">
    <tr><td colspan="2">$header</td></tr>
    <tr><td colspan="2"><h1>$page_title</h1></td></tr>
    <tr><td width="60%"><b>An error occured: $error</b></td><td width="40%">&nbsp;</td></tr>
    <tr><td colspan="2">&nbsp;</td></tr>
    <tr><td colspan="2" align="center">$debug_info</td></tr>
    <tr><td colspan="2">$footer</td></tr>
    </table>
    </body>
</html>
HTML

    exit 0;
}

# Function  : Performs the necessary operations and displays a complete info page.
# Arguments : None
# Returns   : 1
# Notes     : None specified.

sub display_info {
    my ($self) = @_;

    # This display is *not* interactive, no search form is provided
    # "submit" is assumed, no need to check for it

    # We must have an identifier provided
    my $identifier = $self->cgi_params->{'identifier'};
    $self->display_error_page('A valid identifier is required!')
      unless defined $identifier;

    # Automatically set parameter field
    my $base_identifier = $self->base_identifier;
    $self->display_error_page('A base_identifier is not specified!')
      unless defined $base_identifier;
    my $pf = HTML::SearchPage::Param->new(
        -sql_column => $base_identifier,
        -form_name  => 'identifier',
        -param_type => 'text:12',       # place-holder
    ) or $self->display_error_page($@);
    $self->param_field('identifier', $pf);

    # We set the "identifier_operator" to "equals" by default
    $self->cgi_params->{'identifier_operator'} = '=';

    # We set the "output_format" to "html" by default
    $self->cgi_params->{'output_format'} = 'html';

    eval {

        # -> do not generate search form
        $self->_generate_sql_statements if !$self->query_sql_statement;
        $self->_get_debug_info          if $self->debug_level;
        $self->_retrieve_data           if !$self->data;
        $self->_retrieve_count          if !(defined $self->count);

        # We have to retrieve one and only one record
        if ($self->count == 0) {
            $self->display_error_page(
                "Cannot find identifier ($identifier)!");
        }
        if ($self->count > 1) {
            $self->display_error_page(
                "Multiple records found for identifier ($identifier)!");
        }

        #Use different method to format data
        $self->_format_vertical_data if !$self->formatted_data;
    };

    $self->display_error_page($@) if $@;

    eval { $self->_print_page; };

    $self->display_error_page($@) if $@;

    return 1;
}

# Function  : Retrieves values for a distinct statement.
# Arguments : $statement
# Returns   : @columns
# Notes     : None specified.

sub run_distinct_statement {
    my ($self, $statement) = @_;

    my $dbh = $self->dbh;

    my $sth = $dbh->prepare($statement) or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);

    my @columns;
    while (my ($value) = $sth->fetchrow_array) { push @columns, $value; }

    $sth->finish or croak($dbh->errstr);

    return @columns;
}

# Function  : URL-encodes a given string.
# Arguments : $string
# Returns   : $url_encoded_string
# Notes     : This is a private method.

sub url_encode {
    my ($self, $string) = @_;

    $string =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

    return $string;
}

# Function  : URL-decodes a given string.
# Arguments : $string
# Returns   : $url_decoded_string
# Notes     : This is a private method.

sub url_decode {
    my ($self, $string) = @_;

    $string =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg if $string;

    return $string;
}

###########################
# PRIVATE/UTILITY METHODS #
###########################

# Function  : Parse base_output_headers for super headers,
#             store in base_super_headers as an array.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _calculate_super_headers {
    my ($self) = @_;

    my $headers = $self->base_output_headers;

    my %super_headers;

    my $current_group        = 0;
    my $current_super_header = qq[];

    foreach my $pos (0 .. $#{@$headers}) {
        my $super_header = qq[];
        $super_header = $1 if $headers->[$pos] =~ s/^([^~]*)~//;

        if ($super_header && $super_header eq $current_super_header) {
            push @{$super_headers{$current_group}{headers}}, $headers->[$pos];
            $super_headers{$current_group}{colspan}++;
        }

        else {
            $current_group++;
            $current_super_header = $super_header;

            $super_headers{$current_group}{super_header} = $super_header;
            push @{$super_headers{$current_group}{headers}}, $headers->[$pos];
            $super_headers{$current_group}{colspan}++;
        }
    }

    $self->super_output_headers(\%super_headers);

    return 1;
}

# Function  : Validates CGI params. Checks the CGI parameters
#             passed on as a hashref and croaks
#             if an error is found.
# Arguments : \%cgi
# Returns   : 1
# Notes     : This is a private method.

sub _validate_cgi_params {
    my ($self) = @_;

    my $cgi_params = $self->cgi_params;

    my %validated_cgi_params = %{$cgi_params};

    my @fields = @{$self->base_output_headers};

    my %allowed_order_by_fields;
    foreach my $field (@fields) {
        my ($column_name, $order_by_field) = split(':', $field);
        if ($order_by_field) {
            $allowed_order_by_fields{$self->url_decode($order_by_field)} = 1;
        }
    }

    $allowed_order_by_fields{asc}          = 1;
    $allowed_order_by_fields{desc}         = 1;
    $allowed_order_by_fields{not_selected} = 1;

    my %allowed_operators = (
        '='          => 1,
        'like_m'     => 1,
        'like_c'     => 1,
        '>'          => 1,
        '>='         => 1,
        '<'          => 1,
        '<='         => 1,
        '<>'         => 1,
        'not_like_m' => 1,
        'not_like_c' => 1,
    );

    my %allowed_output_formats = (
        'html'  => 1,
        'csv'   => 1,
        'tab'   => 1,
        'text'  => 1,
        'excel' => 1,
    );

    foreach my $key (keys %$cgi_params) {
        unless ($cgi_params->{$key} or $cgi_params->{$key} eq '0') {
            $cgi_params->{$key} = undef;
            next;
        }

        my @value = split("\0", $cgi_params->{$key});

        foreach (@value) {
            $_ =~ s/^\s+//;
            $_ =~ s/\s+$//;

            # Check all values against this
            if ($_ =~ /[^A-Za-z0-9\-\_\?\*\.\%\(\)\,\'\+\=\:\# ]/
                and !$allowed_operators{$_}) {
                croak("Illegal character in value ($key:$_)!");
            }

            # Check individual values
            if ($key =~ /_operator$/) {
                croak("Illegal operator ($key:$_)!")
                  unless $allowed_operators{$_};
            }

            elsif ($key eq 'order_by') {
                my $lc_cgi_value = lc $_;
                croak("Invalid order by column ($key:$_)!")
                  unless ($allowed_order_by_fields{$_}
                    or $allowed_order_by_fields{$lc_cgi_value});
            }

            elsif ($key eq 'output_format') {
                croak("Invalid output format($key:$_)!")
                  unless $allowed_output_formats{$_};
            }
        }
        $validated_cgi_params{$key} = @value > 1 ? \@value : $value[0];

        # (Array memory location stringified if passed to $cgi_params)
    }

    $self->cgi_params(\%validated_cgi_params);

    return 1;
}

# Function  : Generates and stores the HTML code for the
#             search form component.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _generate_search_form {
    my ($self) = @_;

    # Assign form information
    my $dbh    = $self->dbh;
    my $action = $self->action;
    my $method = $self->method;
    my $cgi    = $self->cgi_params;

    my $database = $self->cgi_params->{database};

    my @order_by = @{$self->cgi_params->{order_by}}
      if $self->cgi_params->{order_by};
    my $sort_fields         = $self->sort_fields;
    my @sort_defaults       = @{$self->sort_defaults} if $self->sort_defaults;
    my @base_output_headers = @{$self->base_output_headers};

    my $reset_button =
      $self->new_search
      ? qq[&nbsp; <input type="submit" name="new_search" value="New Search"></input>]
      : !$self->no_reset
      ? qq[&nbsp; <input type="submit" name="reset" value="Reset"></input>]
      : qq[];
    my $db_selector = $self->_make_db_selector;

    my @field_sections;

    foreach my $id (
        sort { $self->param_field($a)->rank <=> $self->param_field($b)->rank }
        keys %{$self->param_fields}
      ) {
        my $pf = $self->param_field($id);

        my $field_section;

        # Assign field information
        my $label            = $pf->label;
        my $sql_column       = $pf->sql_column;
        my $form_name        = $pf->form_name;
        my @operator_list    = @{$pf->operator_list} if $pf->operator_list;
        my $operator_display = $pf->operator_display;
        my $disabled         = $pf->disabled;
        my $operator_default = $pf->operator_default || qq[];
        my $case_sensitive   = $pf->case_sensitive;
        my $exact            = $pf->exact;
        my $numerical        = $pf->numerical;
        my $param_type       = $pf->param_type;
        my @param_list       = @{$pf->param_list} if $pf->param_list;
        my $auto_all         = $pf->auto_all;
        my $auto_null        = $pf->auto_null;
        my $param_default    = $pf->param_default || qq[];

        #        my %param_default;
        #        foreach (@param_default) {
        #            $param_default{$_} = 1 if $_;
        #        }

        # Adjustments

        # (i) Resolve DISTINCT statements in param_list
        my @resolved_param_list;
        foreach my $param_statement (@param_list) {
            if ($param_statement && $param_statement =~ s/^DISTINCT://) {
                my @resolved_params =
                  $self->run_distinct_statement($param_statement);
                foreach (@resolved_params) {
                    next if !defined $_;
                    $_ = $self->url_encode($_);
                    push(@resolved_param_list, $_);
                }
            }
            else { push(@resolved_param_list, $param_statement); }
        }
        @param_list = @resolved_param_list;
        $pf->param_list(\@param_list);

        # (ii) Append AUTO NULL AND ALL to param list
        unshift @param_list, 'null:NULL' if $auto_null;
        unshift @param_list, 'all:ALL'   if $auto_all;

        # Make sure param_list is populated 
        if (   $param_type eq 'drop_down'
            or $param_type =~ /^scrolling_list:\d+$/) {
            croak("Parameter field ($label) has empty param_list!") 
                unless @param_list;
        }                               
        
        # (iii) Auto-complete display names for param_list
        foreach (@operator_list, @param_list) { 
            $_ = "$1:$1" if ($_ && $_ =~ /^([^:]+)$/); 
        }

        # Prepare operator section
        my $operator_section;

        if (@operator_list > 1) {
            $operator_section .= qq[<select name="${form_name}_operator">\n];
            foreach (@operator_list) {
                my ($operator, $display) = split(':', $_);
                $operator = $self->url_decode($operator) || qq[];
                $display  = $self->url_decode($display)  || qq[];

                my $selected = qq[];
                if (   defined $cgi->{$form_name}
                    && defined $cgi->{"${form_name}_operator"}
                    && $cgi->{"${form_name}_operator"} eq $operator) {
                    $selected = 'selected';
                }
                elsif ($operator eq $operator_default
                    && !defined $cgi->{$form_name}) {
                    $selected = 'selected';
                }

                $operator_section .=
                  qq[<option $selected value="$operator">$display</option>\n];
            }
            $operator_section .= qq[</select>\n];
        }

        elsif (@operator_list == 1) {
            my ($operator, $display) = split(':', $operator_list[0]);
            $operator = $self->url_decode($operator);
            $display  = $self->url_decode($display);

            my ($field_type, $disabled) =
              $operator_display ? ('text', 'disabled') : ('hidden', qq[]);
            $operator_section .=
              qq[<input type="$field_type" name="${form_name}_operator" value="$operator" $disabled>&nbsp;</input>\n];
        }

        else { croak("No opearator specified (form field: $form_name)!"); }

        # Prepare param section
        my $param_section;

        if (   $param_type eq 'drop_down'
            or $param_type =~ /^scrolling_list:\d+$/) {
            if ($param_type eq 'drop_down') {
                $param_section .= qq[<select name="$form_name">\n];
            }
            elsif ($param_type =~ /^scrolling_list:(\d+)$/) {
                $param_section .=
                  qq[<select name="$form_name" size="$1" multiple>\n];
            }

            my @values;
            if (defined $cgi->{$form_name}) {
                @values =
                  ref $cgi->{$form_name}
                  ? @{$cgi->{$form_name}}
                  : ($cgi->{$form_name});
            }
            my %values = map { ($_, 1) } @values;

            foreach (@param_list) {
                my ($param, $display) = split(':', $_);
                $param   = $self->url_decode($param);
                $display = $self->url_decode($display);

                my $selected = ' ';
                if (@values and $values{$param}) { $selected = 'selected'; }
                elsif (!@values and $param_default eq $param) {
                    $selected = 'selected';
                }

                $param_section .=
                  qq[<option $selected value="$param">$display</option>\n];
            }
            $param_section .= qq[</select>\n];
        }

        elsif ($param_type =~ /^text:(\d+)$/) {
            my $field_size = $1;

            my $value = qq[];
            if ($cgi->{"${form_name}"} and ($cgi->{"${form_name}"} ne 'all'))
            {
                $value = $cgi->{"${form_name}"};
            }
            elsif ($param_default && $param_default ne 'all') {
                $value = $param_default;
            }

            my $disable_status = $disabled ? qq[disabled="1"] : qq[];

            $param_section .=
              qq[<input type="text" name="$form_name" value="$value" size="$field_size" maxlength="$field_size" $disable_status></input>\n];
        }

        else {
            croak(
                "Invalid param field type designation ($form_name : $param_type)!"
            );
        }

        $field_section .=
          qq[<tr><td align="left" width="50%"><b>$label</b></td><td align="left" width="25%">$operator_section</td><td align="left" width="25%">$param_section</td></tr>\n];

        push @field_sections, $field_section;
    }

    my @order_by_sections;

    my @sortable_fields = ('-- Select --:not_selected');
    foreach (@base_output_headers) { push @sortable_fields, $_ if /:/; }

    foreach my $i (1 .. $sort_fields) {
        my $label = "Sort by (\#$i):";

        # Direction
        my $direction = lc(shift @order_by);
        if ($direction and !($direction =~ /^asc$/ or $direction =~ /^desc$/))
        {
            croak("Illegal direction (order_by) param ($direction)!");
        }

        my $direction_default = lc(shift @sort_defaults);
        if ($direction_default
            and !(
                   $direction_default =~ /^asc$/
                or $direction_default =~ /^desc$/
            )
          ) {
            croak(
                "Illegal direction (sort_defaults) param ($direction_default)!"
            );
        }

        my $direction_selected =
            $direction         ? $direction
          : $direction_default ? $direction_default
          :                      qq[];

        my $direction_section = $self->_make_select(
            'order_by', [qw(ascending:asc descending:desc)],
            $direction_selected
        );

        # Field
        my $field         = shift @order_by;
        my $field_default = shift @sort_defaults;
        my $field_selected =
            $field         ? $field
          : $field_default ? $field_default
          :                  'not_selected';
        my $field_section =
          $self->_make_select('order_by', \@sortable_fields, $field_selected);

        # Order by
        my $order_by_section =
          qq[<tr><td align="left" width="50%"><b><i>$label</i></b></td><td align="left" width="25%">$direction_section</td><td align="left" width="25%">$field_section</td></tr>\n];
        push @order_by_sections, $order_by_section;
    }

    # Render complete HTML form
    my $search_form;

    $search_form .= <<HTML;
<form method="$method" action="$action">
<table border="0" align="center" width="100%" cellpadding="1" cellspacing="1">
HTML

    $search_form .= $db_selector;

    $search_form .= join("\n", @field_sections);

    $search_form .= <<HTML;
<tr>
<td align="left">&nbsp;</td>
<td align="left">&nbsp;</td>
<td align="left">&nbsp;</td>
</tr>
HTML

    $search_form .= join("\n", @order_by_sections);

    $search_form .= <<HTML;
<tr>
<td align="left"><b><i>Output Format:</i></b></td>
<td align="left">&nbsp;</td>
<td align="left">
<select name="output_format">
<option selected value="html">HTML</option>
<option          value="excel">Excel</option>
<option          value="text">text (fixed-width)</option>
<option          value="csv">csv (comma-separated)</option>
<option          value="tab">tsv (tab-delimited)</option>
</select>
</td>
</tr>

<tr>
<td align="left">&nbsp;</td>
<td align="center" colspan="2">
&nbsp;&nbsp;
<input type="submit" name="submit" value="Submit"></input>
$reset_button
</td>
</tr>

</table>
</form>

<script type="text/javascript">
<!--
document.getElementById("javascript_warning").deleteRow(0)
-->
</script>
HTML

    # Store in the object
    $self->search_form($search_form);

    return 1;
}

# Function  : Returns a select box.
# Arguments : $name, \@fields, $selected
# Returns   : $html
# Notes     : This is a private method.
#             Members of @fields are
#             in the format: "<display>:<value>"

sub _make_select {
    my ($self, $name, $fields_ref, $selected) = @_;
    my @fields_ref = @$fields_ref;

    my $html;

    $html .= qq[<select name="$name">\n];

    foreach (@$fields_ref) {
        my ($display, $field) = split(':', $_);
        my $selected_switch = $field eq $selected ? 'selected' : qq[];
        $html .=
          qq[<option $selected_switch value="$field">$display</option>\n];
    }

    $html .= qq[</select>\n];

    return $html;
}

# Function  : Returns a db selection box.
# Arguments :
# Returns   : $html
# Notes     : This is a private method.

sub _make_db_selector {
    my ($self) = @_;

    my $db_access_params = $self->db_access_params;
    my $database         = $self->db_selected;

    my @available_databases =
      (       ref($db_access_params->{database})
          and ref($db_access_params->{database}) eq 'ARRAY')
      ? @{$db_access_params->{database}}
      : ($db_access_params->{database});
    my $html;

    if (@available_databases > 1) {
        my $select;

        $select .=
          qq[<select id="db_selector" name="database" onchange="select_db()">\n];
        foreach my $available_database (@available_databases) {
            my $alias           = $available_database->{alias};
            my $display         = $available_database->{display};
            my $selected_switch = $alias eq $database ? 'selected' : qq[];
            $select .=
              qq[<option $selected_switch value="$alias">$display</option>\n];
        }
        $select .= qq[</select>\n];

        $html = <<HTML;
<tr>
<td align="left"><b><i>Database:</i></b></td>
<td align="left">&nbsp;</td>
<td align="left">
<script type="text/javascript">
<!--
function select_db()
{
var database=document.getElementById("db_selector").value
var target_url= location.pathname + "?database=" + database
window.location=target_url
}
-->
</script>
$select
</td>
</tr>

<tr>
<td align="left" colspan="3">

<table id="javascript_warning" width="100%">
<tr>
<td>
<a style="color:red; font-style:italic">
(Javascript must be enabled for automatic refresh!)</a>
</td>
</tr>
</table>

</td>
</tr>

<tr>
<td align="left">&nbsp;</td>
<td align="left">&nbsp;</td>
<td align="left">&nbsp;</td>
</tr>
HTML

    }

    else {
        $html .=
          qq[<input type="hidden" name="database" value="$database"/></input>\n];
    }

    return $html;
}

# Function  : Generates and stores the relevant SQL statements
#             (query and count).
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _generate_sql_statements {
    my ($self) = @_;

    my $base_sql_table = $self->base_sql_table;
    my $page_size      = $self->page_size;

    my $current_page =
        $self->cgi_params->{page}
      ? $self->cgi_params->{page}
      : 1;    # Page defaults to 1

    my $output_format = $self->cgi_params->{output_format};

    my $group_by = $self->group_by;

    my @fields = @{$self->base_sql_fields};
    my $distinct = $self->distinct ? 'distinct' : qq[];
    my @where_clauses;
    my @order_by_clauses
      ; # Currently only a single sort column is supported although data is stored in a list
    my $limit_clause;

    # Assign CGI information and clean values
    my @order_by = @{$self->cgi_params->{"order_by"}}
      if $self->cgi_params->{"order_by"};

    foreach my $id (sort keys %{$self->param_fields}) {
        my $pf = $self->param_field($id);

        # Assign field information
        my $param_type     = $pf->param_type;
        my $sql_column     = $pf->sql_column;
        my $form_name      = $pf->form_name;
        my $case_sensitive = $pf->case_sensitive;
        my $exact          = $pf->exact;
        my $numerical      = $pf->numerical;

        # Skip this ParamField if sql_column is 'INDEPENDENT'
        next if $sql_column eq 'INDEPENDENT';

        # Assign CGI information and clean values
        my $value    = $self->cgi_params->{$form_name};
        my $operator = $self->cgi_params->{"${form_name}_operator"};

        # Add the field to the WHERE <SOMETHING> segment if it is defined, observe additional rules
        if (defined $value
            and ($value or $value eq '0')
            && $param_type =~ /^scrolling_list:\d+$/) {
            my @values = ref $value ? @$value : ($value);

            if (($operator eq '<>' or $operator =~ /^not_/)
                and $self->_ary_exists(\@values, 'all')) {
                croak("Negation operators cannot be used with value ALL!");
            }

            unless ($self->_ary_exists(\@values, 'all')) {
                my @in_where_clauses;

                foreach my $value (@values) {
                    push @in_where_clauses,
                      $self->_make_where_clause($operator, $value, $pf);
                }

                if ($operator eq '<>' or $operator =~ /^not_/) {
                    push @where_clauses,
                      "(" . join(" AND ", @in_where_clauses) . ")";
                }
                else {
                    push @where_clauses,
                      "(" . join(" OR ", @in_where_clauses) . ")";
                }
            }
        }

        elsif (($operator eq '<>' or $operator =~ /^not_/)
            and $value eq 'all') {
            croak("Negation operators cannot be used with value ALL!");
        }

        elsif ( defined $value
            and ($value or $value eq '0')
            and $value ne 'all') {
            croak("Operator is not specified for field ($form_name)!")
              unless defined $operator;

            push @where_clauses,
              $self->_make_where_clause($operator, $value, $pf);
        }
    }

    # Add external WHERE clause rule
    my @external_where_clauses = @{$self->external_where_clauses}
      if $self->external_where_clauses;
    push @where_clauses, @external_where_clauses;

    # Add the field to ORDER BY <SOMETHING>
    while (@order_by) {
        my $direction = shift @order_by;
        my $field     = shift @order_by;
        croak("Invalid order direction ($direction)!")
          unless ($direction eq 'asc' or $direction eq 'desc');

        push @order_by_clauses, "$field $direction"
          if ($field and $field ne 'not_selected');
    }

    # Add LIMIT section (for pagination)
    my $limit_start = ($current_page - 1) * $page_size;
    $limit_clause = "LIMIT $limit_start, $page_size";

    # Generate query SQL statement
    my $query_sql_statement = "SELECT $distinct " . join(", ", @fields);
    $query_sql_statement .= " FROM " . $base_sql_table;
    $query_sql_statement .= " WHERE " . join(" AND ", @where_clauses)
      if @where_clauses;
    $query_sql_statement .= " GROUP BY " . $group_by if $group_by;
    $query_sql_statement .= " ORDER BY " . join(", ", @order_by_clauses)
      if @order_by_clauses;
    $query_sql_statement .= " " . $limit_clause if $output_format eq 'html';

    # Generate count SQL statement
    my $count_sql_statement = "SELECT COUNT(*) FROM (";

    # Mysql 5 complains about duplicate column names in select ocunt(*)
    # Added placeholder aliases
    my @aliased_fields;
    foreach my $i (0 .. $#fields) {
        push @aliased_fields, $fields[$i] . " as alias$i";
    }

    $count_sql_statement .= "SELECT $distinct " . join(", ", @aliased_fields);
    $count_sql_statement .= " FROM " . $base_sql_table;
    $count_sql_statement .= " WHERE " . join(" AND ",        @where_clauses)
      if @where_clauses;
    $count_sql_statement .= " GROUP BY " . $group_by if $group_by;
    $count_sql_statement .= ") a";

    # Store in the object
    $self->query_sql_statement($query_sql_statement);
    $self->count_sql_statement($count_sql_statement);

    return 1;
}

# Function  : Return whether the query exists in the ary
# Arguments : $aryref, $query
# Returns   : undef | 1
# Notes     : This is a private method.

sub _ary_exists {
    my ($self, $ary, $query) = @_;

    foreach (@$ary) { return 1 if $_ eq $query; }

    return;
}

# Function  : Generates WHERE clause for the SQL statement.
# Arguments : $operator, $value, $ParamField
# Returns   : $where_clause
# Notes     : This is a private method.

sub _make_where_clause {
    my ($self, $operator, $value, $pf) = @_;

    my $dbh = $self->dbh;

    my $sql_column     = $pf->sql_column;
    my $case_sensitive = $pf->case_sensitive;
    my $numerical      = $pf->numerical;

    my $where_clause;

    if ($value eq 'null') {
        if (   $operator eq '='
            or $operator eq 'like_m'
            or $operator eq 'like_c') {
            $where_clause = qq[$sql_column IS NULL];
        }
        elsif ($operator eq '<>'
            or $operator eq 'not_like_m'
            or $operator eq 'not_like_c') {
            $where_clause = qq[$sql_column IS NOT NULL];
        }
        else {
            croak(
                "Unable to process reserved keyword null, invalid operator ($operator)!"
            );
        }
    }

    else {
        if ($operator eq 'like_c') {
            $operator = 'like';
            $value    = qq[%$value%];
            $value    = $dbh->quote($value);
        }
        elsif ($operator eq 'like_m') {
            $operator = 'like';
            $value =~ s/\*/%/g;
            $value =~ s/\?/_/g;
            $value = $dbh->quote($value);
        }
        else { $value = $numerical ? qq[$value] : qq["$value"]; }

        $value = qq[BINARY $value] if $case_sensitive;
        $where_clause = qq[$sql_column $operator $value];
    }

    return $where_clause;
}

# Function  : Executes the query SQL statement, retrieves and stores the raw data.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _retrieve_data {
    my ($self) = @_;

    my $dbh       = $self->dbh;
    my $statement = $self->query_sql_statement
      || croak("No pre-set (query) SQL statement!");

    my @data;

    my $sth = $dbh->prepare($statement)
      || croak("Cannot prepare statement ($statement)!");
    $sth->execute() || croak("Cannot execute statement ($statement)!");

    while (my @row = $sth->fetchrow_array) { 
        foreach (@row) {
            $_ = '' unless defined $_;
        }    
        push @data, \@row; 
    }

    # Store in the object
    $self->data(\@data);

    return 1;
}

# Function  : Executes the count SQL statement, retrieves
#             and stores the data count.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _retrieve_count {
    my ($self) = @_;

    my $dbh       = $self->dbh;
    my $statement = $self->count_sql_statement
      || croak("No pre-set (count) SQL statement!");

    my $sth = $dbh->prepare($statement)
      || croak("Cannot prepare statement ($statement)!");
    $sth->execute() || croak("Cannot execute statement ($statement)!");

    my ($count) = $sth->fetchrow_array;

    # Store in the object
    $self->count($count);

    return 1;
}

# Function  : Compiles debug info and stores in object.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _get_debug_info {
    my ($self) = @_;

    my $debug_level = $self->debug_level;

    my $dbh   = $self->dbh;
    my $alias = $self->db_selected;
    my ($database_name) = $dbh->{Name} =~ /database=([^;]+)/;

    my $datasource_info = qq[alias=$alias; database_name=$database_name];

    my $html;

    my $debug_info = qq[];

    if ($debug_level > 0) {
        my $time_stamp = $time{'dd-Mon-yyyy hh:mm:ss tz'};

        my $url = $ENV{HTTP_HOST} . $ENV{REQUEST_URI};

        my @software;
        foreach my $file (
            $0, $INC{'HTML/SearchPage/Param.pm'},
            $INC{'HTML/SearchPage.pm'},
          ) {
            my ($id) = $self->_get_version_information($file);
            my ($file_name) = $file =~ /([^\/]+)$/;
            push(@software, "SW: $file_name", $id);
        }

        my $query_sql_statement = $self->query_sql_statement;
        my $count_sql_statement = $self->count_sql_statement;

        $debug_info .= '<p>'
          . $self->_format_box(
            'VERSION & PROCESSING INFORMATION',
            'URL',  $url,
            'Time', $time_stamp,
            @software,
            'Datasource',          $datasource_info,
            'Query SQL Statement', $query_sql_statement,
            'Count SQL Statement', $count_sql_statement,
          );
    }

    if ($debug_level > 1) {
        $debug_info .= '<p>' . $self->_format_box('ENVIRONMENT', %ENV);
    }

    # Store in the object
    $self->debug_info($debug_info);

    return 1;
}

# Function  :
# Arguments :
# Returns   :
# Notes     : This is a private method.

sub _format_box {
    my ($self, $title, @content) = @_;

    tie my %content, 'Tie::IxHash';
    %content = @content;

    my $formatted_box;

    $formatted_box .= qq[<table class="small_box2" border="0" width="100%">];
    $formatted_box .=
      qq[<tr><td align="left"colspan="2"><b><u>$title</u></b></td></tr>];

    foreach my $key (keys %content) {
        my $line = $content{$key} || qq[];
        $line =~ s/(.{100})/      $1<br>/g if $line =~ /\S{100,}/;
        $formatted_box .= qq[<tr><td><b>$key</b></td><td>$line</td></tr>];
    }
    $formatted_box .= qq[</table>];

    return $formatted_box;
}

# Function  :
# Arguments :
# Returns   :
# Notes     : This is a private method.

sub _get_version_information {
    my ($self, $file) = @_;
    open(IN, "<$file") or die("Cannot read file ($file)");
    my $content;
    { local $/; $content = <IN>; }
    close IN;
    my ($id) = $content =~ /\n(\$Id[^\$]*\$)/;
    return ($id);
}

# Function  : Formats the stored data based on the selected output format.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _format_data {
    my ($self) = @_;

    # Do modifications if any
    $self->_modify_data if @{$self->modifications};

    # Assign form information
    my $temp_dir_eq = $self->temp_dir_eq;

    my $action    = $self->action;
    my $method    = $self->method;
    my $page_size = $self->page_size;

    # Self-referencing URL, without explicit database
    my $search_url =
      $self->show_search_url ? $self->cgi->self_url . "#results" : qq[];

    my $order_by        = $self->cgi_params->{"order_by"};
    my $order_direction = $self->cgi_params->{"order_direction"};

    my $current_page =
        $self->cgi_params->{page}
      ? $self->cgi_params->{page}
      : 1;    # Page defaults to 1

    my $count = $self->count;

    my $number_of_pages =
      $count % $page_size
      ? int($count / $page_size) + 1
      : $count / $page_size;

    $current_page = 1 if $current_page < 1;
    $current_page = $number_of_pages if $current_page > $number_of_pages;

    my $output_format = $self->cgi_params->{output_format};

    my @data = @{$self->data};

    my @base_sql_fields     = @{$self->base_sql_fields};
    my @base_output_headers = @{$self->base_output_headers};

    my $column_width_percent = int(100 / @base_output_headers);

    my %super_output_headers = %{$self->super_output_headers};
    my @trimmed_boh = map { /^([^:]+)/; $1; } @base_output_headers;

    my $formatted_data;

    if ($output_format eq 'html') {

        # Prepare segment to display page navigation
        my %no_page_cgi = %{$self->cgi_params};
        delete $no_page_cgi{page};
        my $no_page_opt = $self->_form_opt(\%no_page_cgi);

        my $display_start = ($current_page - 1) * $page_size + 1;
        $display_start = 0 if $count == 0;

        my $display_end = $current_page * $page_size;
        $display_end = $count if $display_end > $count;
        $display_end = 0      if $count == 0;

        my $prev_page = $current_page - 1;
        $prev_page = 1 if $prev_page < 1;
        my $next_page = $current_page + 1;
        $next_page = $number_of_pages if $next_page > $number_of_pages;

        my @page_list =
          map {
            $current_page eq $_
              ? qq[<option selected value="$_">Page $_</option>\n]
              : qq[<option value="$_">Page $_</option>\n]
          } (1 .. $number_of_pages);
        my $page_list = join(qq[], @page_list);

        my $search_url_link =
          $search_url ? qq[<a href="$search_url">[Search URL]</a>] : '&nbsp;';

        my $page_navigation = <<HTML;

<table border="0" width="100%" class="navigator_color">
<tr>
<td width="40%" align="left">
Record $display_start-$display_end of $count
&nbsp;&nbsp;&nbsp;$search_url_link
</td>

<td align="center">
<form method="$method" action="$action">
$no_page_opt
<input type="hidden" name="page" value="$prev_page"/></input>
<input type="image" src="$temp_dir_eq/left-arrow.png" alt="Previous" width="25" height="25" name="submit"></input>
</form>
</td>

<td align="center">
Page $current_page of $number_of_pages
</td>

<td align="center">
<form method="$method" action="$action">
$no_page_opt
<input type="hidden" name="page" value="$next_page"></input>
<input type="image" src="$temp_dir_eq/right-arrow.png" alt="Next" width="25" height="25" name="submit"></input>
</form>
</td>

<td width="40%" align="right">
<form method="$method" action="$action">
$no_page_opt
<select name="page">
$page_list
</select>
<input type="submit" name="submit" value="Go"></input>
</form>
</td>

</tr>
</table>
HTML

        # Add navigation bar to the top
        $formatted_data .=
          qq[<table border="0" width="100%"><tr><td>$page_navigation</td></tr></table>\n];

        # Start table
        $formatted_data .=
          qq[<table border="1" width="100%" class="header_color">\n];

        # Add headers - 1st row
        $formatted_data .= qq[<tr>\n];
        foreach my $group (sort { $a <=> $b } keys %super_output_headers) {
            my $super_header = $super_output_headers{$group}{super_header};
            my @headers      = @{$super_output_headers{$group}{headers}};
            my $colspan      = $super_output_headers{$group}{colspan};

            if ($colspan == 1) {
                my $header_piece = $self->_get_header_piece($headers[0]);
                $formatted_data .=
                  qq[<td rowspan="2" width="$column_width_percent\%" align="center">$header_piece</td>\n];
            }

            else {
                $formatted_data .=
                  qq[<td colspan="$colspan" align="center"><b>$super_header</b></td>\n];
            }
        }
        $formatted_data .= qq[</tr>\n];

        # Add headers - 2nd row
        $formatted_data .= qq[<tr>\n];
        foreach my $group (sort { $a <=> $b } keys %super_output_headers) {
            my @headers = @{$super_output_headers{$group}{headers}};
            my $colspan = $super_output_headers{$group}{colspan};

            if ($colspan > 1) {
                foreach (@headers) {
                    my $header_piece = $self->_get_header_piece($_);
                    $formatted_data .=
                      qq[<td align="center"  width="$column_width_percent\%">$header_piece</td>\n];
                }
            }
        }
        $formatted_data .= qq[</tr>\n];

        # Add data
        my $counter = 0;
        foreach my $row (@data) {
            $counter++;
            my $background_color =
              $counter % 2 == 1
              ? qq[class="row_color_one"]
              : qq[class="row_color_two"];

            $formatted_data .= qq[<tr $background_color>\n];
            foreach (@$row) {
                $formatted_data .=
                  (defined $_ and $_ ne qq[])
                  ? qq[<td>$_</td>]
                  : qq[<td>&nbsp;</td>];
                $formatted_data .= "\n";
            }
            $formatted_data .= qq[</tr>];
        }

        # End table
        $formatted_data .= qq[</table>\n];

        # Add navigation bar to the bottom
        $formatted_data .=
          qq[<table border="0" width="100%"><tr><td>$page_navigation</td></tr></table>\n];
    }

    elsif ($output_format eq 'text') {

        # Calculate field length for each column
        my @index = @{$self->_get_column_lengths(\@trimmed_boh, @data)};

        # Add headers and data
        foreach my $row (\@trimmed_boh, @data) {
            my @row = @$row;

            foreach my $i (0 .. $#row) {
                my $size = $index[$i] + 1;
                $formatted_data .= sprintf("\%-${size}s", $row[$i]);
            }
            $formatted_data .= "\n";
        }

        # Add end marker
        $formatted_data .= '# [END]';
    }

    elsif ($output_format eq 'excel') {
        open my $fh, '>', \$formatted_data
          or croak("Failed to open filehandle to write excel output: $!");

        # Create WriteExcel object
        my $workbook  = Spreadsheet::WriteExcel->new($fh);
        my $worksheet = $workbook->add_worksheet();

        # Add header format to WriteExcel object
        my $header_format = $workbook->add_format;
        $header_format->set_properties(
            bold => 1,
        );

        # Set column widths
        my @index =
          @{$self->_get_column_lengths(\@base_output_headers, @data)};
        foreach my $i (0 .. $#index) {
            $worksheet->set_column($i, $i, $index[$i]);
        }

        # Add headers and data
        my $row_number = 0;
        foreach my $row (\@trimmed_boh, @data) {
            foreach my $i (0 .. $#{@$row}) {
                if ($row_number == 0) {
                    $worksheet->write(
                        $row_number, $i, $row->[$i],
                        $header_format
                    );
                }
                else {
                    $worksheet->write($row_number, $i, $row->[$i]);
                }
            }
            $row_number++;
        }

        $workbook->close;
    }

    elsif ($output_format eq 'csv') {

        # Add headers and data
        foreach my $row (\@trimmed_boh, @data) {
            foreach (@$row) { $_ = qq["$_"]; }
            $formatted_data .= join(',', @$row) . "\n";
        }

        # Add end marker
        $formatted_data .= '# [END]';
    }

    elsif ($output_format eq 'tab') {

        # Track tab conversion
        my @tab_removed;

        # Add headers and data
        my $row_number = 0;
        foreach my $row (\@trimmed_boh, @data) {
            foreach my $i (0 .. $#{@$row}) {
                if ($row->[$i] =~ s/\t/_/g) {
                    push @tab_removed, "Row: row_number, Column: $i";
                }
            }
            $formatted_data .= join("\t", @$row) . "\n";
            $row_number++;
        }

        # Record tab removals
        foreach (@tab_removed) {
            $formatted_data .= "# tab conveted to underscore $_\n";
        }

        # Add end marker
        $formatted_data .= "# [END]\n";
    }

    # Store in the object
    $self->formatted_data($formatted_data);

    return 1;
}

# Function  : Generates the oheader segment that contains the sort icons
# Arguments : $label (header:sql_column)
# Returns   : $html_code
# Notes     : This is a private method.

sub _get_header_piece {
    my ($self, $label) = @_;

    my $temp_dir_eq = $self->temp_dir_eq;

    my ($header, $sql_column) = split(':', $label);

    my $content;

    my $image = $sql_column
      ? qq[<img src="$temp_dir_eq/sort-button.png" alt="Sortable" width="14" height="14">]
      : '&nbsp;';
    $content .=
      qq[<table><tr><td><b>$header</b></td><td>$image</td></tr></table>];

    return $content;
}

# Function  : Generates the options segment of a form, given
#             a hasref of cgi params
# Arguments : \%cgi
# Returns   : $options_segment
# Notes     : This is a private method.

sub _form_opt {
    my ($self, $cgi) = @_;

    my $options;

    foreach my $key (keys %$cgi) {
        my @values = ref $cgi->{$key} ? @{$cgi->{$key}} : ($cgi->{$key});
        foreach my $value (@values) {
            $value ||= qq[];
            $options .=
              qq[<input type="hidden" name="$key" value="$value"></input>\n];
        }
    }

    return $options;
}

# Function  : For a given arrayref of data, calculate max column lengths
# Arguments : \@data (Each member is an arrayref of column data)
# Returns   : \@index (Each member is the max length of that column)
# Notes     : This is a private method.

sub _get_column_lengths {
    my ($self, @data) = @_;

    my @index;

    foreach my $row_ref (@data) {
        my @row = @{$row_ref};
        foreach my $i (0 .. $#row) {
            if (!defined $index[$i] || length($row[$i]) > $index[$i]) {
                $index[$i] = length($row[$i]);
            }
        }
    }

    return \@index;
}

# Function  : Generates the HTML code for the search page
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _print_page {
    my ($self)       = @_;
    my $header       = $self->_content($self->header);
    my $css          = $self->_content($self->css);
    my $page_title   = $self->page_title;
    my $instructions = $self->_content($self->instructions);
    my $search_form    = $self->search_form    || qq[];
    my $formatted_data = $self->formatted_data || qq[];
    my $debug_info     = $self->debug_info     || qq[];
    my $footer      = $self->_content($self->footer);
    my $temp_dir_eq = $self->temp_dir_eq;

    my $cookie                 = $self->cookie;
    my $session_id             = $self->session_id;
    my $cookie_expires_in_min  = $self->cookie_expires_in_min;

    my $cookie_obj = CGI::cookie(
        -name    => $cookie,
        -value   => $session_id,
        -expires => "+${cookie_expires_in_min}m",
    );

    my $output_format = $self->cgi_params->{output_format} || 'html';

    my $results_anchor =
      $formatted_data
      ? "results"
      : "placeholder";    # Don't display results anchor if there
                          # are no results

    if ($output_format eq 'html') {
        print $self->cgi->header(-cookie => $cookie_obj);
        print <<HTML;
<html>
    <head>
    <title>$page_title</title>
    <link rel="stylesheet" type="text/css" href="$temp_dir_eq/searchpage-main.css" />
    $css
    </head>

    <body>
    <table border="0" width="97%" align="center">
    <tr><td colspan="2" align="center">$header</td></tr>
    <tr><td colspan="2" align="center"><h1>$page_title</h1></td></tr>
    <tr><td width="60%" align="left">$instructions</td><td width="40%" align="center">$search_form</td></tr>
    <tr><td colspan="2" align="center"><a name="$results_anchor"></a>$formatted_data</td></tr>
    <tr><td colspan="2" align="center">$debug_info</td></tr>
    <tr><td colspan="2" align="center">$footer</td></tr>
    </table>
    </body>
</html>
HTML
    }

    elsif ($output_format eq 'excel') {
        print $self->cgi->header(
            -cookie => $cookie_obj,
            -type   => 'application/vnd.ms-excel'
        );
        print $formatted_data;
    }

    elsif ($output_format eq 'csv') {
        print $self->cgi->header(
            -cookie => $cookie_obj,
            -type   => 'text/comma-separated-values'
        );
        print $formatted_data;
    }

    elsif ($output_format eq 'tab') {
        print $self->cgi->header(
            -cookie => $cookie_obj,
            -type   => 'text/tab-separated-values'
        );
        print $formatted_data;
    }

    elsif ($output_format eq 'text') {
        print $self->cgi->header(
            -cookie => $cookie_obj,
            -type   => 'text/plain'
        );
        print $formatted_data;
    }

    else {
        print $self->cgi->header(
            -cookie => $cookie_obj,
            -type   => 'text/plain'
        );
        print $formatted_data;
    }

    return 1;
}

# Function  : Retrieves the content for the directive specified;
#             supports GET (retrieval by LWP), EXEC (executes a command-line
#             and captures output), FILE (retrieves a file content).
# Arguments : $directive
# Returns   : $content
# Notes     : This is a private method.

sub _content {
    my ($self, $container) = @_;

    return '&nbsp;' unless $container;

    my $content = $container || qq[];

    if ($container =~ s/^(FILE|EXEC|GET)://) {
        my $type = $1;

        if ($type eq 'GET') {
            my $self_url = $self->cgi->self_url;
            my ($current_url, $current_args) = split(/\?/, $self_url);
            $current_args ||= qq[];

            $current_url =~ s!^http://[^/]+!!;
            $current_url  = CGI::escape($current_url);
            $current_args = CGI::escape($current_args);
            $container =~ s/__CURRENT_URL__/$current_url/;
            $container =~ s/__CURRENT_ARGS__/$current_args/;
            $content = get($container)
              or croak("Cannot get container ($container)!");
        }

        elsif ($type eq 'EXEC') {
            open(EXEC, "$container|")
              or croak("Cannot exec container ($container)! - $!");
            { local $/; $content = <EXEC>; }
            close EXEC;
        }

        elsif ($type eq 'FILE') {
            open(FILE, "<$container")
              or croak("Cannot open container ($container)! - $!");
            { local $/; $content = <FILE>; }
            close FILE;
        }
    }

    return $content;
}

# Function  : Modifies the data in its raw form.
# Arguments : %params
# Returns   : 1
# Notes     : This is a private method.

sub _modify_data {
    my ($self) = @_;

    my $modifier = $self->modifier
      or croak("Cannot modify without a modifier object!");

    foreach my $params (@{$self->modifications}) {

        $params->{-page_obj} =
          $self;    # temporary hack to be able to modify SearchPage obj
        $params->{-data}          = $self->data;
        $params->{-output_format} = $self->cgi_params->{output_format}
          || 'html';
        $params->{-dbh} = $self->dbh;

        my $action = $params->{-action}
          or croak("No modifier action specified!");
        delete $params->{-action};

        eval { $modifier->$action(%$params); };

        croak($@) if $@;
    }

    # Ref to data is passed on, changes are made directly.

    return 1;
}

# Function  : Formats the stored data based on the selected output format.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _format_vertical_data {
    my ($self) = @_;

    # Do modifications if any
    $self->_modify_data if @{$self->modifications};

    # Assign form information
    my $action = $self->action;
    my $method = $self->method;

    my $output_format = $self->cgi_params->{output_format};

    my @data = @{$self->data};

    my @base_output_headers = @{$self->base_output_headers};

    my @trimmed_boh = map { /^([^:]+)/; $1; } @base_output_headers;

    # Combine @data and trimmed_boh to make data vertical
    my @vertical_data;
    foreach my $i (0 .. $#trimmed_boh) {
        $vertical_data[$i] = [$trimmed_boh[$i], $data[0][$i]];
    }

    my $formatted_data;

    if ($output_format eq 'html') {

        # Start table
        $formatted_data .=
          qq[<table border="1" align="center" width="75%">\n];

        # Add data
        my $counter = 0;
        foreach my $row (@vertical_data) {
            $counter++;
            my $background_color =
              $counter % 2 == 1
              ? qq[class="row_color_one"]
              : qq[class="row_color_two"];

            $formatted_data .= qq[<tr $background_color>\n];
            foreach my $i (0 .. $#{@$row}) {
                my $value = $row->[$i];
                if ($i == 0) {
                    $formatted_data .= $value
                      ? qq[<td width="20%"><b>$value</b></td>]
                      : qq[<td>&nbsp;</td>];
                }
                else {
                    $formatted_data .= $value
                      ? qq[<td width="80%">$value</td>]
                      : qq[<td>&nbsp;</td>];
                }

                $formatted_data .= "\n";
            }
            $formatted_data .= qq[</tr>];
        }

        # End table
        $formatted_data .= qq[</table>\n];

        # Add some space
        $formatted_data .= qq[<p>&nbsp;<p>&nbsp;<p>&nbsp;\n];

    }

    else { croak("Unknown output_format ($output_format) to display_info!"); }

    # Store in the object
    $self->formatted_data($formatted_data);

    return 1;
}

###################
# GET/SET METHODS #
###################

sub action {
    my ($self, $value) = @_;
    $self->{action} = $value if @_ > 1;
    return $self->{action};
}

sub base_identifier {
    my ($self, $value) = @_;
    $self->{base_identifier} = $value if @_ > 1;
    return $self->{base_identifier};
}

sub base_output_headers {
    my ($self, $value) = @_;
    $self->{base_output_headers} = $value if @_ > 1;
    return $self->{base_output_headers};
}

sub base_sql_fields {
    my ($self, $value) = @_;
    $self->{base_sql_fields} = $value if @_ > 1;
    return $self->{base_sql_fields};
}

sub base_sql_table {
    my ($self, $value) = @_;
    $self->{base_sql_table} = $value if @_ > 1;
    return $self->{base_sql_table};
}

sub cgi {
    my ($self, $value) = @_;
    $self->{cgi} = $value if @_ > 1;
    return $self->{cgi};
}

sub cgi_params {
    my ($self, $value) = @_;
    $self->{cgi_params} = $value if @_ > 1;
    return $self->{cgi_params};
}

sub cookie {
    my ($self, $value) = @_;
    $self->{cookie} = $value if @_ > 1;
    return $self->{cookie};
}

sub cookie_expires_in_min {
    my ($self, $value) = @_;
    $self->{cookie_expires_in_min} = $value if @_ > 1;
    return $self->{cookie_expires_in_min};
}

sub count {
    my ($self, $value) = @_;
    $self->{count} = $value if @_ > 1;
    return $self->{count};
}

sub count_sql_statement {
    my ($self, $value) = @_;
    $self->{count_sql_statement} = $value if @_ > 1;
    return $self->{count_sql_statement};
}

sub css {
    my ($self, $value) = @_;
    $self->{css} = $value if @_ > 1;
    return $self->{css};
}

sub data {
    my ($self, $value) = @_;
    $self->{data} = $value if @_ > 1;
    return $self->{data};
}

sub db_access_params {
    my ($self, $value) = @_;
    $self->{db_access_params} = $value if @_ > 1;
    return $self->{db_access_params};
}

sub db_display {
    my ($self, $value) = @_;
    $self->{db_display} = $value if @_ > 1;
    return $self->{db_display};
}

sub dbh {
    my ($self, $value) = @_;
    $self->{dbh} = $value if @_ > 1;
    return $self->{dbh};
}

sub db_selected {
    my ($self, $value) = @_;
    $self->{db_selected} = $value if @_ > 1;
    return $self->{db_selected};
}

sub debug_info {
    my ($self, $value) = @_;
    $self->{debug_info} = $value if @_ > 1;
    return $self->{debug_info};
}

sub debug_level {
    my ($self, $value) = @_;
    $self->{debug_level} = $value if @_ > 1;
    return $self->{debug_level};
}

sub distinct {
    my ($self, $value) = @_;
    $self->{distinct} = $value if @_ > 1;
    return $self->{distinct};
}

sub external_where_clauses {
    my ($self, $value) = @_;
    $self->{external_where_clauses} = $value if @_ > 1;
    return $self->{external_where_clauses};
}

sub footer {
    my ($self, $value) = @_;
    $self->{footer} = $value if @_ > 1;
    return $self->{footer};
}

sub formatted_data {
    my ($self, $value) = @_;
    $self->{formatted_data} = $value if @_ > 1;
    return $self->{formatted_data};
}

sub go_to_results {
    my ($self, $value) = @_;
    $self->{go_to_results} = $value if @_ > 1;
    return $self->{go_to_results};
}

sub group_by {
    my ($self, $value) = @_;
    $self->{group_by} = $value if @_ > 1;
    return $self->{group_by};
}

sub header {
    my ($self, $value) = @_;
    $self->{header} = $value if @_ > 1;
    return $self->{header};
}

sub instructions {
    my ($self, $value) = @_;
    $self->{instructions} = $value if @_ > 1;
    return $self->{instructions};
}

sub method {
    my ($self, $value) = @_;
    $self->{method} = $value if @_ > 1;
    return $self->{method};
}

sub modifications {
    my ($self, $value) = @_;
    $self->{modifications} = $value if @_ > 1;
    return $self->{modifications};
}

sub modifier {
    my ($self, $value) = @_;
    $self->{modifier} = $value if @_ > 1;
    return $self->{modifier};
}

sub new_search {
    my ($self, $value) = @_;
    $self->{new_search} = $value if @_ > 1;
    return $self->{new_search};
}

sub no_reset {
    my ($self, $value) = @_;
    $self->{no_reset} = $value if @_ > 1;
    return $self->{no_reset};
}

sub page_size {
    my ($self, $value) = @_;
    $self->{page_size} = $value if @_ > 1;
    return $self->{page_size};
}

sub page_title {
    my ($self, $value) = @_;
    $self->{page_title} = $value if @_ > 1;
    return $self->{page_title};
}

sub param_fields {
    my ($self, $value) = @_;
    $self->{param_fields} = $value if @_ > 1;
    return $self->{param_fields};
}

sub query_sql_statement {
    my ($self, $value) = @_;
    $self->{query_sql_statement} = $value if @_ > 1;
    return $self->{query_sql_statement};
}

sub search_form {
    my ($self, $value) = @_;
    $self->{search_form} = $value if @_ > 1;
    return $self->{search_form};
}

sub session {
    my ($self, $value) = @_;
    $self->{session} = $value if @_ > 1;
    return $self->{session};
}

sub session_id {
    my ($self, $value) = @_;
    $self->{session_id} = $value if @_ > 1;
    return $self->{session_id};
}

sub show_search_url {
    my ($self, $value) = @_;
    $self->{show_search_url} = $value if @_ > 1;
    return $self->{show_search_url};
}

sub sort_defaults {
    my ($self, $value) = @_;
    $self->{sort_defaults} = $value if @_ > 1;
    return $self->{sort_defaults};
}

sub sort_fields {
    my ($self, $value) = @_;
    $self->{sort_fields} = $value if @_ > 1;
    return $self->{sort_fields};
}

sub super_output_headers {
    my ($self, $value) = @_;
    $self->{super_output_headers} = $value if @_ > 1;
    return $self->{super_output_headers};
}

sub temp_dir {
    my ($self, $value) = @_;
    $self->{temp_dir} = $value if @_ > 1;
    return $self->{temp_dir};
}

sub temp_dir_eq {
    my ($self, $value) = @_;
    $self->{temp_dir_eq} = $value if @_ > 1;
    return $self->{temp_dir_eq};
}

1;

__END__

=head1 NAME

HTML::SearchPage - Generic framework for building web-based search pages

=head1 SYNOPSIS

Please refer to HTML::SearchPage::Tutorial for a tutorial on using HTML::SearchPage & HTML::SearchPage::Param.

=head1 DESCRIPTION

This module provides a generic framework for building web-based search pages.

=head1 USAGE

Please refer to HTML::SearchPage::Tutorial for a tutorial on using HTML::SearchPage & HTML::SearchPage::Param.

=head1 QUICK REFERENCE

All the parameters listed below have a get/set method. However, the set
functionality of the params in the 3rd group is not intended to be
utilized except for development.

=head2 Group 1 - Parameters required by the constructor

The following parameters are required by the constructor.

 Parameter            Description                                    Format
 ---------            -----------                                    ------
 db_access_params     Database access parameters                     [$datasource, $user,
                                                                     $password]
 temp_dir             Temporary directory to store images scalar     scalar
                      and session files
 temp_dir_eq          URL-equivalent to access files in temp_dir     scalar
 base_sql_table       Base SQL table (or table join) to build final  scalar
                      SQL queries
 base_sql_fields      Fields that will be retrieved by the SQL       arrayref
                      statement
 base_output_headers  Headers output in results                      arrayref
 base_identifier      Unique identifier column used by display_info  scalar
                      method (* required only when display_info
                      method is used)

=head2 Group 2 - Optional parameters

The following parameters are optional.

 Parameter               Description                    Format       Default
 ---------               -----------                    ------       -------
 page_title              Page title                     scalar       'Search
                                                                     Page'

 header                  HTML header in views           scalar(i)    ''
 footer                  HTML footer in views           scalar(i)    ''
 cookie                  Name of cookie                 scalar       html-searchpage
 cookie_expires_in_min   Expiration tim eof cookie      scalar       30
                                                        (number)
 css                     CSS for views                  scalar(i)    ''
 instructions            Instructions for views         scalar(i)    ''
 distinct                Make SQL query "distinct"      0|1          0
 no_reset                No reset button                0|1          0
 new_search              Place a new search button,     0|<URL>      0
                         (implies no_reset)
 group_by                Group by statement             scalar       ''
                                                        (exclude
                                                        GROUP BY)
 sort_fields             Number of sort fields          scalar       0
                                                        (number)
 sort_defaults           Default sort options           arrayref(ii) []

 method                  HTML form method to use        GET|POST     GET
 action                  HTML URL to script             scalar       $ENV{SCRIPT_NAME}
 page_size               Number of records per          scalar       50
                         result page                    (number)
 show_search_url         Whether to display a
                         self-referencing search URL    0|1          0
 debug_level             Level of debug information:    0|1|2(iii)   0
 go_to_results           If set, a click on the page    0|1          1
                         will take the display to the
                         beginning of the results
                         on the subsequent page
 modifier                The page modifier object       ref          undef
 external_where_clauses  External where clauses         arrayref     []

 Notes:
 (i) The parameter provided here can be of the following types, specified by the preceding keyword:
     - FILE:<something> : Contents of file <something> is retrieved
     - EXEC:<something> : <something> is executed and its STDOUT is retrieved
     - GET:<something>  : URL <something> is retrieved by LWP
     - <something>      : <something> is used as it is

 (ii) Format for sort defaults:
      ["(asc|desc) <field>", "(asc|desc) <field>", "(asc|desc) <field>"]

 (iii) Debug levels:
       - 0: No debug information
       - 1: Time, URL, version information of critical code components, generated SQL statements
       - 2: In addition to (1), environment variables

=head2 Group 3 - Internal methods

The following parameters are set automatically but they can be
get/set after object instantiation.

 Parameter             Description                     Format
 ---------             -----------                     ------
 cgi                   CGI object                      CGI ref
 cgi_params            CGI params                      hashref
 count                 Retrieved data count            scalar
 count_sql_statement   Generated SQL statement for     scalar
                       retrieving count of results
 data                  Retrieved data                  arrayref (each element is
                                                       an arrayref of a row)
 debug_info            HTML code for retrieved debug   scalar
                       info based on debug level
 db_display            Display name for the database   scalar
                       in effect
 dbh                   Database handle                 DBI ref
 db_selected           Database specified using the    scalar
                       database param in the URL
 formatted_data        HTML code or text for of data   scalar
                       formatted based on output
                       format
 modifications         Scheduled modifications         arrayref
 param_fields          Stored HTML::SearchPage::Param  hashref
                       objects
 query_sql_statement   Generated SQL statement for     scalar
                       retrieving results
 search_form           HTML code for generated search  scalar
                       form
 session               Session object                  CGI::Session ref
 session_id            Session id                      scalar
 super_output_headers  Headers and super               hashref
                       headers

=head1 OTHER

"db_access_params" can be specified in two forms:

The following format is used when there is only one database that the page will be running on.

 db_access_params => [$datasource, $username, $password];

Alternatively, a set of databases can be specified and can be addressed by "database=<alias>" URL parameter.

 db_access_params => {
     database => [
         {
           alias      => $alias,
           display    => 'Database 1',
           datasource => $datasource2,
           username   => $username2,
           password   => $password2,
          },
          {
           alias      => $alias,
           display    => 'Database 2',
           datasource => $datasource2,
           username   => $username2,
           password   => $password2,
          },
     ],
 }

When multiple databases are provided, database selection is persistent between pages that use HTML::SearchPage. This feature requires cookies to be enabled. 

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

=head1 VERSION

Version 0.05

=head1 ACKNOWLEDGEMENTS

This module has been initially written for implementing search pages for displaying maize diversity data on Panzea (www.panzea.org), the public web site of the "Molecular and Functional Diversity of the Maize Genome" project. Thanks to project members for their feedback on user features and help in testing the web displays.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut

