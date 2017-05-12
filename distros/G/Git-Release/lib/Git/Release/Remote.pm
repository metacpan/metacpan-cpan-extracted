package Git::Release::Remote;
use Moose;

has name => ( is => 'rw' , isa => 'Str' );

has manager => ( is => 'rw' , isa => 'Git::Release' );

has info => (is => 'rw', isa => 'HashRef' , lazy => 1, default => sub { 
    my $self = shift;
    my @lines = $self->manager->repo->command(qw(remote show), $self->name);
    my %info = ( tracking => { } );
    for my $line ( @lines ) {
        if( ($line =~ m{^\s*(\S+)\s*pushes to (\S+)\s*\((.*?)\)}) ) {
            $info{tracking}->{ $1 } = 'remotes/' . $self->name . '/' . $2;
        }
    }
    return \%info;
});

1;
