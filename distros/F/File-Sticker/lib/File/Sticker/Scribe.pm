package File::Sticker::Scribe;
$File::Sticker::Scribe::VERSION = '4.00';
=head1 NAME

File::Sticker::Scribe - read, write and standardize meta-data from files

=head1 VERSION

version 4.00

=head1 SYNOPSIS

    use File::Sticker::Scribe;

    my $scribe = File::Sticker::Scribe->new(%args);

    my $meta = $scribe->read_meta($filename);

    $scribe->write_meta(%args);

=head1 DESCRIPTION

This will read and write meta-data from files in various formats,
and standardize it to a common nomenclature,
such as "tags" for things called tags, or Keywords or Subject etc.

The standard nomenclature is:

=over

=item url

The source URL of this file (ref 'dublincore.source')

=item creator

The author or artist who created this. (ref 'dublincore.creator')

=item title

The title of the item. (ref 'dublincore.title')

=item description

The description of the item. (ref 'dublincore.description')

=item tags

The item's tags. (ref 'Keywords').

=back

Other fields will be called whatever the user has pre-configured.

=cut

use common::sense;
use File::LibMagic;
use List::MoreUtils qw(uniq);

=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 new

Create a new object, setting global values for the object.

    my $obj = File::Sticker::Scribe->new();

=cut

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = bless ({%parameters}, ref ($class) || $class);

    return ($self);
} # new

=head2 init

Initialize the object.
Check if all the required parameters are there.

    $scribe->init(wanted_fields=>{title=>'TEXT',count=>'NUMBER',tags=>'MULTI'});

=cut

sub init {
    my $self = shift;
    my %parameters = @_;

    foreach my $key (keys %parameters)
    {
	$self->{$key} = $parameters{$key};
    }
    $self->{file_magic} = File::LibMagic->new(follow_symlinks=>1);

    # Set the writable fields from the known and readonly fields
    if (exists $self->{wanted_fields}
            and defined $self->{wanted_fields})
    {
        my %writable = ();
        my $known = $self->known_fields();
        my $readonly = $self->readonly_fields();
        foreach my $field (keys %{$known})
        {
            # If it is Known and Not Readonly, it is writable
            if (!(exists $readonly->{$field}
                        and defined $readonly->{$field}))
            {
                $writable{$field} = $known->{$field};
            }
        }
        $self->{writable_fields} = \%writable;
    }
} # init

=head2 name

The name of the scribe; this is basically the last component
of the module name.  This works as either a class function or a method.

$name = $self->name();

$name = File::Sticker::Scribe::name($class);

=cut

sub name {
    my $class = shift;
    
    my $fullname = (ref ($class) ? ref ($class) : $class);

    my @bits = split('::', $fullname);
    return pop @bits;
} # name

=head2 priority

The priority of this scribe.  Scribes with higher priority
get tried first.  This is useful where there may be more
than one possible meta-data format for a file, such as
EXIF versus XATTR.

This works as either a class function or a method.

This must be overridden by the specific scribe class.

    $priority = $self->priority();

    $priority = File::Sticker::Scribe::priority($class);

=cut

sub priority {
    my $class = shift;
    return 0;
} # priority

=head2 allow

If this scribe can be used for the given file and the wanted_fields,
then this returns true.

    if ($scribe->allow($file))
    {
	....
    }

=cut

sub allow {
    my $self = shift;
    my $file = shift;
    say STDERR whoami(), " file=$file" if $self->{verbose} > 2;

    my $okay = $self->allowed_file($file);
    if ($okay) # okay so far
    {
        say STDERR 'Scribe ' . $self->name() . ' allows filetype of ' . $file if $self->{verbose} > 1;
        $okay = $self->allowed_fields();
    }
    return $okay;
} # allow

=head2 allowed_file

If this scribe can be used for the given file, then this returns true.
This must be overridden by the specific scribe class.

    if ($scribe->allowed_file($file))
    {
	....
    }

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;

    return 0;
} # allowed_file

=head2 allowed_fields

If this writer can be used for the known and wanted fields, then this returns true.
By default, if there are no wanted_fields, this returns false.
(But this may be overridden by subclasses)

    if ($writer->allowed_fields())
    {
	....
    }

=cut

