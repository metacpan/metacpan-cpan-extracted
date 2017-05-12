package Git::ReleaseRepo::WithVersionPrefix;
{
  $Git::ReleaseRepo::WithVersionPrefix::VERSION = '0.006';
}

use Moose::Role;

around git => sub {
    my ( $orig, $self, @args ) = @_;
    my $obj = $self->$orig( @args );
    $obj->release_prefix( $self->release_prefix );
    return $obj;
};
1;
__END__

=head1 NAME

Git::ReleaseRepo::WithVersionPrefix - Make sure the Git::Repository has a version prefix set
