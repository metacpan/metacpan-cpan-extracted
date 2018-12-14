use strict;

package HTML::FormFu::OutputProcessor;
$HTML::FormFu::OutputProcessor::VERSION = '2.07';
# ABSTRACT: Post-process HTML output

use Moose;
use MooseX::Attribute::Chained;

with 'HTML::FormFu::Role::HasParent', 'HTML::FormFu::Role::Populate';

use HTML::FormFu::ObjectUtil qw( form parent );

has type => ( is => 'rw', traits => ['Chained'] );

sub clone {
    my ($self) = @_;

    my %new = %$self;

    return bless \%new, ref $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::OutputProcessor - Post-process HTML output

=head1 VERSION

version 2.07

=head1 DESCRIPTION

Post-process a form or element's HTML.

=head1 CORE OUTPUT PROCESSORS

=over

=item L<HTML::FormFu::OutputProcessor::Indent>

=item L<HTML::FormFu::OutputProcessor::StripWhitespace>

=back

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
