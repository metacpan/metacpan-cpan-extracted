package Devel::REPL::Plugin::InProcess;

use Devel::REPL::Plugin;
use PadWalker ();
use namespace::clean -except => [ 'meta' ];

has '_caller_depth' => (
    isa     => 'Int',
    is      => 'rw',
);

has '_package' => (
    isa     => 'Str',
    is      => 'rw',
);

has '_my_scalars' => (
    isa     => 'HashRef',
    is      => 'rw',
);

has '_our_scalars' => (
    isa     => 'HashRef',
    is      => 'rw',
);

has '_lexical_hints' => (
    isa     => "ArrayRef",
    is      => "rw",
);

has 'skip_levels' => (
    isa     => "Int",
    is      => "rw",
    default => 0,
);

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('LexEnv');
}

around 'execute' => sub {
    my ($orig, $_REPL, @args) = @_;
    $_REPL->_sync_to_lexenv;
    my @res = $_REPL->$orig(@args);
    $_REPL->_sync_from_lexenv;
    return @res;
};

# stolen from Devel::REPL::Plugin::Package
around 'wrap_as_sub' => sub {
    my ($orig, $_REPL, @args) = @_;
    $_REPL->_find_level_and_initialize unless $_REPL->_caller_depth;
    my $line = $_REPL->$orig(@args);
    return sprintf "package %s;\n%s", $_REPL->_package, $line;
};

sub _sync_to_lexenv {
    my ($self) = @_;
    my $cxt = $self->lexical_environment->get_context('_');
    my $my = $self->_my_scalars;
    my $our = $self->_our_scalars;

    $cxt->{$_} = ${$my->{$_}} for keys %$my;
    $cxt->{$_} = ${$our->{$_}} for keys %$our;
}

sub _sync_from_lexenv {
    my ($self) = @_;
    my $cxt = $self->lexical_environment->get_context('_');
    my $my = $self->_my_scalars;
    my $our = $self->_our_scalars;

    ${$my->{$_}} = $cxt->{$_} for keys %$my;
    ${$our->{$_}} = $cxt->{$_} for keys %$our;
}

sub _find_level_and_initialize {
    my ($self) = @_;
    my ($level, $evals, @found_level, @found_eval) = (0, 0);
    my $skip = $self->skip_levels;

    for (;; ++$level) {
        my ($package, $filename, $line, $subroutine, $hasargs,
            $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) =
                caller $level;
        last if !defined $package;
        ++$evals if $subroutine && $subroutine eq '(eval)';
        if ($package =~ /^Devel::REPL\b/) {
            @found_level = @found_eval = ();
        } elsif ($package =~ /^DB\b/) {
            # just ignore DB frames
        } else {
            push @found_level, $level;
            push @found_eval, $evals;
        }
    }

    die "Could not find package outside REPL/debugger" unless @found_level;
    die "Asked to skip more packages than have been forund"
        if $skip && $skip >= @found_level;
    my ($found_level, $found_eval) = ($found_level[$skip], $found_eval[$skip]);

    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) =
            caller $found_level;

    # (+ 1) because caller(0) is the caller package while peek_my(0) are
    # the lexicals in the current scope, (- $found_evals) because peek_my
    # skips eval frames but caller counts them
    my $my = PadWalker::peek_my($found_level + 1 - $found_eval);
    my $our = PadWalker::peek_our($found_level + 1 - $found_eval);
    my $lexenv = $self->lexical_environment;
    my $cxt;

    for my $key (keys %$my) {
        if ($key =~ /^\$/) {
            $cxt->{$key} = ${$my->{$key}};
        } else {
            $cxt->{$key} = $my->{$key};
        }
    }
    for my $key (keys %$our) {
        if ($key =~ /^\$/) {
            $cxt->{$key} = ${$our->{$key}};
        } else {
            $cxt->{$key} = $our->{$key};
        }
    }

    $lexenv->set_context('_' => $cxt);

    $self->_caller_depth($found_level);
    $self->_package($package);
    $self->_lexical_hints([$hints, $hinthash]);
    $self->_my_scalars({
        map +($_ => $my->{$_}), grep /^\$/, keys %$my
    });
    $self->_our_scalars({
        map +($_ => $our->{$_}), grep /^\$/, keys %$our
    });
}

1;
