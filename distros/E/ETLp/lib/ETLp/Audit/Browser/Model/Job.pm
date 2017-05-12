package ETLp::Audit::Browser::Model::Job;

use MooseX::Declare;

class ETLp::Audit::Browser::Model::Job with 
    (ETLp::Role::Config, ETLp::Role::Schema, ETLp::Role::Audit,
     ETLp::Role::Browser) {
    use DateTime;
    use DateTime::Format::Strptime;
    
   method get_jobs(Maybe[Int] :$page?, Maybe[Str] :$section_name?, Maybe[Int] :$config_id?, Maybe[Int ]:$status_id?, Maybe[Str] :$minimum_date?, Maybe[Str] :$maximum_date?) {
        my ($criteria, $jobs, $join);
    
        my $strp = DateTime::Format::Strptime->new(pattern => '%d/%m/%Y');
    
        if ($section_name) {
            $criteria->{'section_name'} = $section_name;
            $join++;
        }
    
        if ($config_id) {
            $criteria->{'config_id'} = $config_id;
            $join++;
        }
        
        if ($status_id) {
            $criteria->{'me.status_id'} = $status_id;
        }
    
        if ($minimum_date && $maximum_date) {
            $criteria->{'me.date_created'} = {
                '>=' => $self->db_time($strp->parse_datetime($minimum_date)),
                '<'  => $self->db_time($strp->parse_datetime($maximum_date))
            };
        } elsif ($minimum_date) {
            $criteria->{'me.date_created'} =
              {'>=' => $self->db_time($strp->parse_datetime($minimum_date))
              };
        } elsif ($maximum_date) {
            $criteria->{'me.date_created'} =
              {'<' => $self->db_time($strp->parse_datetime($maximum_date))};
        }
    
        my $attributes = {
            page     => $page,
            rows     => $self->pagesize,
            order_by => 'me.date_updated desc'
        };
    
        if ($join) {
            $attributes->{join} = 'section';
        }
    
        $jobs = $self->EtlpJob()->search($criteria, $attributes);
    
        return $jobs;
    }
    
    method get_config_list(Maybe[Str] $section_name?) {
        my $criteria;
        my $attributes = {order_by => 'config_name'};
    
        if ($section_name) {
            $criteria->{section_name} = $section_name;
            $attributes->{join}       = 'etlp_section';
        }
    
        return $self->EtlpConfiguration()->search($criteria, $attributes);
    }
    
    method get_section_list(Maybe[Int] $config_id?) {
        my $attributes = {
            select   => 'section_name',
            distinct => '1',
            order_by => 'section_name',
        };
    
        my $criteria;
    
        if ($config_id) {
            $criteria->{config_id} = $config_id;
        }
    
        return $self->EtlpSection()->search($criteria, $attributes);
    }
    
    method get_config_section_options(Maybe[Int] $config_id?) {
        my $option_text = '<option value=""/>';
        my $criteria;
    
        $criteria = {config_id => $config_id} if $config_id;
    
        my $section_rs =
          $self->EtlpSection()->search($criteria, {order_by => 'section_name',});
    
        while (my $section = $section_rs->next) {
            $option_text .=
                '<option value ="'
              . $section->section_name . '">'
              . $section->section_name
              . '</option>';
        }
    
        return $option_text;
    }
    
    method get_section_config_options(Maybe[Str] $section_name?) {
        my $option_text  = '<option value=""/>';
        my $criteria;
    
        $criteria = {section_name => $section_name} if $section_name;
    
        my $config_rs = $self->EtlppConfig->search(
            $criteria,
            {
                join     => 'sections',
                order_by => 'config_name'
            }
        );
    
        while (my $config = $config_rs->next) {
            $option_text .=
                '<option value ="'
              . $config->config_id . '">'
              . $config->config_name
              . '</option>';
        }
    
        return $option_text;
    
    }
}
       
=head1 NAME

ETLp::Audit::Browser::Model::Job - Model Class for interacting
with Runtime Process Audit Records

=head1 SYNOPSIS

    use ETLp::Audit::Browser::Model::Job;
    
    my $model = ETLp::Audit::Browser::Model::Job->new();
    my $jobs = $model->get_jobs(page => 3);
    
=head1 METHODS

=head2 get_jobs

Returns a resultset on the etlpp_job table. It will a page at
a time, and is ordered by date_updated descending

=head3 Parameters

All of the following parameters are optional:
    
    * page. Integer. The page you wish to return. Defaults to one
    * section_name. The section the job belongs to
    * config_id. The configuration file that the section belongs to
    * status_id. The status to filter the results by
    * minimum_date. The earliest date that the job ran
    * maximum_date. The latest data that the job ran
    
=head3 Returns

    * A DBIx::Class resultset
    
=head2 get_config_list

Return a list of all configuration files

=head3 Parameters

    * section_name. Optional. Will filter the configuration file to those
      that have the section name    
    
=head3 Returns

    * DBIx::Class resultset
    
=head2 get_section_list

Get an alphabetical list of all sections. 

=head3 Parameters

    * config_id. Optional. The requests\ will filter on config_id if one
      is supplied

=head3 Returns

    * DBIx::Class resultset
    
=head2 get_config_section_options

Given a config id, construct an HTML option list comprisng of sections that
belong to the config

=head3 Parameters

    * A config_id. 
    
=head3 Returns

    * A list of all sections that belong to the config_id as a string of
      HTML <option> tags
    
=head2 get_section_config_options

Given a section, construct an HTML option list comprisng of sections that
belong to the config

=head3 Parameters

    * A section name. 
    
=head3 Returns

    * A list of all configurations that have a section with the supplied
      name as a string consisting of HTML <option> tages

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut


