package File::Sticker;
$File::Sticker::VERSION = '4.301';
=head1 NAME

File::Sticker - Read, Write file meta-data

=head1 VERSION

version 4.301

=head1 SYNOPSIS

    use File::Sticker;

    my $obj = File::Sticker->new(%args);

=head1 DESCRIPTION

This will read and write meta-data from files, in a standardized manner.
And update a database with that information.

=cut

use common::sense;
use File::Sticker::Scribe;
use File::Sticker::Database;
use POSIX qw(strftime);
use String::CamelCase qw(wordsplit);
use YAML::Any;
use Path::Tiny;
use Hash::Merge;

use Module::Pluggable instantiate => 'new',
search_path => ['File::Sticker::Scribe'],
sub_name => 'all_scribes';
use Module::Pluggable instantiate => 'new',
search_path => ['File::Sticker::Derive'],
sub_name => 'derivers';

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 new

Create a new object, setting global values for the object.

    my $obj = File::Sticker->new(
        wanted_fields=>\%wanted_fields,
        verbose=>$verbose,
        dbname=>$dbname,
        field_order=>\@fields,
        primary_table=>$primary_table,
        tagfield=>$tagfield,
        derive=>1,
    );

=cut

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = bless ({%parameters}, ref ($class) || $class);

    my %new_args = ();
    foreach my $key (qw(wanted_fields verbose topdir read_all derive))
    {
        if (exists $self->{$key})
        {
            $new_args{$key} = $self->{$key};
        }
    }
    # -------------------------------------
    # Modules
    my %to_disable = ();
    foreach my $mod (@{$self->{disable}})
    {
        $to_disable{$mod} = 1;
    }

    # -------------------------------------
    # Scribes
    # Find out what scribes are available, and group them by priority
    my @scribes = $self->all_scribes();
    $self->{_scribe_pri} = {};
    foreach my $rd (@scribes)
    {
        my $nm = $rd->name();
	my $priority = $rd->priority();
        if ($to_disable{$nm})
        {
            print STDERR "DISABLE SCRIBE: ${nm}\n" if $self->{verbose} > 1;
        }
        else
        {
            print STDERR "SCRIBE: ${nm}\n" if $self->{verbose} > 1;
            $rd->init(%new_args);
            if (!exists $self->{_scribe_pri}->{$priority})
            {
                $self->{_scribe_pri}->{$priority} = [];
            }
            push @{$self->{_scribe_pri}->{$priority}}, $rd;
        }
    }
    # -------------------------------------
    # Derivers
    # Find out what derivers are available and enabled.
    my @derivers = $self->derivers();
    # Sort by order, numerically
    @derivers = sort {$a->order() <=> $b->order()} @derivers;
    $self->{_derivers} = [];
    foreach my $dd (@derivers)
    {
        my $nm = $dd->name();
        if ($to_disable{$nm})
        {
            print STDERR "DISABLE DERIVER: ${nm}\n" if $self->{verbose} > 1;
        }
        else
        {
            print STDERR "DERIVER: ${nm}\n" if $self->{verbose} > 1;
            $dd->init(%new_args);
            push @{$self->{_derivers}}, $dd;
        }
    }

    # -------------------------------------
    # Database (optional)
    # -------------------------------------
    if (exists $self->{dbname}
            and defined $self->{dbname}
            and exists $self->{wanted_fields}
            and defined $self->{wanted_fields}
            and exists $self->{field_order}
            and defined $self->{field_order}
            and exists $self->{primary_table}
            and defined $self->{primary_table})
    {
        # we have enough to instantiate a database object
        $self->{db} = File::Sticker::Database->new(
            dbname=>$self->{dbname},
            wanted_fields=>$self->{wanted_fields},
            field_order=>$self->{field_order},
            primary_table=>$self->{primary_table},
            taggable_fields=>$self->{taggable_fields},
            topdir=>$self->{topdir},
            tagfield=>$self->{tagfield},
            space_sep=>$self->{space_sep},
            readonly=>$self->{readonly},
            verbose=>$self->{verbose},
        );
        $self->{db}->do_connect();
        $self->{db}->create_tables();
    }

    return ($self);
} # new

=head2 read_meta

This will read the meta-data from the file, using all possible ways.

    my $info = $fs->read_meta(filename=>$filename,read_all=>0);

