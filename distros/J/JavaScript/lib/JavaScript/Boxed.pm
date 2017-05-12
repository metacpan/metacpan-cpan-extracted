package JavaScript::Boxed;

use strict;
use warnings;

use JavaScript::Context;

sub new {
    my ($pkg, $content, $context, $jsvalue) = @_;
    $pkg = ref $pkg || $pkg;

    $context = JavaScript::Context->find($context);
    my $self = bless \[$content, $context, $jsvalue], $pkg;
    return $self;
}

sub content {
    return ${$_[0]}->[0];
}

sub context {
    return ${$_[0]}->[1];
}

sub jsvalue {
    return ${$_[0]}->[2];
}

my $in_global_destruct = 0;
END { $in_global_destruct = 1; }

sub DESTROY {
    my $self = shift;
    return if $in_global_destruct;

    my $cx = $self->context();
    
    JavaScript::Context::jsc_free_root( $self->context, $self->jsvalue);
}

1;
__END__
    
=head1 NAME

JavaScript::Boxed - Encapsulates a JavaScript object in order to keep track of memory

=head1 DESCRIPTION

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( $content, $context, $jsvalue )

Creates a new "boxed" value.

=back

=head2 INSTANCE METHODS

=over 4

=item content

=item context

=item jsvalue

=back

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over

=back

=end PRIVATE

=cut
