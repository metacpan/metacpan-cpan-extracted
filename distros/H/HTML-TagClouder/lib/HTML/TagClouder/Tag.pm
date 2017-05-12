
package HTML::TagClouder::Tag;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(label uri count timestamp count_norm);

sub new
{
    shift->SUPER::new({@_});
}

1;

__END__

=head1 NAME

HTML::TagClouder::Tag - A Tag Object

=head1 METHODS

=head2 new

=head2 label

=head2 uri

=head2 count

=head2 timestamp

=head2 count_norm *THIS METHOD NAME IS STILL TBD*

=cut


