package JQ::Lite::Runtime;

use strict;
use warnings;

use JQ::Lite::Error ();
use JQ::Lite::Filters ();
use JQ::Lite::Util ();

sub new {
    my ($class, %opts) = @_;
    die 'runtime owner is required' unless $opts{owner};
    return bless { owner => $opts{owner} }, $class;
}

sub decode_input {
    my ($self, $json_text) = @_;

    my ($value, $ok, $error);
    {
        local $@;
        $ok = eval {
            $value = JQ::Lite::Util::_decode_json($json_text);
            1;
        };
        $error = $@;
    }

    return $value if $ok;
    die $error if ref($error) && eval { $error->isa('JQ::Lite::Error') };
    die JQ::Lite::Error::Input->new(message => $error);
}

sub evaluate_filter {
    my ($self, $filter, $inputs) = @_;

    my @outputs;
    if (JQ::Lite::Filters::apply(
            $self->{owner}, $filter->source, $inputs, \@outputs
        ))
    {
        return @outputs;
    }

    for my $input (@{$inputs}) {
        push @outputs, JQ::Lite::Util::_traverse($input, $filter->source);
    }

    return @outputs;
}

1;
