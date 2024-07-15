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
use constant _F_DATA     => 0;  # difference set result set object
use constant _F_SPACES   => 1;  # PDS space result set object or undef
use constant _F_VERSION  => 2;  # PDS space result set object or undef
use constant _F_PATH     => 3;  # database path name
use constant _NFIELDS    => 4;

our $VERSION  = '1.002';
our @CARP_NOT = qw(Math::DifferenceSet::Planar);

our $DATABASE_DIR = dist_dir('Math-DifferenceSet-Planar');

use constant _KNOWN => { '<>' => 0 };

# ----- private subroutines -----

sub _iterate {
    my ($domain, $query, $min, $max, @columns) = @_;
    my @sel  = $query? @{$query}: ();
    my @osel = ();
    my $dir = 'ASC';
    if (defined($min) && defined($max) && $min > $max) {
        ($min, $max, $dir) = ($max, $min, 'DESC');
    }
    push @osel, '>=' => $min if defined $min;
    push @osel, '<=' => $max if defined $max;
    push @sel, order_ => { @osel } if @osel;
    my $results = $domain->search(
        @sel? { @sel }: undef,
        {
            @columns? ( columns => \@columns ): (),
            order_by => "order_ $dir",
        }
    );
    return sub { $results->next };
}

# ----- private accessor methods -----

sub _data    { $_[0]->[_F_DATA]    }
sub _spaces  { $_[0]->[_F_SPACES]  }
sub _version { $_[0]->[_F_VERSION] }
sub _path    { $_[0]->[_F_PATH]    }

sub _get_version_of {
    my ($this, $table_name) = @_;
    my $version = $this->_version;
    return (0, 0) if !defined $version;
    my $rec = $version->search({ table_name => $table_name })->single;
    return (0, 0) if !defined $rec;
    return ($rec->major, $rec->minor);
}

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
    my $spaces = $schema->resultset('DifferenceSetSpace');
    undef $spaces if !eval { $spaces->search->count };
    my $version = $schema->resultset('DatabaseVersion');
    undef $version if !eval { $version->search->count };
    return bless [$data, $spaces, $version, $path], $class;
}

# ----- object methods -----

sub get {
    my ($this, $order, @columns) = @_;
    return $this->_data->search(
        { order_ => $order },
        @columns ? { columns => \@columns } : ()
    )->single;
}

sub get_space {
    my ($this, $order) = @_;
    my $spaces = $this->_spaces;
    return undef if !defined $spaces;
    return $spaces->search({ order_ => $order })->single;
}

sub get_version       { $_[0]->_get_version_of('difference_set')       }
sub get_space_version { $_[0]->_get_version_of('difference_set_space') }

sub iterate {
    my ($this, $min, $max) = @_;
    return _iterate($this->_data, undef, $min, $max);
}

sub iterate_properties {
    my ($this, $min, $max, @columns) = @_;
    foreach my $col (@columns) {
        $col = 'order_' if $col eq 'order';
    }
    @columns =
        grep {!/delta/}
        Math::DifferenceSet::Planar::Schema::Result::DifferenceSet->columns
        if !@columns;
    return _iterate($this->_data, undef, $min, $max, @columns);
}

sub iterate_refs {
    my ($this, $type, $min, $max) = @_;
    return _iterate($this->_data, [$type => { '<>' => 0 }], $min, $max);
}

sub iterate_spaces {
    my ($this, $min, $max) = @_;
    my $spaces = $this->_spaces;
    return sub {} if !defined $spaces;
    return _iterate($spaces, undef, $min, $max);
}

sub min_order    { $_[0]->_data->get_column('order_')->min  }
sub max_order    { $_[0]->_data->get_column('order_')->max  }
sub count        { $_[0]->_data->search->count              }
sub path         { $_[0]->_path                             }

sub sp_min_order {
    my ($this) = @_;
    my $spaces = $this->_spaces;
    return $spaces && $spaces->get_column('order_')->min;
}

sub sp_max_order {
    my ($this) = @_;
    my $spaces = $this->_spaces;
    return $spaces && $spaces->get_column('order_')->max;
}

sub sp_count {
    my ($this) = @_;
    my $spaces = $this->_spaces;
    return 0 if !defined $spaces;
    return $spaces->search->count;
}

sub ref_min_order {
    my ($this, $type) = @_;
    return $this->_data->search({$type => _KNOWN})->get_column('order_')->min;
}

sub ref_max_order {
    my ($this, $type) = @_;
    return $this->_data->search({$type => _KNOWN})->get_column('order_')->max;
}

sub ref_count {
    my ($this, $type) = @_;
    return $this->_data->search({$type => _KNOWN})->count;
}

1;

__END__

=encoding utf8

=head1 NAME

Math::DifferenceSet::Planar::Data - storage of sample planar difference sets

=head1 VERSION

This documentation refers to version 1.002 of
Math::DifferenceSet::Planar::Data.

