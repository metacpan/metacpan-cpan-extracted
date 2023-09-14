package Image::DS9::Daemon;

# ABSTRACT: Wrapper around Proc::Daemon to implement terminate_on_destroy

use v5.10;
use strict;
use warnings;

our $VERSION = 'v1.0.0';

use parent 'Proc::Daemon';

sub Init {
    my $self = shift;

    my @pid = $self->SUPER::Init( @_ );
    $self->{ +__PACKAGE__ }{pids} = \@pid;
    ## no critic (Community::Wantarray)
    # duplicate API from parent
    return ( wantarray ? @pid : $pid[0] );
}

sub alive {
    my $self = shift;
    my @pid  = @{ $self->{ +__PACKAGE__ }{pids} };

    my @dead = grep { !$self->SUPER::Status( $_ ) } @pid;
    return !scalar @dead;
}

sub DESTROY {
    my $self = shift;
    return unless $self->{terminate_on_destroy};

    my $pid = $self->{ +__PACKAGE__ }{pids};
    $self->Kill_Daemon( $_ ) for @{$pid};
}


1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Image::DS9::Daemon - Wrapper around Proc::Daemon to implement terminate_on_destroy

=head1 VERSION

version v1.0.0

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-image-ds9@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-DS9>

=head2 Source

Source is available at

  https://gitlab.com/djerius/image-ds9

and may be cloned from

  https://gitlab.com/djerius/image-ds9.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Image::DS9|Image::DS9>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
