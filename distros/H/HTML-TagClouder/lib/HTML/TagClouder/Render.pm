package HTML::TagClouder::Render;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(cloud);

sub new {
    my $class = shift;
    return $class->next::method({ @_ });
}

sub render { die "render() unimplemented" }

1;

__END__

=head1 NAME

HTML::TagClouder::Render - Base Render Class

=head1 METHODS

=head2 new %args

=head2 render

Renders the cloud. Must be overriden in the subclass

=cut