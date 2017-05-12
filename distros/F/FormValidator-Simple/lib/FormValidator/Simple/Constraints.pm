package FormValidator::Simple::Constraints;
use strict;
use base qw/FormValidator::Simple::ArrayList/;
use FormValidator::Simple::Constants;
use FormValidator::Simple::Iterator;

__PACKAGE__->mk_accessors(qw/needs_blank_check/);

sub _init {
    my $self = shift;
    $self->needs_blank_check( FALSE );
}

sub iterator {
    my $self = shift;
    return FormValidator::Simple::Constraint::Iterator->new($self);
}

package FormValidator::Simple::Constraint::Iterator;
use base qw/FormValidator::Simple::Iterator/;

1;
__END__


