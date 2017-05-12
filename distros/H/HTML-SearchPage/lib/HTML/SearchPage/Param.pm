package HTML::SearchPage::Param;

our $VERSION = '0.05';

# $Id: Param.pm,v 1.8 2007/09/19 21:30:18 canaran Exp $

use warnings;
use strict;

use Carp;

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
        # Required params
        my $sql_column = $params{sql_column}
          or croak("A sql_column is required!");
        $self->sql_column($sql_column);

        my $form_name = $params{form_name}
          or croak("A form_name is required!");
        $self->form_name($form_name);

        my $param_type = $params{param_type}
          or croak("A param_type is required!");
        croak("Invalid value for param_type ($param_type)!")
              unless ($param_type eq 'drop_down'
                or $param_type =~ /^scrolling_list:\d+$/
                or $param_type =~ /^text:\d+$/);
        $self->param_type($param_type);

        my $param_list = [];
        if (defined $params{param_list} && ref $params{param_list}) {
            $param_list = $params{param_list};
        }
        elsif (defined $params{param_list}) {
            $param_list = [$params{param_list}];
        }
        
        my $valid_param_count = 0;
        if (@$param_list) {
            foreach my $value (@$param_list) {
                next unless defined $value;
                $valid_param_count++;
                croak("Invalid param_list value ($value)!")
                  unless (
                       $value =~ /^DISTINCT:/
                    or $value =~ /^([^:]+):([^:]+)$/ # space is allowed
                    or $value =~ /^([^:]+)$/         # space is allowed
                  );
            }
        }

        # *** Disabled; now handled by SearchPage.pm ***
        # if (!$valid_param_count && $self->param_type !~ /^text:\d+$/) {
        #     croak("Valid param_list values are required!");
        # }

        $self->param_list($param_list);

        # Optional params
        $self->auto_all($params{auto_all});

        $self->auto_null($params{auto_null});

        $self->case_sensitive($params{case_sensitive});

        $self->disabled($params{disabled});

        $self->exact($params{exact});

        my $label = $params{label} ? $params{label} : 'Unknown Field';
        $self->label($label);

        $self->numerical($params{numerical});

        my $operator_default = $params{operator_default};
        if ($operator_default) {
            croak("Invalid operator_default ($operator_default)!")
              unless ($operator_default =~ /^([^\s:]+)$/);
        }
        $self->operator_default($operator_default);

        $self->operator_display($params{operator_display});

        my $operator_list =
          $params{operator_list} ? $params{operator_list} : ['=:equals to'];
        if ($operator_list) {
            foreach my $value (@$operator_list) {
                next unless defined $value;
                croak("Invalid operator_list value ($value)!")
                  unless ($value =~ /^([^\s:]+):([^:]+)$/
                    or $value =~ /^([^\s:]+)$/);
            }
        }
        $self->operator_list($operator_list);

        my $param_default = $params{param_default};
        if ($param_default) {
            croak("Invalid param_default value ($param_default)!")
              unless ($param_default =~ /^([^:]+)$/); # space is allowed
        }
        $self->param_default($param_default);

        $self->rank($params{rank});

    };

    return $@ ? undef: $self;
}

###################
# GET/SET METHODS #
###################

sub auto_all {
    my ($self, $value) = @_;
    $self->{auto_all} = $value if @_ > 1;
    return $self->{auto_all};
}

sub auto_null {
    my ($self, $value) = @_;
    $self->{auto_null} = $value if @_ > 1;
    return $self->{auto_null};
}

sub case_sensitive {
    my ($self, $value) = @_;
    $self->{case_sensitive} = $value if @_ > 1;
    return $self->{case_sensitive};
}

sub disabled {
    my ($self, $value) = @_;
    $self->{disabled} = $value if @_ > 1;
    return $self->{disabled};
}

sub exact {
    my ($self, $value) = @_;
    $self->{exact} = $value if @_ > 1;
    return $self->{exact};
}

