package # hidden from PAUSE indexer
Var::Javan;
our $VERSION = '0.000001';

use 5.020; use warnings; use autodie;

use Keyword::Declare;
use Types::Standard;

sub import {

    keyword let (Ident $type, Ident $name) {
        _define_symbol('lexical', $name, $type);
    }

    keyword let (Ident $name) {
        _define_symbol('lexical', $name);
    }

    keyword var (Ident? $type, Ident $name) {
        _define_symbol('global', $name, $type);
    }

    keyword const (Ident? $type, Ident $name, '=', Expr $value) {
        _define_symbol('constant', $name, $type, $value);
    }
}


sub _croak {
    my ($filename, $linenum) = (caller 1)[1,2];
    die join q{}, @_, " at $filename line $linenum\n";
}

sub _constrain {
    use Variable::Magic qw< wizard cast >;
    cast $_[0], wizard( set => $_[1] );
}

sub _typify {
    my ($kind, $name, $type) = @_;

    my $type_obj = do { no strict; qq{Types::Standard::$type}->() };

    _constrain($_[3] => sub {
        my $val = ${shift()};
        _croak qq{Can't assign '$val' to $kind $name of type $type}
            if ! $type_obj->check($val);
    });
}

sub _define_symbol {
    my ($kind, $name, $type, $value) = @_;

    my $prefix
        = $kind eq 'global' ? q{} : q{use experimental 'lexical_subs'; my};

    my $init
        = @_ < 4 ? q{} : qq{\$data = $value;
                             Var::Javan::_constrain( \$data, sub {
                                 Var::Javan::_croak qq{Can't assign '\${shift()}' to constant $name};
                             })};

    my $type_setup
        = !$type ? q{}
                 : qq{ Var::Javan::_typify(qw<$kind $name $type>, \$data); };

    my $setup
        = $init || $type_setup ? qq{state \$setup = do { $type_setup; $init; };}
                               : q{};

    return qq{
        $prefix sub $name() :lvalue {
            state \$data;
            $setup
            \$data;
        }
        $name
    } =~ tr/\n/ /r;
}


1; # Magic true value required at end of module
