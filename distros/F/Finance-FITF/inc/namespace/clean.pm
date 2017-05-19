#line 1
package namespace::clean;
BEGIN {
  $namespace::clean::AUTHORITY = 'cpan:PHAYLON';
}
BEGIN {
  $namespace::clean::VERSION = '0.20';
}
# ABSTRACT: Keep imports and functions out of your namespace

use warnings;
use strict;

use vars qw( $STORAGE_VAR );
use Sub::Name 0.04 qw(subname);
use Sub::Identify 0.04 qw(sub_fullname);
use Package::Stash 0.22;
use B::Hooks::EndOfScope 0.07;

$STORAGE_VAR = '__NAMESPACE_CLEAN_STORAGE';


my $RemoveSubs = sub {

    my $cleanee = shift;
    my $store   = shift;
    my $cleanee_stash = Package::Stash->new($cleanee);
    my $deleted_stash = Package::Stash->new("namespace::clean::deleted::$cleanee");
  SYMBOL:
    for my $f (@_) {
        my $variable = "&$f";
        # ignore already removed symbols
        next SYMBOL if $store->{exclude}{ $f };

        next SYMBOL unless $cleanee_stash->has_symbol($variable);

        if (ref(\$cleanee_stash->namespace->{$f}) eq 'GLOB') {
            # convince the Perl debugger to work
            # it assumes that sub_fullname($sub) can always be used to find the CV again
            # since we are deleting the glob where the subroutine was originally
            # defined, that assumption no longer holds, so we need to move it
            # elsewhere and point the CV's name to the new glob.
            my $sub = $cleanee_stash->get_symbol($variable);
            if ( sub_fullname($sub) eq ($cleanee_stash->name . "::$f") ) {
                my $new_fq = $deleted_stash->name . "::$f";
                subname($new_fq, $sub);
                $deleted_stash->add_symbol($variable, $sub);
            }
        }

        my ($scalar, $array, $hash, $io) = map {
            $cleanee_stash->get_symbol($_ . $f)
        } '$', '@', '%', '';
        $cleanee_stash->remove_glob($f);
        for my $var (['$', $scalar], ['@', $array], ['%', $hash], ['', $io]) {
            next unless defined $var->[1];
            $cleanee_stash->add_symbol($var->[0] . $f, $var->[1]);
        }
    }
};

sub clean_subroutines {
    my ($nc, $cleanee, @subs) = @_;
    $RemoveSubs->($cleanee, {}, @subs);
}


sub import {
    my ($pragma, @args) = @_;

    my (%args, $is_explicit);

  ARG:
    while (@args) {

        if ($args[0] =~ /^\-/) {
            my $key = shift @args;
            my $value = shift @args;
            $args{ $key } = $value;
        }
        else {
            $is_explicit++;
            last ARG;
        }
    }

    my $cleanee = exists $args{ -cleanee } ? $args{ -cleanee } : scalar caller;
    if ($is_explicit) {
        on_scope_end {
            $RemoveSubs->($cleanee, {}, @args);
        };
    }
    else {

        # calling class, all current functions and our storage
        my $functions = $pragma->get_functions($cleanee);
        my $store     = $pragma->get_class_store($cleanee);
        my $stash     = Package::Stash->new($cleanee);

        # except parameter can be array ref or single value
        my %except = map {( $_ => 1 )} (
            $args{ -except }
            ? ( ref $args{ -except } eq 'ARRAY' ? @{ $args{ -except } } : $args{ -except } )
            : ()
        );

        # register symbols for removal, if they have a CODE entry
        for my $f (keys %$functions) {
            next if     $except{ $f };
            next unless $stash->has_symbol("&$f");
            $store->{remove}{ $f } = 1;
        }

        # register EOF handler on first call to import
        unless ($store->{handler_is_installed}) {
            on_scope_end {
                $RemoveSubs->($cleanee, $store, keys %{ $store->{remove} });
            };
            $store->{handler_is_installed} = 1;
        }

        return 1;
    }
}


sub unimport {
    my ($pragma, %args) = @_;

    # the calling class, the current functions and our storage
    my $cleanee   = exists $args{ -cleanee } ? $args{ -cleanee } : scalar caller;
    my $functions = $pragma->get_functions($cleanee);
    my $store     = $pragma->get_class_store($cleanee);

    # register all unknown previous functions as excluded
    for my $f (keys %$functions) {
        next if $store->{remove}{ $f }
             or $store->{exclude}{ $f };
        $store->{exclude}{ $f } = 1;
    }

    return 1;
}


sub get_class_store {
    my ($pragma, $class) = @_;
    my $stash = Package::Stash->new($class);
    my $var = "%$STORAGE_VAR";
    $stash->add_symbol($var, {})
        unless $stash->has_symbol($var);
    return $stash->get_symbol($var);
}


sub get_functions {
    my ($pragma, $class) = @_;

    my $stash = Package::Stash->new($class);
    return {
        map { $_ => $stash->get_symbol("&$_") }
            $stash->list_all_symbols('CODE')
    };
}


no warnings;
'Danger! Laws of Thermodynamics may not apply.'

__END__
#line 378