sub form_name {
    my ($self, $value) = @_;
    $self->{form_name} = $value if @_ > 1;
    return $self->{form_name};
}

sub label {
    my ($self, $value) = @_;
    $self->{label} = $value if @_ > 1;
    return $self->{label};
}

sub numerical {
    my ($self, $value) = @_;
    $self->{numerical} = $value if @_ > 1;
    return $self->{numerical};
}

sub operator_default {
    my ($self, $value) = @_;
    $self->{operator_default} = $value if @_ > 1;
    return $self->{operator_default};
}

sub operator_display {
    my ($self, $value) = @_;
    $self->{operator_display} = $value if @_ > 1;
    return $self->{operator_display};
}

sub operator_list {
    my ($self, $value) = @_;
    $self->{operator_list} = $value if @_ > 1;
    return $self->{operator_list};
}

sub param_default {
    my ($self, $value) = @_;
    $self->{param_default} = $value if @_ > 1;
    return $self->{param_default};
}

sub param_list {
    my ($self, $value) = @_;
    $self->{param_list} = $value if @_ > 1;
    return $self->{param_list};
}

sub param_type {
    my ($self, $value) = @_;
    $self->{param_type} = $value if @_ > 1;
    return $self->{param_type};
}

sub rank {
    my ($self, $value) = @_;
    $self->{rank} = $value if @_ > 1;
    return $self->{rank};
}

sub sql_column {
    my ($self, $value) = @_;
    $self->{sql_column} = $value if @_ > 1;
    return $self->{sql_column};
}

1;

__END__

=head1 NAME

HTML::SearchPage::Param - Container for parameter fields used by HTML::SearchPage

=head1 SYNOPSIS

Please refer to HTML::SearchPage::Tutorial for a tutorial on using HTML::SearchPage & HTML::SearchPage::Param.

=head1 DESCRIPTION

This module represents parameter fields as used by HTML::SearchPage for building web-based search pages.

=head1 USAGE

Please refer to HTML::SearchPage::Tutorial for a tutorial on using HTML::SearchPage & HTML::SearchPage::Param.

=head1 QUICK REFERENCE

This module is only a container for information associated with a parameter field. All the parameters listed below have a get/set method.

=head2 Group 1 - Parameters required by the constructor

The following parameters are required by the constructor.

 Parameter   Description                   Format
 ---------   -----------                   ------
 sql_column  name of SQL column            scalar
             that this field acts on
 form_name   name of parameter to be used  scalar
             in the HTML form
 param_type  type of parameter             (i)
 param_list  list of parameters            arrayref
             (required only for
              drop-down and
              scrolling-list)
 Notes:
 (i) Parameter type can be one of:
     - text:<length>         : Text field, <length> characters long
     - drop_down             : Drop-down list from which a single parameter
                               can be selected
     - scrolling_list:<size> : Drop-down list from which multiple parameters
                               can be selected

=head2 Group 2 - Optional parameters

The following parameters are optional.

 Parameter         Description                       Format       Default
 ---------         -----------                       ------       -------
 auto_all          whether to include an "all:All"   0|1          0
                   on the top of param list
 auto_null         whether to include an "null:NULL" 0|1          0
                   on the top of param list
 case_sensitive    whether the field is
                   case-sensitive                    0|1          0
 disabled          whether field is disabled         0|1          0
 label             name to display for the           scalar       'Unknown field'
                   field in the HTML form
 numerical         numerical field                   0|1          0
 operator_default  the default operator to display   scalar       undef
 operator_display  whether the operator is           0|1          0
                   displayed or not
 operator_list     list of operators allowed         arrayref     "=:equals to"
 param_default     the default parameter to display  scalar       undef

=head2 Group 3 - Internal methods

The following parameters are set automatically but they can be
get/set after object instantiation.

 Parameter  Description                  Format
 ---------  -----------                  ------
 rank       display rank of param field  scalar

=cut

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

=head1 VERSION

Version 0.05

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut

