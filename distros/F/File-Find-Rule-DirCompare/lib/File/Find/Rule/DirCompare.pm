package File::Find::Rule::DirCompare;

use warnings;
use strict;

use base 'File::Find::Rule';
use Carp qw(croak);
use File::Spec;
use File::stat;
use Params::Util qw(_ARRAY0);

use Data::Dumper;

=head1 NAME

File::Find::Rule::DirCompare - Find files by comparing with 2nd directory

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.020';

=head1 SYNOPSIS

    use File::Find::Rule::DirCompare;

    my @only_in_searchdir = find( file => not_exists_in => $cmpdir, in => $searchdir );
    my @in_both_dirs = find( file => exists_in => $cmpdir, in => $searchdir );
    my @newer_in_cmpdir = find( file => newer_in => $cmpdir, in => $searchdir );
    my @older_in_cmpdir = find( file => older_in => $cmpdir, in => $searchdir );

    # or use OO interface
    my $Find;

    $Find = File::Find::Rule->file->not_exists_in( $cmpdir );
    my @ois = $Find->in( $searchdir );

    $Find = File::Find::Rule->file->exists_in( $cmpdir );
    my @ibd = $Find->in( $searchdir );

    $Find = File::Find::Rule->file->newer_in( $cmpdir );
    my @nic = $Find->in( $searchdir );

    $Find = File::Find::Rule->file->older_in( $cmpdir );
    my @oic = $Find->in( $searchdir );

    # sure it can be combined ...
    $Find = File::Find::Rule->file
                            ->any(
			        File::Find::Rule->new->not_exists_in( $cmpdir ),
			        File::Find::Rule->new->newer_in( $cmpdir ),
			      );
    my @newer_or_newly = $Find->in( $searchdir );

=head1 EXPORT

This module doesn't export any function. The provided functionality is called
by L<File::Find::Rule> according to the matching rules.

=head1 SUBROUTINES/METHODS

=head2 exists_in

Accept a list of directory names to be checked if found files exists in any
of them or not. The directory names are interpreted relative to the current
directory (L<Cwd/cwd>), not relative to the directory specified in C<in>.
To ensure the right directory is chosen, specify an absolute path.

If the first argument is an array reference, the list in this array
will be used.

=head2 not_exists_in

Accept a list of directory names to be checked if found files does not
exists in any of them or not. The directory names are interpreted relative
to the current directory (L<Cwd/cwd>), not relative to the directory
specified in C<in>.  To ensure the right directory is chosen, specify an
absolute path.

If the first argument is an array reference, the list in this array
will be used.

=head2 newer_in

Accept a list of directory names to be checked if found files exists in any
of them and have a newer timestamp when it's last modified. The directory
names are interpreted relative to the current directory (L<Cwd/cwd>), not
relative to the directory specified in C<in>.  To ensure the right directory
is chosen, specify an absolute path.

If the first argument is an array reference, the list in this array
will be used.

=head2 older_in

Accept a list of directory names to be checked if found files exists in any
of them and have an older timestamp when it's last modified. The directory
names are interpreted relative to the current directory (L<Cwd/cwd>), not
relative to the directory specified in C<in>.  To ensure the right directory
is chosen, specify an absolute path.

If the first argument is an array reference, the list in this array
will be used.

=cut

sub File::Find::Rule::not_exists_in
{
    my $self = shift;
    my @params = defined( _ARRAY0( $_[0] ) ) ? @{$_[0]} : @_;
    croak "Missing at least a directory to compare" unless( scalar( @params ) );
    my $code = sub {
	my $fn = $_;
	foreach my $cmpdir (@params)
	{
	    my $cmpfn = File::Spec->catfile( $cmpdir, $fn );
	    return 1 unless( -e $cmpfn );
	}
	return;
    };
    $self->exec( $code );
}

sub File::Find::Rule::exists_in
{
    my $self = shift;
    my @params = defined( _ARRAY0( $_[0] ) ) ? @{$_[0]} : @_;
    croak "Missing at least a directory to compare" unless( scalar( @params ) );
    my $code = sub {
	my $fn = $_;
	foreach my $cmpdir (@params)
	{
	    my $cmpfn = File::Spec->catfile( $cmpdir, $fn );
	    return 1 if( -e $cmpfn );
	}
	return;
    };
    $self->exec( $code );
}

sub File::Find::Rule::newer_in
{
    my $self = shift;
    my @params = defined( _ARRAY0( $_[0] ) ) ? @{$_[0]} : @_;
    croak "Missing at least a directory to compare" unless( scalar( @params ) );
    my $code = sub {
	my $fn = $_;
	my $fnstat = stat($fn);
	my $fnmtime = $fnstat->mtime();
	foreach my $cmpdir (@params)
	{
	    my $cmpfn = File::Spec->catfile( $cmpdir, $fn );
	    my $cmpstat = stat($cmpfn) or next;
	    my $cmpmtime = $cmpstat->mtime();
	    return 1 if( $fnmtime < $cmpmtime );
	}
	return;
    };
    $self->exec( $code );
}

sub File::Find::Rule::older_in
{
    my $self = shift;
    my @params = defined( _ARRAY0( $_[0] ) ) ? @{$_[0]} : @_;
    croak "Missing at least a directory to compare" unless( scalar( @params ) );
    my $code = sub {
	my $fn = $_;
	my $fnstat = stat($fn);
	my $fnmtime = $fnstat->mtime();
	foreach my $cmpdir (@params)
	{
	    my $cmpfn = File::Spec->catfile( $cmpdir, $fn );
	    my $cmpstat = stat($cmpfn) or next;
	    my $cmpmtime = $cmpstat->mtime();
	    return 1 if( $fnmtime > $cmpmtime );
	}
	return;
    };
    $self->exec( $code );
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-find-rule-dircompare at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-Rule-DirCompare>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Find::Rule::DirCompare

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Find-Rule-DirCompare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Find-Rule-DirCompare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Find-Rule-DirCompare>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Find-Rule-DirCompare/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of File::Find::Rule::DirCompare
