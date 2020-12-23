package Make::Target;

use strict;
use warnings;
## no critic (ValuesAndExpressions::ProhibitConstantPragma)
use constant DEBUG => $ENV{MAKE_DEBUG};
## use critic

our $VERSION = '2.011';

# Intermediate 'target' package
# There is an instance of this for each 'target' that apears on
# the left hand side of a rule i.e. for each thing that can be made.
sub new {
    my ( $class, $name, $info ) = @_;
    return bless {
        NAME       => $name,    # name of thing
        MAKEFILE   => $info,    # Makefile context
        RULES      => [],
        RULE_TYPE  => undef,    # undef, :, ::
        HAS_RECIPE => undef,    # undef, boolean
        Pass       => 0,        # Used to determine if 'done' this sweep
    }, $class;
}

sub date {
    my $self = shift;
    my $info = $self->Info;
    return $info->date( $self->Name );
}

sub phony {
    my $self = shift;
    return $self->Info->phony( $self->Name );
}

sub has_recipe {
    my ($self) = @_;
    return $self->{HAS_RECIPE} if defined $self->{HAS_RECIPE};
    ## no critic (BuiltinFunctions::RequireBlockGrep)
    return $self->{HAS_RECIPE} = grep @{ $_->recipe }, @{ $self->{RULES} };
    ## use critic
}

sub rules {
    my ($self) = @_;
    if ( !$self->phony && !$self->has_recipe ) {
        my $rule = $self->Info->patrule( $self->Name, $self->{RULE_TYPE} || ':' );
        DEBUG and print STDERR "Implicit rule (", $self->Name, "): @{ $rule ? $rule->prereqs : ['none'] }\n";
        $self->add_rule($rule) if $rule;
    }
    return $self->{RULES};
}

sub add_rule {
    my ( $self, $rule ) = @_;
    my $new_kind = $rule->kind;
    my $kind     = $self->{RULE_TYPE} ||= $new_kind;
    die "Target '$self->{NAME}' had '$kind' but tried to add '$new_kind'"
        if $kind ne $new_kind;
    $self->{HAS_RECIPE} ||= undef;    # reset if was no or unknown
    return push @{ shift->{RULES} }, $rule;
}

sub Name {
    return shift->{NAME};
}

sub Base {
    my $name = shift->{NAME};
    $name =~ s/\.[^.]+$//;
    return $name;
}

sub Info {
    return shift->{MAKEFILE};
}

sub done {
    my $self = shift;
    my $pass = $self->Info->pass;
    return 1 if ( $self->{Pass} == $pass );
    $self->{Pass} = $pass;
    return 0;
}

# as part of "out of date" processing, if any child is remade, I need too
sub recurse {
    my ( $self, $method ) = @_;
    return if $self->done;
    my $info = $self->Info;
    my @results;
    DEBUG and print STDERR "Build " . $self->Name, "\n";
    foreach my $rule ( @{ $self->rules } ) {
        ## no critic (BuiltinFunctions::RequireBlockMap)
        push @results, map $info->target($_)->recurse($method), @{ $rule->prereqs };
        ## use critic
        push @results, $rule->$method($self);
    }
    return @results;
}

1;
