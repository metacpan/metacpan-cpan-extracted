#! /usr/bin/env perl

use strict;

use File::Spec;
my $code;

BEGIN {
    my @spec = File::Spec->splitpath(__FILE__);
    $spec[2] = 'PythonXGettext.py';
    my $filename = File::Spec->catpath(@spec);
    open HANDLE, "<$filename"
        or die "Cannot open '$filename': $!\n";
    $code = join '', <HANDLE>;
}

use Inline Python => 'DATA';

foreach my $key (keys %PythonXGettext::) {
    no strict 'refs';
    if ('new' ne $key && defined &{"PythonXGettext::$key"}) {
        *{"Locale::XGettext::Python::$key"} = sub {
            my ($self, @args) = @_;

            $self->{__helper}->$key(@args);
        };
    }
}

Locale::XGettext::Python->newFromArgv(\@ARGV)->run->output;

package Locale::XGettext::Python;

use strict;

use base qw(Locale::XGettext);

sub newFromArgv {
    my ($class, @args) = @_;

    my $self = bless {}, $class;
    $self->{__helper} = PythonXGettext->new($self);
    
    $self->SUPER::newFromArgv(@args);

    return $self;
}

__END__
__Python__

class PythonXGettext:
    def __init__(self, xgettext):
        self.xgettext = xgettext

    def readFile(self, filename):
        with open(filename) as f:
            for line in f:
                # You don't have to check that the line is empty.  The
                # PO header gets added after input has been processed.
                self.xgettext.addEntry({'msgid': line});

# For extended usage, see the file PythonXGettext.py!
