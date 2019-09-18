package Math::DifferenceSet::Planar::Data;

use strict;
use warnings;
use Carp qw(croak);
use File::Spec;
use File::Share qw(dist_dir);
use DBD::SQLite::Constants qw(SQLITE_OPEN_READONLY);
use Math::DifferenceSet::Planar::Schema;

# Math::DifferenceSet::Planar::Data=ARRAY(...)

# .......... index ..........   # .......... value ..........
use constant _F_DATA     => 0;  # result set object
use constant _F_PATH     => 1;  # result set object
use constant _NFIELDS    => 2;

our $VERSION  = '0.008';
our @CARP_NOT = qw(Math::DifferenceSet::Planar);

our $DATABASE_DIR = dist_dir('Math-DifferenceSet-Planar');

# ----- private accessor methods -----

sub _data { $_[0]->[_F_DATA] }
sub _path { $_[0]->[_F_PATH] }

# ----- class methods -----

sub list_databases {
    opendir my $dh, $DATABASE_DIR or return (); 
    my @files =
        map {
            my $is_standard = /^pds[_\W]/i? 1: 0;
            my $path = File::Spec->rel2abs($_, $DATABASE_DIR);
            (-f $path)? [$_, $is_standard, -s _]: ()
        }
        grep { /\.db\z/i } readdir $dh;
    closedir $dh;
    return
        map { $_->[0] }
        sort {
            $b->[1] <=> $a->[1] || $b->[2] <=> $a->[2] ||
            $a->[0] cmp $b->[0]
        }
        @files;
}

sub new {
    my $class = shift;
    my ($filename) = @_? @_: $class->list_databases
        or croak "bad database: empty share directory: $DATABASE_DIR";
    my $path = File::Spec->rel2abs($filename, $DATABASE_DIR);
    -e $path or croak "bad database: file does not exist: $path";
    my $schema =
        Math::DifferenceSet::Planar::Schema->connect(
            "dbi:SQLite:$path", q[], q[], 
            { sqlite_open_flags => SQLITE_OPEN_READONLY },
        );
    my $data = $schema->resultset('DifferenceSet');
    my $count = eval { $data->search->count };
    croak "bad database: query failed: $@" if !defined $count;
    return bless [$data, $path], $class;
}

# ----- object methods -----

sub get {
    my ($this, $order, @columns) = @_;
    return $this->_data->search(
        { order_ => $order },
        @columns ? { columns => \@columns } : ()
    )->single;
}

sub iterate {
    my ($this, $min, $max) = @_;
    my @sel = ();
    my $dir = 'ASC';
    if (defined($min) && defined($max) && $min > $max) {
        ($min, $max, $dir) = ($max, $min, 'DESC');
    }
    push @sel, '>=' => $min if defined $min;
    push @sel, '<=' => $max if defined $max;
    my $results = $this->_data->search(
        @sel? { order_ => { @sel } }: undef,
        { order_by => "order_ $dir" }
    );
    return sub { $results->next };
}

sub iterate_properties {
    my ($this, $min, $max) = @_;
    my @sel = ();
    my $dir = 'ASC';
    if (defined($min) && defined($max) && $min > $max) {
        ($min, $max, $dir) = ($max, $min, 'DESC');
    }
    push @sel, '>=' => $min if defined $min;
    push @sel, '<=' => $max if defined $max;
    my $results = $this->_data->search(
        @sel? { order_ => { @sel } }: undef,
        {
            columns  => [qw(order_ base exponent modulus n_planes)],
            order_by => "order_ $dir",
        }
    );
    return sub { $results->next };
}

sub max_order { $_[0]->_data->get_column('order_')->max }
sub count     { $_[0]->_data->search->count }
sub path      { $_[0]->_path }

1;

__END__

=encoding utf8

=head1 NAME

Math::DifferenceSet::Planar::Data - storage of sample planar difference sets

=head1 VERSION

This documentation refers to version 0.008 of
Math::DifferenceSet::Planar::Data.

