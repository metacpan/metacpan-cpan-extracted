package Git::Release::RemoteManager;
use Moose;
use Git::Release::Remote;

has manager => ( is => 'rw' );

sub repo { return $_[0]->manager->repo; }

sub add { 
	my ($self,$name,$uri) = @_;
	$self->manager->repo->command('remote','add',$name,$uri);
}

sub all {
	my $self = shift;
    # provide a list context to get remote names
    return map { $self->get($_) } $self->list;
}

sub list { 
    my $self = shift;
    my @remotes = $self->manager->repo->command('remote');
    chomp(@remotes);
    return @remotes;
}

sub get { 
    my ($self,$name) = @_;
    return Git::Release::Remote->new( manager => $self->manager , name => $name );
}

sub origin {
    my @r = grep /origin/,$_[0]->list;
    return pop @r if @r;
}

1;
