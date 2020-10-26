package File::Sticker::Reader;
$File::Sticker::Reader::VERSION = '1.01';
=head1 NAME

File::Sticker::Reader - read and standardize meta-data from files

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    use File::Sticker::Reader;

    my $obj = File::Sticker::Reader->new(%args);

    my $meta = $obj->read_meta($filename);

=head1 DESCRIPTION

This will read meta-data from files in various formats, and standardize it to a common
nomenclature, such as "tags" for things called tags, or Keywords or Subject etc.

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

# FOR DEBUGGING
=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 new

Create a new object, setting global values for the object.

    my $obj = File::Sticker::Reader->new();

=cut

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = bless ({%parameters}, ref ($class) || $class);

    return ($self);
} # new

=head2 init

Initialize the object.
Set which fields you are interested in ('wanted_fields').

    $reader->init(wanted_fields=>{title=>'TEXT',count=>'NUMBER',tags=>'MULTI'});

=cut

sub init {
    my $self = shift;
    my %parameters = @_;

    foreach my $key (keys %parameters)
    {
	$self->{$key} = $parameters{$key};
    }
    $self->{file_magic} = File::LibMagic->new();
} # init

=head2 name

The name of the reader; this is basically the last component
of the module name.  This works as either a class function or a method.

$name = $self->name();

$name = File::Sticker::Reader::name($class);

=cut

sub name {
    my $class = shift;
    
    my $fullname = (ref ($class) ? ref ($class) : $class);

    my @bits = split('::', $fullname);
    return pop @bits;
} # name

=head2 allow

If this reader can be used for the given file, and the wanted_fields then this returns true.
Returns TRUE if there are no wanted_fields.

    if ($reader->allow($file))
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
        if (exists $self->{wanted_fields}
                and defined $self->{wanted_fields})
        {
            # the known fields must be a subset of the wanted fields
            my $known_fields = $self->known_fields();
            foreach my $fn (keys %{$self->{wanted_fields}})
            {
                if (!exists $known_fields->{$fn}
                        or !defined $known_fields->{$fn}
                        or !$known_fields->{$fn})
                {
                    $okay = 0;
                    last;
                }
            }
        }
    }
    return $okay;
} # allow

=head2 allowed_file

If this reader can be used for the given file, then this returns true.
This must be overridden by the specific reader class.

    if ($reader->allowed_file($file))
    {
	....
    }

=cut

sub allowed_file {
    my $self = shift;
    my $file = shift;

    return 0;
} # allowed_file

=head2 known_fields

Returns the fields which this reader knows about.

This must be overridden by the specific reader class.

    my $known_fields = $reader->known_fields();

=cut

sub known_fields {
    my $self = shift;

    return undef;
} # known_fields

=head2 read_meta

Read the meta-data from the given file.

This must be overridden by the specific reader class.

    my $meta = $reader->read_meta($filename);

=cut

sub read_meta {
    my $self = shift;
    my $filename = shift;

} # read_meta

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Reader
__END__
