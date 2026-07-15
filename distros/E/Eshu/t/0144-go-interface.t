use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# interface definition
{
	my $input = <<'END';
type Writer interface {
Write(p []byte) (n int, err error)
Close() error
}
END
	my $expected = <<'END';
type Writer interface {
	Write(p []byte) (n int, err error)
	Close() error
}
END
	is(go($input), $expected, 'interface definition');
}

# empty interface
{
	my $input = <<'END';
type Any interface{}
END
	my $expected = <<'END';
type Any interface{}
END
	is(go($input), $expected, 'empty interface on one line');
}

# interface with embedded interface
{
	my $input = <<'END';
type ReadWriter interface {
Reader
Writer
Seek(offset int64, whence int) (int64, error)
}
END
	my $expected = <<'END';
type ReadWriter interface {
	Reader
	Writer
	Seek(offset int64, whence int) (int64, error)
}
END
	is(go($input), $expected, 'interface embedding other interfaces');
}

done_testing;
