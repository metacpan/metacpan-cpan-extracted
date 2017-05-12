package Form::Factory::Stasher::Memory;
$Form::Factory::Stasher::Memory::VERSION = '0.022';
use Moose;

with qw( Form::Factory::Stasher );

# ABSTRACT: Remember things in a Perl hash


has stash_hash => (
    is        => 'rw',
    isa       => 'HashRef',
    required  => 1,
    default   => sub { {} },
);


sub stash {
    my ($self, $moniker, $stash) = @_;
    $self->stash_hash->{ $moniker } = $stash;
}


sub unstash {
    my ($self, $moniker) = @_;
    delete $self->stash_hash->{ $moniker };
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Stasher::Memory - Remember things in a Perl hash

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  $c->session->{stash_stuff} ||= {};
  my $stasher = Form::Factory::Stasher::Memory->new(
      stash_hash => $c->session->{stash_stuff},
  );

  $stasher->stash(foo => { blah => 1 });
  my $bar = $stasher->unstash('bar');

=head1 DESCRIPTION

Stashes things into a plain memory hash. This is useful if you already have a mechanism for remember things that can be reused via a hash.

=head1 ATTRIBUTES

=head2 stash_hash

The hash reference to stash stuff into. Defaults to an empty anonymous hash.

=head1 METHODS

=head2 stash

Stash the stuff given.

=head2 unstash

Unstash the stuff requested.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
