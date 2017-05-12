#!/usr/bin/env perl

use Module::Find;
use Data::Section::Simple qw/get_data_section/;
use Text::MicroTemplate qw/render_mt/;

sub find_all_policies {
    my $namespace = 'Perl::Critic::Policy';
    my @modules   = findallmod($namespace);
    return [ map { substr($_, length($namespace) + 2) } @modules ];
}

sub filter_policies {
    return $_[0];
}

sub policies_to_string {
    my $policies = shift;
    return join ', ', @$policies;
}

sub load_template {
    return get_data_section('perlcriticrc');
}

sub main {
    my $policies = filter_policies(find_all_policies);
    my $template = load_template;
    print render_mt($template, policies_to_string($policies));
    print "\n";
}

main unless caller;

__DATA__
@@ perlcriticrc
only = 1
include = <?= $_[0] ?>
