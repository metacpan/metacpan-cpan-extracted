package HTML::GMap;

our $VERSION = '0.06';

# $Id: GMap.pm,v 1.24 2007/09/19 01:48:58 canaran Exp $

use warnings;
use strict;

use HTML::GMap::Files;

use Carp;
use CGI;
use CGI::Session;
use DBI;
use File::Temp qw(tempfile);
use GD::Graph::pie;
use GD::Icons;
use List::MoreUtils qw(any);
use List::Util qw(first);
use LWP::Simple;
use Template;
use Time::Format qw(%time);
use XML::Simple;

###############
# CONSTRUCTOR #
###############

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;

    eval {
        my $cgi = CGI->new();
        $self->cgi($cgi);

        my $cgi_params = $self->{cgi}->Vars;
        $self->cgi_params($cgi_params);

        my $page_title =
          exists $params{page_title}
          ? $params{page_title}
          : "Geographical Display";
        $self->page_title($page_title);

        exists $params{base_sql_table}
          or croak("A base_sql_table param is required!");
        $self->base_sql_table($params{base_sql_table});

        exists $params{base_sql_fields}
          or croak("A base_sql_fields param is required!");
        $self->base_sql_fields($params{base_sql_fields});

        exists $params{base_output_headers}
          or croak("A base_output_headers param is required!");
        $self->base_output_headers($params{base_output_headers});

        my $param_fields =
          exists $params{param_fields} ? $params{param_fields} : {};
        $self->param_fields($param_fields);

        exists $params{gmap_key} or croak("A gmap_key param is required!");
        $self->gmap_key($params{gmap_key});

        exists $params{gmap_key} or croak("A gmap_key param is required!");
        $self->gmap_key($params{gmap_key});

        exists $params{temp_dir} or croak("A temp_dir param is required!");
        $self->temp_dir($params{temp_dir});

        exists $params{temp_dir_eq}
          or croak("A temp_dir_eq param is required!");
        $self->temp_dir_eq($params{temp_dir_eq});

        my $install_dir =
          exists $params{install_dir}
          ? $params{install_dir}
          : $self->temp_dir;
        $self->install_dir($install_dir);

        my $install_dir_eq =
          exists $params{install_dir_eq}
          ? $params{install_dir_eq}
          : $self->temp_dir_eq;
        $self->install_dir_eq($install_dir_eq);

        # Create HTML/js files
        HTML::GMap::Files->new(temp_dir => $self->install_dir);

        my $session_id = $self->cgi->param('session_id');

        my $session_dir = $self->temp_dir . '/sessions';
        my $session =
          CGI::Session->new('file', $session_id, {Directory => $session_dir});
        if ($session_id && $session_id ne $session->id) {
            croak("Cannot create session!");
        }
        $self->session_id($session->id);
        $self->session($session);

        $self->legend_field1($params{legend_field1});

        $self->legend_field2($params{legend_field2});

        my $max_hires_display =
          exists $params{max_hires_display}
          ? $params{max_hires_display}
          : 100;
        $self->max_hires_display($max_hires_display);

        my $center_latitude =
          exists $params{center_latitude}
          ? $params{center_latitude}
          : 40.863233;
        $self->center_latitude($center_latitude);

        my $center_longitude =
          exists $params{center_longitude}
          ? $params{center_longitude}
          : -73.466566;
        $self->center_longitude($center_longitude);

        my $center_zoom =
          exists $params{center_zoom}
          ? $params{center_zoom}
          : 4;
        $self->center_zoom($center_zoom);

        $self->messages($params{messages});

        $self->header($params{header});

        $self->footer($params{footer});

        $self->hires_shape_keys($params{hires_shape_keys});
        $self->hires_shape_values($params{hires_shape_values});

        $self->hires_color_keys($params{hires_color_keys});
        $self->hires_color_values($params{hires_color_values});

        my $image_height_pix =
          exists $params{image_height_pix} ? $params{image_height_pix} : 600;
        $self->image_height_pix($image_height_pix);

        my $image_width_pix =
          exists $params{image_width_pix} ? $params{image_width_pix} : 600;
        $self->image_width_pix($image_width_pix);

        my $tile_width_pix =
          exists $params{tile_width_pix} ? $params{tile_width_pix} : 60;
        $self->tile_width_pix($tile_width_pix);

        my $tile_height_pix =
          exists $params{tile_height_pix} ? $params{tile_height_pix} : 60;
        $self->tile_height_pix($tile_height_pix);

        my $cluster_field =
          exists $params{cluster_field} ? $params{cluster_field} : '_default';
        $self->cluster_field($cluster_field);

        my $gmap_main_css_file =
          exists $params{gmap_main_css_file}
          ? $params{gmap_main_css_file}
          : 'gmap-main.css';
        $self->gmap_main_css_file($gmap_main_css_file);

        my $gmap_main_html_file =
          exists $params{gmap_main_html_file}
          ? $params{gmap_main_html_file}
          : 'gmap-main.html';
        $self->gmap_main_html_file($gmap_main_html_file);

        my $gmap_main_js_file =
          exists $params{gmap_main_js_file}
          ? $params{gmap_main_js_file}
          : 'gmap-main.js';
        $self->gmap_main_js_file($gmap_main_js_file);

        my $prototype_js_file =
          exists $params{prototype_js_file}
          ? $params{prototype_js_file}
          : 'prototype.js';
        $self->prototype_js_file($prototype_js_file);

        # If db_access_params are provided, generate a db handle and store it
        my $db_access_params = $params{db_access_params};
        if ($db_access_params) {
            # Re-format if a single db is enteredd
            if (      ref($db_access_params)
                  and ref($db_access_params) eq 'ARRAY') {
                my ($datasource, $username, $password) = @$db_access_params;

                $db_access_params = {
                    database => [{ alias      => 'default',
                                   datasource => $datasource,
                                   username   => $username,
                                   password   => $password,
                                 }
                                ]
                }              
            }

            $self->db_access_params($db_access_params);
            
            my $database = $self->{cgi_params}->{database};

            my @available_databases =
              (       ref($db_access_params->{database})
                  and ref($db_access_params->{database}) eq 'ARRAY')
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
        }

        my $request_url_template;
        if (exists $params{request_url_template}) {
            if ($params{request_url_template} =~ /session_id=/) {
                croak(  "request_url_template cannot contain a session_id, "
                      . "session_id must be incorporated by this module!");
            }

            $request_url_template = $params{request_url_template};

            my $session_id_param = 'session-id=' . $self->session_id;
            $request_url_template =~
              s/session_id=[^\;\&]+/session_id=$session_id/;
        }
        else {
            my ($default_request_url_template) =
              $self->cgi->self_url =~ /^([^\?]+)/;

            my @additional_params;

            if ($self->db_selected) {
                push @additional_params, 'database=' . $self->db_selected;
            }

            exists $params{initial_format}
              or croak("A initial_format param is required if "
                  . "request_url_template is not specified!");
            my $initial_format = $params{initial_format};

            if (   $initial_format ne 'xml-piechart'
                && $initial_format ne 'xml-hires') {
                croak(  "initial_format parameter can only be "
                      . "xml-piechart or xml-hires!");
            }

            push @additional_params, "format=$initial_format";

            $self->initial_format($initial_format);

            push @additional_params, 'session_id=' . $self->session_id;

            $default_request_url_template .=
              '?' . join(';', @additional_params);

            $request_url_template = $default_request_url_template;
        }
        $self->request_url_template($request_url_template);
    };

    $self->error($@) if $@;

    return $self;
}

##################
# PUBLIC METHODS #
##################

# Function  :
# Arguments : none
# Returns   : 1
# Notes     : None specified.

sub display {
    my ($self) = @_;

    $self->_process_params;

    my $cgi    = $self->cgi;
    my $format = $cgi->param("format");

    if (!$format) {
        $self->_display_js_page;
    }

    elsif ($format eq "js") {
        $self->_display_js_page;
    }

    elsif ($format eq "xml-hires") {
        $self->_serve_xml_data;
    }

    elsif ($format eq "xml-piechart") {
        $self->_serve_xml_data;
    }

    else {
        $self->error("Invalid format parameter ($format)!");
    }

    return 1;
}

# Function  :
# Arguments : $message
# Returns   : exits
# Notes     : None specified.

sub error {
    my ($self, $message) = @_;
    croak($message);
}

###########################################################
# HOOKS (Methods intended to be overridden by subclasses) #
###########################################################

# Function  :
# Arguments : \@data
# Returns   : 1
# Notes     : None specified

sub process_data_post_retrieve {
    my ($self, $data_ref) = @_;

    return 1;
}

# Function  :
# Arguments : \%markers
# Returns   : 1
# Notes     : None specified

sub process_markers_pre_filter {
    my ($self, $markers_ref) = @_;

    return 1;
}

# Function  :
# Arguments : \%markers
# Returns   : 1
# Notes     : None specified

sub process_markers_pre_cluster {
    my ($self, $markers_ref) = @_;

    return 1;
}

# Function  :
# Arguments : \%markers
# Returns   : 1
# Notes     : None specified

sub process_markers_post_cluster {
    my ($self, $markers_ref) = @_;

    return 1;
}

# Function  :
# Arguments : $data_count, $max_data_count, $min_chart_size, $max_chart_size
# Returns   : $piechart_icon_size
# Notes     : None specified

sub piechart_icon_size {
    my ($self, $data_count, $max_data_count, $min_chart_size, $max_chart_size) = @_;    
    
    my $piechart_icon_size = $self->_round(
        $min_chart_size + (
            ($data_count / $max_data_count) *
              ($max_chart_size - $min_chart_size)
        )
    );
    
    return $piechart_icon_size;
}    

# Function  :
# Arguments : \@info ([$icon_url, $label, $count], ...)
# Returns   : $html
# Notes     :

sub generate_piechart_legend_html {
    my ($self, $info_ref) = @_;

    my @sorted_info = sort {
        if (   ($a->[1] eq 'Clustered' || $a->[1] eq 'Other')
            && ($b->[1] eq 'Clustered' || $b->[1] eq 'Other')) {
            $a cmp $b;
        }
        elsif (($a->[1] eq 'Clustered' || $a->[1] eq 'Other')
            && ($b->[1] ne 'Clustered' && $b->[1] ne 'Other')) {
            1;
        }
        elsif (($a->[1] ne 'Clustered' && $a->[1] ne 'Other')
            && ($b->[1] eq 'Clustered' || $b->[1] eq 'Other')) {
            -1;
        }
        else { $b->[2] <=> $a->[2] }
    } @$info_ref;

    $info_ref = \@sorted_info;

    my $html;

    $html .= qq[<table>\n];

    $html .= qq[<tr>\n];
    $html .= qq[<td colspan="2">
                This section displays data points in current view and
                is updated as the map is moved and/or filtering is applied.<br/>
                </td>\n];
    $html .= qq[</tr>\n];

    foreach my $info (@{$info_ref}) {
        my ($icon_url, $label, $count) = @$info;
        $html .= qq[<tr>\n];
        $html .= qq[<td align="left">
                        <img src="$icon_url"/> $label ($count points)
                    </td>\n];
        $html .= qq[</tr>\n];
    }
    $html .= qq[</table>\n];

    return $html;
}

# Function  :
# Arguments : \%markers
# Returns   : $html
# Notes     :

sub generate_hires_legend_html {
    my ($self, $rows_ref, $type) = @_;

    my $legend_field1 = $self->legend_field1;
    my $legend_field2 = $self->legend_field2;

    my $temp_dir_eq = $self->temp_dir_eq;
    my $session_id  = $self->session_id;

    my $multiples_icon_url =
      "$temp_dir_eq/Multiple-icon-$session_id-0-0-0.png";

    my $legend_info;
    my @legend_markers;

    if ($type eq 'hires') {
        $legend_info = qq[(The coordinates with overlapping data points
                          are displayed as <img src="$multiples_icon_url">.)];

        my %legend_markers;
        foreach my $key (keys %$rows_ref) {
            foreach my $row_ref (@{$rows_ref->{$key}->{rows}}) {
                my $icon_url            = $row_ref->{icon_url};
                my $legend_field1_value = $row_ref->{$legend_field1};
                my $legend_field2_value = $row_ref->{$legend_field2};

                $legend_markers{$icon_url}{count}++;
                $legend_markers{$icon_url}{text} = join(
                    '; ',
                    map { s/^(.{5}).+/$1 .../; $_; } $legend_field1_value,
                    $legend_field2_value
                );
            }
        }

        foreach my $icon_url (
            sort { $legend_markers{$b}{count} <=> $legend_markers{$a}{count} }
            keys %legend_markers
          ) {
            my $text = $legend_markers{$icon_url}{text};

            push @legend_markers,
              { icon_url  => $icon_url,
                icon_size => 11,
                text      => $text,
              };
        }
    }

    else {
        $legend_info = qq[];

        @legend_markers = @$rows_ref;
    }

    my $html;

    $html .= qq[<table>\n];

    $html .= qq[<tr>\n];
    $html .= qq[<td colspan="2">
                $legend_info<br/>
                </td>\n];
    $html .= qq[</tr>\n];

    foreach my $legend_marker (@legend_markers) {
        my $icon_url  = $legend_marker->{icon_url};
        my $icon_size = $legend_marker->{icon_size};
        my $text      = $legend_marker->{text};
        $html .= qq[<tr>\n];
        $html .= qq[<td align="left">
                 <img height="$icon_size" src="$icon_url"/> $text
                 </td>\n];
        $html .= qq[</tr>\n];
    }
    $html .= qq[</table>\n];

    return $html;
}

# Function  :
# Arguments : $data_ref
# Returns   : $html
# Notes     :

sub generate_piechart_details_html {
    my ($self, $key_ref) = @_;

    my $data_ref = $key_ref->{cluster_set};

    my $session         = $self->session;
    my $color_table_ref = $session->param('color_table');
    my $temp_dir_eq     = $self->temp_dir_eq;

    my $total_count = $key_ref->{cluster_data_count};

    my $html;

    $html .= qq[<table>\n];
    $html .= qq[<tr>\n];
    $html .= qq[<th align="left" width="50%">
                Total Count</th><th align="left">: $total_count
                </th>\n];
    $html .= qq[</tr>\n];
    $html .= qq[</table>\n];

    $html .= qq[<table>\n];

    foreach my $label (
        sort {
            if ($b eq 'Clustered' || $b eq 'Other') { -1 }
            else { $data_ref->{$b} <=> $data_ref->{$a} }
        } keys %{$data_ref}
      ) {
        my $count    = $data_ref->{$label};
        my $color    = $color_table_ref->{$label};
        my $icon_url = "$temp_dir_eq/Legend-icon-$color.png";

        my $rounded_percent = $self->_round($count / $total_count * 100);

        $html .= qq[<tr>\n];
        $html .= qq[<td align="left">
                    <img src="$icon_url"/> $label ($count points)
                    </td>\n];
        $html .= qq[<td align="right"> $rounded_percent %</td>\n];
        $html .= qq[</tr>\n];
    }
    $html .= qq[</table>\n];

    return $html;
}

# Function  :
# Arguments : $data_ref
# Returns   : $html
# Notes     :

