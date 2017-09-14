#! /usr/bin/env perl

use strict;

use File::Spec;
my $code;

BEGIN {
    my @spec = File::Spec->splitpath(__FILE__);
    $spec[2] = 'RubyXGettext.rb';
    my $filename = File::Spec->catpath(@spec);
    open HANDLE, "<$filename"
        or die "Cannot open '$filename': $!\n";
    $code = join '', <HANDLE>;
}

use Inline Ruby => $code;

# First inject all methods from the Ruby class into Perl.
my %ruby_methods = %RubyXGettext::;
foreach my $key (sort keys %ruby_methods) {
    no strict 'refs';
    if ('new' ne $key && defined &{"RubyXGettext::$key"}) {
        *{"Locale::XGettext::Ruby::$key"} = sub {
            my ($self, @args) = @_;

            $self->{__helper}->$key(@args);
        };
    }
}

# Ruby does not support calling arbitrary Perl methods or subroutines.
# But we can pass a closure as a Proc that can be called from Ruby.
# This is not a general-purpose solution but works in our case.
my @isa = @Locale::XGettext::Ruby::ISA;
my %seen;
foreach my $class (@isa, 'Locale::XGettext::Ruby') {
    no strict 'refs';
    foreach my $method (keys %{$class . '::'}) {
        # Do not export what we had imported above.
        next if $ruby_methods{$method};

        # And private methods.
        next if $method =~ /^__/;

        # And more stuff.
        next if $method =~ /::$/;
        next if 'new' eq $method;
        next if 'newFromArgv' eq $method;
        next if 'ISA' eq $method;

        next if $seen{$method}++;

        Inline::Ruby::rb_eval(<<EOF);
class RubyXGettext
    def $method(*args)
        \@xgettext['$method'].call(*args)
    end
end
EOF
    }

}

Locale::XGettext::Ruby->newFromArgv(\@ARGV)->run->output;

package Locale::XGettext::Ruby;

use strict;

use base qw(Locale::XGettext);

sub newFromArgv {
    my ($class, @args) = @_;

    my $self = bless {}, $class;

    my %procs;
    foreach my $method (keys %seen) {
        $procs{$method} = sub {
            $self->$method(@_);
        }
    }

    $self->{__helper} = RubyXGettext->new(\%procs);
    
    $self->SUPER::newFromArgv(@args);

    return $self;
}
