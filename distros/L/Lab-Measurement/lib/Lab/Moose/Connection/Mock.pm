package Lab::Moose::Connection::Mock;

use 5.010;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;
use Data::Dumper;
use YAML::XS;
use Carp;

our $VERSION = '3.542';

has log_file => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_log_file',
);

has log_fh => (
    is        => 'ro',
    isa       => 'FileHandle',
    builder   => 'log_build_fh',
    predicate => 'has_log_fh',
    lazy      => 1,
);

has logs => (
    is       => 'ro',
    isa      => 'ArrayRef',
    writer   => '_logs',
    init_arg => undef,
);

has id => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_id',
    init_arg => undef,
    default  => 0,
);

sub log_build_fh {
    my $self = shift;
    my $file = $self->log_file();
    open my $fh, '<', $file
        or croak "cannot open logfile '$file': $!";
    return $fh;
}

sub BUILD {
    my $self = shift;
    if ( !( $self->has_log_file() || $self->has_log_fh() ) ) {
        croak "no log_file in Mock connection";
    }

    my $fh   = $self->log_fh();
    my $yaml = do { local $/; <$fh> };
    my @logs = Load($yaml);
    $self->_logs( \@logs );
    close $fh
        or croak "cannot close log_fh: $!";
}

my $meta = __PACKAGE__->meta();

for my $method (qw/Read Write Query Clear/) {
    $meta->add_method(
        $method => sub {
            my $self   = shift;
            my @params = @_;
            my %arg;
            if ( ref $params[0] eq 'HASH' ) {
                %arg = %{ $params[0] };
            }
            else {
                %arg = @params;
            }
            $arg{method} = $method;
            my $id = $self->id();
            $arg{id} = $id;
            $self->_id( ++$id );
            my $log = shift @{ $self->logs };

            my $retval     = delete $log->{retval};
            my $retval_enc = delete $log->{retval_enc};

            # Compare:
            my $arg_yaml = Dump( \%arg );
            my $log_yaml = Dump($log);
            if ( $arg_yaml ne $log_yaml ) {
                croak <<"EOF";
mismatch in Mock Connection:
logged:
$log_yaml
received:
$arg_yaml
EOF
            }
            if ( defined $retval_enc && $retval_enc eq 'hex' ) {
                $retval = pack( 'H*', $retval );
            }
            return $retval;
        }
    );
}

with 'Lab::Moose::Connection';

$meta->make_immutable();
1;

