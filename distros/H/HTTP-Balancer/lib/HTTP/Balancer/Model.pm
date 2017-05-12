package HTTP::Balancer::Model;
use Modern::Perl;
use Moose;
use File::Spec;
use Path::Tiny qw(!path);

with qw(HTTP::Balancer::Role);

=head1 NAME

HTTP::Balancer::Model - the base class of models of HTTP::Balancer

=head1 SYNOPSIS

    package HTTP::Balancer::Model::Foo;
    use Modern::Perl;

    use Moose;
    extends qw(HTTP::Balancer::Model);

    use MoooseX::Storage;
    with Storage(format => 'YAML', io => 'File');

=head1 FUNCTIONS AND METHODS

=head2 models

returns the list of last name of HTTP::Balancer::Model::*

=cut

sub models {
    my $class = ref($_[0]) ? ref(shift) : shift;
    require Namespace::Dispatch;
    map { $class->model($_) }
    @{Namespace::Dispatch::leaves($class)};
}

=head2 model_name

class method and instance method

returns lowercase of last name of current model

=cut

sub model_name {
    my ($self, ) = @_;
    my $ref = ref($self) || $self;
    $ref =~ s{HTTP::Balancer::Model::}{};
    return lc($ref);
}

=head2 model_dir

class method and instance method

returns the directory store the entities of current model

=cut

sub model_dir {
    my ($self, ) = @_;
    File::Spec->catdir(
        $self->config->dbpath,
        $self->model_name
    );
}

=head2 path

instance method

returns the path for storing current object

=cut

sub path {
    my ($self, ) = @_;
    $self->id ?
    File::Spec->catfile(
        $self->model_dir,
        $self->id
    )
    : undef;
}

=head2 glob

class method

returns all entities stored in model_dir, sorted with id.

=cut

sub glob {
    my ($self, ) = @_;
    sort {
        [File::Spec->splitpath($a)]->[-1] <=> [File::Spec->splitpath($b)]->[-1]
    }
    glob(File::Spec->catfile($self->model_dir, "*"));
}

=head2 save

instance method

save current object into model_dir, named as its id.

generate auto-incremented id for new object not on disk yet.

=cut

sub save {
    my ($self, ) = @_;

    unless ($self->id) {
        my $last = [$self->glob]->[-1];
        my $num = $last ? [File::Spec->splitpath($last)]->[-1] : 0;
        $self->id($num+1)
    }

    $self->store($self->path);
}

=head2 all(\&closure)

class method

returns all object restored from disk

call \&closure on each instance if given.

=cut

sub all {
    my ($self, $closure) = @_;
    map { $closure ? $closure->($_) : $_ }
    map { $self->load($_) } $self->glob;
}

=head2 find($attr => $value)

class method

returns the first object satisfying the condition from disk.

=cut

sub find {
    my ($self, $attr, $value) = @_;
    for ($self->all) {
        return $_ if $_->$attr eq $value;
    }
}

=head2 where($attr => $value)

class method

returns all objects satisfying the condition from disk

=cut

sub where {
    my ($self, $attr, $value) = @_;
    grep {
        $_->$attr eq $value
    } $self->all;
}

=head2 remove

remove the instance from disk.

=cut

sub remove {
    my ($self, ) = @_;
    Path::Tiny::path($self->path)->remove or die $@;
}

=head2 columns

list names of all columns of current Model.

=cut

sub columns {
    my ($self, ) = @_;
    map { $_->name } $self->meta->get_all_attributes;

}

=head2 slice(@columns)

returns attributes slice

=cut

sub slice {
    my ($self, @columns) = @_;
    map { $self->$_ } @columns;
}

1;
__END__