=cut
sub read_meta ($%) {
    my $self = shift;
    my %args = @_;
    my $filename = $args{filename};
    say STDERR whoami(), " filename=$filename" if $self->{verbose} > 2;

    if (!-r $filename)
    {
        # the file may not exist yet, so don't die
        return {};
    }

    # Don't limit this to only one scribe, due to data being
    # held in multiple forms, we need a fallback.
    my @possible_scribes = ();
    # Look for the high-priority scribes first
    foreach my $pri (reverse sort keys %{$self->{_scribe_pri}})
    {
        foreach my $rd (@{$self->{_scribe_pri}->{$pri}})
        {
            if ($rd->allow($filename))
            {
                push @possible_scribes, $rd;
                say STDERR "Scribe($pri) ", $rd->name() if $self->{verbose} > 1;
            }
        }
    }

    # Merge in ALL found data; LEFT_PRECEDENT because the
    # earlier scribes have higher priority.
    my $merge = Hash::Merge->new('LEFT_PRECEDENT');
    my $meta = {};
    foreach my $scribe (@possible_scribes)
    {
        say STDERR "Reading ", $scribe->name() if $self->{verbose} > 1;
        my $info = $scribe->read_meta($filename);
        my $newmeta = $merge->merge($meta, $info);
        $meta = $newmeta;
        print STDERR "META: ", Dump($meta), "\n" if $self->{verbose} > 1;
    }

    # If read_all or derive, add in the derived values
    if ($args{read_all} or $args{derive})
    {
        my $derived = $self->derive_values(filename=>$filename,meta=>$meta);
        foreach my $field (sort keys %{$derived})
        {
            # only add a derived field if it isn't there already
            if (!exists $meta->{$field} and $derived->{$field})
            {
                $meta->{$field} = $derived->{$field};
            }
            # Unless it is the file size, which must always be taken
            # from the actual file size
            if ($field eq 'filesize')
            {
                $meta->{$field} = $derived->{$field};
            }
        }
    }

    # If we only want the wanted_fields, remove anything that isn't wanted
    if (!$args{read_all}
            and exists $self->{wanted_fields}
            and defined $self->{wanted_fields})
    {
        my @fields = sort keys %{$meta};
        foreach my $fn (@fields)
        {
            if (! exists $self->{wanted_fields}->{$fn})
            {
                delete $meta->{$fn};
            }
        }
    }

    return $meta;
} # read_meta

=head2 add_field_to_file

Add the contents of the given field to the file, taking into account multi-value fields.

    $sticker->add_field_to_file(
        filename=>$filename,
        field=>$field,
        value=>$value);

=cut
sub add_field_to_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};
    my $value = $args{value};

    if (!-w $filename)
    {
        return undef;
    }
    my $scribe = $self->_get_scribe($filename);
    if (defined $scribe)
    {
        # Never over-write readonly fields.
        my $readonly_fields = $scribe->readonly_fields();
        if (exists $readonly_fields->{$field}
                and defined $readonly_fields->{$field})
        {
            return undef;
        }

        my $old_meta = $self->read_meta(filename=>$filename,read_all=>0);
        my $derived = $self->derive_values(filename=>$filename,meta=>$old_meta);
        if ($self->{derive} and defined $derived->{$field})
        {
            $value = $derived->{$field};
        }

        $scribe->add_field_to_file(
            filename=>$filename,
            field=>$field,
            value=>$value,
            old_meta=>$old_meta);
    }
}

=head2 delete_field_from_file

Completely remove the given field.
For multi-value fields, it removes ALL the values.

    $sticker->delete_field_from_file(filename=>$filename,field=>$field);

=cut

sub delete_field_from_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};

    if (!-w $filename)
    {
        return undef;
    }
    my $scribe = $self->_get_scribe($filename);
    if (defined $scribe)
    {
        # Never delete readonly fields.
        my $readonly_fields = $scribe->readonly_fields();
        if (exists $readonly_fields->{$field}
                or defined $readonly_fields->{$field})
        {
            return undef;
        }

        $scribe->delete_field_from_file(
            filename=>$filename,
            field=>$field);
    }
} # delete_field_from_file

=head2 replace_all_meta

Overwrite the existing meta-data with that given.

    $sticker->replace_all_meta(filename=>$filename,meta=>\%meta);

=cut

sub replace_all_meta {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $meta = $args{meta};

    if (!-w $filename)
    {
        return undef;
    }

    my $scribe = $self->_get_scribe($filename);
    if (defined $scribe)
    {
        # We don't want to replace readonly fields so take this meta-data
        # and remove the readonly fields from it so they don't get written to.
        # But we don't want to alter the passed-in hashref, so make a new hash.
        my $writable_fields = $scribe->writable_fields();
        my %new_meta = ();
        foreach my $field (sort keys %{$meta})
        {
            if (exists $writable_fields->{$field}
                    and defined $writable_fields->{$field})
            {
                # A writable field
                $new_meta{$field} = $meta->{$field};
            }
        }
        $scribe->replace_all_meta(
            filename=>$filename,
            meta=>\%new_meta);
    }
} # replace_all_meta

=head2 query_by_tags

Search using +tag -tag nomenclature.

    $sticker->do_search($query_string);

=cut
sub query_by_tags {
    my $self = shift;
    my $query = shift;

    return $self->{db}->query_by_tags($query);
} # query_by_tags

=head2 query_one_file

Get the database info about the given file.  This is different from read_meta,
since this is getting the info from the database, not from the file.

    $sticker->query_one_file($file);

