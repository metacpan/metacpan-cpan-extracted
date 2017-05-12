package Excel::Template::Base;

use strict;

use Excel::Template::Factory;

sub new
{
    my $class = shift;

    push @_, %{shift @_} while ref $_[0] eq 'HASH';
    (@_ % 2)
        and die "$class->new() called with odd number of option parameters\n";

    my %x = @_;

    # Do not use a hashref-slice here because of the uppercase'ing
    my $self = {};
    $self->{uc $_} = $x{$_} for keys %x;

    bless $self, $class;
}

*isa = *isa = \&Excel::Template::Factory::isa;
*is_embedded = *is_embedded = \&Excel::Template::Factory::is_embedded;

#sub calculate { ($_[1])->get(@_[0,2]) }
#{
#    my $self = shift;
#    my ($context, $attr) = @_;
#
#    return $context->get($self, $attr);
#}

sub enter_scope { ($_[1])->enter_scope($_[0]) }
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    return $context->enter_scope($self);
#}

sub exit_scope { ($_[1])->exit_scope($_[0], $_[2]) }
#{
#    my $self = shift;
#    my ($context, $no_delta) = @_;
#
#    return $context->exit_scope($self, $no_delta);
#}

sub deltas
{
#    my $self = shift;
#    my ($context) = @_;

    return {};
}

# Everyone seems to have their own versions.
# Maybe, it's part of the API to require that you have the right one of these
# defined?
#sub resolve
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    '';
#}
#
#sub render
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    1;
#}

1;
__END__

=head1 NAME

Excel::Template::Base - Excel::Template::Base

=head1 PURPOSE

Base class for all Excel::Template classes

=head1 NODE NAME

None

=head1 INHERITANCE

None

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 EFFECTS

None

=head1 DEPENDENCIES

None

=head1 METHODS

=head2 calculate

This is a wrapper around Excel::Template::Context->get()

=head2 isa

This is a wrapper around Excel::Template::Factory->isa()

=head2 is_embedded

This is a wrapper around Excel::Template::Factory->is_embedded()

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

=cut