sub allowed_fields {
    my $self = shift;

    my $okay = 1;
    if (exists $self->{wanted_fields}
            and defined $self->{wanted_fields})
    {
        # the wanted fields must be a subset of the (known fields + readonly fields)
        my $known_fields = $self->known_fields();
        my $readonly_fields = $self->readonly_fields();
        foreach my $fn (keys %{$self->{wanted_fields}})
        {
            if ((!exists $known_fields->{$fn}
                        or !defined $known_fields->{$fn}
                        or !$known_fields->{$fn})
                    and (!exists $readonly_fields->{$fn}
                        or !defined $readonly_fields->{$fn}
                        or !$readonly_fields->{$fn}))
            {
                $okay = 0;
                last;
            }
        }
    }
    else
    {
        say STDERR 'Scribe ' . $self->name() . ' was not given wanted_fields' if $self->{verbose} > 1;
        $okay = 0;
    }
    return $okay;
} # allowed_fields

=head2 known_fields

Returns the fields which this scribe knows about.

This must be overridden by the specific scribe class.

    my $known_fields = $scribe->known_fields();

=cut

sub known_fields {
    my $self = shift;

    return undef;
} # known_fields

=head2 readonly_fields

Returns the fields which this scribe knows about, which can't be overwritten,
but are allowed to be "wanted" fields. Things like file-size etc.

    my $readonly_fields = $scribe->readonly_fields();

=cut

sub readonly_fields {
    my $self = shift;

    return {filesize=>'NUMBER'};
} # readonly_fields

=head2 writable_fields

Returns the fields which this scribe knows about, which can be written into.

    my $writable_fields = $scribe->writable_fields();

=cut

sub writable_fields {
    my $self = shift;

    return $self->{writable_fields};
} # writable_fields

=head2 read_meta

Read the meta-data from the given file.

This must be overridden by the specific scribe class.

    my $meta = $scribe->read_meta($filename);

=cut

sub read_meta {
    my $self = shift;
    my $filename = shift;

} # read_meta

=head2 add_field_to_file

Adds a field to a file, taking account of whether it is a multi-value field or not.
This requires the old meta-data for the file to be passed in.

    $scribe->add_field_to_file(filename=>$filename,
        field=>$field,
        value=>$value,
        old_meta=>\%meta);

=cut
sub add_field_to_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};
    my $value = $args{value};
    my $old_meta = $args{old_meta};

    my $type = (
        exists $self->{wanted_fields}->{$field}
            and defined $self->{wanted_fields}->{$field}
        ? $self->{wanted_fields}->{$field}
        : 'UNKNOWN'
    );
    say STDERR "field=$field value=$value type=$type" if $self->{verbose} > 2;
    if ($type =~ /multi/i)
    {
        return $self->update_multival_field(
            filename=>$filename,
            field=>$field,
            value=>$value,
            old_vals=>$old_meta->{$field});
    }
    else
    {
        $self->replace_one_field(
            filename=>$filename,
            field=>$field,
            value=>$value);
    }
} # add_field_to_file

=head2 delete_field_from_file

Completely remove the given field.
For multi-value fields, it removes ALL the values.

This must be overridden by the specific scribe class.

    $scribe->delete_field_from_file(filename=>$filename,field=>$field);

=cut

sub delete_field_from_file {
    my $self = shift;
    my %args = @_;
    my $filename = $args{filename};
    my $field = $args{field};

} # delete_field_from_file

=head2 replace_all_meta

Overwrite the existing meta-data with that given.

    $scribe->replace_all_meta(filename=>$filename,meta=>\%meta);

=cut

sub replace_all_meta {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $meta = $args{meta};

    # overwrite the known writable fields
    # ignore the unknown fields
    my $writable = $self->writable_fields();
    foreach my $field (sort keys %{$writable})
    {
        if (exists $meta->{$field}
                and defined $meta->{$field})
        {
            $self->replace_one_field(filename=>$filename,
                field=>$field,
                value=>$meta->{$field});
        }
        else # not there, remove it
        {
            $self->delete_field_from_file(filename=>$filename,field=>$field);
        }
    }
} # replace_all_meta

=head1 Helper Functions

Private interface.

=head2 update_multival_field 

