use Test::More;
use File::Spec;

BEGIN { plan tests => 2 };

use Inline Lua => 'DATA';

ok(1);

my $file = File::Spec->catfile("t", "test.out");
open FILE, ">", $file or die $!;
write_file(\*FILE, "foo", "bar", "baz");
close FILE;

my $fh = get_fh($file);
is_deeply([<$fh>], ["foo\n", "bar\n", "baz\n"]);

__END__
__Lua__
function write_file (fh, ...)
    local arg={...}
    for i,v in ipairs(arg) do
	fh:write(v, "\n")
    end
end

function get_fh (file)
    return io.open(file, "r")
end
