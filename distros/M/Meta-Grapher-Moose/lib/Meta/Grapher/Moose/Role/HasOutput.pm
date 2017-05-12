package Meta::Grapher::Moose::Role::HasOutput;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.03';

use Moose::Role;

has output => (
    is  => 'ro',
    isa => 'Str',
);

has format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_format',
);

sub has_output { defined $_[0]->output }

sub _build_format {
    my $self = shift;

    # attempt to use the file extension as the format, if there is a usable
    # extension that is...
    my $ext;
    unless ( $self->has_output
        && ( ($ext) = $self->output =~ /[.]([^.]+)\z/ ) ) {
        return 'src';
    }

    return $ext;
}

1;

# ABSTRACT: Role with standard way to specify Meta::Grapher::Moose output

__END__

=pod

=encoding UTF-8

=head1 NAME

Meta::Grapher::Moose::Role::HasOutput - Role with standard way to specify Meta::Grapher::Moose output

=head1 VERSION

version 1.03

=for Pod::Coverage output has_output format

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Meta-Grapher-Moose>
(or L<bug-meta-grapher-moose@rt.cpan.org|mailto:bug-meta-grapher-moose@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
