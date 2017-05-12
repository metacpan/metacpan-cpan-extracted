package Language::MinCaml::Type;
use strict;
use base qw(Class::Accessor::Fast Exporter);

__PACKAGE__->mk_accessors(qw(kind children));

our @EXPORT = qw(Type_Unit Type_Bool Type_Int Type_Float Type_Tuple
                 Type_Array Type_Var Type_Fun);

for my $routine_name (@EXPORT){
    my $routine;
    my $kind = $routine_name;
    $kind =~ s/^Type_//;
    $routine = sub { __PACKAGE__->new($kind, @_); };
    no strict 'refs';
    *{$routine_name} = $routine;
}

sub new {
    my($class, $kind, @children) = @_;
    return bless { kind => $kind, children => \@children }, $class;
}

1;
