package Form::Factory::Processor::DeferredValue;
$Form::Factory::Processor::DeferredValue::VERSION = '0.022';
use Moose;

# ABSTRACT: Tag class for deferred_values


has code => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
);


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Processor::DeferredValue - Tag class for deferred_values

=head1 VERSION

version 0.022

=head1 DESCRIPTION

No user serviceable parts. You void your non-existant warranty if you open this up.

See L<Form::Factory::Processor/deferred_value>. There's really nothing to see here.

=head1 SEE ALSO

L<Form::Factory::Processor>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