sub generate_hires_details_html {
    my ($self, $key_ref) = @_;

    my $data_ref = $key_ref->{rows};

    my $legend_field1 = $self->legend_field1;
    my $legend_field2 = $self->legend_field2;
    my $session       = $self->session;
    my $temp_dir_eq   = $self->temp_dir_eq;

    my %icon_urls;

    my $total_count = 0;

    foreach my $row_ref (@$data_ref) {
        my $icon_url            = $row_ref->{icon_url};
        my $legend_field1_value = $row_ref->{$legend_field1};
        my $legend_field2_value = $row_ref->{$legend_field2};

        $icon_urls{$icon_url}{count}++;
        $icon_urls{$icon_url}{text} = join(
            '; ', map { s/^(.{5}).+/$1 .../; $_; } $legend_field1_value,
            $legend_field2_value
        );

        $total_count++;
    }

    my $html;

    $html .= qq[<table>\n];
    $html .= qq[<tr>\n];
    $html .= qq[<th align="left" width="50%">Total Count</th>
                <th align="left">: $total_count</th>\n];
    $html .= qq[</tr>\n];
    $html .= qq[</table>\n];

    $html .= qq[<table>\n];

    foreach my $icon_url (
        sort { $icon_urls{$b}{count} <=> $icon_urls{$a}{count} }
        keys %icon_urls
      ) {
        my $count = $icon_urls{$icon_url}{count};
        my $text  = $icon_urls{$icon_url}{text};

        my $rounded_percent = $self->_round($count / $total_count * 100);

        $html .= qq[<tr>\n];
        $html .= qq[<td align="left">
                    <img src="$icon_url"/> $text ($count points)
                    </td>\n];
        $html .= qq[<td align="right"> $rounded_percent%</td>\n];
        $html .= qq[</tr>\n];
    }
    $html .= qq[</table>\n];

    return $html;
}

###################
# GET/SET METHODS #
###################

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

sub center_latitude {
    my ($self, $value) = @_;
    $self->{center_latitude} = $value if @_ > 1;
    return $self->{center_latitude};
}

sub center_longitude {
    my ($self, $value) = @_;
    $self->{center_longitude} = $value if @_ > 1;
    return $self->{center_longitude};
}

