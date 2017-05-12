package Test::Workflow::Layer;
use strict;
use warnings;

use Test::Workflow::Block;

use Fennec::Util qw/accessors require_module/;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

our @ATTRIBUTES = qw{
    test
    case
    child
    before_case
    before_each
    before_all
    after_each
    after_all
    around_each
    around_all
    control
};

accessors 'finalized', @ATTRIBUTES;

sub new {
    bless( {map { ( $_ => [] ) } @ATTRIBUTES}, shift );
}

sub merge_in {
    my $self = shift;
    my ( $caller, @classes ) = @_;
    for my $class (@classes) {
        require_module $class;
        push @{$self->$_} => @{$class->TEST_WORKFLOW->root_layer->$_} for @ATTRIBUTES;
    }
}

sub add_control {
    my $self = shift;
    push @{$self->control} => @_;
}

sub add_after_case {
    goto &before_each;
}

for my $type (qw/test case child before_case before_each before_all around_each around_all/) {
    my $add = sub {
        my $self = shift;
        my $block = Test::Workflow::Block->new(@_);
        $block->subtype($type);
        push @{$self->$type} => $block;
    };
    no strict 'refs';
    *{"add_$type"} = $add;
}

for my $type (qw/after_each after_all/) {
    my $add = sub {
        my $self = shift;
        my $block = Test::Workflow::Block->new(@_);
        $block->subtype($type);
        unshift @{$self->$type} => $block;
    };
    no strict 'refs';
    *{"add_$type"} = $add;
}

1;

__END__

=head1 NAME

Test::Workflow::Layer - Used to track per-encapsulation meta-data

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Test-Workflow is free software; Standard perl license.

Test-Workflow is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
