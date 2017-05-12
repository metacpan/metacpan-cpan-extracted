package IPTables::Mangle;
use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

IPTables::Mangle - Manage iptables rules with Perl / YAML

=head1 SYNOPSIS

Given a config file, produces rules for iptables-restore.

Example YAML file, for ease of viewing:

   filter:
       forward: { default: drop }
       foo:
           rules:
              - src: 9.9.9.9
              - src: 10.10.10.10
                action: drop
       input:
           # by default, do not allow any connections unless authorized
           # in the rules below
           default: drop

           # by default, if no "action" is given to a rule below, accept it
           default_rule_action: accept 

           rules:
               # Accept all traffic on loopback interface
               - in-interface: lo

               # Don't disconnect existing connections during a rule change.
               - { match: state, state: 'ESTABLISHED,RELATED' }

               # Allow for pings (no more than 10 a second)
               - { protocol: icmp, icmp-type: 8, match: limit, limit: 10/sec }

               # Allow these IPs, no matter what
               - src: 123.123.123.123

               # example of blocking an IP 
               - { action: drop, src: 8.8.8.8 }

               # example of allowing ip to connect to port 25 (smtp) (one-line)
               - { protocol: tcp, dport: 25, src: 4.2.2.2 }

               # jump to rules defined in "foo" above
               - action: foo

               # if there are no more rules, reject the connection with icmp, don't just let it hang
               - action: reject
                 action_options:
                     reject-with: icmp-admin-prohibited

=head1 DESCRIPTION

This module allows for the management of iptables rules with Perl / YAML.

=head1 TABLES

The top hashref is the table for iptables, this can be either mangle, nat, or filter. 

=head1 CHAINS

The hashref under the top hashref is the chain name.  For system chains the default chainrule can
be set by setting a default hashref in the chain.

$VAR1->{filter}{input} would be the input chain for the filter table.

=head1 CHAIN RULES

Chainrules live in a 'rules' arrayref under the chain, $VAR1->{filter}{input}{rules}, for example.

Every rule in the chain is a hashref which builds a rule.  By default, the jump in the rules, referenced
as 'action' in a rule, is set to accept.  The default action can be modified by changing 
'default_rule_action' in the chain.  Every key in the rule's hashref represents a parameter prefixed by two dashes, '--', 
in an iptables rule.  Two things to note here are that 'action' in a rule really maps to 'jump' in iptables, and 
a special action_options key exists, which references a hashref, which appends options after the iptables jump.  This is 
useful for things like setting '--reject-with' after a jump to reject.


Examples of a chain rule:


# by default, allow this ip

$VAR1->{filter}{input}{rules}[0] = { src => '10.10.10.10' } ;


# allow this ip on port 25 tcp, using accept default

$VAR1->{filter}{input}{rules}[1] = { protocol: 'tcp', dport: 25, src => '10.10.10.10' } ;


# make it explicit

$VAR1->{filter}{input}{rules}[2] = { protocol: 'tcp', dport: 25, src => '10.10.10.10', action => 'accept' } ;


# blacklist an ip

$VAR1->{filter}{input}{rules}[3] = { src => '10.10.10.10', action => 'drop' } ;

# reject with icmp  message

$VAR1->{filter}{input}{rules}[-1] = {
    action => 'reject', 
    action_options => {
        reject-with: 'icmp-admin-prohibited',
    },
};

=cut

=head1 METHODS

=head2 process_config

Given a hashref, produces rules usable by iptables-restore.

Returns one string.

=cut

sub process_config
{
    my $config = shift;

    my $config_out = '';

    $config_out .= _process_table({
        table  => 'mangle',
        chains => [ qw(prerouting input forward output postrouting) ],
        config => $config,
    });

    $config_out .= _process_table({
        table  => 'nat',
        chains => [ qw(prerouting postrouting output) ],
        config => $config,
    });

    $config_out .= _process_table({
        table  => 'filter',
        chains => [ qw(input forward output) ],
        config => $config,
    });

    return $config_out;
}

sub _process_table
{
    my $args = shift;

    my $table  = $args->{table};
    my $config = $args->{config};

    my $table_out = '';
    $table_out .= "*$table\n";

    # configure built-in chains
    $table_out .= ":" . uc($_) . ' ' .
        (exists $config->{$table}{$_} ? 
         uc($config->{$table}{$_}{default}) : 'ACCEPT') . "\n"
            for @{$args->{chains}};

    # configure custom chains
    for my $chain (keys %{$config->{$table} || {} })
    {
        # skip built-in chains
        next if grep { $chain eq $_ } @{$args->{chains}};

        $table_out .= ":" . uc($chain) . " -\n";
    }

    for my $chain (keys %{$config->{$table} || {} })
    {
        $table_out .= &_process_rule({
            target => (
                uc($_->{action} || '') 
             || uc($config->{$table}{$chain}{default_rule_action} || '') 
             || 'ACCEPT'),
            chain  => uc($chain),
            rule   => $_
        }) . "\n" for @{$config->{filter}{$chain}{rules} || []};
    }

    $table_out .= "COMMIT\n";

    return $table_out;
}

sub _process_rule
{
    my $args = shift;
    my $output = "-A $args->{chain} ";

    # remove action from rule
    delete $args->{rule}{action};

    # grab action options
    my $action_opts = delete $args->{rule}{action_options};
    my $action_opts_str = '';

    if ($action_opts)
    {
        $action_opts_str .= "--$_ $action_opts->{$_} "
            for keys %$action_opts;
    }

    $output .= "--$_ $args->{rule}{$_} "
        for keys %{$args->{rule}};

    $output .= "-j $args->{target} $action_opts_str";

    return $output;
}

1;

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut
