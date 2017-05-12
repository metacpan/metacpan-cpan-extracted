package Test::Workflow::Meta;
use strict;
use warnings;

use Test::Workflow::Layer;
use Test::Builder;

use Fennec::Util qw/accessors/;

accessors qw{
    test_class build_complete root_layer test_run test_wait test_sort ok diag
    skip todo_start todo_end control_store
};

sub new {
    my $class = shift;
    my ($test_class) = @_;

    my $tb = "tb";

    my $root_layer = Test::Workflow::Layer->new();

    my $self = bless(
        {
            test_class  => $test_class,
            root_layer  => $root_layer,
            ok          => Fennec::Util->can("${tb}_ok"),
            diag        => Fennec::Util->can("${tb}_diag"),
            skip        => Fennec::Util->can("${tb}_skip"),
            todo_start  => Fennec::Util->can("${tb}_todo_start"),
            todo_end    => Fennec::Util->can("${tb}_todo_end"),
            layer_stack => [$root_layer],
        },
        $class
    );

    return $self;
}

my @LAYER_STACK;

sub push_layer {
    my $self = shift;
    push @LAYER_STACK => @_;
}

sub pop_layer {
    my $self    = shift;
    my ($check) = @_;
    my $layer   = pop @LAYER_STACK;
    die "Bad pop!" unless $layer == $check;
    return $layer;
}

sub peek_layer {
    my $self = shift;
    return $LAYER_STACK[-1];
}

1;

__END__

=head1 NAME

Test::Workflow::Meta - The meta-object added to all Test-Workflow test classes.

=head1 DESCRIPTION

When you C<use Test::Workflow> a function is added to you class named
'TEST_WORKFLOW' that returns the single Test-Workflow meta-object that tracks
information about your class.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Test-Workflow is free software; Standard perl license.

Test-Workflow is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
