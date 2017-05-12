package HTTP::Balancer::Command::Init;

use Modern::Perl;

use Moose;

with qw( HTTP::Balancer::Role::Command );

use Path::Tiny;

sub run {
    my ($self, ) = @_;

    require HTTP::Balancer::Model;
    $self->mkpath( map { $_->model_dir } HTTP::Balancer::Model->models );
}

sub mkpath {
    my ($self, @path) = @_;

    for my $path (map { path($_) } @path) {
        if ($path->exists) {
            say "$path has existed.";
            $path->mkpath;
        } else {
            say "create $path";
            $path->mkpath;
        }
    }

    $self;
}

1;
__END__

=head1 NAME

HTTP::Balancer::Command::Init - prepare the environment for HTTP::Balancer

=head1 SYNOPSIS

    # http-balancer init

=cut