=cut
sub query_one_file {
    my $self = shift;
    my $file = shift;

    if ($self->{db})
    {
        return $self->{db}->get_file_meta($file);
    }
    return undef;
} # query_one_file

=head2 missing_files

Check through the database to see which files in the database no longer exist.

    my $files = $sticker->missing_files();

=cut
sub missing_files {
    my $self = shift;

    my @missing_files = ();
    my @files = @{$self->{db}->get_all_files()};
    foreach my $file (@files)
    {
        say STDERR "checking $file" if $self->{verbose} > 2;
        if (!-r $file and !-d $file)
        {
            push @missing_files, $file;
        }
    }
    return \@missing_files;
} # missing_files

=head2 overlooked_files

Check through the database to see which of the given files are not in the database.

    my $files = $sticker->overlooked_files(@files);

=cut
sub overlooked_files {
    my $self = shift;
    my @files = @_;

    my @overlooked = ();
    foreach my $file (@files)
    {
        my $id = $self->{db}->get_file_id($file);
        if (!$id)
        {
            push @overlooked, $file;
        }
    }
    return \@overlooked;
} # overlooked_files

=head2 list_tags

List the faceted-tags from the info table in the database.

    my @tags = @{$sticker->list_tags()};

=cut
sub list_tags {
    my $self = shift;

    my $tags = $self->{db}->get_all_tags();
    return $tags;
} # list_tags

=head2 update_db

Add/Update the given files into the database.

    $sticker->update_db(@files);

=cut
sub update_db {
    my $self = shift;
    my @files = @_;

    my $transaction_on = 0;
    my $num_trans = 0;

    foreach my $filename (@files)
    {
        say $filename if !$self->{quiet};
        if (!$transaction_on)
        {
            $self->{db}->start_transaction();
            $transaction_on = 1;
            $num_trans = 0;
        }
        my $meta = $self->read_meta(filename=>$filename,read_all=>0);
        my $scribe = $self->_get_scribe($filename);

        # If there are desired fields which are derivable
        # but which are not set in the file itself,
        # derive them, so they can be added to the meta
        my $derived = $self->derive_values(filename=>$filename,meta=>$meta);
        my $readonly_fields = $scribe->readonly_fields();
        foreach my $field (@{$self->{field_order}})
        {
            if (!$meta->{$field} and defined $derived->{$field})
            {
                $meta->{$field} = $derived->{$field};
            }
            # If it is a readonly field, which is also derived,
            # (such as filesize) then it needs to overwrite any old value.
            if (exists $readonly_fields->{$field}
                    and defined $readonly_fields->{$field}
                    and defined $derived->{$field})
            {
                $meta->{$field} = $derived->{$field};
            }
        }

        $self->{db}->add_meta_to_db($filename,%{$meta});
        # do the commits in bursts
        $num_trans++;
        if ($transaction_on and $num_trans > 100)
        {
            $self->{db}->commit();
            $transaction_on = 0;
            $num_trans = 0;
            say " " if $self->{verbose};
        }
    }
    $self->{db}->commit();
} # update_db

=head2 delete_file_from_db

Delete the given file from the database.

    $sticker->delete_file_from_db($filename);

=cut
sub delete_file_from_db {
    my $self = shift;
    my $filename = shift;

    return $self->{db}->delete_file_from_db($filename);
} # delete_file_from_db

=head2 delete_missing_files

Delete from the database the files which no longer exist.

    my $files = $sticker->delete_missing_files();

=cut
sub delete_missing_files {
    my $self = shift;

    my $missing_files = $self->missing_files();
    foreach my $file (@{$missing_files})
    {
        $self->delete_file_from_db($file);
    }
    return $missing_files;
} # delete_missing_files

=head2 derive_values

Derive values from the existing meta-data.
Updates the passed-in meta hash.
Calls plugins to do so.

    my $new_meta = $sticker->derive_values(filename=>$filename,
        meta=>$meta);

=cut

sub derive_values {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $meta = $args{meta};
    foreach my $dd (@{$self->{_derivers}})
    {
        my $nm = $dd->name();
        say STDERR "Derive($nm)" if $self->{verbose} > 2;
        $dd->derive(%args,meta=>$meta);
    }

    return $meta;
} # derive_values

=head2 _get_scribe

Pick the appropriate scribe for this file

    my $scribe = $sticker->_get_scribe($filename);

=cut
sub _get_scribe {
    my $self = shift;
    my $filename = shift;

    my $scribe;
    foreach my $pri (reverse sort keys %{$self->{_scribe_pri}})
    {
        foreach my $wt (@{$self->{_scribe_pri}->{$pri}})
        {
            if ($wt->allow($filename))
            {
                $scribe = $wt;
                say STDERR "Scribe($pri) ", $scribe->name() if $self->{verbose} > 1;
                last;
            }
        }
        if (defined $scribe)
        {
            last;
        }
    }
    return $scribe;
} # _get_scribe

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker
__END__
