package HTML::Feature::Result;
use strict;
use warnings;
use base qw(HTML::Feature::Base);

__PACKAGE__->mk_accessors($_) for qw(text title desc element root);

sub element_delete {
    my $self = shift;
    if ( $self->root ) {
        $self->root->delete();
    }
}

sub DESTROY {
    my $self = shift;
    $self->element_delete();
}
1;
__END__

=head1 NAME

HTML::Feature::Result -Result Class of HTML::Feature

=head1 SYNOPSYS

    my $result = HTML::Feature::Result;
    $result->title("title");
    $result->desc("desc");
    $result->text("text");
    retrun $result;

=head1 METHODS

=head2 new()

=head2 element_delete()

    avoid memory leak;

=head2 DESTROY

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut