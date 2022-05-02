package File::KeePass::Agent::KDBX;
# ABSTRACT: A KeePass 2 agent

use utf8;
use warnings;
use strict;

use Module::Load;
use namespace::clean;

use parent 'File::KeePass::Agent';

our $VERSION = '0.901'; # VERSION

our $KEEPASS_CLASS;

sub new {
    my $class = shift;
    my %args  = @_ == 1 && (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
    return bless \%args, $class;
}

sub run { __PACKAGE__->new->SUPER::run(@_) }


sub keepass_class {
    (ref $_[0] eq 'HASH') && $_[0]->{keepass_class}
        || $KEEPASS_CLASS || $ENV{PERL_FILE_KEEPASS_CLASS} || 'File::KeePass::KDBX';
}

sub load_keepass {
    my $self = shift;
    load $self->keepass_class;
    return $self->SUPER::load_keepass(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KeePass::Agent::KDBX - A KeePass 2 agent

=head1 VERSION

version 0.901

=head1 SYNOPSIS

    use File::KeePass::Agent::KDBX;

    File::KeePass::Agent::KDBX->new(%attributes)->run;
    # OR
    File::KeePass::Agent::KDBX->new(%attributes)->run($filepath, $password);

See L<File::KeePass::Agent> for a more complete synopsis.

=head1 DESCRIPTION

This is a thin subclass of L<File::KeePass::Agent> that uses the newer L<File::KDBX> parser. It is meant to be
a drop-in replacement. This module really doesn't do anything except provide a way to load a backend other
than L<File::KeePass>. You could accomplish the same thing with B<File::KeePass::Agent> directly in a hackier
way:

    use File::KeePass::Agent;
    use File::KeePass::KDBX;

    no warnings 'redefine';
    *File::KeePass::Agent::keepass_class = sub { 'File::KeePass::KDBX' };

Perhaps in the future B<File::KeePass::Agent> will support this without monkey-patching. Until then, this
module allows setting the backend B<File::KeePass> class in three ways (in decreasing precedence):

Pass as an attribute to the constructor:

    File::KeePass::Agent::KDBX->new(keepass_class => 'My::KeePass')->run;

as a package variable:

    $File::KeePass::Agent::KDBX::KEEPASS_CLASS = 'My::KeePass';
    File::KeePass::Agent::KDBX->new->run;

or from the environment:

    $ENV{PERL_FILE_KEEPASS_CLASS} = 'My::KeePass';
    File::KeePass::Agent::KDBX->new->run;

=head1 ATTRIBUTES

=head2 keepass_class

    $k = File::KeePass::Agent::KDBX->keepass_class;
    $k = $agent->keepass_class;

Get the backend L<File::KeePass> (or compatible) package name.

=for Pod::Coverage load_keepass

=head1 ENVIRONMENT

=over 4

=item *

C<PERL_FILE_KEEPASS_CLASS> - Name of the backend class (default: C<File::KeePass::KDBX>)

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KeePass-Agent-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
