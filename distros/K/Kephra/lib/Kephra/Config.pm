use v5.12;
use warnings;

package Kephra::Config;

use File::HomeDir;
use File::Spec;
use YAML;

use Kephra::Config::Default;

my $file_name = File::Spec->catfile( File::HomeDir->my_home, '.config', 'kephra', 'main-recent.yaml');

sub new {
    my $default = Kephra::Config::Default::get();
    my $data = {};
    if (-r $file_name){
        $data = (YAML::LoadFile( $file_name ))[0];
        check( $data, $default);
    } else { $data = $default; }
    return bless {data => $data};
}

sub write {
    my ($self) = @_;
    YAML::DumpFile( $file_name, $self->{'data'} );
}

sub reload {
    my ($self) = @_;
}

sub set_value {
    my ($self, $value, @keys) = @_;
    return undef unless @keys;
    my $last_key = pop @keys;
    my $data = $self->{'data'};
    for my $k (@keys){
        return undef unless exists $data->{ $k };
        $data = $data->{ $k };
    }
    $data->{$last_key} = $value if exists $data->{$last_key};
}

sub get_value {
    my ($self, @keys) = @_;
    my $data = $self->{'data'};
    for my $k (@keys){
        return undef unless exists $data->{ $k };
        $data = $data->{ $k };
    }
    return $data;
}


sub check {
    my ($data, $default) = @_;
    return unless ref $data eq 'HASH' and ref $default eq 'HASH';
    for my $k (keys %$data){
        delete $data->{$k} unless exists $default->{$k};
    }
    for my $k (keys %$default) {
        my $vr = ref $default->{$k};
        if ( not $vr){
            $data->{$k} = $default->{$k} if not exists $data->{$k} or ref $data->{$k};
        } elsif ($vr eq 'ARRAY'){
            if (ref $data->{$k} ne 'ARRAY'){
                 $data->{$k} = $default->{$k};
            } else {
                if (@{$default->{$k}}){
                    my $subvalref = ref $default->{$k}[0];
                    for my $i (reverse 0 .. $#{$data->{$k}}){
                        delete $data->{$k}[$i] if ref $data->{$k}[$i] ne $subvalref;
                    }
                    if (ref $default->{$k}[0] eq 'HASH') {
                       check( $_, $default->{$k}[0]) for @{$data->{$k}};
                    }
                }
            }
        } elsif ($vr eq 'HASH'){
            if (ref $data->{$k} ne 'HASH'){ $data->{$k} = $default->{$k} }
            else                          { check( $data->{$k}, $default->{$k} ) }
        } else { return }
    }
}

1;
