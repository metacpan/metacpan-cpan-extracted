package JavaScript::V8::CommonJS::Exception;

use strict;
use warnings;
use overload '""' => 'to_string';

sub new {
    my $class = shift;
    my $args  = shift || {};

    bless {
        stack   => $args->{stack}   || [],
        message => $args->{message} || '',
        source  => $args->{source}  || '?',
        line    => $args->{line}    || '?',
        column  => $args->{column}  || '?',
    }, $class;
}

sub new_from_string {
    my ($class, $string) = @_;

    # single line
    if ($string =~ /^(.*) at (.*):(\d+)$/) {
        return $class->new({ message => $1, source => $2, line => $3 });
    }

    # stacktrace
    # die "invalid stacktrace string" unless $string =~ /\nat /;
    my @lines = split /\n/, $string;

    # ReferenceError: foo is not defined
    # at eval (eval at <anonymous> (/home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:80), /home/cafe/workspace/JavaScript-V8-CommonJS/t/modules/notStrict.js:2:5)
    # at /home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:75
    # at global.require (/home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:96)
    # at eval (eval at <anonymous> (/home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:80), /home/cafe/workspace/JavaScript-V8-CommonJS/t/modules/exception.js:3:17)
    # at /home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:75
    # at global.require (/home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:96)
    # at test_script:1:6 at test_script:1


    my $message = shift @lines;
    my @stack;
    foreach (@lines) {
        my ($source, $line, $col);

        $_ =~ s/^\s+//;

        # at eval (eval at <anonymous> (/home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:80), /home/cafe/workspace/JavaScript-V8-CommonJS/t/modules/notStrict.js:2:5)
        if (($source, $line, $col) = $_ =~ /^at .*?, (.+):(\d+):(\d+)\)$/) { }

        # at /home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:75
        elsif (($source, $line, $col) = $_ =~ /^at (.+):(\d+):(\d+)$/) { }

        # at global.require (/home/cafe/workspace/JavaScript-V8-CommonJS/share/require.js:45:96)
        elsif (($source, $line, $col) = $_ =~ /^at \S+ \((.+):(\d+):(\d+)\)$/) { }

        # at test_script:1:6 at test_script:1
        elsif (($source, $line, $col) = $_ =~ /^at (.+):(\d+):(\d+) at \S+:\d+$/) { }

        # unknown line format
        else {
            warn "Couldn't parse javascript stacktrace line ($_)";
        }

        # push parsed line
        push @stack, {
            source => $source,
            line   => $line,
            column => $col
        }
    }

    $class->new({
        stack => \@stack,
        message => $message,
        %{ $stack[0] }
    })

}



sub stack { shift->{stack} }
sub message { shift->{message} }
sub source { shift->{source} }
sub line { shift->{line} }
sub column { shift->{column} }


sub to_string {
    my $self = shift;
    sprintf "[JavaScript Exception] %s at %s:%s:%s", $self->message, $self->source, $self->line, $self->column;
}


1;
