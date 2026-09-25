use strict;

package HTML::FormFu::I18N;
# ABSTRACT: localization base class
$HTML::FormFu::I18N::VERSION = '2.09';
use Moose;

extends 'Locale::Maketext';

*loc = \&localize;

sub localize {
    my $self = shift;

    return $self->maketext(@_);
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::I18N - localization base class

=head1 VERSION

version 2.09

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026, 2018, 2016, 2015, 2012, 2011 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
