package File::Sticker::Derive;
$File::Sticker::Derive::VERSION = '4.301';
=head1 NAME

File::Sticker::Derive - derive values from existing meta-data

=head1 VERSION

version 4.301

=head1 SYNOPSIS

    use File::Sticker::Derive;

    my $deriver = File::Sticker::Derive->new(%args);

    my $derived_meta = $deriver->derive(filename=>$filename,meta=>$meta);

=head1 DESCRIPTION

This will derive values from existing meta-data.

This is a plug-in, different plug-ins will do different derivations.

=cut

use common::sense;

=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 new

Create a new object, setting global values for the object.

    my $obj = File::Sticker::Derive->new();

=cut

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = bless ({%parameters}, ref ($class) || $class);

    return ($self);
} # new

=head2 init

Initialize the object.

    $deriver->init(%args);

=cut

sub init {
    my $self = shift;
    my %parameters = @_;

    foreach my $key (keys %parameters)
    {
	$self->{$key} = $parameters{$key};
    }
} # init

=head2 name

The name of the deriver; this is basically the last component
of the module name. This works as either a class function or a method.

$name = $self->name();

$name = File::Sticker::Derive::name($class);

=cut

sub name {
    my $class = shift;
    
    my $fullname = (ref ($class) ? ref ($class) : $class);

    my @bits = split('::', $fullname);
    return pop @bits;
} # name

=head2 order

The order of this deriver, ranging from 0 to 99.
This makes sure that the deriver is applied in order;
useful because a later deriver may depend on data created
by an earlier deriver.

This must be overridden by the specific deriver class.

=cut

sub order {
    return 50;
} # order

=head2 derive

Derive common values from the existing meta-data.
This is expected to update the given meta-data.

This must be overridden by the specific deriver class.

    $deriver->derive(filename=>$filename, meta=>$meta);

=cut

sub derive {
    my $self = shift;
    my %args = @_;

    my $filename = $args{filename};
    my $meta = $args{meta};
} # derive

=head1 Helper Functions

Private interface.


=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Derive
__END__
