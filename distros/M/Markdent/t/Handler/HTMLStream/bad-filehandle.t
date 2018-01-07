use strict;
use warnings;

use Test2::V0;

use File::Temp qw( tempfile );
use IO::File;
use Markdent::Handler::HTMLStream::Fragment;
use Markdent::Parser;

{
    my $fh = tempfile();

    my $handler
        = Markdent::Handler::HTMLStream::Fragment->new( output => $fh );

    close $fh or die "Cannot close temp filehandle: $!";

    like(
        dies { _parse_to_handler($handler) },
        qr/\QCannot write to handle/,
        'Got an exception when the HTMLStream handler tries to write to a closed filehandle',
    );
}

{
    my $fh = IO::File->new_tmpfile();

    my $handler
        = Markdent::Handler::HTMLStream::Fragment->new( output => $fh );

    close $fh or die "Cannot close temp filehandle: $!";

    like(
        dies { _parse_to_handler($handler) },
        qr/\QCannot write to handle/,
        'Got an exception when the HTMLStream handler tries to write to a closed filehandle',
    );
}

sub _parse_to_handler {
    my $handler = shift;

    my $parser = Markdent::Parser->new( handler => $handler );

    my $markdown = <<'EOF';
This is a paragraph
EOF

    $parser->parse( markdown => $markdown );

    return;
}

done_testing();
