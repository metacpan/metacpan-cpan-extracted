use strict;
use warnings;
package # hide from PAUSE! but see Dist::Zilla::Plugin::Breaks...
    Breaks;
use Moose;
with 'Dist::Zilla::Role::MetaProvider';
use CPAN::Meta::Requirements;

has breaks => (
    is => 'ro', isa => 'HashRef[Str]',
    required => 1,
);
around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = $self->$orig(@_);
    return {
        zilla => delete $args->{zilla},
        plugin_name => delete $args->{plugin_name},
        breaks => $args,
    };
};
sub metadata
{
    my $self = shift;
    my $reqs = CPAN::Meta::Requirements->new;
    my $breaks_data = $self->breaks;
    $reqs->add_string_requirement($_, $breaks_data->{$_}) foreach keys %$breaks_data;
    return { x_breaks => $reqs->as_string_hash };
}
1;
