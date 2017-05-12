# $Id: /mirror/gungho/lib/Gungho/Component/RobotRules/Rule.pm 31623 2007-12-01T04:12:45.036041Z lestrrat  $

package Gungho::Component::RobotRules::Rule;
use strict;
use warnings;
use base qw(Gungho::Base);
use URI;

__PACKAGE__->mk_accessors($_) for qw(rules);

sub new
{
    my $class = shift;
    my $self  = $class->next::method();
    $self->setup(@_);
    $self;
}

sub setup
{
    my $self = shift;
    my $rules = shift;
    $self->rules($rules);
}

sub allowed
{
    my $self = shift;
    my $c    = shift;
    my $uri  = shift;

    $uri = URI->new($uri) unless ref $uri;
    my $str   = $uri->path_query || '/';
    my $rules = $self->rules;

    # XXX - There seems to be a problem where each %$rules doesn't get
    # reset when we get out of the while loop in the middle of execution.
    # We do this stupid hack to make sure that the context is reset correctly
    keys %$rules;
    while (my ($key, $list) = each %$rules) {
        next unless $self->is_me($c, $key);

        foreach my $rule (@$list) {
            return 1 unless length $rule;
            return 0 if index($str, $rule) == 0;
        }
        return 1;
    }
    return 1;
}

sub is_me
{
    my $self = shift;
    my $c    = shift;
    my $name = shift;

    return $name eq '*' || index(lc($c->user_agent), lc($name)) >= 0;
}

1;

__END__

=head1 NAME

Gungho::Component::RobotRules::Rule - A Rule Object

=head1 SYNOPSIS

  use Gungho::Component::RobotRules::Rule;
  my $rule = Gungho::Component::RobotRules::Rule->new(
    'UserAgent A' => [ '/foo', '/bar' ],
    'UserAgent B' => [ '/baz', '/quux' ],
  );

=head1 DESCRIPTION

This modules stores the RobotRules ruleset for a particular host.

=head1 METHODS

=head2 new

Creates a new rule. A single rule is a set of subrules that represents
an user-agent to a list of denied paths.

No host information is stored.

=head2 setup

Initializes the rule.

=head2 allowed($c, $uri)

Returns true if the given URL is allowed within this ruleset

=head2 is_me($c,$string)

Returns true if $string matches our user agent string contained in $c->user_agent

=cut
