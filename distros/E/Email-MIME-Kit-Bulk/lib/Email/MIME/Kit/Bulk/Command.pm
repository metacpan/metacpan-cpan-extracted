package Email::MIME::Kit::Bulk::Command;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: send bulk emails using Email::MIME::Kit
$Email::MIME::Kit::Bulk::Command::VERSION = '0.0.3';

use strict;
use warnings;

use MooseX::App::Simple;

use Email::MIME::Kit::Bulk;
use Email::MIME::Kit::Bulk::Target;
use JSON;
use MooseX::Types::Path::Tiny qw/ Path /;
use PerlX::Maybe;

option kit => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    coerce   => 1,
    documentation => 'path to the mime kit directory',
);

option from => (
    is  => 'ro',
    isa => 'Str',
    documentation => 'sender address',
    required => 1,
);

option processes => (
    is  => 'ro',
    isa => 'Maybe[Int]',
    documentation => 'nbr of parallel processes for sending emails',
);

option quiet => (
    is => 'ro',
    isa => 'Bool',
    documentation => q{don't output anything},
    default => 0,
);

has transport => (
    is => 'ro',
);

has _targets_file => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub { shift->kit->child('targets.json') },
);

sub BUILD {
    my $self = shift;

    die 'Kit directory must have a manifest'
        unless grep { -r }
               grep {
                   my $f = $_->basename;
                   $f =~ /^manifest\./ && $f =~ /\.json$/
               } $self->kit->children;

    die 'Cannot find target specification (' . $self->_targets_file . ')'
        unless -e $self->_targets_file;
}

sub run {
    my $self = shift;

    my @addresses = @{ decode_json($self->_targets_file->slurp) };

    my $mailer = Email::MIME::Kit::Bulk->new(
        verbose => !$self->quiet,
        targets => [ map { Email::MIME::Kit::Bulk::Target->new($_) } @addresses ],
        kit     => $self->kit,
        maybe from      => $self->from,
        maybe processes => $self->processes,
        maybe transport => $self->transport,
    );

    $mailer->send;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::Bulk::Command - send bulk emails using Email::MIME::Kit

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

    use Email::MIME::Kit::Bulk::Command;

    Email::MIME::Kit::Bulk::Command->new_with_options->run;

=head1 AUTHORS

=over 4

=item *

Jesse Luehrs    <doy@cpan.org>

=item *

Yanick Champoux <yanick.champoux@iinteractive.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Infinity Interactive <contact@iinteractive.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
