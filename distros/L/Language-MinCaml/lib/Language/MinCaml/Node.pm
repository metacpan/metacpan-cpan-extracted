package Language::MinCaml::Node;
use strict;
use base qw(Class::Accessor::Fast Exporter);

__PACKAGE__->mk_accessors(qw(kind children));

our @EXPORT = qw(Node_Unit Node_Bool Node_Int Node_Float Node_Tuple
                 Node_Array Node_Var Node_Not Node_Neg Node_Add Node_Sub
                 Node_FNeg Node_FAdd Node_FSub Node_FMul Node_FDiv
                 Node_Eq Node_LE Node_If Node_Let Node_LetRec Node_App
                 Node_LetTuple Node_Get Node_Put);

for my $routine_name (@EXPORT){
    my $kind = $routine_name;
    $kind =~ s/^Node_//;
    my $routine = sub { __PACKAGE__->new($kind, @_); };
    no strict 'refs';
    *{$routine_name} = $routine;
}

sub new {
    my($class, $kind, @children) = @_;
    return bless { kind => $kind, children => \@children }, $class;
}

sub to_str {
    my($self, $depth) = @_;
    $depth ||= 0;
    my $content = "\t" x $depth . "$self->{kind}\n";

    for my $child (@{$self->{children}}) {
        if (ref($child) eq __PACKAGE__) {
            $content .= $child->to_str($depth + 1);
        }
    }

    $content;
}

1;
