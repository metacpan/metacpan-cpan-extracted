package Git::PurePerl::Object::Commit;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use Encode qw/decode/;
use namespace::autoclean;

extends 'Git::PurePerl::Object';

has 'kind' =>
    ( is => 'ro', isa => 'ObjectKind', required => 1, default => 'commit' );
has 'tree_sha1'   => ( is => 'rw', isa => 'Str', required => 0 );
has 'parent_sha1s' => ( is => 'rw', isa => 'ArrayRef[Str]', required => 0, default => sub { [] });
has 'author' => ( is => 'rw', isa => 'Git::PurePerl::Actor', required => 0 );
has 'authored_time' => ( is => 'rw', isa => 'DateTime', required => 0 );
has 'committer' =>
    ( is => 'rw', isa => 'Git::PurePerl::Actor', required => 0 );
has 'committed_time' => ( is => 'rw', isa => 'DateTime', required => 0 );
has 'comment'        => ( is => 'rw', isa => 'Str',      required => 0 );
has 'encoding'       => ( is => 'rw', isa => 'Str',      required => 0 );

my %method_map = (
    'tree'      => 'tree_sha1',
    'parent'    => '_push_parent_sha1',
    'author'    => 'authored_time',
    'committer' => 'committed_time'
);

sub BUILD {
    my $self = shift;
    return unless $self->content;
    my @lines = split "\n", $self->content;
    my %header;
    while ( my $line = shift @lines ) {
        last unless $line;
        my ( $key, $value ) = split ' ', $line, 2;
        push @{$header{$key}}, $value;
    }
    $header{encoding}
        ||= [ $self->git->config->get(key => "i18n.commitEncoding") || "utf-8" ];
    my $encoding = $header{encoding}->[-1];
    for my $key (keys %header) {
        for my $value (@{$header{$key}}) {
            $value = decode($encoding, $value);
            if ( $key eq 'committer' or $key eq 'author' ) {
                my @data = split ' ', $value;
                my ( $email, $epoch, $tz ) = splice( @data, -3 );
                $email = substr( $email, 1, -1 );
                my $name = join ' ', @data;
                my $actor
                    = Git::PurePerl::Actor->new( name => $name, email => $email );
                $self->$key($actor);
                $key = $method_map{$key};
                my $dt
                    = DateTime->from_epoch( epoch => $epoch, time_zone => $tz );
                $self->$key($dt);
            } else {
                $key = $method_map{$key} || $key;
                $self->$key($value);
            }
        }
    }
    $self->comment( decode($encoding, join "\n", @lines) );
}


sub tree {
    my $self = shift;
    return $self->git->get_object( $self->tree_sha1 );
}


sub _push_parent_sha1 {
    my ($self, $sha1) = @_;
  
    push(@{$self->parent_sha1s}, $sha1);
}

sub parent_sha1 {
    return shift->parent_sha1s->[0];
}
  
sub parent {
    my $self = shift;
    return $self->git->get_object( $self->parent_sha1 );
}

sub parents {
    my $self = shift;
    
    return map { $self->git->get_object( $_ ) } @{$self->parent_sha1s};
}

__PACKAGE__->meta->make_immutable;

