use 5.008;
use strict;
use warnings;

package Error::Hierarchy::Container;
BEGIN {
  $Error::Hierarchy::Container::VERSION = '1.103530';
}

use Class::Trigger;
use Error::Hierarchy::Util 'load_class';

# ABSTRACT: Container for hierarchical exceptions
use parent qw(
  Data::Container
  Error::Hierarchy::Base
);

sub items_push {
    my ($self, @values) = @_;
    $self->call_trigger('before_push', @values);
    $self->SUPER::items_push(@values);

}

sub items_set_push {
    my ($self, @values) = @_;

    # Some methods won't work on non-E-H objects; report them so they appear
    # directly - e.g., in the error.log if running under mod_perl
    $self->call_trigger('before_push', @values);
    $self->SUPER::items_set_push(@values);
}

sub record {
    my ($self, $exception_class, %args) = @_;

    load_class $exception_class, 1;
    # make record() invisible to caller when reporting exception location
    local $Error::Depth = $Error::Depth + 1;
    $self->items_set_push($exception_class->record(%args));
}

# Given a list of uuid's, deletes all exceptions from the container whose uuid
# is one of those given.
sub delete_by_uuid {
    my ($self, @uuid) = @_;
    my %uuid;
    @uuid{@uuid} = ();
    $self->items(grep { !exists $uuid{$_} } $self->items);
}

sub delete_duplicate_exceptions {
    my $self = shift;
    my @items;
    my %seen;
    for my $exception ($self->items) {
        my %properties = $exception->properties_as_hash;
        $properties{__package} = ref $exception;
        my $signature =
          join ';' => map { $_ => $properties{$_} } sort keys %properties;
        next if $seen{$signature}++;
        push @items => $exception;
    }
    $self->items(@items);
    $self;
}
1;


__END__
=pod

=head1 NAME

Error::Hierarchy::Container - Container for hierarchical exceptions

=head1 VERSION

version 1.103530

=head1 SYNOPSIS

    my $my_exception = create_some_exception();
    my %exception_args = (foo => 'bar');
    my $uuid1 = gen_some_uuid();
    my $uuid2 = gen_some_uuid();

    my $container = Error::Hierarchy::Container->new;
    $container->items_set_push($my_exception);
    $container->record('Some::Exception', %exception_args);
    $container->delete_by_uuid($uuid1, $uuid2);

=head1 DESCRIPTION

This class implements a container for hierarchical exception objects. It is
effectively a L<Data::Container> but also has the following methods.

=head1 METHODS

=head2 record

Takes an exception class name (a string) and a hash of arguments. First the
exception is constructed with the given arguments, then it is added - using
C<items_set_push()> - to the container. It's really a shortcut that saves you
from having to record the exception and then adding it to the container
yourself.

=head2 delete_by_uuid

Takes a list of uuid values and deletes all those exceptions from the
container whose uuid appears in the given list.

=head2 delete_duplicate_exceptions

Deletes duplicate exceptions. Two exceptions are considered to be the same if
they are of the same class and have the same properties, as defined by the
exception's C<properties_as_hash()> method.

=head2 items_push

Overrides L<Data::Container>'s C<items_push()> method by calling the
C<before_push> trigger before pushing. The list of items to be pushed is
passed to the trigger. One possible use might be to warn if you try to push
any items that are not derived from L<Error::Hierarchy>. The trigger mechanism
is based on L<Class::Trigger>.

=head2 items_set_push

Similar to C<items_push()>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Error-Hierarchy>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Error-Hierarchy/>.

The development version lives at L<http://github.com/hanekomu/Error-Hierarchy>
and may be cloned from L<git://github.com/hanekomu/Error-Hierarchy>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

