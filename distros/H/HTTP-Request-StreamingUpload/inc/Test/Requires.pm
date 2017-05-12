#line 1
package Test::Requires;
use strict;
use warnings;
our $VERSION = '0.01';
use base 'Test::Builder::Module';
use 5.008005;

our @QUEUE;

sub import {
    my $class = shift;
    my $caller = caller(0);

    # export methods
    {
        no strict 'refs';
        *{"$caller\::test_requires"} = \&test_requires;
    }

    # enqueue the args
    if (@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH') {
        while (my ($mod, $ver) = each %{$_[0]}) {
            push @QUEUE, [$mod, $ver, $caller];
        }
    } else {
        for my $mod (@_) {
            push @QUEUE, [$mod, undef, $caller];
        }
    }

    # dequeue one argument
    if (my $e = shift @QUEUE) {
        @_ = @$e;
        goto \&test_requires;
    }
}

sub test_requires {
    my ( $mod, $ver, $caller ) = @_;
    return if $mod eq __PACKAGE__;
    if (@_ != 3) {
        $caller = caller(0);
    }

    my $builder = __PACKAGE__->builder;

    package DB;
    local *DB::_test_requires_foo = sub {
        $ver ||= '';
        eval qq{package $caller; use $mod $ver}; ## no critic.
        if (my $e = $@) {
            my $skip_all = sub {
                if (not defined $builder->has_plan) {
                    $builder->skip_all(@_);
                } elsif ($builder->has_plan eq 'no_plan') {
                    $builder->skip(@_);
                    if ( $builder->parent ) {
                        die bless {} => 'Test::Builder::Exception';
                    }
                    exit 0;
                } else {
                    for (1..$builder->has_plan) {
                        $builder->skip(@_);
                    }
                    if ( $builder->parent ) {
                        die bless {} => 'Test::Builder::Exception';
                    }
                    exit 0;
                }
            };
            if ( $e =~ /^Can't locate/ ) {
                $skip_all->("Test requires module '$mod' but it's not found");
            }
            else {
                $skip_all->("$e");
            }
        }

        if (@QUEUE > 0) {
            @_ = @{ shift @QUEUE };
            goto \&Test::Requires::test_requires;
        }
    };

    goto \&DB::_test_requires_foo;
}

1;
__END__

#line 145
