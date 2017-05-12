package Debian::Releases;
{
  $Debian::Releases::VERSION = '0.14';
}
# ABSTRACT: Mapping and comparing Debian release codenames and versions

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

use Version::Compare;


has 'releases' => (
    'is'      => 'ro',
    'isa'     => 'HashRef[Str]',
    'lazy'    => 1,
    'builder' => '_init_releases',
);

has 'codenames' => (
    'is'      => 'ro',
    'isa'     => 'HashRef[Str]',
    'lazy'    => 1,
    'builder' => '_init_codenames',
);

sub _init_releases {
    my $self = shift;
    my $rels = {
        '1.1'       => 'buzz',
        '1.2'       => 'rex',
        '1.3'       => 'bo',
        '2.0'       => 'hamm',
        '2.1'       => 'slink',
        '2.2'       => 'potato',
        '3.0'       => 'woody',
        '3.1'       => 'sarge',
        '4.0'       => 'etch',
        '5.0'       => 'lenny',
        '6.0'       => 'squeeze',
        '7.0'       => 'wheezy',
        '8.0'       => 'jessie',
        '9999.9999' => 'sid',
    };
    return $rels;
}

sub _init_codenames {
    my $self  = shift;
    my $rels  = $self->releases();
    my $codes = {};
    foreach my $version ( keys %{$rels} ) {
        my $codename = $rels->{$version};
        $codes->{$codename} = $version;
    }
    return $codes;
}


## no critic (ProhibitAmbiguousNames)
sub version_compare {
    my $self  = shift;
    my $left  = shift;
    my $right = shift;

    $left  =~ s/^\s+//;
    $left  =~ s/\s+$//;
    $right =~ s/^\s+//;
    $right =~ s/\s+$//;
    $left  =~ s/\s*Debian\s*//g;
    $right =~ s/\s*Debian\s*//g;

    if ( $left =~ m/^(\d+\.\d)/ ) {
        $left = $1;
    }
    elsif ( my $ver = $self->codenames()->{$left} ) {
        $left = $ver;
    }
    else {
        $left = '0.0';
    }
    if ( $right =~ m/^(\d+\.\d)/ ) {
        $right = $1;
    }
    elsif ( my $ver = $self->codenames()->{$right} ) {
        $right = $ver;
    }
    else {
        $right = '0.0';
    }

    return Version::Compare::version_compare( $left, $right );
}
## use critic

no Moose;
__PACKAGE__->meta->make_immutable();


1; # End of Debian::Releases

__END__

=pod

=head1 NAME

Debian::Releases - Mapping and comparing Debian release codenames and versions

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    use Debian::Releases;

    if(Debian::Releases::version_compare('6.0','squeeze')) {
        print "This is squeeze\n";
    }

=head1 NAME

Debian::Releases - Comparing debian releases

=head1 SUBROUTINES/METHODS

=head2 version_compare

Compare two debian releases in numerical or codename form.

=head1 AUTHOR

Dominik Schulz, C<< <dominik.schulz at gauner.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-debian-releases at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Debian-Releases>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debian::Releases

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Debian-Releases>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Debian-Releases>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Debian-Releases>

=item * Search CPAN

L<http://search.cpan.org/dist/Debian-Releases/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dominik Schulz

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
