#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;

our $CLASS = "Exporter::Declare::Export::Generator";
require_ok $CLASS;

tests create => sub {
    throws_ok { $CLASS->new(sub{ sub {} }, exported_by => __PACKAGE__ ) }
        qr/You must specify type when calling $CLASS\->new()/,
        "Required specs";
    my $export = $CLASS->new(sub { sub {} }, exported_by => __PACKAGE__, type => 'sub' );
    isa_ok( $export, $CLASS );
    is( $export->type, 'sub', "Stored property" );
};

tests generate_subs => sub {
    my $val = 1;
    my $export = $CLASS->new(
        sub { my $out = $val++; sub { $out } },
        exported_by => __PACKAGE__,
        type => 'sub'
    );
    $export->inject( __PACKAGE__, 'foo' );
    $export->inject( __PACKAGE__, 'bar' );
    $export->inject( __PACKAGE__, 'baz' );
    is( foo(), 1, "First generated" );
    is( bar(), 2, "Second generated" );
    is( baz(), 3, "Third generated" );
    is( $val, 4, "value incrimented" );
};

tests generate_vars => sub {
    my $val = 1;
    my $export = $CLASS->new(
        sub { my $out = $val++; \$out },
        exported_by => __PACKAGE__,
        type => 'variable'
    );
    $export->inject( __PACKAGE__, 'foo' );
    $export->inject( __PACKAGE__, 'bar' );
    $export->inject( __PACKAGE__, 'baz' );
    no strict 'vars';
    is( $foo, 1, "First generated" );
    is( $bar, 2, "Second generated" );
    is( $baz, 3, "Third generated" );
    is( $val, 4, "value incrimented" );
};

run_tests();
done_testing;

__END__

sub type { shift->_data->{ type }}

sub new {
    my $class = shift;
    croak "Generators must be coderefs, not " . ref($_[0])
        unless ref( $_[0] ) eq 'CODE';
    $class->SUPER::new( @_ );
}

sub generate {
    my $self = shift;
    my ( $import_class, @args ) = @_;
    my $ref = $self->( $self->exported_by, $import_class, @args );

    return Exporter::Declare::Export::Sub->new(
        $ref,
        %{ $self->_data },
    ) if $self->type eq 'sub';

    return Exporter::Declare::Export::Variable->new(
        $ref,
        %{ $self->_data },
    );
}

sub inject {
    my $self = shift;
    my ( $class, $name, @args ) = @_;
    $self->generate( $class, @args )->inject( $class, $name );
}

1;