=head1 SYNOPSIS

  use Math::DifferenceSet::Planar::Data;

  $data = Math::DifferenceSet::Planar->new;

  $data = Math::DifferenceSet::Planar->new('pds.db');
  $data = Math::DifferenceSet::Planar->new($full_path);

  @databases = Math::DifferenceSet::Planar::Data->list_databases;
  $data = Math::DifferenceSet::Planar::Data->new($databases[0]);

  $pds = $data->get(9);

  @columns = qw(base exponent modulus n_planes);
  $pds = $data->get(9, @columns);

  $it = $data->iterate($min, $max);
  while (my $pds = $it->()) {
    # ...
  }

  $max   = $data->max_order;
  $count = $data->count;
  $path  = $data->path;

=head1 DESCRIPTION

Math::DifferenceSet::Planar::Data is a class giving access to a local
database of sample planar difference sets, hiding its implementation
details.  It is used internally by Math::DifferenceSet::Planar to populate
difference set objects.

=head1 CLASS VARIABLES

=over 4

=item I<$VERSION>

C<$VERSION> is the version number of the module.

=item I<$DATABASE_DIR>

C<$DATABASE_DIR> is the directory containing databases for this module.
It is initialized automatically to refer to the location where its data
has been installed.

=back

=head1 CLASS METHODS

=over 4

=item I<new>

C<Math::DifferenceSet::Planar::Data-E<gt>new> creates a handle for
access to a database of difference set samples.  Without parameter, it
finds a suitable database in the distribution-specific share directory.
With a filename parameter, it tries to open that particular database.
Relative filenames are resolved relative to the share directory.
On success, it returns the handle.  On failure, it raises an exception.

=item I<list_databases>

C<Math::DifferenceSet::Planar::Data-E<gt>list_databases> returns a list
of filenames currently suitable as arguments for I<new> on your platform.

=back

=head1 OBJECT METHODS

=over 4

=item I<get>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>get($order)> fetches a single record from the database
with order C<$order>.  If the database has no record of that
order, a false value is returned, otherwise an object of type
Math::DifferenceSet::Planar::Schema::Result::DifferenceSet.

C<$data-E<gt>get($order, @columns)> does the same, but returns a partial
record with only the columns that are specified.  This is particularly
efficient if the I<deltas> column and thus the I<elements> accessor are
not needed.

=item I<iterate>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>iterate> returns a code reference that, repeatedly called,
returns all sample planar difference set records in the database, one
by one. The iterator returns a false value when it is exhausted.

C<$data-E<gt>iterate($lo, $hi)> returns an iterator over all samples with
orders between $lo and $hi (inclusively), ordered by ascending size. If
C<$lo> is not defined, it is taken as zero. If C<$hi> is omitted or not
defined, it is taken as plus infinity. If C<$lo> is greater than C<$hi>,
they are swapped and the sequence is reversed, so that it is ordered by
descending size.

=item I<iterate_properties>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>iterate_properties(@args)> behaves exactly like
C<$data-E<gt>iterate(@args)>, except that the result records have no
deltas component and thus no access to elements.  Using this method
to browse difference set properties is more efficient than fetching
complete records.

=item I<max_order>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>max_order> returns the order of the largest sample planar
difference set in the database.

=item I<count>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>count> returns the number of sample planar difference sets
in the database.

=item I<path>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>path> returns the full path name of the database.

=back

=head1 DIAGNOSTICS

Most methods of this module do not generate diagnostic output nor raise
any exceptions.

The I<new> constructor, however, will fail with an exception if the
database specified by the optional filename argument or by default is
missing or broken.

=over 4

=item bad database: E<lt>reasonE<gt>

The database could not be accessed.  Diagnostics from underlying
libraries such as DBI or File::Share are added, if present.

=back

=head1 BUGS AND LIMITATIONS

Bug reports and suggestions are welcome.
See L<the main module|Math::DifferenceSet::Planar> on how to contribute.

=head1 SEE ALSO

=over 4

=item *

L<Math::DifferenceSet::Planar> - the main module of this library.

=item *

L<Math::DifferenceSet::Planar::Schema::Result::DifferenceSet> -
the result type for queries.

=item *

L<File::Spec> - file name parsing.

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
