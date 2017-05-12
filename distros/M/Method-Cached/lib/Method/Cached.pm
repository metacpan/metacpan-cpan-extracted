package Method::Cached;

use 5.008_001;
use strict;
use warnings;
use Sub::Attribute;
use Method::Cached::Manager;
use Method::Cached::KeyRule;

our $VERSION = '0.051';

sub import {
    my $class  = shift;
    my $caller = caller 0;
    return unless $class eq __PACKAGE__;
    return if $caller->isa(__PACKAGE__);
    {
        no strict 'refs';
        push @{$caller . '::ISA'}, __PACKAGE__;
    }
}

sub Cached :ATTR_SUB {
    my ($package, $sym_ref, $code_ref, $attr, $args_code) = @_;
    my $name = $package . '::' . *{$sym_ref}{NAME};
    my @args = defined $args_code ? eval(<<__EVAL__) : (); ## no critic
        package $package;
        no strict 'subs';
        no warnings;
        local \$SIG{__WARN__} = sub{ die };
        ($args_code)
__EVAL__
    Method::Cached::Manager->set_method_setting($name, $attr, @args);
    {
        no strict 'refs';
        no warnings 'redefine';
        *{$name} = sub {
            unshift @_, $name, $code_ref, wantarray;
            goto &Method::Cached::LocalWrapper::_wrapper;
        };
    }
}

{
    package #
        Method::Cached::LocalWrapper;

    sub _wrapper {
        my ($name, $code_ref, $warray) = splice @_, 0, 3;
        my $method = Method::Cached::Manager->get_method_setting($name);
        my $domain = Method::Cached::Manager->get_domain_setting($method->{domain});
        my $rule   = $method->{key_rule} || $domain->{key_rule};
        my $key    = Method::Cached::KeyRule::regularize($rule, $name, [ @_ ]);
        my $key_f  = $key . ($warray ? ':l' : ':s');
        my $cache  = Method::Cached::Manager->get_instance($domain);
        my $ret    = $cache->get($key_f);
        unless ($ret) {
            $ret = [ $warray ? $code_ref->(@_) : scalar $code_ref->(@_) ];
            $cache->set($key_f, $ret, $method->{expires} || 0);
        }
        return $warray ? @{ $ret } : $ret->[0];
    }
}

1;

__END__

=head1 NAME

Method::Cached - The return value of the method is cached to your storage

=head1 SYNOPSIS

 package Foo;
 
 use Method::Cached;

 sub cached :Cached { time . rand }
 sub no_cached      { time . rand }
 
 package main;

 my $test1 = { cached => Foo->cached, no_cached => Foo->no_cached };
 
 sleep 1; # It is preferable that time passes in this test
 
 my $test2 = { cached => Foo->cached, no_cached => Foo->no_cached };
 
 is   $test1->{cached},    $test2->{cached};
 isnt $test1->{no_cached}, $test2->{no_cached};

=head1 DESCRIPTION

Method::Cached offers the following mechanisms:

The return value of the method is stored in storage, and
the value stored when being execute it next time is returned.

=head2 SETTING OF CACHED DOMAIN

In beginning logic or the start-up script:

 use Method::Cached::Manager
     -default => { class => 'Cache::FastMmap' },
     -domains => {
         'some-namespace' => { class => 'Cache::Memcached::Fast', args => [ ... ] },
     },
 ;

For more documentation on setting of cached domain, see L<Method::Cached::Manager>.

=head2 DEFINITION OF METHODS

This function is mounting used as an attribute of the method.

=over 4

=item B<:Cached ( DOMAIN_NAME, EXPIRES, [, KEY_RULE, ...] )>

The cached rule is defined specifying the domain name.

 sub message :Cached('some-namespace', 60 * 5, LIST) { ... }

=item B<:Cached ( EXPIRES, [, KEY_RULE, ...] )>

When the domain name is omitted, the domain of default is used.

 sub message :Cached(60 * 5, LIST) { ... }

=back

=head2 RULE TO GENERATE KEY

=over 4

=item B<LIST>

=item B<HASH>

=item B<SELF_SHIFT>

=item B<PER_OBJECT>

=back

=head2 OPTIONAL, RULE TO GENERATE KEY

 use Method::Cached::KeyRule::Serialize;

=over 4

=item B<SERIALIZE>

=item B<SELF_CODED>

=back

=head1 METHODS

=over 4

=item B<default_domain ($setting)>

=item B<set_domain (%domain_settings)>

=item B<get_domain ($domain_name)>

=back

=head1 AUTHOR

Satoshi Ohkubo E<lt>s.ohkubo@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
