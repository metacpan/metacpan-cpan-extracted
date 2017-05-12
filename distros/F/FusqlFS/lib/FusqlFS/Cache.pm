use strict;
use 5.010;

package FusqlFS::Cache;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

=head1 NAME

FusqlFS::Cache - main FusqlFS cache factory

=head1 SYNOPSIS

    use FusqlFS::Cache;

    our %cache;
    my $cache = FusqlFS::Cache->init(\%cache, 'limited', 10);
    # tied(%cache) == $cache

=head1 DESCRIPTION

This is a cache subsystem initialization class. It is an abstract factory
class, just like L<FusqlFS::Backend>, and thus it can't be instantiated
directly.

Its single method C<init()> accepts hashref as first argument, cache strategy
as second argument and cache threshold as third argument, and returns
L<FusqlFS::Cache::Base> subclass instance or undef, if cache is done directly
in memory without any complex cache logic layers.

FusqlFS cache is actually a simple hash, so all cache strategies are
implemented as hash tie()-able classes. See L<FusqlFS::Cache::Base> and its
subclasses on details of cache strategies implementation.

All this concrete class does (with its single C<init()> method) is just
verifies cache threshold, recognizes cache strategy by name and tie()s cache
hash given by hashref to cache class corresponding chosen cache strategy.

Special `memory' strategy means cache is done directly in memory and thus no
tie()ing is needed, and so C<init()> returns undef as no tied class is
instantiated. This strategy is also chosen in case of any errors, so if cache
strategy is not defined or not recognized or cache threshold have no sense for
chosen cache strategy, `memory' strategy is chosen, debug message is displayed
and undef is returned, leaving cache hash untied.

=cut

use Carp;

use FusqlFS::Cache::Limited;
use FusqlFS::Cache::File;

=begin testing init

#!noinst

foreach (qw(Limited File))
{
    my %cache;
    ok !FusqlFS::Cache->init(\%cache, lc $_, 0), $_.' cache strategy not chosen';
    ok !tied(%cache), $_.' cache handler is untied';

    isa_ok FusqlFS::Cache->init(\%cache, lc $_, 10), 'FusqlFS::Cache::'.$_, $_.' cache strategy chosen';
    isa_ok tied(%cache), 'FusqlFS::Cache::'.$_, $_.' cache handler tied';
}

my %cache;
ok !FusqlFS::Cache->init(\%cache, 'memory'), 'Memory cache strategy chosen';
ok !FusqlFS::Cache->init(\%cache, 'xxxxxx'), 'Memory cache strategy chosen (fallback 1)';
ok !FusqlFS::Cache->init(\%cache), 'Memory cache strategy chosen (fallback 2)';
ok !tied(%cache), 'Memory cache handler is untied';

=end testing
=cut
sub init
{
    my $class = shift;
    my $hash = shift;
    my $strategy = shift || 'memory';
    my $subclass = '';

    given ($strategy)
    {
        when ('memory')  { }
        when ('limited') { $subclass = '::Limited' }
        when ('file')    { $subclass = '::File' }
        default
        {
            #carp "Unknown cache strategy `$strategy', using default `memory' strategy";
        }
    }

    return unless $subclass;

    $class .= $subclass;
    unless ($class->is_needed(@_))
    {
        #carp "Given parameters don't match `$strategy' cache strategy, falling back to `memory' strategy";
        return;
    }

    tie %$hash, $class, @_;
}

1;