A multi-valued field could have individual values added or removed from it.
This expects a comma-separated list of individual values, prefixed with an operation:
'+' or nothing -- add the values
'-' -- remove the values
'=' -- replace the values

This also needs to know the existing values of the multi-valued field.
The old values are either a reference to an array, or a string with comma-separated values.

    $scribe->update_multival_field(filename=>$filename,
        field=>$field_name,
        value=>$value,
        old_vals=>$old_vals);

=cut
sub update_multival_field {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $field = $args{field};
    my $value = $args{value};
    my $old_vals = $args{old_vals};

    my $prefix = '+';
    if ($value =~ /^([+=-])(.*)/)
    {
        $prefix = $1;
        $value = $2;
    }
    say STDERR "prefix='$prefix'" if $self->{verbose} > 2;
    if ($prefix eq '=')
    {
        $self->replace_one_field(
            filename=>$filename,
            field=>$field,
            value=>$value);
    }
    else
    {
        if ($prefix eq '-')
        {
            $self->delete_multival_from_file(
                filename=>$filename,
                field=>$field,
                value=>$value,
                old_vals=>$old_vals);
        }
        else
        {
            $self->add_multival_to_file(
                filename=>$filename,
                field=>$field,
                value=>$value,
                old_vals=>$old_vals);
        }
    }
} # update_multival_field

=head2 add_multival_to_file 

Add a multi-valued field to the file.
Needs to know the existing values of the multi-valued field.
The old values are either a reference to an array, or a string with comma-separated values.

    $scribe->add_multival_to_file(filename=>$filename,
        field=>$field_name,
        value=>$value,
        old_vals=>$old_vals);

=cut
sub add_multival_to_file {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $fname = $args{field};
    my $old_vals = $args{old_vals};

    # allow for multiple values, comma-separated
    my @vals = ($args{value});
    if ($args{value} =~ /,/)
    {
        @vals = split(/,/, $args{value});
    }

    # add new value(s) to existing taglike-values
    my @old_values = ();
    if (ref $old_vals eq 'ARRAY')
    {
        @old_values = @{$old_vals};
    }
    elsif (!ref $old_vals)
    {
        @old_values = split(/,/, $old_vals);
    }
    my @newvals = @old_values;
    push @newvals, @vals;
    @newvals = uniq @newvals;
    my $newvals = join(',', @newvals);

    $self->replace_one_field(filename=>$filename,
        field=>$fname,
        value=>$newvals);
} # add_multival_to_file

=head2 delete_multival_from_file

Remove one value of a multi-valued field.
Needs to know the existing values of the multi-valued field.
The old values are either a reference to an array, or a string with comma-separated values.

    $scribe->delete_multival_from_file(filename=>$filename,
        value=>$value,
        field=>$field_name,
        old_vals=>$old_vals);

=cut
sub delete_multival_from_file ($%) {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $fname = $args{field};
    my $old_vals = $args{old_vals};

    # allow for multiple values, comma-separated
    my @vals = ($args{value});
    if ($args{value} =~ /,/)
    {
        @vals = split(/,/, $args{value});
    }
    my %to_delete = ();
    foreach my $t (@vals)
    {
        $to_delete{$t} = 1;
    }

    # remove value from existing values
    # preserving the existing order
    my @old_values = ();
    if (ref $old_vals eq 'ARRAY')
    {
        @old_values = @{$old_vals};
    }
    elsif (!ref $old_vals)
    {
        @old_values = split(/,/, $old_vals);
    }
    my @newvals = ();
    foreach my $t (@old_values)
    {
        if (! exists $to_delete{$t})
        {
            push @newvals, $t;
        }
    }
    my $newvals = join(',', @newvals);

    $self->replace_one_field(filename=>$filename,
        field=>$fname,
        value=>$newvals);
} # delete_multival_from_file

=head2 replace_one_field

Overwrite the given field. This does no checking.

This must be overridden by the specific scribe class.

    $scribe->replace_one_field(filename=>$filename,field=>$field,value=>$value);

=cut

sub replace_one_field {
    my $self = shift;
    my %args = @_;
    my $filename = $args{filename};
    my $field = $args{field};
    my $value = $args{value};

} # replace_one_field

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Scribe
__END__
