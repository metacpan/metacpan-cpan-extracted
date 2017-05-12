package Getopt::Chain::Builder;

use Moose;
use Getopt::Chain::Carp;

use Path::Dispatcher;
use Path::Dispatcher::Declarative::Builder;

has builder => qw/is ro lazy_build 1/, handles => [qw/ dispatcher rewrite /];
sub _build_builder {
    my $self = shift;
    return Path::Dispatcher::Declarative::Builder->new;
}

sub start {
    my $self = shift;
    $self->on( '' => always_run => 1, @_ );
}

sub on {
    my $self = shift;
    my $path = shift;

    my ( @argument_schema, $run, @given );
    while ( @_ ) {

        local $_ = shift;
        if ( ref eq 'ARRAY' ) {
            push @argument_schema, @$_;
        }
        elsif ( ref eq 'CODE' ) {
            $run = $_;
        }
        elsif ( ! defined ) {   
        }
        else {
            push @given, $_ => shift;
        }
    }
    my %given = @given;

    my %control = (
        map { $_ => $given{$_} } grep { exists $given{$_} } qw/always_run terminator/
    );
    
    my $matcher;
    if (ref $path eq 'ARRAY') {
        $matcher = $path;
    }
    elsif (ref $path eq 'Regexp') {
        $matcher = $path;
    }
    elsif (! ref $path) {
        if ( $path =~ s/\s+\*\s*$// ) { # "xyzzy *"
            $matcher = qr/$path\b(.*)/;
            $control{arguments_from_1} = 1;
        }
        elsif ( $path =~ m/^\s*\*\s*$/ ) { # "*"
            $matcher = qr/(.*)/;
            $control{arguments_from_1} = 1;
        }
        elsif ( $path =~ s/\s+--\s*$// ) { # "xyzzy --"
            $matcher = [ split m/\s+/, $path ];
            $control{terminator} = 1;
        }
        elsif ( $path =~ m/^\s*--\s*$/ ) { # "--"
            $matcher = [];
            $control{terminator} = 1;
        }
        else {
            $matcher = [ split m/\s+/, $path ];
        }
    }
    else {
        croak "Don't recogonize matcher ($path)";
    }
    $self->builder->on( $matcher, sub { # The builder should do the split for us!
        my $context = shift;
        my $dollar1;
        $dollar1 = $1 if $control{arguments_from_1};
        return $context->run_step( \@argument_schema, $run, { %control }, dollar1 => $dollar1 );
    } );
}

sub under {
    my $self = shift;
    $self->builder->under( @_ );
}

1;
