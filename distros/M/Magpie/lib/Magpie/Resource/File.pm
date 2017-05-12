package Magpie::Resource::File;
# ABSTRACT: INCOMPLETE - Basic file Resource implementation.
$Magpie::Resource::File::VERSION = '1.163200';
use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Plack::App::File;

has root => (
    #traits => [ qw(MooseX::UndefTolerant::Attribute)],
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_root {
    my $self = shift;
    warn "buildroot called";
    my $docroot = undef;
    if ( defined $self->request->env->{DOCUMENT_ROOT} ) {
        $docroot = $self->request->env->{DOCUMENT_ROOT};
    }
    else {
        $docroot = Cwd::getcwd;
    }

    return Cwd::realpath($docroot);
}

sub absolute_path {
    my $self = shift;
    return Cwd::realpath($self->root . $self->request->env->{PATH_INFO});
}

sub mtime {
    my @stat = stat(shift->absolute_path);
    return scalar @stat ? $stat[9] : -1;
}

sub GET {
    my $self = shift;
    my $ctxt = shift;
    my %paf_args = ();
    my $paf = Plack::App::File->new(root => $self->root);
    my $r = $paf->call($self->request->env);

    unless ( $r->[0] == 200 ) {
        $self->set_error({
            status_code => $r->[0],
            additional_headers => $r->[1],
            reason => join "\n", @{$r->[2]},
        });
    }
    $self->parent_handler->resource($self);
    $self->data( $r->[2] );

    return OK;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Resource::File - INCOMPLETE - Basic file Resource implementation.

=head1 VERSION

version 1.163200

# SEALSO: Magpie, Magpie::Resource

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
