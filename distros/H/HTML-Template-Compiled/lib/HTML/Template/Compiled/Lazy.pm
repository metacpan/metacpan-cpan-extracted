package HTML::Template::Compiled::Lazy;
use strict;
use warnings;
our $VERSION = '1.003'; # VERSION

use base 'HTML::Template::Compiled';

sub from_scratch {
    my ($self) = @_;
    # dummy method. wait until real compilation until output().
    return $self;
}

sub compile_early { 0 }

sub query {
    my ( $self, @args ) = @_;
    my $perl = $self->get_perl;
    unless ($perl) {
        $self = $self->SUPER::from_scratch();
    }
    $self->SUPER::query(@args);
}

sub output {
    my ( $self, @args ) = @_;
    my $perl = $self->get_perl;
    unless ($perl) {
        $self = $self->SUPER::from_scratch();
    }
    $self->SUPER::output(@args);
}

sub get_code {
    my ($self) = @_;
    my $perl = $self->get_perl;
    unless ($perl) {
        $self = $self->SUPER::from_scratch;
        $perl = $self->get_perl;
    }
    return $perl;
}

1;

__END__

=head1 NAME

HTML::Template::Compiled::Lazy - Lazy Loading for HTML::Template::Compiled

=head1 SYNOPSIS

    use HTML::Template::Compiled::Lazy;
    my $htcl = HTML::Template::Compiled::Lazy->new(
        # usual parameters for HTML::Template::Compiled
    );
    $htcl->param(...);
    # file wasn't compiled yet
    print $htcl->output; # now compile and output!

=head1 DESCRIPTION

This class does not compile templates before calling C<output()>.
This includes C<TMPL_INCLUDE>s. This can be useful in CGI environments.
If your template has got a lot of includes L<HTML::Template::Compiled> will
compile all of them, even if they aren't needed because they are never
reached (in a C<TMPL_IF>, for example).

L<HTML::Template::Compiled::Lazy> also won't complain if the file does
not exist - it will complain when you call C<output()>, though.

=cut

