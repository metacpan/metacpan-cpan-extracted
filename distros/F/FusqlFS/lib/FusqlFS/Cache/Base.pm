use strict;
use 5.010;

package FusqlFS::Cache::Base;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

=head1 NAME

FusqlFS::Cache::Base - base abstract class for cache strategy classes
implementation

=head1 SYNOPSIS

    package FusqlFS::Cache::CleverStrategy;
    use parent 'FusqlFS::Cache::Base';

    sub TIEHASH
    {
        # ...
    }

    sub FETCH
    {
        # ...
    }

    sub STORE
    {
        # ...
    }

=head1 DESCRIPTION

This is an abstract base class for all cache strategy subclasses.

FusqlFS cache is a hash. To implement any cache strategy you need to create
a hash tie()-able class (see also L<perltie> for more info) which will be
tied to cache hash and should implement cache strategy you want.

This class defines main cache class interface. See L</METHODS> section for
details on this interface.

=head1 METHODS

=over

=cut

=item new

Class constructor (so called).

Input: @parameters.
Output: $cache_hashref.

This method is not a real constructor, it's actually a tie()-er.

It creates new empty hash, checks if given parameters satisfy this concrete
class implementation and tie()s hash to this class if everything ok.

The returned value is a hashref tied to the class (or untied if parameters
don't satisfy class's requirements). See also L</is_needed> method to learn how
criteria for correct cache parameters are defined.

=begin testing new

#!noinst

my $test = $_tcls->new();
isa_ok $test, 'HASH';
is tied($test), undef;

=end testing
=cut
sub new
{
    my $class = shift;
    my %cache;
    tie %cache, $class, @_ if $class->is_needed(@_);
    return \%cache;
}

=item is_needed

I<Abstract method> called to determine if cache parameters satisfy this cache
strategy's criteria.

Input: @parameters.
Output: $satisfied.

This method is called before the class is tied to real cache hash to determine
if cache strategy implemented by the class can be used with given parameters.

The method is passed the same parameters, as L</new> method, and must return
boolean value: true if these parameters have sense for the cache strategy
or false otherwise.

If this method returns false no cache class instance is created nor tied to
cache hash, so cache strategy is fallen back to `memory'.

See also L<FusqlFS::Cache> for more info about cache strategies initialization.

=cut
sub is_needed
{
    return;
}

1;

__END__

=back
