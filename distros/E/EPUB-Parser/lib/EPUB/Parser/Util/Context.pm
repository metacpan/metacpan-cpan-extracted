package EPUB::Parser::Util::Context;
use strict;
use warnings;
use Carp;
use Smart::Args;
use Exporter qw/import/;

our @EXPORT_OK = qw/ child_class context_name parser /;

sub child_class {
    args(
        my $class  => 'ClassName',
        my $context_name => 'Str',
    );

    my $child_class = sprintf( "%s::%s", $class, ucfirst($context_name) );

    local $@;
    eval "require $child_class";
    die $@ if $@;

    return $child_class;
}

sub context_name { shift->{context_name} }

sub parser {
    my $self = shift;
    my $context = 'in_' . $self->context_name;
    $self->{parser}->$context;
    $self->{parser};
}


1;