sub center_zoom {
    my ($self, $value) = @_;
    $self->{center_zoom} = $value if @_ > 1;
    return $self->{center_zoom};
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

sub cluster_field {
    my ($self, $value) = @_;
    $self->{cluster_field} = $value if @_ > 1;
    return $self->{cluster_field};
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

sub db_selected {
    my ($self, $value) = @_;
    $self->{db_selected} = $value if @_ > 1;
    return $self->{db_selected};
}

sub dbh {
    my ($self, $value) = @_;
    $self->{dbh} = $value if @_ > 1;
    return $self->{dbh};
}

sub fields {
    my ($self, $value) = @_;
    $self->{fields} = $value if @_ > 1;
    return $self->{fields};
}

sub footer {
    my ($self, $value) = @_;
    $self->{footer} = $value if @_ > 1;
    return $self->{footer};
}

sub gmap_key {
    my ($self, $value) = @_;
    $self->{gmap_key} = $value if @_ > 1;
    return $self->{gmap_key};
}

sub gmap_main_css_file {
    my ($self, $value) = @_;
    $self->{gmap_main_css_file} = $value if @_ > 1;
    return $self->{gmap_main_css_file};
}

sub gmap_main_html_file {
    my ($self, $value) = @_;
    $self->{gmap_main_html_file} = $value if @_ > 1;
    return $self->{gmap_main_html_file};
}

sub gmap_main_js_file {
    my ($self, $value) = @_;
    $self->{gmap_main_js_file} = $value if @_ > 1;
    return $self->{gmap_main_js_file};
}

sub hires_shape_keys {
    my ($self, $value) = @_;
    $self->{hires_shape_keys} = $value if @_ > 1;
    return $self->{hires_shape_keys};
}

sub hires_shape_values {
    my ($self, $value) = @_;
    $self->{hires_shape_values} = $value if @_ > 1;
    return $self->{hires_shape_values};
}

sub hires_color_keys {
    my ($self, $value) = @_;
    $self->{hires_color_keys} = $value if @_ > 1;
    return $self->{hires_color_keys};
}

sub hires_color_values {
    my ($self, $value) = @_;
    $self->{hires_color_values} = $value if @_ > 1;
    return $self->{hires_color_values};
}

sub header {
    my ($self, $value) = @_;
    $self->{header} = $value if @_ > 1;
    return $self->{header};
}

sub image_height_pix {
    my ($self, $value) = @_;
    $self->{image_height_pix} = $value if @_ > 1;
    return $self->{image_height_pix};
}

sub image_width_pix {
    my ($self, $value) = @_;
    $self->{image_width_pix} = $value if @_ > 1;
    return $self->{image_width_pix};
}

sub initial_format {
    my ($self, $value) = @_;
    $self->{initial_format} = $value if @_ > 1;
    return $self->{initial_format};
}

sub install_dir {
    my ($self, $value) = @_;
    $self->{install_dir} = $value if @_ > 1;
    return $self->{install_dir};
}

sub install_dir_eq {
    my ($self, $value) = @_;
    $self->{install_dir_eq} = $value if @_ > 1;
    return $self->{install_dir_eq};
}

sub legend_field1 {
    my ($self, $value) = @_;
    $self->{legend_field1} = $value if @_ > 1;
    return $self->{legend_field1};
}

sub legend_field2 {
    my ($self, $value) = @_;
    $self->{legend_field2} = $value if @_ > 1;
    return $self->{legend_field2};
}

sub max_hires_display {
    my ($self, $value) = @_;
    $self->{max_hires_display} = $value if @_ > 1;
    return $self->{max_hires_display};
}

sub messages {
    my ($self, $value) = @_;
    $self->{messages} = $value if @_ > 1;
    return $self->{messages};
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

sub prototype_js_file {
    my ($self, $value) = @_;
    $self->{prototype_js_file} = $value if @_ > 1;
    return $self->{prototype_js_file};
}

sub request_url_template {
    my ($self, $value) = @_;
    $self->{request_url_template} = $value if @_ > 1;
    return $self->{request_url_template};
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

sub tile_height_pix {
    my ($self, $value) = @_;
    $self->{tile_height_pix} = $value if @_ > 1;
    return $self->{tile_height_pix};
}

sub tile_width_pix {
    my ($self, $value) = @_;
    $self->{tile_width_pix} = $value if @_ > 1;
    return $self->{tile_width_pix};
}

###########################
# PRIVATE/UTILITY METHODS #
###########################

# Function  : Display Javascript page, use provided URL template.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _display_js_page {
    my ($self) = @_;

    my $initial_format = $self->initial_format;

    my @fields = @{$self->fields};
    my @param_fields_with_values;

    foreach my $field (@fields) {
        if (   $field->{param}
            && exists $field->{values}
            && @{$field->{values}} > 0) {
            push @param_fields_with_values, $field;
        }
    }

    my $cgi_header = CGI::header();

    my $center_latitude =
      defined $self->center_latitude
      ? $self->center_latitude
      : 40.863233;
    my $center_longitude =
      defined $self->center_longitude
      ? $self->center_longitude
      : -73.466566;
    my $center_zoom =
      defined $self->center_zoom
      ? $self->center_zoom
      : 4;
    my $param_fields = join(
        ", ",
        map { qq["] . $_->{name} . qq["] } @param_fields_with_values
    );

    my $gmap_main_css_file_eq =
      $self->install_dir_eq . '/' . $self->gmap_main_css_file;

    my $gmap_main_js_file_eq =
      $self->install_dir_eq . '/' . $self->gmap_main_js_file;

    my $prototype_js_file_eq =
      $self->install_dir_eq . '/' . $self->prototype_js_file;

    my %vars = (

        # HTML variables
        cgi_header               => $cgi_header,
        header                   => $self->_content($self->header),
        footer                   => $self->_content($self->footer),
        page_title               => $self->page_title,
        legend                   => undef,
        param_fields_with_values => \@param_fields_with_values,
        messages                 => $self->messages,
        gmap_key                 => $self->gmap_key,
        gmap_main_css_file_eq    => $gmap_main_css_file_eq,
        gmap_main_js_file_eq     => $gmap_main_js_file_eq,
        prototype_js_file_eq     => $prototype_js_file_eq,
        container_height_pix     => $self->image_height_pix + 20,
        container_width_pix      => $self->image_width_pix + 450,
        center_width_pix         => $self->image_width_pix + 0,
        display_cluster_slices   => $initial_format eq 'xml-piechart' ? 1 : 0,

        # var_store variables
        center_latitude  => $center_latitude,
        center_longitude => $center_longitude,
        center_zoom      => $center_zoom,
        image_height_pix => $self->image_height_pix,
        tile_height_pix  => $self->tile_height_pix,
        image_width_pix  => $self->image_width_pix,
        tile_width_pix   => $self->tile_width_pix,
        param_fields     => $param_fields,
        url_template     => $self->request_url_template,
        cluster_field    => $self->cluster_field,
        draw_grid        => $self->initial_format eq 'xml-piechart' ? 1 : 0,
    );

    my $template = Template->new(INCLUDE_PATH => $self->install_dir);

    $template->process($self->gmap_main_html_file, \%vars)
      or $self->error("Template process failed: " . $template->error);

    return 1;
}

# Function  : Display XML data.
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _serve_xml_data {
    my ($self) = @_;

    $self->_clean_temp_dir;

    my $dbh                 = $self->dbh;
    my $cgi                 = $self->cgi;
    my $base_sql_table      = $self->base_sql_table;
    my @base_sql_fields     = @{$self->base_sql_fields};
    my @base_output_headers = @{$self->base_output_headers};

    my @fields = @{$self->fields};

    my $format = $cgi->param("format");
    if ($format ne 'xml-piechart' && $format ne 'xml-hires') {
        $self->error("Invalid format param($format)!");
    }

    my $cluster_field = $self->cluster_field;

    # Generate WHERE clauses (Two statements are needed,
    my @where_clauses;

    # - filter params
    foreach my $field (@fields) {
        my $name    = $field->{name};
        my $display = $field->{display};
        my $values  = $field->{values};

        # For pie charts, handling of this field is done by script
        next
          if ($name eq $cluster_field and $format eq 'xml-piechart');

        my $cgi_value = $cgi->param($name);

        if ($cgi_value and $cgi_value ne 'all') {
            push @where_clauses, qq[$name = ] . $dbh->quote($cgi_value);
        }
    }

    # - coordinates
    push @where_clauses,
      qq[latitude >= ] . $dbh->quote($cgi->param("latitude_south"));
    push @where_clauses,
      qq[latitude <= ] . $dbh->quote($cgi->param("latitude_north"));

    if ($cgi->param("longitude_west") <= $cgi->param("longitude_east")) {
        push @where_clauses,
          qq[longitude >= ] . $dbh->quote($cgi->param("longitude_west"));
        push @where_clauses,
          qq[longitude <= ] . $dbh->quote($cgi->param("longitude_east"));
    }

    else {
        push @where_clauses,
          qq[((longitude >= ]
          . $dbh->quote($cgi->param("longitude_west"))
          . qq[AND longitude <= 180)]
          . qq[ OR ]
          . qq[(longitude <= ]
          . $dbh->quote($cgi->param("longitude_east"))
          . qq[AND longitude >= -180))];
    }

    # Generate query SQL statement
    my $statement = "SELECT " . join(", ", @base_sql_fields);
    $statement .= " FROM " . $base_sql_table;
    $statement .= " WHERE " . join(" AND ", @where_clauses) if @where_clauses;

    # Retrieve data
    my $data_ref;
    my $sth = $dbh->prepare($statement);
    $sth->execute;
    while (my @row = $sth->fetchrow_array) { push @{$data_ref}, \@row; }
    $sth->finish;

    # Process data array (this is a hook intended to be used in subclasses)
    $self->process_data_post_retrieve($data_ref);

    # Remove any undef rows
    my $clean_data_ref;
    foreach (@{$data_ref}) {
        push @{$clean_data_ref}, $_ if $_;
    }
    $data_ref = $clean_data_ref;

    # Generate XML output
    my $xml_ref;
    if ($format eq "xml-hires") {
        $xml_ref = $self->_generate_hires_xml_data($data_ref);
    }

    elsif ($format eq "xml-piechart") {
        $xml_ref = $self->_generate_piechart_xml_data($data_ref);
    }

    else {
        $self->error("Invalid XML data format ($format)!");
    }

    #    # Generate XML headers
    #    my @xml_boh = map { my ($h) = $_ =~ /^([^:]+)/;
    #                        $h =~ s/[^a-zA-Z0-9]/_/g;
    #                        $h =~ s/^[^a-zA-Z]//g;
    #                        $h =~ s/^xml//gi;
    #                        lc($h);
    #                        } @base_output_headers;

    my $formatted_data = XMLout($xml_ref, keyattr => []);

    # Print XML data out
    print CGI::header(-type => 'text/plain');
    print $formatted_data;

    return 1;
}

# Function  :
# Arguments : $\@data
# Returns   : \%xml_ref
# Notes     : This is a private method.

sub _generate_hires_xml_data {
    my ($self, $data_ref) = @_;

    my @base_sql_fields = @{$self->base_sql_fields};

    my $legend_field1 = $self->legend_field1;
    my $legend_field2 = $self->legend_field2;
    my $session       = $self->session;

    my $temp_dir    = $self->temp_dir;
    my $temp_dir_eq = $self->temp_dir_eq;
    my $session_id  = $self->session_id;

    my $max_hires_display = $self->max_hires_display;

    my $markers_ref    = {};
    my $max_data_count = 0;

    # Cluster data points by geo coords (how many distinct geo coords?)
    foreach my $data (@{$data_ref}) {
        my $row_ref;

        foreach my $i (0 .. $#base_sql_fields) {
            $row_ref->{$base_sql_fields[$i]} = $data->[$i];
        }

        my $latitude  = $row_ref->{latitude};
        my $longitude = $row_ref->{longitude};

        my $key = join(':', $latitude, $longitude);

        push @{$markers_ref->{$key}->{rows}}, $row_ref;
        $markers_ref->{$key}->{cluster_data_count}++;

        if (    $markers_ref->{$key}->{cluster_data_count}
            and $markers_ref->{$key}->{cluster_data_count} > $max_data_count)
        {
            $max_data_count = $markers_ref->{$key}->{cluster_data_count};
        }
    }

    # Process marker hash to generate cumulative information
    my $xml_ref = {};

    # If there are more than max_hires_display markers, cluster data and display low res view
    # *** Override $markers_ref and $max_data_count ***
    if (scalar(keys %$markers_ref) > $max_hires_display) {
        ($markers_ref, $max_data_count) = $self->_cluster_data($data_ref);

        $self->_add_hires_icon_urls($markers_ref);

        my $lowres_legend_marker_count = 5;

        my $density_icon_prefix = "Density-icon-$session_id";
        my $icon                = GD::Icons->new(
            shape_keys   => [":default"],
            shape_values => ["_large_square"],
            color_keys   => [":default"],
            color_values => ["#0009ff"],
            sval_keys    => [0 .. $lowres_legend_marker_count - 1],
            icon_dir     => $temp_dir,
            icon_prefix  => $density_icon_prefix,
        );
        $icon->generate_icons;

        my @lowres_legend_markers;
        foreach my $i (0 .. $lowres_legend_marker_count - 1) {
            my $icon_url = "$temp_dir_eq/$density_icon_prefix-0-0-$i.png";
            my $text =
                int($i * $max_data_count / $lowres_legend_marker_count) + 1
              . ' to '
              . int(($i + 1) * $max_data_count / $lowres_legend_marker_count)
              . ' points';
            my $icon_size = 22;
            push @lowres_legend_markers,
              { icon_url  => $icon_url,
                icon_size => $icon_size,
                text      => $text,
              };
        }

        foreach my $key (keys %{$markers_ref}) {
            my ($latitude, $longitude) = split(':', $key);

            my $data_ref = $markers_ref->{$key}->{rows};

            my $data_count = scalar(@$data_ref);

            my $density_icon_index =
              int(($data_count / $max_data_count) *
                  ($lowres_legend_marker_count - 1));
            my $icon_url =
              "$temp_dir_eq/$density_icon_prefix-0-0-$density_icon_index.png";
            my $icon_size = 22;

            my $details_on_click =
              $self->generate_hires_details_html($markers_ref->{$key});

            my $row_ref = {
                latitude          => $latitude,
                longitude         => $longitude,
                icon_url          => $icon_url,
                icon_size         => $icon_size,
                details_on_click  => $details_on_click,
                messages_on_click => '',
                legend_on_click   => '',
            };

            push(@{$xml_ref->{marker}}, $row_ref);
        }

        my $legend = $self->generate_hires_legend_html(
            \@lowres_legend_markers,
            'lowres'
        );

        my $meta_data_ref = {
            messages_by_default => $self->messages,
            details_by_default  => '[Click an icon for details ...]',
            legend_by_default   => $legend,
        };
        push(@{$xml_ref->{meta_data}}, $meta_data_ref);
    }

    # Else
    else {
        $self->_add_hires_icon_urls($markers_ref);

#        my $multiples_icon_prefix = "Multiple-icon-$session_id";
#        my $icon                  = GD::Icons->new(
#            shape_keys   => [":default"],
#            shape_values => ["_letter-m"],
#            color_keys   => [":default"],
#            color_values => ["Blue"],
#            sval_keys    => [":default"],
#            sval_values  => [":default"],
#            icon_dir     => $temp_dir,
#            icon_prefix  => $multiples_icon_prefix,
#        );
#        $icon->generate_icons;
#
#        my $multiples_icon_url =
#          "$temp_dir_eq/" . $icon->icon(':default', ':default', ':default');

        foreach my $key (keys %{$markers_ref}) {
            my ($latitude, $longitude) = split(':', $key);

            my $data_ref = $markers_ref->{$key}->{rows};

            my $data_count = scalar(@$data_ref);

            my $icon_size = $data_count > 1 ? 14 : 11;

            my $multiples_icon_url;
            
            if ($data_count > 1) {
                my $multiples_icon_prefix = "Multiple-icon-$data_count-$session_id";
                my $icon = GD::Icons->new(
                    alpha        => 30,
                    shape_keys   => ["Multiple:$data_count"],
                    shape_values => ["_number-flag"],
                    color_keys   => [":default"],
                    color_values => ["#c1caff"],
                    sval_keys    => [":default"],
                    sval_values  => [":default"],
                    icon_dir     => $temp_dir,
                    icon_prefix  => $multiples_icon_prefix,
                );
                $icon->generate_icons;
                $multiples_icon_url =
                    "$temp_dir_eq/" . $icon->icon("Multiple:$data_count", ':default', ':default');
            }                
            
            my $icon_url =
                $data_count > 1
              ? $multiples_icon_url
              : $data_ref->[0]->{icon_url};

            my $details_on_click =
              $self->generate_hires_details_html($markers_ref->{$key});

            my $row_ref = {
                latitude          => $latitude,
                longitude         => $longitude,
                icon_url          => $icon_url,
                icon_size         => $icon_size,
                details_on_click  => $details_on_click,
                messages_on_click => '',
                legend_on_click   => '',
            };

            push(@{$xml_ref->{marker}}, $row_ref);
        }

        my $legend = $self->generate_hires_legend_html($markers_ref, 'hires');

        my $meta_data_ref = {
            messages_by_default => $self->messages,
            details_by_default  => '[Click icons for details ...]',
            legend_by_default   => $legend
        };
        push(@{$xml_ref->{meta_data}}, $meta_data_ref);
    }

    return $xml_ref;
}

# Function  :
# Arguments : \%markers_ref
# Returns   : 1
# Notes     : This is a private method.

sub _add_hires_icon_urls {
    my ($self, $markers_ref) = @_;

    my $legend_field1 = $self->legend_field1;
    my $legend_field2 = $self->legend_field2;
    my $session       = $self->session;

    my $hires_shape_keys   = $self->hires_shape_keys;
    my $hires_shape_values = $self->hires_shape_values;
    
    my $hires_color_keys   = $self->hires_color_keys;
    my $hires_color_values = $self->hires_color_values;

    my $temp_dir    = $self->temp_dir;
    my $temp_dir_eq = $self->temp_dir_eq;
    my $session_id  = $self->session_id;

    # Create icon set and store in row_refs
    my %legend_field1_values;
    my %legend_field2_values;
    foreach my $key (keys %{$markers_ref}) {
        my $data_ref = $markers_ref->{$key}->{rows};
        foreach my $row_ref (@$data_ref) {
            $legend_field1_values{$row_ref->{$legend_field1}} = 1
              if exists $row_ref->{$legend_field1};
            $legend_field2_values{$row_ref->{$legend_field2}} = 1
              if exists $row_ref->{$legend_field2};
        }
    }
    my @legend_field1_values = sort keys %legend_field1_values;
    my @legend_field2_values = sort keys %legend_field2_values;

    my $small_icon_prefix = "Small-icon-$session_id";
    my $icon              = GD::Icons->new(
        color_keys   => $hires_color_keys ? $hires_color_keys : \@legend_field2_values,
        color_values => $hires_color_values,
        shape_keys   => $hires_shape_keys ? $hires_shape_keys : \@legend_field1_values,
        shape_values => $hires_shape_values,
        sval_keys    => [":default"],
        icon_dir     => $temp_dir,
        icon_prefix  => $small_icon_prefix,
    );
    $icon->generate_icons;

    foreach my $key (keys %{$markers_ref}) {
        my $data_ref = $markers_ref->{$key}->{rows};
        foreach my $row_ref (@$data_ref) {
            $row_ref->{icon_url} = "$temp_dir_eq/"
              . $icon->icon(
                $row_ref->{$legend_field1},
                $row_ref->{$legend_field2}, ':default' # GD::Icons uses first color, then shape
              );
        }
    }

    return 1;
}

# Function  :
# Arguments : $\@data
# Returns   : \%xml_ref
# Notes     : This is a private method.

sub _generate_piechart_xml_data {
    my ($self, $data_ref) = @_;

    my $cgi           = $self->cgi;
    my $cluster_field = $self->cluster_field;
    my $session       = $self->session;

    # Whether filter by value is valid
    my $cluster_filter_value;
    if ($cgi->param($cluster_field) && $cgi->param($cluster_field) ne 'all') {
        $cluster_filter_value = $cgi->param($cluster_field);
    }

    # Cluster data points and cluster them in a hash (key being the lat-lng pair)
    my ($markers_ref, $max_data_count) = $self->_cluster_data($data_ref);

    # Process markers hash (this is a hook intended to be used in subclasses)
    $self->process_markers_pre_filter($markers_ref);

    # Apply single cluster field filter if applicable
    if ($cluster_filter_value) {
        foreach my $key (keys %{$markers_ref}) {
            my $data = $markers_ref->{$key}->{cluster_set};
            my $cluster_data_count =
              $markers_ref->{$key}->{cluster_data_count};

            my $blank_value = 0;

            foreach my $cluster_value (keys %$data) {
                if ($cluster_value eq $cluster_filter_value) {
                    next;
                }
                else {
                    $blank_value += $data->{$cluster_value};
                    delete $data->{$cluster_value};
                }
            }

            $data->{Other} = $blank_value;
        }
    }

    # Process markers hash (this is a hook intended to be used in subclasses)
    $self->process_markers_pre_cluster($markers_ref);

    # Cluster small slices
    my $cluster_slices       = $cgi->param('cluster_slices');
    my $cluster_slices_by    = $cgi->param('cluster_slices_by');
    my $cluster_slices_value = $cgi->param('cluster_slices_value');

    if (   $cluster_slices
        && $cluster_slices ne 'off'
        && $cluster_slices ne 'false'
        && $cluster_slices_value > 0) {
        foreach my $key (keys %{$markers_ref}) {
            my $data = $markers_ref->{$key}->{cluster_set};

            my $other_value = 0;
            foreach my $cluster_value (keys %$data) {
                my $cluster_count = $data->{$cluster_value};
                my $cluster_percent =
                  $data->{$cluster_value} /
                  $markers_ref->{$key}->{cluster_data_count} * 100;

                if ($cluster_slices_by eq 'count') {
                    if ($cluster_count < $cluster_slices_value) {
                        $other_value += $cluster_count;
                        delete $data->{$cluster_value};
                    }
                }

                elsif ($cluster_slices_by eq 'percent') {
                    if ($cluster_percent < $cluster_slices_value) {
                        $other_value += $cluster_count;
                        delete $data->{$cluster_value};
                    }
                }

                else {
                    $self->error(
                        "Invalid cluster_slices_type value ($cluster_slices_by)!"
                    );
                }
            }
            $data->{Clustered} = $other_value;
        }
    }

    # Process markers hash (this is a hook intended to be used in subclasses)
    $self->process_markers_post_cluster($markers_ref);

    # Generate list of all cluster values
    my %all_cluster_values;
    foreach my $key (keys %{$markers_ref}) {
        my $data = $markers_ref->{$key}->{cluster_set};
        foreach my $cluster_value (keys %$data) {
            $all_cluster_values{$cluster_value} += $data->{$cluster_value};
        }
    }

    # Generate/store color table
    my $color_table_ref  = $session->param('color_table')      || {};
    my $last_color_index = $session->param('last_color_index') || 0;

    my @colors = @{$self->_colors};
    my @all_cluster_values =
      sort { $all_cluster_values{$b} <=> $all_cluster_values{$a} }
      keys %all_cluster_values;

    my $color_index;
    foreach my $i (0 .. $#all_cluster_values) {
        my $cluster_value = $all_cluster_values[$i];

        next if $color_table_ref->{$cluster_value};

        $color_index = ($i + $last_color_index + 1) % @colors;
        $color_table_ref->{$cluster_value} = $colors[$color_index];
    }
    $color_table_ref->{Other}     = 'white';
    $color_table_ref->{Clustered} = 'purple';

    $session->param('color_table',      $color_table_ref);
    $session->param('last_color_index', $color_index);

    # Process marker hash to generate cumulative information
    my $xml_ref = {};

    foreach my $key (keys %{$markers_ref}) {
        my ($latitude, $longitude) = split(':', $key);

        my $data_ref = $markers_ref->{$key}->{cluster_set};

        my @piechart_labels;
        my @piechart_values;
        my @piechart_colors;

        foreach my $label (
            sort { $data_ref->{$b} <=> $data_ref->{$a} }
            keys %{$data_ref}
          ) {    # sort by frequent to rare
            push @piechart_labels, $label;
            push @piechart_values, $data_ref->{$label};
            push @piechart_colors, $color_table_ref->{$label};
        }

        my ($icon_url, $icon_size) = $self->_make_piechart_icon(
            [\@piechart_labels, \@piechart_values],
            \@piechart_colors, $max_data_count
        );

        my $details_on_click =
          $self->generate_piechart_details_html($markers_ref->{$key});

        my $row_ref = {
            latitude          => $latitude,
            longitude         => $longitude,
            icon_url          => $icon_url,
            icon_size         => $icon_size,
            details_on_click  => $details_on_click,
            messages_on_click => '',
            legend_on_click   => '',
        };

        push(@{$xml_ref->{marker}}, $row_ref);
    }

    my $legend_info =
      $self->_generate_piechart_legend_info(\%all_cluster_values);
    my $legend = $self->generate_piechart_legend_html($legend_info);

    my $meta_data_ref = {
        messages_by_default => $self->messages,
        details_by_default  => '[Click a pie chart for details ...]',
        legend_by_default   => $legend
    };
    push(@{$xml_ref->{meta_data}}, $meta_data_ref);

    return $xml_ref;
}

# Function  :
# Arguments : \@data
# Returns   : (\%markers, $max_data_count)
# Notes     :

sub _cluster_data {
    my ($self, $data_ref) = @_;

    my $cgi             = $self->cgi;
    my @base_sql_fields = @{$self->base_sql_fields};

    my $cluster_field = $self->cluster_field;

    my $image_height_pix = $self->image_height_pix;
    my $tile_height_pix  = $self->tile_height_pix;

    my $image_width_pix = $self->image_width_pix;
    my $tile_width_pix  = $self->tile_width_pix;

    # Determine map geographical boundaries
    my $latitude_south = $cgi->param("latitude_south");
    my $latitude_north = $cgi->param("latitude_north");
    my $longitude_east = $cgi->param("longitude_east");
    my $longitude_west = $cgi->param("longitude_west");

    # Calculate size of map in degrees
    my $latitude_delta = $latitude_north - $latitude_south;
    my $longitude_delta =
        ($longitude_west < $longitude_east)
      ? ($longitude_east - $longitude_west)
      : (($longitude_east - (-180)) + (180 - $longitude_west));

    # Number of tiles
    my $number_of_vertical_tiles   = $image_height_pix / $tile_height_pix;
    my $number_of_horizontal_tiles = $image_width_pix / $tile_width_pix;

    my %markers, my $max_data_count = 0;

    foreach my $data (@{$data_ref}) {
        my $row_ref;

        foreach my $i (0 .. $#base_sql_fields) {
            $row_ref->{$base_sql_fields[$i]} = $data->[$i];
        }

        my $latitude             = $row_ref->{latitude};
        my $latitude_from_origin = $latitude - $latitude_south;

        my $longitude = $row_ref->{longitude};
        my $longitude_from_origin =
            ($longitude_west < $longitude)
          ? ($longitude - $longitude_west)
          : (($longitude - (-180)) + (180 - $longitude_west));

        my $rounded_latitude =
          $number_of_vertical_tiles * $latitude_from_origin / $latitude_delta;
        my $lowres_latitude =
          $latitude_south + (int($rounded_latitude) + 0.5) *
          ($latitude_delta / $number_of_vertical_tiles);

        my $rounded_longitude =
          $number_of_horizontal_tiles * $longitude_from_origin /
          $longitude_delta;
        my $lowres_longitude =
          $longitude_west + (int($rounded_longitude) + 0.5) *
          ($longitude_delta / $number_of_horizontal_tiles);
        if ($lowres_longitude > 180) {
            $lowres_longitude = -180 + ($lowres_longitude - 180);
        }

        my $key = join(':', $lowres_latitude, $lowres_longitude);

        my $cluster_value = $row_ref->{$cluster_field} || '_default';

        push @{$markers{$key}{rows}}, $row_ref;
        $markers{$key}{cluster_set}{$cluster_value}++;
        $markers{$key}{cluster_data_count}++;

        if (    $markers{$key}{cluster_data_count}
            and $markers{$key}{cluster_data_count} > $max_data_count) {
            $max_data_count = $markers{$key}{cluster_data_count};
        }
    }

    return (\%markers, $max_data_count);
}

# Function  :
# Arguments : \%all_cluster_values (key: $label, value: count), \%color_table (key: $label, value: color)
# Returns   : $html
# Notes     :

sub _generate_piechart_legend_info {
    my ($self, $data_ref) = @_;

    my $session         = $self->session;
    my $color_table_ref = $session->param('color_table');
    my $temp_dir        = $self->temp_dir;
    my $temp_dir_eq     = $self->temp_dir_eq;

    my @legend_data;

    foreach my $label (
        sort { $data_ref->{$b} <=> $data_ref->{$a} }
        keys %{$data_ref}
      ) {
        my $count = $data_ref->{$label};
        my $color = $color_table_ref->{$label};

        my $icon_file = "$temp_dir/Legend-icon-$color.png";
        my $icon_url  = "$temp_dir_eq/Legend-icon-$color.png";

        if (!-e $icon_file) {
            my @icon_data = (
                [$label, 'empty'],
                [75,     25],
            );

            my $graph = GD::Graph::pie->new(15, 15)
              or croak("Cannot create an GD::Graph object!");

            $graph->set(
                '3d'           => 0,
                'labelclr'     => 0,
                'axislabelclr' => 0,
                'legendclr'    => 0,
                'valuesclr'    => 0,
                'textclr'      => 0,
                'start_angle'  => 180,
                'accentclr'    => 'dgray',
                'dclrs'        => [$color, 'white'],
            ) or croak($graph->error);

            my $icon = $graph->plot(\@icon_data)
              or croak($graph->error);    # Convert to GD object

            open(IMG, ">$icon_file")
              or croak("Cannot write file ($icon_file): $!");
            binmode IMG;
            print IMG $icon->png;
            close IMG;
        }

        push @legend_data, [$icon_url, $label, $count];
    }

    return \@legend_data;
}

# Function  :
# Arguments : $data_ref (an array ref of two equal-length arrays is needed)
# Returns   : 1
# Notes     : This is a private method.

sub _make_piechart_icon {
    my ($self, $data_ref, $color_ref, $max_data_count) = @_;

    my $temp_dir    = $self->temp_dir;
    my $temp_dir_eq = $self->temp_dir_eq;
    my $session_id  = $self->session_id;

    # Check data (must be an array of two arrays
    unless ($data_ref
        && ref $data_ref
        && ref $data_ref eq 'ARRAY'
        && $data_ref->[0]
        && ref $data_ref->[0]
        && ref $data_ref->[0] eq 'ARRAY'
        && $data_ref->[1]
        && ref $data_ref->[1]
        && ref $data_ref->[1] eq 'ARRAY'
        && scalar(@{$data_ref->[0]}) == scalar(@{$data_ref->[1]})) {
        $self->error("Invalid data param (an array ref of two "
              . "equal-length arrays is needed)!");
    }

    # Get data count
    my $data_count = $self->_total(@{$data_ref->[1]});

    my $max_chart_size = 50; # This can go into constructor
    my $min_chart_size = 20; # This can go into constructor

    my $piechart_icon_size = $self->piechart_icon_size( # This method can be overridden
        $data_count, $max_data_count, $min_chart_size, $max_chart_size
    );    
    
    # Generate pie chart and render it as a GD object
    my $graph = GD::Graph::pie->new($piechart_icon_size, $piechart_icon_size)
      or $self->error("Cannot create an GD::Graph object!");

    $graph->set(
        '3d'           => 0,
        'labelclr'     => 0,
        'axislabelclr' => 0,
        'legendclr'    => 0,
        'valuesclr'    => 0,
        'textclr'      => 0,
        'start_angle'  => 180,
        'accentclr'    => 'dgray',
        'dclrs'        => $color_ref,
    ) or $self->error($graph->error);

    my $graph_as_gd = $graph->plot($data_ref) or $self->error($graph->error);

    # Generate a temp file and print it out
    my $file_temp = File::Temp->new(
        TEMPLATE => "PieChart-icon-$session_id-XXXXX",
        DIR      => $temp_dir,
        SUFFIX   => '.png',
        UNLINK   => 0,
    );
    my $icon_file = $file_temp->filename;

    open(IMG, ">$icon_file")
      or $self->error("Cannot write file ($icon_file): $!");
    binmode IMG;
    print IMG $graph_as_gd->png;
    close IMG;

    my ($icon_file_name) = $icon_file =~ /([^\/]+)$/;
    my $icon_url = "$temp_dir_eq/$icon_file_name";

    return ($icon_url, $piechart_icon_size);
}

# Function  :
# Arguments :
# Returns   : 1
# Notes     : This is a private method.

sub _process_params {
    my ($self) = @_;

    my $base_sql_fields     = $self->base_sql_fields;
    my $base_output_headers = $self->base_output_headers;
    my $param_fields        = $self->param_fields;

    if (@{$base_sql_fields} != @{$base_output_headers}) {
        croak(
            "Count of base_sql_fields and base_output_headers do not match!");
    }

    my @fields;
    foreach my $i (0 .. @{$base_sql_fields} - 1) {
        my $name    = $base_sql_fields->[$i];
        my $display = $base_output_headers->[$i];
        my $values  = $param_fields->{$name} || [];
        my $param   = (any { $_ eq $name } (keys %$param_fields)) ? 1 : 0;

        foreach (@$values) {
            my ($param, $display) = split(':', $_);
            if (!defined $display) { $display = $param }

            $_ = {param => $param, display => $display};
        }

        push @fields,
          { name    => $name,
            display => $display,
            values  => $values,
            param   => $param,
          };
    }

    $self->fields(\@fields);

    return 1;
}

# Function  : URL-encodes a given string.
# Arguments : $string
# Returns   : $url_encoded_string
# Notes     : This is a private method.

sub _url_encode {
    my ($self, $string) = @_;

    $string =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

    return $string;
}

# Function  : URL-decodes a given string.
# Arguments : $string
# Returns   : $url_decoded_string
# Notes     : This is a private method.

sub _url_decode {
    my ($self, $string) = @_;

    $string =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

    return $string;
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

    my $content = $container;

    if ($container =~ s/^(FILE|EXEC|GET)://) {
        my $type = $1;

        if ($type eq 'GET') {
            $content = get($container)
              or croak("Cannor get container ($container)!");
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

# Function  : Rounds a number.
# Arguments : $number
# Returns   : $number
# Notes     : This is a private method.

sub _round {
    my ($self, $number) = @_;

    return int($number + 0.5);
}

# Function  : Totals values in an array.
# Arguments : @array
# Returns   : $number
# Notes     : This is a private method.

sub _total {
    my ($self, @values) = @_;

    my $total;

    foreach my $value (@values) {
        $total += $value;
    }

    return $total;
}

# Function  :
# Arguments : None
# Returns   : \@colors
# Notes     : This is a private method.

sub _colors {
    my ($self) = @_;

    my @colors = qw(
      lyellow
      lblue
      lorange
      lgreen
      cyan
      red
      gold
      lred
      pink
      dpurple
      lgray
      yellow
      lbrown
      orange
      dpink
      marine
      gray
      dyellow
      dgreen
      dbrown
      dred
      blue
      dblue
      green
    );

    return \@colors;
}

# Function  :
# Arguments : None
# Returns   : 1
# Notes     : This is a private method.

sub _clean_temp_dir {
    my ($self) = @_;

    my $temp_dir   = $self->temp_dir;
    # my $session_id = $self->session_id;

    my @cmds = (
        "find $temp_dir -name \'Legend-icon-*\' -cmin +20 -exec rm -f {} \\;",
        # "find $temp_dir -name \'PieChart-icon-$session_id-*\' -exec rm -f {} \\;",
        # "find $temp_dir -name \'Density-icon-$session_id-*\' -exec rm -f {} \\;",
        # "find $temp_dir -name \'Small-icon-$session_id-*\' -exec rm -f {} \\;",   
        "find $temp_dir -name \'PieChart-icon-*\' -cmin +2 -exec rm -f {} \\;",
        "find $temp_dir -name \'Density-icon-*\' -cmin +2 -exec rm -f {} \\;",
        "find $temp_dir -name \'Small-icon-*\' -cmin +2 -exec rm -f {} \\;",   
        "find $temp_dir/sessions -name \'cgisess_*\' -cmin +20 -exec rm -f {} \\;",
    );

    foreach my $cmd (@cmds) {
        system($cmd);
    }

    return 1;
}

1;

__END__

=head1 NAME

HTML::GMap - Generic framework for building Google Maps displays

=head1 SYNOPSIS

 # hires mode

 my $gmap = HTML::GMap->new (
     initial_format        => 'xml-hires',
     page_title            => 'HTML::GMap hires View Demo',
     header                => '[Placeholder for Header]',
     footer                => '[Placeholder for Header]',
     db_access_params      => [$datasource, $username, $password],         
     base_sql_table        => qq[html_gmap_hires_sample],
     base_sql_fields       => ['id',
                               'latitude',
                               'longitude',
                               'name',
                               'pharmacy',
                               'open24',
                               ],
     base_output_headers   => ['Id',
                               'Latitude',
                               'Longitude',
                               'Store Name',
                               'Pharmacy',
                               'Open 24 Hours',
                               ],
     legend_field1         => 'pharmacy',
     legend_field2         => 'open24',
     param_fields          => {
       pharmacy => ['all:All', 'Yes', 'No'],
       open24   => ['all:All', 'Yes', 'No'],
     },
     gmap_key              => $gmap_key,
     temp_dir              => qq[/usr/local/demo/html/demo/tmp],
     temp_dir_eq           => qq[http://localhost:8080/demo/tmp],
 );

 $gmap->display;

 # piechart mode

 my $gmap = HTML::GMap->new (
     initial_format        => 'xml-piechart',
     page_title            => 'HTML::GMap piechart View Demo',
     header                => '[Placeholder for Header]',
     footer                => '[Placeholder for Header]',
     db_access_params      => [$datasource, $username, $password],         
     base_sql_table        => qq[html_gmap_piechart_sample],
     base_sql_fields       => ['id',
                               'latitude',
                               'longitude',
                               'name',
                               'specialty',
                               'insurance',
                               ],
     base_output_headers   => ['Id',
                               'Latitude',
                               'Longitude',
                               'Name',
                               'Specialty',
                               'Insurance',
                               ],
     cluster_field         => 'specialty',
     param_fields          => {
       specialty => ['all:All',      'Specialty #1', 'Specialty #2',
                     'Specialty #3', 'Specialty #4', 'Specialty #5'],
       insurance => ['all:All', 'Yes', 'No'],
     },
     gmap_key              => $gmap_key,
     temp_dir              => qq[/usr/local/demo/html/demo/tmp],
     temp_dir_eq           => qq[http://localhost:8080/demo/tmp],
 );

 $gmap->display;

=head1 DESCRIPTION

This module provides an easy-to-use way to build interactive web-based
geographical maps that utilize the Google Maps API.

=head1 USAGE

Please refer to HTML::GMap::Tutorial for a tutorial on using HTML::GMap.

=head1 QUICK REFERENCE

All the parameters listed below have a get/set method. However, the set
functionality of the params in the 3rd group is not intended to be
utilized except for development.

=head2 Group 1 - Parameters required by the constructor

The following parameters are required by the constructor.

 Parameter           Description                                     Format
 ---------           -----------                                     ------
 initial_format      Initial display format (xml-piechart|xml-hires) scalar
 db_access_params    Database access params                          arrayref
                     ([datasource, username, password])
 base_sql_table      Base SQL table (or table join) to build final   scalar
                     SQL queries from
 base_sql_fields     Fields that will be retrieved by the            arrayref
                     SQL statement
 base_output_headers Headers that will be output in results          arrayref
 legend_field1       For hires display, first field to fold on       scalar
                     (Required only for xml-hires)
 legend_field2       For hires display, second field to fold on      scalar
                     (Required only for xml-hires)
 cluster_field       For pie chart display, the field to fold on     scalar
                     (Required only for xml-piechart)
 param_fields        Param fields to include as filters              arrayref
 gmap_key            Google Maps API key                             scalar
 temp_dir            Temporary directory to store images scalar
                     and session files 
 temp_dir_eq         URL-equivalent to access files in temp_dir      scalar

=head2 Group 2 - Optional parameters

The following parameters are optional.

 Parameter             Description                    Format  Default
 ---------             -----------                    ------  -------
 page_title            Page title                     scalar  'Geographical
                                                               Display'
 header                HTML header in views           scalar  ''
 footer                HTML footer in views           scalar  ''
 messages              Initial content to display     scalar  ''
                       in the "Messages" section              
 request_url_template  URL template for making AJAX   scalar  *set
                       requests to refresh displays           automatically*         
 center_latitude       The initial latitude that the  scalar  40.863233
                       map will centered               
 center_longitude      The initial latitude that the  scalar  -73.466566
                       map will centered at            
 max_hires_display     For hires display, max number  scalar  100
                       of data points displayed when   
                       in high resolution mode                          
 install_dir           Directory containing the HTML  scalar  temp_dir
                       components of installation  
 install_dir_eq        HTML-equivalent to access      scalar  temp_dir_eq
                       files in install_dir              
 image_height_pix      Height of map in pixels        scalar  600
 image_width_pix       Width of map in pixels         scalar  600
 tile_height_pix       Height of tiles in pixels      scalar  60
 tile_width_pix        Width of tiles in pixels       scalar  60
 hires_shape_values    Default shape values           arrayref undef
                       (Contained in GD::Icons)
 hires_color_values    Default color values           arrayref undef
                       (Contained in GD::Icons)

=head2 Group 3 - Internal methods

The following parameters are set automatically but they can be
get/set after object instantiation.

 Parameter            Description                    Format
 ---------            -----------                    ------
 cgi                  CGI object                     CGI ref         
 cgi_params           CGI params                     hashref         
 db_display           Display name for the database  scalar          
                      in effect
 dbh                  Database handle                DBI ref         
 db_selected          Database specified using the   scalar          
                      database param in the URL
 fields               Processed form of fields       hashref         
 session              CGI::Session object            CGI::Session ref
 session_id           CGI::Session object id         scalar      

=head1 OTHER

"db_access_params" can be specified in two forms:

The following format is used when there is only one database that the page will be running on.

 db_access_params => [$datasource, $username, $password];

Alternatively, a set of databases can be specified and can be addressed by "database=<alias>" URL parameter.

 db_access_params => [
                       {
                         alias      => $alias,
                         datasource => $datasource2,
                         username   => $username2,
                         password   => $password2,
                       },
                       {
                         alias      => $alias,
                         datasource => $datasource2,
                         username   => $username2,
                         password   => $password2,
                       },
                     ];                        

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

=head1 VERSION

Version 0.06

=head1 ACKNOWLEDGEMENTS

This module has been initially written for implementing a geographic viewer for displaying maize genetic polymorphism data on Panzea (www.panzea.org), the public web site of the "Molecular and Functional Diversity of the Maize Genome" project. Thanks to project members for their feedback on user features. Particularly thanks to Jeff Glaubitz for his feedback and providing use cases and help in testing the Panzea viewer.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut

