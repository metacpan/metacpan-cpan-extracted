package Devel::ebug::Wx::Plugin;

use strict;
use base qw(Exporter);

our @EXPORT_OK = qw(load_plugins MODIFY_CODE_ATTRIBUTES);
our %EXPORT_TAGS = ( manager => [ qw(load_plugins) ],
                     plugin  => [ qw(MODIFY_CODE_ATTRIBUTES) ],
                     );

my %attributes;

sub load_plugins {
    my( %args ) = @_;

    require Module::Pluggable::Object;
    Module::Pluggable::Object->new( %args, require => 1 )->plugins;
}

sub MODIFY_CODE_ATTRIBUTES {
    my( $class, $code, @attrs ) = @_;
    my( @known, @unknown );

    foreach ( @attrs ) {
        /^(?:Service|Command|View|Configuration|Configurable)\s*(?:$|\()/ ?
          push @known, $_ : push @unknown, $_;
    }

    $attributes{$class}{$code} = [ $code, \@known ];

    return @unknown;
}

our $AUTOLOAD;

sub AUTOLOAD {
    ( my $method = $AUTOLOAD ) =~ s/.*:://;
    return if $method eq 'DESTROY';

    return _instantiators( $method );
}

sub _instantiators {
    my( $name ) = @_;
    $name =~ s/s$//;
    my $is_class = $name =~ s/_classe$//;

    my @rv;
    foreach my $c ( keys %attributes ) {
        my $class = $c;
        foreach my $v ( values %{$attributes{$c}} ) {
            my( $code, $attrs ) = @$v;
            next unless grep lc( $_ ) eq $name, @$attrs;
            if( $is_class ) {
                push @rv, $class;
            } else {
                push @rv, sub {
                    $code->( $class, @_ );
                };
            }
        }
    }

    return @rv;
}

1;
