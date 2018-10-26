package Devel::Examine::Subs::Postprocessor;
use 5.008;
use strict;
use warnings;

our $VERSION = '1.70';

use Carp;

BEGIN {

    # we need to do some trickery for Devel::Trace::Subs due to circular
    # referencing, which broke CPAN installs. DTS does nothing if not presented,
    # per this code

    eval {
        require Devel::Trace::Subs;
        import Devel::Trace::Subs qw(trace);
    };

    if (! defined &trace){
        *trace = sub {};
    }
}

sub new {
    trace() if $ENV{TRACE};
    my $self = {};
    bless $self, shift;
    $self->{post_procs} = $self->_dt();
    return $self;
}
sub _dt {
    
    trace() if $ENV{TRACE};

    my $dt = {
        file_lines_contain => \&file_lines_contain,
        subs => \&subs,
        objects => \&objects,
        _default => \&_default,
        _test => \&_test,
        _test_bad => \&_test_bad,
        end_of_last_sub => \&end_of_last_sub,
    };

    return $dt;
}
sub exists {
    
    trace() if $ENV{TRACE};

    my $self = shift;
    my $string = shift;

    if (exists $self->{post_procs}{$string}){
        return 1;
    }
    else {
        return 0;
    }
}
sub subs {
    
    trace() if $ENV{TRACE};
    
    return sub {
        
        trace() if $ENV{TRACE};

        my ($p, $struct) = @_;

        my $s = $struct;
        my @subs;

        for my $f (keys %$s){

            for my $sub (keys %{$s->{$f}{subs}}){
                $s->{$f}{subs}{$sub}{start}++;
                $s->{$f}{subs}{$sub}{end}++;
                $s->{$f}{subs}{$sub}{name} = $sub;
                @{ $s->{$f}{subs}{$sub}{code} }
                  = @{ $s->{$f}{subs}{$sub}{code} };
                push @subs, $s->{$f}{subs}{$sub};
            }
        }
        return \@subs;
    };
}
sub file_lines_contain {
    
    trace() if $ENV{TRACE};

    return sub {
        
        trace() if $ENV{TRACE};

        my $p = shift;
        my $struct = shift;

        my $search = $p->{search};

        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }

        my $s = $struct;

        if (not $search){
            return $struct;
        }

        for my $f (keys %$s){
            for my $sub (keys %{$s->{$f}{subs}}){
                my $found = 0;
                my @has;
                for (@{$s->{$f}{subs}{$sub}{code}}){
                    if ($_ and /$search/){
                        $found++;
                        push @has, $_;
                     }
                }
                if (! $found){
                    delete $s->{$f}{subs}{$sub};                
                    next;
                }
                $s->{$f}{subs}{$sub}{code} = \@has;
            }
        }
        return $struct;
    };
}
sub end_of_last_sub {
    
    trace() if $ENV{TRACE};
    
    return sub {
        
        trace() if $ENV{TRACE};
        
        my $p = shift;
        my $struct = shift;

        my @last_line_nums;

        for my $sub (@$struct){
            push @last_line_nums, $sub->{end};
        }

        @last_line_nums = sort {$a<=>$b} @last_line_nums;

        return $last_line_nums[-1];

    };
}
sub _test {
    
    trace() if $ENV{TRACE};

    return sub {
        trace() if $ENV{TRACE};
        my ($p, $struct) = @_;
        return $struct;
    };
}
sub objects {
    
    trace() if $ENV{TRACE};

    # uses 'subs' post_proc

    return sub {
        
        trace() if $ENV{TRACE};

        my $p = shift;
        my $struct = shift;

        my @return;

        return if not ref($struct) eq 'ARRAY';

        my $search = $p->{search};

        if ($search && ! $p->{regex}){
            $search = "\Q$search";
        }

        my $des_sub;

        for my $sub (@$struct){

            $des_sub
              = Devel::Examine::Subs::Sub->new($sub, $sub->{name});

            push @return, $des_sub;
        }

        return \@return;
    };
}
sub _vim_placeholder {1;}
1;
__END__

=head1 NAME

Devel::Examine::Subs::Postprocessor - Provides core Pre-Filter callbacks for
Devel::Examine::Subs

=head1 DESCRIPTION

This module generates and supplies the core post-processor module callbacks.
Postprocessors run after the core Processor, and before any Engine is run.

=head1 SYNOPSIS

Post-processors can be daisy chained as text strings that represent a built-in
post-processor, or as callbacks, or both.

See C<Devel::Examine::Subs::_post_proc()> for implementation details.

=head1 METHODS

All methods other than C<exists()> takes an href of configuration data as its
first parameter.

=head2 C<exists('post-processor')>

Verifies whether the post-processor name specified as the string parameter
exists and is valid.

=head2 C<subs()>

Returns an aref of hash refs, each containing info per sub.


=head2 C<file_lines_contain()>

Returns an aref similar to C<subs()>, but includes an array within each sub
href that contains lines that match a search term.

=head2 C<end_of_last_sub()>

Takes data from C<subs()>.

Returns a scalar containing the last line number of the last sub in a file.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Examine::Subs

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
