use Exception::Backtrace;
use Sub::Name qw/subname/;
use Devel::StackTrace;

my ($f, $g, $h);

$f = subname fn1 => sub {
    $g->();
};

$g = subname "Foo::Bar" => sub {
    $h->();
};

$h = sub {
    $DB::single = 1;
    warn "ebt::\n ", Exception::Backtrace::create_backtrace()->to_string(), "\n";
    warn "dt::\n ", Devel::StackTrace->new(skip_frames => 1, message => ""), "\n";
};

$f->();

#use Devel::Peek;
#warn Dump($g);