=head1 SYNOPSIS

  use Math::DifferenceSet::Planar::Data;

  $data = Math::DifferenceSet::Planar::Data->new;

  $data = Math::DifferenceSet::Planar::Data->new('pds.db');
  $data = Math::DifferenceSet::Planar::Data->new($full_path);

  @databases = Math::DifferenceSet::Planar::Data->list_databases;
  $data = Math::DifferenceSet::Planar::Data->new($databases[0]);

  $pds = $data->get(9);

  @columns = qw(base exponent modulus n_planes);
  $pds = $data->get(9, @columns);

  $it = $data->iterate($min, $max);
  while (my $pds = $it->()) {
    # ...
  }

  $min   = $data->min_order;
  $max   = $data->max_order;
  $count = $data->count;
  $path  = $data->path;

  $it = $data->iterate_refs('ref_std', $min, $max);
  while (my $pds = $it->()) {
    # ...
  }

  $min   = $data->ref_min_order('ref_std');
  $max   = $data->ref_max_order('ref_lex');
  $count = $data->ref_count('ref_gap');

  $space = $data->get_space(9);
  $min   = $data->sp_min_order;
  $max   = $data->sp_max_order;
  $count = $data->sp_count;

  ($major, $minor) = $data->get_version;
  ($major, $minor) = $data->get_space_version;

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
It is initialized automatically to refer to the location where its
data has been installed.  It may be set to another absolute path before
calling I<new>.

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
efficient if the I<delta_main> column and thus the I<main_elements>
accessor are not needed.

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
C<$data-E<gt>iterate_properties(@minmax)> behaves exactly like
C<$data-E<gt>iterate(@minmax)>, except that the result records have no
delta_main component and thus no access to elements.  Using this method
to browse difference set properties is more efficient than fetching
complete records.

With additional arguments after the minimum and maximum order, these
arguments are taken as names of components to fetch, so that the resulting
records can be even more tailored to what is needed.  Minimum and maximum
order can not be omitted in that case, but may be C<undef>.

=item I<min_order>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>min_order> returns the order of the smallest sample planar
difference set in the database.

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

=item I<iterate_refs>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>iterate_refs($type)> with C<$type> one of
C<'ref_std'>, C<'ref_lex'>, or C<'ref_gap'>, returns a code reference
that, repeatedly called, returns all reference planar difference set
records of the given type in the database.  The iterator returns a
false value when it is exhausted.

Optional arguments after the type argument are minimum and maximum order
values in like the optional arguments of I<iterate>.

=item I<ref_min_order>

This method takes a type argument like I<iterate_refs> and returns the
smallest order of available reference sets of that kind, or C<undef>
if none are available.

=item I<ref_max_order>

This method takes a type argument like I<iterate_refs> and returns the
largest order of available reference sets of that kind, or C<undef>
if none are available.

=item I<ref_count>

This method takes a type argument like I<iterate_refs> and returns the
number of available reference sets of that kind.

=item I<get_space>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>get_space($order)> fetches a difference set space record
from the database with order C<$order>.  If the database has no space
record of that order, a false value is returned, otherwise an object of
type Math::DifferenceSet::Planar::Schema::Result::DifferenceSetSpace.

Databases may contain more or less spaces than difference sets or even
none at all.  Spaces speed up enumerating difference set planes but are
not depended on in the rest of the library.

=item I<iterate_spaces>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>iterate_spaces> returns a code reference that, repeatedly
called, returns all planar difference set space records in the database,
one by one. The iterator returns a false value when it is exhausted.

C<$data-E<gt>iterate($lo, $hi)> returns an iterator over all spaces with
orders between $lo and $hi (inclusively), ordered by ascending size. If
C<$lo> is not defined, it is taken as zero. If C<$hi> is omitted or not
defined, it is taken as plus infinity. If C<$lo> is greater than C<$hi>,
they are swapped and the sequence is reversed, so that it is ordered by
descending size.

=item I<sp_min_order>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>sp_min_order> returns the order of the smallest planar
difference set space in the database, or C<undef> if no spaces are stored.

=item I<sp_max_order>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>sp_max_order> returns the order of the largest planar
difference set space in the database, or C<undef> if no spaces are stored.

=item I<sp_count>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>sp_count> returns the number of planar difference set spaces
in the database.  This may be greater or less than the number of sample
planar difference sets or even zero.

=item I<get_version>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>get_version> returns a pair of numbers matching the planar
difference set collection major and minor version reported in the
database.  Missing version information is treated as I<major = minor = 0>.

=item I<get_space_version>

If C<$data> is a Math::DifferenceSet::Planar::Data object,
C<$data-E<gt>get_space_version> returns a pair of numbers matching
the planar difference set spaces collection major and minor version
reported in the database.  Missing version information is treated as
I<major = minor = 0>.

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
the result type for set queries.

=item *

L<Math::DifferenceSet::Planar::Schema::Result::DifferenceSetSpace> -
the result type for space queries.

=item *

L<File::Spec> - file name parsing.

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2024 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

The licence grants freedom for related software development but does
not cover incorporating code or documentation into AI training material.
Please contact the copyright holder if you want to use the library whole
or in part for other purposes than stated in the licence.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
