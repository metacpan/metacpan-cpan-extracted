use strict;
use warnings;
use MetaCPAN::API::Tiny;
use Carp ();
use Exporter 5.57 'import';

our @EXPORT    = qw(exception mcpan mock);

my $version = $MetaCPAN::API::Tiny::VERSION || 'xx';

sub mcpan {
    return MetaCPAN::API::Tiny->new(
        ua_args => [ agent => "MetaCPAN::API::Tiny-testing/$version" ],
    );
}

sub exception (&) {
  my $code = shift;
    
    my $ret = eval {
        $code->();
        "perlamonster";
    } || do {
        if($@)
        {
            "$@";
        }
        else
        {
            my $problem = defined $@ ? 'false' : 'undef';
            Carp::confess("$problem exception caught by Test::Fatal::exception");
        }
    
    };

    return $ret eq "perlamonster" ? undef : $ret;
}
my $mocks = {};

sub method($)  {@_}
sub methods($) {@_}
sub should(&)  {@_}

sub mock {
    Carp::croak 'useless use of mock with one or less parameter'
      if scalar @_ < 2;

    my $sub     = pop;
    my @symbols = _flat_symbols(@_);

    foreach my $symbol (@symbols) {
        Carp::croak "unknown symbol: $symbol"
          unless _symbol_exists($symbol);

        _save_sub($symbol);
        _bind_coderef_to_symbol($symbol, $sub);
    }
}

sub _flat_symbols {
    if (@_ == 2) {
        return ref $_[1] eq 'ARRAY'
          ? map {qq{$_[0]::$_}} @{$_[1]}
          : qq{$_[0]::$_[1]};
    }
    else {
        return ref $_[0] eq 'ARRAY'
          ? @{$_[0]}
          : $_[0];
    }
}

sub _symbol_exists {
    my ($symbol) = @_;
    {
        no strict 'refs';
        no warnings 'redefine', 'prototype';

        return defined *{$symbol}{CODE};
    }
}

sub _bind_coderef_to_symbol {
    my ($symbol, $sub) = @_;
    {
        no strict 'refs';
        no warnings 'redefine', 'prototype';

        *{$symbol} = $sub;
    }
}

sub _save_sub {
    my ($name) = @_;

    {
        no strict 'refs';
        $mocks->{$name} ||= *{$name}{CODE};
    }

    return $name;
}

1;
