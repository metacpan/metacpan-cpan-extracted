package JavaScript::Script;

use strict;
use warnings;

sub new {
    my ($pkg, $context, $source) = @_;

    $pkg = ref $pkg || $pkg;

    my $script = jss_compile($context, $source);
    my $self = bless { _impl => $script }, $pkg;
    
    return $self;
}

sub exec {
    my ($self) = @_;
    
    my $rval = jss_execute($self->{_impl});
    
    return $rval;
}

1;
__END__

=head1 NAME

JavaScript::Script - Pre-compiled JavaScript

=head1 DESCRIPTION

If you have a big script that has to be executed over and over again compilation time may be significant.
The method C<compile> in C<JavaScript::Context> provides a mean of returning a pre-compiled script which is
an instance of this class which can be executed without the need of compilation.

=head1 INTERFACE

=head2 INSTANCE METHODS

=over 4

=item exec

Executes the script and returns the result of the last statement.

=back

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item new ( $context, $source )

Creates a new script in context.

=item jss_compile ( PJS_Context *cx, char *source )

Compiles a script and returns a C<PJS_Script *> associated with the context and the C<JSScript *>.

=item jss_execute ( PJS_Script * )

Executes the script

=back

=end PRIVATE

=cut

