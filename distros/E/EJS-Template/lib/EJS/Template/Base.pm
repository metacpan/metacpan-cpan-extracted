use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::Base - Base class for some EJS::Template classes to hold common config

=cut

package EJS::Template::Base;

use Scalar::Util qw(reftype);

=head1 Methods

=head2 new

Common constructor with the config

=cut

sub new {
    my ($class, $config) = @_;
    $config = {} unless ref $config;
    $config = {map {$_ => $config->{$_}} @EJS::Template::CONFIG_KEYS};
    return bless {config => $config}, $class;
}

=head2 config

Retrieves the config value.

=cut

sub config {
    my $self = shift;
    my $config = $self->{config};
    
    for my $name (@_) {
        if ((reftype($config) || '') eq 'HASH') {
            $config = $config->{$name};
        } else {
            return undef;
        }
    }
    
    return $config;
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=back

=cut

1;
