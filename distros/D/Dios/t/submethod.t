use Test::More;
plan tests => 6;

use Dios;

class Basic {
    submethod submeth {
        1;
    }
}

class Der is Basic {
    method call_submeth {
        $self->submeth();
    }
}

my $der_obj = Der->new;
my $basic_obj = Basic->new;

ok !defined(eval{ 'Der'->call_submeth }) => "Can't call base submethod from derived class";
ok !defined(eval{ 'Der'->submeth      }) => "Can't call base submethod through derived class";

ok !defined(eval{ $der_obj->call_submeth }) => "Can't call base submethod from derived object";
ok !defined(eval{ $der_obj->submeth      }) => "Can't call base submethod through derived object";

ok  defined(eval{ 'Basic'->submeth })    => "Can call base submethod on base class";
ok  defined(eval{ $basic_obj->submeth }) => "Can call base submethod on base object";

done_testing();
