package HackaMol::Roles::ReadXyzRole;
$HackaMol::Roles::ReadXyzRole::VERSION = '0.045';
# ABSTRACT: Read files with molecular information
use Moose::Role;
use Carp;
use Math::Vector::Real;
use FileHandle;

sub read_xyz_atoms {

    #read xyz file and generate list of Atom objects
    my $self = shift;
    my $fh   = shift;
 #   my $file = shift;
 #   my $fh   = FileHandle->new("<$file") or croak "unable to open $file";

    my @atoms;
    my ( $n, $t ) = ( 0, 0 );

    my $nat = undef;
    while (<$fh>) {

        if (/^(\s*\d+\s*)$/) {
            $n = (split)[0];
            if ( defined($nat) ) {
                croak "number of atoms has changed\n" unless ( $nat == $n );
                $t++;
            }
            $nat = $n;
            $n   = 0;
        }
        elsif (/(\w+|\d+)(\s+-*\d+\.\d+){3}/) {
            my @stuff = split;
            my $sym   = $stuff[0];
            my $xyz   = V( @stuff[ 1, 2, 3 ] );
            if ( $t == 0 ) {
                if ( $sym =~ /\d/ ) {
                    $atoms[$n] = HackaMol::Atom->new(
                        name   => "at$n",
                        Z      => $sym,
                        coords => [$xyz]
                    );
                }
                else {
                    $atoms[$n] = HackaMol::Atom->new(
                        name   => "at$n",
                        symbol => $sym,
                        coords => [$xyz]
                    );
                }
            }
            else {
                if ( $sym =~ /\d/ ) {
                    croak "atoms have changed from last model to current: $t\n"
                      if ( $sym != $atoms[$n]->Z );
                }
                else {
                    croak "atoms have changed from last model to current: $t\n"
                      if ( $sym ne $atoms[$n]->symbol );
                }
                $atoms[$n]->set_coords( $t, $xyz );

            }
            $n++;
        }
    }

    # set iatom to track the array.  diff from serial which refers to pdb
    $atoms[$_]->iatom($_) foreach ( 0 .. $#atoms );
    return (@atoms);
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::ReadXyzRole - Read files with molecular information

=head1 VERSION

version 0.045

=head1 SYNOPSIS

   my @atoms = HackaMol->new
                       ->read_xyz_atoms("some.xyz");

=head1 DESCRIPTION

The HackaMol::Roles::ReadXyzRole provides read_xyz_atoms reading xyz files.

=head1 METHODS

=head2 read_xyz_atoms

One argument: the filename
Returns a list of HackaMol::Atom objects.

=head1 SEE ALSO

=over 4

=item *

L<HackaMol>

=item *

L<HackaMol::Atom>

=item *

L<HackaMol::Roles::MolReadRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
