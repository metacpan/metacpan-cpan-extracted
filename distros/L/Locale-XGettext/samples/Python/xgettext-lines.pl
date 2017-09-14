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

use Inline Python => $code;

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
